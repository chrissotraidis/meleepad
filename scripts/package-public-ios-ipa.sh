#!/usr/bin/env bash
# Package a reproducible, unsigned, game-data-free iOS app shell.
# A playable local build requires the user-generated GALE01 module and must not
# be published through this script.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE_APP=${1:-}
OUTPUT=${2:-"$ROOT/artifacts/MeleePad-v0.1.0-preview.2-module-free-unsigned.ipa"}

if [[ -z "$SOURCE_APP" || ! -d "$SOURCE_APP" ]]; then
  echo "usage: $0 /path/to/MeleePad.app [output.ipa]" >&2
  exit 2
fi

SOURCE_APP="$(cd "$(dirname "$SOURCE_APP")" && pwd)/$(basename "$SOURCE_APP")"
OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"
OUTPUT="$(cd "$OUTPUT_DIR" && pwd)/$(basename "$OUTPUT")"

source_prohibited="$(find "$SOURCE_APP" -type f \( \
    -name 'gGALE01_recomp.dylib' -o -name '*.iso' -o -name '*.gcm' -o \
    -name '*.rvz' -o -name '*.gci' -o -name '*.sav' -o \
    -name 'embedded.mobileprovision' \) -print -quit)"
if [[ -n "$source_prohibited" ]]; then
  echo "refusing to package an app containing a game module, game/save data, or provisioning profile" >&2
  exit 1
fi

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/meleepad-public-ipa.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/Payload"
ditto "$SOURCE_APP" "$STAGING/Payload/MeleePad.app"
APP="$STAGING/Payload/MeleePad.app"

# Development manifests can contain local absolute paths even when the files
# they name are not bundled. They have no purpose in the public shell.
rm -f "$APP/dev-config.plist" "$APP/embedded.mobileprovision"
rm -rf "$APP/_CodeSignature"

identifier="$(plutil -extract CFBundleIdentifier raw -o - "$APP/Info.plist")"
version="$(plutil -extract CFBundleShortVersionString raw -o - "$APP/Info.plist")"
build="$(plutil -extract CFBundleVersion raw -o - "$APP/Info.plist")"
executable="$(plutil -extract CFBundleExecutable raw -o - "$APP/Info.plist")"

[[ "$identifier" == com.meleepad.MeleePad ]]
[[ "$version" == 0.1.0 ]]
[[ "$build" == 5 ]]
[[ "$(lipo -archs "$APP/$executable")" == arm64 ]]

if codesign -d "$APP" >/dev/null 2>&1; then
  echo "refusing to package a signed app" >&2
  exit 1
fi
packaged_prohibited="$(find "$APP" -type f \( \
    -name 'gGALE01_recomp.dylib' -o -name '*.iso' -o -name '*.gcm' -o \
    -name '*.rvz' -o -name '*.gci' -o -name '*.sav' -o \
    -name '*.mobileprovision' -o -name '*.p12' -o -name '*.cer' -o \
    -name '*.key' \) -print -quit)"
if [[ -n "$packaged_prohibited" ]]; then
  echo "public package audit found prohibited private or game-derived data" >&2
  exit 1
fi
private_paths="$(find "$APP" -type f -exec strings -a {} + | \
  rg '/Users/|/tmp/meleepad' || true)"
if [[ -n "$private_paths" ]]; then
  echo "public package audit found a private host path" >&2
  exit 1
fi

find "$STAGING/Payload" -exec touch -h -t 202601010000 {} +
TEMP_IPA="$STAGING/MeleePad.ipa"
(cd "$STAGING" && TZ=UTC zip -X -q -y -r "$TEMP_IPA" Payload)
unzip -tq "$TEMP_IPA" >/dev/null
mv "$TEMP_IPA" "$OUTPUT"
checksum="$(shasum -a 256 "$OUTPUT" | awk '{print $1}')"
printf '%s  %s\n' "$checksum" "$(basename "$OUTPUT")" > "$OUTPUT.sha256"

echo "Public module-free IPA: $OUTPUT"
echo "SHA-256: $checksum"
echo "This app shell is not playable until a private generated module is added and the bundle is signed."
