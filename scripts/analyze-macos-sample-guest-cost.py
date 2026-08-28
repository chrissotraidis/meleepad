#!/usr/bin/env python3
"""Map direct generated-function samples from macOS `sample` to guest PCs.

This is deliberately a cost-selection tool, not an acceptance metric. It reads
line-attributed sample output and the matching generated C tree, then aggregates
only direct children of chassis_dispatch. Nested runtime/helper samples remain
charged to their generated caller by macOS `sample`'s inclusive count.
"""

from __future__ import annotations

import argparse
import bisect
import collections
import pathlib
import re
import sys


DIRECT_GENERATED = re.compile(
    r"^\s*\+ ! : \| (?P<count>\d+) (?P<function>func_[0-9A-Fa-f]+)\b"
    r".*? (?P<source>chunk_[^ :]+\.c):(?P<line>\d+)\s*$"
)
GUEST_INSTRUCTION = re.compile(r"^\s*//\s*(?P<pc>[0-9A-Fa-f]{8}):\s*(?P<opcode>\S+)")
SYMBOL = re.compile(
    r"^(?P<name>[^=]+?)\s*=\s*[^:]+:0x(?P<address>[0-9A-Fa-f]+);"
    r".*\btype:function\b.*\bsize:0x(?P<size>[0-9A-Fa-f]+)\b"
)


def read_symbols(path: pathlib.Path) -> list[tuple[int, int, str]]:
    symbols: list[tuple[int, int, str]] = []
    with path.open(encoding="utf-8", errors="replace") as source:
        for text in source:
            match = SYMBOL.match(text)
            if not match:
                continue
            start = int(match.group("address"), 16)
            size = int(match.group("size"), 16)
            if size != 0:
                symbols.append((start, start + size, match.group("name").strip()))
    return sorted(symbols)


def containing_symbol(
    pc: int, symbols: list[tuple[int, int, str]]
) -> tuple[int, int, str] | None:
    # The GALE01 map is small enough that a linear walk keeps this tool simple
    # and deterministic; stop as soon as starts have passed the requested PC.
    found: tuple[int, int, str] | None = None
    for symbol in symbols:
        if symbol[0] > pc:
            break
        if pc < symbol[1]:
            found = symbol
    return found


def source_map(path: pathlib.Path) -> dict[int, tuple[int, str]]:
    """Return source-line -> most recent guest PC/opcode."""
    mapping: dict[int, tuple[int, str]] = {}
    current: tuple[int, str] | None = None
    with path.open(encoding="utf-8") as source:
        for number, text in enumerate(source, 1):
            match = GUEST_INSTRUCTION.match(text)
            if match:
                current = (int(match.group("pc"), 16), match.group("opcode"))
            if current is not None:
                mapping[number] = current
    return mapping


def generated_instructions(root: pathlib.Path) -> list[tuple[int, str]]:
    instructions: list[tuple[int, str]] = []
    for path in sorted(root.glob("chunk_*.c")):
        with path.open(encoding="utf-8", errors="replace") as source:
            for text in source:
                match = GUEST_INSTRUCTION.match(text)
                if match:
                    instructions.append((int(match.group("pc"), 16), match.group("opcode")))
    return sorted(instructions)


def parse_samples(
    sample_path: pathlib.Path, generated_root: pathlib.Path
) -> tuple[collections.Counter[tuple[str, int, str]], collections.Counter[str], int, int]:
    pc_samples: collections.Counter[tuple[str, int, str]] = collections.Counter()
    function_samples: collections.Counter[str] = collections.Counter()
    maps: dict[pathlib.Path, dict[int, tuple[int, str]]] = {}
    mapped = 0
    unmapped = 0

    with sample_path.open(encoding="utf-8", errors="replace") as sample:
        for text in sample:
            match = DIRECT_GENERATED.match(text.rstrip("\n"))
            if not match:
                continue
            count = int(match.group("count"))
            function = match.group("function")
            function_samples[function] += count
            line = int(match.group("line"))
            path = generated_root / match.group("source")
            if line == 0 or not path.is_file():
                unmapped += count
                continue
            if path not in maps:
                maps[path] = source_map(path)
            guest = maps[path].get(line)
            if guest is None:
                unmapped += count
                continue
            pc, opcode = guest
            pc_samples[(function, pc, opcode)] += count
            mapped += count

    return pc_samples, function_samples, mapped, unmapped


