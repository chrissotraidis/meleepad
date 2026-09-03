#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PATCH="$ROOT/patches/moderngekko-dolphin/0044-netplay-canonical-boundary.patch"
TEST_PATCH="$ROOT/patches/moderngekko/0018-netplay-canonical-boundary-test.patch"
BOOTSTRAP="$ROOT/scripts/bootstrap-dependencies.sh"

test -f "$PATCH"

for contract in \
  'struct NetplayBoundarySnapshot' \
  'CaptureNetplayBoundarySnapshot' \
  'm_netplay_boundary_sequence % 60' \
  'NetPlay::IsNetPlayRunning()' \
  'm_caller_idle_pc != 0 && m_caller_idle_lr != 0 ? caller_idle : configured_idle' \
  'canonical-boundary active' \
  'GetNetplayBoundarySnapshot' \
  'HashSelectedRamPages' \
  'CanonicalStateMatches' \
  'moderngekko-netplay-7' \
  'canonical_sequence=' \
  'canonical_ram_hash=' \
  'canonical-match sequence=' \
  'canonical-unpaired sequence=' \
  'm_canonical_by_sequence'; do
  grep -Fq "$contract" "$PATCH"
done

for contract in \
  'integer_state_hash ^=' \
  'fpr_state_hash ^=' \
  'paired_state_hash ^=' \
  'timebase ^=' \
  'ram_hash ^='; do
  grep -Fq "$contract" "$TEST_PATCH"
done

grep -Fq '0044-netplay-canonical-boundary.patch' "$BOOTSTRAP"

echo "Netplay canonical-boundary source contract passed"
