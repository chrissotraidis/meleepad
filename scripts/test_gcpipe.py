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

    def send_values_now(self, values: list[int]) -> None:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        try:
            for value in values:
                message = f"{self.address:08X}\n{value:x}\n\0".encode("ascii")
                sock.sendto(message, str(self.client.socket_path))
        finally:
            sock.close()

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

    def test_wait_counter_counts_increments_across_u32_wrap(self) -> None:
        thread = self.send_values([0xFFFFFFFE, 0xFFFFFFFF, 0, 1])
        value = self.client.wait_counter(self.address, 3, 1.0)
        thread.join()
        self.assertEqual(value, 1)

    def test_wait_counter_counts_dropped_observations_by_value_delta(self) -> None:
        thread = self.send_values([10, 13])
        value = self.client.wait_counter(self.address, 3, 1.0)
        thread.join()
        self.assertEqual(value, 13)

    def test_wait_counter_discards_packets_queued_before_action(self) -> None:
        self.send_values_now([5, 10])
        thread = self.send_values([20, 23])
        value = self.client.wait_counter(self.address, 3, 1.0)
        thread.join()
        self.assertEqual(value, 23)


class SequenceTests(unittest.TestCase):
    def test_memory_aware_sequence_pumps_watcher_during_delays(self) -> None:
        class FakeWriter:
            def tap(self, button: str, hold_s: float = 0.12) -> None:
                raise AssertionError("watcher-aware taps must not sleep inside PadWriter")

            def send(self, command: str) -> None:
                pass

        class FakeWatcher:
            def __init__(self) -> None:
                self.pumped: list[float] = []

            def pump_for(self, seconds: float) -> None:
                self.pumped.append(seconds)

        watcher = FakeWatcher()
        gcpipe.run_sequence(
            FakeWriter(),
            [
                {"action": "wait", "seconds": 5.0},
                {"action": "tap", "button": "A", "hold": 0.3, "delay": 0.5},
            ],
            watcher,
        )
        self.assertEqual(watcher.pumped, [5.0, 0.5, 0.3])

    def test_isolated_user_dir_uses_its_fifo_by_default(self) -> None:
        user_dir = Path("/private/tmp/ssbmpad-test/user")
        self.assertEqual(
            gcpipe.default_pipe_path(user_dir), user_dir / "Pipes/ssbmpad"
        )

    def test_collects_revision_zero_memory_address(self) -> None:
        sequence = [
            {"action": "wait_memory", "address": "0x80477D68"},
            {
                "action": "wait_counter",
                "address": "0x804D5324",
                "increments": 4,
            },
        ]
        self.assertEqual(
            gcpipe.sequence_addresses(sequence), {0x80477D68, 0x804D5324}
        )

    def test_wait_counter_sequence_action_uses_watcher(self) -> None:
        class FakeWriter:
            pass

        class FakeWatcher:
            def __init__(self) -> None:
                self.calls: list[tuple[int, int, float]] = []

            def wait_counter(
                self, address: int, increments: int, timeout_s: float
            ) -> int:
                self.calls.append((address, increments, timeout_s))
                return 123

        watcher = FakeWatcher()
        gcpipe.run_sequence(
            FakeWriter(),
            [
                {
                    "action": "wait_counter",
                    "address": "0x804D5324",
                    "increments": 6,
                    "timeout": 2.5,
                }
            ],
            watcher,
        )
        self.assertEqual(watcher.calls, [(0x804D5324, 6, 2.5)])

    def test_wait_counter_rejects_non_positive_increment_count(self) -> None:
        class FakeWriter:
            pass

        class FakeWatcher:
            def wait_counter(
                self, address: int, increments: int, timeout_s: float
            ) -> int:
                raise AssertionError("invalid action must fail before watcher call")

        with self.assertRaisesRegex(ValueError, "increments must be at least 1"):
            gcpipe.run_sequence(
                FakeWriter(),
                [
                    {
                        "action": "wait_counter",
                        "address": "0x804D5324",
                        "increments": 0,
                    }
                ],
                FakeWatcher(),
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

    def test_title_to_css_does_not_require_a_boot_time_zero_packet(self) -> None:
        sequence_path = (
            Path(__file__).parent / "input-sequences/g5-r0-title-to-css.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        self.assertEqual(sequence[0].get("address"), "0x804D4594")
        self.assertEqual(sequence[0].get("not_equals"), "0x00000000")

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
            ["0x01000000", "0x02000000"],
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
