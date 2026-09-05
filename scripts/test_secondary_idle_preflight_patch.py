#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    patch = (
        ROOT / "patches/moderngekko-dolphin/0049-secondary-idle-preflight.patch"
    ).read_text(encoding="utf-8")
    required = (
        "STATICRECOMP_SECONDARY_IDLE_PC",
        "MAIN_STATICRECOMP_SECONDARY_IDLE_PC",
        "StaticRecompSecondaryIdlePC = 0x80349494",
        "m_secondary_idle_pc",
        "secondary_idle_pc != 0 && m_guest.pc == secondary_idle_pc",
        "m_system.GetCoreTiming().Idle()",
        "secondary_idle=%llu",
    )
    for fragment in required:
        if fragment not in patch:
            raise RuntimeError(f"secondary-idle patch is missing: {fragment}")
    host = (ROOT / "apple/ios/MeleePadCoreHost.mm").read_text(encoding="utf-8")
    host_required = (
        "MAIN_STATICRECOMP_SECONDARY_IDLE_PC, 0x80349494u",
        "secondary=80349494",
    )
    for fragment in host_required:
        if fragment not in host:
            raise RuntimeError(f"iOS product secondary-idle config is missing: {fragment}")
    print("Secondary-idle preflight source checks passed")


if __name__ == "__main__":
    main()
