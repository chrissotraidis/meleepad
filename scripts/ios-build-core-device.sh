#!/usr/bin/env bash
# Builds the ModernGekko core and GALE01 module for a physical arm64 iOS device.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
TOOLCHAIN="$ROOT/scripts/ios-device-toolchain.cmake"
BUILD="$MG/build-ios-iphoneos-meleepad-static"
MODULE_BUILD="/tmp/meleepad-module-ios-device"

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
ACTIVE_MODULE_FILE="$TPL/build/modules-macos14/GALE01/active-module.txt"
if [[ ! -f "$ACTIVE_MODULE_FILE" ]]; then
  echo "prepared module pointer missing; run scripts/prepare-game.sh first" >&2
  exit 1
fi
ACTIVE_MODULE="$(<"$ACTIVE_MODULE_FILE")"
if [[ "$ACTIVE_MODULE" != /* ]]; then
  ACTIVE_MODULE="$TPL/$ACTIVE_MODULE"
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
  -DCHASSIS_ABI_DIR="$MG/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp"
ninja -C "$MODULE_BUILD" -j8

echo "==> Provisioning app"
"$ROOT/scripts/ios-provision.sh" device

echo "Device core, module, and provisioning complete."
