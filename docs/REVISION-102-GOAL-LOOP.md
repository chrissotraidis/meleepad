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
| R1 Build separation | Independently prepare both revisions without overwriting active v1.00 module or extraction; compile v1.02 | Passed: separate r0/r2 extraction and module stores; Simulator/device r2 modules built; macOS 14 module rebuilt and packaged |
| R2 Runtime correctness | Audit every revision-specific address, input hook, idle shortcut and diagnostic write; verify v1.02 against executable/source | Implemented: revision-specific waits and scene address; legacy diagnostic writes gated to r0; runtime boot and input observed |
| R3 Import and selection | Preferred-version explanation, validated imports, independent storage, module selection, legacy migration | Passed in Simulator: both actual imports, both selection directions, accurate labels; r2 save unchanged after r0 import |
| R4 Online identity | Actual selected revision in discovery and transport; reject mixed revisions/builds/mods; positive and negative tests | Identity implemented; service tests pass for mixed-revision rejection and matching-r2 acceptance; two local r2 peers passed compatibility and booted matching modules; synchronized gameplay not yet accepted |
| R5 Product acceptance | Build both Apple targets; visible import, boot, controls, match/results, audio, lifecycle; preserve v1.00 | Simulator r2: save creation, menus, character select, Classic match and stage results observed; r0 boot/save and return to r2 passed. Device app builds; separate QA app signed; install blocked by locked iPad |
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
  Simulator modules and the v1.02 device module compile with matching identity
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
