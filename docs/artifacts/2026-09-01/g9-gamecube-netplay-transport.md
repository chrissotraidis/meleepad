# G9 GameCube netplay transport

Date: 2026-09-01

Goal: NL0 and NL1

## Question

Does MeleePad's existing fixed-delay stack assign Melee clients to GameCube
slots and relay the complete GameCube controller payload, without regressing
the customized Wii transport?

## Pinned sources

- ModernGekko: `048c426ba3db0369e40826d22ad3adcce7fe7c58`
- Dolphin: `e13ab348f13cd67879f6db6e9d7185410f8f62c6`
- DolRecomp: `93b881c8f73df1d64a88491f2aa50c7c9ed2384d`

## Control and failing regression

The existing `moderngekko_netplay_protocol_test` passed before modification.
It assigned three, one, and one controller slots through the Wii map and
relayed the existing three-byte `WiimoteData` payload.

A GameCube-map assertion was then added immediately after the first client was
assigned three controllers. The rebuilt test exited `19`: the advertised
controller count was three while the server GameCube map contained zero slots
for that client. This reproduced the source diagnosis without launching or
changing the installed app.

## Change

- Add an explicit `ControllerFamily` to the Dolphin-derived server. GameCube is
  the default; the legacy test opts into Wii Remote explicitly.
- Route capacity, connection assignment, controller-count changes, and the
  start gate through the selected family map.
- Add a locked GameCube mapping snapshot for lobby/session consumers.
- Make the MeleePad desktop session explicitly select GameCube and label slots
  `GC 1` through `GC 4`.
- Store the dependency changes as ordered outer patches `0039` and `0013`, and
  teach bootstrap to apply and recognize them.

## Candidate result

The focused test passes and covers:

- the unchanged Wii assignment, capacity update, adaptive buffer, and exact
  `WiimoteData` path;
- two GameCube clients receiving three and one slots;
- exact `PadData` relay for buttons, analog A/B, main stick, C-stick, analog
  left/right triggers, and connection state;
- GameCube controller-count reduction on both server and client snapshots;
- disconnect cleanup; and
- a new client reconnecting and receiving two freed GameCube slots.

The desktop `MeleePadRunner` target also rebuilds successfully with the corrected
GameCube lobby snapshot and labels. Both outer patches pass reverse-apply
checks against the live nested worktrees, bootstrap passes shell syntax, and
the outer checkout passes `git diff --check`.

## Decision

NL0 and NL1 pass at focused protocol/build evidence. This does not prove a
Melee match, a reusable headless session, internet traversal, or mobile Online
Play. The next goal is NL2: extract a platform-neutral session owner and prove
host/join/ready/start/stop/destroy twice without an SDL/ImGui window.

The installed app, canonical G8 package, ordinary save, ROM, module, and
Simulator state were not touched.
