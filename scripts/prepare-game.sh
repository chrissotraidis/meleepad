#!/usr/bin/env bash
# Validate the supported local image, extract it privately, and build the
# hash-keyed macOS static-recomp module. No game-derived output leaves ref/.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ISO=${1:-}
PGO_INPUT=${2:-${SSBMPAD_PGO_PROFILE:-}}
PGO_PROFILE=
PGO_GENERATE=0
EXPECTED_SIZE=1459978240
EXPECTED_SHA256=2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484
EXPECTED_FILES=1209

if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "usage: $0 /path/to/GALE01-revision-0.iso [private-profile.profdata | --pgo-generate]" >&2
  exit 2
fi
ISO="$(cd "$(dirname "$ISO")" && pwd)/$(basename "$ISO")"

if [[ "$PGO_INPUT" == --pgo-generate ]]; then
  PGO_GENERATE=1
elif [[ -n "$PGO_INPUT" ]]; then
  PGO_PROFILE=$PGO_INPUT
  if [[ ! -f "$PGO_PROFILE" ]]; then
    echo "PGO profile is unavailable" >&2
    exit 2
  fi
  PGO_PROFILE="$(cd "$(dirname "$PGO_PROFILE")" && pwd)/$(basename "$PGO_PROFILE")"
  if ! xcrun llvm-profdata show "$PGO_PROFILE" >/dev/null 2>&1; then
    echo "PGO profile is not valid LLVM profile data" >&2
    exit 2
  fi
fi

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
# moderngekko-port's POST_BUILD copy does not rerun when only its dolrecomp
# dependency changes. Refresh the executable beside moderngekko-port explicitly
# so source edits cannot generate a module with a stale code generator.
cmake -E copy_if_different \
  "$BUILD/vendor/dolphin/DolRecomp/dolrecomp" "$BUILD/dolrecomp"

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
build_args=(build "$GAME" --backend c --toolchain clang --output "$MODULES")
if [[ -n "$PGO_PROFILE" ]]; then
  build_args+=(--pgo-profile "$PGO_PROFILE")
elif [[ "$PGO_GENERATE" == 1 ]]; then
  build_args+=(--pgo-generate)
fi
"$BUILD/moderngekko-port" "${build_args[@]}"
echo "Prepared GALE01 revision 0 at $GAME"
