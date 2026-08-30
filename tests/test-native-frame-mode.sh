#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HOST="$ROOT/apple/ios/SsbmPadCoreHost.mm"

grep -Fq 'config.enable_gmse01_60fps = false;' "$HOST"
grep -Fq '_activeFrameMode = @"native-60-fps";' "$HOST"
grep -Fq 'runtime frame mode=native 60 FPS source=GALE01' "$HOST"
if rg -q 'Experimental60FPS|experimental60FPS|Experimental 60 FPS' \
    "$ROOT/apple"; then
  echo "Sunshine-only 60 FPS control leaked into SsbmPad" >&2
  exit 1
fi
echo "GALE01 native frame-mode checks passed"
