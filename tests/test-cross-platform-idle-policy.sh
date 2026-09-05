#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
GAME_INI_PATCH="$ROOT/patches/moderngekko-dolphin/0003-gale01r0-staticrecomp-idle.patch"
SECONDARY_CORE_PATCH="$ROOT/patches/moderngekko-dolphin/0049-secondary-idle-preflight.patch"
RUNTIME_PATCH="$ROOT/patches/moderngekko/0017-executable-boot-caller-idle-config.patch"
SECONDARY_RUNTIME_PATCH="$ROOT/patches/moderngekko/0022-secondary-idle-policy.patch"
BOOTSTRAP="$ROOT/scripts/bootstrap-dependencies.sh"

for contract in \
  'StaticRecompIdlePC = 0x80348814' \
  'StaticRecompCallerIdlePC = 0x80019550' \
  'StaticRecompCallerIdleLR = 0x801A4064'; do
  grep -Fq "$contract" "$GAME_INI_PATCH"
done

for contract in \
  'StaticRecompSecondaryIdlePC = 0x80349494' \
  'MAIN_STATICRECOMP_SECONDARY_IDLE_PC'; do
  grep -Fq "$contract" "$SECONDARY_CORE_PATCH"
done

for contract in \
  'StaticRecompSecondaryIdlePC' \
  'MAIN_STATICRECOMP_SECONDARY_IDLE_PC'; do
  grep -Fq "$contract" "$SECONDARY_RUNTIME_PATCH"
done

for contract in \
  'StaticRecompCallerIdlePC' \
  'StaticRecompCallerIdleLR' \
  'MAIN_STATICRECOMP_CALLER_IDLE_PC' \
  'MAIN_STATICRECOMP_CALLER_IDLE_LR'; do
  grep -Fq "$contract" "$RUNTIME_PATCH"
done

grep -Fq '0017-executable-boot-caller-idle-config.patch' "$BOOTSTRAP"
grep -Fq '0022-secondary-idle-policy.patch' "$BOOTSTRAP"
grep -Fq "Data/Sys/GameSettings/GALE01r0.ini 'StaticRecompIdlePC = 0x80348814'" "$BOOTSTRAP"

echo "Cross-platform static-recomp idle policy source checks passed"
