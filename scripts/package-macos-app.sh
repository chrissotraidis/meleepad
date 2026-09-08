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

cmake -S "$MG" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
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

active_module=$(cat "$TPL/build/modules-macos14/GALE01/active-module.txt")
if [[ "$active_module" != /* ]]; then
  if [[ -e "$ROOT/$active_module" ]]; then
    active_module="$ROOT/$active_module"
  else
    active_module="$TPL/$active_module"
  fi
fi
if [[ ! -f "$active_module" ]]; then
  echo "Generated GALE01 desktop module not found: $active_module" >&2
  exit 1
fi
module_minos=$(vtool -show-build "$active_module" | awk '/minos/ {print $2; exit}')
if [[ -z "$module_minos" || "${module_minos%%.*}" -gt 14 ]]; then
  echo "GALE01 module does not target macOS 14: ${module_minos:-unknown}" >&2
  exit 1
fi

for binary in "$BUILD/MeleePadFrontend" "$BUILD/MeleePadRunner" "$active_module"; do
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
cp "$active_module" "$OUTPUT/Contents/MacOS/gGALE01_recomp.dylib"
# Package every prepared revision under its executable hash. The runner selects
# this directory from the imported game, never from a shared GALE01 pointer.
python3 - "$TPL" "$OUTPUT/Contents/MacOS" <<'PYMODULES'
import hashlib, pathlib, shutil, subprocess, sys
root, out = map(pathlib.Path, sys.argv[1:])
for revision in (0, 2):
    suffix = "-r2" if revision == 2 else ""
    pointer = root / f"build/modules-macos14{suffix}/GALE01/active-module.txt"
    if not pointer.is_file():
        continue
    module = pathlib.Path(pointer.read_text().strip())
    if not module.is_absolute(): module = root / module
    dol = root / f"extracted/Super-Smash-Bros-Melee-GALE01-r{revision}/sys/main.dol"
    digest = hashlib.sha256(dol.read_bytes()).hexdigest()
    manifest = module.parent / "manifest.txt"
    if not manifest.is_file() or f"dol_sha256={digest}" not in manifest.read_text().splitlines():
        raise SystemExit(f"Revision {revision} module does not match extracted executable")
    build = subprocess.check_output(["vtool", "-show-build", str(module)], text=True)
    fields = dict(line.split() for line in build.splitlines() if len(line.split()) == 2)
    if fields.get("platform") != "MACOS" or int(fields.get("minos", "99").split(".")[0]) > 14:
        raise SystemExit(f"Revision {revision} module does not target macOS 14")
    deps = subprocess.check_output(["otool", "-L", str(module)], text=True)
    if "/opt/homebrew" in deps or "/usr/local" in deps:
        raise SystemExit(f"Revision {revision} module has non-portable dependencies")
    destination = out / "StaticRecompModules" / digest
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copy2(module, destination / "gGALE01_recomp.dylib")
PYMODULES
cp -R "$BUILD/Sys" "$OUTPUT/Contents/Resources/Sys"
cp "$ROOT/apple/macos/default-config.ini" "$OUTPUT/Contents/Resources/default-config.ini"
cp "$ROOT/apple/macos/default-GCPadNew.ini" "$OUTPUT/Contents/Resources/default-GCPadNew.ini"
chmod +x "$OUTPUT/Contents/MacOS/MeleePad"

source_icon="$ROOT/apple/ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
cp "$source_icon" "$OUTPUT/Contents/Resources/AppIcon.png"

"$ROOT/scripts/test-macos-package-layout.sh" "$OUTPUT"

codesign --force --deep --sign - "$OUTPUT"
codesign --verify --deep --strict "$OUTPUT"
echo "$OUTPUT"
