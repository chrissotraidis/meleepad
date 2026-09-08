#!/usr/bin/env bash
# Builds the ModernGekko core and GALE01 module for a physical arm64 iOS device.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
TOOLCHAIN="$ROOT/scripts/ios-device-toolchain.cmake"
BUILD="$MG/build-ios-iphoneos-meleepad-static"
MODULE_BUILD="/tmp/meleepad-module-ios-device"
REVISION=${MELEEPAD_GAME_REVISION:-0}
case "$REVISION" in 0|2) ;; *) echo "supported revisions: 0 or 2" >&2; exit 2;; esac
MODULES="$TPL/build/modules-macos14"
if [[ "$REVISION" == 2 ]]; then
  MODULE_BUILD="${MODULE_BUILD}-r2"
  MODULES="$TPL/build/modules-macos14-r2"
fi

"$ROOT/scripts/bootstrap-dependencies.sh"

CMAKE_COMMON=(
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN"
  -DCMAKE_SYSTEM_PROCESSOR=arm64
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0
  -DCMAKE_BUILD_TYPE=Release
  -DENABLE_QT=OFF -DENABLE_TESTS=OFF
  -DUSE_DISCORD_PRESENCE=OFF -DUSE_MGBA=OFF
  -DUSE_RETRO_ACHIEVEMENTS=OFF -DENABLE_AUTOUPDATE=OFF
  -DENABLE_ANALYTICS=OFF -DUSE_UPNP=OFF
  -DUSE_SYSTEM_LIBS=OFF
  -DMODERNGEKKO_ENABLE_DOLPHIN_TESTS=OFF
  -DENABLE_CUBEB=OFF -DENABLE_VULKAN=OFF
  -DUSE_SYSTEM_LZ4=OFF -DUSE_SYSTEM_ZSTD=OFF
  -DHAVE_PIPE2=0
  -DMODERNGEKKO_GAMECUBE_CONTROLLERS=ON
  -DUSE_SANITIZERS=OFF
  "-DCMAKE_C_FLAGS=-ffile-prefix-map=$ROOT=."
  "-DCMAKE_CXX_FLAGS=-ffile-prefix-map=$ROOT=."
  "-DCMAKE_OBJC_FLAGS=-ffile-prefix-map=$ROOT=."
  "-DCMAKE_OBJCXX_FLAGS=-ffile-prefix-map=$ROOT=."
)

echo "==> Configuring ModernGekko core for iOS device"
cmake -S "$MG" -B "$BUILD" -G Ninja "${CMAKE_COMMON[@]}"

echo "==> Building core libraries"
ninja -C "$BUILD" libmoderngekko.a libmoderngekko_netplay_session.a -j8

echo "==> Building GALE01 recompiled module for iOS device"
ACTIVE_MODULE_FILE="$MODULES/GALE01/active-module.txt"
if [[ ! -f "$ACTIVE_MODULE_FILE" ]]; then
  echo "prepared module pointer missing; run scripts/prepare-game.sh first" >&2
  exit 1
fi
ACTIVE_MODULE="$(<"$ACTIVE_MODULE_FILE")"
if [[ "$ACTIVE_MODULE" != /* ]]; then
  ACTIVE_MODULE="$TPL/$ACTIVE_MODULE"
fi
EXPECTED_DOL_SHA256=$(shasum -a 256 "$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r${REVISION}/sys/main.dol" | awk '{print $1}')
if ! grep -Fxq "dol_sha256=$EXPECTED_DOL_SHA256" "$(dirname "$ACTIVE_MODULE")/manifest.txt"; then
  echo "module pointer does not match selected revision; prepare that revision again" >&2
  exit 1
fi
GEN="$(dirname "$ACTIVE_MODULE")/dolrecomp-output/generated"
if [[ ! -f "$GEN/generated.c" || ! -f "$GEN/generated.h" ]]; then
  echo "prepared module sources missing; run scripts/prepare-game.sh first" >&2
  exit 1
fi
cmake -S "$MG/vendor/dolphin/module-template" -B "$MODULE_BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DGAME_ID=GALE01 \
  -DGENERATED_DIR="$GEN" \
  -DGXRUNTIME_DIR="$MG/vendor/dolphin/GXRuntime" \
  -DCHASSIS_ABI_DIR="$MG/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp" \
  -DRECOMPCORE_MODULE_TUNE_CPU=apple-a15
ninja -C "$MODULE_BUILD" -j8

# Identity travels with the locally generated module; signing does not change
# this source-executable hash.
shasum -a 256 "$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r${REVISION}/sys/main.dol" | awk '{print $1}' > "$MODULE_BUILD/gGALE01_recomp.dylib.dol-sha256"
echo "==> Provisioning app"
"$ROOT/scripts/ios-provision.sh" device

echo "Device core, module, and provisioning complete."
