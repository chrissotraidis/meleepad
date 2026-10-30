#!/usr/bin/env bash
set -euo pipefail
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
clang++ -std=c++20 -fobjc-arc -fblocks -fsanitize=address,undefined -g \
  -I"$ROOT/tests/fixtures/discio" -framework Foundation \
  "$ROOT/tests/MeleePadExtractionProgressTests.mm" -o "$TEMP/test"
"$TEMP/test"
