#!/usr/bin/env python3
"""Drive MeleePad's GameCube controller through ModernGekko's FIFO backend."""

from __future__ import annotations

import argparse
import json
import os
import socket
import struct
import sys
import time
from pathlib import Path


DEFAULT_PIPE = (
    Path.home() / "Library/Application Support/MeleePad/Pipes/meleepad"
)


def default_pipe_path(memory_user_dir: Path | None = None) -> Path:
    if memory_user_dir is not None:
        return memory_user_dir / "Pipes/meleepad"
    return DEFAULT_PIPE


def parse_int(value: int | str) -> int:
    if isinstance(value, int):
        return value
    return int(value, 0)


def memory_location(value: int | str) -> str:
    """Normalize a Dolphin MemoryWatcher address or pointer chain."""
    if isinstance(value, int):
        return f"{value:08X}"
    tokens = value.split()
    if not tokens:
        raise ValueError("memory location cannot be empty")
    parsed = [
        int(token, 0) if token.lower().startswith("0x") else int(token, 16)
        for token in tokens
    ]
    return " ".join(
        f"{address:08X}" if index == 0 else f"{address:X}"
        for index, address in enumerate(parsed)
    )


def u32_to_be_f32(value: int) -> float:
    """Decode the big-endian float representation published by MemoryWatcher."""
    return struct.unpack(">f", value.to_bytes(4, "big"))[0]


class MemoryWatcherClient:
    """Receive Dolphin MemoryWatcher values from an isolated user directory."""

    def __init__(
        self, user_dir: Path, addresses: set[int | str], trace: bool = False
    ):
        watcher_dir = user_dir / "MemoryWatcher"
        watcher_dir.mkdir(parents=True, exist_ok=True)
        locations = sorted({memory_location(address) for address in addresses})
        (watcher_dir / "Locations.txt").write_text(
            "".join(f"{location}\n" for location in locations), encoding="ascii"
        )

        self.socket_path = watcher_dir / "MemoryWatcher"
        if len(os.fsencode(self.socket_path)) >= 104:
            raise ValueError(f"MemoryWatcher socket path is too long: {self.socket_path}")
        self.socket_path.unlink(missing_ok=True)
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.socket.bind(str(self.socket_path))
        self.values: dict[str, int] = {}
        self.trace = trace

    def _process_payload(self, payload: bytes) -> None:
        lines = payload.rstrip(b"\0").decode("ascii").splitlines()
        for index in range(0, len(lines) - 1, 2):
            location = memory_location(lines[index])
            value = int(lines[index + 1], 16)
            self.values[location] = value
            if self.trace:
                print(f"[memory] {location}={value:08X}", flush=True)

    def _receive(self, deadline: float) -> None:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("MemoryWatcher predicate timed out")
        self.socket.settimeout(min(remaining, 0.5))
        try:
            payload = self.socket.recv(65536)
        except socket.timeout:
            return
        self._process_payload(payload)

    def _drain(self) -> None:
        """Consume watcher packets queued before a new timed action."""
        self.socket.setblocking(False)
        while True:
            try:
                self._process_payload(self.socket.recv(65536))
            except BlockingIOError:
                return

    def wait_value(
        self, address: int | str, mask: int, expected: int, timeout_s: float
    ) -> int:
        location = memory_location(address)
        deadline = time.monotonic() + timeout_s
        while True:
            value = self.values.get(location)
            if value is not None and value & mask == expected:
                return value
            self._receive(deadline)

    def wait_f32(self, address: int | str, timeout_s: float) -> float:
        """Wait for an initial value and decode it as a guest big-endian float."""
        location = memory_location(address)
        deadline = time.monotonic() + timeout_s
        while location not in self.values:
            self._receive(deadline)
        return u32_to_be_f32(self.values[location])

    def wait_current(self, address: int | str, timeout_s: float) -> int:
        """Wait until a watched location has published its initial value."""
        location = memory_location(address)
        deadline = time.monotonic() + timeout_s
        while location not in self.values:
            self._receive(deadline)
        return self.values[location]

    def wait_value_not(
        self, address: int | str, mask: int, rejected: int, timeout_s: float
    ) -> int:
        location = memory_location(address)
        deadline = time.monotonic() + timeout_s
        while True:
            value = self.values.get(location)
            if value is not None and value & mask != rejected:
                return value
            self._receive(deadline)

    def wait_counter(
        self, address: int | str, increments: int, timeout_s: float
    ) -> int:
        """Wait for a watched unsigned 32-bit counter to advance."""
        if increments < 1:
            raise ValueError("increments must be at least 1")

        location = memory_location(address)
        deadline = time.monotonic() + timeout_s
        self._drain()
        baseline = self.values.get(location)
        while self.values.get(location) == baseline:
            self._receive(deadline)

        previous = self.values[location]
        remaining = increments
        while True:
            self._receive(deadline)
            current = self.values[location]
            delta = (current - previous) & 0xFFFFFFFF
            if delta == 0:
                continue
            if delta > 0x7FFFFFFF:
                # Treat a large backwards jump as a counter reset, not as
                # billions of forward increments. Normal u32 wrap produces a
                # small positive delta and is counted above.
                previous = current
                continue
            if delta >= remaining:
                return current
            remaining -= delta
            previous = current

    def pump_for(self, seconds: float) -> None:
        """Drain watcher traffic while a scripted input delay elapses."""
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            self._receive(deadline)

    def close(self) -> None:
        self.socket.close()
        self.socket_path.unlink(missing_ok=True)


