# Slippi interoperability feasibility

Follow-up: [priority assessment and executed compiler probe](SLIPPI-PRIORITY-ASSESSMENT-2026-09-10.md)
identifies Project Slippi's modern Dolphin port as the primary runtime reference
and records four Slippi hooks compiled to iOS ARM64 objects. The initial research
below predates that probe; neither pass establishes playable Slippi integration.

Researched 2026-09-10. Source inspection and experiment proposal; no Slippi
integration, service login, online match, or hardware deployment was performed.
MeleePad baseline: `a4ef57750cd1dc7510f6777d16404184eee57f44`, on
`codex/native-port-learning`.

## Recommendation

Investigate a bounded, offline Slippi compatibility prototype. The useful first
question is whether MeleePad can execute Slippi's game modifications and recover
correctly from delayed input within its no-JIT runtime. Buying a VPS does not
answer this question. A successful prototype would justify testing against a
consenting desktop Slippi player; it would not establish public matchmaking
support by itself.

The earlier description of Slippi as a major separate port remains reasonable,
but a calendar estimate is premature. There are concrete experiments that can
reject or support feasibility before committing to the whole port.

## Which players would each approach reach?

| Approach | Opponents | Main unresolved work |
|---|---|---|
| Existing Private Room / Direct IP | Other compatible MeleePad builds, including Mac builds | Completed physical-device Internet matches, rematches, latency and NAT coverage |
| Pad Lobby on a small VPS | The same compatible MeleePad population, with easier discovery | Gameplay acceptance first, then service deployment and operation |
| Slippi-compatible MeleePad mode | Potentially existing desktop Slippi users | Game-code execution, EXI integration, simulation compatibility, rollback, performance and service integration |
| Our own rollback protocol and lobby | Users of our compatible client | Rollback implementation plus our own player population; no automatic Slippi compatibility |

