#!/usr/bin/env python3
"""Stage prepared private Melee modules in a local macOS app before signing."""
import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess


def stage_modules(template, output):
    prepared = []
    for revision in (0, 2):
        suffix = "-r2" if revision == 2 else ""
        pointer = template / f"build/modules-macos14{suffix}/GALE01/active-module.txt"
        if not pointer.is_file():
            continue
        module = Path(pointer.read_text().strip())
        if not module.is_absolute():
            repository_path = template.parent.parent / module
            module = repository_path if repository_path.is_file() else template / module
        if not module.is_file():
            raise ValueError(f"Revision {revision} desktop module not found: {module}")
        dol = template / f"extracted/Super-Smash-Bros-Melee-GALE01-r{revision}/sys/main.dol"
        digest = hashlib.sha256(dol.read_bytes()).hexdigest()
        manifest = module.parent / "manifest.txt"
        if not manifest.is_file() or f"dol_sha256={digest}" not in manifest.read_text().splitlines():
            raise ValueError(f"Revision {revision} module does not match extracted executable")
        build = subprocess.check_output(["vtool", "-show-build", str(module)], text=True)
        fields = dict(line.split() for line in build.splitlines() if len(line.split()) == 2)
        if fields.get("platform") != "MACOS" or int(fields.get("minos", "99").split(".")[0]) > 14:
            raise ValueError(f"Revision {revision} module does not target macOS 14")
        deps = subprocess.check_output(["otool", "-L", str(module)], text=True)
        if "/opt/homebrew" in deps or "/usr/local" in deps:
            raise ValueError(f"Revision {revision} module has non-portable dependencies")
        prepared.append((module, digest))
    if not prepared:
        raise ValueError("No prepared desktop modules found; run scripts/prepare-game.sh with your Melee disc first")

    # Validate every available revision before copying. A fresh v1.02 build has
    # only modules-macos14-r2; it must not depend on a previous v1.00 build.
    for module, digest in prepared:
        destination = output / "StaticRecompModules" / digest
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(module, destination / "gGALE01_recomp.dylib")
    # Preserve the bundle's legacy filename, preferring v1.00 when available.
    # The runner selects v1.02 by its executable hash, not this legacy copy.
    shutil.copy2(prepared[0][0], output / "gGALE01_recomp.dylib")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("template", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        stage_modules(args.template, args.output)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Cannot stage macOS modules: {error}\n")


if __name__ == "__main__":
    main()
