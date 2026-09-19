#!/usr/bin/env python3
"""Attribute arm64 Time Profiler samples to decompiled guest functions.

Read-only, offline analysis. Requires the exact generated source tree used by
an equivalent debug rebuild; DWARF v4 does not authenticate source contents.
Machine code, image UUIDs and addresses are checked before attribution. Output
contains aggregate costs, not traces, device paths, or predicted FPS gains.
"""

from __future__ import annotations

import argparse
import bisect
import collections
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
import uuid
import xml.etree.ElementTree as ET


def macho_identity(path: Path) -> tuple[str, dict]:
    data = path.read_bytes()
    if len(data) < 32 or struct.unpack_from("<II", data) != (0xFEEDFACF, 0x0100000C):
        raise ValueError("expected a thin little-endian arm64 Mach-O")
    count, command_bytes = struct.unpack_from("<II", data, 16)
    end = 32 + command_bytes
    if end > len(data):
        raise ValueError("truncated Mach-O commands")
    pos, image_uuid, sections = 32, None, {}
    for _ in range(count):
        if pos + 8 > end:
            raise ValueError("truncated Mach-O command")
        cmd, size = struct.unpack_from("<II", data, pos)
        if size < 8 or pos + size > end:
            raise ValueError("invalid Mach-O command size")
        if cmd == 0x1B and size >= 24:
            image_uuid = str(uuid.UUID(bytes=data[pos + 8 : pos + 24])).upper()
        if cmd == 0x19:
            if size < 72:
                raise ValueError("truncated segment")
            nsects = struct.unpack_from("<I", data, pos + 64)[0]
            if 72 + nsects * 80 > size:
                raise ValueError("truncated sections")
            for i in range(nsects):
                p = pos + 72 + 80 * i
                name = data[p : p + 16].split(b"\0")[0].decode()
                segment = data[p + 16 : p + 32].split(b"\0")[0].decode()
                address, length, offset = struct.unpack_from("<QQI", data, p + 32)
                if segment == "__TEXT":
                    if offset + length > len(data):
                        raise ValueError("truncated text section")
                    sections[name] = dict(
                        address=address,
                        length=length,
                        sha256=hashlib.sha256(
                            data[offset : offset + length]
                        ).hexdigest(),
                    )
        pos += size
    if not image_uuid or "__text" not in sections:
        raise ValueError("missing UUID or executable section")
    return image_uuid, sections


def source_map(path: Path) -> dict[int, int]:
    result, pc = {}, None
    for n, line in enumerate(path.read_text().splitlines(), 1):
        match = re.match(r"(?:label_|\s*// )([A-Fa-f0-9]{8}):", line)
        if match:
            pc = int(match[1], 16)
        if re.match(r"(return_dispatch_|void func_|static )", line):
            pc = None
        if pc is not None:
            result[n] = pc
    return result


def line_ranges(text: str) -> list[tuple]:
    result, files, file_id, previous = [], {}, None, None
    for line in text.splitlines():
        if line.startswith("debug_line["):
            files, previous = {}, None
        match = re.match(r"file_names\[\s*(\d+)\]:", line)
        if match:
            file_id = int(match[1])
        match = re.match(r'\s+name: "(.*)"', line)
        if match:
            files[file_id] = Path(match[1]).name
        match = re.match(r"(0x[0-9a-f]+)\s+(\d+)\s+\d+\s+(\d+)\s+", line)
        if not match:
            continue
        address, n, f = int(match[1], 16), int(match[2]), int(match[3])
        if previous and address > previous[0]:
            result.append((*previous, address))
        previous = None if "end_sequence" in line else (address, files.get(f, "?"), n)
    return sorted(result)


class SourceLookup:
    def __init__(self, lines: str, info: str, generated: Path, symbols: Path):
        self.ranges = line_ranges(lines)
        self.starts = [r[0] for r in self.ranges]
        needed = {r[1] for r in self.ranges}
        self.sources = {
            p.name: source_map(p) for p in generated.glob("*.c") if p.name in needed
        }
        self.symbols = []
        for line in symbols.read_text().splitlines():
            m = re.match(
                r"(.*?) = \.text:0x([0-9a-fA-F]+);.*type:function size:0x([0-9a-fA-F]+)",
                line,
            )
            if m and int(m[3], 16):
                start = int(m[2], 16)
                self.symbols.append((start, start + int(m[3], 16), m[1]))
        self.symbols.sort()
        self.symbol_starts = [s[0] for s in self.symbols]
        self.inlines = collections.defaultdict(list)
        for entry in re.split(r"(?m)^0x[0-9a-f]+:", info):
            if not entry.lstrip().startswith("DW_TAG_inlined_subroutine"):
                continue
            f = re.search(r'DW_AT_call_file\s+\("([^"]+)"\)', entry)
            n = re.search(r"DW_AT_call_line\s+\((\d+)\)", entry)
            if not f or not n:
                continue
            pc = self.sources.get(Path(f[1]).name, {}).get(int(n[1]))
            if pc is None:
                continue
            spans = [
                (int(a, 16), int(b, 16))
                for a, b in re.findall(r"\[(0x[0-9a-f]+), (0x[0-9a-f]+)\)", entry)
            ]
            if not spans:
                lo = re.search(r"DW_AT_low_pc\s+\((0x[0-9a-f]+)\)", entry)
                hi = re.search(r"DW_AT_high_pc\s+\((0x[0-9a-f]+)\)", entry)
                if lo and hi:
                    spans = [(int(lo[1], 16), int(hi[1], 16))]
            for start, end in spans:
                for bucket in range(start >> 12, ((end - 1) >> 12) + 1):
                    self.inlines[bucket].append((start, end, pc))

    def __call__(self, address: int) -> tuple[int, str] | None:
        pc = None
        i = bisect.bisect_right(self.starts, address) - 1
        if i >= 0:
            start, file, n, end = self.ranges[i]
            if start <= address < end:
                pc = self.sources.get(file, {}).get(n)
        if pc is None:
            matches = [
                r for r in self.inlines.get(address >> 12, ()) if r[0] <= address < r[1]
            ]
            if matches:
                pc = min(matches, key=lambda r: r[1] - r[0])[2]
        if pc is None:
            return None
        i = bisect.bisect_right(self.symbol_starts, pc) - 1
        if i < 0 or pc >= self.symbols[i][1]:
            return None
        start, _, name = self.symbols[i]
        return start, name


