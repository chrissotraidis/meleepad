#!/usr/bin/env bash
# MeleePad iOS/iPadOS provisioning: assembles the locally built ModernGekko /
# Dolphin-derived core into a linker response file for either the Simulator or
# a physical device, and records the dev-only game-data + module locations.
# Keeping the component archives intact avoids an
# Apple libtool archive-table corruption seen when flattening this core into one
# large archive.
#
# Everything referenced here is locally generated from the user's legally
# obtained GALE01 disc and is excluded from Git. Nothing is redistributed.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MG="$ROOT/ref/ModernGekko"
TPL="$ROOT/ref/ModernGekko-Template"
OUT="$ROOT/apple/ios/Provisioned"
PLATFORM="${1:-simulator}"

case "$PLATFORM" in
  simulator)
    IOS_BUILD="$MG/build-ios-iphonesimulator-meleepad-static"
    LIBS_DIR="$OUT/iphonesimulator/libs"
    MODULE="/tmp/meleepad-module-ios-simulator/gGALE01_recomp.dylib"
    SLIPPI_VCDIFF_DIR="$ROOT/ref/slippi-compatibility/exi-probe-001/vcdiff-simulator"
    SLIPPI_RUST_ARCHIVE="$ROOT/ref/slippi-compatibility/rust-build-ios16/aarch64-apple-ios-sim/release/libslippi_rust_extensions.a"
    SLIPPI_SEMVER_OBJECTS=(
      "$ROOT/ref/slippi-compatibility/exi-probe-001/Semver200_comparator-simulator.o"
      "$ROOT/ref/slippi-compatibility/exi-probe-001/Semver200_modifier-simulator.o"
      "$ROOT/ref/slippi-compatibility/exi-probe-001/Semver200_parser-simulator.o"
    )
    DEVICE_MODULE_ENTRY=""
    DEVICE_SLIPPI_MODULE_ENTRY=""
    DEVICE_BUNDLED_REVISION_ENTRY=""
    DEVICE_BUNDLED_ROOT_ENTRY=""
    DEVICE_BUNDLED_DISC_ENTRY=""
    DEVICE_BUNDLED_ORIGINAL_MODULE_ENTRY=""
    ;;
  device)
    IOS_BUILD="$MG/build-ios-iphoneos-meleepad-static"
    LIBS_DIR="$OUT/iphoneos/libs"
    MODULE="/tmp/meleepad-module-ios-device/gGALE01_recomp.dylib"
    DEVICE_MODULE_ENTRY=$'\t<key>DeviceModuleRelativePath</key>\n\t<string>gGALE01_recomp.dylib</string>'
    DEVICE_SLIPPI_MODULE_ENTRY=$'\t<key>DeviceBundledSlippiModuleRelativePath</key>\n\t<string>gGALE01r2_slippi_recomp.dylib</string>'
    DEVICE_BUNDLED_REVISION_ENTRY=$'\t<key>DeviceBundledGameRevision</key>\n\t<integer>2</integer>'
    DEVICE_BUNDLED_ROOT_ENTRY=$'\t<key>DeviceBundledGameRootRelativePath</key>\n\t<string>PrivateQA/GameData-r2/GALE01</string>'
    DEVICE_BUNDLED_DISC_ENTRY=$'\t<key>DeviceBundledDiscImageRelativePath</key>\n\t<string>PrivateQA/GALE01-r2.iso</string>'
    DEVICE_BUNDLED_ORIGINAL_MODULE_ENTRY=$'\t<key>DeviceBundledOriginalModuleRelativePath</key>\n\t<string>gGALE01r2_recomp.dylib</string>'
    SLIPPI_VCDIFF_DIR=""
    SLIPPI_RUST_ARCHIVE=""
    SLIPPI_SEMVER_OBJECTS=()
    ;;
  *)
    echo "usage: $0 [simulator|device]" >&2
    exit 2
    ;;
esac

mkdir -p "$LIBS_DIR"

if [[ "$PLATFORM" == "device" ]]; then
  python3 "$ROOT/scripts/check-ios-slippi-build-inputs.py"
fi

if [[ ! -d "$IOS_BUILD" ]]; then
  echo "iOS core build missing: $IOS_BUILD" >&2
  exit 1
fi