def make_clusters(
    pc_samples: collections.Counter[tuple[str, int, str]], maximum_gap: int
) -> list[tuple[int, str, int, int, int, int]]:
    by_function: dict[str, list[tuple[int, int]]] = collections.defaultdict(list)
    for (function, pc, _opcode), count in pc_samples.items():
        by_function[function].append((pc, count))

    clusters: list[tuple[int, str, int, int, int, int]] = []
    for function, entries in by_function.items():
        entries.sort()
        start = end = entries[0][0]
        samples = entries[0][1]
        pcs = 1
        for pc, count in entries[1:]:
            if pc - end <= maximum_gap:
                end = pc
                samples += count
                pcs += 1
            else:
                clusters.append((samples, function, start, end, pcs, end - start + 4))
                start = end = pc
                samples = count
                pcs = 1
        clusters.append((samples, function, start, end, pcs, end - start + 4))
    return sorted(clusters, reverse=True)


def positive_int(value: str) -> int:
    parsed = int(value, 0)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return parsed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sample", type=pathlib.Path)
    parser.add_argument("generated_root", type=pathlib.Path)
    parser.add_argument("--top", type=positive_int, default=20)
    parser.add_argument("--cluster-gap", type=positive_int, default=0x40)
    parser.add_argument("--symbols", type=pathlib.Path)
    args = parser.parse_args()

    if not args.sample.is_file():
        parser.error(f"sample does not exist: {args.sample}")
    if not args.generated_root.is_dir():
        parser.error(f"generated root does not exist: {args.generated_root}")
    if args.symbols is not None and not args.symbols.is_file():
        parser.error(f"symbol map does not exist: {args.symbols}")

    pc_samples, function_samples, mapped, unmapped = parse_samples(
        args.sample, args.generated_root
    )
    if not function_samples:
        print("no direct generated samples found", file=sys.stderr)
        return 1

    print("summary,mapped_samples,unmapped_samples")
    print(f"summary,{mapped},{unmapped}")
    print("\nrank,function,inclusive_samples")
    for rank, (function, count) in enumerate(function_samples.most_common(args.top), 1):
        print(f"{rank},{function},{count}")

    print("\nrank,function,guest_pc,opcode,inclusive_samples")
    for rank, ((function, pc, opcode), count) in enumerate(pc_samples.most_common(args.top), 1):
        print(f"{rank},{function},0x{pc:08X},{opcode},{count}")

    opcode_samples: collections.Counter[str] = collections.Counter()
    for (_function, _pc, opcode), count in pc_samples.items():
        opcode_samples[opcode] += count
    print("\nrank,opcode,inclusive_samples")
    for rank, (opcode, count) in enumerate(opcode_samples.most_common(args.top), 1):
        print(f"{rank},{opcode},{count}")

    print("\nrank,function,start_pc,end_pc,distinct_sampled_pcs,span_bytes,inclusive_samples")
    for rank, (count, function, start, end, pcs, span) in enumerate(
        make_clusters(pc_samples, args.cluster_gap)[: args.top], 1
    ):
        print(f"{rank},{function},0x{start:08X},0x{end:08X},{pcs},{span},{count}")

    if args.symbols is not None:
        symbols = read_symbols(args.symbols)
        instructions = generated_instructions(args.generated_root)
        instruction_pcs = [pc for pc, _opcode in instructions]
        direct_call_prefix = [0]
        indirect_call_prefix = [0]
        for _pc, opcode in instructions:
            direct_call_prefix.append(direct_call_prefix[-1] + (opcode == "bl"))
            indirect_call_prefix.append(indirect_call_prefix[-1] + (opcode == "blrl"))
        symbol_samples: collections.Counter[tuple[str, int, int]] = collections.Counter()
        unresolved = 0
        for (_function, pc, _opcode), count in pc_samples.items():
            symbol = containing_symbol(pc, symbols)
            if symbol is None:
                unresolved += count
                continue
            start, end, name = symbol
            symbol_samples[(name, start, end)] += count

        print(
            "\nrank,symbol,start_pc,end_pc,size_bytes,inclusive_samples,"
            "mapped_share_percent,guest_instructions,direct_calls,indirect_calls"
        )
        for rank, ((name, start, end), count) in enumerate(
            symbol_samples.most_common(args.top), 1
        ):
            share = count * 100.0 / mapped if mapped else 0.0
            first = bisect.bisect_left(instruction_pcs, start)
            last = bisect.bisect_left(instruction_pcs, end)
            direct_calls = direct_call_prefix[last] - direct_call_prefix[first]
            indirect_calls = indirect_call_prefix[last] - indirect_call_prefix[first]
            print(
                f"{rank},{name},0x{start:08X},0x{end - 4:08X},"
                f"{end - start},{count},{share:.6f},{last - first},"
                f"{direct_calls},{indirect_calls}"
            )
        print(f"symbol_summary,resolved_samples,{mapped - unresolved}")
        print(f"symbol_summary,unresolved_samples,{unresolved}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
