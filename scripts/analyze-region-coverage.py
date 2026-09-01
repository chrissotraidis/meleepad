#!/usr/bin/env python3
"""Rank fixed guest-code regions and screen projected whole-frame gain."""

from __future__ import annotations

import argparse
import csv
from collections import Counter
from pathlib import Path


def positive_int(value: str) -> int:
    parsed = int(value, 0)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def fraction(value: str) -> float:
    parsed = float(value)
    if not 0.0 < parsed <= 1.0:
        raise argparse.ArgumentTypeError("fraction must be greater than 0 and at most 1")
    return parsed


def load_samples(path: Path, first_frame: int, last_frame: int, region_size: int) -> Counter[int]:
    regions: Counter[int] = Counter()
    with path.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        if rows.fieldnames is None or not {"frame", "pc"}.issubset(rows.fieldnames):
            raise ValueError("sample CSV must contain frame and pc columns")
        for row in rows:
            frame = int(row["frame"])
            if first_frame <= frame <= last_frame:
                pc = int(row["pc"], 16)
                regions[(pc // region_size) * region_size] += 1
    return regions


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sample_csv", type=Path)
    parser.add_argument("--first-frame", type=positive_int, required=True)
    parser.add_argument("--last-frame", type=positive_int, required=True)
    parser.add_argument("--region-size", type=positive_int, default=0x4000)
    parser.add_argument("--local-gain", type=fraction, default=0.35)
    parser.add_argument("--target-whole-gain", type=fraction, default=0.25)
    parser.add_argument("--limit", type=positive_int, default=20)
    args = parser.parse_args()

    if args.first_frame > args.last_frame:
        parser.error("first frame must not exceed last frame")
    if args.target_whole_gain > args.local_gain:
        parser.error("target whole-frame gain cannot exceed local gain")

    try:
        regions = load_samples(
            args.sample_csv, args.first_frame, args.last_frame, args.region_size
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))
    total = sum(regions.values())
    if total == 0:
        parser.error("selected frame interval has no samples")

    required_coverage = args.target_whole_gain / args.local_gain
    cumulative = 0
    required_regions = 0
    ranked = regions.most_common()
    for required_regions, (_, samples) in enumerate(ranked, 1):
        cumulative += samples
        if cumulative / total >= required_coverage:
            break

    print(
        "SUMMARY,"
        f"samples={total},regions={len(regions)},region_size=0x{args.region_size:x},"
        f"local_gain={args.local_gain:.6f},target_whole_gain={args.target_whole_gain:.6f},"
        f"required_coverage={required_coverage:.6f},required_regions={required_regions},"
        f"selected_coverage={cumulative / total:.6f},"
        f"projected_whole_gain={(cumulative / total) * args.local_gain:.6f}"
    )
    print("rank,start,end,samples,coverage,cumulative_coverage,projected_whole_gain")
    cumulative = 0
    for rank, (start, samples) in enumerate(ranked[: args.limit], 1):
        cumulative += samples
        coverage = samples / total
        cumulative_coverage = cumulative / total
        print(
            f"{rank},{start:08x},{start + args.region_size:08x},{samples},"
            f"{coverage:.6f},{cumulative_coverage:.6f},"
            f"{cumulative_coverage * args.local_gain:.6f}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
