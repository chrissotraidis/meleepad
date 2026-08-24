#!/usr/bin/env python3
"""Drive SsbmPad's GameCube controller through ModernGekko's FIFO backend."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path


DEFAULT_PIPE = (
    Path.home() / "Library/Application Support/SsbmPad/Pipes/ssbmpad"
)


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


def run_sequence(writer: PadWriter, sequence: list[dict]) -> None:
    started = time.monotonic()
    for step in sequence:
        delay = float(step.get("delay", 0.0))
        if delay:
            time.sleep(delay)
        action = step.get("action", "tap")
        if action == "tap":
            writer.tap(step["button"], float(step.get("hold", 0.12)))
        elif action == "press":
            writer.send(f"PRESS {step['button']}")
        elif action == "release":
            writer.send(f"RELEASE {step['button']}")
        elif action == "stick":
            writer.set_stick(step["axis"], float(step["x"]), float(step["y"]))
        elif action == "wait":
            time.sleep(float(step.get("seconds", 1.0)))
        else:
            raise ValueError(f"unknown action: {action}")
        print(f"[{time.monotonic() - started:7.2f}s] {json.dumps(step)}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pipe", type=Path, default=DEFAULT_PIPE)
    parser.add_argument("--open-timeout", type=float, default=60.0)
    parser.add_argument("--sequence", type=Path)
    parser.add_argument("--tap", metavar="BUTTON")
    parser.add_argument("--stick", nargs=3, metavar=("AXIS", "X", "Y"))
    args = parser.parse_args()

    writer = PadWriter(args.pipe, args.open_timeout)
    try:
        if args.sequence:
            with args.sequence.open(encoding="utf-8") as sequence_file:
                run_sequence(writer, json.load(sequence_file))
        if args.tap:
            writer.tap(args.tap)
        if args.stick:
            writer.set_stick(args.stick[0], float(args.stick[1]), float(args.stick[2]))
    finally:
        writer.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
