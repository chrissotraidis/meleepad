# G9 public Internet room vertical-slice pass

Date: 2026-09-03
Scope: unreleased Mac + iPad Simulator engineering candidate
Result: Internet room-code play is possible; beta/release acceptance remains open

## Research result

The premise that no usable servers exist is false in the narrow transport
sense. Dolphin mainline still defaults to `stun.dolphin-emu.org` on UDP 6262
with alternate UDP 6226, and its public lobby endpoint returned active sessions
during this run, including a GALE01 revision-2 room. Dolphin's traversal server
issued and resolved fresh eight-character host codes for every retained
MeleePad test.

This does not make Slippi a drop-in service. Slippi provides active rollback
matchmaking for its customized Dolphin client, while its matchmaking service
source and protocol are not a public compatibility surface for MeleePad.

Sources:

- https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/Config/NetplaySettings.cpp
- https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/NetPlayServer.cpp
- https://slippi.gg/netplay
- https://github.com/project-slippi/slippi-wiki/blob/master/GETTING_STARTED.md

## Change

- Add traversal-backed room hosting and joining to the platform-neutral
  `NetplaySession`, using Dolphin's published default host and ports.
- Keep the host's local client direct while the server owns the traversal
  socket, matching Dolphin's upstream ownership model.
- Surface the ephemeral room code in the session snapshot and Mac lobby.
- Add `--netplay-room-host` and `--netplay-room-join` runner paths.
- Make Internet Room the iOS setup default, retain Direct IP as the adjacent
  advanced fallback, show the host code in the lobby, and validate join codes.
- State the security boundary in-product: a room code is a locator, not a
  password or end-to-end encryption.
- Add Simulator-only automation for reproducible host/join/ready/start testing;
  room-code logging remains disabled unless the private trace variable is set.

The durable dependency change is
`patches/moderngekko/0020-netplay-internet-rooms.patch` and is wired into the
dependency bootstrap.

## Retained runs

No IP address or room code is retained in this artifact.

1. Clean iPad-host/Mac-join direct connection sustained 4,769 iPad-rendered
   frames at 59.9 FPS with no canonical mismatch or disconnect.
2. Clean Mac-host/iPad-join direct connection sustained 3,588 iPad-rendered
   frames at 59.9 FPS with no canonical mismatch or disconnect.
3. Public-service Mac-host/iPad-join resolved a fresh code, launched both
   synchronized runtimes, armed the canonical boundary on both peers, and
   sustained 4,768 iPad-rendered frames. The last sample was 59.7 FPS/VPS and
   1.009 speed with no mismatch or disconnect.
4. Public-service iPad-host/Mac-join resolved a second fresh code, launched both
   synchronized runtimes, and sustained 4,707 iPad-rendered frames. The last
   sample was 59.1 FPS/VPS and 1.011 speed with no mismatch or disconnect.

The earlier frame-120 `timebase,ram` failure did not reproduce after completely
rebuilding the iOS core/module and Mac package from the current checkout. No
timebase tolerance, RAM exclusion, timing adjustment, or gameplay semantic
change was used. The prior failure is therefore classified as stale build
contamination, not evidence that cross-platform deterministic play is broken.
The new regional RAM and signed-timebase diagnostics remain in place so a real
future mismatch fails closed with useful location data.

## Verification

- ModernGekko netplay protocol and session tests: pass.
- Internet-room and native-lobby source contracts: pass.
- New dependency patch reverse-check and patch parse: pass.
- Rebuilt Simulator core/module/provisioned libraries: pass.
- Release iPad Simulator link: pass.
- Visual setup review: pass; Internet Room is primary, Direct IP remains
  available, host fields fit without clipping, and the navigation title is
  legible on the dark form sheet.

## Claim boundary and next loop

It is now accurate to say: **MeleePad-to-MeleePad Internet room play works in
the retained public-traversal Simulator/Mac test.** It is not yet accurate to
say the friends beta is ready. These remain open:

- complete five-minute match, results, rematch, and clean leave/reconnect;
- physical iPhone/iPad testing;
- two genuinely independent outside networks and a NAT success matrix;
- malformed/expired/full/game-running and service-outage recovery;
- background, Wi-Fi-loss, host-loss, and controller-disconnect cleanup;
- diagnostics redaction, security review, and release/package validation;
- a support/availability decision for relying on Dolphin's public service or
  operating a separately authorized MeleePad endpoint.

Continue the goal loop at B1/B2 acceptance while treating B3/B4 as a proven
vertical slice, not as a beta claim. Do not deploy infrastructure or publish a
release without separate authority.
