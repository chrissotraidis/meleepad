#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HOOKS="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Hooks.cpp"
PATCH="$ROOT/patches/moderngekko-dolphin/0032-lockstep-skip-cache-side-effects.patch"

grep -Fq 'Cache-control hooks mutate cache state that the lockstep journal cannot replay.' "$HOOKS"
grep -Fq 'core->m_lockstep_verifier->m_ls_fallback_seen = true;' "$HOOKS"
grep -Fq 'Cache-control hooks mutate cache state that the lockstep journal cannot replay.' "$PATCH"
grep -Fq 'lockstep_cache_side_effect_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

echo "Lockstep cache-side-effect skip source checks passed"
