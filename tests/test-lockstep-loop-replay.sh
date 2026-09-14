#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# Dependency selection is verified by dependency-lock.py; bootstrap no longer replays patches.
CHECK="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompLockstep_Check.cpp"
PATCH="$ROOT/patches/moderngekko-dolphin/0033-lockstep-replay-loop-interval.patch"

contract='ppc.pc == end_pc && (!replay_full_interval || interp_cycles >= native_charge)'
grep -Fq "$contract" "$CHECK"
grep -Fq "$contract" "$PATCH"

echo "Lockstep loop-interval replay source checks passed"
