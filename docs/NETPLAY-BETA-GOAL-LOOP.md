# MeleePad Online Play with Friends beta loop

Status: active at B1/B2 acceptance; public B3/B4 vertical slice proven (2026-09-03)
Written: 2026-09-02  
Supersedes: `NETPLAY-GOAL-LOOP.md`  
Companion architecture: `NETPLAY-FEASIBILITY.md`

The clean cross-platform rebuild no longer reproduces the old frame-120
failure, and public Dolphin traversal now creates and resolves room codes in
both Mac/iPad Simulator host directions. Resume at complete-match and lifecycle
acceptance without repeating the transport vertical slice. The current work is
still an engineering preview; “Online Play with Friends (Beta)” remains the
claim earned only by B10.

On 2026-09-04, Preview 2 build 5 on a physical iPad progressed from `Creating
lobby` to `Internet room is ready` and received a room code. A VPN was active,
so the delay is not a clean timing result. This closes only physical host
registration, not a peer connection or match. The next gate is a bounded
Private Room community test across independent networks. Public-lobby
deployment is deferred until that gameplay evidence is positive.

The current completion log is insufficient to explain a slow `Creating lobby`
attempt. Before the next build, add privacy-safe breadcrumbs for request start,
traversal phase changes, elapsed time, timeout/cancel, and final outcome. Never
include a room code, player name, token, or full address. The UI must also stop
with a useful retry message instead of spinning forever when traversal cannot
register.

## Goal

Ship a real friends-only Online Play beta inside MeleePad. A person opens the
three-dot menu, creates or joins a private room with a short code, sees who is
connected and whether the builds match, then completes synchronized Melee
matches on Mac, iPhone, and iPad using touch controls or a connected
controller.

The room-code experience is the product. Direct IP is an Advanced fallback,
not the main screen. A lobby that connects but cannot finish a match is an
engineering preview, not a beta.

## Beta definition of done

The beta exists only when one unchanged candidate proves all of the following:

1. **Consumer flow:** Online Play opens to `Host a Game` and `Join a Game`.
   Hosting produces a shareable eight-character room code; joining accepts the
   displayed code without asking for an IP address or port.
2. **Real gameplay:** Mac/iPad, Mac/iPhone, and iPad/iPhone pairs each complete
   a five-minute match through results and a rematch without desync, crash,
   stale input, or hung teardown.
3. **Native input:** touch and physical controllers traverse the existing
   GameCube input mixer. Simultaneous stick plus shield/attack and disconnect
   neutralization are visibly proven.
4. **Internet path:** room codes connect devices on two independent outside
   networks through the MeleePad traversal service. Direct IP remains available
   under Advanced.
5. **Honest NAT behavior:** the tested connection-success rate is at least 90%.
   If traversal misses that floor, a relay or a narrower disclosed beta scope
   is required; failure may not degrade into a spinner or generic error.
6. **Lifecycle:** cancel, host loss, client loss, Wi-Fi loss, backgrounding,
   controller disconnect, match completion, and app relaunch all converge on a
   usable Online home with neutral input and no leaked network/runtime thread.
7. **Compatibility and saves:** exact game, module, protocol, settings, and
   save-sync compatibility is enforced. Ordinary local saves remain
   byte-identical after every client run.
8. **Performance:** each endpoint maintains the row-7 solo floor during the
   match. Same-Mac dual-Simulator contention is diagnostic only; beta evidence
   uses separate devices or hosts.
9. **Privacy and operations:** exported diagnostics contain no full IP, room
   code, save, or game data. The service has health checks, rate limits,
   bounded retention, restart supervision, and a separate development endpoint.
10. **Claim:** only the evidence above permits `Online Play with Friends
    (Beta)`. Earlier builds must say `Direct Connection Preview`.

This is fixed-delay Dolphin-derived netplay. It is not Slippi rollback, ranked
matchmaking, a public lobby, spectating, or anonymous pairing.

## Review of the current build

