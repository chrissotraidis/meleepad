#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

git diff --check
for script in scripts/*.sh; do
  bash -n "$script"
done
for script in tests/*.sh; do
  bash -n "$script"
done
python3 scripts/test_classify_g5_intervals.py
python3 scripts/test_analyze_triggered_native_pcs.py
python3 scripts/test_lightweight_frame_timing_patch.py
python3 scripts/test_triggered_thread_sampler.py
tests/test-input-pipe-encoder.sh
tests/test-pipe-short-tap-latching.sh
tests/test-controller-mapping.sh
tests/test-controller-slots.sh
tests/test-diagnostics.sh
tests/test-macos-diagnostics-export.sh
tests/test-macos-keyboard-profile.sh
tests/test-experimental-performance-config.sh
tests/test-native-frame-mode.sh
tests/test-iphone-touch-layout-defaults.sh
tests/test-touch-stick-accessibility.sh
tests/test-game-data-setup.sh
tests/test-ios-audio-diagnostics.sh
tests/test-ios-external-pipe-input.sh
tests/test-static-recomp-loop-hoists.sh

prohibited=$(git ls-files | grep -E \
  '(^|/)(ref|DerivedData|Provisioned|build[^/]*)/|\.(iso|gcm|rvz|wia|wbfs|gcz|dylib|ipa|xcarchive|mobileprovision|p12|pem|key|gci|sav|raw|profraw|profdata)$' || true)
if [[ -n "$prohibited" ]]; then
  echo "prohibited tracked material:" >&2
  echo "$prohibited" >&2
  exit 1
fi

if git grep -n -I -E \
  'BEGIN [A-Z ]*PRIVATE KEY|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}' -- .; then
  echo "possible credential material found" >&2
  exit 1
fi

echo "Repository checks passed"
