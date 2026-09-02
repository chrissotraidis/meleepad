# SsbmPad Online Play goal-based loop

Status: active

Started: 2026-09-01

Companion design: `docs/NETPLAY-FEASIBILITY.md`

## Objective

Ship native **Online Play with Friends** for SsbmPad. A player opens the
three-dot menu, hosts or joins with a short room code, and completes synchronized
Melee matches between Mac, iPhone, and iPad using the existing touch controls or
a connected controller.

The first release uses Dolphin-derived fixed-delay netplay. It is not Slippi
rollback, ranked matchmaking, or a public lobby.

## Goal stack

Work only the lowest unmet goal. A build, connection, first frame, or automated
smoke does not satisfy a gameplay goal. Every pass requires retained evidence.

- **NL0 — Baseline frozen.** Record protocol/source pins, the passing legacy
  Wii-oriented test, and a failing regression proving SsbmPad receives no
  GameCube slot on current code.
- **NL1 — GameCube transport correct.** Make controller family explicit. Two
  clients receive correct `m_pad_map` slots and transmit every `GCPadStatus`
  field byte-for-byte; the legacy Wii path remains green.
- **NL2 — Headless session reusable.** Extract one platform-neutral
  `NetplaySession` from SDL/ImGui. Host, join, ready, start, stop, destroy, and
  repeat work without a desktop window.
- **NL3 — Two-Mac Melee proof.** Two isolated macOS instances complete a full
  match with two-sided input, matching timebase diagnostics, no desync, clean
  teardown, and unchanged ordinary saves.
- **NL4 — Native mobile lobby.** The three-dot menu opens UIKit Online Play.
  iPhone/iPad can host/join, display players/ping/buffer/compatibility, start,
  cancel, report exact errors, and neutralize input on every exit.
- **NL5 — Mac/mobile gameplay proof.** Mac and iPadOS Simulator complete a full
  touch-controlled match with no desync. This is the minimum technical G9
  cross-platform proof, not the public mobile claim.
- **NL6 — Room-code internet path.** A SsbmPad-controlled traversal service
  produces an eight-character room code and connects two outside networks.
  Advanced direct IP remains available. Strict NAT fails clearly.
- **NL7 — Physical iPhone/iPad beta.** Physical iPhone and iPad complete
  real-internet matches using touch and connected controllers across the
  network/lifecycle matrix.
- **NL8 — Public Online Play claim.** At least 20 room-code connection attempts
  meet the written threshold, ten five-minute matches complete with zero
  desync/crash/hung teardown, ordinary save hashes remain unchanged, and
  repository/package/privacy/security/licensing checks pass.

## Current goal

**NL3 — Two-Mac Melee proof.** NL0 through NL2 passed their focused gates on
2026-09-01. NL3 gameplay is PARTIAL as of 2026-09-02.

The reusable `NetplaySession` now completes host/join/ready/start-data/stop
twice in one process, rejects invalid role/state actions, consumes boot data
once, rebuilds the desktop adapter, preserves the protocol suite, and compiles
for the iPhone Simulator toolchain. See
`docs/artifacts/2026-09-01/g9-headless-netplay-session.md`.

A control completed Zelda versus Samus on Onett through timed combat, Sudden
Death, identical results, and return to ready CSS with independent P1/P2 input
and no reported desync. It also exposed stale restart after host close and a
changed host ordinary isolated GCI. The candidate adds explicit runtime finish,
one-shot test auto-start, load-only save sync, exact Pipe profiles, and the
macOS SDL application handoff. Repeat the paired match from clean card copies;
NL3 passes only if teardown is clean and canonical/host/join ordinary save
hashes remain identical. See
`docs/artifacts/2026-09-02/g9-two-mac-melee-match-partial.md`.

## Operating loop

Repeat until NL8 passes:

1. **Orient.** Read this file, `docs/NETPLAY-FEASIBILITY.md`, current status,
   and the newest netplay artifact. State the lowest unmet goal.
2. **Audit.** Confirm repository status, dependency pins, active processes, and
   isolated build/user paths. Preserve the canonical solo app and user files.
3. **Predict.** Name one mechanism, one smallest change, expected result,
   rejection threshold, and rollback before editing.
4. **Add the regression first.** It must fail for the intended reason on the
   control whenever a focused automated test is possible.
5. **Change one boundary.** Prefer a narrow durable outer patch over edits that
   exist only inside ignored `ref/` checkouts.
6. **Test immediately.** Run the focused test, legacy Wii/controller tests, and
   the smallest relevant product regression. One endpoint never substitutes
   for the pair.
7. **Reverse when risky.** For runtime, timing, save, lifecycle, or network
   changes, run control/candidate/control or an equivalent clean rebuild.
