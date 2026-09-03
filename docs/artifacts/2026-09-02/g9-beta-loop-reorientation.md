# G9 Online Play beta-loop reorientation

Date: 2026-09-02  
Decision: **direct-address engineering preview is not a fleshed-out beta**

## Review finding

The current native iPad screen is real and connected to the headless Dolphin
session, but it is organized around Host/Join plus address and port fields. Its
copy says room codes arrive later. That is useful for integration testing and
wrong as the primary product experience.

The original NL sequence also delayed room-code traversal until after the
native direct-IP form and cross-platform proof. This made sense for bringing up
the transport, but it left the beta definition underspecified: no complete
Online home, host/create/share flow, join normalization, lobby information
hierarchy, in-match online status, error recovery, operational service gate,
NAT success threshold, or beta claim matrix controlled the work.

The underlying implementation is farther along than the UI suggests:

- exact GameCube payload and controller ownership tests pass;
- one platform-neutral session owner passes repeated lifecycle tests;
- two isolated Mac endpoints complete a full synchronized match and preserve
  ordinary saves; and
- native iPad host/join/ready/start/cancel uses the real session.

But Mac/iPad still stops around frames 6,180/6,240, iPhone is compile-only, and
there is no MeleePad-operated traversal service or room-code client path. This
cannot be described as a working mobile beta.

## Diagnostic correction

The latest execution fingerprint samples static-recomp guest state when
`SendTimeBase()` runs from the CPU-thread Pixel Engine finish event. That is a
better diagnostic than timebase alone, but it is not the Video Interface field
callback and remains a live native-dispatch-boundary read. The peers can report
the same PE-finish counter on opposite sides of generated-code dispatch. The
same-PC/tick bound classified early skew, but a different live PC is not yet
proof that canonical same-boundary CPU/RAM state diverged.

The next correctness experiment must synchronize static guest state at a
canonical emulated boundary and compare deterministic CPU plus selected RAM
digests. It must
also reject deliberately injected CPU, FPR, paired-single, timing, and RAM
mismatches. Do not weaken Dolphin's stop rule to make the pair run longer.

## New loop

`docs/NETPLAY-BETA-GOAL-LOOP.md` is now the active product loop. It defines:

- the exact beta promise and non-goals;
- the primary Host a Game / Join a Game room-code flow;
- Advanced Direct Connection as a fallback;
- host, join, lobby, running-match, failure, and lifecycle states;
- one serialized ownership/snapshot model;
- the pinned Dolphin traversal client/server boundary;
- service health, rate-limit, privacy, logging, and authority requirements;
- plaintext and strict-NAT limitations;
- B0-B10 proof gates and a sixteen-row beta matrix; and
- evidence, isolation, claim, publication, and rollback rules.

B0 passes with this truth reset. B1—canonical Mac/mobile determinism—is the
lowest unmet beta gate. Room-code service and UI work cannot conceal or bypass
a match that still diverges, but their complete product contract is now fixed
before implementation.

The current native sheet is also corrected at the product boundary: its title
is `Direct Connection Preview`, its primary heading is `Advanced Direct
Connection`, and it states that room-code Online Play is unavailable in this
build. A focused regression rejects the old deferred-goal placeholder. No fake
Host-a-Game or Join-a-Game room button is added before the traversal path works.

The Release iPad Simulator target builds successfully and the built executable
SHA-256 is
`935e30ec3577719c1c2f9fc404c287b593dab3959de736a134c6ee58de8466dc`.
The exact app was installed and visibly verified on the sole booted iPad Pro
13-inch (M5) Simulator. Its accessibility tree exposes the new title, heading,
truth copy, Host/Join control, nickname, port, buffer, and Host Lobby. The
private visual proof SHA-256 is
`407b49b0b891808b4cb93efda3bef31f896ac81958e16f3bce9eaac2f79961aa`;
the screenshot stays outside Git because it contains a live game frame.

The user has explicitly reprioritized the isolated netplay lane while the G8
human Fountain gate awaits manual input. No stable-60, physical-device, service,
or beta claim follows from this document.
