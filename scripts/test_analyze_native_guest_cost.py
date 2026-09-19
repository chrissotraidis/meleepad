#!/usr/bin/env python3
"""Synthetic fixtures only: no game code, traces, or device identifiers."""

import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import uuid
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location(
    "native_cost", Path(__file__).with_name("analyze-native-guest-cost.py")
)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
UUID = "00000000-0000-0000-0000-000000000001"


def frame(addr, module=True):
    binary = '<binary ref="module"/>' if module else '<binary name="host"/>'
    return f'<frame addr="{addr}">{binary}</frame>'


def row(frames, weight=1000000, thread="CPU thread"):
    return f'<row><thread fmt="{thread}"/><weight>{weight}</weight><tagged-backtrace><backtrace>{frames}</backtrace></tagged-backtrace></row>'


def trace(rows, image_uuid=UUID):
    return ET.fromstring(
        f'<trace><binary id="module" name="game.dylib" UUID="{image_uuid}" arch="arm64" load-addr="0x1000"/>{rows}</trace>'
    )


class NativeCostTest(unittest.TestCase):
    def test_each_sample_counted_once_and_unmapped_retained(self):
        rows = (
            row(frame("0x1010") + frame("0x1024"))
            + row(frame("0x9999", False) + frame("0x1024"), 2000000)
            + row(frame("0x9988", False), 3000000)
            + row(frame("0x1010"), 5000000, "GPU thread")
        )
        result = m.analyze(
            trace(rows),
            "game.dylib",
            UUID,
            lambda addr: (addr, "same_name") if addr in (0x10, 0x20) else None,
        )
        self.assertEqual(result["cpu_ms"], 6)
        self.assertEqual(result["mapped_ms"], 3)
        self.assertEqual(result["unmapped_ms"], 3)
        # Same names at different guest addresses must not be merged.
        self.assertEqual(
            {f["address"] for f in result["functions"]}, {"00000010", "00000020"}
        )
        self.assertEqual(result["functions"][0]["ms"], 2)

    def test_uuid_mismatch_rejected(self):
        with self.assertRaisesRegex(ValueError, "UUID"):
            m.analyze(
                trace(row(frame("0x1010")), UUID[:-1] + "2"),
                "game.dylib",
                UUID,
                lambda _: (1, "fake"),
            )

    def test_missing_module_rejected(self):
        with self.assertRaisesRegex(ValueError, "no matching"):
            m.analyze(
                trace(row(frame("0x1010", False))), "game.dylib", UUID, lambda _: None
            )

    def test_referenced_rows_and_call_address(self):
        root = trace(
            '<thread id="t" fmt="CPU thread"/><weight id="w">1000000</weight><backtrace id="bt">'
            + frame("0x8888", False)
            + frame("0x1014")
            + '</backtrace><row><thread ref="t"/><weight ref="w"/><tagged-backtrace><backtrace ref="bt"/></tagged-backtrace></row>'
        )
        observed = []

        def lookup(addr):
            observed.append(addr)
            return (3, "example")

        m.analyze(root, "game.dylib", UUID, lookup)
        self.assertEqual(observed, [0x10])

    def test_line_zero_inline_and_end_sequence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "chunk_example.c").write_text(
                "label_80001000:\n  // 80001000: example\n  helper();\nreturn_dispatch_example:\n"
            )
            symbols = root / "symbols.txt"
            symbols.write_text(
                "example = .text:0x80001000; // type:function size:0x10\n"
            )
            lines = """debug_line[0x0]
file_names[ 1]:
 name: "chunk_example.c"
0x00000010 2 0 1 0 0 0 is_stmt
0x00000014 0 0 1 0 0 0
0x00000018 4 0 1 0 0 0
0x00000020 4 0 1 0 0 0 end_sequence
"""
            info = """0x0001: DW_TAG_inlined_subroutine
 DW_AT_call_file ("/private/chunk_example.c")
 DW_AT_call_line (3)
 DW_AT_low_pc (0x00000014)
 DW_AT_high_pc (0x00000018)
"""
            lookup = m.SourceLookup(lines, info, root, symbols)
            self.assertEqual(lookup(0x10), (0x80001000, "example"))
            self.assertEqual(lookup(0x14), (0x80001000, "example"))
            self.assertIsNone(lookup(0x18))
            self.assertIsNone(lookup(0x20))

    def test_macho_section_identity_and_truncation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "synthetic"
            header = struct.pack("<8I", 0xFEEDFACF, 0x0100000C, 0, 6, 2, 176, 0, 0)
            segment = struct.pack(
                "<II16sQQQQIIII", 0x19, 152, b"__TEXT", 0, 4096, 0, 212, 7, 5, 1, 0
            )
            section = struct.pack(
                "<16s16sQQIIIIIIII",
                b"__text",
                b"__TEXT",
                0x100,
                4,
                208,
                2,
                0,
                0,
                0,
                0,
                0,
                0,
            )
            data = (
                header
                + segment
                + section
                + struct.pack("<II", 0x1B, 24)
                + uuid.UUID(UUID).bytes
                + b"1234"
            )
            path.write_bytes(data)
            image_uuid, sections = m.macho_identity(path)
            self.assertEqual(image_uuid, UUID)
            self.assertEqual(sections["__text"]["length"], 4)
            path.write_bytes(data[:-2])
            with self.assertRaisesRegex(ValueError, "truncated text"):
                m.macho_identity(path)


if __name__ == "__main__":
    unittest.main()
