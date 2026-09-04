#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SERVER="$ROOT/services/lobby/server.py"
CLIENT="$ROOT/apple/ios/MeleePadPublicLobbyClient.m"
DESIGN="$ROOT/docs/PUBLIC-LOBBY-DESIGN.md"
CLOUDFLARE_COMPOSE="$ROOT/services/lobby/compose.cloudflare.yaml"
DIGITALOCEAN_RUNBOOK="$ROOT/docs/PUBLIC-LOBBY-DIGITALOCEAN.md"

for file in "$SERVER" "$CLIENT" "$DESIGN" "$CLOUDFLARE_COMPOSE" "$DIGITALOCEAN_RUNBOOK"; do
  [[ -f "$file" ]] || {
    echo "public-lobby component is missing: $file" >&2
    exit 1
  }
done

for contract in \
  'MAX_BODY_BYTES = 8 * 1024' \
  'MAX_SESSIONS = 5000' \
  'MAX_RATE_LIMIT_KEYS = 10000' \
  'MAX_CONCURRENT_REQUESTS = 64' \
  'REQUEST_SOCKET_TIMEOUT_SECONDS = 10' \
  'ROOM_TTL_SECONDS = 45' \
  'RESERVATION_TTL_SECONDS = 20' \
  'MAX_ROOM_CAPACITY = 4' \
  'REPORT_LIMIT = 5' \
  'hashlib.sha256' \
  'hmac.compare_digest' \
  'threading.BoundedSemaphore' \
  'CF-Connecting-IP' \
  'trust_cloudflare' \
  'hmac.new(salt' \
  'MAX_CHAT_MESSAGE_CHARS = 160' \
  'CHAT_MESSAGE_LIMIT = 4' \
  'CHAT_CONTROL_PATTERN' \
  'BLOCKED_TEXT_FRAGMENTS' \
  'REPORT_REASONS' \
  'Different app build' \
  'DIRECTORY_PROTOCOL = "pad-lobby-1"' \
  'PRODUCT_PATTERN' \
  'host.product_id != guest.product_id' \
  'def activity(' \
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
for contract in '"roster"' '"open_seats"' '"updated_seconds_ago"' '"joinable"' '"product_id"'; do
  grep -Fq "$contract" "$SERVER"
done

grep -Fq 'moderngekko-netplay-8' "$CLIENT"
grep -Fq 'MeleePadPublicLobbyProductID' "$CLIENT"
grep -Fq '/v1/activity' "$CLIENT"
grep -Fq 'moderngekko-netplay-8' "$ROOT/services/lobby/test_server.py"
grep -Fq 'traversal code only after compatible join' "$DESIGN"
grep -Fq 'TUNNEL_TOKEN' "$CLOUDFLARE_COMPOSE"
grep -Fq 'http://pad-lobby:8765' "$DIGITALOCEAN_RUNBOOK"

python3 -m unittest services.lobby.test_server

echo "public lobby security and API contracts passed"
