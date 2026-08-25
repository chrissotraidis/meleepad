# ssbmpad journal

Append-only execution ledger. Claims are limited to observed evidence.

## 2026-08-24 — G0 environment audit

- Goal: establish the exact host, immutable inputs, reference state, and lowest
  unmet goal before any build work.
- Commands: `xcrun simctl list devices booted`; process audit; ROM header read;
  `shasum -a 1`; `shasum -a 256`; tool version checks; `git -C ref/sunpad`
  status/revision; mandated SunPad documentation and script review.
- Result: **PARTIAL**. Host tools and the read-only SunPad reference are ready.
  The supplied raw ISO is valid `GALE01`, disc 0, revision 0, but differs from
  the PRD's expected v1.02 image. No Simulator or stale game process was found.
  Required toolchain/reference clones are not yet present.
- Evidence: `docs/artifacts/2026-08-24/g0-environment.md`.
- Next: clone and pin the required repositories, apply SunPad's reviewed Apple
  runtime patch snapshots without modifying `ref/sunpad`, then build the tools.

## 2026-08-24 — G0 dependency closure

- Goal: make the local build reproducible without modifying the read-only
  SunPad reference.
- Work: pinned ModernGekko, Dolphin/RecompCore, DolRecomp, RecompCore, the
  ModernGekko Template, melee, and m-ex under ignored `ref/`; added bootstrap,
  extraction, repository-safety, and macOS packaging scripts.
- Result: **PASS**. Exact revisions are recorded in `docs/STATUS.md`; the
  revision-0 retail input is supported by hash rather than silently treated as
  the PRD's revision-2 target.

## 2026-08-24 — G1 SMC analysis

- Goal: classify DolRecomp's 128 detected ranges before producing a module.
- Work: extracted `main.dol`; ran the GameCube/Gekko C backend; decoded all
  ranges and inspected `icbi`, store, halfword, and float-store sites against
  function/control-flow boundaries.
- Result: **PASS**. No runtime code generator was proven. The patch list stays
  empty and the runtime SMC hash guard is retained. Runtime shutdown later
  reported `smc_failed=0`.
- Evidence: `docs/artifacts/2026-08-24/g1-smc-report.md`.

## 2026-08-24 — G2 arm64 module and macOS package

- Goal: link the revision-0 module and produce a ROM-safe native app bundle.
- Work: compiled 237 generated chunks; linked the arm64 dylib; integrated the
  frontend/runner; packaged and ad-hoc signed the app; verified architecture,
  deployment target, export, dependencies, signature, and ROM absence.
- Result: **PASS**. The module loads at entry `0x8000522C`.
- Integration fixes: removed the launcher's unsolicited Documents scan and
  changed its blocking child wait into an event-pumping nonblocking wait.
- Evidence: `docs/artifacts/2026-08-24/g2-module-and-package.md`.

## 2026-08-24 — G3 title boot

- Goal: prove a real title boot and an input-caused transition on macOS.
- Work: launched the packaged frontend and runner, created first-boot game
  data, reached the Melee title, retained title and native Quartz A-transition
  screenshots, and inspected module/runtime logs.
- Result: **PASS**, narrowly scoped to title plus input transition.
- Evidence: `docs/artifacts/2026-08-24/g3-macos-title-and-input.md`.

## 2026-08-24 — G4 controlled-play investigation

- Goal: enter and control a real CSS -> 1v1 match with audio.
- Work: replayed Quartz with separated button mappings; distinguished attract
  battles from user-controlled play; exercised the reference FIFO with the
  writer connected after boot and before boot; verified one frontend/one
  runner and clean shutdowns.
- Result: **IN PROGRESS**. Neither replay produced a reliable port-1 edge.
  Attract battles are not gameplay evidence. Cubeb initialization is proven;
  audible output is not.
- Restored state: shipped Quartz Application Support profile, background input
  false, zero SsbmPad processes, zero booted Simulators.
- Evidence: `docs/artifacts/2026-08-24/g4-input-investigation.md`.

## 2026-08-24 — G4 clean controlled match

- Goal: prove packaged native macOS playability from Character Select through
  a complete controlled 1v1, including a live audio path.
- Work: corrected the reference FIFO parser/binding, removed temporary tracing,
  repackaged and verified the app, selected Kirby and CPU Samus, launched Venom,
  replayed movement/attack/jump inputs, and retained the results screen. Sampled
  the live runner while it pushed streaming samples through Cubeb/CoreAudio.
