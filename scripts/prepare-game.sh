#!/usr/bin/env bash
# Validate the supported local image, extract it privately, and build the
# hash-keyed macOS static-recomp module. No game-derived output leaves ref/.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ISO=${1:-}
PGO_INPUT=${2:-${MELEEPAD_PGO_PROFILE:-}}
PGO_PROFILE=
PGO_GENERATE=0
EXPECTED_FILES=1209

if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "usage: $0 /path/to/Melee-USA.iso-or-ciso [private-profile.profdata | --pgo-generate]" >&2
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

identity=$(python3 "$ROOT/scripts/identify-game.py" "$ISO")
revision=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"])' <<<"$identity")
EXPECTED_SHA256=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["image_sha256"])' <<<"$identity")
EXPECTED_DOL_SHA256=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["dol_sha256"])' <<<"$identity")
image_format=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["format"])' <<<"$identity")
if [[ "$image_format" == ciso ]]; then
  normalized="$ROOT/ref/normalized/GALE01-r${revision}.iso"
  mkdir -p "$(dirname "$normalized")"
  if [[ ! -f "$normalized" ]]; then
    python3 "$ROOT/scripts/identify-game.py" "$ISO" --normalize "$normalized" >/dev/null
  fi
  normalized_revision=$(python3 "$ROOT/scripts/identify-game.py" "$normalized" --field revision)
  [[ "$normalized_revision" == "$revision" ]]
  ISO="$normalized"
  EXPECTED_SHA256=$(shasum -a 256 "$ISO" | awk '{print $1}')
fi

"$ROOT/scripts/bootstrap-dependencies.sh"

MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
GAME="$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r${revision}"
MODULES="$TPL/build/modules-macos14"
if [[ "$revision" != 0 ]]; then MODULES="$TPL/build/modules-macos14-r${revision}"; fi
MARKER="$GAME/.meleepad-source-sha256"
BUILD="${MELEEPAD_TOOLS_BUILD:-$MG/build-desktop-tools-meleepad}"

cmake -S "$MG" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DMODERNGEKKO_GAMECUBE_CONTROLLERS=ON \
  -DUSE_SYSTEM_LIBS=OFF -DENABLE_VULKAN=OFF \
  -DENABLE_QT=OFF -DENABLE_TESTS=OFF -DUSE_DISCORD_PRESENCE=OFF \
  -DUSE_MGBA=OFF -DUSE_RETRO_ACHIEVEMENTS=OFF -DENABLE_AUTOUPDATE=OFF \
  -DENABLE_ANALYTICS=OFF -DUSE_UPNP=OFF
cmake --build "$BUILD" --target moderngekko-port moderngekko-run \
  -j"${MELEEPAD_JOBS:-8}"
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
  printf '%s\n' "$EXPECTED_SHA256" > "$staging/.meleepad-source-sha256"
  mv "$staging" "$GAME"
  trap - EXIT
fi

[[ -f "$GAME/sys/boot.bin" && -f "$GAME/sys/main.dol" ]]
[[ "$(find "$GAME/files" -type f | wc -l | tr -d ' ')" == "$EXPECTED_FILES" ]]
if [[ ! -f "$MARKER" ]]; then
  printf '%s\n' "$EXPECTED_SHA256" > "$MARKER"
fi

[[ "$(shasum -a 256 "$GAME/sys/main.dol" | awk '{print $1}')" == "$EXPECTED_DOL_SHA256" ]]

export MACOSX_DEPLOYMENT_TARGET=14.0
build_args=(build "$GAME" --backend c --toolchain clang --output "$MODULES")
if [[ -n "$PGO_PROFILE" ]]; then
  build_args+=(--pgo-profile "$PGO_PROFILE")
elif [[ "$PGO_GENERATE" == 1 ]]; then
  build_args+=(--pgo-generate)
fi
"$BUILD/moderngekko-port" "${build_args[@]}"
echo "Prepared GALE01 revision $revision at $GAME"
