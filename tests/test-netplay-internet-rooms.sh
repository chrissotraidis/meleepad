#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# Dependency selection is verified by dependency-lock.py; bootstrap no longer replays patches.
PATCH="$ROOT/patches/moderngekko/0020-netplay-internet-rooms.patch"

for contract in \
  'stun.dolphin-emu.org' \
  'TRAVERSAL_PORT = 6262' \
  'TRAVERSAL_PORT_ALT = 6226' \
  'bool use_traversal = false' \
  'std::string room_code' \
  'Common::g_TraversalClient->GetHostID()' \
  'Internet room connection failed' \
  '--netplay-room-host' \
  '--netplay-room-join <code>' \
  'MELEEPAD_NETPLAY_TRACE_ROOM_CODE'; do
  grep -Fq -- "$contract" "$PATCH"
done


echo "Netplay Internet-room source contract passed"
