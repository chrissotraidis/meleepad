#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$(mktemp /tmp/ssbmpad-controller-mapping.XXXXXX)"
trap 'rm -f "$OUT"' EXIT
CORE="$ROOT/apple/ios/SsbmPadCoreHost.mm"

xcrun clang++ -std=c++20 -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/tests/SsbmPadControllerMappingTests.mm" \
  "$ROOT/apple/shared/SsbmPadControllerMapping.mm" \
  -o "$OUT"
"$OUT"

grep -Fq 'MemoryWatcherUtils::ReadStaticRecompU32' "$CORE"
grep -Fq '0x80477D68u' "$CORE"
if grep -Fq '0x804D6720u' "$CORE"; then
  echo "controller scene gate regressed to a revision-1.02 address" >&2
  exit 1
fi
