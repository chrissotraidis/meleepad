#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CORE="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp"
HEADER="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.h"
RUN="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp"
TIMING="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Common/FramePhaseTiming.h"
PATCH="$ROOT/patches/moderngekko-dolphin/0036-static-recomp-dispatch-burst-trace.patch"

grep -Fq 'STATICRECOMP_DISPATCH_BURST_LOG' "$CORE"
grep -Fq 'void FlushDispatchBurstSamples(bool final);' "$HEADER"
grep -Fq 'm_dispatch_burst_remaining = 16' "$RUN"
grep -Fq '(m_native_dispatches & 16383u) == 0' "$RUN"
grep -Fq 'present_frame,emulated_frame,burst,index,previous_pc,pc' "$CORE"
grep -Fq 'm_dispatch_burst_log_path.clear();' "$CORE"
grep -Fq 'm_dispatch_burst_samples.clear();' "$CORE"
grep -Fq 'STATICRECOMP_DISPATCH_BURST_LOG' "$TIMING"
grep -Fq 'STATICRECOMP_DISPATCH_BURST_LOG' "$PATCH"
grep -Fq 'm_dispatch_burst_log_path.clear();' "$PATCH"
grep -Fq 'm_dispatch_burst_samples.clear();' "$PATCH"
grep -Fq 'static_recomp_dispatch_burst_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

echo "Static-recomp dispatch burst trace source checks passed"
