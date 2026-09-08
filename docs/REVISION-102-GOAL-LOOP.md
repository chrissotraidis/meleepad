# Preferred v1.02 and decompilation integration goal loop

Started 2026-09-08. The owner authorizes implementing USA v1.02 as the
preferred target while retaining v1.00, investigating the completed
decompilation, and pursuing measured improvements. This loop governs that new
work; historical performance gates remain evidence requirements, not a ban on
implementing the newly requested revision support.

## Product contract

- Detect the actual imported revision; never infer it from a filename.
- Recommend v1.02 for alignment with the completed decompilation and the
  wider Melee tooling ecosystem. Do not promise higher FPS or Slippi support.
- Keep v1.00 usable, including existing imports and saves. Retain each
  revision independently; switching games must not silently replace data.
- Explain: v1.02 is recommended for new setups and future improvements;
  v1.00 preserves existing setups and that revision's behavior. Online peers
  need the same game revision, compatible app build, and gameplay changes.
- Check module identity against the selected executable before launch.
- Public artifacts remain module-free. All disc-derived outputs stay private.

## Work lowest incomplete gate

| Gate | Evidence required | State |
| --- | --- | --- |
| R0 Input verified | Identify container, disc revision, executable and data hashes | Verified supplied CISO, executable hash, FST extents; independent retail asset comparison remains open |
| R1 Build separation | Independently prepare both revisions without overwriting active v1.00 module or extraction; compile v1.02 | Passed: separate r0/r2 extraction and module stores; Simulator/device modules for both revisions built; macOS 14 module rebuilt and packaged |
| R2 Runtime correctness | Audit every revision-specific address, input hook, idle shortcut and diagnostic write; verify v1.02 against executable/source | Implemented: revision-specific waits and scene address; legacy diagnostic writes gated to r0; runtime boot and input observed |
| R3 Import and selection | Preferred-version explanation, validated imports, independent storage, module selection, legacy migration | Passed in Simulator: both actual imports, both selection directions, accurate labels; r2 save unchanged after r0 import |
| R4 Online identity | Actual selected revision in discovery and transport; reject mixed revisions/builds/mods; positive and negative tests | Identity implemented; service tests pass for mixed-revision rejection and matching-r2 acceptance; direct transport rejects mixed revisions (guest exit 12); matching r2 peers produced 44 matched snapshots in bounded title/attract run; controlled online match remains open |
| R5 Product acceptance | Build both Apple targets; visible import, boot, controls, match/results, audio, lifecycle; preserve v1.00 | Simulator r2: save creation, menus, character select, Classic match and stage results observed; r0 boot/save and return to r2 passed. Device app builds; separate QA app signed; installed on iPad; v1.02 first save prompt observed, hands-on match pending |
| R6 Decompilation improvements | Pinned complete upstream source; named profiling; investigate a concrete defect/hotspot and validate any fix | Pinned completed source; executable-checked symbolizer; audited scheduler and pad waits. No measured performance claim; reflection/thermal investigation remains open |
| R7 Delivery | Relevant checks, docs and exact acceptance/debt ledger; audit distributable boundaries | Full repository checks pass; docs implemented; macOS layout/signature passed; public module-free IPA audited and playable-module rejection passed; hardware acceptance open |

## Operating loop

1. Record the current finding and one falsifiable next step.
2. Inspect existing implementation before adding infrastructure; prefer shared
   small revision metadata and existing Dolphin extraction/runtime facilities.
3. Implement the smallest complete change, then run focused regressions.
4. Build and inspect the real application. Compilation and scripted tests do
   not prove physical gameplay or sustained performance.
5. For performance changes use matched control/candidate routes, correct
   graphics/input, frame tails, CPU cost, audio underruns and thermal state.
   Reject changes without a measured benefit or with semantic regressions.
6. Update this ledger and continue. A missing device or manual acceptance
   blocks that evidence only; finish independent work and document the gap.

## Evidence and remaining work

Private evidence lives under `ref/revision-102/`: image and extraction, build
logs, isolated QA simulator inventory, and before/after save hashes. No game
data or device identifiers belong in this ledger.

