#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$(mktemp /tmp/meleepad-controller-mapping.XXXXXX)"
trap 'rm -f "$OUT"' EXIT
CORE="$ROOT/apple/ios/MeleePadCoreHost.mm"

xcrun clang++ -std=c++20 -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/tests/MeleePadControllerMappingTests.mm" \
  "$ROOT/apple/shared/MeleePadControllerMapping.mm" \
  "$ROOT/apple/shared/MeleePadInputPipeEncoder.mm" \
  "$ROOT/apple/shared/MeleePadSettings.mm" \
  -o "$OUT"
"$OUT"

grep -Fq 'state.cStickX = (int8_t)std::lround(gamepad.rightThumbstick.xAxis.value * 127.0f);' \
  "$ROOT/apple/ios/MeleePadGameViewController.mm"
grep -Fq 'state.cStickY = (int8_t)std::lround(gamepad.rightThumbstick.yAxis.value * 127.0f);' \
  "$ROOT/apple/ios/MeleePadGameViewController.mm"
python3 - "$ROOT/apple/ios/MeleePadGameViewController.mm" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text()
start = source.index('- (void)publishMergedInput')
end = source.index('- (void)pauseRuntimeForApplicationLifecycle', start)
merged = source[start:end]
if 'MeleePadApplyRightStickSmashMode' not in merged:
    raise SystemExit('C-stick combat conversion is not at the merged touch/controller boundary')

controller_start = source.index('- (void)publishInputFromController:')
controller_end = source.index('- (void)reconcileControllersForReason:', controller_start)
if 'MeleePadApplyRightStickSmashMode' in source[controller_start:controller_end]:
    raise SystemExit('controller-only C-stick conversion path remains')
PY
grep -Fq 'MemoryWatcherUtils::ReadStaticRecompU32' "$CORE"
grep -Fq '0x80477D68u' "$CORE"
if grep -Fq '0x804D6720u' "$CORE"; then
  echo "controller scene gate regressed to a revision-1.02 address" >&2
  exit 1
fi
