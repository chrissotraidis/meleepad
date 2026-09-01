#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
RUN="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp"

for contract in \
  'const bool lockstep_enabled = m_lockstep_verifier->IsEnabled();' \
  'STATICRECOMP_DISPATCH_SAMPLE' \
  'STATICRECOMP_FREEZE_TRACE' \
  'const bool has_rel_modules = m_module && m_module->num_rel_modules != 0;' \
  'const u32 idle_pc = m_idle_pc;' \
  'lockstep_enabled && m_lockstep_verifier->ShouldCheck(m_guest.pc)' \
  'sample_dispatches && (m_native_dispatches & 4095u) == 0' \
  'if (has_rel_modules)' \
  'if (idle_pc != 0 && m_guest.pc == idle_pc)'; do
  grep -Fq -- "$contract" "$RUN"
done

PATCH="$ROOT/patches/moderngekko-dolphin/0030-static-recomp-loop-hoists.patch"
grep -Fq 'STATICRECOMP_DISPATCH_SAMPLE' "$PATCH"
grep -Fq 'STATICRECOMP_FREEZE_TRACE' "$PATCH"
grep -Fq 'static_recomp_loop_hoists_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

echo "Static-recomp loop-hoist source checks passed"
