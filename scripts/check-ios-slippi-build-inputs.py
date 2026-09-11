#!/usr/bin/env python3
"""Verify the private inputs required by the iPhoneOS Slippi target.

The generated Slippi overlay and native dependency archives are intentionally
kept under ``ref/`` and are not part of the repository. This check reports the
complete missing-input set before Xcode starts compiling; it never downloads,
generates, signs, installs, or reads game/account data.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


OVERLAY = Path("ref/slippi-compatibility/ios-direct-005/overlay")
OVERLAY_FILES = (
    "Core/Slippi/SlippiCompat.h",
    "Core/Slippi/SlippiDirectCodes.cpp",
    "Core/Slippi/SlippiGame.cpp",
    "Core/Slippi/SlippiGameFileLoader.cpp",
    "Core/Slippi/SlippiMatchmaking.cpp",
    "Core/Slippi/SlippiNetplay.cpp",
    "Core/Slippi/SlippiPad.cpp",
    "Core/Slippi/SlippiPlayback.cpp",
    "Core/Slippi/SlippiReplayComm.cpp",
    "Core/Slippi/SlippiSavestate.cpp",
    "Core/Slippi/SlippiSpectate.cpp",
    "Core/Slippi/SlippiStrings.cpp",
    "Core/Slippi/SlippiUser.cpp",
    "Core/HW/EXI/EXI_DeviceSlippi.cpp",
    "Core/Cheats/GeckoCode.cpp",
    "Core/State.cpp",
    "Core/HW/DVD/DVDThread.cpp",
    "VideoCommon/OnScreenDisplay.cpp",
    "Core/HW/EXI/EXI_Device.cpp",
    "Core/PowerPC/JitCommon/JitCache.cpp",
    "Core/HLE/HLE_Misc.cpp",
)


def project_paths(project: Path) -> set[Path]:
    text = project.read_text()
    return {
        Path(match.group(1))
        for match in re.finditer(r"\$\(SRCROOT\)/(ref/[A-Za-z0-9_./+_-]+)", text)
    }


def response_paths(response: Path) -> set[Path]:
    paths = set()
    if not response.is_file():
        return paths
    for line in response.read_text().splitlines():
        value = line.strip()
        if value.startswith("-Wl,-force_load,"):
            value = value.removeprefix("-Wl,-force_load,")
        if value.startswith("/"):
            paths.add(Path(value))
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable status")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[1]
    project = repo / "MeleePad.xcodeproj/project.pbxproj"
    response = repo / "apple/ios/Provisioned/iphoneos/libs/MeleePadSlippiCore.rsp"

    required = {repo / OVERLAY}
    required.update(repo / OVERLAY / path for path in OVERLAY_FILES)
    required.add(repo / "ref/slippi-compatibility/local-online-guest-008/Interpreter_LoadStore.cpp")
    required.add(response)
    required.update(repo / path for path in project_paths(project) if path != OVERLAY)
    required.update(path for path in response_paths(response) if path.is_relative_to(repo))

    missing = sorted(path.relative_to(repo) for path in required if not path.exists())
    result = {
        "pass": not missing,
        "required_paths": len(required),
        "missing": [str(path) for path in missing],
        "scope": "private prepared iPhoneOS Slippi inputs; no game or account data",
    }
    if args.json:
        import json

        print(json.dumps(result, indent=2))
    elif missing:
        print("missing iPhoneOS Slippi build inputs:")
        for path in missing:
            print(f"  {path}")
        print(
            "Prepare the ignored dependency tree and native archives before "
            "running the iPhoneOS build. No game data or account file is "
            "created by this check."
        )
    else:
        print(f"iPhoneOS Slippi build inputs present ({len(required)} paths)")
    return 0 if not missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
