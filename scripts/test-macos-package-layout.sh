#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP="${1:-$ROOT/build-macos/MeleePad.app}"
SYS="$APP/Contents/Resources/Sys"

test -x "$APP/Contents/MacOS/MeleePad"
test -x "$APP/Contents/MacOS/MeleePadFrontend"
test -x "$APP/Contents/MacOS/MeleePadRunner"
test -f "$APP/Contents/MacOS/gGALE01_recomp.dylib"
grep -Fqx 'fullscreen=true' "$APP/Contents/Resources/default-config.ini"
test "$(plutil -extract LSApplicationCategoryType raw "$APP/Contents/Info.plist")" = \
  "public.app-category.games"
test "$(plutil -extract LSSupportsGameMode raw "$APP/Contents/Info.plist")" = true
grep -F 'MELEEPAD_PREWARM_EFB_VRAM=1' "$APP/Contents/MacOS/MeleePad" >/dev/null
grep -F 'Pipe/[0-9]+/meleepad' "$APP/Contents/MacOS/MeleePad" >/dev/null
grep -Fqx 'Main Stick/Up = W' \
  "$APP/Contents/Resources/default-GCPadNew.ini"
grep -Fqx 'Buttons/X = U | Space' \
  "$APP/Contents/Resources/default-GCPadNew.ini"
strings "$APP/Contents/MacOS/MeleePadRunner" | grep -F \
  "metal layer display sync: product policy enabled" >/dev/null
strings "$APP/Contents/MacOS/MeleePadRunner" | grep -F \
  "MELEEPAD_PREWARM_EFB_VRAM" >/dev/null
test -f "$SYS/GameSettings/GALE01r0.ini"
grep -Eq '^StaticRecompIdlePC = 0x80348814$' \
  "$SYS/GameSettings/GALE01r0.ini"
grep -Eq '^StaticRecompCallerIdlePC = 0x80019550$' \
  "$SYS/GameSettings/GALE01r0.ini"
grep -Eq '^StaticRecompCallerIdleLR = 0x801A4064$' \
  "$SYS/GameSettings/GALE01r0.ini"

echo "macOS package layout: pass"
