#!/usr/bin/env bash
# Build a local Apple Silicon MeleePad.app. The generated module is copied only
# into the ignored local bundle and must never be committed or distributed.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
BUILD="${MELEEPAD_MACOS_BUILD_DIR:-$MG/build-desktop-app-meleepad}"
OUTPUT="${MELEEPAD_MACOS_OUTPUT:-$ROOT/build-macos/MeleePad.app}"

"$ROOT/scripts/bootstrap-dependencies.sh"
export MACOSX_DEPLOYMENT_TARGET=14.0

# curl finds pipe2 in the macOS 27 SDK, but the app targets macOS 14, where it is missing.
cmake -S "$MG" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DHAVE_PIPE2=OFF \
  -DMODERNGEKKO_FRONTEND_NAME=MeleePad \
  -DMODERNGEKKO_LAUNCHER_OUTPUT_NAME=MeleePadFrontend \
  -DMODERNGEKKO_RUNNER_OUTPUT_NAME=MeleePadRunner \
  -DMODERNGEKKO_USER_DIRECTORY_NAME=MeleePad \
  -DMODERNGEKKO_DEFAULT_WINDOW_TITLE=MeleePad \
  -DMODERNGEKKO_LOG_FILENAME=MeleePad.log \
  -DMODERNGEKKO_GAMECUBE_CONTROLLERS=ON \
  -DMODERNGEKKO_APP_BUNDLE=ON \
  -DMODERNGEKKO_MACOS_METAL_DISPLAY_SYNC=ON \
  -DMODERNGEKKO_REQUIRED_DISC_ID=GALE01 \
  -DUSE_SYSTEM_LIBS=OFF -DENABLE_VULKAN=OFF \
  -DENABLE_QT=OFF -DENABLE_TESTS=OFF
cmake --build "$BUILD" --target moderngekko-run moderngekko-launcher \
  -j"${MELEEPAD_JOBS:-8}"

for binary in "$BUILD/MeleePadFrontend" "$BUILD/MeleePadRunner"; do
  if otool -L "$binary" | grep -Eq '/opt/homebrew|/usr/local'; then
    echo "non-portable package dependency in $binary" >&2
    otool -L "$binary" >&2
    exit 1
  fi
done

app_parent=$(dirname -- "$OUTPUT")
mkdir -p "$app_parent"
if [[ -e "$OUTPUT" ]]; then
  mv "$OUTPUT" "$OUTPUT.previous.$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources"
cp "$ROOT/apple/macos/Info.plist" "$OUTPUT/Contents/Info.plist"
cp "$ROOT/apple/macos/MeleePad" "$OUTPUT/Contents/MacOS/MeleePad"
cp "$BUILD/MeleePadFrontend" "$OUTPUT/Contents/MacOS/MeleePadFrontend"
cp "$BUILD/MeleePadRunner" "$OUTPUT/Contents/MacOS/MeleePadRunner"
# Package every prepared revision under its executable hash. The runner selects
# this directory from the imported game, never from a shared GALE01 pointer.
python3 "$ROOT/scripts/stage-macos-modules.py" "$TPL" "$OUTPUT/Contents/MacOS"
cp -R "$BUILD/Sys" "$OUTPUT/Contents/Resources/Sys"
cp "$ROOT/apple/macos/default-config.ini" "$OUTPUT/Contents/Resources/default-config.ini"
cp "$ROOT/apple/macos/default-GCPadNew.ini" "$OUTPUT/Contents/Resources/default-GCPadNew.ini"
chmod +x "$OUTPUT/Contents/MacOS/MeleePad"

source_icon="$ROOT/apple/ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
cp "$source_icon" "$OUTPUT/Contents/Resources/AppIcon.png"

"$ROOT/scripts/test-macos-package-layout.sh" "$OUTPUT"

python3 "$ROOT/scripts/stage-notices.py" "$OUTPUT/Contents/Resources/Notices"

codesign --force --deep --sign - "$OUTPUT"
codesign --verify --deep --strict "$OUTPUT"
echo "$OUTPUT"
