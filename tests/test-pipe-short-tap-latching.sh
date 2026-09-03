#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOLPHIN="$ROOT/ref/ModernGekko/vendor/dolphin"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

clang++ -std=c++20 \
  -I"$DOLPHIN/Source/Core" \
  -I"$DOLPHIN/Externals/fmt/fmt/include" \
  "$ROOT/tests/MeleePadPipeShortTapTests.cpp" \
  -o "$TEMP_DIR/MeleePadPipeShortTapTests"

"$TEMP_DIR/MeleePadPipeShortTapTests"
