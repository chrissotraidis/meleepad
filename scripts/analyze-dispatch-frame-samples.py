#!/usr/bin/env python3
"""Compare sampled native dispatch PCs in ordinary and p95-tail frame rows."""

from __future__ import annotations

import argparse
import csv
import math
from collections import Counter
from pathlib import Path


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase_csv", type=Path)
    parser.add_argument("sample_csv", type=Path)
    parser.add_argument("--start-frame", type=int, required=True)
    parser.add_argument("--end-frame", type=int, required=True)
    parser.add_argument("--limit", type=int, default=20)
    args = parser.parse_args()

    frame_ms: dict[int, float] = {}
    with args.phase_csv.open(newline="", encoding="utf-8") as phase_file:
        for row in csv.DictReader(phase_file):
            frame = int(row["frame"])
            if args.start_frame <= frame <= args.end_frame:
                frame_ms[frame] = float(row["total_ms"])
    if not frame_ms:
        parser.error("selected phase interval is empty")

    p50 = percentile(list(frame_ms.values()), 0.50)
    p95 = percentile(list(frame_ms.values()), 0.95)
    body_frames = {frame for frame, total in frame_ms.items() if total <= p50}
    tail_frames = {frame for frame, total in frame_ms.items() if total >= p95}

    body: Counter[int] = Counter()
    tail: Counter[int] = Counter()
    with args.sample_csv.open(newline="", encoding="utf-8") as sample_file:
        for row in csv.DictReader(sample_file):
            frame = int(row["frame"])
            pc = int(row["pc"], 16)
            if frame in body_frames:
                body[pc] += 1
            if frame in tail_frames:
                tail[pc] += 1

    body_total = sum(body.values())
    tail_total = sum(tail.values())
    if body_total == 0 or tail_total == 0:
        parser.error("selected body or tail has no dispatch samples")

    print(
        "SUMMARY,"
        f"frames={len(frame_ms)},body_frames={len(body_frames)},tail_frames={len(tail_frames)},"
        f"p50_ms={p50:.6f},p95_ms={p95:.6f},body_samples={body_total},tail_samples={tail_total},"
        f"body_samples_per_frame={body_total / len(body_frames):.3f},"
        f"tail_samples_per_frame={tail_total / len(tail_frames):.3f}"
    )
    print(
        "pc,body_samples,tail_samples,body_per_frame,tail_per_frame,delta_per_frame,"
        "estimated_extra_dispatches,body_per_1000,tail_per_1000,share_delta_per_1000,ratio"
    )
    ranked: list[tuple[float, int]] = []
    for pc in body.keys() | tail.keys():
        body_per_frame = body[pc] / len(body_frames)
        tail_per_frame = tail[pc] / len(tail_frames)
        ranked.append((tail_per_frame - body_per_frame, pc))
    for _, pc in sorted(ranked, reverse=True)[: args.limit]:
        body_per_frame = body[pc] / len(body_frames)
        tail_per_frame = tail[pc] / len(tail_frames)
        delta_per_frame = tail_per_frame - body_per_frame
        body_share = body[pc] * 1000.0 / body_total
        tail_share = tail[pc] * 1000.0 / tail_total
        ratio = tail_per_frame / body_per_frame if body_per_frame else math.inf
        ratio_text = "inf" if math.isinf(ratio) else f"{ratio:.3f}"
        print(
            f"{pc:08x},{body[pc]},{tail[pc]},{body_per_frame:.6f},{tail_per_frame:.6f},"
            f"{delta_per_frame:.6f},{delta_per_frame * 4096.0:.1f},{body_share:.3f},"
            f"{tail_share:.3f},{tail_share - body_share:.3f},{ratio_text}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