| Area | Evidence | Truth |
|---|---|---|
| GameCube packet mapping | exact payload regressions | pass |
| Headless session owner | two repeated lifecycle cycles | pass |
| Two-Mac direct match | full match, results, lobby return, unchanged saves | pass |
| Native iPad form | Internet room/direct selection, host/join/code/ready/start/cancel | partial |
| Mac/iPad gameplay | synchronized direct and public-room runs in both host directions | partial |
| iPhone interaction | compile coverage only | missing |
| Room-code client | `NetplaySession` host/join vertical slice works | partial |
| Traversal service | Dolphin public service works in retained test; no MeleePad-operated endpoint | partial |
| Physical iPad hosting | Preview 2 build 5 created a room code; no remote peer joined | partial |
| Relay | no implementation or measured need decision | missing |
| Real internet/device beta | no evidence | missing |

The current iPad form is an engineering preview backed by a real room-code
path, not a fake action. It still lacks the complete home/lobby/failure,
accessibility, physical-device, and lifecycle evidence required for beta.

The current desync diagnostic is also not a canonical state proof. Dolphin
calls `SendTimeBase()` from the CPU-thread Pixel Engine finish event, not the
Video Interface field callback. The added static-recomp fingerprint reads the
live guest state at that host callback. The two peers can reach it on opposite
native dispatch boundaries.
Same-PC/tick tolerance usefully classified sampling skew, but different live
PCs do not by themselves prove that canonical same-frame memory/state differs.
The next gate must capture comparable state at a defined emulated boundary and
must never hide a genuine mismatch.

## Product flow

### Online home

```text
Online Play with Friends

Play private delay-based matches. Nearby players work best.

[ Host a Game ]
[ Join a Game ]

Connection status / service maintenance message
Advanced Direct Connection
```

- No address, port, buffer stepper, or compatibility jargon appears on the
  primary screen.
- Nickname is requested once and may be remembered locally.
- Room codes are never remembered.
- Advanced contains direct host/join address, UDP port, automatic/manual
  buffer, and the plaintext/port-forwarding limitation.

### Host flow

```text
Nickname -> Create Room -> Creating Room

Room ABCD-EF12        [Copy] [Share]
Ready to invite a friend

Player      Touch Controls   GC 1   Compatible   Ready
Friend      Controller       GC 2   Checking...  Not Ready

Automatic delay: 2 frames
[Ready] [Start Match] [Cancel Room]
```

- Display uppercase `XXXX-XXXX`; transmit normalized lowercase eight hex
  characters required by Dolphin's traversal protocol.
- Copy/Share contains only the code and a short MeleePad instruction.
- Start remains disabled until two controller slots exist, every build/game/
  setting fingerprint matches, host save sync succeeds, and all players are
  ready.
- The code disappears after gameplay starts and never enters diagnostic export.

### Join flow

```text
Nickname
Room code  [ABCD-EF12]
[Join Room]
```

- Accept paste, lowercase or uppercase, surrounding whitespace, and an optional
  hyphen. Normalize before network use.
- Invalid format fails locally. Expired room, unavailable service, unreachable
  host, strict NAT, full room, game running, version mismatch, game mismatch,
  module mismatch, save-sync failure, and local-network denial are separate
  user-facing states.
- Retry returns to the populated code field; Cancel returns to Online home.

### Running match

- The normal touch/controller overlay remains the only input UI.
- The three-dot menu shows `Online Match`, peer, ping, delay buffer, connection
  quality, and `Leave Match`.
- Leaving is confirmed, sends a stop reason when possible, neutralizes input,
  tears down runtime/network ownership once, and returns to Online home.
- Version 1 ends the match on background; it does not pretend to resume a peer
  that iOS may suspend.

## State and ownership model

One serialized session owner drives both UIKit and the macOS adapter:

```text
Idle
  -> Preparing
  -> RegisteringRoom | ResolvingRoom | ConnectingDirect
  -> Lobby
  -> Synchronizing
  -> Starting
  -> Running
  -> Stopping
  -> Idle | Failed(reason, retryAction)
```

