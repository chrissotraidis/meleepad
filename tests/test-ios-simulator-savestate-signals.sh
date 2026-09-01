#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE="$ROOT/ref/ModernGekko/src/runtime/dolphin_runtime.cpp"
PATCH="$ROOT/patches/moderngekko/0012-ios-simulator-savestate-signals.patch"

grep -Fq '#include <TargetConditionals.h>' "$SOURCE"
grep -Fq 'TARGET_OS_SIMULATOR' "$SOURCE"
grep -Fq '#define MODERNGEKKO_HAVE_SAVESTATE_SIGNALS 1' "$SOURCE"
[[ "$(grep -Fc '#if defined(MODERNGEKKO_HAVE_SAVESTATE_SIGNALS)' "$SOURCE")" -eq 2 ]]
grep -Fq 'MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS' "$SOURCE"
grep -Fq 'TARGET_OS_SIMULATOR' "$PATCH"
grep -Fq 'ios_simulator_savestate_signals_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

echo "iOS Simulator savestate signal source checks passed"
