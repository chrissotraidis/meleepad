# Public lobby development vertical slice

Date: 2026-09-03
Result: pass for local service discovery and authorized traversal join
Release result: not deployed; no public-lobby release claim

## Change

- Add a small standard-library lobby service for room discovery, exact
  version/build/protocol/game compatibility, authenticated join, expiry,
  preset quick chat, hide, report, and health checks.
- Add an ephemeral native client that accepts HTTPS in products and permits
  plaintext loopback only in Simulator development.
- Replace the two-way Internet Room/Direct IP selector with Public Games,
  Private Room, and Direct IP while preserving both existing connection paths.
- Add version-aware room cards, explicit compatibility badges, Host/Join,
  bounded quick chat, and a Safety menu.

## Retained proof

- Ten service tests pass, including secret room-code handling, room expiry,
  full-room/non-member refusal, incompatibility refusal, host-only actions,
  free-text rejection, quick-chat
  rate limiting, authentication/input rejection, and report-to-hide behavior.
- The iPad Simulator build succeeds and the public-room browser renders one
  compatible room without clipping or hierarchy regressions.
- The iPad Simulator discovered a room backed by a fresh Dolphin traversal
  host, authorized Join, and reached the native two-player lobby. The host and
  guest showed matching compatibility and a measured 54 ms guest ping.
- A live UI check found and fixed the initial guest reservation expiring under
  an active traversal session. Authenticated guest heartbeats now extend
  presence; after the original 20-second window, preset quick chat delivered
  and rendered in the connected lobby.
- The direction was then reversed: the iPad Simulator used **Host Public
  Game**, an authenticated compatible client discovered the listing without a
  code, and a Mac joined the disclosed traversal code. The native host showed
  both compatible players at 59 ms. Cancel removed the room immediately; a
  fresh listing returned zero rooms.
- No ephemeral room code, bearer token, IP address, game data, or save data is
  retained in this artifact.

## Boundary

The service runs locally and in memory. It is not a production deployment and
does not yet provide durable moderation, a published abuse contact, monitoring,
backups, or a public availability commitment. Physical-device and independent-
network acceptance also remain open.

See `docs/PUBLIC-LOBBY-DESIGN.md` and
`docs/PUBLIC-LOBBY-GOAL-LOOP.md` for the design and remaining release gates.
