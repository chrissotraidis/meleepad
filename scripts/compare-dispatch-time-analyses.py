#!/usr/bin/env python3
"""Find generated-code regions with stable host-time share across captures."""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class RegionShare:
    minimum: float
    maximum: float
    windows: dict[str, float]


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


def load_regions(path: Path) -> dict[int, RegionShare]:
    regions: dict[int, RegionShare] = {}
    region_header: list[str] | None = None
    with path.open(newline="", encoding="utf-8") as stream:
        rows = csv.reader(stream)
        for row in rows:
            if not row or row[0] != "REGION":
                continue
            if row[1] == "rank":
                region_header = row
                continue
            if len(row) < 6 or region_header is None:
                raise ValueError(f"malformed region row in {path}")
            start = int(row[2], 16)
            if start in regions:
                raise ValueError(f"duplicate region {start:08x} in {path}")
            windows = {
                name.removesuffix("_share"): float(row[index])
                for index, name in enumerate(region_header)
                if index >= 6 and name.endswith("_share")
            }
            if not windows:
                raise ValueError(f"region analysis has no per-window shares: {path}")
            regions[start] = RegionShare(float(row[4]), float(row[5]), windows)
    if not regions:
        raise ValueError(f"analysis contains no region rows: {path}")
    return regions


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--analysis", action="append", nargs=2, metavar=("LABEL", "CSV"), required=True
    )
    parser.add_argument("--maximum-share-ratio", type=positive_float, default=1.25)
    parser.add_argument("--target-coverage", type=fraction, default=0.70)
    parser.add_argument("--region-size", type=lambda value: int(value, 0), default=0x4000)
    parser.add_argument("--region-limit", type=int, default=30)
    args = parser.parse_args()

    if args.maximum_share_ratio < 1.0:
        parser.error("maximum share ratio must be at least 1")
    if args.region_size <= 0 or args.region_limit <= 0:
        parser.error("region size and limit must be positive")

    labels = [label for label, _ in args.analysis]
    if len(labels) != len(set(labels)):
        parser.error("analysis labels must be unique")
    try:
        captures = {
            label: load_regions(Path(path)) for label, path in args.analysis
        }
    except (OSError, ValueError) as error:
        parser.error(str(error))

    common = set.intersection(*(set(regions) for regions in captures.values()))
    stable: list[tuple[float, int, float, float, dict[str, RegionShare]]] = []
    for start in common:
        shares = {label: captures[label][start] for label in labels}
        window_names = [set(share.windows) for share in shares.values()]
        if any(names != window_names[0] for names in window_names[1:]):
            parser.error(f"window labels differ for region {start:08x}")
        minimum = min(share.minimum for share in shares.values())
        maximum = max(share.maximum for share in shares.values())
        matched_ratios = []
        for window in window_names[0]:
            values = [share.windows[window] for share in shares.values()]
            if min(values) <= 0.0:
                matched_ratios.append(float("inf"))
            else:
                matched_ratios.append(max(values) / min(values))
        maximum_matched_ratio = max(matched_ratios)
        if minimum > 0.0 and maximum_matched_ratio <= args.maximum_share_ratio:
            stable.append((minimum, start, maximum, maximum_matched_ratio, shares))
    stable.sort(key=lambda item: (-item[0], item[1]))

    coverage = 0.0
    selected = 0
    for selected, (minimum, _, _, _, _) in enumerate(stable, 1):
        coverage += minimum
        if coverage >= args.target_coverage:
            break
    reached = coverage >= args.target_coverage
    if not stable:
        selected = 0
    elif not reached:
        selected = len(stable)

    print(
        "SUMMARY,"
        f"captures={len(labels)},stable_regions={len(stable)},"
        f"target_coverage={args.target_coverage:.6f},"
        f"maximum_share_ratio={args.maximum_share_ratio:.6f},"
        f"selected_regions={selected},"
        f"selected_minimum_coverage={coverage:.6f},"
        f"coverage_gate={'PASS' if reached else 'FAIL'}"
    )
    print(
        "REGION,rank,start,end,min_share,max_share,route_range_ratio,"
        "max_matched_capture_ratio,"
        + ",".join(f"{label}_min_share,{label}_max_share" for label in labels)
        + ",selected"
    )
    for rank, (minimum, start, maximum, matched_ratio, shares) in enumerate(
        stable[: args.region_limit], 1
    ):
        print(
            f"REGION,{rank},{start:08x},{start + args.region_size:08x},"
            f"{minimum:.6f},{maximum:.6f},{maximum / minimum:.6f},"
            f"{matched_ratio:.6f},"
            + ",".join(
                f"{shares[label].minimum:.6f},{shares[label].maximum:.6f}"
                for label in labels
            )
            + f",{'yes' if rank <= selected else 'no'}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
