#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TIMING="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Common/FramePhaseTiming.h"
PRESENT="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/Present.cpp"
METAL="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoBackends/Metal/MTLObjectCache.mm"
STATIC_HEADER="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.h"
STATIC_CORE="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp"
STATIC_RUN="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp"

for contract in \
  's_metal_pipeline_creates' \
  's_metal_pipeline_create_ns' \
  'AddMetalPipelineCreate' \
  'metal_pipeline_creates' \
  'metal_pipeline_create_ns'; do
  grep -Fq -- "$contract" "$TIMING"
done

grep -Fq 'Common::FramePhaseTiming::AddMetalPipelineCreate' "$METAL"
grep -Fq 'draw_calls,primitives,vertex_shaders_created,pixel_shaders_created,textures_created,metal_pipeline_creates,metal_pipeline_ms' "$PRESENT"
grep -Fq 'g_stats.this_frame.num_draw_calls' "$PRESENT"
grep -Fq 'g_stats.this_frame.num_prims + g_stats.this_frame.num_dl_prims' "$PRESENT"
grep -Fq 'void FlushDispatchFrameSamples(bool final);' "$STATIC_HEADER"
grep -Fq 'void StaticRecompCore::FlushDispatchFrameSamples(bool final)' "$STATIC_CORE"
grep -Fq 'm_dispatch_frame_samples.size() >= 16384' "$STATIC_RUN"

PATCH="$ROOT/patches/moderngekko-dolphin/0031-frame-workload-attribution.patch"
grep -Fq 's_metal_pipeline_creates' "$PATCH"
grep -Fq 'FlushDispatchFrameSamples' "$PATCH"
grep -Fq 'frame_workload_attribution_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

echo "Frame workload attribution source checks passed"