On 2026-09-08, build 8 imported the supplied CISO through the real Files picker,
identified v1.02, created a save and navigated to a Fox Classic match against
Captain Falcon on Mute City. The stage-clear/results screen rendered. The
legacy ISO then imported without replacing v1.02; the saved v1.02 GCI hash
remained unchanged. v1.00 booted, created its separate save, and the version
chooser returned to the existing v1.02 save without another creation prompt.
These are Simulator observations, not physical-device or latency acceptance.

Next gates: isolated physical-device smoke test after iPad unlock; complete
two-peer synchronized gameplay and mismatch messaging; measure a matched
control/candidate performance route before changing more scheduling/rendering.
A complete upstream decompilation is a reference for these investigations,
not evidence that a native-source port or rollback networking is complete.

## Initial findings

The supplied file is CISO, not a raw ISO. The GameCube header identifies
GALE01 disc 0 revision 2. Its main.dol SHA-1 is
`08e0bf20134dfcb260699671004527b2d6bb1a45`, matching
[upstream's target](https://github.com/doldecomp/melee).
Executable identity alone does not establish every asset's integrity.

Current assumptions to remove: prepare-game.sh exact r0 hash; shared GALE01
module pointer and temporary module build paths; provisioned r0 extraction;
iOS single GameData directory and hash; unconditional r0 controller/scheduler
addresses; lobby client hard-coded r0. The lobby service already rejects a
different revision. Preserve its strict checks.

First decompilation applications: audit controller queue and idle shortcuts,
map v1.02 scene/input structures, annotate dispatch profiles, and investigate
the retained reflection/thermal issues only from reproducible evidence.
Wholesale native source replacement and rollback remain separate research
directions, not prerequisites or promised outcomes of this loop.

## Build and transport checkpoint

- Simulator build 8 and unsigned device build 8 compile successfully. Both
  Simulator and device modules for both revisions compile with matching identity
  sidecars. The separate `com.meleepad.RevisionQA` app was signed and verified;
  installation was rejected because the iPad had not been unlocked recently.
  The existing installed MeleePad was not replaced.
- The macOS 14 package includes both modules under executable-hash directories.
  Layout, platform/dependency checks and strict signing verification pass.
  CLI extraction of both source images retains `games/GALE01` and
  `games/GALE01-r2`. The CISO file-picker filter is included.
- A local two-process v1.02 test passed compatibility negotiation, entered the
  lobby, and started both exact r2 modules with the configured secondary and
  caller waits. Both logged an active canonical boundary. The bounded run did
  not establish sustained matching canonical snapshots or playable online
  synchronization; this remains an explicit acceptance gate.
- Full repository checks pass. The shared lobby service's HTTP tests include
  matching r2 acceptance and mixed r0/r2 rejection. Public packaging rejects
  the new playable module name; an unsigned module-free build 8 IPA was
  produced privately and audited, but has not been published.

## Next improvements, in order

1. Finish hardware and peer acceptance before promoting build 8. Add a v1.02
   deterministic benchmark route from verified scene/CSS structures; do not
   reuse r0 memory writes or infer FPS gains from Simulator behavior.
2. Use the pinned symbol map to attribute repeatable gameplay frame stalls to
   named functions. Compare the same route, scene, settings and thermal state
   before proposing another scheduler or generated-code optimization.
3. Reproduce the retained reflection/rendering issue with source-guided state
   traces and a fixed camera/scene. Treat visual correctness as a prerequisite
   to accepting any performance change.
4. Add training/diagnostic features from verified game state only after the
   revision and runtime acceptance gates pass. Rollback/Slippi interoperability
   and wholesale native source replacement require separate designs.

## Canonical trace follow-up (2026-09-08)

The original logger printed success only when a sampled boundary sequence was
an exact multiple of 600. Silent logs therefore did not prove missing reports
or matching gameplay. An opt-in `MELEEPAD_NETPLAY_TRACE_CANONICAL=1` now prints
received report identity/frame/sequence and every successfully paired match.
It changes diagnostics only, not the comparison, sampling, packet format, or
mismatch policy. Leave the variable unset for normal logging.

A fresh-save local run matched six startup snapshots before reaching a modal
save screen outside the selected main-loop boundary. A subsequent bounded run
using the existing isolated QA simulator save produced 44 matching canonical
snapshots, last sequence 488880, through host callback frame 16440. No mismatch
or unpaired-snapshot records appeared. The visible host reached title and
attract-mode gameplay. This verifies sampled same-build local determinism for
that route, not a player-controlled online match, cross-platform synchronization,
network latency, audio, or physical-device acceptance.

The direct mixed-revision test hosted v1.00 and joined with v1.02. The guest
exited with code 12 (`CompatibilityMismatch`) before opening its lobby or
loading its module. The host was stopped normally after the bounded test.
Private evidence: `peer-r2-trace-summary.json`, `peer-r2-*.log`, and
`peer-mixed-*.log` under `ref/revision-102/`. The iPad installation recheck still
reported a locked device; no installed MeleePad app was replaced.


## Cross-platform and input follow-up (2026-09-08)

A bounded macOS-host/iOS-Simulator-guest run produced 109 matching canonical
snapshots through callback frame 10680 (last sequence 1931580), with no mismatch
records. This adds cross-platform evidence for the observed title/attract route;
a player-controlled online match and physical-device latency remain open.
Private evidence: `cross-summary.json` and `cross-host.log`.

Both revision-specific device modules now build and carry verified DOL identity
sidecars. The isolated Revision QA device app was staged with both and its
signature verified. Physical installation still requires the paired iPad to be
unlocked; the installed production app has not been replaced.

The reverse Simulator-host test confirms that a touch Start press reaches
`NetPlayClient::PollLocalPad` as button value `0x1000` on local/game pad 0.
The title-screen transition has not yet been established. Optional
`MELEEPAD_NETPLAY_TRACE_INPUT=1` diagnostics record button/connection changes at
local polling and after dequeueing synchronized input, so the next investigation
can distinguish input delivery from the guest game's response. This does not
change controller bindings, input timing, or the network protocol. Leave it
unset outside diagnostics. Private evidence: `sim-input-stderr.log`.


The subsequent delivery-trace run confirmed Start at both local polling and
synchronized dequeue (`0x1000`, game pad 0). UI observation then verified
leaving attract mode, entering the main menu, navigating to Versus/Melee, and
selecting Fox with the Simulator touch controller. The macOS peer visibly
showed the same selected fighter. Thus the earlier failure to advance has not
been reproduced as a controller defect; no input behavior change was made.
Remote keyboard control and completing a controlled match remain unverified.
This run recorded 64 matching snapshots before/menu transitions, with no
mismatch records at the checkpoint; those samples do not cover every menu
state. Private evidence: `sim-delivery-stderr.log` and
`cross-guest-delivery.log`.


## Physical boot and keyboard configuration (2026-09-08)

The iPad became available. The separately signed `com.meleepad.RevisionQA` app
installed successfully with both revision modules. Only its new private
container was provisioned with extracted v1.02 data and an initial revision
preference; no production container was changed. Reading its executable back
verified the catalog SHA-256. QuickTime showed the app progress from first-frame
loading to Melee's new-save prompt. This proves physical v1.02 boot, but not
physical import UX, touch responsiveness, gameplay performance, speaker audio,
or v1.00 regression acceptance. QuickTime routes audio through HDMIOutput, so a
separate unmirrored speaker check remains necessary. The user has been asked
for a hands-on match. Private evidence: `device-qa-runtime.log` and
`device-qa-transfer.log`.

The macOS test's explicit Quartz keyboard selection received SDL gamepad
bindings. Patch 0025 generates Dolphin's macOS keyboard defaults for that exact
device, retaining existing SDL and pipe mappings. The focused controller-config
regression test, full repository checks, and rebuilt macOS package layout pass.
The launcher's picker remains SDL-only; this change addresses the explicit
netplay runner keyboard path. Runtime keyboard acceptance is being checked separately.


## Branding and timing divergence follow-up (2026-09-08)

The user identified the macOS SunPad icon and KirbyRecomp lobby title. The
packager now copies MeleePad's existing original icon; the lobby uses the
configured frontend product name. Package checks verify the icon bytes and
MeleePad lobby title in the rebuilt runner. Full repository checks and macOS
package/signature checks passed; the live window was observed as
"MeleePad Netplay Lobby" after rebuild.

A fresh-profile keyboard/netplay run generated the corrected Quartz bindings,
but CUA key presses did not produce logged local button changes. Runtime
keyboard acceptance remains open. The preserved old profile was intentionally
not overwritten; the fix affects newly generated profiles.

The same cross-platform run exited to its lobby with a desync at callback frame
6120. Two canonical comparisons diverged only in timebase: sequence 374160
(delta -2160) and sequence 375540 (delta -1287). CPU state/integer/FPR/paired and
RAM hashes match in those records. This is a failed timing/determinism gate,
not a passing match or proof that timing differences are harmless. Earlier
bounded matching runs remain scoped to their sampled routes. Preserve the
comparison policy while investigating the source of timing divergence.
Private evidence: `cross-keyboard-clean-summary.json`,
`sim-keyboard-clean-stderr.log`, and `cross-guest-keyboard-clean.log`.


## Boundary-clock diagnostic follow-up (2026-09-08)

Patch 0054 adds opt-in `MELEEPAD_NETPLAY_TRACE_BOUNDARY_CLOCK=1` output at the
existing sampled boundaries: cached/live timebase, burst base/cycles, and
Dolphin downcount. It changes no timing or comparison behavior. Both desktop and
Simulator builds compile; the bounded five-minute cross-platform run paired
4,200 clock samples with identical cached values between peers. Within either
peer, cached minus live timebase ranged from -1 to 0 ticks, with no larger
sampling offset. This run reached Classic character selection via touch input;
it did not reproduce the earlier timebase divergence or complete a match.
The harness ended at its timeout and both test peers were stopped. A longer
controlled gameplay reproduction is still required. Private evidence:
`sim-clock-stderr.log`, `cross-guest-clock.log`, and
`analyze-boundary-clocks.py`.

The new Quartz profile now follows MeleePad's existing packaged WASD/J/K layout
instead of introducing Dolphin's different defaults. Existing custom profiles
remain preserved; the focused generator regression test passes.


## Controlled route and reproduced divergence (2026-09-08)

The longer Simulator-host/macOS-guest run reached Classic character selection
with touch input, selected Fox, and reached Stage Clear. Both visible peers
showed the same 77,700 score, time bonus 27,800, damage 0, and bonus list. The
battle itself occurred between screenshots; this is observed matching results,
not continuous gameplay or two-player-input acceptance.

Continuing from results reproduced the failure. There were 37 matching report
comparisons before two divergent comparisons: sequence 416580 differed in
timebase (+16731 ticks in the report), then 470460 differed in timebase, CPU
state and sampled RAM (first differing RAM region at 0x80400000). The denser
clock trace identifies the first paired clock difference at sequence 414720:
Simulator cached/live 34108812678687225 versus macOS cached/live
34108812678702669, a 15444-tick difference. Each peer's cached/live difference
remained at most one tick across the run, ruling out a large cached-clock
reporting offset for this reproduction. The prior matching boundary was
414660, before the long results-screen gap. This needs an execution/scheduling
investigation across that gap; comparison tolerances must not be widened.

Pinned decomp symbols identify diagnostic live PC 0x8034738C as
`OSRestoreInterrupts`, and the sampled caller boundary 0x800195D0 as
`lb_800195D0`. The live PC is contextual, not the canonical comparison point.
Source review confirms netplay syncs GPU timing settings and requests GPU
determinism during BootManager initialization, but effective runtime settings
and dispatch/fallback paths still need measurement. Both test peers were
stopped after preserving evidence. Private files: `sim-match-stderr.log`,
`cross-match-guest.log`, `cross-match-summary.json`, and
`analyze-match-clocks.py`.


## Focused execution-path follow-up (2026-09-08)

The scheduling trace now logs effective dual-core, deterministic-GPU, GPU sync,
idle sync, distance and overclock settings once at the first sampled boundary.
Simulator and macOS builds plus repository checks pass. No runtime scheduling
policy changed.

Source inspection found an execution-path difference: desktop initializes
`JitArm64` fallback unless `STATICRECOMP_NO_FALLBACK_JIT` is set, while iOS
excludes it at compilation. Prior cross-platform test scripts did not set that
variable. The existing override can isolate this difference without changing
production behavior. A private `cross-parity.py` harness is prepared with it,
but the comparison has not run yet. The idle Simulator host was stopped.
The next test should exercise the known results-to-next-stage transition with
matched interpreter fallback before adding more diagnostics or claiming a fix.


## Automatic fallback parity policy (2026-09-08)

The diagnostic override run reached visible Fox-versus-Samus gameplay, Stage
Clear, and the next team stage on Dream Land. Its 21,850 paired sampled boundary
clocks matched exactly, with no divergent canonical reports observed. Both
peers logged identical effective GPU/CPU scheduling settings. Opponent and
stage selection differed from the failing run, so this is supporting evidence
for fallback parity rather than a controlled proof that every desync is fixed.

Build 9 now automatically selects interpreter fallback during netplay on
desktop, matching iOS's existing execution contract. The normal offline desktop
path remains unchanged. Native transport and iOS discovery both advance to
compatibility prefix 10, preventing old builds from joining the changed policy.
The existing dependency bootstrap passes; the new runtime patch passes a
reverse/forward application round trip. Repository checks, Simulator app build,
and macOS package checks pass. Private override evidence: `sim-parity-stderr.log`,
`cross-parity-guest.log`, and `analyze-parity-clocks.py`.

A fresh build-9 Simulator-host/macOS-guest run explicitly removes the diagnostic
override and confirms both peers log `netplay fallback=interpreter`. It reaches
actual Classic gameplay with touch movement and attack input. The bounded run ended with 23,318 paired timing samples and 80 canonical
comparisons matching, with no divergent reports. Fox-versus-Link gameplay and
a round restart were visible; the specific Stage Clear-to-next-stage route
was not reproduced in this run and remains open. Both peers were stopped.
Private evidence: `sim-policy-stderr.log`, `cross-policy-guest.log`, and
`analyze-policy-clocks.py`.
Sampling only covers the existing canonical boundaries and selected RAM; it
is not a per-frame, full-memory proof. Physical gameplay, two-human-player
input, audio, and sustained performance remain separate acceptance work.


Build-9 device compilation also passes. The public packager correctly rejects
the local app with its generated module; a separate module-free copy passes
the archive audit. Private IPA SHA-256:
`650dd0cb65f132b3b4f40d0c2feb8b3f166d788bc7a5a3dfbad5ae12a5c8333d`.
Nothing was published or installed over the owner's physical app. The installed
Revision QA app remains build 8 and cannot join build-9 peers.

The rebuilt native mixed-revision test again rejects the v1.02 guest against
a v1.00 host during compatibility validation (guest exit 12, before module
load). The final repository check run passes.


## Build-9 upgrade-path audit (2026-09-08)

An existing build-8 dependency checkout still has transport prefix 9. Rewriting
the earlier prefix-8 patch directly to 10 would fail on that checkout. Restore
the original 8-to-9 patch and compose a new 9-to-10 patch; the earlier patch
recognizes the retained final marker on repeated bootstrap. Actual bootstrap
helpers were exercised in isolated directories with prefixes 8, 9, and 10: all
reach the exact current source and pass a second run. An unexpected prefix 999
is rejected without modifying the file. The real checkout bootstrap passes.

A separate private build-9 Revision QA candidate was staged with both verified
revision modules and signed; strict nested signature verification passes. The
iPad still has two MeleePad processes running, so this candidate was not
installed over an active session. Its path is
`ref/revision-102/build9-device-qa/MeleePad.app`. Existing app data and the
installed build-8 QA app remain unchanged.
