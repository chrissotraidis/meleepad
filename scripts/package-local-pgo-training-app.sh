#!/usr/bin/env bash
# Build a local instrumented PGO-training app from the user-owned disc. The
# generated module/app stay in ignored paths and the canonical module pointer
# is restored on every exit.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ISO=${1:-}
OUTPUT=${2:-$ROOT/build-macos/SsbmPad-PGO-Training.app}
ACTIVE="$ROOT/ref/ModernGekko-Template/build/modules-macos14/GALE01/active-module.txt"

if [[ -z "$ISO" ]]; then
  echo "usage: $0 /path/to/GALE01-revision-0.iso [output.app]" >&2
  exit 2
fi

active_backup=$(mktemp "${TMPDIR:-/tmp}/ssbmpad-active-module.XXXXXX")
had_active=0
if [[ -f "$ACTIVE" ]]; then
  cp "$ACTIVE" "$active_backup"
  had_active=1
fi
restore_active() {
  if [[ "$had_active" == 1 ]]; then
    cp "$active_backup" "$ACTIVE"
  elif [[ -f "$ACTIVE" ]]; then
    find "$ACTIVE" -delete
  fi
  find "$active_backup" -delete
}
trap restore_active EXIT

"$ROOT/scripts/prepare-game.sh" "$ISO" --pgo-generate

active_module=$(cat "$ACTIVE")
manifest="${active_module%/*}/manifest.txt"
if [[ ! -f "$manifest" ]] || ! grep -Fx "pgo_generate=1" "$manifest" >/dev/null; then
  echo "instrumented module manifest is missing pgo_generate=1" >&2
  exit 1
fi
if grep -F "pgo_profile_sha256=" "$manifest" >/dev/null; then
  echo "instrumented module manifest unexpectedly selects a PGO-use profile" >&2
  exit 1
fi
for symbol in staticrecomp_profile_reset staticrecomp_profile_dump; do
  if ! nm -gU "$active_module" | awk -v symbol="_$symbol" '$3 == symbol { found = 1 } END { exit !found }'; then
    echo "instrumented module is missing $symbol" >&2
    exit 1
  fi
done
for section in __llvm_covfun __llvm_covmap; do
  if ! otool -l "$active_module" | awk '$1 == "sectname" { print $2 }' |
       grep -Fx "$section" >/dev/null; then
    echo "instrumented module is missing coverage section $section" >&2
    exit 1
  fi
done

SSBMPAD_MACOS_OUTPUT="$OUTPUT" "$ROOT/scripts/package-macos-app.sh"
"$ROOT/scripts/test-macos-package-layout.sh" "$OUTPUT"
codesign --verify --deep --strict "$OUTPUT"

echo "Local PGO training app: $OUTPUT"
echo "Instrumented module SHA-256: $(shasum -a 256 "$OUTPUT/Contents/MacOS/gGALE01_recomp.dylib" | awk '{print $1}')"
