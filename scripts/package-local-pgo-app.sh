#!/usr/bin/env bash
# Build and package a local PGO app from user-owned disc/profile inputs. The
# profile and generated module remain outside Git; only their hashes enter the
# private module-cache manifest.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ISO=${1:-}
PROFILE=${2:-}
OUTPUT=${3:-$ROOT/build-macos/SsbmPad-PGO.app}
ACTIVE="$ROOT/ref/ModernGekko-Template/build/modules-macos14/GALE01/active-module.txt"

if [[ -z "$ISO" || -z "$PROFILE" ]]; then
  echo "usage: $0 /path/to/GALE01-revision-0.iso private-profile.profdata [output.app]" >&2
  exit 2
fi
if [[ ! -f "$PROFILE" ]]; then
  echo "PGO profile is unavailable" >&2
  exit 2
fi
PROFILE="$(cd "$(dirname "$PROFILE")" && pwd)/$(basename "$PROFILE")"
if ! xcrun llvm-profdata show "$PROFILE" >/dev/null 2>&1; then
  echo "PGO profile is not valid LLVM profile data" >&2
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

"$ROOT/scripts/prepare-game.sh" "$ISO" "$PROFILE"

active_module=$(cat "$ACTIVE")
manifest="${active_module%/*}/manifest.txt"
profile_hash=$(shasum -a 256 "$PROFILE" | awk '{print $1}')
if [[ ! -f "$manifest" ]] ||
   ! grep -Fx "pgo_profile_sha256=$profile_hash" "$manifest" >/dev/null; then
  echo "PGO module manifest does not match the private profile hash" >&2
  exit 1
fi
if grep -F "$PROFILE" "$manifest" >/dev/null; then
  echo "PGO module manifest leaked the private profile path" >&2
  exit 1
fi

SSBMPAD_MACOS_OUTPUT="$OUTPUT" "$ROOT/scripts/package-macos-app.sh"
"$ROOT/scripts/test-macos-package-layout.sh" "$OUTPUT"
if ! codesign --verify --deep --strict "$OUTPUT"; then
  echo "local PGO app signature verification failed" >&2
  exit 1
fi

echo "Local PGO app: $OUTPUT"
echo "Private profile SHA-256: $profile_hash"