LIBS=(
  "$IOS_BUILD/libmoderngekko.a"
  "$IOS_BUILD/libmoderngekko_netplay_session.a"
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

if [[ "$PLATFORM" == "simulator" ]]; then
  SLIPPI_INPUTS=(
    "$SLIPPI_VCDIFF_DIR/libvcdenc.a"
    "$SLIPPI_VCDIFF_DIR/libvcddec.a"
    "$SLIPPI_VCDIFF_DIR/libvcdcom.a"
    "${SLIPPI_SEMVER_OBJECTS[@]}"
    "$SLIPPI_RUST_ARCHIVE"
  )
  MISSING_SLIPPI=()
  for input in "${SLIPPI_INPUTS[@]}"; do
    if [[ ! -f "$input" ]]; then
      MISSING_SLIPPI+=("$input")
    fi
  done
  if (( ${#MISSING_SLIPPI[@]} )); then
    printf 'missing simulator Slippi link inputs:\n'
    printf '  %s\n' "${MISSING_SLIPPI[@]}"
    exit 1
  fi
  LINKER_RESPONSE="$LIBS_DIR/MeleePadSlippiCore.rsp"
  : > "$LINKER_RESPONSE"
  # Replacement Slippi objects are compiled into the app. Ordinary archives
  # let the linker prefer those objects without duplicate symbols.
  for lib in "${LIBS[@]}"; do
    printf '%s\n' "$lib" >> "$LINKER_RESPONSE"
  done
  for lib in "$SLIPPI_VCDIFF_DIR/libvcdenc.a" "$SLIPPI_VCDIFF_DIR/libvcddec.a" "$SLIPPI_VCDIFF_DIR/libvcdcom.a"; do
    printf '%s\n' "-Wl,-force_load,$lib" >> "$LINKER_RESPONSE"
  done
  printf '%s\n' "${SLIPPI_SEMVER_OBJECTS[@]}" "$SLIPPI_RUST_ARCHIVE" >> "$LINKER_RESPONSE"
else
  LINKER_RESPONSE="$LIBS_DIR/MeleePadSlippiCore.rsp"
  : > "$LINKER_RESPONSE"
  for lib in "${LIBS[@]}"; do
    printf '%s\n' "-Wl,-force_load,$lib" >> "$LINKER_RESPONSE"
  done
fi
echo "linker response: $LINKER_RESPONSE"

# Dev provisioning manifest (host paths; the iOS Simulator can read the host
# filesystem for acceptance testing). Replaced by the document-picker import
# flow on real devices.
GAME_ROOT="$TPL/extracted/Super-Smash-Bros-Melee-GALE01-r0"
cat > "$OUT/dev-config.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>DevGameRoot</key>
	<string>$GAME_ROOT</string>
	<key>DevModulePath</key>
	<string>$MODULE</string>
$DEVICE_MODULE_ENTRY
$DEVICE_SLIPPI_MODULE_ENTRY
$DEVICE_BUNDLED_REVISION_ENTRY
$DEVICE_BUNDLED_ROOT_ENTRY
$DEVICE_BUNDLED_DISC_ENTRY
$DEVICE_BUNDLED_ORIGINAL_MODULE_ENTRY
</dict>
</plist>
PLIST
echo "dev config: $OUT/dev-config.plist"

python3 - "$OUT/dev-config.plist" "$TPL" "$PLATFORM" <<'PYCONFIG'
import pathlib, plistlib, sys
path, template, platform = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
config = plistlib.loads(path.read_bytes())
config["DevModulesByRevision"] = {}
config["DevSlippiModulesByRevision"] = {}
config["DevGameRootsByRevision"] = {}
for revision in (0, 2):
    suffix = "-r2" if revision == 2 else ""
    module = pathlib.Path(f"/tmp/meleepad-module-ios-{platform}{suffix}/gGALE01_recomp.dylib")
    root = template / f"extracted/Super-Smash-Bros-Melee-GALE01-r{revision}"
    if module.is_file() and root.is_dir():
        config["DevModulesByRevision"][f"r{revision}"] = str(module)
        config["DevGameRootsByRevision"][f"r{revision}"] = str(root)
        if platform == "simulator" and revision == 2:
            config["DevSlippiModulesByRevision"][f"r{revision}"] = str(module)
path.write_bytes(plistlib.dumps(config))
PYCONFIG
