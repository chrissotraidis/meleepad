#!/usr/bin/env python3
"""Capture and save an iOS Simulator state when an exact projection hash appears."""

from __future__ import annotations

import argparse
import json
import os
import re
import signal
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


PROJECTION_HASH = re.compile(r"(?:^|\s)projectionHash=([0-9a-fA-F]{16})(?:\s|$)")


def projection_hash(line: str) -> str | None:
    match = PROJECTION_HASH.search(line)
    return match.group(1).lower() if match else None


def wait_for_state(path: Path, previous_mtime_ns: int | None, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if path.stat().st_mtime_ns != previous_mtime_ns:
                return True
        except FileNotFoundError:
            pass
        time.sleep(0.1)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-log", type=Path, required=True)
    parser.add_argument("--projection-hash", required=True)
    parser.add_argument("--pid", type=int, required=True)
    parser.add_argument("--simulator-udid", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--savestate", type=Path)
    parser.add_argument("--timeout-seconds", type=float, default=600.0)
    parser.add_argument("--poll-seconds", type=float, default=0.1)
    parser.add_argument("--from-start", action="store_true")
    args = parser.parse_args()

    target = args.projection_hash.lower()
    if not re.fullmatch(r"[0-9a-f]{16}", target):
        parser.error("projection hash must contain exactly 16 hexadecimal digits")
    if args.pid <= 0:
        parser.error("pid must be positive")
    if args.timeout_seconds <= 0 or args.poll_seconds <= 0:
        parser.error("timeouts must be positive")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + args.timeout_seconds
    with args.runtime_log.open("r", encoding="utf-8", errors="replace") as stream:
        if not args.from_start:
            stream.seek(0, os.SEEK_END)
        while time.monotonic() < deadline:
            line = stream.readline()
            if not line:
                time.sleep(args.poll_seconds)
                continue
            if projection_hash(line) != target:
                continue

            previous_mtime_ns = None
            if args.savestate is not None:
                try:
                    previous_mtime_ns = args.savestate.stat().st_mtime_ns
                except FileNotFoundError:
                    pass
            os.kill(args.pid, signal.SIGUSR1)
            screenshot = args.output_dir / "trigger.png"
            subprocess.run(
                [
                    "xcrun",
                    "simctl",
                    "io",
                    args.simulator_udid,
                    "screenshot",
                    str(screenshot),
                ],
                check=True,
            )
            state_updated = None
            if args.savestate is not None:
                state_updated = wait_for_state(
                    args.savestate, previous_mtime_ns, min(15.0, args.timeout_seconds)
                )
            metadata = {
                "capturedAt": datetime.now(timezone.utc).isoformat(),
                "pid": args.pid,
                "projectionHash": target,
                "runtimeRow": line.rstrip("\n"),
                "savestate": str(args.savestate) if args.savestate else None,
                "savestateUpdated": state_updated,
                "screenshot": str(screenshot),
                "simulatorUDID": args.simulator_udid,
            }
            (args.output_dir / "trigger.json").write_text(
                json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8"
            )
            print(json.dumps(metadata, sort_keys=True))
            return 0

    print(f"projection hash {target} did not appear before timeout", file=os.sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
