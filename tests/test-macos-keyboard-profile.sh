#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/ssbmpad-keyboard-profile.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT

CONTENTS="$FIXTURE/SsbmPad.app/Contents"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$FIXTURE/home"
cp "$ROOT/apple/macos/SsbmPad" "$CONTENTS/MacOS/SsbmPad"
cp "$ROOT/apple/macos/default-config.ini" "$CONTENTS/Resources/default-config.ini"
cp "$ROOT/apple/macos/default-GCPadNew.ini" \
  "$CONTENTS/Resources/default-GCPadNew.ini"

cat >"$CONTENTS/MacOS/SsbmPadFrontend" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$CONTENTS/MacOS/SsbmPad" "$CONTENTS/MacOS/SsbmPadFrontend"

run_launcher() {
  HOME="$FIXTURE/home" "$CONTENTS/MacOS/SsbmPad"
}

PAD_DIR="$FIXTURE/home/Library/Application Support/SsbmPad/Config"
PAD_CONFIG="$PAD_DIR/GCPadNew.ini"

run_launcher
cmp "$ROOT/apple/macos/default-GCPadNew.ini" "$PAD_CONFIG"
grep -Fqx 'Main Stick/Up = W' "$PAD_CONFIG"
grep -Fqx 'Buttons/X = U | Space' "$PAD_CONFIG"

cat >"$PAD_CONFIG" <<'EOF'
[GCPad1]
Device = Pipe/0/ssbmpad
Buttons/A = `Button A`
EOF
sed -E -i '' \
  's|^controller1=.*$|controller1=Pipe/0/ssbmpad|' \
  "$FIXTURE/home/Library/Application Support/SsbmPad/config.ini"
run_launcher
cmp "$ROOT/apple/macos/default-GCPadNew.ini" "$PAD_CONFIG"
grep -Fqx 'controller1=Quartz/0/Keyboard & Mouse' \
  "$FIXTURE/home/Library/Application Support/SsbmPad/config.ini"

cat >"$PAD_CONFIG" <<'EOF'
[GCPad1]
Device = SDL/0/My Controller
Buttons/A = Custom A
EOF
cp "$PAD_CONFIG" "$FIXTURE/custom-profile.expected"
run_launcher
cmp "$FIXTURE/custom-profile.expected" "$PAD_CONFIG"

echo "macOS keyboard profile: pass"
