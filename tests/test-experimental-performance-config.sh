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
SETTINGS_HEADER="$ROOT/apple/shared/SsbmPadSettings.h"
OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"
for contract in \
  '-ssbmpadExperimentalPerformanceMode' \
  '-ssbmpadExperimentalPerformance95' \
  '-ssbmpadExperimentalPerformanceQoSOnly' \
  'QOS_CLASS_USER_INITIATED' \
  'experimental-single-core-90' \
  'experimental-single-core-95' \
  'experimental-qos-only-100' \
  'cpuVideoSplit=1' \
  'syncGPU=1' \
  'shaderCompilerThreads=3' \
  'runtime render scale=%ld source=live' \
  'runtime aspect mode=%@ source=%@'; do
  grep -Fq -- "$contract" "$HOST"
done
grep -Fq 'Config::SetBase(Config::MAIN_CPU_THREAD, true);' \
  "$ROOT/ref/ModernGekko/src/runtime/dolphin_runtime.cpp"
grep -Fq 'Config::SetBase(Config::MAIN_SYNC_GPU, true);' \
  "$ROOT/ref/ModernGekko/src/runtime/dolphin_runtime.cpp"
grep -Fq 'Config::SetBase(Config::GFX_SHADER_COMPILER_THREADS, 3);' \
  "$ROOT/ref/ModernGekko/src/runtime/dolphin_runtime.cpp"
grep -Fq 'Config::SetBase(Config::GFX_HACK_SKIP_DUPLICATE_XFBS, false);' \
  "$ROOT/ref/ModernGekko/src/runtime/dolphin_runtime.cpp"

# Experimental clock/QoS variants remain explicit developer launch arguments,
# never a user-facing product mode. Remove the old persisted preference during
# settings initialization so an existing install cannot remain at 90% clock.
grep -Fq 'removeObjectForKey:@"SsbmPadExperimentalPerformanceMode"' "$SETTINGS"
if grep -Fq 'experimentalPerformanceMode' "$SETTINGS_HEADER" "$SETTINGS" "$HOST" "$OVERLAY"; then
  echo "experimental performance preference remains in product code" >&2
  exit 1
fi
if grep -Fq 'Experimental Performance Mode' "$OVERLAY"; then
  echo "experimental performance mode remains in the three-dot menu" >&2
  exit 1
fi
if grep -Fq 'menuPreferencePerformance' "$HOST"; then
  echo "runtime still accepts the removed menu preference" >&2
  exit 1
fi

for menu_contract in \
  'Render Resolution' \
  'Aspect Ratio' \
  'Show FPS Counter' \
  'Controller Button Mapping…' \
  'Touch Control Settings…' \
  'Game Data & Saves' \
  'Share Diagnostic Log…' \
  'Report a Problem…'; do
  grep -Fq -- "$menu_contract" "$OVERLAY"
done
grep -Fq -- '- (void)shareDiagnosticLog' "$OVERLAY"

echo "Performance launch-argument and three-dot menu checks passed"