def analyze(root: ET.Element, image_name: str, image_uuid: str, lookup) -> dict:
    ids = {e.get("id"): e for e in root.iter() if e.get("id")}

    def deref(e):
        if e is None:
            raise ValueError("missing trace element")
        return ids[e.get("ref")] if e.get("ref") else e

    counts, total_ns, matched_image = collections.Counter(), 0, False
    for row in root.iter("row"):
        fields = {e.tag: deref(e) for e in row}
        if "tagged-backtrace" not in fields or not fields.get(
            "thread", ET.Element("thread")
        ).get("fmt", "").startswith("CPU thread"):
            continue
        weight = int(fields["weight"].text)
        if weight < 0:
            raise ValueError("negative trace sample weight")
        total_ns += weight
        frames = [deref(f) for f in deref(fields["tagged-backtrace"].find("backtrace"))]
        for i, frame in enumerate(frames):
            binary = frame.find("binary")
            if binary is None:
                continue
            binary = deref(binary)
            if binary.get("name") != image_name:
                continue
            if (
                binary.get("UUID", "").upper() != image_uuid.upper()
                or binary.get("arch") != "arm64"
            ):
                raise ValueError(
                    "sampled module UUID/architecture does not match baseline"
                )
            matched_image = True
            # arm64 caller PCs point after BL; leaf PCs name the sampled instruction.
            address = (
                int(frame.get("addr"), 16) - int(binary.get("load-addr"), 16)
            ) & ~3
            found = lookup(address - (4 if i else 0))
            if found is not None:
                counts[found] += weight
                break  # Charge each CPU sample exactly once, even with multiple callers.
    if not total_ns or not matched_image:
        raise ValueError("no matching CPU-thread/module samples")
    mapped = sum(counts.values())
    return dict(
        cpu_ms=total_ns / 1e6,
        mapped_ms=mapped / 1e6,
        mapped_percent=100 * mapped / total_ns,
        unmapped_ms=(total_ns - mapped) / 1e6,
        functions=[
            dict(
                address=f"{pc:08x}",
                name=name,
                ms=ns / 1e6,
                percent_cpu=100 * ns / total_ns,
            )
            for (pc, name), ns in counts.most_common()
        ],
    )


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    for flag in (
        "trace-xml",
        "baseline",
        "debug-module",
        "dsym",
        "generated",
        "symbols",
    ):
        p.add_argument("--" + flag, type=Path, required=True)
    p.add_argument("--image-name", default="gGALE01r2_recomp.dylib")
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    baseline_uuid, baseline_sections = macho_identity(a.baseline)
    debug_uuid, debug_sections = macho_identity(a.debug_module)
    if baseline_sections != debug_sections:
        raise ValueError("debug rebuild __TEXT bytes or addresses differ from baseline")
    dsym_uuid = subprocess.check_output(
        ["xcrun", "dwarfdump", "--uuid", str(a.dsym)], text=True
    )
    if f"UUID: {debug_uuid} (arm64)" not in dsym_uuid:
        raise ValueError("dSYM does not match debug module")
    lines = subprocess.check_output(
        ["xcrun", "llvm-dwarfdump", "--debug-line", str(a.dsym)], text=True
    )
    info = subprocess.check_output(
        ["xcrun", "llvm-dwarfdump", "--debug-info", str(a.dsym)], text=True
    )
    lookup = SourceLookup(lines, info, a.generated, a.symbols)
    result = analyze(
        ET.parse(a.trace_xml).getroot(), a.image_name, baseline_uuid, lookup
    )
    result["text_sha256"] = baseline_sections["__text"]["sha256"]
    result["scope"] = (
        "Source-attributed CPU samples; not removable time or predicted FPS. Exact matching generated source required."
    )
    a.output.write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"Mapped {result['mapped_percent']:.2f}% of CPU samples; remaining samples explicitly unassigned."
    )


if __name__ == "__main__":
    try:
        main()
    except (
        ValueError,
        KeyError,
        OSError,
        ET.ParseError,
        subprocess.CalledProcessError,
    ) as error:
        sys.exit(str(error))
