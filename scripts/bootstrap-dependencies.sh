#!/usr/bin/env bash
# Recreate ssbmpad's ignored public dependency tree at reviewed revisions.
# This script never downloads game data.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
REF="$ROOT/ref"
MG="$REF/ModernGekko"
TPL="$REF/ModernGekko-Template"
SUNPAD="$REF/sunpad"

MG_REV=048c426ba3db0369e40826d22ad3adcce7fe7c58
DOLPHIN_REV=e13ab348f13cd67879f6db6e9d7185410f8f62c6
DOLRECOMP_REV=93b881c8f73df1d64a88491f2aa50c7c9ed2384d
TPL_REV=1ee85bb5e09c38f493a09f5fa6e9dc8228b23e42
RECOMPCORE_REV=af7a1a4854ee243b92926875e5a6b66663b0fda0
SUNPAD_REV=e43f0ea6b797e5110787171957c9dc3c6213269c
MELEE_REV=8b5e380f412dc6bad8cc0557fa8fd95fee6815ed
MEX_REV=c9f25da0e59e8c387895371934e98eb5046796b3

mkdir -p "$REF"

ensure_checkout() {
  local url=$1 destination=$2 revision=$3
  if [[ ! -d "$destination/.git" ]]; then
    git clone --filter=blob:none "$url" "$destination"
    git -C "$destination" checkout --detach "$revision"
  fi
  local actual
  actual=$(git -C "$destination" rev-parse HEAD)
  if [[ "$actual" != "$revision" ]]; then
    echo "unexpected revision in $destination" >&2
    echo "  expected: $revision" >&2
    echo "  actual:   $actual" >&2
    echo "Move the ignored checkout aside before bootstrapping." >&2
    exit 1
  fi
}

apply_patch_once() {
  local checkout=$1 patch=$2
  if git -C "$checkout" apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "already applied: ${patch#$ROOT/}"
  elif git -C "$checkout" apply --check "$patch" >/dev/null 2>&1; then
    git -C "$checkout" apply "$patch"
    echo "applied: ${patch#$ROOT/}"
  else
    echo "patch does not apply cleanly: $patch" >&2
    exit 1
  fi
}

verify_patch_scope() {
  local checkout=$1 patch=$2
  shift 2
  local allowed changed
  allowed=$(awk '/^diff --git / {sub(/^b\//, "", $4); print $4}' "$patch")
  while IFS= read -r changed; do
    [[ -z "$changed" ]] && continue
    local extra match=false
    for extra in "$@"; do
      [[ "$changed" == "$extra" ]] && match=true
    done
    [[ "$match" == true ]] && continue
    if ! grep -Fqx "$changed" <<<"$allowed"; then
      echo "unexpected local dependency change: $checkout/$changed" >&2
      exit 1
    fi
  done < <(git -C "$checkout" status --porcelain --untracked-files=all | sed -E 's/^.. //')
}

ensure_checkout https://github.com/chrissotraidis/sunpad.git "$SUNPAD" "$SUNPAD_REV"
ensure_checkout https://github.com/ExpansionPak/ModernGekko.git "$MG" "$MG_REV"
ensure_checkout https://github.com/ExpansionPak/ModernGekko-Template.git "$TPL" "$TPL_REV"
ensure_checkout https://github.com/ExpansionPak/RecompCore.git \
  "$REF/RecompCore" "$RECOMPCORE_REV"
ensure_checkout https://github.com/doldecomp/melee.git "$REF/melee" "$MELEE_REV"
ensure_checkout https://github.com/akaneia/m-ex.git "$REF/m-ex" "$MEX_REV"

if [[ -n "$(git -C "$TPL" status --porcelain --untracked-files=all)" ]]; then
  echo "unexpected local changes in $TPL" >&2
  exit 1
fi

