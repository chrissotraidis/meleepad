#!/usr/bin/env python3
"""Annotate v1.02 guest addresses using the pinned completed decompilation.

Requires the matching private executable, so v1.00 traces cannot accidentally
be labeled with v1.02 symbols. Output contains names and offsets, never code.
"""
import argparse
import bisect
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = "ae5898ee0dfda41b34fdf846f7d680a33e14779d"


def load_symbols(text):
    symbols = []
    for line in text.splitlines():
        match = re.match(r"(\S+) = \.text:0x([0-9A-Fa-f]+);.*?size:0x([0-9A-Fa-f]+)", line)
        if match:
            name, address, size = match.groups()
            symbols.append((int(address, 16), int(size, 16), name))
    return sorted(symbols)


def describe(address, symbols):
    index = bisect.bisect_right([s[0] for s in symbols], address) - 1
    if index >= 0:
        start, size, name = symbols[index]
        if start <= address < start + size:
            return f"{name}+0x{address - start:X}"
    return "unknown"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dol", required=True, type=Path)
    parser.add_argument("--upstream", type=Path, default=ROOT / "ref/melee-complete")
    parser.add_argument("addresses", nargs="+", help="Hex guest PCs from a v1.02 trace")
    args = parser.parse_args()
    expected = next(r for r in json.loads((ROOT / "apple/shared/MeleePadRevisions.json").read_text()) if r["revision"] == 2)
    if hashlib.sha256(args.dol.read_bytes()).hexdigest() != expected["dol_sha256"]:
        parser.error("Executable is not the verified USA v1.02 target")
    # Read the exact committed map, even if the working tree is edited.
    text = subprocess.check_output(["git", "-C", str(args.upstream), "show",
                                    f"{UPSTREAM}:config/GALE01/symbols.txt"], text=True)
    symbols = load_symbols(text)
    for value in args.addresses:
        address = int(value, 16)
        print(f"0x{address:08X}\t{describe(address, symbols)}")


if __name__ == "__main__":
    main()
