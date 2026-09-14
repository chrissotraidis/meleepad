#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# Dependency selection is verified by dependency-lock.py; bootstrap no longer replays patches.
TIMING="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Common/FramePhaseTiming.h"
BACKEND="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/VideoBackendBase.cpp"
PRESENT="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/Present.cpp"
PATCH="$ROOT/patches/moderngekko-dolphin/0035-xfb-boundary-attribution.patch"

for contract in \
  s_xfb_output_requests \
  s_xfb_swap_queued \
  s_xfb_swap_executed \
  s_xfb_duplicates \
  s_xfb_presents; do
  grep -Fq -- "$contract" "$TIMING"
  grep -Fq -- "$contract" "$PATCH"
done

grep -Fq 'AddXfbOutputRequest' "$BACKEND"
grep -Fq 'AddXfbSwapQueued' "$BACKEND"
grep -Fq 'AddXfbSwapExecuted' "$BACKEND"
grep -Fq 'AddXfbDuplicate' "$PRESENT"
grep -Fq 'AddXfbPresent' "$PRESENT"
grep -Fq '"efb_ram_shader_ms,efb_ram_pipeline_ms,xfb_output_requests,"' "$PRESENT"
grep -Fq '"xfb_swap_queued,xfb_swap_executed,xfb_duplicates,xfb_presents\n"' "$PRESENT"

echo "XFB boundary attribution source checks passed"