8. **Retain evidence.** Write a dated artifact with commands, revisions,
   endpoint identities, result, failure classification, rollback, and next
   experiment. Never retain game data, modules, saves, IPs, or room codes.
9. **Update truth.** Update `docs/JOURNAL.md`, `docs/STATUS.md`, this current-goal
   section, and technical debt. Do not raise a goal from partial evidence.
10. **Publish.** Run `scripts/check-repository.sh`, commit only scoped work,
    push `main`, and verify local HEAD, `origin/main`, and remote `main` agree.
11. **Continue.** Pick the smallest step for the same or next goal. Stop only
    for a real authority, hardware, or service blocker.

## Isolation rules

- Use a dedicated netplay CMake build directory and dedicated user/config/save/
  pipe/log directories for every endpoint.
- Do not replace the installed Simulator app, promoted module, canonical G8
  package, or ordinary save while NL0-NL3 are under test.
- Run one game process except for an intentional paired netplay test. During a
  pair, identify both PIDs, roles, ports, user roots, and logs before launch.
- Never use the same user directory, FIFO, memory card, or diagnostics file for
  both endpoints.
- Dependency edits under `ref/ModernGekko` or its Dolphin submodule are working
  copies only. The durable result is an ordered patch under `patches/` plus a
  bootstrap application/check.
- Keep the ROM, extracted tree, generated module, save/savestate, profiles,
  signing material, IP addresses, and room codes untracked and out of evidence.
- Do not deploy a public service, change DNS, or create external infrastructure
  without the authority required at NL6. Local traversal-server tests are safe.

## Product correctness rules

- `m_pad_map` is the Melee GameCube ownership source. Do not make SsbmPad appear
  to work by translating touch into Wii packets.
- Preserve the existing touch pipeline. UIKit publishes the local virtual
  GameCube controller; Dolphin owns network packet encoding.
- Preserve exact game/module/mod compatibility. Never add a bypass.
- Automatic buffer is the default; manual 1-20 frames is advanced. Network wait
  time does not excuse sub-59 FPS/VPS emulation.
- The ordinary local memory card must remain byte-identical after client runs.
  Host save sync uses Dolphin's temporary NetPlay directory.
- Backgrounding an active mobile endpoint ends the version-1 match cleanly. Do
  not claim live resume until synchronized pause/resume is proven.
- Room codes are ephemeral locators, not authentication. ENet is plaintext
  until authenticated encryption is explicitly implemented and tested.

## Required regressions

Before NL8, automated coverage must include:

- GameCube slot capacity, assignment, controller-count changes, ready/start
  gating, disconnect cleanup, and reconnect;
- exact buttons, analog A/B, both sticks, both analog triggers, and connection
  state through `PadData`;
- unchanged Wii assignment and `WiimoteData` transport;
- identical dynamic/attached module fingerprints and every mismatch family;
- host/join/start/stop twice in one process with no leaked thread/service;
- automatic/manual buffer propagation and bounded input-wait telemetry;
- invalid/expired room code, unavailable traversal, strict NAT, room full,
  game running, nickname rejection, mismatch, host loss, and client loss;
- touch/controller disconnect neutralization and touch reclaim;
- mobile inactive/background/foreground transitions; and
- repository/package audits that reject private/game/save/network evidence.

## Evidence ladder

1. Physical iPhone/iPad real-internet full match.
2. Mac/iPadOS paired full match with visible input/results and both logs.
3. Two-Mac paired full match.
4. Headless two-client session regression.
5. Exact protocol payload regression.
6. Source inspection, mocks, or compile-only proof.

Lower evidence explains but never promotes a failed higher gate.

## Claim language

- Before NL1: `netplay infrastructure exists; Melee controller mapping is broken`.
- After NL1: `GameCube netplay transport passes focused tests`.
- After NL3: `direct two-Mac Melee netplay works in the retained test`.
- After NL5: `cross-platform Mac/iPadOS Simulator netplay works in the retained
  test`; do not claim mobile online support.
- After NL7: `Online Play with Friends beta works on tested physical Apple
  devices and networks`, with strict-NAT/plaintext limitations disclosed.
- Only after NL8: `SsbmPad supports Online Play with Friends`.

## Stop conditions

Stop and request user or external action only when the next gate requires:

- physical-device signing or hands-on input unavailable to the agent;
- authority to deploy or pay for traversal/relay infrastructure;
- DNS or account credentials;
- a product decision that changes the private-friend/delay-based scope; or
- the same independently verified blocker survives three goal turns and no
  safe local experiment remains.

Difficulty, uncertainty, a long build, or a failed candidate are not blockers.
