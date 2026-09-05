#!/usr/bin/env python3
"""Summarize MeleePad phase metrics over emulated-frame windows."""

from __future__ import annotations

import argparse
import csv
import statistics
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Window:
    label: str
    start: int
    end: int


METRICS = (
    "total_ms",
    "cpu_thread_ms",
    "video_build_ms",
    "present_ms",
    "static_cycles",
    "static_native_dispatches",
    "draw_calls",
    "primitives",
)


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase_csv", type=Path)
    parser.add_argument(
        "--window", action="append", nargs=3,
        metavar=("LABEL", "START_EMULATED_FRAME", "END_EMULATED_FRAME"), required=True,
    )
    args = parser.parse_args()

    windows: list[Window] = []
    labels: set[str] = set()
    for label, start_text, end_text in args.window:
        start, end = int(start_text, 0), int(end_text, 0)
        if label in labels or start >= end:
            parser.error(f"invalid or duplicate window: {label}")
        labels.add(label)
        windows.append(Window(label, start, end))

    values = {
        window.label: {metric: [] for metric in METRICS} for window in windows
    }
    host_times = {window.label: [] for window in windows}
    try:
        with args.phase_csv.open(newline="", encoding="utf-8") as stream:
            rows = csv.DictReader(stream)
            required = {"emulated_frame", "host_frame_end_unix_ns", *METRICS}
            if rows.fieldnames is None or not required.issubset(rows.fieldnames):
                raise ValueError("phase CSV is missing required timing columns")
            for row in rows:
                try:
                    frame = int(row["emulated_frame"])
                    host_ns = int(row["host_frame_end_unix_ns"])
                    parsed = {metric: float(row[metric]) for metric in METRICS}
                except (TypeError, ValueError):
                    continue
                for window in windows:
                    if window.start <= frame < window.end:
                        host_times[window.label].append(host_ns)
                        for metric in METRICS:
                            values[window.label][metric].append(parsed[metric])
                        break
    except (OSError, ValueError) as error:
        parser.error(str(error))

    print(
        "WINDOW,label,rows,effective_fps,total_mean_ms,total_p95_ms,"
        "cpu_mean_ms,cpu_p95_ms,video_mean_ms,present_mean_ms,cycles_mean,"
        "dispatches_mean,draws_mean,primitives_mean"
    )
    for window in windows:
        label = window.label
        current = values[label]
        if not current["total_ms"]:
            parser.error(f"window {label} has no complete rows")
        elapsed_seconds = (
            (max(host_times[label]) - min(host_times[label])) / 1_000_000_000.0
            + statistics.fmean(current["total_ms"]) / 1000.0
        )
        rows = len(current["total_ms"])
        print(
            f"WINDOW,{label},{rows},{rows / elapsed_seconds:.6f},"
            f"{statistics.fmean(current['total_ms']):.6f},"
            f"{percentile(current['total_ms'], 0.95):.6f},"
            f"{statistics.fmean(current['cpu_thread_ms']):.6f},"
            f"{percentile(current['cpu_thread_ms'], 0.95):.6f},"
            f"{statistics.fmean(current['video_build_ms']):.6f},"
            f"{statistics.fmean(current['present_ms']):.6f},"
            f"{statistics.fmean(current['static_cycles']):.3f},"
            f"{statistics.fmean(current['static_native_dispatches']):.3f},"
            f"{statistics.fmean(current['draw_calls']):.3f},"
            f"{statistics.fmean(current['primitives']):.3f}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
