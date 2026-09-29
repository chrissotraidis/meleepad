#!/usr/bin/env bash
# Add the player's own game module to the published MeleePad app.
# Usage: scripts/package-ios.sh PUBLISHED.ipa OUTPUT.ipa
# The module comes from scripts/ios-build-core-device.sh (translated from the
# player's disc). The result is personal: never publish it.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PUBLISHED="${1:?usage: package-ios.sh PUBLISHED.ipa OUTPUT.ipa}"
OUTPUT="${2:?usage: package-ios.sh PUBLISHED.ipa OUTPUT.ipa}"
[[ -f "$PUBLISHED" ]] || { echo "published app not found: $PUBLISHED" >&2; exit 1; }

work="$(mktemp -d /tmp/meleepad-package.XXXXXX)"
trap 'rm -rf "$work"' EXIT
ditto -x -k "$PUBLISHED" "$work"
app="$work/Payload/MeleePad.app"
[[ -f "$app/Info.plist" ]] || { echo "the published IPA has no MeleePad.app" >&2; exit 1; }
if find "$app" -maxdepth 1 -name '*recomp*.dylib' | grep -q .; then
  echo "the published app already contains a game module" >&2; exit 1
fi

python3 "$ROOT/scripts/stage-ios-modules.py" --platform device "$app"
find "$app" -maxdepth 1 -name '*recomp*.dylib' -exec codesign --remove-signature {} \; 2>/dev/null || true

mkdir -p "$(dirname "$OUTPUT")"
[[ "$OUTPUT" = /* ]] || OUTPUT="$PWD/$OUTPUT"
rm -f "$OUTPUT"
(cd "$work" && TZ=UTC zip -X -q -y -r "$OUTPUT" Payload)
unzip -tq "$OUTPUT" >/dev/null
echo "Personal MeleePad IPA (do not share): $OUTPUT"