class PadWriter:
    def __init__(self, pipe_path: Path, timeout_s: float = 60.0):
        self.pipe_path = pipe_path
        self.fd: int | None = None
        deadline = time.monotonic() + timeout_s
        while time.monotonic() < deadline:
            try:
                self.fd = os.open(pipe_path, os.O_WRONLY | os.O_NONBLOCK)
                return
            except (FileNotFoundError, OSError):
                time.sleep(0.25)
        raise RuntimeError(f"pipe never opened for reading: {pipe_path}")

    def send(self, command: str) -> None:
        assert self.fd is not None
        os.write(self.fd, (command.rstrip("\n") + "\n").encode())

    def tap(self, button: str, hold_s: float = 0.12) -> None:
        self.send(f"PRESS {button}")
        time.sleep(hold_s)
        self.send(f"RELEASE {button}")

    def set_stick(self, name: str, x: float, y: float) -> None:
        self.send(f"SET {name} {0.5 + x / 2.0:.3f} {0.5 - y / 2.0:.3f}")

    def close(self) -> None:
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None


def sequence_addresses(sequence: list[dict]) -> set[str]:
    addresses: set[str] = set()
    for step in sequence:
        action = step.get("action", "tap")
        if action in {"wait_memory", "wait_counter", "tap_until_memory"}:
            addresses.add(memory_location(step["address"]))
        elif action == "steer_memory_f32":
            addresses.add(memory_location(step["x_address"]))
            addresses.add(memory_location(step["y_address"]))
            if "target_x_address" in step:
                addresses.add(memory_location(step["target_x_address"]))
            if "target_y_address" in step:
                addresses.add(memory_location(step["target_y_address"]))
    return addresses


def watched_addresses(sequence: list[dict], extra: list[str]) -> set[str]:
    """Combine sequence predicates with read-only diagnostic locations."""
    return sequence_addresses(sequence) | {memory_location(value) for value in extra}


