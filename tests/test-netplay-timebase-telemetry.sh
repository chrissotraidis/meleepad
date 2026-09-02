#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DOLPHIN_PATCH="$ROOT/patches/moderngekko-dolphin/0042-netplay-timebase-mismatch-telemetry.patch"
SESSION_PATCH="$ROOT/patches/moderngekko/0016-netplay-timebase-status-history.patch"
BOOTSTRAP="$ROOT/scripts/bootstrap-dependencies.sh"

for contract in \
  'netplay-timebase frame=' \
  'pid=' \
  'reported_timebase' \
  'AppendChat(mismatch)'; do
  grep -Fq "$contract" "$DOLPHIN_PATCH"
done

for contract in \
  'm_status.find("; ")' \
  'm_status.erase(0, separator + 2)' \
  'm_error += ": " + m_status'; do
  grep -Fq "$contract" "$SESSION_PATCH"
done

grep -Fq '0042-netplay-timebase-mismatch-telemetry.patch' "$BOOTSTRAP"
grep -Fq '0016-netplay-timebase-status-history.patch' "$BOOTSTRAP"

echo "Netplay timebase mismatch telemetry source contract passed"
