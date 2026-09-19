#!/usr/bin/env python3
"""Focused controls for the item-event comparator."""
import csv
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location("item_trace", Path(__file__).with_name("analyze-slippi-item-trace.py"))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def frame(number, items=()):
    prefix = struct.pack(">i", number)
    packets = [
        bytes([0x3A]) + prefix + bytes(8),
        bytes([0x38]) + prefix + bytes([0, 0]) + bytes(78),
        bytes([0x38]) + prefix + bytes([1, 0]) + bytes(78),
    ]
    for item_type, lane_word, raw_28, raw_29 in items:
        packet = bytearray([0x3B]) + bytearray(prefix) + bytearray([0, item_type]) + bytearray(38)
        struct.pack_into(">I", packet, 0x18, lane_word)
        packet[0x28] = raw_28
        packet[0x29] = raw_29
        packets.append(bytes(packet))
    packets.append(bytes([0x3C]) + prefix + prefix)
    return [{"command": str(packet[0]), "payload": packet.hex()} for packet in packets]


class Controls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def write_run(self, left_items, right_items):
        run = self.root / "run"
        for side, items in (("user-0", left_items), ("user-1", right_items)):
            folder = run / side
            folder.mkdir(parents=True)
            rows = frame(-123, items)
            path = folder / "online-frame-packets.csv"
            with path.open("w") as file:
                writer = csv.DictWriter(file, fieldnames=["command", "payload"])
                writer.writeheader()
                writer.writerows(rows)
            (folder / "online-frame-trace.json").write_text(json.dumps({"packets": len(rows), "overflow": False}))
        return run

    def test_multiple_items_are_compared_in_order(self):
        run = self.write_run(
            [(0x4B, 0x3F800000, 0x80, 0x00), (0x37, 0x41021F33, 0x00, 0x4E)],
            [(0x4B, 0x3F800000, 0x20, 0x00), (0x37, 0x41021F32, 0x00, 0x00)],
        )
        result = MODULE.compare(run / "user-0/online-frame-packets.csv", run / "user-1/online-frame-packets.csv")
        self.assertFalse(result["pass"])
        self.assertEqual(result["item_packets"]["compared_pairs"], 2)
        self.assertEqual(result["first_item_packet_payload_mismatch"]["frame"], -123)
        self.assertEqual(result["raw_byte_mismatch_counts"]["0x3b:0x28"], 1)
        self.assertEqual(result["float_lane_mismatch_counts"]["0x18"], 1)
        self.assertEqual(result["one_ulp_float_difference_count"], 1)

    def test_count_mismatch_is_not_hidden(self):
        run = self.write_run(
            [(0x4B, 0x3F800000, 0x80, 0x00)],
            [(0x4B, 0x3F800000, 0x80, 0x00), (0x4B, 0x3F800000, 0x80, 0x00)],
        )
        result = MODULE.compare(run / "user-0/online-frame-packets.csv", run / "user-1/online-frame-packets.csv")
        self.assertFalse(result["pass"])
        self.assertEqual(result["first_item_packet_count_mismatch"]["reference"], 2)
        self.assertEqual(result["item_packet_payload_mismatches"], 0)


if __name__ == "__main__":
    unittest.main()