def steer_memory_f32(
    writer: PadWriter,
    watcher: MemoryWatcherClient,
    step: dict,
    pause,
) -> None:
    """Pulse one stick axis at a time until watched cursor coordinates converge."""
    x_address = memory_location(step["x_address"])
    y_address = memory_location(step["y_address"])
    target_x_address = (
        memory_location(step["target_x_address"])
        if "target_x_address" in step
        else None
    )
    target_y_address = (
        memory_location(step["target_y_address"])
        if "target_y_address" in step
        else None
    )
    if target_x_address is None and "target_x" not in step:
        raise ValueError("steer_memory_f32 requires target_x or target_x_address")
    if target_y_address is None and "target_y" not in step:
        raise ValueError("steer_memory_f32 requires target_y or target_y_address")
    fixed_target_x = float(step["target_x"]) if target_x_address is None else None
    fixed_target_y = float(step["target_y"]) if target_y_address is None else None
    target_x_offset = float(step.get("target_x_offset", 0.0))
    target_y_offset = float(step.get("target_y_offset", 0.0))
    tolerance = float(step.get("tolerance", 1.5))
    magnitude = float(step.get("magnitude", 0.7))
    pulse_s = float(step.get("pulse", 0.04))
    settle_s = float(step.get("settle", 0.04))
    timeout_s = float(step.get("timeout", 20.0))
    axis = step.get("axis", "MAIN")

    if tolerance <= 0:
        raise ValueError("steer_memory_f32 tolerance must be positive")
    if not 0 < magnitude <= 1:
        raise ValueError("steer_memory_f32 magnitude must be in (0, 1]")
    if pulse_s <= 0 or settle_s < 0 or timeout_s <= 0:
        raise ValueError("steer_memory_f32 timing values must be positive")

    deadline = time.monotonic() + timeout_s
    writer.set_stick(axis, 0.0, 0.0)
    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError(
                    f"cursor did not reach its target within {timeout_s}s"
                )
            x = watcher.wait_f32(x_address, remaining)
            y = watcher.wait_f32(y_address, remaining)
            target_x = (
                watcher.wait_f32(target_x_address, remaining)
                if target_x_address is not None
                else fixed_target_x
            )
            target_y = (
                watcher.wait_f32(target_y_address, remaining)
                if target_y_address is not None
                else fixed_target_y
            )
            assert target_x is not None and target_y is not None
            target_x += target_x_offset
            target_y += target_y_offset
            dx = target_x - x
            dy = target_y - y
            if abs(dx) <= tolerance and abs(dy) <= tolerance:
                return

            if abs(dx) >= abs(dy):
                stick_x, stick_y = (magnitude if dx > 0 else -magnitude), 0.0
            else:
                stick_x, stick_y = 0.0, (magnitude if dy > 0 else -magnitude)
            writer.set_stick(axis, stick_x, stick_y)
            pause(min(pulse_s, max(0.0, deadline - time.monotonic())))
            writer.set_stick(axis, 0.0, 0.0)
            if settle_s:
                pause(min(settle_s, max(0.0, deadline - time.monotonic())))
    finally:
        writer.set_stick(axis, 0.0, 0.0)


def tap_until_memory(
    writer: PadWriter,
    watcher: MemoryWatcherClient,
    step: dict,
    pause,
) -> None:
    """Repeat a button tap until a watched masked value reaches its target."""
    address = memory_location(step["address"])
    mask = parse_int(step.get("mask", "0xffffffff"))
    expected = parse_int(step["equals"])
    hold_s = float(step.get("hold", 0.12))
    interval_s = float(step.get("interval", 0.2))
    timeout_s = float(step.get("timeout", 10.0))
    max_taps = parse_int(step.get("max_taps", 32))
    if hold_s <= 0 or interval_s < 0 or timeout_s <= 0 or max_taps < 1:
        raise ValueError("tap_until_memory timing and tap limits must be positive")

    deadline = time.monotonic() + timeout_s
    for _ in range(max_taps):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        if watcher.wait_current(address, remaining) & mask == expected:
            return
        writer.send(f"PRESS {step['button']}")
        pause(min(hold_s, max(0.0, deadline - time.monotonic())))
        writer.send(f"RELEASE {step['button']}")
        if interval_s:
            pause(min(interval_s, max(0.0, deadline - time.monotonic())))
    value = watcher.wait_current(address, max(0.001, deadline - time.monotonic()))
    if value & mask != expected:
        raise TimeoutError(
            f"{address} did not reach 0x{expected:08X} under mask 0x{mask:08X}"
        )