Rules:

- solo runtime and netplay runtime are mutually exclusive;
- only `Lobby` accepts ready/controller changes;
- only the host requests start;
- synchronized boot data is consumed once;
- every callback observes a session generation and ignores stale generations;
- all stop paths are idempotent;
- snapshots are immutable and contain presentation-ready failure categories;
- UIKit never owns a raw Dolphin server/client/traversal pointer; and
- UIKit never encodes network controller packets.

The platform-neutral snapshot must eventually expose:

```text
state, role, generation
connectionMethod (roomCode | direct)
roomCode (lobby only)
players { nickname, local, inputSource, gcSlot, ping, compatibility, ready }
automaticBuffer, bufferFrames, canStart
serviceState, connectionQuality
failure { category, recoveryAction }
```

## Room-code architecture

Use the pinned Dolphin `TraversalClient` and CC0 `traversal_server`; do not add
a second gameplay transport.

```text
UIKit / macOS adapter
        |
NetplaySession commands + snapshots
        |
Dolphin NetPlayServer / NetPlayClient
        |
TraversalClient ---- MeleePad traversal service UDP 6262/6226
        |
peer-to-peer ENet gameplay
```

The server assigns a random 32-bit host ID formatted as eight hexadecimal
characters. Its source evicts an unrefreshed registration after 30 seconds;
the client already sends keepalive traffic. The room code is an ephemeral
locator, not an account, password, or cryptographic secret.

The first service is deliberately small:

- pinned traversal protocol and build identity;
- development and production hostnames;
- UDP 6262 plus alternate 6226;
- process supervision and restart policy;
- health probe and synthetic create/resolve check;
- packet-rate and source-rate limits;
- aggregate success/error/latency metrics without IPs or codes;
- no account, room list, chat, matchmaking database, or long-lived room log;
- client-visible maintenance state; and
- a documented rollback to Advanced Direct Connection.

No public service, DNS, cloud account, or paid resource may be created without
explicit user authority. Local service builds and loopback/LAN tests are safe.

## Security boundary

The current ENet gameplay channel is plaintext. Compatibility fingerprints
prevent accidental mismatch; they do not authenticate the other person or
encrypt traffic. Until authenticated encryption is implemented, the beta is
limited to private play with trusted friends and must disclose this once under
Advanced/About—not as an alarming modal on every match.

Before a broader public claim:

- fuzz nickname, room code, pad index/count, save chunks, unknown messages, and
  oversized payloads;
- rate-limit room-code enumeration and traversal floods;
- verify no save/game/module bytes enter logs or crash reports;
- decide and document an authenticated-encryption design; and
- complete a focused review of handshake, save transfer, traversal, replay,
  denial-of-service, and downgrade surfaces.

Do not claim end-to-end encryption or secure room codes before those properties
exist and pass tests.

## Goal stack

Work only the lowest unmet beta goal. A UI screenshot, connection, first frame,
or mock service never substitutes for a completed match.

### B0 — Contract and truth reset

Pass when this loop, current evidence table, beta definition, consumer flow,
failure taxonomy, service boundary, security boundary, and claim language are
reviewed into the repository; the direct-address screen is explicitly treated
as Preview rather than beta.

**Current status: PASS with this checkpoint.** The installed direct-address
screen is relabelled `Direct Connection Preview` / `Advanced Direct
Connection`; it exposes no fake room action.

### B1 — Canonical cross-platform determinism

Mac and iPad Simulator must complete two consecutive direct five-minute
matches with independent input, results, rematch, no desync, and matching
canonical frame records. This is the current goal.

First experiment:

1. add a focused failing regression proving the existing live-PC fingerprint
   can report different native dispatch boundaries for the same PE-finish
   counter value;
2. retain live PC/counter fields as diagnostics, but base mismatch decisions on
   exact timebase plus a canonical emulated boundary record whose state is
   synchronized from the static guest independently of PE-finish overshoot;
3. include deterministic CPU state and selected RAM page digests sufficient to
   separate CPU-register, memory, timing, and merely asynchronous sampling;
