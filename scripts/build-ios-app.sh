#!/usr/bin/env bash
# Build the publishable MeleePad app: no game code. PadForge adds the module
# translated from the player's own disc (scripts/package-ios.sh PUBLISHED.ipa).
# Usage: scripts/build-ios-app.sh [OUTPUT.ipa]
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT/version.json")"
build="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["build"])' "$ROOT/version.json")"
OUTPUT="${1:-$ROOT/artifacts/MeleePad-v$version-ios-unsigned.ipa}"
derived="$(mktemp -d /tmp/meleepad-app.XXXXXX)"
trap 'rm -rf "$derived"' EXIT

"$ROOT/scripts/ios-build-core-device.sh" --core-only
python3 "$ROOT/scripts/build-slippi-dependencies.py"   # Slippi link inputs (docs/SLIPPI-BUILD.md)
"$ROOT/scripts/ios-provision.sh" device
xcodebuild -project "$ROOT/MeleePad.xcodeproj" -scheme MeleePad -configuration Release \
  -destination generic/platform=iOS -derivedDataPath "$derived" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$build" build
"$ROOT/scripts/package-public-ios-ipa.sh" "$derived/Build/Products/Release-iphoneos/MeleePad.app" "$OUTPUT"
