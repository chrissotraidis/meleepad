#!/usr/bin/env python3
"""Drive SsbmPad's GameCube controller through ModernGekko's FIFO backend."""

from __future__ import annotations

import argparse
import json
import os
import socket
import sys
import time
from pathlib import Path


DEFAULT_PIPE = (
    Path.home() / "Library/Application Support/SsbmPad/Pipes/ssbmpad"
)


def default_pipe_path(memory_user_dir: Path | None = None) -> Path:
    if memory_user_dir is not None:
        return memory_user_dir / "Pipes/ssbmpad"
    return DEFAULT_PIPE


def parse_int(value: int | str) -> int:
    if isinstance(value, int):
        return value
    return int(value, 0)


class MemoryWatcherClient:
    """Receive Dolphin MemoryWatcher values from an isolated user directory."""

    def __init__(
        self, user_dir: Path, addresses: set[int], trace: bool = False
    ):
        watcher_dir = user_dir / "MemoryWatcher"
        watcher_dir.mkdir(parents=True, exist_ok=True)
        (watcher_dir / "Locations.txt").write_text(
            "".join(f"{address:08X}\n" for address in sorted(addresses)),
            encoding="ascii",
        )

        self.socket_path = watcher_dir / "MemoryWatcher"
        if len(os.fsencode(self.socket_path)) >= 104:
            raise ValueError(f"MemoryWatcher socket path is too long: {self.socket_path}")
        self.socket_path.unlink(missing_ok=True)
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.socket.bind(str(self.socket_path))
        self.values: dict[int, int] = {}
        self.trace = trace

    def _process_payload(self, payload: bytes) -> None:
        lines = payload.rstrip(b"\0").decode("ascii").splitlines()
        for index in range(0, len(lines) - 1, 2):
            address = int(lines[index].split()[0], 16)
            value = int(lines[index + 1], 16)
            self.values[address] = value
            if self.trace:
                print(f"[memory] {address:08X}={value:08X}", flush=True)

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
        self, address: int, mask: int, expected: int, timeout_s: float
    ) -> int:
        deadline = time.monotonic() + timeout_s
        while True:
            value = self.values.get(address)
            if value is not None and value & mask == expected:
                return value
            self._receive(deadline)

    def wait_value_not(
        self, address: int, mask: int, rejected: int, timeout_s: float
    ) -> int:
        deadline = time.monotonic() + timeout_s
        while True:
            value = self.values.get(address)
            if value is not None and value & mask != rejected:
                return value
            self._receive(deadline)

    def wait_counter(
        self, address: int, increments: int, timeout_s: float
    ) -> int:
        """Wait for a watched unsigned 32-bit counter to advance."""
        if increments < 1:
            raise ValueError("increments must be at least 1")

        deadline = time.monotonic() + timeout_s
        self._drain()
        baseline = self.values.get(address)
        while self.values.get(address) == baseline:
            self._receive(deadline)

        previous = self.values[address]
        remaining = increments
        while True:
            self._receive(deadline)
            current = self.values[address]
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


def sequence_addresses(sequence: list[dict]) -> set[int]:
    addresses: set[int] = set()
    for step in sequence:
        action = step.get("action", "tap")
        if action in {"wait_memory", "wait_counter"}:
            addresses.add(parse_int(step["address"]))
    return addresses


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
            address = parse_int(step["address"])
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
                parse_int(step["address"]),
                increments,
                float(step.get("timeout", 60.0)),
            )
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
        addresses = sequence_addresses(sequence)
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
