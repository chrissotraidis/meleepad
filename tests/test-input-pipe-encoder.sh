#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

if rg -q 'SsbmPadInputState state;' "$ROOT/apple/ios/SsbmPadGameViewController.mm"; then
  echo "uninitialized controller snapshot found" >&2
  exit 1
fi
rg -q 'SsbmPadInputState state = \{\};' "$ROOT/apple/ios/SsbmPadGameViewController.mm"

clang++ -x objective-c++ -std=gnu++2b -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/apple/shared/SsbmPadInputPipeEncoder.mm" \
  "$ROOT/tests/SsbmPadInputPipeEncoderTests.mm" \
  -o "$TEMP_DIR/SsbmPadInputPipeEncoderTests"
"$TEMP_DIR/SsbmPadInputPipeEncoderTests"