4. run same-build two-Mac control, then iPad-host/Mac-join and reverse-host on
   isolated user/save/input roots with no Computer Use during gameplay; and
5. reject any comparator that permits a deliberately injected CPU, FPR,
   paired-single, timebase, or RAM mismatch.

No room service or consumer UI work may conceal a B1 failure.

**Current status: PARTIAL.** The corrected two-Mac control reached live
Fountain combat and emitted four exact canonical matches with no mismatch,
unpaired record, desync, or crash. The package gate now rejects stale builds
without the caller-qualified boundary settings. The first current Release
iPad-host/Mac-join run fails closed at frame 120; sequence 6780 differs only in
timebase and sampled MEM1 while all CPU hash families match. Subdivide the RAM
digest and classify the first differing region before reverse-host; the two
consecutive five-minute results/rematch gate is unchanged. See
`docs/artifacts/2026-09-02/g9-canonical-boundary-live-control.md` and
`docs/artifacts/2026-09-02/g9-cross-platform-canonical-classification.md`.

### B2 — Session and lifecycle resilience

Pass host/join/start/match/stop twice in one process plus: cancel while
registering/connecting, host loss, client loss, timeout, Wi-Fi loss, local-
network denial, background from lobby, background from match, app relaunch,
controller disconnect, and touch reclaim. Every path must neutralize input,
stop once, expose an exact recovery action, and leave ordinary saves unchanged.

### B3 — Local room-code vertical slice

Build the pinned traversal server locally. Extend `NetplaySession` with
room-host and room-join options, traversal state, normalized room code, exact
failure categories, and retry. Two isolated clients must create/resolve a code
and complete a match on loopback and LAN. Expired, malformed, unavailable,
wrong-version, full, and game-running cases require focused regressions.

### B4 — Consumer native room UI

Replace the current direct-address-first sheet with the Online home, Host,
Join, Lobby, in-match status, and failure/retry flows specified above. Direct
IP moves under Advanced. Pass iPad and iPhone portrait/landscape constraints,
Dynamic Type, VoiceOver, Switch Control, hardware keyboard, paste, Copy, Share,
and input-neutralization tests. No room button may ship against a fake backend.

### B5 — Complete simulator room match

Using the local traversal service, complete host and join in both directions
between Mac/iPad Simulator and Mac/iPhone Simulator. Prove touch plus physical
controller input, results, rematch, leave, reconnect, exact errors, save hashes,
and per-endpoint performance. Use separate hosts when measuring performance.

### B6 — Operated development traversal service

After explicit infrastructure authority, deploy the pinned service to a
development endpoint with supervision, health checks, metrics, rate limits,
bounded logging, and documented rollback. Run synthetic create/resolve/expire
tests and prove the app handles maintenance/unavailability without hanging.

### B7 — Physical-device real-internet beta

Physical iPhone and iPad complete room-code matches across at least home Wi-Fi,
cellular hotspot, and a second independent network, in both host directions.
Cover touch, controller, background, route change, host/client loss, thermal
soak, audio, and relaunch. Simulator evidence cannot pass B7.

### B8 — NAT matrix and relay decision

Run at least 20 intended friend-pair attempts across the network matrix. Pass
at 90% or better without router configuration. Below that floor, implement a
bounded relay or narrow the beta claim to tested network classes; never call a
known-unreliable universal path complete.

### B9 — Security, privacy, and operational review

Pass protocol fuzzing, abuse/rate-limit tests, diagnostic redaction, save
isolation, dependency/license audit, service failure/rollback drill, and the
documented plaintext limitation. Resolve every release-blocking finding.

### B10 — Beta acceptance and claim

One unchanged candidate must complete ten five-minute room-code matches with
zero desync, crash, hung teardown, save mutation, or stale input; at least 20
connection attempts meet the B8 threshold; the physical-device matrix and
repository/package checks pass; and setup/support/privacy documentation matches
the observed product. Only then publish the beta claim.

