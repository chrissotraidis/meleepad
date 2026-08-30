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

# A later canonical patch may intentionally edit a hunk introduced by an
# earlier one, making that earlier patch impossible to reverse-check in
# isolation. In those explicit cases, use a unique retained source marker.
apply_patch_once_or_marker() {
  local checkout=$1 patch=$2 marker_file=$3 marker=$4
  if grep -Fq "$marker" "$checkout/$marker_file"; then
    echo "already applied (composed): ${patch#$ROOT/}"
  else
    apply_patch_once "$checkout" "$patch"
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
module_source_cache_patch="$ROOT/patches/moderngekko/0005-module-source-cache-identity.patch"
extracted_idle_patch="$ROOT/patches/moderngekko/0006-extracted-game-idle-config.patch"
app_bundle_sys_patch="$ROOT/patches/moderngekko/0007-macos-app-bundle-sys.patch"
pgo_cache_patch="$ROOT/patches/moderngekko/0008-private-pgo-cache-identity.patch"
metal_sync_config_patch="$ROOT/patches/moderngekko/0009-macos-metal-display-sync.patch"
render_log_patch="$ROOT/patches/moderngekko-dolphin/0002-buffer-render-time-logging.patch"
idle_patch="$ROOT/patches/moderngekko-dolphin/0003-gale01r0-staticrecomp-idle.patch"
memory_watcher_patch="$ROOT/patches/moderngekko-dolphin/0004-static-recomp-memory-watcher.patch"
profile_hooks_patch="$ROOT/patches/moderngekko-dolphin/0005-instrumentation-profile-hooks.patch"
frame_phase_patch="$ROOT/patches/moderngekko-dolphin/0006-buffered-frame-phase-timing.patch"
dolrecomp_scalar_patch="$ROOT/patches/dolrecomp/0001-scalar-single-semantics.patch"
dolrecomp_fma_patch="$ROOT/patches/dolrecomp/0002-scalar-fma-semantics.patch"
dolrecomp_multiword_patch="$ROOT/patches/dolrecomp/0003-multiword-range-helpers.patch"
gxruntime_scalar_patch="$ROOT/patches/moderngekko-dolphin/0007-gxruntime-scalar-single-semantics.patch"
cache_control_patch="$ROOT/patches/moderngekko-dolphin/0008-static-recomp-cache-control-parity.patch"
slow_window_patch="$ROOT/patches/moderngekko-dolphin/0009-slow-window-phase-trigger.patch"
dispatch_counts_patch="$ROOT/patches/moderngekko-dolphin/0010-module-dispatch-branch-counts.patch"
dispatch_frame_patch="$ROOT/patches/moderngekko-dolphin/0011-dispatch-frame-attribution.patch"
paired_store_patch="$ROOT/patches/moderngekko-dolphin/0012-gxruntime-paired-store-transactions.patch"
savestate_signal_patch="$ROOT/patches/moderngekko-dolphin/0013-runtime-savestate-signal-harness.patch"
emulated_frame_patch="$ROOT/patches/moderngekko-dolphin/0014-emulated-frame-phase-index.patch"
gxruntime_fma_test_patch="$ROOT/patches/moderngekko-dolphin/0015-gxruntime-scalar-fma-tests.patch"
gxruntime_multiword_patch="$ROOT/patches/moderngekko-dolphin/0016-gxruntime-multiword-range-helpers.patch"
metal_sync_runtime_patch="$ROOT/patches/moderngekko-dolphin/0017-macos-layer-display-sync.patch"
efb_pipeline_timing_patch="$ROOT/patches/moderngekko-dolphin/0018-efb-pipeline-phase-timing.patch"
frame_wait_attribution_patch="$ROOT/patches/moderngekko-dolphin/0019-frame-wait-attribution.patch"
efb_vram_prewarm_patch="$ROOT/patches/moderngekko-dolphin/0020-efb-vram-prewarm.patch"
frame_phase_host_timestamp_patch="$ROOT/patches/moderngekko-dolphin/0021-frame-phase-host-timestamp.patch"
frame_task_event_patch="$ROOT/patches/moderngekko-dolphin/0022-frame-task-event-attribution.patch"
lightweight_frame_timing_patch="$ROOT/patches/moderngekko-dolphin/0023-lightweight-frame-timing.patch"
lightweight_frame_identity_patch="$ROOT/patches/moderngekko-dolphin/0024-lightweight-frame-identity.patch"
apply_patch_once_or_marker "$MG" "$mg_patch" \
  include/moderngekko/runtime.hpp 'struct RuntimeDiagnosticsSnapshot'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$dolphin_patch" \
  Source/Core/DolphinNoGUI/PlatformIOS.mm 'class PlatformIOS : public Platform'
apply_patch_once "$MG" "$launcher_patch"
apply_patch_once "$MG" "$thinlto_patch"
apply_patch_once "$MG" "$pipe_input_patch"
apply_patch_once "$MG" "$memory_watcher_test_patch"
apply_patch_once_or_marker "$MG" "$module_source_cache_patch" \
  tools/moderngekko_port.cpp ModuleSourceFingerprint
apply_patch_once "$MG/vendor/dolphin" "$render_log_patch"
apply_patch_once "$MG/vendor/dolphin" "$idle_patch"
apply_patch_once "$MG/vendor/dolphin" "$memory_watcher_patch"
apply_patch_once_or_marker "$MG/vendor/dolphin" "$profile_hooks_patch" \
  module-template/module_export.c staticrecomp_profile_reset
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_phase_patch" \
  Source/Core/Common/FramePhaseTiming.h s_cpu_throttle_requested_ns
apply_patch_once_or_marker "$MG/vendor/dolphin/DolRecomp" "$dolrecomp_scalar_patch" \
  src/backend/emitter.c 'ppc_fadds(ctx'
apply_patch_once "$MG/vendor/dolphin/DolRecomp" "$dolrecomp_fma_patch"
apply_patch_once "$MG/vendor/dolphin/DolRecomp" "$dolrecomp_multiword_patch"
apply_patch_once_or_marker "$MG/vendor/dolphin" "$gxruntime_scalar_patch" \
  GXRuntime/src/core/cpu_interpreter_float.c GXRUNTIME_ALWAYS_INLINE
apply_patch_once_or_marker "$MG/vendor/dolphin" "$cache_control_patch" \
  Source/Core/Common/FramePhaseTiming.h s_static_recomp_cache_controls
apply_patch_once_or_marker "$MG/vendor/dolphin" "$slow_window_patch" \
  Source/Core/VideoCommon/Present.cpp SSBMPAD_FRAME_PHASE_SLOW_MARKER
apply_patch_once "$MG/vendor/dolphin" "$dispatch_counts_patch"
apply_patch_once_or_marker "$MG/vendor/dolphin" "$dispatch_frame_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  STATICRECOMP_DISPATCH_FRAME_LOG
apply_patch_once "$MG/vendor/dolphin" "$paired_store_patch"
apply_patch_once "$MG" "$savestate_signal_patch"
apply_patch_once_or_marker "$MG" "$extracted_idle_patch" \
  src/runtime/dolphin_runtime.cpp \
  'Executable-only boots do not give Dolphin a disc volume'
apply_patch_once_or_marker "$MG" "$app_bundle_sys_patch" \
  CMakeLists.txt MODERNGEKKO_APP_BUNDLE
apply_patch_once "$MG" "$pgo_cache_patch"
apply_patch_once_or_marker "$MG" "$metal_sync_config_patch" \
  CMakeLists.txt MODERNGEKKO_MACOS_METAL_DISPLAY_SYNC
apply_patch_once_or_marker "$MG/vendor/dolphin" "$emulated_frame_patch" \
  Source/Core/Common/FramePhaseTiming.h s_emulated_frame_index
apply_patch_once_or_marker "$MG/vendor/dolphin" "$gxruntime_fma_test_patch" \
  GXRuntime/tests/runtime_tests.c test_scalar_fma_semantics
apply_patch_once "$MG/vendor/dolphin" "$gxruntime_multiword_patch"
apply_patch_once_or_marker "$MG/vendor/dolphin" "$metal_sync_runtime_patch" \
  Source/Core/VideoBackends/Metal/MTLGfx.mm \
  'metal layer display sync: product policy enabled'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$efb_pipeline_timing_patch" \
  Source/Core/Common/FramePhaseTiming.h s_efb_vram_pipeline_misses
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_wait_attribution_patch" \
  Source/Core/Common/FramePhaseTiming.h s_cpu_precision_throttle_calls
apply_patch_once_or_marker "$MG/vendor/dolphin" "$efb_vram_prewarm_patch" \
  Source/Core/VideoCommon/ShaderCache.cpp SSBMPAD_PREWARM_EFB_VRAM
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_phase_host_timestamp_patch" \
  Source/Core/VideoCommon/Present.cpp host_frame_end_unix_ns
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_task_event_patch" \
  Source/Core/VideoCommon/Present.cpp task_context_switches
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lightweight_frame_timing_patch" \
  Source/Core/VideoCommon/PerformanceTracker.cpp SSBMPAD_LIGHTWEIGHT_FRAME_LOG
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lightweight_frame_identity_patch" \
  Source/Core/VideoCommon/LightweightFrameTimingRecorder.cpp emulated_frame
verify_patch_scope "$MG" "$mg_patch" vendor/dolphin tools/moderngekko_launcher.cpp \
  tools/moderngekko_port.cpp tests/frontend_config_test.cpp \
  tools/frontend_config.cpp tools/frontend_config.hpp tools/moderngekko_run.cpp \
  CMakeLists.txt tests/memory_watcher_utils_test.cpp \
  src/runtime/dolphin_runtime.cpp src/runtime/game.cpp \
  include/moderngekko/game.hpp tests/game_inspect_test.cpp
verify_patch_scope "$MG/vendor/dolphin" "$dolphin_patch" \
  DolRecomp \
  Source/Core/VideoCommon/PerformanceTracker.cpp \
  Data/Sys/GameSettings/GALE01r0.ini \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.h \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp \
  Source/Core/Common/FramePhaseTiming.h \
  Source/Core/Common/Timer.cpp \
  Source/Core/Common/Timer.h \
  Source/Core/Core/CoreTiming.h \
  Source/Core/Core/HW/VideoInterface.cpp \
  Source/Core/Core/CoreTiming.cpp \
  Source/Core/AudioCommon/Mixer.cpp \
  Source/Core/VideoBackends/Metal/MTLGfx.mm \
  Source/Core/VideoCommon/CMakeLists.txt \
  Source/Core/VideoCommon/Present.cpp \
  Source/Core/VideoCommon/LightweightFrameTimingRecorder.cpp \
  Source/Core/VideoCommon/LightweightFrameTimingRecorder.h \
  Source/Core/VideoCommon/PerformanceTracker.h \
  Source/Core/VideoCommon/ShaderCache.cpp \
  Source/Core/DolphinNoGUI/Platform.cpp \
  Source/Core/Core/Cheats/MemoryWatcher.cpp \
  Source/Core/Core/Cheats/MemoryWatcher.h \
  Source/Core/Core/Cheats/MemoryWatcherUtils.h \
  Source/UnitTests/Core/CMakeLists.txt \
  Source/UnitTests/Core/Cheats/MemoryWatcherUtilsTest.cpp \
  module-template/CMakeLists.txt \
  module-template/module.exports \
  module-template/module_export.c \
  GXRuntime/src/core/cpu.c \
  GXRuntime/include/core/cpu.h \
  GXRuntime/src/core/cpu_interpreter_float.c \
  GXRuntime/tests/runtime_tests.c
verify_patch_scope "$MG/vendor/dolphin/DolRecomp" "$dolrecomp_scalar_patch" \
  src/backend/emitter.c src/cpu/cpu.c src/cpu/cpu.h

echo "ssbmpad dependencies are pinned and patched."
