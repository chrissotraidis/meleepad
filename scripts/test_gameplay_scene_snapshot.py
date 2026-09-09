#!/usr/bin/env python3
"""Exercise the shipped scene snapshot patch without a private game checkout."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
patch = (ROOT / "patches/moderngekko-dolphin/0058-gameplay-scene-snapshot.patch").read_text()
name = "Source/Core/Common/GameplaySceneSnapshot.h"
section = patch.split(f"diff --git a/{name} b/{name}\n", 1)[1].split("\ndiff --git ", 1)[0]
header = "\n".join(line[1:] for line in section.splitlines() if line.startswith("+") and not line.startswith("+++")) + "\n"
with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    (root / "Common").mkdir()
    (root / "Common/GameplaySceneSnapshot.h").write_text(header)
    executable = root / "scene-tests"
    subprocess.run(["c++", "-std=c++20", "-O2", "-pthread", f"-I{root}", str(ROOT / "tests/GameplaySceneSnapshotTests.cpp"), "-o", str(executable)], check=True)
    subprocess.run([str(executable)], check=True, timeout=20)
print("Scene snapshot lifecycle, revision, transition and concurrency checks passed")
