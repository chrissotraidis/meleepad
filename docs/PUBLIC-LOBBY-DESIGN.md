# MeleePad public lobby design

Status: implemented development vertical slice; not deployed
Date: 2026-09-03

## Product outcome

Players should be able to open Online Play, see real MeleePad rooms, understand
compatibility before tapping Join, exchange enough coordination to start a
match, and enter the existing traversal-backed netplay session without sharing
an IP address or finding a code on another service.

The first public lobby is intentionally small:

```text
Online Play

Public Games   Private Room   Direct IP

Open games                                      Refresh
┌─────────────────────────────────────────────────────┐
│ Player's game                           Joinable    │
│ Asia · 4-player game · Live                         │
│ Players: Player (Host) · FoxMain · 2 open           │
│ ● ● ○ ○  2 of 4 seats filled                       │
│ Same build · Ready to join            Safety  Join  │
└─────────────────────────────────────────────────────┘

Host a public game
Room size                                      2 3 4
Development feature · Gameplay is currently unencrypted
Create Public Game
```

After joining, the normal player/ready/start lobby remains authoritative. A
visible Room Chat section provides a 160-character text field, a bounded
message feed, and Hide Player and Report Chat Message actions for remote
senders.

## Architecture

```text
iPhone / iPad / Mac
        │ HTTPS JSON: discover, authorize join, relay room chat
        ▼
MeleePad lobby service
        │ returns traversal code only after compatible join
        ▼
Dolphin public traversal rendezvous
        │ introduces peers; does not relay gameplay
        ▼
MeleePad host ◀──── encrypted? no; fixed-delay ENet ────▶ MeleePad guest
```

The discovery service never receives ROMs, extracted files, modules, saves,
controller input, or gameplay packets. It stores ephemeral lobby metadata only.
The existing netplay handshake remains the final compatibility authority.

## Compatibility and room cards

Every anonymous two-hour lobby session declares:

- MeleePad marketing version and build;
- ModernGekko netplay protocol;
- game ID and game revision.

Room-list responses contain those values, an explicit compatibility/joinability
result, heartbeat freshness, open-seat count, and a bounded four-person roster.
The primary card shows the exact host build and specific mismatch or unavailable
reason. An incompatible, full, or in-progress room remains visible so the player
understands why Join is disabled, but the service refuses code disclosure.
The gameplay handshake still verifies the stronger game/module/settings
fingerprint after peers connect.

## Security and privacy decisions

- No accounts in this slice. The service issues cryptographically random,
  short-lived bearer tokens and stores only their SHA-256 hashes.
- Public listings never contain traversal codes or IP addresses. Join returns
  a code only to a compatible authenticated session.
- Hosts and joined guests heartbeat every 15 seconds; stale rooms expire after
  45 seconds. Initial Join reservations expire after 20 seconds unless the
  connected guest renews presence.
- Hosts select a capacity of two, three, or four seats. Capacity validation and
  final-slot reservation run under the room-store lock.
- Request bodies are JSON allow-lists capped at 8 KiB. Rooms, reports, message
  history, request rate, and chat rate are bounded.
- Room chat accepts text up to 160 characters. Every send rechecks room
  membership, rejects control characters and blocked content, caps history at
  50 entries, and applies a four-message-per-ten-second limit. Display names
  remain restricted and filtered server-side.
- Chat is relayed by the lobby service rather than the peer-to-peer gameplay
  channel. It is not end-to-end encrypted. Messages live only in the room's
  bounded in-memory record and disappear when the room expires or closes.
- Room menus provide Hide and per-player Report. Reports also hide the player
  immediately; blocked roster names are omitted on later listings. The service
  verifies room/target context, deduplicates identical reports, and applies a
  separate report-submission limit.
- Application diagnostics exclude IPs, tokens, room codes, and message bodies.
- Production requires HTTPS, edge connection/rate limits, durable report
  storage, health monitoring, restart supervision, and a published abuse
  contact. The local server deliberately does not pretend those exist.

Apple's current App Review Guideline 1.2 requires filtering, reporting,
blocking, published contact information, and a real response process for
user-generated content, and explicitly covers random or anonymous chat. OWASP
additionally recommends authenticated per-message authorization, strict
validation, message-size and rate limits, idle expiry, and secret-safe logging.
The development UI now exercises bounded text chat, but it must not ship as a
public service before the remaining moderation operations exist.

References:

- https://developer.apple.com/app-store/review/guidelines/#user-generated-content
- https://developer.apple.com/news/?id=d75yllv4
- https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html
- https://github.com/dolphin-emu/netplay-index
- https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/UICommon/NetPlayIndex.cpp

## Acceptance boundary

The development slice is complete when service tests pass, the native public
lobby can create/list/join a room against the local service, Room Chat and
report/hide work, the traversal code stays absent from list responses, and
Simulator screenshots verify the visible hierarchy.

Production remains blocked on deployment authority, persistent moderation,
operational controls, independent-network/physical-device testing, NAT success
measurement, and the broader netplay beta gates.
