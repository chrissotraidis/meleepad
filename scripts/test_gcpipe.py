#!/usr/bin/env python3

from __future__ import annotations

import socket
import tempfile
import threading
import time
import unittest
from pathlib import Path

import gcpipe


class MemoryWatcherClientTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.user_dir = Path(self.temp_dir.name) / "user"
        self.address = 0x80477D68
        self.client = gcpipe.MemoryWatcherClient(self.user_dir, {self.address})

    def tearDown(self) -> None:
        self.client.close()
        self.temp_dir.cleanup()

    def send_values(self, values: list[int]) -> threading.Thread:
        def sender() -> None:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
            try:
                for value in values:
                    time.sleep(0.01)
                    message = f"{self.address:08X}\n{value:x}\n\0".encode("ascii")
                    sock.sendto(message, str(self.client.socket_path))
            finally:
                sock.close()

        thread = threading.Thread(target=sender)
        thread.start()
        return thread

    def test_wait_value_uses_revision_zero_state_mask(self) -> None:
        thread = self.send_values([0x18000000, 0x01000002])
        value = self.client.wait_value(self.address, 0xFF000000, 0x01000000, 1.0)
        thread.join()
        self.assertEqual(value, 0x01000002)

    def test_locations_are_sorted_and_uppercase(self) -> None:
        locations = (self.user_dir / "MemoryWatcher/Locations.txt").read_text(
            encoding="ascii"
        )
        self.assertEqual(locations, "80477D68\n")


class SequenceTests(unittest.TestCase):
    def test_collects_revision_zero_memory_address(self) -> None:
        sequence = [{"action": "wait_memory", "address": "0x80477D68"}]
        self.assertEqual(
            gcpipe.sequence_addresses(sequence), {0x80477D68}
        )


if __name__ == "__main__":
    unittest.main()
