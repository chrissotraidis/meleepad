#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# Dependency selection is verified by dependency-lock.py; bootstrap no longer replays patches.
HEADER="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompLockstep.h"
SOURCE="$ROOT/ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompLockstep.cpp"
PATCH="$ROOT/patches/moderngekko-dolphin/0034-lockstep-repeat-pc-set.patch"

grep -Fq 'std::unordered_set<u32> m_ls_repeat_pcs' "$HEADER"
grep -Fq 'parse_pc_set(s, m_ls_repeat_pcs);' "$SOURCE"
grep -Fq 'm_ls_repeat_pcs.find(address) != m_ls_repeat_pcs.end()' "$SOURCE"
grep -Fq 'm_ls_repeat_pcs' "$PATCH"

echo "Lockstep repeat-PC set source checks passed"