- Result: **PASS**. The clean match reached results without a crash. The package
  remained ROM-safe and ad-hoc-signature verification passed.
- Evidence: `docs/artifacts/2026-08-24/g4-controlled-match.md` and retained PNG/
  process-sample artifacts beside it.
- Next: G5 exact frame-time baselines on Final Destination and Fountain of
  Dreams; the Venom match's roughly 12.5-13.0 FPS is a hard failure signal.

## 2026-08-24 — Goal-stack extension

- User requirement: add working netplay as an explicit end-of-loop deliverable.
- Result: added G9 after the existing test-matrix gate. Acceptance requires the
  ssbmpad Host/Join shell and a completed synchronized two-instance match with
  at least one iPadOS endpoint; macOS-only button or connection evidence is not
  sufficient.

## 2026-08-24 — G5 ThinLTO correction

- Goal: optimize the measured generated-module CPU bottleneck without changing
  emulation semantics.
- Finding: the Clang cache identity claimed ThinLTO, but forced Ninja response
  files made CMake's Apple IPO probe fail at `/usr/bin/ar @response-file`; the
  production module had no `-flto` compile or link flags.
- Work: restored platform-default response-file behavior on Apple, added that
  policy to the cache identity, built the normal O2 + ThinLTO artifact through
  `moderngekko-port`, and compared aligned exact frame intervals. Also tested
  O3 + native tuning and rejected it because it was no faster.
- Result: **PARTIAL**. Frames 2001-3500 improved from 20.247 ms mean / 26.069 ms
  p95 to 17.703 ms / 21.207 ms (12.6% and 18.6%). This remains above the 16.7 ms
  target and is not a required-stage trace, so G5 stays open.
- Evidence: `docs/artifacts/2026-08-24/g5-thinlto-investigation.md` and the raw
  traces named there.

## 2026-08-24 — G5 Fountain baseline and isolated PGO

- Goal: measure a required G5 stage, classify its bottleneck, and test the
  highest-confidence generated-module optimization without changing product
  state prematurely.
- Work: established a reproducible FIFO route to Fountain; captured a clean
  two-minute match, built an isolated profile-instrumented O2 + strict-FP +
  ThinLTO module, trained it through real Fountain combat, merged 6,531-function
  profile data, built a profile-use candidate, and ran exact clean/candidate
  Yoshi-versus-CPU-Ice-Climbers comparisons. Rotated logs before launch and
  bounded combat windows by cumulative presented-frame time.
- Result: **PARTIAL / NOT RETAINED**. Clean Fountain is CPU-bound and fails G5.
  PGO improved the exact 110-second pair by 8.5% median, 10.0% p95, and 15.4%
  p99, with frames over 40 ms falling from seven to one, but its isolated worst
  frame regressed from 86.467 ms to 129.740 ms. Final Destination is also locked
  and unmeasured. The clean module SHA
  `5bbd12e0704d6ce2221603d3fc016eb9aba88756b88d2139809c8b6ee1b09b82`
  was restored and the app re-signed; no runner or Simulator remains active.
- Evidence: `docs/artifacts/2026-08-24/g5-fountain-pgo-investigation.md` and the
  raw traces named there.
- Next: use the merged profile to reduce the generated dispatch/memory-access
  hot path with one falsifiable change, replay Fountain, and establish a
  ROM-safe save/unlock setup for the Final Destination comparison.

## 2026-08-24 — G5 no-EXRAM specialization

- Goal: test one small generated-memory hot-path specialization without
  changing Wii behavior or retaining an unproven product flag.
- Work: added a default-off GameCube-only `get_ram_ptr` branch and focused
  normal/specialized tests, built the module in isolation, proved FIFO-to-pad
  input with temporary tracing, and replayed an equal 105-second Yoshi-versus-
  CPU-Ice-Climbers Fountain pair with the same workload.
- Result: **NOT RETAINED**. Mean/median/p95/p99 improved 3.0-4.4%, below the 5%
  threshold, while worst regressed from 1320.456 ms to 1385.798 ms. The
  recurring approximately 1.3-second hitch now appears across clean, PGO, and
  specialized runs.
