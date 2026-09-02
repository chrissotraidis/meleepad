#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HARNESS="$ROOT/scripts/run-g8-human-acceptance.sh"

[[ -x "$HARNESS" ]] || {
  echo "G8 human acceptance harness is missing or not executable" >&2
  exit 1
}

help="$($HARNESS --help)"
for contract in \
  'human-controlled G8 row-7 route' \
  'P1 Samus vs level-1 CPU Kirby, Stock/04, 05:00, Fountain of Dreams' \
  'Play for at least five uninterrupted combat minutes' \
  'It never drives or inspects the UI'; do
  grep -Fq "$contract" <<< "$help"
done

for contract in \
  'expected exactly one booted Simulator' \
  'recordVideo --codec=hevc --force' \
  'simctl launch --terminate-running-process' \
  'app_launched=0' \
  'exit 130' \
  'Library/Application Support/SsbmPad/Logs/runtime.log' \
  "grep ' performance fps='" \
  'reports_below_59_fps' \
  'reports_below_59_vps' \
  'reports_below_0.98_speed' \
  'minimum_capture_duration_met=0' \
  'INELIGIBLE: capture is shorter than five minutes.' \
  'video_sha256=' \
  'runtime_log_sha256=' \
  'This harness never declares row 7 passed automatically'; do
  grep -Fq "$contract" "$HARNESS"
done

if grep -Eq 'simctl io .*screenshot|get_app_state|MemoryWatcher|savestate|gcpipe|SIMCTL_CHILD_SSBMPAD_' "$HARNESS"; then
  echo "G8 human acceptance harness contains a forbidden observer or diagnostic path" >&2
  exit 1
fi

echo "G8 human acceptance harness source checks passed"
