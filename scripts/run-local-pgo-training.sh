#!/usr/bin/env bash
# Run the local training app with combat-only reset/dump hooks armed. Navigate
# into a revision-0 match that satisfies the trigger, complete/leave it, then
# quit normally so LLVM finalizes the private raw profile.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP=${1:-$ROOT/build-macos/SsbmPad-PGO-Training.app}
USER_DIR=${2:-}
RAW_DIR=${3:-}
TRIGGER=${SSBMPAD_PGO_TRIGGER:-80477D68,ffffffff,02020102}
GAME="$ROOT/ref/ModernGekko-Template/extracted/Super-Smash-Bros-Melee-GALE01-r0"

if [[ -z "$USER_DIR" || -z "$RAW_DIR" ]]; then
  echo "usage: $0 training.app private-user-dir private-raw-profile-dir" >&2
  exit 2
fi
if [[ ! -x "$APP/Contents/MacOS/SsbmPadRunner" ||
      ! -f "$APP/Contents/MacOS/gGALE01_recomp.dylib" ||
      ! -f "$GAME/.ssbmpad-source-sha256" ]]; then
  echo "training app or private extracted game is unavailable" >&2
  exit 2
fi
mkdir -p "$USER_DIR" "$RAW_DIR"
if find "$RAW_DIR" -type f -name '*.profraw' -print -quit | grep . >/dev/null; then
  echo "raw profile directory is not empty: $RAW_DIR" >&2
  exit 2
fi

echo "PGO trigger: $TRIGGER"
echo "Complete or leave the triggered match, then quit the app normally."
env \
  LLVM_PROFILE_FILE="$RAW_DIR/ssbmpad-%p.profraw" \
  STATICRECOMP_PROFILE_TRIGGER="$TRIGGER" \
  MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1 \
  "$APP/Contents/MacOS/SsbmPadRunner" \
    --game "$GAME" \
    --module "$APP/Contents/MacOS/gGALE01_recomp.dylib" \
    --user-dir "$USER_DIR" \
    --title "SsbmPad PGO Training" \
    --graphics Metal \
    --audio Cubeb
