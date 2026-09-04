#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER="$ROOT/services/lobby/server.py"
CLIENT="$ROOT/apple/ios/MeleePadPublicLobbyClient.m"
DESIGN="$ROOT/docs/PUBLIC-LOBBY-DESIGN.md"

for file in "$SERVER" "$CLIENT" "$DESIGN"; do
  [[ -f "$file" ]] || {
    echo "public-lobby component is missing: $file" >&2
    exit 1
  }
done

for contract in \
  'MAX_BODY_BYTES = 8 * 1024' \
  'ROOM_TTL_SECONDS = 45' \
  'RESERVATION_TTL_SECONDS = 20' \
  'MAX_ROOM_CAPACITY = 4' \
  'REPORT_LIMIT = 5' \
  'hashlib.sha256' \
  'hmac.compare_digest' \
  'MAX_CHAT_MESSAGE_CHARS = 160' \
  'CHAT_MESSAGE_LIMIT = 4' \
  'CHAT_CONTROL_PATTERN' \
  'BLOCKED_TEXT_FRAGMENTS' \
  'REPORT_REASONS' \
  'Different MeleePad build' \
  'traversal_code' \
  'Cache-Control' \
  'no-store'; do
  grep -Fq "$contract" "$SERVER"
done

if grep -Fq 'QUICK_MESSAGES' "$SERVER"; then
  echo "public lobby still contains the removed quick-message allow-list" >&2
  exit 1
fi

grep -Fq '"capacity"' "$SERVER"
grep -Fq 'REPORT_CONTEXT' "$SERVER"
for contract in '"roster"' '"open_seats"' '"updated_seconds_ago"' '"joinable"'; do
  grep -Fq "$contract" "$SERVER"
done

grep -Fq 'moderngekko-netplay-8' "$CLIENT"
grep -Fq 'moderngekko-netplay-8' "$ROOT/services/lobby/test_server.py"
grep -Fq 'traversal code only after compatible join' "$DESIGN"

python3 -m unittest services.lobby.test_server

echo "public lobby security and API contracts passed"
