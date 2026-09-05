#!/usr/bin/env python3
"""Join dispatch samples to wall-time windows and rank stable chunk entries."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import statistics
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Window:
    label: str
    phase_csv: Path
    sample_csv: Path
    start_ns: int
    end_ns: int


@dataclass
class WindowData:
    frames: set[int]
    samples: Counter[int]
    duration_seconds: float
    cpu_thread_ms: list[float]
    native_dispatches: list[int]
    draw_calls: list[int]
    primitives: list[int]


def positive_int(value: str) -> int:
    parsed = int(value, 0)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def positive_float(value: str) -> float:
    parsed = float(value)
    if parsed <= 0.0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def fraction(value: str) -> float:
    parsed = float(value)
    if not 0.0 < parsed <= 1.0:
        raise argparse.ArgumentTypeError("fraction must be greater than 0 and at most 1")
    return parsed


def timestamp_ns(value: str) -> int:
    try:
        return int(value, 0)
    except ValueError:
        pass
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"invalid timestamp: {value}") from error
    if parsed.tzinfo is None:
        raise argparse.ArgumentTypeError("ISO timestamp must include a UTC offset")
    return int(parsed.timestamp() * 1_000_000_000)


def parse_windows(raw_windows: list[list[str]]) -> list[Window]:
    windows: list[Window] = []
    labels: set[str] = set()
    for label, phase, samples, start, end in raw_windows:
        if label in labels:
            raise ValueError(f"duplicate window label: {label}")
        labels.add(label)
        start_ns = timestamp_ns(start)
        end_ns = timestamp_ns(end)
        if start_ns >= end_ns:
            raise ValueError(f"window {label} start must precede end")
        windows.append(Window(label, Path(phase), Path(samples), start_ns, end_ns))
    return windows


def load_window(window: Window) -> WindowData:
    frames: set[int] = set()
    cpu_thread_ms: list[float] = []
    native_dispatches: list[int] = []
    draw_calls: list[int] = []
    primitives: list[int] = []
    required_phase = {
        "frame",
        "host_frame_end_unix_ns",
        "cpu_thread_ms",
        "static_native_dispatches",
        "draw_calls",
        "primitives",
    }
    with window.phase_csv.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        if rows.fieldnames is None or not required_phase.issubset(rows.fieldnames):
            raise ValueError(
                f"phase CSV for {window.label} must contain "
                + ", ".join(sorted(required_phase))
            )
        for row in rows:
            end_ns = int(row["host_frame_end_unix_ns"])
            if window.start_ns <= end_ns < window.end_ns:
                frames.add(int(row["frame"]))
                cpu_thread_ms.append(float(row["cpu_thread_ms"]))
                native_dispatches.append(int(row["static_native_dispatches"]))
                draw_calls.append(int(row["draw_calls"]))
                primitives.append(int(row["primitives"]))
    if not frames:
        raise ValueError(f"window {window.label} has no phase rows")

    samples: Counter[int] = Counter()
    with window.sample_csv.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        if rows.fieldnames is None or not {"frame", "pc"}.issubset(rows.fieldnames):
            raise ValueError(
                f"sample CSV for {window.label} must contain frame and pc columns"
            )
        for row in rows:
            if int(row["frame"]) in frames:
                samples[int(row["pc"], 16)] += 1
    if not samples:
        raise ValueError(f"window {window.label} has no dispatch samples")

    return WindowData(
        frames=frames,
        samples=samples,
        duration_seconds=(window.end_ns - window.start_ns) / 1_000_000_000.0,
        cpu_thread_ms=cpu_thread_ms,
        native_dispatches=native_dispatches,
        draw_calls=draw_calls,
        primitives=primitives,
    )


def region_for_pc(pc: int, origin: int, size: int) -> int:
    return origin + ((pc - origin) // size) * size


def mean(values: list[float] | list[int]) -> float:
    return statistics.fmean(values)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--window",
        action="append",
        nargs=5,
        metavar=("LABEL", "PHASE_CSV", "SAMPLE_CSV", "START", "END"),
        required=True,
        help="repeat for each ISO-8601 or Unix-nanosecond wall-time window",
    )
    parser.add_argument("--region-origin", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--region-size", type=positive_int, default=0x4000)
    parser.add_argument("--minimum-region-samples", type=positive_int, default=20)
    parser.add_argument("--maximum-share-ratio", type=positive_float, default=1.25)
    parser.add_argument("--target-coverage", type=fraction, default=0.70)
    parser.add_argument("--region-limit", type=positive_int, default=20)
    parser.add_argument("--entry-limit", type=positive_int, default=8)
    args = parser.parse_args()

    if args.maximum_share_ratio < 1.0:
        parser.error("maximum share ratio must be at least 1")
    try:
        windows = parse_windows(args.window)
        data = {window.label: load_window(window) for window in windows}
    except (OSError, ValueError, argparse.ArgumentTypeError) as error:
        parser.error(str(error))

    labels = [window.label for window in windows]
    totals = {label: sum(data[label].samples.values()) for label in labels}
    regions: dict[str, Counter[int]] = {label: Counter() for label in labels}
    for label in labels:
        for pc, samples in data[label].samples.items():
            regions[label][region_for_pc(pc, args.region_origin, args.region_size)] += samples

    print(
        "WINDOW,label,frames,duration_seconds,phase_fps,cpu_thread_ms,"
        "native_dispatches,draw_calls,primitives,samples"
    )
    for label in labels:
        current = data[label]
        print(
            f"WINDOW,{label},{len(current.frames)},{current.duration_seconds:.6f},"
            f"{len(current.frames) / current.duration_seconds:.6f},"
            f"{mean(current.cpu_thread_ms):.6f},{mean(current.native_dispatches):.3f},"
            f"{mean(current.draw_calls):.3f},{mean(current.primitives):.3f},"
            f"{totals[label]}"
        )

    all_regions = set().union(*(set(counter) for counter in regions.values()))
    stable: list[tuple[float, int, dict[str, float]]] = []
    for start in all_regions:
        shares = {label: regions[label][start] / totals[label] for label in labels}
        if not all(
            regions[label][start] >= args.minimum_region_samples for label in labels
        ):
            continue
        minimum_share = min(shares.values())
        if minimum_share == 0.0:
            continue
        if max(shares.values()) / minimum_share > args.maximum_share_ratio:
            continue
        stable.append((minimum_share, start, shares))
    stable.sort(reverse=True)

    cumulative = {label: 0.0 for label in labels}
    selected_count = 0
    for selected_count, (_, _, shares) in enumerate(stable, 1):
        for label in labels:
            cumulative[label] += shares[label]
        if min(cumulative.values()) >= args.target_coverage:
            break
    reached = bool(stable) and min(cumulative.values()) >= args.target_coverage
    if not stable:
        selected_count = 0
    elif not reached:
        selected_count = len(stable)

    print(
        "SUMMARY,"
        f"windows={len(labels)},stable_regions={len(stable)},"
        f"target_coverage={args.target_coverage:.6f},"
        f"maximum_share_ratio={args.maximum_share_ratio:.6f},"
        f"selected_regions={selected_count},"
        f"selected_minimum_coverage={min(cumulative.values()) if stable else 0.0:.6f},"
        f"coverage_gate={'PASS' if reached else 'FAIL'}"
    )
    print(
        "REGION,rank,start,end,min_share,max_share,share_ratio,"
        + ",".join(f"{label}_samples,{label}_share" for label in labels)
        + ",selected"
    )
    selected_starts: set[int] = set()
    for rank, (minimum_share, start, shares) in enumerate(
        stable[: args.region_limit], 1
    ):
        selected = rank <= selected_count
        if selected:
            selected_starts.add(start)
        print(
            f"REGION,{rank},{start:08x},{start + args.region_size:08x},"
            f"{minimum_share:.6f},{max(shares.values()):.6f},"
            f"{max(shares.values()) / minimum_share:.6f},"
            + ",".join(
                f"{regions[label][start]},{shares[label]:.6f}" for label in labels
            )
            + f",{'yes' if selected else 'no'}"
        )

    print(
        "ENTRY,region,rank,pc,min_total_share,max_total_share,share_ratio,"
        + ",".join(f"{label}_samples,{label}_share" for label in labels)
    )
    for start in sorted(selected_starts):
        end = start + args.region_size
        pcs = set().union(
            *(
                {pc for pc in data[label].samples if start <= pc < end}
                for label in labels
            )
        )
        entries: list[tuple[float, int, dict[str, float]]] = []
        for pc in pcs:
            shares = {
                label: data[label].samples[pc] / totals[label] for label in labels
            }
            minimum_share = min(shares.values())
            if minimum_share == 0.0:
                continue
            entries.append((minimum_share, pc, shares))
        entries.sort(reverse=True)
        for rank, (minimum_share, pc, shares) in enumerate(
            entries[: args.entry_limit], 1
        ):
            print(
                f"ENTRY,{start:08x},{rank},{pc:08x},{minimum_share:.6f},"
                f"{max(shares.values()):.6f},"
                f"{max(shares.values()) / minimum_share:.6f},"
                + ",".join(
                    f"{data[label].samples[pc]},{shares[label]:.6f}"
                    for label in labels
                )
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
