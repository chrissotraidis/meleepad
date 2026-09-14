#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# Dependency selection is verified by dependency-lock.py; bootstrap no longer replays patches.
RUN="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp"

for contract in \
  'const bool lockstep_enabled = Diagnostics && m_lockstep_verifier->IsEnabled();' \
  'RunWithDiagnostics<true>();' \
  'RunWithDiagnostics<false>();' \
  'const bool diagnostics = Common::FramePhaseTiming::IsEnabled() ||' \
  'STATICRECOMP_DISPATCH_SAMPLE' \
  'STATICRECOMP_FREEZE_TRACE' \
  'const bool has_rel_modules = m_module && m_module->num_rel_modules != 0;' \
  'const u32 idle_pc = m_idle_pc;' \
  'lockstep_enabled && m_lockstep_verifier->ShouldCheck(m_guest.pc)' \
  'sample_dispatches &&' \
  'm_native_dispatches % m_dispatch_sample_interval == m_dispatch_sample_offset' \
  'if (has_rel_modules)' \
  'const bool configured_idle = idle_pc != 0 && m_guest.pc == idle_pc;' \
  'const bool secondary_idle =' \
  'const bool caller_idle = m_caller_idle_pc != 0 && m_caller_idle_lr != 0' \
  'if (configured_idle || secondary_idle || caller_idle)'; do
  grep -Fq -- "$contract" "$RUN"
done

PATCH="$ROOT/patches/moderngekko-dolphin/0030-static-recomp-loop-hoists.patch"
grep -Fq 'STATICRECOMP_DISPATCH_SAMPLE' "$PATCH"
grep -Fq 'STATICRECOMP_FREEZE_TRACE' "$PATCH"

echo "Static-recomp loop-hoist source checks passed"
