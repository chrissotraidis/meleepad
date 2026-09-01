#!/usr/bin/env python3
"""Rank guest regions and PCs by candidate-minus-control samples per frame."""

from __future__ import annotations

import argparse
import csv
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Samples:
    regions: Counter[int]
    pcs: Counter[int]
    frames: int


def positive_int(value: str) -> int:
    parsed = int(value, 0)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def load_samples(path: Path, first_frame: int, last_frame: int, region_size: int) -> Samples:
    regions: Counter[int] = Counter()
    pcs: Counter[int] = Counter()
    frames: set[int] = set()
    with path.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        if rows.fieldnames is None or not {"frame", "pc"}.issubset(rows.fieldnames):
            raise ValueError("sample CSV must contain frame and pc columns")
        for row in rows:
            frame = int(row["frame"])
            if first_frame <= frame <= last_frame:
                pc = int(row["pc"], 16)
                frames.add(frame)
                pcs[pc] += 1
                regions[(pc // region_size) * region_size] += 1
    if not frames:
        raise ValueError("selected frame interval has no samples")
    return Samples(regions, pcs, len(frames))


def positive_deltas(
    candidate: Counter[int], candidate_frames: int, control: Counter[int], control_frames: int
) -> list[tuple[int, float, float, float]]:
    ranked = []
    for address in candidate.keys() | control.keys():
        candidate_rate = candidate[address] / candidate_frames
        control_rate = control[address] / control_frames
        delta = candidate_rate - control_rate
        if delta > 0.0:
            ranked.append((address, candidate_rate, control_rate, delta))
    return sorted(ranked, key=lambda row: (-row[3], row[0]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate_csv", type=Path)
    parser.add_argument("control_csv", type=Path)
    parser.add_argument("--candidate-first-frame", type=positive_int, required=True)
    parser.add_argument("--candidate-last-frame", type=positive_int, required=True)
    parser.add_argument("--control-first-frame", type=positive_int, required=True)
    parser.add_argument("--control-last-frame", type=positive_int, required=True)
    parser.add_argument("--region-size", type=positive_int, default=0x4000)
    parser.add_argument("--limit", type=positive_int, default=20)
    parser.add_argument("--pc-limit", type=positive_int, default=20)
    args = parser.parse_args()

    if args.candidate_first_frame > args.candidate_last_frame:
        parser.error("candidate first frame must not exceed last frame")
    if args.control_first_frame > args.control_last_frame:
        parser.error("control first frame must not exceed last frame")

    try:
        candidate = load_samples(
            args.candidate_csv,
            args.candidate_first_frame,
            args.candidate_last_frame,
            args.region_size,
        )
        control = load_samples(
            args.control_csv,
            args.control_first_frame,
            args.control_last_frame,
            args.region_size,
        )
    except (OSError, ValueError) as error:
        parser.error(str(error))

    candidate_rate = sum(candidate.regions.values()) / candidate.frames
    control_rate = sum(control.regions.values()) / control.frames
    total_delta = candidate_rate - control_rate
    if total_delta <= 0.0:
        parser.error("candidate interval has no positive total sample-rate delta")

    region_deltas = positive_deltas(
        candidate.regions, candidate.frames, control.regions, control.frames
    )
    print(
        "SUMMARY,"
        f"candidate_frames={candidate.frames},control_frames={control.frames},"
        f"candidate_samples_per_frame={candidate_rate:.6f},"
        f"control_samples_per_frame={control_rate:.6f},delta_per_frame={total_delta:.6f},"
        f"region_size=0x{args.region_size:x}"
    )
    print(
        "REGIONS,rank,start,end,candidate_per_frame,control_per_frame,"
        "delta_per_frame,cumulative_delta_coverage"
    )
    cumulative = 0.0
    for rank, (start, candidate_value, control_value, delta) in enumerate(
        region_deltas[: args.limit], 1
    ):
        cumulative += delta
        print(
            f"REGION,{rank},{start:08x},{start + args.region_size:08x},"
            f"{candidate_value:.6f},{control_value:.6f},{delta:.6f},"
            f"{cumulative / total_delta:.6f}"
        )

    print("PCS,rank,pc,candidate_per_frame,control_per_frame,delta_per_frame")
    pc_deltas = positive_deltas(candidate.pcs, candidate.frames, control.pcs, control.frames)
    for rank, (pc, candidate_value, control_value, delta) in enumerate(
        pc_deltas[: args.pc_limit], 1
    ):
        print(
            f"PC,{rank},{pc:08x},{candidate_value:.6f},{control_value:.6f},{delta:.6f}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
