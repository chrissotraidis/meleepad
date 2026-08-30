#!/usr/bin/env python3
"""Join external native-PC samples to exact phase start-to-start intervals."""

from __future__ import annotations

import argparse
import bisect
import csv
import ctypes
import math
import pathlib
import re
import subprocess
import sys
from collections import Counter, defaultdict


REQUIRED_PHASE_FIELDS = (
    "frame",
    "emulated_frame",
    "host_frame_end_unix_ns",
    "total_ms",
    "video_build_ms",
    "present_ms",
)
ATOS_OFFSET = re.compile(r"^(.*?)(?: \(in .+\))? \+ [0-9]+$")


def complete(row: dict[str, str | None], fields: tuple[str, ...]) -> bool:
    return all(row.get(field) not in (None, "") for field in fields)


def phase_bounds(row: dict[str, str | None]) -> tuple[int, int]:
    frame_end = int(row["host_frame_end_unix_ns"] or "")
    frame_start = frame_end - round(
        (float(row["video_build_ms"] or "") + float(row["present_ms"] or ""))
        * 1_000_000
    )
    previous_frame_start = frame_start - round(
        float(row["total_ms"] or "") * 1_000_000
    )
    return previous_frame_start, frame_start


def symbol_name(text: str) -> str:
    match = ATOS_OFFSET.match(text)
    return match.group(1) if match else text


def symbolize(samples: list[dict[str, str]], batch_size: int = 500) -> dict[int, str]:
    groups: dict[tuple[str, int], list[int]] = defaultdict(list)
    for sample in samples:
        path = sample["image_path"]
        if path:
            groups[(path, int(sample["image_base"]))].append(int(sample["native_pc"]))

    result: dict[int, str] = {}
    for (path, base), values in groups.items():
        pcs = list(dict.fromkeys(values))
        for begin in range(0, len(pcs), batch_size):
            batch = pcs[begin : begin + batch_size]
            completed = subprocess.run(
                [
                    "atos",
                    "-arch",
                    "arm64",
                    "-o",
                    path,
                    "-l",
                    hex(base),
                    *(hex(pc) for pc in batch),
                ],
                capture_output=True,
                text=True,
            )
            symbols = completed.stdout.splitlines()
            if completed.returncode != 0 or len(symbols) != len(batch):
                if begin == 0:
                    print(f"warning: atos unavailable for {path}; using image offsets", file=sys.stderr)
                continue
            result.update((pc, symbol_name(text)) for pc, text in zip(batch, symbols))
    if sys.platform == "darwin":
        class DlInfo(ctypes.Structure):
            _fields_ = (
                ("filename", ctypes.c_char_p),
                ("image_base", ctypes.c_void_p),
                ("symbol_name", ctypes.c_char_p),
                ("symbol_address", ctypes.c_void_p),
            )

        process = ctypes.CDLL(None)
        process.dladdr.argtypes = (ctypes.c_void_p, ctypes.POINTER(DlInfo))
        process.dladdr.restype = ctypes.c_int
        for sample in samples:
            if sample["image_path"] or int(sample["image_base"]) == 0:
                continue
            pc = int(sample["native_pc"])
            if pc in result:
                continue
            info = DlInfo()
            if process.dladdr(ctypes.c_void_p(pc), ctypes.byref(info)) and info.symbol_name:
                name = info.symbol_name.decode(errors="replace")
                symbol_address = info.symbol_address or 0
                offset = pc - symbol_address
                result[pc] = name if offset == 0 else f"{name} + 0x{offset:x}"
    return result


def sample_key(sample: dict[str, str], symbols: dict[int, str]) -> str:
    pc = int(sample["native_pc"])
    if pc in symbols:
        return symbols[pc]
    path = sample["image_path"] or (
        "shared-cache" if int(sample["image_base"]) != 0 else "unresolved"
    )
    return f"{path}+0x{int(sample['image_offset']):x}"


