#!/usr/bin/env python3
"""Verify source and library availability for the pinned iOS Slippi adapter."""

from __future__ import annotations

import argparse
import re
import shlex
from pathlib import Path


OVERLAY = Path("ref/ModernGekko/vendor/dolphin/SlippiAdapter/Source")
SLIPPI_GAME_SETTINGS = Path(
    "ref/slippi-compatibility/upstream/Data/Sys/GameSettings/GALE01r2.ini"
)
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

# The overlay is generated/private, so its path can remain present while its
# contents come from an older Direct-only build. Keep this contract limited to
# non-sensitive source markers that define the currently accepted search modes.
OVERLAY_CONTRACTS = {
    "Core/Slippi/SlippiNetplay.cpp": (
        "NET_SERVICE_TYPE_RV",
        "slippi_network_diagnostics.ObservePing",
        "slippi_network_diagnostics.peer_disconnects",
        "slippi_network_diagnostics.ObserveQueue",
        "slippi_network_diagnostics.ObserveThrottle",
    ),
    "Core/HW/EXI/EXI_DeviceSlippi.cpp": (
        "SlippiDirectProbe::AllowsSearch",
        "SlippiDirectProbe::ObserveMatchmakingState",
        "SlippiDirectProbe::SearchDeniedMessage",
        "SlippiDirectProbe::ObserveSearch",
        "SampleSlippiNativeCounters",
    ),
}


def project_paths(project: Path) -> set[Path]:
    text = project.read_text()
    return {
        Path(match.group(1))
        for match in re.finditer(r"\$\(SRCROOT\)/(ref/[A-Za-z0-9_./+_-]+)", text)
    }


def response_paths(response: Path, repo: Path) -> set[Path]:
    """Read the deliberately small response-file format emitted by provisioning.

    Reject unsupported arguments instead of silently skipping linker inputs.
    Relative paths are relative to Xcode's project working directory.
    """
    paths = set()
    if not response.is_file():
        return paths
    for value in shlex.split(response.read_text()):
        if value.startswith("-Wl,-force_load,"):
            value = value.removeprefix("-Wl,-force_load,")
        elif value.startswith(("-", "@")):
            raise ValueError("unsupported response-file argument: " + value)
        path = Path(value)
        if path.suffix not in (".a", ".o"):
            raise ValueError("expected archive or object in response file: " + value)
        paths.add(path if path.is_absolute() else repo / path)
    if not paths:
        raise ValueError("linker response file is empty")
    return paths


def check_inputs(repo: Path, *, sources_only: bool = False) -> dict:
    project = repo / "MeleePad.xcodeproj/project.pbxproj"
    response = repo / "apple/ios/Provisioned/iphoneos/libs/MeleePadSlippiCore.rsp"
    required = {repo / OVERLAY}
    required.add(repo / "scripts/slippi-network-diagnostics.hpp")
    required.add(repo / "scripts/slippi-native-diagnostics.hpp")
    required.update(repo / OVERLAY / path for path in OVERLAY_FILES)
    required.add(repo / "ref/ModernGekko/vendor/dolphin/SlippiAdapter/Source/Core/PowerPC/Interpreter_LoadStore.cpp")
    required.update(repo / path for path in project_paths(project) if path != OVERLAY and "iphonesimulator" not in str(path) and (not sources_only or path.suffix not in (".a", ".o")))
    response_errors = []
    if not sources_only:
        required.add(response)
        try:
            required.update(response_paths(response, repo))
        except ValueError as error:
            response_errors.append(str(error))

    def label(path):
        return str(path.relative_to(repo)) if path.is_relative_to(repo) else str(path)

    missing = sorted(label(path) for path in required if not path.exists() or
                     (path.suffix in (".a", ".o", ".rsp", ".cpp", ".h", ".hpp", ".ini")
                      and not path.is_file()))
    invalid = []
    for relative, markers in OVERLAY_CONTRACTS.items():
        path = repo / OVERLAY / relative
        if path.exists():
            text = path.read_text()
            absent = [marker for marker in markers if marker not in text]
            if absent:
                invalid.append({"path": str(OVERLAY / relative), "missing_markers": absent})
    result = {
        "pass": not missing and not invalid and not response_errors,
        "required_paths": len(required),
        "missing": missing,
        "response_errors": response_errors,
        "response_checked": not sources_only,
        "invalid": invalid,
        "scope": "pinned iPhoneOS Slippi adapter inputs; availability check",
    }
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="emit machine-readable status")
    parser.add_argument("--sources-only", action="store_true",
                        help="pre-provision check; skip the not-yet-generated linker response")
    args = parser.parse_args()
    result = check_inputs(Path(__file__).resolve().parents[1], sources_only=args.sources_only)
    if args.json:
        import json

        print(json.dumps(result, indent=2))
    elif not result["pass"]:
        print("missing iPhoneOS Slippi build inputs:")
        for path in result["missing"]:
            print(f"  {path}")
        if result["invalid"]:
            print("invalid iPhoneOS Slippi overlay contracts:")
            for contract in result["invalid"]:
                print(f"  {contract['path']}")
                for marker in contract["missing_markers"]:
                    print(f"    missing marker: {marker}")
        for error in result["response_errors"]:
            print(f"  {error}")
        print(
            "Bootstrap pinned sources and run build-slippi-dependencies.py; "
            "before running "
            "the iPhoneOS build. No game data or account file is created by "
            "this check."
        )
    else:
        print(f"iPhoneOS Slippi build inputs present ({result['required_paths']} paths; "
              f"response checked={result['response_checked']}; availability only)")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
