#!/usr/bin/env bash
# SsbmPad iOS/iPadOS provisioning: assembles the locally built ModernGekko /
# Dolphin-derived core into a linker response file, and records the dev-only
# game-data + module locations. Keeping the component archives intact avoids an
# Apple libtool archive-table corruption seen when flattening this core into one
# large archive.
#
# Everything referenced here is locally generated from the user's legally
# obtained GALE01 disc and is excluded from Git. Nothing is redistributed.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
IOS_BUILD="$MG/build-ios-iphonesimulator-ssbmpad-static"
OUT="$ROOT/apple/ios/Provisioned"
LIBS_DIR="$OUT/iphonesimulator/libs"

mkdir -p "$LIBS_DIR"

if [[ ! -d "$IOS_BUILD" ]]; then
  echo "iOS core build missing: $IOS_BUILD (run scripts/ios-build-core.sh first)" >&2
  exit 1
fi

LIBS=(
  "$IOS_BUILD/libmoderngekko.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/UICommon/libuicommon.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/Core/libcore.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/DiscIO/libdiscio.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/VideoBackends/Null/libvideonull.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/VideoBackends/Metal/libvideometal.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/VideoCommon/libvideocommon.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/AudioCommon/libaudiocommon.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/InputCommon/libinputcommon.a"
  "$IOS_BUILD/vendor/dolphin/Source/Core/Common/libcommon.a"
  "$IOS_BUILD/vendor/dolphin/Externals/FreeSurround/libFreeSurround.a"
  "$IOS_BUILD/vendor/dolphin/Externals/SDL/SDL/libSDL3.a"
  "$IOS_BUILD/vendor/dolphin/Externals/LZO/liblzo2.a"
  "$IOS_BUILD/vendor/dolphin/Externals/spirv_cross/libspirv_cross.a"
  "$IOS_BUILD/vendor/dolphin/Externals/xxhash/libxxhash.a"
  "$IOS_BUILD/vendor/dolphin/Externals/implot/libimplot.a"
  "$IOS_BUILD/vendor/dolphin/Externals/imgui/libimgui.a"
  "$IOS_BUILD/vendor/dolphin/Externals/glslang/glslang/SPIRV/libSPIRV.a"
  "$IOS_BUILD/vendor/dolphin/Externals/glslang/glslang/glslang/libglslang.a"
  "$IOS_BUILD/vendor/dolphin/Externals/tinygltf/libtinygltf.a"
  "$IOS_BUILD/vendor/dolphin/Externals/enet/enet/libenet.a"
  "$IOS_BUILD/vendor/dolphin/Externals/SFML/libsfml-network.a"
  "$IOS_BUILD/vendor/dolphin/Externals/SFML/libsfml-system.a"
  "$IOS_BUILD/vendor/dolphin/Externals/FatFs/libFatFs.a"
  "$IOS_BUILD/vendor/dolphin/Externals/curl/curl/lib/libcurl.a"
  "$IOS_BUILD/vendor/dolphin/Externals/mbedtls/library/libmbedtls.a"
  "$IOS_BUILD/vendor/dolphin/Externals/mbedtls/library/libmbedx509.a"
  "$IOS_BUILD/vendor/dolphin/Externals/mbedtls/library/libmbedcrypto.a"
  "$IOS_BUILD/vendor/dolphin/Externals/libspng/libspng/libspng_static.a"
  "$IOS_BUILD/vendor/dolphin/Externals/zlib-ng/zlib-ng/libz.a"
  "$IOS_BUILD/vendor/dolphin/Externals/pugixml/pugixml/libpugixml.a"
  "$IOS_BUILD/vendor/dolphin/Externals/cpp-optparse/libcpp-optparse.a"
  "$IOS_BUILD/vendor/dolphin/Externals/minizip-ng/minizip-ng/libminizip-ng.a"
  "$IOS_BUILD/vendor/dolphin/Externals/liblzma/liblzma.a"
  "$IOS_BUILD/vendor/dolphin/Externals/fmt/fmt/libfmt.a"
  "$IOS_BUILD/vendor/dolphin/Externals/lz4/lz4/build/cmake/liblz4.a"
  "$IOS_BUILD/vendor/dolphin/Externals/zstd/zstd/build/cmake/lib/libzstd.a"
  "$IOS_BUILD/vendor/dolphin/Externals/bzip2/libbzip2.a"
  "$IOS_BUILD/vendor/dolphin/Externals/libiconv/libiconv.a"
  "$IOS_BUILD/vendor/dolphin/Externals/libiconv/libcharset/liblibcharset.a"
)

MISSING=()
for lib in "${LIBS[@]}"; do
  if [[ ! -f "$lib" ]]; then
    MISSING+=("$lib")
  fi
done
if (( ${#MISSING[@]} )); then
  printf 'missing iOS core libraries:\n'
  printf '  %s\n' "${MISSING[@]}"
  exit 1
fi

LINKER_RESPONSE="$LIBS_DIR/SsbmPadCore.rsp"
: > "$LINKER_RESPONSE"
for lib in "${LIBS[@]}"; do
  printf '%s\n' "-Wl,-force_load,$lib" >> "$LINKER_RESPONSE"
done
echo "linker response: $LINKER_RESPONSE"

# Dev provisioning manifest (host paths; the iOS Simulator can read the host
# filesystem for acceptance testing). Replaced by the document-picker import
# flow on real devices.
GAME_ROOT="$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r0"
MODULE="/tmp/ssbmpad-module-ios-simulator/gGALE01_recomp.dylib"
cat > "$OUT/dev-config.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>DevGameRoot</key>
	<string>$GAME_ROOT</string>
	<key>DevModulePath</key>
	<string>$MODULE</string>
</dict>
</plist>
PLIST
echo "dev config: $OUT/dev-config.plist"
