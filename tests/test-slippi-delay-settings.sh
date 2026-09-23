#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
output="$(mktemp /tmp/meleepad-slippi-delay.XXXXXX)"
trap 'rm -f "$output"' EXIT
xcrun clang++ -std=c++20 -fobjc-arc -framework Foundation \
  -I"$root/apple/shared" \
  "$root/tests/MeleePadSlippiDelaySettingsTests.mm" \
  "$root/apple/shared/MeleePadSettings.mm" -o "$output"
"$output"
