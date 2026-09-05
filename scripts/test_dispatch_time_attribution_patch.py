#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches" / "moderngekko-dolphin" / "0048-dispatch-time-attribution.patch"


def main() -> int:
    text = PATCH.read_text(encoding="utf-8")
    required = (
        "STATICRECOMP_DISPATCH_TIME_LOG",
        "Clock::now()",
        "dispatch_time_end - dispatch_time_start",
        "dispatch_clock_end - dispatch_time_end",
        "present_frame,emulated_frame,pc,host_ns,clock_ns",
        "m_dispatch_time_log_path.clear()",
    )
    missing = [fragment for fragment in required if fragment not in text]
    if missing:
        raise RuntimeError("dispatch-time patch is missing: " + ", ".join(missing))
    print("Dispatch-time attribution patch checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
