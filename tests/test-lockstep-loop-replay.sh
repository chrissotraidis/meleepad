#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CHECK="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompLockstep_Check.cpp"
PATCH="$ROOT/patches/moderngekko-dolphin/0033-lockstep-replay-loop-interval.patch"

contract='ppc.pc == end_pc && (!replay_full_interval || interp_cycles >= native_charge)'
grep -Fq "$contract" "$CHECK"
grep -Fq "$contract" "$PATCH"
grep -Fq 'lockstep_loop_replay_patch=' "$ROOT/scripts/bootstrap-dependencies.sh"

echo "Lockstep loop-interval replay source checks passed"
