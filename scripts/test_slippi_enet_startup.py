#!/usr/bin/env python3
"""Compile and exercise the vendored ENet RTT/throttle implementation locally."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    enet = root / "ref/ModernGekko/vendor/dolphin/Externals/enet/enet"
    fixture = root / "tests/SlippiENetStartupTests.c"
    sources = [enet / f"{name}.c" for name in
               ("callbacks", "compress", "host", "list", "packet", "peer", "unix")]
    required = [fixture, enet / "protocol.c", enet / "include/enet/enet.h", *sources]
    missing = [str(path.relative_to(root)) for path in required if not path.is_file()]
    if missing:
        raise SystemExit("Missing ENet test inputs; bootstrap the checkout first: "
                         + ", ".join(missing))
    compiler = shlex.split(os.environ.get("CC", "cc"))
    if not compiler or shutil.which(compiler[0]) is None:
        raise SystemExit("A C compiler is required (set CC or install cc).")

    # Build from the current vendored source, never a potentially stale archive.
    # The fixture includes protocol.c to reach the actual private ACK handler.
    with tempfile.TemporaryDirectory(prefix="meleepad-enet-startup-") as temporary:
        binary = Path(temporary) / "enet-startup-test"
        command = [*compiler, "-std=c99", "-O2", "-I", str(enet),
                   "-I", str(enet / "include"), str(fixture),
                   *(str(source) for source in sources), "-o", str(binary)]
        subprocess.run(command, check=True, timeout=60)
        subprocess.run([str(binary)], check=True, timeout=10)


if __name__ == "__main__":
    main()
