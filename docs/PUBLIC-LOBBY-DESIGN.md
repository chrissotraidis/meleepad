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
│ Player · Asia                         Compatible    │
│ Waiting · 1/2 · MeleePad 0.1.0 (4) · GALE01 r0    │
│                                              Join   │
└─────────────────────────────────────────────────────┘

Host Public Game
```

After joining, the normal player/ready/start lobby remains authoritative.
Coordination uses six preset quick-chat messages: Hello, Ready, One moment,
Good luck, Good games, and Rematch. There is no public free-text field.

## Architecture

```text
iPhone / iPad / Mac
        │ HTTPS JSON: discover, authorize join, quick chat
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

Room listings show those values and an explicit compatibility result. An
incompatible room remains visible so the player understands why the lobby may
look sparse, but Join is disabled and the service refuses code disclosure.
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
- Request bodies are JSON allow-lists capped at 8 KiB. Rooms, reports, message
  history, request rate, and quick-chat rate are bounded.
- Messaging is preset quick-chat, not arbitrary anonymous chat. Display names
  are restricted and filtered server-side.
- Room menus provide Hide and Report. Reports also hide the player immediately.
- Application diagnostics exclude IPs, tokens, room codes, and message bodies.
- Production requires HTTPS, edge connection/rate limits, durable report
  storage, health monitoring, restart supervision, and a published abuse
  contact. The local server deliberately does not pretend those exist.

Apple's current App Review Guideline 1.2 requires filtering, reporting,
blocking, and published contact information for user-generated content, and
explicitly covers random or anonymous chat. OWASP additionally recommends
authenticated per-message authorization, strict validation, message-size and
rate limits, idle expiry, and secret-safe logging. Preset quick-chat reduces
the initial moderation surface without blocking basic match coordination.

References:

- https://developer.apple.com/app-store/review/guidelines/#user-generated-content
- https://developer.apple.com/news/?id=d75yllv4
- https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html
- https://github.com/dolphin-emu/netplay-index
- https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/UICommon/NetPlayIndex.cpp

## Acceptance boundary

The development slice is complete when service tests pass, the native public
lobby can create/list/join a room against the local service, quick-chat and
report/hide work, the traversal code stays absent from list responses, and a
Simulator screenshot verifies the visible hierarchy.

Production remains blocked on deployment authority, persistent moderation,
operational controls, independent-network/physical-device testing, NAT success
measurement, and the broader netplay beta gates.
