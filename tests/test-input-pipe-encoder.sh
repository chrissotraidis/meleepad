#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

if rg -q 'MeleePadInputState state;' "$ROOT/apple/ios/MeleePadGameViewController.mm"; then
  echo "uninitialized controller snapshot found" >&2
  exit 1
fi
rg -q 'MeleePadInputState state = \{\};' "$ROOT/apple/ios/MeleePadGameViewController.mm"

clang++ -x objective-c++ -std=gnu++2b -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/apple/shared/MeleePadInputPipeEncoder.mm" \
  "$ROOT/tests/MeleePadInputPipeEncoderTests.mm" \
  -o "$TEMP_DIR/MeleePadInputPipeEncoderTests"
"$TEMP_DIR/MeleePadInputPipeEncoderTests"
