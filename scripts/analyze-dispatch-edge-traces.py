#!/usr/bin/env python3
"""Find deterministic hot chains in a sampled native-dispatch edge stream."""

from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Edge:
    source: str
    destination: str
    samples: int
    dominance: float


def parse_address(value: str) -> int:
    return int(value, 0)


def load_edges(path: Path, first_frame: int, last_frame: int) -> dict[str, Counter[str]]:
    outgoing: dict[str, Counter[str]] = defaultdict(Counter)
    with path.open(newline="", encoding="utf-8") as stream:
        rows = csv.DictReader(stream)
        expected = {"emulated_frame", "previous_pc", "pc"}
        if rows.fieldnames is None or not expected.issubset(rows.fieldnames):
            raise ValueError(f"{path} does not contain {sorted(expected)}")
        for row in rows:
            frame = int(row["emulated_frame"])
            if first_frame <= frame <= last_frame:
                source = row["previous_pc"].upper().removeprefix("0X")
                destination = row["pc"].upper().removeprefix("0X")
                outgoing[source][destination] += 1
    return outgoing


def dominant_edges(
    outgoing: dict[str, Counter[str]], minimum_samples: int, minimum_dominance: float
) -> dict[str, Edge]:
    result: dict[str, Edge] = {}
    for source, destinations in outgoing.items():
        total = sum(destinations.values())
        destination, samples = destinations.most_common(1)[0]
        dominance = samples / total
        if (
            source != destination
            and samples >= minimum_samples
            and dominance >= minimum_dominance
        ):
            result[source] = Edge(source, destination, samples, dominance)
    return result


def form_chains(edges: dict[str, Edge], maximum_nodes: int) -> list[list[Edge]]:
    incoming: dict[str, set[str]] = defaultdict(set)
    for edge in edges.values():
        incoming[edge.destination].add(edge.source)

    starts = sorted(source for source in edges if not incoming[source])
    # Cycles and chains whose head was filtered still need deterministic seeds.
    starts.extend(source for source in sorted(edges) if source not in starts)

    chains: list[list[Edge]] = []
    covered: set[str] = set()
    for start in starts:
        if start in covered:
            continue
        chain: list[Edge] = []
        local: set[str] = set()
        source = start
        while source in edges and source not in local and len(chain) + 1 < maximum_nodes:
            local.add(source)
            covered.add(source)
            edge = edges[source]
            chain.append(edge)
            source = edge.destination
        if chain:
            chains.append(chain)
    return chains


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("edge_csv", type=Path)
    parser.add_argument("--first-frame", type=parse_address, required=True)
    parser.add_argument("--last-frame", type=parse_address, required=True)
    parser.add_argument("--minimum-samples", type=int, default=20)
    parser.add_argument("--minimum-dominance", type=float, default=0.80)
    parser.add_argument("--maximum-nodes", type=int, default=16)
    parser.add_argument("--sample-period", type=int, default=4096)
    args = parser.parse_args()

    if args.first_frame > args.last_frame:
        parser.error("first frame must not exceed last frame")
    if args.minimum_samples <= 0:
        parser.error("minimum samples must be positive")
    if not 0.5 < args.minimum_dominance <= 1.0:
        parser.error("minimum dominance must be greater than 0.5 and at most 1")
    if args.maximum_nodes < 2:
        parser.error("maximum nodes must be at least 2")
    if args.sample_period <= 0:
        parser.error("sample period must be positive")

    try:
        outgoing = load_edges(args.edge_csv, args.first_frame, args.last_frame)
    except (OSError, ValueError) as error:
        parser.error(str(error))

    edges = dominant_edges(outgoing, args.minimum_samples, args.minimum_dominance)
    chains = form_chains(edges, args.maximum_nodes)
    chains.sort(
        key=lambda chain: (
            min(edge.samples for edge in chain),
            sum(edge.samples for edge in chain),
            len(chain),
            chain[0].source,
        ),
        reverse=True,
    )

    print(
        "rank,nodes,edge_count,bottleneck_samples,total_samples,"
        "minimum_dominance,estimated_bottleneck_transitions"
    )
    for rank, chain in enumerate(chains, 1):
        nodes = [chain[0].source, *(edge.destination for edge in chain)]
        bottleneck = min(edge.samples for edge in chain)
        print(
            f'{rank},{"->".join(nodes)},{len(chain)},{bottleneck},'
            f'{sum(edge.samples for edge in chain)},'
            f'{min(edge.dominance for edge in chain):.6f},'
            f'{bottleneck * args.sample_period}'
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
