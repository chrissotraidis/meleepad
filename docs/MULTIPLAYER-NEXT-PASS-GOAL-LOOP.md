# MeleePad multiplayer next-pass goal loop

Status: active
Started: 2026-09-04
Companion plans: `NETPLAY-BETA-GOAL-LOOP.md`,
`PUBLIC-LOBBY-GOAL-LOOP.md`, and `MULTIPLAYER-EXPERIENCE-GOAL-LOOP.md`

## Goal

Turn the current Online Play development slice into a stable, understandable
four-seat foundation without presenting it as a public beta. A player should be
able to see open games, create a two-, three-, or four-player room, understand
every seat and compatibility state, recover from service failure, and use
report/block controls whose server-side context is verified.

This pass deliberately preserves the existing fixed-delay gameplay transport,
Private Room, and Direct IP paths. It does not deploy a public service, add
accounts, invent cryptography, or claim four-device gameplay before that evidence
exists.

## Definition of done for this pass

One unchanged candidate must prove all of the following:

1. **Four-seat contract:** public rooms accept a capacity of 2–4, reserve slots
   atomically, report accurate occupancy, and reject the next join when full.
2. **Safer reports:** a report target must belong to the referenced room, self-
   reports are rejected, duplicate reports are idempotent, and report creation is
   rate-limited separately from ordinary lobby traffic.
3. **First-class setup:** Online Play uses the available screen, presents Public
   Games as the primary path, offers room-size selection, and keeps Private Room
   and Direct IP intact.
4. **Readable lobby:** the lobby presents a fixed seat for every room position,
   with player, controller, connection, compatibility, and ready state available
   without dense protocol/build jargon.
5. **Recovery:** an unavailable public service provides Retry and a direct path
   to Private Room; hosting and joining cannot remain stuck after a failed request.
6. **Accessibility:** primary text follows Dynamic Type, controls retain at least
   44-point hit regions, seat/status changes have useful accessibility labels,
   and the screen remains scrollable at larger text sizes.
7. **Regression safety:** lobby unit tests, native source contracts, the complete
   repository check, and a fresh iPad Simulator build pass. Current-build setup,
   public-list, safety-menu, and lobby screenshots are retained.

Passing these gates earns only **four-seat development foundation**. It does not
earn “four-player online,” “secure public matchmaking,” or “public beta.”

## Iteration loop

For each gate:

1. write or tighten the smallest failing contract;
2. make the narrowest implementation change;
3. run the focused test immediately;
4. exercise the affected UI state in a fresh build;
5. inspect failure, cancellation, and stale-state behavior;
6. run the complete repository check; and
7. record the evidence and advance only if the unchanged candidate passes.

If a change destabilizes Private Room, Direct IP, game startup, or input
ownership, revert that change and reduce the slice instead of widening it.

## Gates

### NP0 — freeze the current truth

- Keep Public Games disabled when no supported endpoint is configured.
- Keep the public-list response free of traversal codes and IP addresses.
- Preserve the current compatibility fingerprint and bounded room chat.
- Treat retained two-endpoint runs as the gameplay ceiling until new evidence
  is captured.

### NP1 — four-seat lobby model

- Add an explicit `capacity` field constrained to integer values 2–4.
- Enforce capacity under the room-store lock and test simultaneous final-slot
  joins.
- Keep one local controller per device for this pass.
- End the room cleanly when the host leaves; host migration is not required.

### NP2 — safety hardening

- Verify that report target and room correspond on the server.
- Reject self-reporting and unrelated room/target pairs.
- Deduplicate identical reports and apply a report-specific limiter.
- Continue blocking the reported player locally after acceptance.
- Retain no gameplay, room code, token, save, or game data in reports.

### NP3 — Online Play presentation

- Replace the compact form sheet with a full-screen adaptive layout.
- Make room size, occupancy, compatibility, and Join immediately scannable.
- Show fixed numbered seats in the lobby, including empty seats.
- Move protocol/build detail out of the primary card presentation.
- Keep manual buffering and Direct IP available but visually secondary.

### NP4 — focused acceptance

- Prove 2-, 3-, and 4-seat API capacity and full-room behavior.
- Capture empty, unavailable, compatible, incompatible, moderation, and lobby
  states from the current build.
- Test large text, VoiceOver reading order, keyboard/controller focus, and
  portrait/landscape layouts.

### NP5 — production security gate

This is the next project after the UI/four-seat foundation, not an implicit part
of this local pass:

- choose a service owner, domain, region, retention policy, privacy contact, and
  abuse-response owner;
- deploy behind HTTPS, edge limits, durable storage, metrics, alerts, backups,
  restart supervision, and tested rollback;
- use revocable identities and short-lived room membership tickets;
- complete a protocol review for authentication, replay, downgrade, malformed
  packets, save transfer, and denial of service; and
- select an audited authenticated-encryption and relay design before strangers
  are invited to play.

### NP6 — four-device evidence

- Run host plus three guests on four physical devices and independent networks.
- Complete match, results, rematch, and clean exit with four live controllers.
- Exercise host loss, guest loss, Wi-Fi loss, backgrounding, strict NAT, and
  controller disconnect.
- Measure latency, host upload, thermals, frame pacing, NAT success, and relay
  need without retaining sensitive addresses or room codes.

Only NP5 and NP6 together can support a later secure public four-player claim.

## Current execution order

1. NP1 capacity contracts and API.
2. NP2 report-context hardening.
3. NP3 full-screen setup, room cards, recovery, and four-seat lobby.
4. NP4 focused tests, fresh build, visual/accessibility inspection.
5. Stop and report remaining NP5/NP6 gates; do not silently deploy services.

## Progress — 2026-09-04

| Gate | Status | Evidence / remaining boundary |
|---|---|---|
| NP0 | Pass | Existing compatibility, hidden-code, bounded-message, and disabled-without-endpoint behavior remain covered. |
| NP1 | Development pass | Capacity 2–4, invalid-capacity rejection, full-room behavior, and simultaneous final-slot reservations pass service tests. Four-device gameplay remains unproven. |
| NP2 | Development pass | Report context, self-report rejection, deduplication, and report-specific limiting are implemented and tested. Persistence and operator handling remain NP5 work. |
| NP3 | Development pass | Full-screen setup, four-seat occupancy, numbered lobby seats, service fallback, security copy, and collapsed advanced settings are visible in the fresh Simulator build. |
| NP4 | Partial | Current-build Public Games, three-seat host lobby, unavailable-service fallback, and Accessibility Extra Large layouts were inspected. VoiceOver, controller focus, rotation, and physical devices remain open. |
| NP5 | Open | No service, domain, account, encryption, or relay has been deployed or selected. |
| NP6 | Open | No new physical-device or four-endpoint gameplay claim was made. |
