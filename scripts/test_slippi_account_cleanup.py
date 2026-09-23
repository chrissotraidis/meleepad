#!/usr/bin/env python3
"""Exercise the real Slippi account handoff and interrupted-run cleanup."""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
include = root / "ref/ModernGekko/vendor/dolphin/SlippiAdapter/Externals"
with tempfile.TemporaryDirectory(prefix="meleepad-account-cleanup-") as temporary:
    binary = Path(temporary) / "account-test"
    subprocess.run(
        [*shlex.split(os.environ.get("CXX", "c++")), "-std=c++17", "-O2",
         "-I", str(include), str(root / "scripts/slippi-probe-account-test.cpp"),
         "-o", str(binary)],
        check=True, timeout=60,
    )
    subprocess.run([str(binary), str(Path(temporary) / "fixture")],
                   check=True, timeout=10)
