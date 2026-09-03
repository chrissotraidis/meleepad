#!/usr/bin/env bash
# Recreate meleepad's ignored public dependency tree at reviewed revisions.
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
  if git -C "$checkout" apply --recount --reverse --check "$patch" >/dev/null 2>&1; then
    echo "already applied: ${patch#$ROOT/}"
  elif git -C "$checkout" apply --recount --check "$patch" >/dev/null 2>&1; then
    git -C "$checkout" apply --recount "$patch"
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
  local checkout=$1
  shift
  local patches=()
  while (( $# )) && [[ "$1" != -- ]]; do
    patches+=("$1")
    shift
  done
  if (( $# )) && [[ "$1" == -- ]]; then
    shift
  fi
  local allowed changed
  allowed=$(awk '/^diff --git / {sub(/^b\//, "", $4); print $4}' "${patches[@]}")
  # One historical patch is rooted at ModernGekko and names its Dolphin files
  # as vendor/dolphin/*. The nested checkout reports those same files without
  # that prefix, so accept both canonical spellings.
  allowed+=$'\n'
  allowed+=$(sed -n 's#^vendor/dolphin/##p' <<<"$allowed")
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
macos_diagnostics_patch="$ROOT/patches/moderngekko/0010-macos-diagnostics-export.patch"
ios_performance_defaults_patch="$ROOT/patches/moderngekko/0011-ios-shader-workers.patch"
ios_simulator_savestate_signals_patch="$ROOT/patches/moderngekko/0012-ios-simulator-savestate-signals.patch"
gamecube_netplay_session_patch="$ROOT/patches/moderngekko/0013-gamecube-netplay-session.patch"
headless_netplay_session_patch="$ROOT/patches/moderngekko/0014-headless-netplay-session.patch"
netplay_runtime_lifecycle_patch="$ROOT/patches/moderngekko/0015-netplay-runtime-lifecycle.patch"
netplay_timebase_status_patch="$ROOT/patches/moderngekko/0016-netplay-timebase-status-history.patch"
executable_boot_caller_idle_patch="$ROOT/patches/moderngekko/0017-executable-boot-caller-idle-config.patch"
netplay_canonical_boundary_test_patch="$ROOT/patches/moderngekko/0018-netplay-canonical-boundary-test.patch"
netplay_canonical_status_patch="$ROOT/patches/moderngekko/0019-netplay-canonical-status-history.patch"
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
lightweight_frame_index_activation_patch="$ROOT/patches/moderngekko-dolphin/0025-lightweight-frame-index-activation.patch"
ios_metal_display_sync_availability_patch="$ROOT/patches/moderngekko-dolphin/0026-ios-metal-display-sync-availability.patch"
ios_simulator_framebuffer_fetch_patch="$ROOT/patches/moderngekko-dolphin/0027-ios-simulator-disable-framebuffer-fetch.patch"
ios_audio_diagnostics_patch="$ROOT/patches/moderngekko-dolphin/0028-ios-audio-continuity-diagnostics.patch"
pipe_short_tap_patch="$ROOT/patches/moderngekko-dolphin/0029-pipe-short-tap-latching.patch"
static_recomp_loop_hoists_patch="$ROOT/patches/moderngekko-dolphin/0030-static-recomp-loop-hoists.patch"
frame_workload_attribution_patch="$ROOT/patches/moderngekko-dolphin/0031-frame-workload-attribution.patch"
lockstep_cache_side_effect_patch="$ROOT/patches/moderngekko-dolphin/0032-lockstep-skip-cache-side-effects.patch"
lockstep_loop_replay_patch="$ROOT/patches/moderngekko-dolphin/0033-lockstep-replay-loop-interval.patch"
lockstep_repeat_set_patch="$ROOT/patches/moderngekko-dolphin/0034-lockstep-repeat-pc-set.patch"
xfb_boundary_attribution_patch="$ROOT/patches/moderngekko-dolphin/0035-xfb-boundary-attribution.patch"
static_recomp_dispatch_burst_patch="$ROOT/patches/moderngekko-dolphin/0036-static-recomp-dispatch-burst-trace.patch"
dispatch_sample_phase_patch="$ROOT/patches/moderngekko-dolphin/0037-dispatch-sample-phase-control.patch"
caller_idle_preflight_patch="$ROOT/patches/moderngekko-dolphin/0038-caller-qualified-idle-preflight.patch"
gamecube_netplay_controller_patch="$ROOT/patches/moderngekko-dolphin/0039-gamecube-netplay-controller-family.patch"
macos_sdl_application_patch="$ROOT/patches/moderngekko-dolphin/0040-macos-sdl-application-handoff.patch"
netplay_save_lifetime_patch="$ROOT/patches/moderngekko-dolphin/0041-netplay-save-write-lifetime.patch"
netplay_timebase_telemetry_patch="$ROOT/patches/moderngekko-dolphin/0042-netplay-timebase-mismatch-telemetry.patch"
netplay_execution_fingerprint_patch="$ROOT/patches/moderngekko-dolphin/0043-netplay-execution-fingerprint.patch"
netplay_canonical_boundary_patch="$ROOT/patches/moderngekko-dolphin/0044-netplay-canonical-boundary.patch"
netplay_canonical_summary_patch="$ROOT/patches/moderngekko-dolphin/0045-netplay-canonical-difference-summary.patch"
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
  Source/Core/VideoCommon/Present.cpp MELEEPAD_FRAME_PHASE_SLOW_MARKER
apply_patch_once "$MG/vendor/dolphin" "$dispatch_counts_patch"
apply_patch_once_or_marker "$MG/vendor/dolphin" "$dispatch_frame_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  STATICRECOMP_DISPATCH_FRAME_LOG
apply_patch_once "$MG/vendor/dolphin" "$paired_store_patch"
apply_patch_once_or_marker "$MG" "$savestate_signal_patch" \
  src/runtime/dolphin_runtime.cpp MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS
apply_patch_once_or_marker "$MG" "$extracted_idle_patch" \
  src/runtime/dolphin_runtime.cpp \
  'Executable-only boots do not give Dolphin a disc volume'
apply_patch_once_or_marker "$MG" "$app_bundle_sys_patch" \
  CMakeLists.txt MODERNGEKKO_APP_BUNDLE
apply_patch_once "$MG" "$pgo_cache_patch"
apply_patch_once_or_marker "$MG" "$metal_sync_config_patch" \
  CMakeLists.txt MODERNGEKKO_MACOS_METAL_DISPLAY_SYNC
apply_patch_once_or_marker "$MG" "$macos_diagnostics_patch" \
  tools/moderngekko_launcher.cpp 'ImGui::Button("Export Diagnostics")'
apply_patch_once_or_marker "$MG" "$ios_performance_defaults_patch" \
  src/runtime/dolphin_runtime.cpp \
  'Config::SetBase(Config::GFX_SHADER_COMPILER_THREADS, 3);'
apply_patch_once_or_marker "$MG" "$ios_simulator_savestate_signals_patch" \
  src/runtime/dolphin_runtime.cpp MODERNGEKKO_HAVE_SAVESTATE_SIGNALS
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
  Source/Core/VideoCommon/ShaderCache.cpp MELEEPAD_PREWARM_EFB_VRAM
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_phase_host_timestamp_patch" \
  Source/Core/VideoCommon/Present.cpp host_frame_end_unix_ns
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_task_event_patch" \
  Source/Core/VideoCommon/Present.cpp task_context_switches
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lightweight_frame_timing_patch" \
  Source/Core/VideoCommon/PerformanceTracker.cpp MELEEPAD_LIGHTWEIGHT_FRAME_LOG
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lightweight_frame_identity_patch" \
  Source/Core/VideoCommon/LightweightFrameTimingRecorder.cpp emulated_frame
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lightweight_frame_index_activation_patch" \
  Source/Core/Common/FramePhaseTiming.h IsEmulatedFrameIndexEnabled
apply_patch_once_or_marker "$MG/vendor/dolphin" "$ios_metal_display_sync_availability_patch" \
  Source/Core/VideoBackends/Metal/MTLGfx.mm '#if TARGET_OS_OSX'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$ios_simulator_framebuffer_fetch_patch" \
  Source/Core/VideoBackends/Metal/MTLUtil.mm 'The Simulator reports an Apple GPU family'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$ios_audio_diagnostics_patch" \
  Source/Core/AudioCommon/Mixer.h GetDMAUnderrunCount
apply_patch_once "$MG/vendor/dolphin" "$pipe_short_tap_patch"
apply_patch_once_or_marker "$MG/vendor/dolphin" "$static_recomp_loop_hoists_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp \
  STATICRECOMP_DISPATCH_SAMPLE
apply_patch_once_or_marker "$MG/vendor/dolphin" "$frame_workload_attribution_patch" \
  Source/Core/Common/FramePhaseTiming.h s_metal_pipeline_creates
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lockstep_cache_side_effect_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Hooks.cpp \
  'Cache-control hooks mutate cache state that the lockstep journal cannot replay.'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lockstep_loop_replay_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompLockstep_Check.cpp \
  'ppc.pc == end_pc && (!replay_full_interval || interp_cycles >= native_charge)'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$lockstep_repeat_set_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompLockstep.cpp \
  'parse_pc_set(s, m_ls_repeat_pcs);'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$xfb_boundary_attribution_patch" \
  Source/Core/Common/FramePhaseTiming.h s_xfb_output_requests
apply_patch_once_or_marker "$MG/vendor/dolphin" "$static_recomp_dispatch_burst_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  STATICRECOMP_DISPATCH_BURST_LOG
apply_patch_once_or_marker "$MG/vendor/dolphin" "$dispatch_sample_phase_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  STATICRECOMP_DISPATCH_SAMPLE_INTERVAL
apply_patch_once_or_marker "$MG/vendor/dolphin" "$caller_idle_preflight_patch" \
  Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp \
  STATICRECOMP_CALLER_IDLE_PC
apply_patch_once_or_marker "$MG/vendor/dolphin" "$gamecube_netplay_controller_patch" \
  Source/Core/Core/NetPlay/NetPlayProto.h \
  'enum class ControllerFamily'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$macos_sdl_application_patch" \
  Source/Core/DolphinNoGUI/PlatformMacos.mm \
  'NSApplication (ModernGekkoApplication)'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$netplay_save_lifetime_patch" \
  Source/Core/Core/HW/GCMemcard/GCMemcardDirectory.h \
  'const bool m_save_data_writable;'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$netplay_timebase_telemetry_patch" \
  Source/Core/Core/NetPlay/NetPlayServer.cpp \
  'netplay-timebase frame='
apply_patch_once_or_marker "$MG/vendor/dolphin" "$netplay_execution_fingerprint_patch" \
  Source/Core/Core/NetPlay/NetPlayServer.h \
  'struct TimeBaseRecord'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$netplay_canonical_boundary_patch" \
  Source/Core/Core/NetPlay/NetPlayCommon.h \
  'struct CanonicalStateSnapshot'
apply_patch_once_or_marker "$MG/vendor/dolphin" "$netplay_canonical_summary_patch" \
  Source/Core/Core/NetPlay/NetPlayServer.cpp \
  '" differences=" + differences'
apply_patch_once_or_marker "$MG" "$gamecube_netplay_session_patch" \
  tools/netplay_session_core.cpp \
  'SetControllerFamily(NetPlay::ControllerFamily::GameCube)'
apply_patch_once_or_marker "$MG" "$headless_netplay_session_patch" \
  tools/netplay_session.hpp \
  'class NetplaySession'
apply_patch_once_or_marker "$MG" "$netplay_runtime_lifecycle_patch" \
  tools/netplay_session_core.cpp \
  'void NetplaySession::FinishRuntime()'
apply_patch_once_or_marker "$MG" "$netplay_timebase_status_patch" \
  tools/netplay_session_core.cpp \
  'm_status.starts_with("netplay-timebase")'
apply_patch_once_or_marker "$MG" "$executable_boot_caller_idle_patch" \
  src/runtime/dolphin_runtime.cpp \
  'StaticRecompCallerIdlePC'
apply_patch_once_or_marker "$MG" "$netplay_canonical_boundary_test_patch" \
  tests/netplay_protocol_test.cpp \
  'NetPlay::CanonicalStateSnapshot canonical'
apply_patch_once_or_marker "$MG" "$netplay_canonical_status_patch" \
  tools/netplay_session_core.cpp \
  'message.starts_with("netplay-canonical")'
verify_patch_scope "$MG" "$mg_patch" "$ROOT"/patches/moderngekko/*.patch -- \
  vendor/dolphin
verify_patch_scope "$MG/vendor/dolphin" "$dolphin_patch" "$mg_patch" \
  "$ROOT"/patches/moderngekko-dolphin/*.patch -- DolRecomp
verify_patch_scope "$MG/vendor/dolphin/DolRecomp" \
  "$ROOT"/patches/dolrecomp/*.patch --

echo "meleepad dependencies are pinned and patched."
