#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$(mktemp /tmp/ssbmpad-performance-config.XXXXXX)"
trap 'rm -f "$OUT"' EXIT

clang++ -std=c++23 -I "$ROOT/ref/ModernGekko/include" \
  "$ROOT/tests/SsbmPadExperimentalPerformanceConfigTests.cpp" -o "$OUT"
"$OUT"

HOST="$ROOT/apple/ios/SsbmPadCoreHost.mm"
SETTINGS="$ROOT/apple/shared/SsbmPadSettings.mm"
OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"
for contract in \
  '-ssbmpadExperimentalPerformanceMode' \
  '-ssbmpadExperimentalPerformance95' \
  '-ssbmpadExperimentalPerformanceQoSOnly' \
  'QOS_CLASS_USER_INITIATED' \
  'experimental-single-core-90' \
  'experimental-single-core-95' \
  'experimental-qos-only-100' \
  'runtime render scale=%ld source=live' \
  'runtime aspect mode=%@ source=%@'; do
  grep -Fq -- "$contract" "$HOST"
done
grep -Fq 'SsbmPadExperimentalPerformanceMode' "$SETTINGS"
grep -Fq 'Experimental Performance Mode (Restart Required)' "$OVERLAY"
echo "Experimental performance configuration checks passed"
