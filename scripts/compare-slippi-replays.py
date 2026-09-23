#!/usr/bin/env python3
"""Compare two supplied Slippi replays without launching a game or reading accounts.

The field tables and replay reader come from DashDance's GPL-2.0-or-later
tools/mac/slp.py, pinned and hardened in third_party/dashdance/slp.py.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "third_party/dashdance"))
from slp import IncompleteReplayError, Replay  # noqa: E402


def compare(recorded, reference):
    try:
        a, b = Replay(recorded), Replay(reference)
    except IncompleteReplayError as exc:
        return {"outcome": "incomplete", "reason": str(exc)}
    except (OSError, ValueError) as exc:
        return {"outcome": "invalid", "reason": str(exc)}
    if a.version[0] != 3 or b.version[0] != 3:
        return {"outcome": "unsupported", "reason": "unsupported major replay version",
                "recorded_version": a.version, "reference_version": b.version}
    if a.version != b.version:
        return {"outcome": "unsupported", "reason": "replay versions differ",
                "recorded_version": a.version, "reference_version": b.version}
    if not a.pre or not a.post or not b.pre or not b.post:
        return {"outcome": "incomplete", "reason": "pre-frame or post-frame records are absent"}
    if a.game_end is None or b.game_end is None:
        return {"outcome": "incomplete", "reason": "game-end event is absent"}
    for label in ("pre", "post"):
        left, right = getattr(a, label), getattr(b, label)
        if set(left) != set(right):
            missing = sorted(set(left) ^ set(right))
            return {"outcome": "incomplete", "reason": f"{label}-frame keys differ",
                    "first_missing_key": missing[0]}
        players = {(port, follower) for _, port, follower in left}
        frames = {frame for frame, _, _ in left}
        if not players or len(frames) != max(frames) - min(frames) + 1:
            return {"outcome": "incomplete", "reason": f"{label}-frame coverage has gaps"}
        for frame in frames:
            if any((frame, port, follower) not in left for port, follower in players):
                return {"outcome": "incomplete", "reason": f"{label}-frame player coverage has gaps"}
        for key in sorted(left):
            if set(left[key]) != set(right[key]):
                return {"outcome": "unsupported", "reason": f"{label}-frame fields differ",
                        "key": key}
    if set(a.pre) != set(a.post):
        return {"outcome": "incomplete", "reason": "pre/post frame coverage differs"}
    for key in sorted(a.pre):
        for label in ("pre", "post"):
            left, right = getattr(a, label)[key], getattr(b, label)[key]
            for field in left:
                if left[field] != right[field]:
                    return {"outcome": "divergent", "frame": key[0], "port": key[1],
                            "follower": key[2], "field": f"{label}.{field}",
                            "recorded": left[field], "reference": right[field]}
    if a.game_end != b.game_end:
        return {"outcome": "divergent", "field": "game_end",
                "recorded": a.game_end, "reference": b.game_end}
    return {"outcome": "equivalent", "scope": "finalized frame fields only",
            "version": a.version,
            "frames": len({frame for frame, _, _ in a.post}),
            "players": len(a.players()),
            "rollback_records": sum(len(records) - 1 for replay in (a, b)
                                    for events in replay.history.values()
                                    for records in events.values())}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recorded", required=True, type=Path)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--output", type=Path, help="optional JSON report path")
    args = parser.parse_args()
    result = compare(args.recorded, args.reference)
    report = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(report)
    print(report, end="")
    return {"equivalent": 0, "divergent": 1, "incomplete": 2,
            "invalid": 3, "unsupported": 4}[result["outcome"]]


if __name__ == "__main__":
    raise SystemExit(main())