- Cleanup: removed the specialization, extra tests, and trace hooks; normal
  GXRuntime tests pass; restored and verified clean module SHA
  `5bbd12e0704d6ce2221603d3fc016eb9aba88756b88d2139809c8b6ee1b09b82`;
  no runner or Simulator remains active.
- Evidence: `docs/artifacts/2026-08-24/g5-noexram-investigation.md` and the raw
  equal-window traces named there.
- Next: time-correlate and attribute the approximately 1.3-second hitch before
  another steady-state optimization, while separately solving the ROM-safe
  Final Destination save/unlock setup.

## 2026-08-24 — G5 measurement correction

- Goal: determine whether the recurring approximately 1.3-second frames belong
  to the game or to the evidence workflow.
- Work: found `std::endl` in Dolphin's per-frame benchmark logger, retained a
  reproducible buffered-newline dependency patch, rebuilt the native arm64
  runner, and ran Yoshi versus level-1 CPU Ice Climbers on Fountain with no
  capture or sampling inside the selected 90-second controller-only interval.
- Result: **MEASUREMENT FIX RETAINED; G5 STILL OPEN**. The corrected interval
  measured 18.187 ms mean / 17.903 ms median / 21.168 ms p95 / 21.999 ms p99 /
  55.135 ms worst. It did not reproduce the approximately 1.3-second hitch;
  the full exploratory log's multi-second events correlate with visual
  checkpoints. Sustained Fountain timing still exceeds 16.7 ms.
- Evidence: `docs/artifacts/2026-08-24/g5-render-logging-control.md` and
  `g5-buffered-clean-yoshi-ice-fountain-90s-render-times.txt`.
- Cleanup: clean GALE01 module SHA unchanged; runner and frontend stopped; no
  Simulator booted.
- Next: rerun a matched buffered clean-versus-PGO Fountain pair without visual
  capture inside either measured interval, then retain or reject PGO from the
  corrected tail behavior.

## 2026-08-24 — G5 corrected PGO replay

- Goal: decide PGO from a matched, non-perturbing required-stage comparison.
- Work: replayed the exact Yoshi-versus-level-1-CPU-Ice-Climbers Fountain
  workload with buffered logging and no visual action inside either 90-second
  interval; rebuilt the same profile-use module for macOS 14 and ran a
  30-second portability confirmation.
- Result: **LOCAL PGO RETAINED; G5 STILL OPEN**. PGO improved mean 8.3%, median
  6.8%, p95 20.4%, p99 22.6%, and worst 17.6%; threshold frames rose from
  13.38% to 61.03%. The portable confirmation matched at 16.683 ms mean /
  16.682 ms median / 16.875 ms p95 / 21.963 ms worst. This still fails the
  16.7 ms p95/p99/worst requirement.
