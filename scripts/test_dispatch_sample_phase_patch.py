#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches/moderngekko-dolphin/0037-dispatch-sample-phase-control.patch"


def main() -> None:
    text = PATCH.read_text(encoding="utf-8")
    required = (
        "STATICRECOMP_DISPATCH_SAMPLE_INTERVAL",
        "STATICRECOMP_DISPATCH_SAMPLE_OFFSET",
        "m_native_dispatches % m_dispatch_sample_interval",
        "m_dispatch_sample_offset",
        "std::clamp<u64>",
    )
    for fragment in required:
        if fragment not in text:
            raise RuntimeError(f"dispatch sample phase patch is missing: {fragment}")
    if "+          if (sample_dispatches && (m_native_dispatches & 4095u)" in text:
        raise RuntimeError("fixed one-in-4096 condition remains in the phase-control patch")
    print("Dispatch sample phase-control source checks passed")


if __name__ == "__main__":
    main()
