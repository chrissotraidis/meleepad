#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('extractor', Path(__file__).with_name('extract-slippi-reference-trace.py'))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def replay(events=None):
    sizes = {0x36: 2, 0x39: 2, **m.EVENT_LENGTHS}
    table = b''.join(bytes([c]) + (n-1).to_bytes(2, 'big') for c, n in sizes.items())
    raw = bytes([0x35, len(table)+1]) + table
    raw += events if events is not None else b'\x36\0' + b'\x38' + bytes(84) + b'\x39\0'
    return m.HEADER + len(raw).to_bytes(4, 'big') + raw + b'U\x08metadata{}}'


class Tests(unittest.TestCase):
    def test_extract_exact_packet(self):
        self.assertEqual(m.extract(replay()), [(0x38, (b'\x38'+bytes(84)).hex())])
    def test_short_table_rejected(self):
        with self.assertRaises(ValueError): m.extract(m.HEADER + (1).to_bytes(4, 'big') + b'\x35' + b'{}')
    def test_unclosed_rejected(self):
        data = replay()
        with self.assertRaises(ValueError): m.extract(data[:11]+bytes(4)+data[15:])
    def test_truncated_rejected(self):
        with self.assertRaises(ValueError): m.extract(replay()[:25])
    def test_missing_end_rejected(self):
        with self.assertRaises(ValueError): m.extract(replay(b'\x36\0'+b'\x38'+bytes(84)))
    def test_event_after_end_rejected(self):
        with self.assertRaises(ValueError): m.extract(replay(b'\x36\0\x39\0\x38'+bytes(84)))
    def test_wrong_event_size_rejected(self):
        data = bytearray(replay()); data[25] = 83
        with self.assertRaises(ValueError): m.extract(data)


if __name__ == '__main__': unittest.main()