The current [online-play evidence](ONLINE-PLAY.md#what-has-been-verified) includes
a Mac-to-Mac complete match and Mac/Simulator synchronization. It does not
record completed physical-device Internet matches. Current protocol checks are
specific to MeleePad's modules and runtime; pointing either client at the other's
server cannot make the protocols agree.

## Findings that refine the earlier research

### 1. Slippi Direct still uses the Slippi service

The inspected client submits a matchmaking ticket containing account identity,
play key, connect code, search mode and application version. Direct is one of
those search modes. The response supplies match configuration and peer
addresses, after which the client establishes its peer connection.

Consequently, Slippi Direct is not MeleePad Direct IP. Our room codes cannot be
entered as Slippi connect codes. A private Pad Lobby also cannot introduce us
into the existing Slippi queues without implementing Slippi compatibility.
See [matchmaking client](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/Slippi/SlippiMatchmaking.cpp#L422-L434)
and [mode definitions](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/Slippi/SlippiMatchmaking.h#L25-L32).

Slippi's developer documentation says its matchmaking server source is private.
That prevents treating it as a published self-hosting package; it does not prove
that third-party clients are technically impossible. Supported third-party
access, testing arrangements and future compatibility remain questions for the
maintainers. No claim of approval or rejection is established here.
[Developer overview](https://github.com/project-slippi/slippi-wiki/blob/master/GETTING_STARTED.md)

### 2. Rollback is more targeted than a full Dolphin state reload

`SlippiSavestate::Capture` copies selected Melee memory regions. `Load` restores
them while preserving specified blocks. Sound-related and video-related ranges
are excluded; the full Dolphin-state capture/load calls in this class are
commented out. These are deliberate game-specific semantics, not permission to
ignore arbitrary mismatches.
[Snapshot implementation](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/Slippi/SlippiSavestate.cpp)

The game modifications initiate capture through EXI, loop the game update
function during rollback, and reconcile sounds from cancelled actions.
[Capture hook](https://github.com/project-slippi/slippi-ssbm-asm/blob/fcf47f10dc244152c2ebaa3a9dec142ea42243b7/Online/Static/SaveState.asm)
and [rollback loop](https://github.com/project-slippi/slippi-ssbm-asm/blob/fcf47f10dc244152c2ebaa3a9dec142ea42243b7/Online/Core/LoopEngineForRollback.asm).

Inference: an AOT runtime is not inherently excluded. We need to preserve these
game-visible semantics and prove equivalent results. Existing general Dolphin
savestate support alone does not provide that proof. Local snapshot formats do
not need to be identical across peers; their simulated match must agree.

### 3. Injected and dynamically loaded code is the first MeleePad obstacle

MeleePad's current runtime selects `CPUCore::StaticRecomp`. Its code-verification
guard rejects changed guest-code chunks and routes them through fallback;
physical iOS has no fallback JIT. Slippi patches applied to a vanilla module
would therefore need explicit native coverage or correct interpreter execution.
An unmeasured interpreter-heavy Slippi path is not an acceptable performance
assumption.

Local source: `ref/ModernGekko/src/runtime/dolphin_runtime.cpp`,
`ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore.cpp`,
and `StaticRecompCore_SMC.cpp` in that same directory.

This is also more than prepatching a vanilla DOL: the inspected Slippi Gecko
loader installs a bootloader which loads the codes into heap memory. A prototype
must inventory executable injections, their placement/relocation, and any
dynamically loaded code, then make native dispatch and invalidation handle them.
Do not disable verification to run stale native code over modified guest memory.
[Gecko loader](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/GeckoCode.cpp#L161-L198)

The current Slippi ecosystem also includes
[Melee C code](https://github.com/project-slippi/slippi-ssbm-c/tree/d7174ca0f1e6f19d0e8ec5152a3b53943f5b1c34)
and [Rust extensions](https://github.com/project-slippi/slippi-rust-extensions/tree/2d29e794de8497582675fb70877851f2cdd2f256).
The Rust extension exposes a C interface and includes account, reporting and
audio functionality. An inventory limited to the old ASM repository and ENet
would miss dependencies. These independently inspected revisions are not yet a
verified, mutually compatible release bundle.

MeleePad has ordinary EXI device support, but its inspected device factory has
no Slippi device. Slippi's command handling needs an explicit runtime adapter;
neither the present Room Chat code nor the lobby service supplies it.

### 4. A mobile Slippi port is a useful reference, with a different CPU model

The author of `MaxLaurence/slippi-android` reports Direct, Unranked and Teams play
on an ARM64 Android handheld, with ranked disabled and official Slippi sign-in.
This is author-reported functionality, not an independently repeated device
test or evidence of official endorsement.
[Pinned Android README](https://github.com/MaxLaurence/slippi-android/blob/66b16f105d1b8076a42194d515707b4c58f96960/Readme.md)

Its source retains Dolphin's JIT/interpreter CPU execution model. This makes it
a useful mobile integration reference, but it does not solve MeleePad's AOT
injection coverage or establish iOS performance.
[CPU initialization](https://github.com/MaxLaurence/slippi-android/blob/66b16f105d1b8076a42194d515707b4c58f96960/Source/Core/Core/PowerPC/PowerPC.cpp#L135-L163)

### 5. There is a concrete offline rollback test lead

Upstream contains `LOCAL_TESTING` branches, a dummy peer constructor and
`GetFakePadOutput`. The latter supplies old inputs and then introduces an earlier
button press to trigger rollback. Its normal EXI call site is commented out.
These are reference hooks, not a verified maintained test suite or a ready-made
MeleePad switch.
[Fake input source](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/Slippi/SlippiNetplay.cpp#L1430-L1460)
and [EXI integration](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/HW/EXI_DeviceSlippi.cpp).

## Proposed experiment sequence

1. **Pin a complete Slippi target.** Start with vanilla GALE01 v1.02 and one
   exact Slippi release, including its actual game patches and dependencies.
   Inventory guest execution ranges and EXI commands. Keep v1.00 out of this
   experiment. Shared v1.02 support removes a revision mismatch, not the rest
   of the compatibility work.
2. **Run the game hooks locally.** Use an isolated Mac harness with
   `STATICRECOMP_NO_FALLBACK_JIT=1` to approximate the iOS CPU contract. Implement
   only the runtime integration needed for the pinned offline experiment.
   Measure native coverage, fallback cost, EXI responses and state restoration.
   This desktop restriction is useful preparation, not physical-iOS acceptance.
3. **Force late input and prove recovery.** Compare an authoritative input run
   with the same run receiving input 1, 3, 5 and up to 7 frames late. The inspected
   netplay header defines a seven-frame rollback maximum. Compare finalized
   gameplay state after recovery, including RNG, fighters, projectiles, items
   where applicable and scene transitions. Test audio correction and rendered
   results separately. Restore, replay and forward execution must all agree;
   an empty-scene memory-copy benchmark is insufficient.
4. **Test a consenting desktop Slippi opponent.** First isolate simulation and
   peer-protocol compatibility in a controlled harness. For an unmodified
   desktop client using normal Direct, integrate its account/service flow and
   resolve supported test access with maintainers. Finish games, return to
   selection and rematch. Do not remove MeleePad's existing compatibility
   checks as a shortcut or claim a connection handshake as gameplay success.
5. **Repeat on physical iPad, then iPhone.** Test separate home networks, swapped
   hosts where applicable, delay/jitter/loss, cancellation, backgrounding and
   disconnects. Measure frame-time tails, rollback depth/cost, sound and thermal
   behavior over sustained matches. Expand to public queues only after this
   works reliably and service integration is settled.

The seven-frame limit comes from
[SlippiNetplay.h](https://github.com/project-slippi/Ishiiruka/blob/e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1/Source/Core/Core/Slippi/SlippiNetplay.h#L30-L35).
The test values above are proposed coverage, not measured MeleePad capabilities.

Performance is a real gate: the current
[performance handoff](SESSION-HANDOFF-2026-09-09.md) records heavy iPhone scenes
below full speed. That is not a fresh iPad measurement, but it rules out assuming
spare CPU budget across all supported devices. Rollback adds resimulation work;
it does not fix a device that already cannot sustain normal match speed.

## Hosting and service decision

For the first three experiments: **no VPS is needed**. Offline validation can
run locally. Existing MeleePad P2P community testing can also proceed separately
without deploying Pad Lobby.

For existing Slippi opponents, the practical destination is a compatible client
using Slippi's service for discovery and direct peer gameplay. Hosting our own
service would serve our own compatible population; it would not merge player
pools. A lightweight discovery server also does not provide a gameplay relay
when NAT traversal fails.

Before service integration, ask maintainers which third-party testing route is
supported, whether there is a staging or Direct-only option, which versions and
codesets must match, and what account/reporting requirements apply. These are
open integration questions; no outreach was sent during this research.

## Source snapshot and limits

- Ishiiruka `slippi`: `e9d048ac6f2d77f96fcd1c0b04bc1533a7ff81e1`.
- Slippi ASM `master`: `fcf47f10dc244152c2ebaa3a9dec142ea42243b7`.
- Slippi C: `d7174ca0f1e6f19d0e8ec5152a3b53943f5b1c34`.
- Rust extensions: `2d29e794de8497582675fb70877851f2cdd2f256`.
- Android reference: `66b16f105d1b8076a42194d515707b4c58f96960`.

GitHub's latest-release API returned
[Ishiiruka v3.6.4](https://github.com/project-slippi/Ishiiruka/releases/tag/v3.6.4),
published 2026-06-15. The inspected development head is newer. The report does
not claim those branch heads reproduce that release or establish what a live
matchmaking server currently accepts. No release binaries were downloaded.

The next implementation decision should depend on hook execution, deterministic
rollback and measured device cost. Source availability, a mobile fork's README,
MeleePad room creation, and a server deployment cannot substitute for those
results.
