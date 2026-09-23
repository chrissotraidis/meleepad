#!/usr/bin/env python3
"""Exercise the replay picker against normal, partial, and symlinked run layouts."""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="meleepad-replay-library-") as temporary:
    binary = Path(temporary) / "replay-test"
    subprocess.run(
        [*shlex.split(os.environ.get("CXX", "c++")), "-std=c++17", "-O2",
         str(root / "scripts/slippi-replay-library-test.cpp"), "-o", str(binary)],
        check=True, timeout=60,
    )
    subprocess.run([str(binary), str(Path(temporary) / "fixture")],
                   check=True, timeout=10)
