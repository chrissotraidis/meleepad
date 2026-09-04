# Pad Lobby Protocol goal loop

## Goal

Build a small, open protocol that can help compatible players find each other
across MeleePad, KartPad, and future online Pad projects. MeleePad is the first
proof. The directory coordinates discovery, room membership, chat, and abuse
reports. Each game keeps its own gameplay transport.

The first proof is complete when two MeleePad clients can keep one public room
alive from setup through gameplay and back to the room, while MeleePad can show
anonymous aggregate activity from another supported Pad game.

## Current proof status

| Gate | Status | Evidence still required |
|---|---|---|
| PL0 boundary | Implemented and unit-tested with bounded server resources | Edge and Internet deployment review |
| PL1 product identity | Implemented and unit-tested | None for reference slice |
| PL2 shared activity | Implemented and simulator-built | Visual two-product acceptance |
| PL3 gameplay lifetime | Implemented and simulator-built | Two-device session lasting over 45 seconds |
| PL4 connected screen | Partial: return, leave, roster, chat, and host RTT are wired | In-game device acceptance and connection-loss UX |
| PL5 self-hosting | Hardened reference files, Zo/VPS guide, and compose validation pass | Fresh-host edge/tunnel canary |
| PL6 KartPad adapter | Not started | KartPad client implementation and cross-app proof |
| PL7 release | Not started | Exact-build physical and artifact matrix |

## Product rules

- A room belongs to exactly one `product_id`. MeleePad never lists a KartPad
  room as joinable.
- Cross-game activity is counts only: product, open rooms, games in progress,
  and players. It never includes names, chat, room IDs, connection codes, or IP
  addresses.
- The directory never relays or inspects gameplay.
- Gameplay compatibility remains exact and game-specific. MeleePad currently
  uses ModernGekko netplay. KartPad currently uses its own Retro WFC path.
- Latency is shown only after players connect, as round-trip time to the host.
  The public directory must not invent a pre-join ping.

## Goal-based loop

Run the loop in order. Stop and repair a failed gate before adding another
feature.

### PL0 — Protect the boundary

**Build:** Document directory data versus gameplay data and retain the existing
short-lived sessions, hidden connection codes, bounded inputs, expiry, blocking,
reporting, and rate limits.

**Prove:** A room list and cross-game activity response contain no connection
code, bearer token, IP address, or chat text.

### PL1 — Make the protocol product-aware

**Build:** Add a stable `product_id`, capabilities endpoint, and supported
product registry. Keep gameplay protocol, game ID, revision, app version, and
build as separate compatibility fields.

**Prove:** Unsupported products fail closed. Two supported products can use one
service without seeing each other's rooms.

### PL2 — Show useful cross-game activity

**Build:** Add an authenticated aggregate activity endpoint and a compact
MeleePad UI section that appears only when another Pad game has activity.

**Prove:** A synthetic KartPad room appears in MeleePad only as aggregate
counts. It cannot be joined from MeleePad.

### PL3 — Keep the public room alive during Melee

**Build:** Move public-lobby ownership above the setup screen. Send a bounded
heartbeat while gameplay is running, retain the same room membership, and
return its state to waiting if the synchronized runtime ends normally.

**Prove:** The public room remains `in_game` for longer than the 45-second room
expiry, then becomes `waiting` when the players return to the room.

Normal Melee flow does not require a new lobby after every match: while the
synchronized game keeps running, players naturally move through results and
back to character select together. The directory room stays `in_game`. If the
runtime itself exits, MeleePad reopens the room so players can chat, ready up,
and start again. Leaving Online Play closes or leaves the directory room.

### PL4 — Make connected state honest and useful

**Build:** Label measured latency as “ms to host.” From the in-game three-dot
menu, show the current players, connection health, room chat, and an explicit
Leave Session action without presenting setup controls as if the game were not
running.

**Prove:** Host and guest see the same roster. Returning to the game does not
disconnect. Leaving ends both gameplay and directory presence.

### PL5 — Make self-hosting reproducible

**Build:** Keep the dependency-free reference service, protocol document,
container recipe, and safe local compose defaults in the public repository.

**Prove:** A fresh checkout passes the service tests and can start a loopback
service. Public operators are told that HTTPS, persistence, monitoring, backups,
and an abuse-response process are required before Internet exposure.

### PL6 — Add KartPad as the second adapter

**Build:** Teach KartPad to create a `kartpad` directory session and publish its
own compatible rooms without changing its gameplay transport. Add an app link
only after both apps have a stable, safe destination for it.

**Prove:** MeleePad shows KartPad activity and KartPad shows MeleePad activity,
but each app can only browse and join rooms for itself.

### PL7 — Acceptance and release

**Build:** Run service tests, repository checks, simulator builds, and a
two-device MeleePad session. Audit release artifacts for game data, credentials,
tokens, local paths, and signing material before publication.

**Prove:** Host, join, chat, four-seat capacity, gameplay heartbeat, rematch
flow, return-to-room, leave, expiry, report, and block behavior all pass on the
exact build being distributed.

## Deliberate non-goals for this pass

- no shared gameplay protocol across different games;
- no public production service operated by the project;
- no accounts, friends, rankings, matchmaking, federation, relay, or host
  migration;
- no cross-game names, chat, room details, or presence history;
- no database or cluster until real usage justifies it.

These are not missing abstractions. They are explicit limits that keep the
first proof understandable, testable, and safer to self-host.