## Acceptance matrix

| Row | Requirement | Minimum evidence |
|---:|---|---|
| 1 | Create room | code appears, copies, shares, expires |
| 2 | Join room | paste/normalize/connect succeeds |
| 3 | Compatibility | exact match and every mismatch family |
| 4 | Ready/start | two slots, all ready, host-only start |
| 5 | Touch payload | buttons, sticks, triggers, combinations |
| 6 | Controller handoff | connect/disconnect/neutral/touch reclaim |
| 7 | Full match | five minutes, results, rematch, no desync |
| 8 | Performance/audio | each endpoint meets target; no sustained underrun |
| 9 | Save isolation | ordinary save hashes and mtimes unchanged |
| 10 | Cancel/retry | every pre-match state exits and retries |
| 11 | Peer/network loss | exact error, bounded teardown, usable home |
| 12 | Background/foreground | match ends safely, no stale runtime/input |
| 13 | iPhone/iPad layout | native accessibility and keyboard paths |
| 14 | Internet/NAT | outside networks and success-rate threshold |
| 15 | Privacy/security | redaction, fuzzing, rate limits, disclosure |
| 16 | Packaging/docs | ROM-safe, licensed, reproducible, honest claim |

Every row is pessimistic: the lowest synchronized visual/runtime/network result
controls. A successful lobby does not average away a failed match.

## Operating loop

Repeat until B10 passes:

1. **Orient:** read this file, current status, newest beta artifact, and relevant
   source. State the lowest unmet goal.
2. **Audit:** verify HEAD, dependency pins, processes, endpoint isolation, and
   ROM/save boundaries.
3. **Predict:** name one mechanism, smallest falsifiable change, expected
   result, rejection threshold, and rollback.
4. **Fail first:** add the narrowest regression that fails for the intended
   reason. UI source checks alone cannot pass runtime goals.
5. **Change one boundary:** use durable outer patches for ignored dependencies.
6. **Reverse:** run control/candidate/control for determinism, timing, save,
   lifecycle, and network changes.
7. **Prove the pair:** one endpoint, one screenshot, or first frame is partial.
8. **Retain evidence:** store sanitized commands, revisions, endpoint roles,
   full result, failure classification, hashes, and next experiment. Keep ROM,
   module, saves, IPs, codes, signing material, and raw private logs out of Git.
9. **Update truth:** update this current goal, `STATUS.md`, `JOURNAL.md`,
   `TECH-DEBT.md`, and the dated artifact. Record rejected ideas.
10. **Publish:** run the repository suite, commit only scoped work, push main,
    and verify local/origin/GitHub identities.
11. **Continue:** select the next smallest experiment. Stop only for explicit
    infrastructure authority, physical hardware/user action, or a demonstrated
    external blocker.

## Isolation and claim rules

- Use distinct user/config/save/input/log roots for every endpoint.
- Never replace the canonical solo app or ordinary save with a diagnostic
  fixture.
- Run one process except during an intentional paired test.
- Do not use Computer Use polling during measured gameplay; it measurably
  perturbs Simulator cadence.
- Never bypass compatibility, desync, save, or controller checks to make a demo
  continue.
- Never commit ROMs, extracted game data, generated modules, saves, room codes,
  IP addresses, credentials, device identifiers, or service secrets.
- Before B1: `native Direct Connection Preview; cross-platform matches fail`.
- After B5: `room-code simulator preview works in retained tests`.
- After B7: `private physical-device beta candidate`.
- Only after B10: `Online Play with Friends (Beta)`.

## Current next action

Continue B1 with the compiling canonical-boundary candidate. Repair the
deterministic two-human character/stage route and retain the first same-Mac
combat canonical match or mismatch; opening/title/menu screenshots cannot pass
this gate because the configured idle boundary is not active there. If the
control is interpretable, run the unchanged iPad-host/Mac-join pair and reverse
host. Prove whether exact same-boundary architectural state and selected RAM
diverge before changing timing or weakening the two-consecutive mismatch stop.