def run_sequence(
    writer: PadWriter,
    sequence: list[dict],
    watcher: MemoryWatcherClient | None = None,
) -> None:
    def pause(seconds: float) -> None:
        if watcher is None:
            time.sleep(seconds)
        else:
            watcher.pump_for(seconds)

    started = time.monotonic()
    for step in sequence:
        delay = float(step.get("delay", 0.0))
        if delay:
            pause(delay)
        action = step.get("action", "tap")
        if action == "tap":
            hold_s = float(step.get("hold", 0.12))
            if watcher is None:
                writer.tap(step["button"], hold_s)
            else:
                writer.send(f"PRESS {step['button']}")
                pause(hold_s)
                writer.send(f"RELEASE {step['button']}")
        elif action == "press":
            writer.send(f"PRESS {step['button']}")
        elif action == "release":
            writer.send(f"RELEASE {step['button']}")
        elif action == "stick":
            writer.set_stick(step["axis"], float(step["x"]), float(step["y"]))
        elif action == "wait":
            pause(float(step.get("seconds", 1.0)))
        elif action == "wait_memory":
            if watcher is None:
                raise ValueError("wait_memory requires --memory-user-dir")
            address = memory_location(step["address"])
            mask = parse_int(step.get("mask", "0xffffffff"))
            timeout_s = float(step.get("timeout", 60.0))
            if "not_equals" in step:
                watcher.wait_value_not(
                    address, mask, parse_int(step["not_equals"]), timeout_s
                )
            else:
                watcher.wait_value(
                    address, mask, parse_int(step["equals"]), timeout_s
                )
        elif action == "wait_counter":
            if watcher is None:
                raise ValueError("wait_counter requires --memory-user-dir")
            increments = parse_int(step["increments"])
            if increments < 1:
                raise ValueError("increments must be at least 1")
            watcher.wait_counter(
                memory_location(step["address"]),
                increments,
                float(step.get("timeout", 60.0)),
            )
        elif action == "steer_memory_f32":
            if watcher is None:
                raise ValueError("steer_memory_f32 requires --memory-user-dir")
            steer_memory_f32(writer, watcher, step, pause)
        elif action == "tap_until_memory":
            if watcher is None:
                raise ValueError("tap_until_memory requires --memory-user-dir")
            tap_until_memory(writer, watcher, step, pause)
        else:
            raise ValueError(f"unknown action: {action}")
        print(f"[{time.monotonic() - started:7.2f}s] {json.dumps(step)}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pipe", type=Path)
    parser.add_argument("--open-timeout", type=float, default=60.0)
    parser.add_argument("--sequence", type=Path)
    parser.add_argument("--repeat", type=int, default=1)
    parser.add_argument("--memory-user-dir", type=Path)
    parser.add_argument(
        "--watch",
        action="append",
        default=[],
        metavar="ADDRESS",
        help="also publish a MemoryWatcher address or pointer chain",
    )
    parser.add_argument("--trace-memory", action="store_true")
    parser.add_argument("--tap", metavar="BUTTON")
    parser.add_argument("--stick", nargs=3, metavar=("AXIS", "X", "Y"))
    args = parser.parse_args()
    if args.repeat < 1:
        parser.error("--repeat must be at least 1")

    sequence: list[dict] = []
    if args.sequence:
        with args.sequence.open(encoding="utf-8") as sequence_file:
            sequence = json.load(sequence_file)

    watcher: MemoryWatcherClient | None = None
    if args.memory_user_dir:
        addresses = watched_addresses(sequence, args.watch)
        if not addresses:
            parser.error("--memory-user-dir requires a memory-aware sequence")
        watcher = MemoryWatcherClient(
            args.memory_user_dir, addresses, trace=args.trace_memory
        )

    pipe_path = args.pipe or default_pipe_path(args.memory_user_dir)
    writer = PadWriter(pipe_path, args.open_timeout)
    try:
        if sequence:
            for _ in range(args.repeat):
                run_sequence(writer, sequence, watcher)
        if args.tap:
            writer.tap(args.tap)
        if args.stick:
            writer.set_stick(args.stick[0], float(args.stick[1]), float(args.stick[2]))
    finally:
        writer.close()
        if watcher:
            watcher.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