def return_frames(sample: dict[str, str]) -> list[dict[str, str]]:
    frames: list[dict[str, str]] = []
    index = 0
    while f"return_pc_{index}" in sample:
        pc = sample.get(f"return_pc_{index}", "")
        if pc not in (None, "", "0"):
            frames.append(
                {
                    "native_pc": pc,
                    "image_base": sample.get(f"return_image_base_{index}", "0") or "0",
                    "image_offset": sample.get(f"return_image_offset_{index}", "0") or "0",
                    "image_path": sample.get(f"return_image_path_{index}", "") or "",
                }
            )
        index += 1
    return frames


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase_csv", type=pathlib.Path)
    parser.add_argument("sample_csv", type=pathlib.Path)
    parser.add_argument("--min-emulated-frame", type=int, required=True)
    parser.add_argument("--max-emulated-frame", type=int, required=True)
    parser.add_argument("--metric", default="cpu_thread_ms")
    parser.add_argument("--threshold-ms", type=float, default=16.7)
    parser.add_argument("--limit", type=int, default=30)
    parser.add_argument("--symbolize", action="store_true")
    parser.add_argument("--show-stacks", action="store_true")
    args = parser.parse_args()
    if args.min_emulated_frame >= args.max_emulated_frame:
        parser.error("min-emulated-frame must be below max-emulated-frame")
    if args.threshold_ms <= 0 or args.limit <= 0:
        parser.error("threshold-ms and limit must be positive")

    with args.sample_csv.open(newline="", encoding="utf-8") as source:
        samples = list(csv.DictReader(source))
    if not samples:
        parser.error("sample CSV is empty")
    sample_times = [int(sample["unix_ns"]) for sample in samples]
    if sample_times != sorted(sample_times):
        parser.error("sample timestamps are not monotonic")

    required = REQUIRED_PHASE_FIELDS + (args.metric,)
    with args.phase_csv.open(newline="", encoding="utf-8") as source:
        raw_phase = list(csv.DictReader(source))
    phase = [row for row in raw_phase if complete(row, required)]

    body: Counter[str] = Counter()
    overrun: Counter[str] = Counter()
    joined: list[tuple[dict[str, str | None], list[dict[str, str]], bool]] = []
    selected_samples: list[dict[str, str]] = []
    for row in phase:
        emulated_frame = int(row["emulated_frame"] or "")
        if not args.min_emulated_frame <= emulated_frame < args.max_emulated_frame:
            continue
        start_ns, end_ns = phase_bounds(row)
        begin = bisect.bisect_right(sample_times, start_ns)
        end = bisect.bisect_right(sample_times, end_ns)
        exact = samples[begin:end]
        if not exact:
            continue
        is_overrun = float(row[args.metric] or "") > args.threshold_ms
        joined.append((row, exact, is_overrun))
        selected_samples.extend(exact)

    if not joined:
        parser.error("no phase frames overlap sample coverage")
    symbol_inputs = list(selected_samples)
    if args.show_stacks:
        for sample in selected_samples:
            symbol_inputs.extend(return_frames(sample))
    symbols = symbolize(symbol_inputs) if args.symbolize else {}
    for _row, exact, is_overrun in joined:
        target = overrun if is_overrun else body
        target.update(sample_key(sample, symbols) for sample in exact)

    body_frames = sum(not is_overrun for _row, _exact, is_overrun in joined)
    overrun_frames = sum(is_overrun for _row, _exact, is_overrun in joined)
    print(
        "SUMMARY,"
        f"raw_phase_rows={len(raw_phase)},complete_phase_rows={len(phase)},"
        f"joined_frames={len(joined)},body_frames={body_frames},overrun_frames={overrun_frames},"
        f"body_samples={sum(body.values())},overrun_samples={sum(overrun.values())},"
        f"excluded_incomplete_rows={len(raw_phase) - len(phase)}"
    )
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(
        ("FRAME", "phase_frame", "emulated_frame", "total_ms", "metric_ms", "samples", "running", "waiting")
    )
    for row, exact, is_overrun in joined:
        if not is_overrun:
            continue
        writer.writerow(
            (
                "FRAME",
                row["frame"],
                row["emulated_frame"],
                f"{float(row['total_ms'] or ''):.6f}",
                f"{float(row[args.metric] or ''):.6f}",
                len(exact),
                sum(sample["state"] == "1" for sample in exact),
                sum(sample["state"] == "3" for sample in exact),
            )
        )

    writer.writerow(
        ("SYMBOL", "body_samples", "overrun_samples", "body_per_frame", "overrun_per_frame", "delta_per_frame", "ratio", "symbol")
    )
    ranked: list[tuple[float, str]] = []
    for key in body.keys() | overrun.keys():
        body_rate = body[key] / body_frames if body_frames else 0.0
        overrun_rate = overrun[key] / overrun_frames if overrun_frames else 0.0
        ranked.append((overrun_rate - body_rate, key))
    for _delta, key in sorted(ranked, reverse=True)[: args.limit]:
        body_rate = body[key] / body_frames if body_frames else 0.0
        overrun_rate = overrun[key] / overrun_frames if overrun_frames else 0.0
        ratio = overrun_rate / body_rate if body_rate else math.inf
        ratio_text = "inf" if math.isinf(ratio) else f"{ratio:.3f}"
        writer.writerow(
            (
                "SYMBOL",
                body[key],
                overrun[key],
                f"{body_rate:.6f}",
                f"{overrun_rate:.6f}",
                f"{overrun_rate - body_rate:.6f}",
                ratio_text,
                key,
            )
        )
    if args.show_stacks:
        stacks: Counter[tuple[str, ...]] = Counter()
        for _row, exact, is_overrun in joined:
            if not is_overrun:
                continue
            for sample in exact:
                stack = (sample_key(sample, symbols),) + tuple(
                    sample_key(frame, symbols) for frame in return_frames(sample)
                )
                stacks[stack] += 1
        for stack, count in stacks.most_common(args.limit):
            writer.writerow(("STACK", count, " <- ".join(stack)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
