#!/usr/bin/env python3
"""Exercise the shared Home/boot image lookup with synthetic files."""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="meleepad-disc-availability-") as temporary:
    binary = Path(temporary) / "disc-test"
    subprocess.run(
        [*shlex.split(os.environ.get("CXX", "c++")), "-std=c++17", "-O2",
         "-I", str(root / "apple/shared"),
         str(root / "tests/MeleePadDiscAvailabilityTests.cpp"), "-o", str(binary)],
        check=True, timeout=60,
    )
    subprocess.run([str(binary), str(Path(temporary) / "fixture")],
                   check=True, timeout=10)