- Boundary: the portable module is the best-known local app module, SHA-256
  `a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.
  Its local ROM-trained profile is not a committable shipping input.
- Evidence: `docs/artifacts/2026-08-24/g5-fountain-pgo-investigation.md` and
  corrected clean/PGO raw traces named there.
- Cleanup: runner and writer stopped; no Simulator booted.
- Next: use the PGO binary as an oracle for one static hot-loop-inlining
  experiment, then continue real p99/worst reduction and unlock Final
  Destination.

## 2026-08-24 — G5 static hottest-loop reproduction

- Goal: reproduce the clearest PGO code-generation difference with one small,
  distributable static change.
- Work: forced generated `loop_80349494` to inline, rebuilt the complete macOS
  14 arm64 O2 + ThinLTO module, verified that the helper symbol disappeared,
  and replayed the exact 90-second Yoshi-versus-level-1-CPU-Ice-Climbers
  Fountain workload without capture or sampling inside the interval.
- Result: **NOT RETAINED**. The candidate measured 18.763 ms mean / 18.293 ms
  median / 22.040 ms p95 / 24.031 ms p99 / 1296.873 ms worst, with 23.56% of
  frames at or below 16.7 ms. Its steady-state distribution is worse than the
  clean buffered control, so this helper alone does not explain the PGO gain.
- Cleanup: restored the generated source and cached clean module byte-for-byte;
  restored and verified the signed portable PGO app module SHA-256
  `a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`;
  no runner, writer, or Simulator remains active.
- Evidence: `docs/artifacts/2026-08-24/g5-fountain-pgo-investigation.md` and
  `g5-buffered-inline-loop-yoshi-ice-fountain-90s-render-times.txt`.
- Next: compare the remaining PGO-eliminated helpers and layout decisions for
  the next smallest static experiment, while completing the ROM-safe Final
  Destination unlock path.

## 2026-08-24 — G5 Final Destination unblock and trace

- Goal: remove the Final Destination blocker without changing the retail image
  and establish the second required-stage distribution.
- Work: backed up the real GCI; rejected a fresh generated save with locked
  stages; rejected the revision-2 m-ex hook address on revision 0; mapped the
  matching revision-0 stage-check function to `0x80163C28`; set the live
  eleven-bit stage mask in an isolated save; let Melee persist it; and proved
  the unlock survived a full no-mod restart. Then replayed the exact Yoshi-
  versus-level-1-CPU-Ice-Climbers workload on Final Destination with the
  portable PGO module and no visual action inside the selected 90 seconds.
- Result: **STAGE BLOCKER CLOSED; G5 STILL OPEN**. Final Destination measured
  16.941 ms mean / 16.678 ms median / 16.946 ms p95 / 17.189 ms p99 /
  1385.242 ms worst. Median meets 16.7 ms, while p95, p99, and worst fail.
- Cleanup: temporary mod and generated GCI remain outside the repository; the
  user's main GCI was restored byte-for-byte; no runner, writer, or Simulator
  remains active.
- Evidence: `docs/artifacts/2026-08-24/g5-final-destination.md` and
  `g5-buffered-pgo-yoshi-ice-final-destination-90s-render-times.txt`.
- Next: reduce the shared PGO tail on Fountain and Final Destination, and make
  the unlock setup repository-native without distributing save or ROM data.

## 2026-08-24 — G5 outlining and timer experiments

- Goal: test whether PGO primarily benefits from outlined loop helpers or
  whether the narrow 16.7 ms tail is caused by macOS timer overshoot.
- Work: built an all-969-loop `noinline` module; then restored it and ran a
  default-off Apple Silicon precise-spin timer against the default timer in
  matched cumulative 60-150 second no-input attract windows. Temporary FIFO
  and pad traces also proved `A=0x0100` and `Start=0x1000` reached port 1; all
  traces and the rejected Always Connected profile flag were removed.
- Result: **BOTH NOT RETAINED**. Blanket outlining collapsed an active attract
  battle to 4.1 FPS. Precise-spin moved render p95 only from 17.848 ms to
  17.841 ms and p99 from 18.814 ms to 18.696 ms while multi-second tails
  remained. That does not justify its approximately 1 ms/frame spin cost.
- Cleanup: generated sources, clean cache, default timer, user controller
  profile, and signed portable PGO app were restored; no process or Simulator
  remains active.
- Evidence: `docs/artifacts/2026-08-24/g5-outline-and-timer-experiments.md`
  and the four selected raw traces named there.
- Next: correlate the next large required-stage tail with compute,
  shader/pipeline creation, audio, and host scheduling before changing code.

## 2026-08-24 — G5 timing attribution and PGO/no-EXRAM composition

- Goal: identify whether the remaining tail is compute or host pacing, then
  test the smallest previously positive optimization in combination with PGO.
- Work: temporarily correlated render timestamps with CPU work, requested
  throttle sleep, and host-clock deltas; restored that instrumentation; built
  a complete macOS 14 arm64 O2 + ThinLTO PGO module with only the GameCube-only
  MEM2 branch eliminated; and ran a matched cumulative 60-150 second no-input
  attract diagnostic.
- Attribution: frames above 17 ms averaged 16.757 ms CPU work and 2.562 ms
  requested sleep. The sustained tail is primarily generated-module compute;
  large transitions can combine excess work and catch-up sleep.
- Result: **NOT RETAINED**. The combined candidate left median unchanged at
  16.683 ms and regressed p95 from 17.848 ms to 19.335 ms and p99 from 18.814
  ms to 20.477 ms. That rejects the combination before expensive Fountain and
  Final Destination replays.
- Cleanup: temporary source changes were restored byte-for-byte; the signed
  portable-PGO module SHA-256 `a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`
  and native runner SHA-256 `d2642b463a41e0a94a3cc2869b836ed3ab5cb7777eb0ea9d9f0240c7c760cff6`
  were restored; no runner or Simulator remains active.
- Evidence:
  `docs/artifacts/2026-08-24/g5-timing-attribution-and-pgo-noexram.md`
  and the three raw traces named there.
- Next: use PGO as an oracle for one smaller static compute-path decision, then
  require both real stages to improve before retaining it.

## 2026-08-24 — G5 generated loop-cycle budget

- Goal: reduce the dominant polling helper's repeated returns to the host
  dispatcher without profile data or forced inlining.
- Work: built a complete profile-free macOS 14 arm64 O2 + ThinLTO module with
  only `DOLRECOMP_C_LOOP_CYCLE_BUDGET` raised from 256 to 1024, then ran the
  matched cumulative 60-150 second no-input attract diagnostic.
- Result: **NOT RETAINED**. Median regressed to 16.757 ms, p95 to 22.926 ms,
  p99 to 24.989 ms, and the <=16.7 ms share fell to 44.77%. Vblank regressed in
  parallel. Wider host timing-check latency overwhelms reduced dispatch cost.
- Cleanup: default budget and signed portable-PGO module restored exactly; no
  runner or Simulator remains active.
- Evidence: appended to
  `docs/artifacts/2026-08-24/g5-timing-attribution-and-pgo-noexram.md`, plus
  the two raw budget-1024 traces named there.
- Next: do not sweep intermediate budgets without a narrower timing mechanism;
  continue with PGO-guided static compute-path differences.

## 2026-08-24 — G5 exact PGO-cold helper outlining

- Goal: reproduce PGO's cold helper separation without the hot-helper damage
  caused by blanket `noinline`.
- Work: confirmed all 247 PGO-only loop symbols had profile entry counts zero
  through nine; forced exactly those helpers `noinline` across 55 chunks;
  verified all intended symbols and the unchanged hot polling helper in a full
  profile-free macOS 14 O2 + ThinLTO module; and ran the matched attract
  diagnostic.
- Result: **NOT RETAINED**. Median/p95/p99 regressed to
  16.814/21.459/22.548 ms and the <=16.7 ms share fell to 43.68%. Symbol
  outlining alone does not reproduce PGO's branch-weight and block-layout win.
- Cleanup: all generated chunks restored byte-for-byte; signed portable-PGO
  app restored exactly; no runner or Simulator remains active.
- Evidence: appended to
  `docs/artifacts/2026-08-24/g5-timing-attribution-and-pgo-noexram.md`, plus
  the two raw cold-outline traces named there.
- Next: broaden the local PGO training set across both required stages instead
  of continuing static symbol imitation.

## 2026-08-24 — G5 balanced Fountain/attract PGO corpus

- Goal: add internal branch/block coverage without diluting the original
  required-stage PGO tuning.
- Work: preserved the original 43 MiB Fountain profile; collected a separate
  cleanly flushed three-minute attract profile; merged Fountain 2:1 over
  attract; built a clean-source portable macOS 14 O2 + ThinLTO module; and ran
  the matched attract diagnostic.
- Result: **NOT RETAINED**. p95 improved modestly from 17.848 to 17.682 ms and
  vblank tail improved, but render mean regressed from 17.528 to 17.744 ms and
  p99 from 18.814 to 20.654 ms. That fails the retention rule and does not
  justify required-stage replay.
- Cleanup: signed original Fountain-PGO app restored exactly; no runner or
  Simulator remains active. Both raw profiles and merged profile remain local
  and uncommitted.
- Evidence: appended to
  `docs/artifacts/2026-08-24/g5-timing-attribution-and-pgo-noexram.md`, plus
  the two raw combined-PGO traces named there.
- Next: repair/re-establish the controlled FIFO route and train directly on
  both Fountain and Final Destination; generic attract coverage is rejected.

## 2026-08-25 — G5 controller-route recovery and required-stage PGO

- Goal: re-establish deterministic controller automation, collect direct Final
  Destination coverage, and decide whether a balanced required-stage profile
  improves the retained Fountain-only PGO build.
- Work: traced one temporary Pipe -> GCPad -> SI button edge; confirmed the
  original route was correct after the native input gate opened; removed all
  traces; used two isolated FIFO devices and a ROM-safe local save for visible
  Fountain and Final Destination 1v1s; collected a clean Final Destination
  profile; merged Fountain 2:1 over Final Destination; and built a complete
  macOS 14 O2 + strict-FP + ThinLTO candidate.
- Result: **INPUT ROUTE RECOVERED; PGO CANDIDATE NOT RETAINED**. On the matched
  1,000-frame attract screen, median/p95 regressed from 16.684/18.077 ms to
  16.778/18.383 ms, worst rose from 19.088 to 57.091 ms, and the <=16.7 ms
  share fell from 50.80% to 46.60%.
- Cleanup: all trace hooks were removed, the normal save was untouched, and
  the signed Fountain-PGO module and native runner were restored to their exact
  retained hashes. No runner or Simulator remains active.
- Evidence:
  `docs/artifacts/2026-08-25/g5-fountain-fd-pgo-and-input-route.md` and the four
  selected raw traces named there.
- Next: preserve the Fountain profile's useful branch/block weighting and
  target the generated compute tail directly; retain nothing until both
  required stages and the strict worst-frame requirement improve.

## 2026-08-25 — G5 revision-0 scheduler idle attribution

- Goal: identify the dominant `loop_80349494` work from the actual GALE01
  revision-0 module and remove only proven host-side waste.
- Work: rejected revision-2 symbol maps for the revision-0 disc; traced the
  address in generated r0 source to the scheduler's `RunQueueBits == 0` idle
  loop; enabled Dolphin's existing `StaticRecompIdlePC` facility through a
  revision-specific game-settings patch; verified the idle PC disappeared from
  the shutdown dispatch histogram; and replayed native profile-free and PGO
  builds with the same isolated user directory.
- Result: **OPTIMIZATION RETAINED; G5 STILL OPEN**. The PGO screen improved
  p95/p99/worst from 18.077/18.721/19.088 ms to
  17.824/18.186/18.987 ms, while median and <=16.7 ms share were slightly worse.
  Profile-free four-player scenes remained around 40-55 FPS and Jungle Japes
  reached 16.9 FPS. The setting removes dominant idle dispatch work but does
  not solve active combat.
- Input boundary: a live one-port P1 Bowser versus CPU Mario route reached
  stage select. The old exploratory Final Destination cursor sequence visibly
  selected Battlefield and was rejected. Fixed-delay boot automation also
  confused the non-interactive opening title card with the real title prompt;
  future profiling must visually gate both title and stage.
- Evidence: `docs/artifacts/2026-08-25/g5-gale01r0-idle-loop.md` and the two raw
  profile-free traces named there.
- Cleanup: no runner or Simulator remains active. The retained production app
  and local Fountain-PGO module hashes are unchanged.
- Next: collect a visually verified Fountain/Final Destination combat-only PGO
  corpus with idle skipping enabled, then compare both required stages.

## 2026-08-25 — G5 combat PGO rejection and Fountain visual attribution

- Goal: train on visually verified required-stage combat, measure the resulting
  candidate without capture contamination, and preserve the user's reported
  Fountain warping as a promotion-blocking defect.
- Work: fixed the Pipe controller focus gate; completed two-minute Fountain and
  Final Destination CPU matches; merged their profiles 2:1; built a clean
  macOS 14 O2 + strict-FP + ThinLTO candidate; completed a normal-speed Fountain
  match; and retained the full render/vblank logs. Replayed the same scene with
  the profile-free module, accurate EFB-to-RAM copies, and non-deferred texture
  copies, changing one graphics setting per control.
- Result: **CANDIDATE REJECTED; `VISUAL-001` NARROWED BUT OPEN**. The capture-free
  Fountain interval measured 16.953 ms mean / 16.688 ms median / 18.494 ms p95 /
  21.445 ms p99 / 1334.501 ms worst, so it fails G5 despite a 59.9 FPS title
  counter. Normal-speed PGO and profile-free controls both show corrupted lower
  reflection imagery. RAM and non-deferred EFB controls did not fix it and
  materially reduced performance. The evidence points to a shared Fountain
  reflection / EFB-copy renderer path below those high-level switches; real
  fighter-mesh morphing still requires a short fresh video to classify.
- Cleanup: both graphics experiments were reverted to the baseline defaults;
  the trace-free runner is retained; no runner or Simulator remains active.
- Evidence: `docs/artifacts/2026-08-25/g5-fountain-visual-warping.md`,
  `g5-combat-pgo-fountain-render-times.txt`, and
  `g5-combat-pgo-fountain-vblank-times.txt` in the same artifact directory.
- Next: compare the scene with the reference renderer, then instrument or fix
  the smallest shared Metal texture-cache / EFB-copy mismatch. Remeasure
  Fountain and Final Destination only after visual parity is restored.
