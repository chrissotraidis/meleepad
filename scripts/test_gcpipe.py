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

    def test_pointer_chain_location_is_preserved_in_payload_and_file(self) -> None:
        self.client.close()
        chain = "0x80453134 0x2c 0xb0"
        self.client = gcpipe.MemoryWatcherClient(self.user_dir, {chain})
        locations = (self.user_dir / "MemoryWatcher/Locations.txt").read_text(
            encoding="ascii"
        )
        self.assertEqual(locations, "80453134 2C B0\n")

        sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        try:
            sock.sendto(
                b"80453134 2C B0\n41200000\n\0",
                str(self.client.socket_path),
            )
        finally:
            sock.close()
        value = self.client.wait_value(chain, 0xFFFFFFFF, 0x41200000, 1.0)
        self.assertEqual(value, 0x41200000)

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
    def test_decodes_memorywatcher_guest_float(self) -> None:
        self.assertAlmostEqual(gcpipe.u32_to_be_f32(0xC1F80000), -31.0)

    def test_collects_steering_pointer_chains(self) -> None:
        sequence = [
            {
                "action": "steer_memory_f32",
                "x_address": "0x8049EA88 0xC",
                "y_address": "0x8049EA88 0x10",
                "target_x": 10,
                "target_y": 15.5,
            }
        ]
        self.assertEqual(
            gcpipe.sequence_addresses(sequence),
            {"8049EA88 C", "8049EA88 10"},
        )

    def test_collects_dynamic_steering_target_chains(self) -> None:
        sequence = [
            {
                "action": "steer_memory_f32",
                "x_address": "0x8049EA88 0xC",
                "y_address": "0x8049EA88 0x10",
                "target_x_address": "0x8049EA9C 0x8",
                "target_y_address": "0x8049EA9C 0xC",
            }
        ]
        self.assertEqual(
            gcpipe.sequence_addresses(sequence),
            {"8049EA88 C", "8049EA88 10", "8049EA9C 8", "8049EA9C C"},
        )

    def test_state_driven_steering_converges_and_releases(self) -> None:
        class FakeWriter:
            def __init__(self) -> None:
                self.sticks: list[tuple[str, float, float]] = []

            def set_stick(self, axis: str, x: float, y: float) -> None:
                self.sticks.append((axis, x, y))

        class FakeWatcher:
            def __init__(self) -> None:
                self.x_values = iter([-31.0, -20.0, -9.0, 1.0, 9.5])

            def wait_f32(self, address: int | str, timeout_s: float) -> float:
                if address == "8049EA88 C":
                    return next(self.x_values)
                return 15.5

        writer = FakeWriter()
        gcpipe.steer_memory_f32(
            writer,
            FakeWatcher(),
            {
                "x_address": "0x8049EA88 0xC",
                "y_address": "0x8049EA88 0x10",
                "target_x": 10,
                "target_y": 15.5,
                "pulse": 0.01,
                "settle": 0,
            },
            lambda seconds: None,
        )
        self.assertIn(("MAIN", 0.7, 0.0), writer.sticks)
        self.assertEqual(writer.sticks[-1], ("MAIN", 0.0, 0.0))

    def test_dynamic_steering_applies_target_offsets(self) -> None:
        class FakeWriter:
            def __init__(self) -> None:
                self.sticks: list[tuple[str, float, float]] = []

            def set_stick(self, axis: str, x: float, y: float) -> None:
                self.sticks.append((axis, x, y))

        class FakeWatcher:
            def wait_f32(self, address: int | str, timeout_s: float) -> float:
                values = {
                    "8049EA88 C": 6.2,
                    "8049EA88 10": 12.6,
                    "8049EA9C 8": 10.0,
                    "8049EA9C C": 10.0,
                }
                return values[address]

        writer = FakeWriter()
        gcpipe.steer_memory_f32(
            writer,
            FakeWatcher(),
            {
                "x_address": "0x8049EA88 0xC",
                "y_address": "0x8049EA88 0x10",
                "target_x_address": "0x8049EA9C 0x8",
                "target_y_address": "0x8049EA9C 0xC",
                "target_x_offset": -3.8,
                "target_y_offset": 2.6,
                "tolerance": 0.1,
            },
            lambda seconds: None,
        )
        self.assertEqual(writer.sticks, [("MAIN", 0.0, 0.0)] * 2)

    def test_tap_until_memory_stops_on_masked_target(self) -> None:
        class FakeWriter:
            def __init__(self) -> None:
                self.commands: list[str] = []

            def send(self, command: str) -> None:
                self.commands.append(command)

        class FakeWatcher:
            def __init__(self) -> None:
                self.values = iter([0x00340002, 0x00340102])

            def wait_current(self, address: int | str, timeout_s: float) -> int:
                return next(self.values)

        writer = FakeWriter()
        gcpipe.tap_until_memory(
            writer,
            FakeWatcher(),
            {
                "address": "0x804D1D60 0x1848",
                "mask": "0x0000ff00",
                "equals": "0x00000100",
                "button": "D_RIGHT",
            },
            lambda seconds: None,
        )
        self.assertEqual(writer.commands, ["PRESS D_RIGHT", "RELEASE D_RIGHT"])

    def test_collects_tap_until_memory_address(self) -> None:
        self.assertEqual(
            gcpipe.sequence_addresses(
                [
                    {
                        "action": "tap_until_memory",
                        "address": "0x804D1D60 0x1848",
                    }
                ]
            ),
            {"804D1D60 1848"},
        )

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
            gcpipe.sequence_addresses(sequence), {"80477D68", "804D5324"}
        )

    def test_collects_pointer_chain_memory_location(self) -> None:
        sequence = [
            {
                "action": "wait_memory",
                "address": "0x80453134 0x2c 0xb0",
                "equals": "0x00000000",
            }
        ]
        self.assertEqual(
            gcpipe.sequence_addresses(sequence), {"80453134 2C B0"}
        )

    def test_merges_read_only_watch_locations(self) -> None:
        sequence = [{"action": "wait_memory", "address": "0x80477D68"}]
        self.assertEqual(
            gcpipe.watched_addresses(
                sequence,
                ["0x804D56AC 0x14 0x28 0x38", "0x80BDA810 0x28 0x3c"],
            ),
            {
                "80477D68",
                "804D56AC 14 28 38",
                "80BDA810 28 3C",
            },
        )

    def test_wait_counter_sequence_action_uses_watcher(self) -> None:
        class FakeWriter:
            pass

        class FakeWatcher:
            def __init__(self) -> None:
                self.calls: list[tuple[int | str, int, float]] = []

            def wait_counter(
                self, address: int | str, increments: int, timeout_s: float
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
        self.assertEqual(watcher.calls, [("804D5324", 6, 2.5)])

    def test_wait_counter_rejects_non_positive_increment_count(self) -> None:
        class FakeWriter:
            pass

        class FakeWatcher:
            def wait_counter(
                self, address: int | str, increments: int, timeout_s: float
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

    def test_b1_title_to_css_uses_analog_menu_selection(self) -> None:
        sequence_path = (
            Path(__file__).parent
            / "input-sequences/b1-title-to-two-human-css.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        self.assertFalse(
            any(
                step.get("action") == "tap" and step.get("button") == "D_DOWN"
                for step in sequence
            )
        )
        down = next(
            step
            for step in sequence
            if step.get("action") == "stick" and step.get("y") == -1.0
        )
        self.assertEqual(down.get("axis"), "MAIN")
        self.assertEqual(sequence[-1].get("equals"), "0x02000000")
        waits = [
            step.get("seconds", 0)
            for step in sequence
            if step.get("action") == "wait"
        ]
        self.assertGreaterEqual(waits.count(12.0), 2)

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

    def test_g8_exact_setup_is_revision_zero_and_state_gated(self) -> None:
        sequence_path = (
            Path(__file__).parent
            / "input-sequences/g8-r0-samus-kirby-rules.json"
        )
        sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
        title_transition = sequence[0]
        self.assertEqual(title_transition["action"], "tap_until_memory")
        self.assertEqual(title_transition["button"], "START")
        self.assertEqual(title_transition["address"], "0x80477D68")
        self.assertEqual(title_transition["equals"], "0x01000000")
        addresses = gcpipe.sequence_addresses(sequence)
        self.assertIn("8049EA88 C", addresses)
        self.assertIn("804D1D60 1848", addresses)
        self.assertIn("804D4B30 70", addresses)
        self.assertIn("804D4B30 94", addresses)

        predicates = {
            (step.get("address"), step.get("mask"), step.get("equals"))
            for step in sequence
            if step.get("action") in {"wait_memory", "tap_until_memory"}
        }
        self.assertIn(
            ("0x804D4B30 0x70", "0xFF000000", "0x10000000"), predicates
        )
        self.assertIn(
            ("0x804D4B30 0x94", "0xFFFF0000", "0x04010000"), predicates
        )
        self.assertIn(
            ("0x804D1D60 0x184C", "0xFF000000", "0x04000000"), predicates
        )
        self.assertIn(
            ("0x804D1D60 0x1850", "0xFF000000", "0x05000000"), predicates
        )

        stage_steer = next(
            step
            for step in sequence
            if step.get("action") == "steer_memory_f32"
            and str(step.get("x_address", "")).startswith("0x804D56A4")
        )
        self.assertEqual(stage_steer["x_address"].split().count("0x8"), 22)
        self.assertEqual(stage_steer["y_address"].split().count("0x8"), 22)
        self.assertEqual((stage_steer["target_x"], stage_steer["target_y"]), (7.4, 14.1))

        for address, expected in (
            ("0x804D1D60 0x1848", "0x00000100"),
            ("0x804D1D60 0x184C", "0x04000000"),
            ("0x804D1D60 0x1850", "0x05000000"),
        ):
            setter_index = next(
                index
                for index, step in enumerate(sequence)
                if step.get("action") == "tap_until_memory"
                and step.get("address") == address
                and step.get("equals") == expected
            )
            normalization = next(
                step
                for step in reversed(sequence[:setter_index])
                if step.get("action") == "tap"
            )
            self.assertEqual(normalization["button"], "D_RIGHT")


if __name__ == "__main__":
    unittest.main()