git -C "$MG" submodule update --init vendor/dolphin
required_dolphin_submodules=(
  DolRecomp
  Externals/SDL/SDL Externals/SFML/SFML Externals/bzip2/bzip2
  Externals/cpp-optparse/cpp-optparse Externals/cubeb/cubeb
  Externals/curl/curl Externals/enet/enet Externals/fmt/fmt
  Externals/glslang/glslang Externals/hidapi/hidapi-src
  Externals/imgui/imgui Externals/implot/implot Externals/libspng/libspng
  Externals/libusb/libusb Externals/lz4/lz4
  Externals/minizip-ng/minizip-ng Externals/pugixml/pugixml
  Externals/spirv_cross/SPIRV-Cross Externals/tinygltf/tinygltf
  Externals/watcher/watcher Externals/xxhash/xxHash
  Externals/zlib-ng/zlib-ng Externals/zstd/zstd
)
git -C "$MG/vendor/dolphin" submodule update --init \
  "${required_dolphin_submodules[@]}"
git -C "$MG/vendor/dolphin/Externals/cubeb/cubeb" \
  submodule update --init --recursive

[[ "$(git -C "$MG/vendor/dolphin" rev-parse HEAD)" == "$DOLPHIN_REV" ]]
[[ "$(git -C "$MG/vendor/dolphin/DolRecomp" rev-parse HEAD)" == "$DOLRECOMP_REV" ]]

mg_patch="$SUNPAD/patches/ModernGekko/0001-sunpad-apple-runtime.patch"
dolphin_patch="$SUNPAD/patches/ModernGekko-dolphin/0001-sunpad-ios-runtime.patch"
launcher_patch="$ROOT/patches/moderngekko/0001-launcher-do-not-scan-documents-at-startup.patch"
thinlto_patch="$ROOT/patches/moderngekko/0002-macos-preserve-module-thinlto.patch"
pipe_input_patch="$ROOT/patches/moderngekko/0003-pipe-input-background.patch"
memory_watcher_test_patch="$ROOT/patches/moderngekko/0004-static-recomp-memory-watcher-test.patch"
render_log_patch="$ROOT/patches/moderngekko-dolphin/0002-buffer-render-time-logging.patch"
idle_patch="$ROOT/patches/moderngekko-dolphin/0003-gale01r0-staticrecomp-idle.patch"
memory_watcher_patch="$ROOT/patches/moderngekko-dolphin/0004-static-recomp-memory-watcher.patch"
profile_hooks_patch="$ROOT/patches/moderngekko-dolphin/0005-instrumentation-profile-hooks.patch"
apply_patch_once "$MG" "$mg_patch"
apply_patch_once "$MG/vendor/dolphin" "$dolphin_patch"
apply_patch_once "$MG" "$launcher_patch"
apply_patch_once "$MG" "$thinlto_patch"
apply_patch_once "$MG" "$pipe_input_patch"
apply_patch_once "$MG" "$memory_watcher_test_patch"
apply_patch_once "$MG/vendor/dolphin" "$render_log_patch"
apply_patch_once "$MG/vendor/dolphin" "$idle_patch"
apply_patch_once "$MG/vendor/dolphin" "$memory_watcher_patch"
apply_patch_once "$MG/vendor/dolphin" "$profile_hooks_patch"
verify_patch_scope "$MG" "$mg_patch" vendor/dolphin tools/moderngekko_launcher.cpp \
  tools/moderngekko_port.cpp tests/frontend_config_test.cpp \
  tools/frontend_config.cpp tools/frontend_config.hpp tools/moderngekko_run.cpp \
  CMakeLists.txt tests/memory_watcher_utils_test.cpp
verify_patch_scope "$MG/vendor/dolphin" "$dolphin_patch" \
  Source/Core/VideoCommon/PerformanceTracker.cpp \
  Data/Sys/GameSettings/GALE01r0.ini \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.h \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp \
  Source/Core/Core/Cheats/MemoryWatcher.cpp \
  Source/Core/Core/Cheats/MemoryWatcher.h \
  Source/Core/Core/Cheats/MemoryWatcherUtils.h \
  Source/UnitTests/Core/CMakeLists.txt \
  Source/UnitTests/Core/Cheats/MemoryWatcherUtilsTest.cpp \
  module-template/module.exports \
  module-template/module_export.c

echo "ssbmpad dependencies are pinned and patched."
