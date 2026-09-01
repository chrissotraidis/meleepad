#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    patch = (ROOT / "patches/moderngekko-dolphin/0038-caller-qualified-idle-preflight.patch").read_text()
    required = (
        "STATICRECOMP_CALLER_IDLE_PC",
        "STATICRECOMP_CALLER_IDLE_LR",
        "MAIN_STATICRECOMP_CALLER_IDLE_PC",
        "MAIN_STATICRECOMP_CALLER_IDLE_LR",
        "m_guest.pc == m_caller_idle_pc",
        "m_guest.lr == m_caller_idle_lr",
        "caller_idle=%llu",
    )
    for fragment in required:
        if fragment not in patch:
            raise RuntimeError(f"caller-qualified idle patch is missing: {fragment}")
    if "m_guest.pc == m_caller_idle_pc ||" in patch:
        raise RuntimeError("caller-qualified idle may not ignore the LR guard")
    host = (ROOT / "apple/ios/SsbmPadCoreHost.mm").read_text()
    host_required = (
        "MAIN_STATICRECOMP_CALLER_IDLE_PC, 0x80019550u",
        "MAIN_STATICRECOMP_CALLER_IDLE_LR, 0x801A4064u",
        "caller=80019550/801A4064",
    )
    for fragment in host_required:
        if fragment not in host:
            raise RuntimeError(f"iOS product caller-idle config is missing: {fragment}")
    print("Caller-qualified idle preflight source checks passed")


if __name__ == "__main__":
    main()
