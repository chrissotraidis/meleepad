#!/usr/bin/env python3
"""Rank sampled static-recompiler entries by calibrated host execution time."""

from __future__ import annotations

import argparse
import csv
import statistics
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Window:
    label: str
    start: int
    end: int


@dataclass
class WindowData:
    frame_count: int
    cpu_thread_ms: float
    samples: Counter[int]
    corrected_ns: Counter[int]
    clock_ns: list[int]


def positive_int(value: str) -> int:
    parsed = int(value, 0)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def parse_windows(raw: list[list[str]]) -> list[Window]:
    windows: list[Window] = []
    labels: set[str] = set()
    for label, start_text, end_text in raw:
        start = int(start_text, 0)
        end = int(end_text, 0)
        if label in labels:
            raise ValueError(f"duplicate window label: {label}")
        if start >= end:
            raise ValueError(f"window {label} start must precede end")
        labels.add(label)
        windows.append(Window(label, start, end))
    return windows


def load_phase(path: Path, windows: list[Window]) -> dict[str, tuple[int, float]]:
    values: dict[str, list[float]] = {window.label: [] for window in windows}
    required = {"emulated_frame", "cpu_thread_ms"}
    with path.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        if rows.fieldnames is None or not required.issubset(rows.fieldnames):
            raise ValueError("phase CSV must contain emulated_frame and cpu_thread_ms")
        for row in rows:
            try:
                frame = int(row["emulated_frame"])
                cpu_ms = float(row["cpu_thread_ms"])
            except (TypeError, ValueError):
                continue
            for window in windows:
                if window.start <= frame < window.end:
                    values[window.label].append(cpu_ms)
                    break
    result: dict[str, tuple[int, float]] = {}
    for window in windows:
        current = values[window.label]
        if not current:
            raise ValueError(f"window {window.label} has no phase rows")
        result[window.label] = (len(current), statistics.fmean(current))
    return result


def load_samples(
    path: Path, windows: list[Window], phase: dict[str, tuple[int, float]]
) -> dict[str, WindowData]:
    data = {
        window.label: WindowData(phase[window.label][0], phase[window.label][1],
                                 Counter(), Counter(), [])
        for window in windows
    }
    required = {"emulated_frame", "pc", "host_ns", "clock_ns"}
    with path.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        if rows.fieldnames is None or not required.issubset(rows.fieldnames):
            raise ValueError(
                "sample CSV must contain emulated_frame, pc, host_ns, and clock_ns"
            )
        for row in rows:
            try:
                frame = int(row["emulated_frame"])
                pc = int(row["pc"], 16)
                host_ns = int(row["host_ns"])
                clock_ns = int(row["clock_ns"])
            except (TypeError, ValueError):
                continue
            for window in windows:
                if window.start <= frame < window.end:
                    current = data[window.label]
                    current.samples[pc] += 1
                    current.corrected_ns[pc] += max(host_ns - clock_ns, 0)
                    current.clock_ns.append(clock_ns)
                    break
    for window in windows:
        if not data[window.label].samples:
            raise ValueError(f"window {window.label} has no timing samples")
    return data


def region_for_pc(pc: int, origin: int, size: int) -> int:
    return origin + ((pc - origin) // size) * size


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", type=Path, required=True)
    parser.add_argument("--samples", type=Path, required=True)
    parser.add_argument(
        "--window", action="append", nargs=3,
        metavar=("LABEL", "START_EMULATED_FRAME", "END_EMULATED_FRAME"),
        required=True,
    )
    parser.add_argument("--sample-interval", type=positive_int, required=True)
    parser.add_argument("--region-origin", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--region-size", type=positive_int, default=0x4000)
    parser.add_argument("--minimum-region-samples", type=positive_int, default=20)
    parser.add_argument("--region-limit", type=positive_int, default=20)
    parser.add_argument("--entry-limit", type=positive_int, default=30)
    args = parser.parse_args()

    try:
        windows = parse_windows(args.window)
        phase = load_phase(args.phase, windows)
        data = load_samples(args.samples, windows, phase)
    except (OSError, ValueError) as error:
        parser.error(str(error))

    labels = [window.label for window in windows]
    print(
        "WINDOW,label,frames,samples,median_clock_ns,cpu_thread_ms,"
        "estimated_dispatch_cpu_ms,estimated_cpu_coverage"
    )
    for label in labels:
        current = data[label]
        estimated_ms = (
            sum(current.corrected_ns.values()) * args.sample_interval /
            current.frame_count / 1_000_000.0
        )
        print(
            f"WINDOW,{label},{current.frame_count},{sum(current.samples.values())},"
            f"{statistics.median(current.clock_ns):.3f},{current.cpu_thread_ms:.6f},"
            f"{estimated_ms:.6f},{estimated_ms / current.cpu_thread_ms:.6f}"
        )

    region_samples: dict[str, Counter[int]] = {label: Counter() for label in labels}
    region_time: dict[str, Counter[int]] = {label: Counter() for label in labels}
    all_pcs: set[int] = set()
    for label in labels:
        all_pcs.update(data[label].samples)
        for pc, count in data[label].samples.items():
            region = region_for_pc(pc, args.region_origin, args.region_size)
            region_samples[label][region] += count
            region_time[label][region] += data[label].corrected_ns[pc]

    total_time = {label: sum(data[label].corrected_ns.values()) for label in labels}
    all_regions = set().union(*(set(region_time[label]) for label in labels))
    ranked_regions: list[tuple[float, int]] = []
    for region in all_regions:
        if any(region_samples[label][region] < args.minimum_region_samples for label in labels):
            continue
        shares = [
            region_time[label][region] / total_time[label] if total_time[label] else 0.0
            for label in labels
        ]
        ranked_regions.append((min(shares), region))
    ranked_regions.sort(reverse=True)

    print(
        "REGION,rank,start,end,min_time_share,max_time_share," +
        ",".join(f"{label}_samples,{label}_corrected_ns,{label}_share" for label in labels)
    )
    for rank, (_, region) in enumerate(ranked_regions[: args.region_limit], 1):
        shares = [
            region_time[label][region] / total_time[label] if total_time[label] else 0.0
            for label in labels
        ]
        print(
            f"REGION,{rank},{region:08x},{region + args.region_size:08x},"
            f"{min(shares):.6f},{max(shares):.6f}," +
            ",".join(
                f"{region_samples[label][region]},{region_time[label][region]},"
                f"{region_time[label][region] / total_time[label]:.6f}"
                for label in labels
            )
        )

    ranked_entries: list[tuple[float, int]] = []
    for pc in all_pcs:
        shares = [
            data[label].corrected_ns[pc] / total_time[label] if total_time[label] else 0.0
            for label in labels
        ]
        ranked_entries.append((sum(shares) / len(shares), pc))
    ranked_entries.sort(key=lambda item: (-item[0], item[1]))
    print(
        "ENTRY,rank,pc,mean_time_share," +
        ",".join(f"{label}_samples,{label}_corrected_ns,{label}_share" for label in labels)
    )
    for rank, (mean_share, pc) in enumerate(ranked_entries[: args.entry_limit], 1):
        print(
            f"ENTRY,{rank},{pc:08x},{mean_share:.6f}," +
            ",".join(
                f"{data[label].samples[pc]},{data[label].corrected_ns[pc]},"
                f"{data[label].corrected_ns[pc] / total_time[label]:.6f}"
                for label in labels
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
