#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MODULE_CMAKE="$ROOT/ref/ModernGekko/vendor/dolphin/module-template/CMakeLists.txt"
BUILD_SCRIPT="$ROOT/scripts/ios-build-core-device.sh"
BOOTSTRAP="$ROOT/scripts/bootstrap-dependencies.sh"
PATCH="$ROOT/patches/moderngekko-dolphin/0050-module-cpu-tune.patch"

grep -Fq 'set(RECOMPCORE_MODULE_TUNE_CPU "" CACHE STRING' "$MODULE_CMAKE"
grep -Fq '"-mtune=${RECOMPCORE_MODULE_TUNE_CPU}"' "$MODULE_CMAKE"
grep -Fq -- '-DRECOMPCORE_MODULE_TUNE_CPU=apple-a15' "$BUILD_SCRIPT"
grep -Fq 'module_cpu_tune_patch=' "$BOOTSTRAP"
grep -Fq 'RECOMPCORE_MODULE_TUNE_CPU' "$PATCH"

if grep -Fq -- '-mcpu=apple-a15' "$BUILD_SCRIPT"; then
  echo "physical iOS module build must tune scheduling without raising its ISA target" >&2
  exit 1
fi

echo "iOS generated-module CPU tuning checks passed"
