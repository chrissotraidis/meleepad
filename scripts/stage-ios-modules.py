#!/usr/bin/env python3
"""Stage private locally built modules in an unsigned local app before signing.

Never use the resulting playable app as input to the public IPA packager.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--platform", choices=["device", "simulator"], required=True)
    args = parser.parse_args()
    if not (args.app / "Info.plist").is_file():
        parser.error("Expected a locally built iOS .app directory")
    catalog = json.loads((ROOT / "apple/shared/MeleePadRevisions.json").read_text())
    staged = []
    for revision in catalog:
        number = revision["revision"]
        suffix = "-r2" if number == 2 else ""
        directory = Path(f"/tmp/meleepad-module-ios-{args.platform}{suffix}")
        module = directory / "gGALE01_recomp.dylib"
        identity = directory / "gGALE01_recomp.dylib.dol-sha256"
        if not module.is_file():
            continue
        if not identity.is_file() or identity.read_text().strip() != revision["dol_sha256"]:
            parser.error(f"v{revision['version']} module identity is missing or mismatched")
        platform = subprocess.check_output(["vtool", "-show-build", str(module)], text=True)
        expected = "IOSSIMULATOR" if args.platform == "simulator" else "IOS"
        if not any(line.strip() == f"platform {expected}" for line in platform.splitlines()):
            parser.error("Module belongs to a different Apple platform")
        name = "gGALE01r2_recomp.dylib" if number == 2 else "gGALE01_recomp.dylib"
        staged.append((module, identity, name))
    if not staged:
        parser.error("No matching locally built modules are available")
    # Validate every source before modifying the destination.
    for module, identity, name in staged:
        shutil.copy2(module, args.app / name)
        shutil.copy2(identity, args.app / (name + ".dol-sha256"))
        print(f"Staged {name}; sign the module and app before device installation")


if __name__ == "__main__":
    main()
