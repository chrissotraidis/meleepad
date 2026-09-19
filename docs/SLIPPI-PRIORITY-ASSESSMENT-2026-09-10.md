# Slippi priority assessment and compiler probe

Date: 2026-09-10. Follow-up to the
[initial feasibility report](SLIPPI-FEASIBILITY-2026-09-10.md).
The user has prioritized interoperability with existing online Melee players.
The active [compatibility implementation loop](SLIPPI-COMPATIBILITY-GOAL-LOOP.md)
tracks subsequent executable tests and remaining integration gates.

## Latest Mac-only evidence (2026-09-11)

The [implementation loop](SLIPPI-COMPATIBILITY-GOAL-LOOP.md#iteration-26-mac-only-referencenative-match-start)
now records an instrumented desktop Ishiiruka reference playing against the
native no-JIT runtime. In 1,462 finalized frames, player and RNG packets match,
including desktop rollback revisions. Item data contains a one-ULP projectile
position difference, so strict compatibility still fails. This is materially
stronger feasibility evidence than local-to-local testing, but it does not
establish public Slippi support, a complete match/rematch, or current iPad
acceptance. The detailed assessment below records the earlier milestones.

## Determination

**Proceed with a Slippi compatibility prototype, using Project Slippi's modern
Dolphin port as the primary runtime reference.** The evidence does not support
calling integration impossible. It also does not yet establish that MeleePad
can run a correct, full-speed Slippi match on an iPad.

This is a positive engineering decision to investigate implementation. Public
Slippi support remains unproven until the actual app completes Internet games
and rematches with a standard desktop client. The first online milestone should
be Direct with an arranged opponent, followed by Unranked; ranked is unnecessary
for proving access to existing players.

## Answers to the decisive questions

The product determination remains **go for an experimental compatibility port;
no-go for advertising Slippi support**. The current application cannot play a
Slippi opponent. No fatal architectural incompatibility has been demonstrated.

| Question | Answer from current evidence |
|---|---|
| Can the no-JIT runtime execute all required Slippi code? | **Partial executable proof.** The three required code groups now boot, render and run an offline two-controller match on macOS and physical iPad with CPU and vertex-loader JIT disabled. Patched text and GCT native dispatch work, with interpreter fallback for differing code. Not all code paths are accepted; the full default six-group configuration still fails. |
| Can Slippi snapshots work with this runtime? | **Yes at the memory-component level.** The adapted upstream implementation links and executes against MeleePad's actual Dolphin core. 100 synthetic capture/restore cycles pass 500 checks. |
| Does late-input rollback reproduce the correct match? | **Controlled offline pass.** After deliberately wrong 1/3/7-frame predictions, restoration and authoritative resimulation match 717 complete player/RNG/item packets on macOS and 786 on the physical iPad, each over three 60-frame trials. Actual local online rollback now reaches 3- and 7-frame rewinds and agrees on 4,985/4,994 finalized player/RNG/item packets between two experimental clients. A same-input on-time online baseline, audio/render acceptance and standard desktop crossplay remain open. |
| Can an iPad sustain Slippi match speed? | **Short local online pass; sustained speed not established.** The physical iPad matches 4,742 finalized state packets with the experimental Mac peer and advances at 59.96 game frames/s over 20.50 seconds. This run has no rollback and disables audio. Full matches/rematches, delayed online rollback and sustained thermal behavior remain unaccepted. |
| Can we reach existing desktop users through Slippi? | **A credible upstream route exists; MeleePad access is untested.** Project Slippi reports cross-compatible netplay in its modern Dolphin port. Its client uses the real account/matchmaking flow. We have not authenticated MeleePad or completed a cross-client game. |
| Will deploying Pad Lobby resolve any of these? | **No.** It would discover users of our own protocol; it cannot make them compatible with desktop Slippi. |

The source evidence supports investing in the port. It cannot support a promise
that the completed iOS port will be correct and fast. A Slippi account or second
player is not the blocker for continued offline implementation: sustained physical iOS performance, audio and full default game-code behavior
remain unresolved runtime gates.
Live service testing will require
normal account access and an arranged opponent after that runtime works.

The [network and account audit](SLIPPI-NETWORK-IDENTITY-AUDIT.md) now includes
a passing offline test of 1,000 independent account managers and a bundle
credential guard. iOS authentication, credential transport, session/report
ownership and actual service acceptance remain open. Initial precise iPad
profiling measured 55.22 game frames/s. The later diagnostic idle-control run
reaches 59.94 game frames/s and passes 699 exact correction-packet comparisons.
Different characters prevent a matched speedup claim. Later physical online
results are summarized below; sustained speed and audio remain unaccepted. See
[iteration 13](SLIPPI-COMPATIBILITY-GOAL-LOOP.md#iteration-13-physical-idle-control-experiment).

The latest physical iPad/Mac fixture test matches **11,217 finalized packets**
with delayed-input correction and measures **59.74 game frames/s over 54.82
seconds** with CoreAudio enabled. The measured window has **zero DMA underruns**;
both players change position and action state. Audible quality, complete
matches/rematches and sustained thermal behavior remain open. A prior observed
pause also needs match-rule/render investigation. This is not standard desktop
crossplay or public service acceptance. See [iteration 20](SLIPPI-COMPATIBILITY-GOAL-LOOP.md#iteration-20-physical-coreaudio-path-and-controller-fixture-correction).

## Where players find online games

| Surface | What it provides | Consequence for MeleePad |
|---|---|---|
| Slippi Unranked | Automatic nearby-opponent matchmaking | Primary target for playing existing users without arranging a game |
| Slippi Direct | Games with a specific player's connect code | Best first interoperability acceptance target |
| Slippi ranked | Competitive matchmaking and rankings | Later scope, beyond initial compatibility |
| Melee Discord communities | Finding practice partners, beginners, regional groups and events | Useful recruitment channels; participants still need compatible game clients |
| SmashLadder | Community matchmaking, chat and ladders | Not evidence that MeleePad's custom Dolphin protocol can join those players |

The official [Slippi setup page](https://slippi.gg/netplay), inspected in a live
browser, explicitly distinguishes Direct for specific players and Unranked for
automatic nearby opponents. It requires an account and an unmodified v1.02 game.
Its [leaderboards](https://slippi.gg/leaderboards) are the ranked surface.

[Melee.tv](https://melee.tv/) directs online players to Slippi, links ranked
leaderboards and maintains a [Discord directory](https://melee.tv/discord) and
online-event resources. This supports prioritizing the Slippi ecosystem; it is
not a measured market-share or concurrent-player count. No reliable current
population total or region-specific queue-time estimate was established.

[SmashLadder's own FAQ](https://www.smashladder.com/help/questions) describes its
matchmaking/community role. Older guides alone cannot establish today's active
Melee population, so this assessment does not claim SmashLadder is either empty
or a populated alternative to Slippi.

## Stronger upstream route: Slippi Mainline

The initial pass focused on Ishiiruka and an unofficial Android fork. It missed
the more relevant [Project Slippi modern Dolphin port](https://github.com/project-slippi/dolphin/tree/41a7a3a110ed52999486ae1901c8fbb9a63d4f13).
Its README describes netplay as cross-compatible with Ishiiruka and the Rust
integration as connected, while calling the overall port work in progress.
That README's status paragraph is dated 2025-11-08; it is a maintainer claim,
not a fresh interoperability test performed here.

Current source was inspected at `41a7a3a110ed52999486ae1901c8fbb9a63d4f13`.
Its Slippi EXI device takes `Core::System&`; its snapshots use
`GetMemory().CopyFromEmu/CopyToEmu` and `CPUThreadGuard`. These are the same API
families present in MeleePad's modern Dolphin-derived runtime. Porting this
implementation is a better starting point than independently repeating the old
Ishiiruka-to-modern-Dolphin adaptation.
[EXI source](https://github.com/project-slippi/dolphin/blob/41a7a3a110ed52999486ae1901c8fbb9a63d4f13/Source/Core/Core/HW/EXI/EXI_DeviceSlippi.h)
and [snapshot source](https://github.com/project-slippi/dolphin/blob/41a7a3a110ed52999486ae1901c8fbb9a63d4f13/Source/Core/Core/Slippi/SlippiSavestate.cpp).

This inference does not mean the files can be copied into MeleePad unchanged.
Core configuration, boot/Gecko handling, resource loading, audio, Rust linkage
and lifecycle still need integration. The follow-up component build below
exercised those API differences; no complete Slippi runtime has been built.

The modern port still sends account credentials, search mode and app version
to Slippi's matchmaking service. It is not an implementation of a new isolated
player pool. Source-level service compatibility is visible; service acceptance
and support for MeleePad remain untested.
[Matchmaking source](https://github.com/project-slippi/dolphin/blob/41a7a3a110ed52999486ae1901c8fbb9a63d4f13/Source/Core/Core/Slippi/SlippiMatchmaking.cpp).

## Exact release audit

Pinned Ishiiruka release: **v3.6.4**, commit
`e7711b104b339a99385f2bb12b472d46140a7bc7`.

The release's `Data/Sys/GameSettings/GALE01r2.ini` and the inspected modern
Slippi head's same file are **byte-identical**:

```text
SHA-256 b30b294df5c0d92deb3129afdfbc894a48aabeb1bce0cf92cce8c4e5408a2587
```

Both pin Rust extensions at `2d29e794de8497582675fb70877851f2cdd2f256`.
This is concrete alignment between the two source snapshots, not proof that
their entire resource bundles, binaries or live service behavior are identical.

The release injection manifest contains 309 entries: 275 under the three
Required groups, with the remainder under Recommended or Optional groups.
Entries are patch metadata, not a count of complete functions or work estimates.
The release tree also contains 16 auxiliary GALE01 files totaling 2,358,484 bytes,
including game-code/data containers and resource diffs. Those payloads were
inventoried from tree metadata, not installed or published by this research.
[Release configuration](https://github.com/project-slippi/Ishiiruka/blob/e7711b104b339a99385f2bb12b472d46140a7bc7/Data/Sys/GameSettings/GALE01r2.ini)
and [injection manifest](https://github.com/project-slippi/Ishiiruka/blob/e7711b104b339a99385f2bb12b472d46140a7bc7/Data/Sys/Slippi/InjectionLists/list_netplay.json).

## Executed compiler probe

Four C2 hook payloads were extracted from that exact INI into isolated DOL
fixtures. Each was assigned the synthetic address `0x81700000`. The final Gecko
return-branch placeholder was replaced with `blr` solely for this compiler
fixture. These fixtures do not reproduce actual injection placement or link
against the game.

| Hook | Fixture bytes | DolRecomp decoder summary | iOS ARM64 objects |
|---|---:|---|---|
| ForceEngineOnRollback | 208 | 52 known, 0 unknown | Pass |
| LoopEngineForRollback | 736 | 184 known, 0 unknown | Pass |
| StartEngineLoop | 1,752 | 424 known, 13 embedded data, 1 unknown | Pass |
| TriggerSendInput | 1,936 | 484 known, 0 unknown | Pass |

Each hook generated a dispatcher and one chunk. All eight C translation units
compiled with the existing MeleePad DolRecomp executable and matching GXRuntime
CPU headers, targeting `arm64-apple-ios16.0`, `-O2`, no fast math and no FP
contraction. `file` confirmed an ARM64 Mach-O object. The separate current
DolRecomp research executable also compiled all four with its matching headers.

The one unknown word in StartEngineLoop is `0xFF444553` at payload offset `0x44`,
within an embedded UI-data region containing the text DESYNC. The branch at
offset `0x10` skips to `0x230`. This is not evidence of an unsupported executed
PPC instruction. Nevertheless, the generated code retains a fallback at that
address; the probe does not claim every possible entry point is valid or prove
runtime control flow.

An initial exploratory compile mixed the current research compiler with an
older CPU header and failed on a missing inline helper. Repeating with each
compiler's matching headers passed. This was a probe setup error, not a Slippi
or device failure.

Reproduction script: [probe-slippi-hook-compilation.py](../scripts/probe-slippi-hook-compilation.py).
Recorded metadata: [compiler results](artifacts/slippi-feasibility-2026-09-10/hook-compilation.json).
The script verifies the INI hash and writes extracted/generated files only to
the caller-supplied new output directory. No game image or account is required.

```sh
python3 scripts/probe-slippi-hook-compilation.py \
  --ini /path/to/pinned/GALE01r2.ini \
  --dolrecomp ref/ModernGekko/build-desktop-tools-meleepad-netplay/dolrecomp \
  --cpu-include ref/ModernGekko/vendor/dolphin/GXRuntime/include \
  --output /tmp/meleepad-slippi-hook-probe-new
```

**What this proves:** representative Slippi rollback/input code can pass through
the available static compiler and iOS compiler. It weakens the hypothesis that
these instructions categorically require JIT.

**What it does not prove:** linked game execution, all injected-code coverage,
dynamic relocation, native dispatch correctness, rollback determinism, iOS
runtime performance, account integration or desktop crossplay. No probe code
was installed on a device or executed as a game.

## Executed snapshot integration probe

A subsequent build used the existing macOS and iPhoneOS MeleePad core compiler
flags. Unmodified SlippiPad compiled. SlippiSavestate initially failed because
`HostRead_U32` has become the templated `HostRead<u32>` and the current runtime
has no `SLIPPI_ONLINE` logging category. Adapting those calls and routing the two
heap diagnostics to `CORE` produced ARM64 objects for both macOS and iOS.

The adapted snapshot object was then linked with the existing macOS MeleePad
Dolphin libraries and a small isolated harness. The harness initialized actual
Dolphin memory, supplied synthetic BAT mappings and heap bounds, and executed
100 capture/mutate/restore cycles. All 500 checks passed: included data and heap
values restored; excluded sound memory, an explicitly preserved block and a
location outside the snapshot remained at their later values.

[Recorded results](artifacts/slippi-feasibility-2026-09-10/snapshot-integration.json)
and [executed harness](artifacts/slippi-feasibility-2026-09-10/snapshot-probe.cpp).
The temporary adapted source, compilation logs, linker log and executable are
retained locally under `/tmp/meleepad-slippi-integration-20260910`.

This is a real memory-component integration test using synthetic data, **not**
a game simulation or a timing benchmark. It did not boot Melee, execute generated
Slippi PPC hooks, inject delayed player input, compare against desktop state,
contact Slippi services or execute on iOS. The iOS result is compilation only.

Additional initial build probes exposed missing/relocated configuration and
NetPlay headers in networking and a missing open-vcdiff dependency in the game
resource loader. Those are integration work, not evidence that the architecture
is impossible. None of these exploratory adaptations changes the app or its
installed device build.

## Prioritized implementation boundary

Use a separate experimental Slippi mode and preserve existing fixed-delay
Private Room behavior. For the prototype, use Slippi's own game flow to minimize
independent changes to its match setup and game hooks.

1. Bring the modern Slippi EXI/boot/resource path into an isolated MeleePad
   runtime build using the pinned v1.02 target. Prove commands reach the device
   adapter and game resources load correctly.
2. Extend generation and native dispatch for the pinned injected/loaded code.
   Existing REL address translation is useful precedent, but Gecko heap code
   and Melee DAT containers are not automatically Dolphin REL modules. Preserve
   code verification and correct invalidation; do not bypass them to force
   incompatible native chunks to run.
3. Exercise actual rollback locally with delayed authoritative input. Compare
   finalized match state and audio/render behavior against an on-time run.
4. Validate a Mac native endpoint against desktop Slippi in an arranged test,
   then perform the same match/rematch on a physical iPad. Resolve Slippi account
   and service integration before normal Direct testing. Expand to Unranked
   only after the game remains correct and responsive.

Steps 1-3 determine whether the runtime approach works. Step 4 determines whether
the product can reach the existing player pool. Sustained device performance
remains a separate acceptance gate; desktop compilation cannot settle it.

No new discovery VPS is required for the first experiments. If Slippi
interoperability succeeds, its discovery service is the relevant route to those
players. Pad Lobby remains a separate option for our own compatible clients.

## Questions for Slippi maintainers

The modern port README identifies its maintainers/Discord as the integration
contact. No outreach was sent. A useful technical inquiry would establish:

- the preferred modern-Dolphin revision and synchronized game-resource bundle;
- supported Direct-only or staging tests for a no-JIT iOS client;
- account, versioning and reporting requirements for an alternate frontend;
- known determinism assumptions that could affect an AOT CPU implementation.

These are integration questions, not a finding that a private server makes
third-party clients impossible. The next decisive evidence is the running
prototype, not another lobby implementation.


### Actual local online rollback update

The experimental clients now converge after changed predictions with measured
three- and seven-frame rewinds under delayed PAD delivery. Both delayed runs
pass complete finalized player/RNG/item packet comparison and exit cleanly.
This is stronger than the earlier neutral-input local match, but still uses
two copies of the experimental runtime with audio disabled. See
[iteration 16](SLIPPI-COMPATIBILITY-GOAL-LOOP.md#iteration-16-actual-online-rollback-under-delayed-input-delivery)
for exact counts, negative controls, excluded unfinished tails and the remaining
physical/desktop acceptance boundaries.
