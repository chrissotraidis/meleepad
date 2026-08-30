#!/usr/bin/env bash
# Builds the ModernGekko / Dolphin-derived compatibility runtime for the iOS
# Simulator (arm64) and provisions the SsbmPad iOS/iPadOS app.
#
# Product path: ahead-of-time statically recompiled game code through the
# compatibility runtime. The product path never enables the compiled PowerPC
# JIT (the static-recomp fallback uses the interpreter). The game module is recompiled for
# the simulator from the user's locally generated DolRecomp output.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
TOOLCHAIN="$ROOT/scripts/ios-simulator-toolchain.cmake"
BUILD="$MG/build-ios-iphonesimulator-ssbmpad-static"
MODULE_BUILD="/tmp/ssbmpad-module-ios-simulator"

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
)

echo "==> Configuring ModernGekko core for iOS Simulator"
cmake -S "$MG" -B "$BUILD" -G Ninja "${CMAKE_COMMON[@]}"

echo "==> Building core libraries"
ninja -C "$BUILD" libmoderngekko.a -j8

echo "==> Building GALE01 recompiled module for iOS Simulator"
# The promoted macOS PGO dylib intentionally has no adjacent private source
# tree. The canonical DolRecomp output retained under the private extraction is
# the platform-neutral input for the Simulator cross-build.
GEN="$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r0/recomp-smc/generated"
if [[ ! -f "$GEN/generated.c" || ! -f "$GEN/generated.h" ]]; then
  echo "prepared module sources missing; run scripts/prepare-game.sh first" >&2
  exit 1
fi
if [[ ! -f "$GEN/main.dol" ]]; then
  cp "$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r0/sys/main.dol" "$GEN/main.dol"
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
"$ROOT/scripts/ios-provision.sh"

echo "Core, module, and provisioning complete."
