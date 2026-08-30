#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$(mktemp /tmp/ssbmpad-controller-mapping.XXXXXX)"
trap 'rm -f "$OUT"' EXIT

xcrun clang++ -std=c++20 -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/tests/SsbmPadControllerMappingTests.mm" \
  "$ROOT/apple/shared/SsbmPadControllerMapping.mm" \
  -o "$OUT"
"$OUT"
