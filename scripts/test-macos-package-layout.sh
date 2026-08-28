#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP="${1:-$ROOT/build-macos/SsbmPad.app}"
SYS="$APP/Contents/Resources/Sys"

test -x "$APP/Contents/MacOS/SsbmPad"
test -x "$APP/Contents/MacOS/SsbmPadFrontend"
test -x "$APP/Contents/MacOS/SsbmPadRunner"
test -f "$APP/Contents/MacOS/gGALE01_recomp.dylib"
strings "$APP/Contents/MacOS/SsbmPadRunner" | grep -F \
  "metal layer display sync: product policy enabled" >/dev/null
test -f "$SYS/GameSettings/GALE01r0.ini"
grep -Eq '^StaticRecompIdlePC = 0x80349494$' \
  "$SYS/GameSettings/GALE01r0.ini"

echo "macOS package layout: pass"
