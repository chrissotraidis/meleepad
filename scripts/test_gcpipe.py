#!/usr/bin/env python3

from __future__ import annotations

import json
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

    def test_wait_value_not_rejects_boot_zero(self) -> None:
        thread = self.send_values([0, 0x13])
        value = self.client.wait_value_not(self.address, 0xFFFFFFFF, 0, 1.0)
        thread.join()
        self.assertEqual(value, 0x13)


class SequenceTests(unittest.TestCase):
    def test_isolated_user_dir_uses_its_fifo_by_default(self) -> None:
        user_dir = Path("/private/tmp/ssbmpad-test/user")
        self.assertEqual(
            gcpipe.default_pipe_path(user_dir), user_dir / "Pipes/ssbmpad"
        )

    def test_collects_revision_zero_memory_address(self) -> None:
        sequence = [{"action": "wait_memory", "address": "0x80477D68"}]
        self.assertEqual(
            gcpipe.sequence_addresses(sequence), {0x80477D68}
        )

    def test_title_to_css_does_not_press_start_on_the_main_menu(self) -> None:
        sequence_path = (
            Path(__file__).parent / "input-sequences/g5-r0-title-to-css.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        first_menu_wait = next(
            index
            for index, step in enumerate(sequence)
            if step.get("action") == "wait_memory"
            and step.get("equals") == "0x01000000"
        )
        start_taps = [
            step
            for step in sequence[:first_menu_wait]
            if step.get("action") == "tap" and step.get("button") == "START"
        ]
        self.assertEqual(len(start_taps), 1)

    def test_title_to_css_uses_per_mode_revision_zero_scene_indices(self) -> None:
        sequence_path = (
            Path(__file__).parent / "input-sequences/g5-r0-title-to-css.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        routing_values = [
            step.get("equals")
            for step in sequence
            if step.get("action") == "wait_memory"
            and step.get("address") == "0x80477D68"
        ]
        self.assertEqual(
            routing_values,
            ["0x00000000", "0x01000000", "0x02000000"],
        )

    def test_title_to_css_waits_for_menu_input_animations(self) -> None:
        sequence_path = (
            Path(__file__).parent / "input-sequences/g5-r0-title-to-css.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        down_index = next(
            index
            for index, step in enumerate(sequence)
            if step.get("action") == "tap" and step.get("button") == "D_DOWN"
        )
        a_indices = [
            index
            for index, step in enumerate(sequence)
            if step.get("action") == "tap" and step.get("button") == "A"
        ]
        self.assertGreaterEqual(sequence[down_index - 1].get("seconds", 0), 5)
        self.assertGreaterEqual(sequence[a_indices[1] - 1].get("seconds", 0), 5)

    def test_title_to_css_waits_out_the_title_input_lockout(self) -> None:
        sequence_path = (
            Path(__file__).parent / "input-sequences/g5-r0-title-to-css.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        start_index = next(
            index
            for index, step in enumerate(sequence)
            if step.get("action") == "tap" and step.get("button") == "START"
        )
        lockout_predicates = [
            ("not_equals", step.get("not_equals"))
            if "not_equals" in step
            else ("equals", step.get("equals"))
            for step in sequence[:start_index]
            if step.get("action") == "wait_memory"
            and step.get("address") == "0x804D4594"
        ]
        self.assertEqual(
            lockout_predicates,
            [("not_equals", "0x00000000"), ("equals", "0x00000000")],
            "must observe title initialization before accepting its final zero",
        )


if __name__ == "__main__":
    unittest.main()
