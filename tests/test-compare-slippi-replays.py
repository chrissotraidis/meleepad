#!/usr/bin/env python3
"""Small private-data-free replay fixtures for the DashDance-derived comparator."""
import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "compare_slippi_replays", ROOT / "scripts/compare-slippi-replays.py")
comparator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comparator)


def replay(frames=(0, 1), state=1, game_end=True, declared_extra=0,
           follower=False, rollback=False):
    sizes = {0x36: 3, 0x37: 0x43, 0x38: 0x54, 0x39: 1}
    table = bytes([0x35, 1 + 3 * len(sizes)]) + b"".join(
        bytes([cmd]) + struct.pack(">H", size) for cmd, size in sizes.items())
    raw = bytearray(table + b"\x36\x03\x00\x00")
    for frame in frames:
        for port, is_follower in ((0, 0), (1, 1)) if follower else ((0, 0),):
            pre = bytearray(sizes[0x37])
            post = bytearray(sizes[0x38])
            struct.pack_into(">iBB", pre, 0, frame, port, is_follower)
            struct.pack_into(">iBB", post, 0, frame, port, is_follower)
            struct.pack_into(">H", pre, 0x0A, state)
            struct.pack_into(">H", post, 0x07, state)
            raw += bytes([0x37]) + pre + bytes([0x38]) + post
            if rollback:
                raw += bytes([0x37]) + pre + bytes([0x38]) + post
    if game_end:
        raw += b"\x39\x01"
    return b"raw[$U#l" + struct.pack(">I", len(raw) + declared_extra) + raw


class ReplayComparisonTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def compare(self, a, b):
        first, second = self.root / "first.slp", self.root / "second.slp"
        first.write_bytes(a)
        second.write_bytes(b)
        return comparator.compare(first, second)

    def test_complete_pair_and_rollback_history(self):
        result = self.compare(replay(follower=True, rollback=True),
                              replay(follower=True, rollback=True))
        self.assertEqual(result["outcome"], "equivalent")
        self.assertEqual(result["frames"], 2)
        self.assertEqual(result["players"], 2)
        self.assertEqual(result["rollback_records"], 16)

    def test_first_changed_state(self):
        result = self.compare(replay(state=1), replay(state=2))
        self.assertEqual((result["outcome"], result["frame"], result["field"]),
                         ("divergent", 0, "pre.state"))

    def test_unmapped_frame_byte_is_still_compared(self):
        altered = bytearray(replay())
        pre_start = altered.index(b"\x37", 12 + 14 + 4) + 1
        altered[pre_start + 0x42] = 1
        result = self.compare(replay(), altered)
        self.assertEqual((result["outcome"], result["field"], result["offset"]),
                         ("divergent", "pre.raw_byte", 0x42))

    def test_missing_frame_or_follower_cannot_pass(self):
        self.assertEqual(self.compare(replay(), replay(frames=(0,)))["outcome"],
                         "incomplete")
        self.assertEqual(self.compare(replay(follower=True), replay())["outcome"],
                         "incomplete")

    def test_truncated_event_or_raw_length_cannot_pass(self):
        self.assertEqual(self.compare(replay()[:-1], replay())["outcome"], "incomplete")
        self.assertEqual(self.compare(replay(declared_extra=1), replay())["outcome"],
                         "incomplete")

    def test_game_end_is_required(self):
        self.assertEqual(self.compare(replay(game_end=False), replay())["outcome"],
                         "incomplete")


if __name__ == "__main__":
    unittest.main()
