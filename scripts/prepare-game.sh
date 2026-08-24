#!/usr/bin/env bash
# Validate the supported local image, extract it privately, and build the
# hash-keyed macOS static-recomp module. No game-derived output leaves ref/.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ISO=${1:-}
EXPECTED_SIZE=1459978240
EXPECTED_SHA256=2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484
EXPECTED_FILES=1209

if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "usage: $0 /path/to/GALE01-revision-0.iso" >&2
  exit 2
fi
ISO="$(cd "$(dirname "$ISO")" && pwd)/$(basename "$ISO")"

actual_size=$(stat -f %z "$ISO")
actual_sha=$(shasum -a 256 "$ISO" | awk '{print $1}')
game_id=$(dd if="$ISO" bs=1 count=6 2>/dev/null)
disc_number=$(od -An -tu1 -j6 -N1 "$ISO" | tr -d ' ')
revision=$(od -An -tu1 -j7 -N1 "$ISO" | tr -d ' ')
if [[ "$actual_size" != "$EXPECTED_SIZE" || "$actual_sha" != "$EXPECTED_SHA256" ||
      "$game_id" != GALE01 || "$disc_number" != 0 || "$revision" != 0 ]]; then
  echo "unsupported disc image" >&2
  echo "  size=$actual_size sha256=$actual_sha id=$game_id disc=$disc_number revision=$revision" >&2
  echo "ssbmpad currently targets the exact GALE01 revision 0 image documented in STATUS.md." >&2
  exit 1
fi

"$ROOT/scripts/bootstrap-dependencies.sh"

MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
GAME="$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r0"
MODULES="$TPL/build/modules-macos14"
MARKER="$GAME/.ssbmpad-source-sha256"
BUILD="$MG/build-desktop-tools-ssbmpad"

cmake -S "$MG" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DUSE_SYSTEM_LIBS=OFF -DENABLE_VULKAN=OFF \
  -DENABLE_QT=OFF -DENABLE_TESTS=OFF -DUSE_DISCORD_PRESENCE=OFF \
  -DUSE_MGBA=OFF -DUSE_RETRO_ACHIEVEMENTS=OFF -DENABLE_AUTOUPDATE=OFF \
  -DENABLE_ANALYTICS=OFF -DUSE_UPNP=OFF
cmake --build "$BUILD" --target moderngekko-port moderngekko-run \
  -j"${SSBMPAD_JOBS:-8}"

if [[ -e "$GAME" ]]; then
  if [[ -f "$MARKER" && "$(<"$MARKER")" != "$EXPECTED_SHA256" ]]; then
    echo "existing extraction belongs to another image: $GAME" >&2
    exit 1
  fi
else
  staging="$GAME.importing.$$"
  trap 'rm -rf "$staging"' EXIT
  "$BUILD/dolrecomp" extract "$ISO" "$staging"
  [[ -f "$staging/sys/boot.bin" && -f "$staging/sys/main.dol" ]]
  [[ "$(find "$staging/files" -type f | wc -l | tr -d ' ')" == "$EXPECTED_FILES" ]]
  printf '%s\n' "$EXPECTED_SHA256" > "$staging/.ssbmpad-source-sha256"
  mv "$staging" "$GAME"
  trap - EXIT
fi

[[ -f "$GAME/sys/boot.bin" && -f "$GAME/sys/main.dol" ]]
[[ "$(find "$GAME/files" -type f | wc -l | tr -d ' ')" == "$EXPECTED_FILES" ]]
if [[ ! -f "$MARKER" ]]; then
  printf '%s\n' "$EXPECTED_SHA256" > "$MARKER"
fi

export MACOSX_DEPLOYMENT_TARGET=14.0
"$BUILD/moderngekko-port" build "$GAME" \
  --backend c --toolchain clang --output "$MODULES"
echo "Prepared GALE01 revision 0 at $GAME"
