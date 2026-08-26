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

## 2026-08-25 — G5 Fountain reference-parity correction

- Goal: decide whether the reported Fountain lower-surface distortion is an
  ssbmpad renderer defect or reference behavior.
- Work: ran the pinned runtime without a generated module using
  `--allow-interpreter`; then fetched, signature-checked, and ran official
  Dolphin 2606a from a temporary non-installed app copy. Both controls used
  Metal, native internal resolution, separate user/save directories, the same
  private GALE01 revision-0 image, and a controlled Fountain match.
- Result: **REFLECTION CLOSED AS REFERENCE PARITY; REAL-MESH REPORT OPEN**.
  Both no-module and official Dolphin controls reproduce the same blurred and
  blocky lower Fountain reflection. The earlier EFB-copy experiments targeted
  normal stage behavior and remain rejected. The original single Bowser/DK
  overlap frame does not prove actual mesh deformation; a short time-adjacent
  capture is still required for `VISUAL-001B`.
- Cleanup: the official reference process required SIGKILL after its batch
  window closed and ignored SIGTERM; no Dolphin, runner, or Simulator remains.
  The DMG was detached and Jump Desktop Audio restored. No official app was
  installed globally and no game data entered Git.
- Evidence: `docs/artifacts/2026-08-25/g5-fountain-no-module-reference.jpeg`,
  `g5-fountain-official-dolphin-2606a-reference.jpeg`, and
  `g5-fountain-visual-warping.md`.
- Next: capture a fresh real-fighter time sequence if the report recurs, while
  resuming the independent G5 generated-compute tail investigation.

## 2026-08-25 — G5 real-mesh temporal capture and route correction

- Goal: test the remaining fighter-body morph report with time-adjacent native
  gameplay evidence instead of a single overlap frame.
- Work: recorded only the SsbmPad window for 29.985 seconds, retained a 9.8
  second 640x480 gameplay clip, and sampled the interaction interval at 5 FPS.
  The 49-frame dense sheet covers movement, attacks, jumps, specials, CPU
  overlap, hit sparks, and damage. The prelaunch MemoryWatcher also exposed one
  extra `START` in the committed title-to-CSS sequence; that input entered
  1-P Mode, so it was removed and a focused action-order regression added.
- Result: **REAL-MESH DEFORMATION NOT REPRODUCED; AUTOMATION FIX RETAINED**.
  Real Bowser and CPU meshes remain coherent across adjacent frames. The report
  stays monitored and reopens on fresh temporal evidence, but it is not a
  current promotion blocker. The corrected manual route visibly reached VS
  character select; full cold-route replay remains required before calling the
  memory-gated sequence deterministic.
- Cleanup: the 94 MiB source recording was moved outside Git to
  `/private/tmp/ssbmpad-g5-fountain-real-mesh-capture-original.mov`; the 6.2 MiB
  compressed clip and dense sheet are the committable evidence. No runner or
  Simulator remains, and Jump Desktop Audio was restored.
- Evidence: `docs/artifacts/2026-08-25/g5-fountain-real-mesh-capture.m4v`,
  `g5-fountain-real-mesh-dense-contact-sheet.jpeg`, and
  `g5-fountain-visual-warping.md`.
- Next: cold-replay the corrected memory-gated route, then resume the G5
  generated-compute tail experiment on both required stages.

## 2026-08-25 — G5 cold-route predicate audit

- Goal: prove the revised memory-gated title-to-CSS route from a cold launch.
- Work: performed three bounded cold replays while preserving one runtime per
  run. The first exposed the extra `START` by entering 1-P Event Match. The
  second showed the original watched word `0x80477D68` could time out or match
  during attract gameplay. Source attribution then replaced it with
  `gm_80479D30`, the decomp-backed `GameState` routing word, using exact
  `GM_TITLE/GS_TITLE`, `GM_MENU/GS_MENU`, and `GM_VS/GS_CSS` predicates. The
  final bounded replay still fell into How to Play because scene entry occurs
  before title accepts input. `gmtitle.c` proves `gmTitle_804D6714` starts at
  `0x14` and `OnFrame` ignores input until it reaches zero, so an explicit
  `0x804D6714 == 0` wait was added with a focused regression.
- Result: **PARTIAL; AUTOMATION NOT YET DETERMINISTIC**. The action-order,
  authoritative scene word, exact scene predicates, and title lockout gate are
  now source-backed and unit-tested, but the final lockout-aware sequence has
  not been cold-replayed. Per the loop's repetition rule, no fourth launch was
  attempted. Manual FIFO routing remains available and visually verified.
- Cleanup: no runner or Simulator remains; Jump Desktop Audio is restored.
- Evidence: the live 1-P Event Match and How to Play outcomes plus
  `ref/melee/src/melee/gm/gm_1A3F.c`, `gm/types.h`, `gm/forward.h`, and
  `gm/gmtitle.c`; no misleading pass screenshot was retained.
- Next: one future cold replay of the lockout-aware sequence. If it fails,
  capture all watched values and emitted actions to a trace file before any
  further input change. Continue G5 performance work manually in the meantime.

## 2026-08-25 — G5 FP fast-path rejection and visual recurrence

- Goal: remove the hottest safe generated-runtime helper call, remeasure a
  matched screen, and keep the user's fighter-warp report visible during the
  performance loop.
- Work: inlined the common `MSR.FP` enabled test while preserving the existing
  exception fallback; passed generated-C compile/execute and PowerPC reference
  tests; built all 237 game chunks with O2 + ThinLTO; and ran clean candidate
  and unchanged 500+1,000-frame controls. The longer candidate run also covered
  four-player scenes and retained a fresh suspected vertical fighter stretch.
- Result: **CANDIDATE REJECTED; `VISUAL-001B` REOPENED**. p95/p99 improved
  3.1%/3.4%, but worst regressed from 27.987 to 34.777 ms and the <=16.7 ms
  share slipped. Four-player scenes remained about 45-48 FPS. One Pokémon
  Stadium montage frame shows an orange fighter stretched implausibly above
  Captain Falcon; the adjacent capture was contaminated and later samples were
  coherent, so attribution remains open and promotion is blocked conservatively.
- Cleanup: DolRecomp source and its candidate patch-stack entry were restored.
  No runner or Simulator remains; Jump Desktop Audio is restored.
- Evidence:
  `docs/artifacts/2026-08-25/g5-fp-fast-path-and-watcher-audit.md` and the raw
  traces and screenshot named there.
- Next: fix static-recomp-aware watched memory with a unit-testable reader and
  initial-zero delivery, then obtain uncontaminated temporal mesh evidence and
  required-stage timing.

## 2026-08-25 — G5 static-recomp MemoryWatcher audit

- Goal: cold-replay the source-backed title lockout sequence without another
  fixed-delay guess.
- Work: started MemoryWatcher before the runner and attempted the exact
  `gm_80479D30` and `gmTitle_804D6714` predicates. No input action was emitted.
  The runtime reported both addresses as unresolved because ordinary Dolphin
  MMU state is not synchronized for static-recomp guest RAM. A direct-MEM1
  experiment compiled and removed the panic lines.
- Result: **NOT RETAINED; ROUTE STILL OPEN**. The freshly linked runner then
  hung while CoreAudio instantiated Jump Desktop Audio. Its window close did
  not terminate the process, so a subsequent launch briefly created a second
  runner. The two exact SsbmPad PIDs were detected and terminated immediately.
- Cleanup: the unverified direct-read source was restored, both processes and
  the driver are gone, Simulator remains off, and Jump Desktop Audio is again
  the default output. The bootstrap patch-scope audit was simplified so all
  stacked ModernGekko changes are validated once per checkout.
- Next: add a pure static-recomp MEM1 read regression, make MemoryWatcher send
  the first zero value, preselect built-in audio for a fresh runner, and prove
  process count after every close and before every launch.

## 2026-08-25 — User reconfirmation of real-mesh warping blocker

- Goal: ensure the reported bizarre character morphing/warping remains visible
  in the goal loop and is not conflated with Fountain's reference-matching
  lower reflection.
- Evidence: the reattached 1230 x 848 screenshot has SHA-256
  `a524450eb97c9bb99722a4d48a5d1f55998dc300aac0a7984a2f2af576e19b6c`,
  exactly matching the already retained
  `g5-fountain-warping-user-observation.png`; no duplicate was created.
- Result: `VISUAL-001B` remains open and promotion-blocking. The next accepted
  classification evidence must contain uncontaminated adjacent frames or a
  matched official-reference sequence; a coherent later sample does not erase
  the reported recurrence.

## 2026-08-25 — G5 static-recomp watcher fix and R0 cold route

- Goal: make watched-memory input deterministic enough to collect clean
  temporal mesh evidence and required-stage performance samples.
- Work: added a pure bounded static-recomp MEM1/MEM2 reader, initial-zero
  publication, upstream-style and always-built regressions, reproducible
  ModernGekko/Dolphin patches, isolated-user FIFO derivation, memory tracing,
  and nonzero-to-zero predicates. Generated revision-0 instructions proved the
  prior sequence mixed revision-1.02 addresses into revision 0; corrected
  `GameState` to `0x80477D68` and title lockout to `0x804D4594`. Corrected
  routing predicates to per-mode scene index zero and retained conservative
  five-second menu animation windows.
- Result: **PARTIAL PASS**. The watcher streamed live R0 boot state and the
  complete 20-to-zero title lockout. A cold route sent no early input, reached
  Main Menu, and visibly reached four-slot VS CSS. The terminal `GM_VS`
  notification still timed out despite visible CSS, so predicate completion is
  unresolved and no full automation-pass claim is made.
- Verification: focused test failed before each fix; nine Python regressions,
  the standalone C++ watcher regression, four focused ModernGekko regressions,
  patched Dolphin core compile, full arm64 runner link, bootstrap patch audit,
  code-signature verification, and repository checks pass.
- Cleanup: the runner and driver are stopped, Simulator remains off, the
  unexpected microphone request was not accepted, and Jump Desktop Audio was
  restored.
- Evidence:
  `docs/artifacts/2026-08-25/g5-static-recomp-memory-watcher-route.md`.
- Next: explain or replace the terminal CSS state signal, then use the reliable
  cold/input path for uncontaminated adjacent-frame mesh capture and required-
  stage G5 timing.

## 2026-08-25 — G5 self-verifying CSS and clean Fountain replay

- Goal: explain the missing VS terminal signal, retain uncontaminated temporal
  fighter evidence, and measure a visually verified audio-inclusive Fountain
  interval.
- Work: proved the source transition is `GM_MENU -> GM_VS/CSS`; reproduced the
  controller's unread-datagram window; added watched-delay pumping and removed
  the timing-dependent initial-zero prerequisite under failing regressions. A
  watcher-first cold retry reached `GameState=0x02020100` and exited zero.
  App-only capture retained clean CSS plus twelve Fountain combat frames while
  leaving the unexpected microphone permission unanswered. After capture, a
  visually verified rematch ran twenty combat cycles with no UI inspection.
- Result: **INPUT-004 CLOSED; G5 STILL FAILS; VISUAL-001B STILL OPEN**. The
  self-verifying route completed at 143.83 seconds. All twelve fresh temporal
  frames were coherent, which is bounded negative evidence only. The clean
  5,463-frame Fountain interval measured 16.683 ms mean, 17.115 ms p95,
  17.318 ms p99, 59.024 ms worst, and 54.714% <=16.7 ms despite a 59.9 FPS
  title. Vblank p95/worst were 17.180/73.595 ms.
- Invalid diagnostics: one attempt started the runner before the watcher; its
  missing stream was discarded. That runner then ignored Ctrl-C/TERM and
  survived into one retry; the duplicate PIDs were detected, force-stopped,
  and excluded. The accepted run began only after proving one watcher, zero
  runners, and zero Simulators.
- Verification: the new regression failed before the pump; eleven controller
  tests, repository audit, bootstrap patch audit, cold terminal predicate,
  clean CSS capture, original 12-frame burst, and exact full timing-log hashes
  pass. No Simulator was booted.
- Cleanup: the app close control terminated the exact runner, no controller or
  Simulator remains, and Jump Desktop Audio is restored.
- Evidence:
  `docs/artifacts/2026-08-25/g5-watcher-pump-fountain-replay.md`.
- Next: profile the retained clean Fountain interval to identify the shared
  17.1 ms p95 and rare 59 ms tail before changing one code path; rerun matched
  Fountain and Final Destination only if the focused candidate improves the
  strict worst-case distribution.

## 2026-08-25 — G5 locked-cache pointer fast-path rejection

- Goal: test whether the sampled `ppc_psq_store -> external write -> MMU` path
  is the remaining required-stage compute bottleneck.
- Work: added a regression that failed before GXRuntime consulted its existing
  external-pointer callback, implemented the narrow pointer path, and disabled
  it during lockstep journaling. The test passed afterward and the arm64 runner
  plus fresh idle-clean Fountain/FD PGO module built. A cold native run proved
  46 pointer-hook samples and moved the CPU thread from almost fully inside
  static-recompiled compute to 6,844/9,774 samples in pacing sleep. A separate
  capture-free bracket ran 20 scripted combat cycles with Cubeb.
- Result: **CANDIDATE REJECTED; G5 STILL OPEN**. The 5,803-frame diagnostic
  measured render p95/p99/worst 18.899/20.513/35.250 ms and only 46.631% at or
  below 16.7 ms. Despite improved compute headroom and rare worst frame, the
  sustained distribution is worse than the retained visually verified
  Fountain interval. Final Destination was not run.
- Evidence boundary: the SDL child was inaccessible to app-window capture, so
  the controller route and performance bracket are screening evidence only;
  no stage-identity or visual claim is made. `VISUAL-001B` remains open.
- Cleanup: temporary dependency edits and tests were removed; the ignored app
  bundle was restored to the retained runner/module hashes; no runner,
  controller, frontend, or Simulator remains active.
- Evidence:
  `docs/artifacts/2026-08-25/g5-locked-cache-pointer-rejection.md`.
- Next: re-evaluate pacing only in the measured locked-cache-headroom state;
  retain nothing unless both required stages improve under the full strict
  distribution and visual gates.

## 2026-08-25 — G5 locked-cache plus precise-spin rejection

- Goal: test the newly falsifiable pacing hypothesis after the locked-cache
  candidate moved 70% of sampled CPU time into `PrecisionTimer::SleepUntil`.
- Work: held the pointer module, lockstep guard, Cubeb, Metal, cold route, and
  20-cycle combat script fixed; changed only the final Apple-silicon precision
  spin from scheduler `yield()` to the ARM `yield` hint. The arm64 runner built
  and the revision-0 watcher route again reached CSS before the bounded route.
- Result: **COMPOSITION REJECTED; G5 STILL OPEN**. The 4,780-frame render
  interval measured 16.678 ms median but 19.658/21.009/70.455 ms
  p95/p99/worst and only 51.318% <=16.7 ms. This is worse in every retained
  tail metric than the required-stage reference, and worse in p95/p99/worst
  than the standalone pointer screening run. Final Destination was not run.
- Evidence boundary: as in the parent diagnostic, the raw SDL child was not
  accessibility-visible, so no stage or visual claim is made. `VISUAL-001B`
  remains open and promotion-blocking.
- Cleanup: the temporary timer and hook changes were removed; the ignored app
  bundle was restored to the retained hashes; no runner, frontend, controller,
  or Simulator remains active.
- Evidence:
  `docs/artifacts/2026-08-25/g5-locked-cache-pointer-rejection.md`.
- Next: stop tuning final-spin behavior. Attribute the retained Fountain tail
  to a different single path, keeping compute and pacing evidence separate.

## 2026-08-25 — G5 sample-attribution correction and kernel-wait preflight

- Goal: audit the source identity of the retained hotspot and test a non-busy
  macOS deadline wait before another expensive boot.
- Finding: the 03:30:57 sample's dominant `0x80331940` PC lies inside
  `__THPDecompressiMCURow640x480`, not Fountain gameplay. The sample captured
  boot/opening/menu video work and is withdrawn as combat attribution. The
  later pointer/timer timing rejections remain valid independently.
- Preflight: a 1,000-frame benchmark compared the current precision loop with
  `mach_wait_until`. The kernel wait regressed p95/p99/worst from
  22.852/23.525/23.543 ms to 23.431/24.530/24.951 ms and reduced the <=16.7
  share from 54.3% to 53.4%.
- Result: **ATTRIBUTION CORRECTED; KERNEL WAIT REJECTED WITHOUT GAME BUILD**.
  No product/dependency source or runtime artifact changed.
- Next: obtain a fresh visually stage-gated Fountain sample before selecting
  another generated-code optimization.

## 2026-08-25 — G5 visually verified Fountain attribution

- Goal: replace the withdrawn opening-video attribution with a sample whose
  character, opponent, stage, combat state, and completion are visible.
- Route correction: the exploratory `css-p2-iceclimbers.json` actually moved
  player one to Fox and left all opponent slots inactive. Blind runs that
  depended on that filename are excluded from stage evidence.
- Work: a fresh native Metal/Cubeb run visibly established Pikachu versus
  level-1 CPU Kirby, Stage Select, an explicit `Fountain of Dreams` highlight,
  live combat, and the results screen. A 12-second sample ran four combat
  cycles only after the stage was visible.
- Result: **ATTRIBUTION RESTORED; G5 STILL FAILS; VISUAL-001B OPEN**. The CPU
  thread spent 5,367/8,396 samples in `StaticRecompCore::Run`. The concurrent
  1,707-frame render bracket measured 16.715 ms mean, 17.565 ms p95,
  22.530 ms p99, 30.615 ms worst, and 54.013% <=16.7 ms. Sampling overhead
  makes this a diagnostic rather than acceptance evidence.
- Visual: four adjacent verified-match frames show a large Kirby silhouette
  transition including a flat horizontal pose. It may be legitimate squash
  animation; a matched reference action is still required. The issue remains
  promotion-blocking.
- Cleanup: route frames, adjacent frames, and the sample are retained; the
  exact native runner was closed and no Simulator is booted.
- Evidence:
  `docs/artifacts/2026-08-25/g5-visually-verified-fountain-sample.md`.
- Next: rebuild a fresh instrumented module and train it under the retained
  revision-0 idle-PC skip using only visually verified required-stage runs.
  The old retained PGO corpus predates idle skipping and is no longer a sound
  layout baseline for the next optimization.

## 2026-08-25 — G5 reduced-idle PGO rejection and combat-profile control

- Goal: determine whether a fresh visually verified idle-skipping Fountain
  corpus improves the strict frame distribution, then remove remaining
  boot/menu counts before another training run.
- Performance result: **CANDIDATE REJECTED; G5 STILL OPEN**. The candidate's
  clean Fountain render p95/p99/worst were 17.216/17.459/88.407 ms versus the
  retained 17.115/17.318/59.024 ms, and <=16.7 ms coverage fell from 54.714%
  to 54.212%. Final Destination was not run.
- Visual result: the independently trained candidate reproduced impossible
  Fountain scale/displacement while its title read 59.9 FPS. `VISUAL-001B`
  remains open and promotion-blocking.
- Control implementation: instrumented modules now optionally export LLVM
  counter reset/dump hooks. The host resolves them from the retained module
  handle and drives a one-shot address/mask/value predicate on the emulated CPU
  thread. Uninstrumented modules keep the prior exported surface and ABI.
- Focused regression: the actual GALE01 instrumented dylib excluded seven
  pre-reset descriptor calls, retained three post-reset calls, and dumped once;
  the PGO-use module exported neither hook.
- Live proof: a cold MemoryWatcher route armed on main-menu state, reset there,
  entered VS CSS, and dumped with result zero. The 43 MB raw profile remains
  outside Git; the native runner was stopped and no Simulator is booted.
- Evidence:
  `docs/artifacts/2026-08-25/g5-reduced-idle-pgo-rejection.md` and
  `docs/artifacts/2026-08-25/g5-combat-profile-control.md`.
- Next: collect a visually verified match-only Fountain corpus with the new
  trigger, build a PGO-use candidate, and reject it before Final Destination
  unless the complete strict Fountain distribution improves.

## 2026-08-25 — G5 release frame-phase correction and timer rejection

- Goal: step back from the visibly slow instrumented trainer and determine
  whether the normal release is actually compute-bound on verified Fountain.
- Work: added default-off buffered present-aligned timing for static-recompiler
  CPU-loop wall time, configured guest idle, throttle sleep, video construction,
  present, and Cubeb mixing. A visible Pikachu-versus-CPU Fountain route held a
  59.9 FPS title while scripted combat ran without capture during measurement.
- Correction: the first counter set included `CoreTiming::Throttle()` sleep in
  CPU wall time. After separating it, 4,094 combat frames showed 8.574 ms mean /
  9.875 ms p95 guest compute and 8.088 ms mean throttle sleep. Present-to-present
  remained 16.683 ms mean / 17.237 ms p95 / 19.112 ms worst, with 53.395% <=16.7.
- Result: **RELEASE IS NOT STEADY-STATE COMPUTE-BOUND; G5 STILL OPEN**. Metal,
  present, audio, and compute did not correlate strongly with the remaining
  tail. The 12.5-22 FPS observation belonged to LLVM instrumentation.
- Experiment: doubling the Apple precision spin window regressed an active-scene
  p95 to 19.314 ms and was removed. The normal 1.02 ms path was rebuilt.
- Visual boundary: impossible Fountain scale/displacement remained visible at
  59.9 FPS. `VISUAL-001B` remains independently promotion-blocking.
- Evidence:
  `docs/artifacts/2026-08-25/g5-release-frame-phase-attribution.md`.
- Next: retain the logger, stop timer/PGO guessing, and find the first divergent
  geometry/state frame against a matched reference before another product fix.

## 2026-08-25 — Independent stale-`ps1` review reconciliation

- Goal: ingest the user-supplied independent report, distinguish evidence from
  instructions, and use it to correct the active G5/visual sub-loop.
- Confirmed: scalar-single C emission formerly wrote only lane 0; exact
  GXRuntime helpers restore both lanes and full Gekko semantics. Adjacent
  frames 176-184 confirm real multi-frame Peach deformation. The same defect
  class remains at 1,237 lane-0-only C-emitter `frsp` sites.
- Corrections: `0x80374174` is a later lockstep comparison/return point, not
  the producing instruction. The prior PGO slowdown comparison used unmatched
  scenes, and disassembly falsifies the call-site-inlining story; only helper-
  body degradation from missing profile records is established.
- Result: **REPORT INGESTED; LOOP REORIENTED; NO FIX CLAIM.** The completed
  large-inline dylib is temporary comparison evidence. Exact helper calls
  remain the product baseline. G5 and `VISUAL-001B` stay open; no Simulator is
  booted.
- Evidence:
  `docs/artifacts/2026-08-25/g5-independent-scalar-single-review.md`.
- Next: matched deterministic A/B the two existing corrected helper dylibs;
  then close `frsp`, extend semantic/C-LLVM parity tests, rebuild once, and
  require extended Peach-inclusive visual evidence before exact-source PGO.

## 2026-08-25 — G5 scalar-single/`frsp` correction and exact-source PGO

- Goal: execute the independent report's falsifiable source, visual, and PGO
  actions without weakening G5 or promoting to Simulator work.
- Source: scalar-single arithmetic and `frsp` now emit exact GXRuntime helper
  calls, update both lanes, and preserve Rc/FPSCR behavior. Focused generated-C
  and runtime tests cover lane sentinels, Force25Bit, exceptional values,
  write suppression, FPRF, FI/FR, and NI flushing.
- Verification: DolRecomp passed 14/14 and GXRuntime 1/1. Clean pinned checkout
  application of the full Dolphin patch stack plus the new DolRecomp patch
  passes `git apply` and `diff --check`.
- Visual: all 200 consecutive corrected app-window frames were coherent and
  included Peach, but not the exact known Battlefield recurrence. This is
  strong negative evidence; `VISUAL-001B` remains open.
- PGO: rebuilt generation/use modules from the identical corrected source and
  exactly one fresh no-input profile. Matched render p95 improved from 20.616
  to 18.232 ms and worst from 37.348 to 30.571 ms, falsifying the feared PGO
  collapse. Both candidates still fail the 16.7 ms rule.
- Result: **CORRECTION RETAINED; G5 AND VISUAL GATE OPEN**. No Simulator is
  booted. No ROM, generated module, or profile is added to Git.
- Evidence:
  `docs/artifacts/2026-08-25/g5-scalar-single-frsp-correction.md`.
- Next: reproduce the known Peach composition or an extended matched equivalent
  under the corrected module, then resume clean visually verified Fountain and
  Final Destination tail attribution one variable at a time.

## 2026-08-25 — Corrected visual closure and clean Fountain baseline

- Goal: satisfy the intermittent visual closure boundary, then establish the
  first required-stage timing baseline from the exact corrected PGO module.
- Visual: retained 2,110 native-window frames over 402.7 seconds. The corpus
  covers Brinstar, several four-player demos, multiple Peach scenes, and 54
  dense ordered Battlefield Peach combat frames. No fighter deformation
  recurred. This satisfies the loop's extended-matched-equivalent boundary;
  `VISUAL-001B` is closed and reopens on any recurrence.
- Route: two pre-game setup attempts were excluded for missing SI/FIFO setup.
  The valid cold run passed the title/CSS state barrier. Stale P2 cursor
  assumptions were corrected under live visual inspection, then Character
  Select showed Pikachu and level-1 CPU Zelda, Stage Select explicitly showed
  Fountain of Dreams, and live Fountain combat held a 60.0 FPS title.
- Timing: a 66-second, capture-free, audio-enabled bracket retained its final
  3,900 frames. Render mean/median/p95/p99/worst were
  16.683/16.684/17.000/17.301/79.167 ms with 54.846% <=16.7 ms. Vblank was
  16.683/16.683/16.855/16.883/79.085 ms with 65.231% <=16.7 ms.
- Result: **VISUAL DEFECT CLOSED; G5 STILL FAILS**. The acceptance runner did
  not emit phase CSV, so no subsystem attribution is claimed. A newer runner
  separately passed a phase-CSV smoke test; its data is not mixed here.
- Evidence:
  `docs/artifacts/2026-08-25/g5-corrected-visual-closure-and-fountain-baseline.md`.
- Next: replay verified Fountain with the phase-CSV runner, attribute the tail,
  and test exactly one implicated subsystem before repeating on Final
  Destination. No Simulator work begins.

## 2026-08-25 — Corrected Fountain phase attribution

- Goal: execute the report-adjusted G5 step by replaying the exact corrected
  module on the phase-CSV runner, without mixing builds or capture overhead.
- Route: a clean isolated run visibly passed CSS, explicitly highlighted
  Fountain of Dreams, and entered live Pikachu-versus-CPU-Pikachu combat. The
  66-second controller bracket contained no screenshot or UI work; 120 rows
  were trimmed from each edge.
- Result: **G5 STILL FAILS; RENDER/PRESENT/AUDIO EXCLUDED AS DOMINANT**. Across
  3,683 frames, total p95/p99/worst are 17.016/17.227/18.986 ms and 53.136%
  meet 16.7 ms. Derived compute is 10.459 ms mean / 12.540 ms p99, with one
  18.010 ms compute-only overrun. Most frames retain about 6.2 ms throttle
  sleep. Video, present, and audio p99 are only 0.101/0.106/1.318 ms.
- Evidence:
  `docs/artifacts/2026-08-25/g5-corrected-fountain-phase-attribution.md` and
  `docs/artifacts/2026-08-25/g5-corrected-fountain-phase.csv`.
- Next: instrument requested throttle time and positive deadline lateness in
  the default-off phase logger, rerun the same Fountain route, and let that
  evidence choose one pacing or compute behavior test. No Simulator work.

## 2026-08-25 — Fountain wake-lateness falsification

- Goal: distinguish requested throttle sleep from macOS deadline wake-up
  lateness without changing runtime behavior.
- Source/repro: added two default-off phase fields; repaired the canonical
  patch to include its missing `FramePhaseTiming.h`; incremental build and a
  111-row smoke passed; clean application to pinned Dolphin plus prerequisites
  passed.
- Route: the final watched-memory predicate timed out, but live UI inspection
  proved Fountain of Dreams was highlighted at 59.9 FPS; launch visibly entered
  live Fountain. The subsequent 65-second timing bracket was capture-free.
- Result: **PACING OVERSHOOT EXCLUDED; G5 STILL FAILS**. Across 3,718 trimmed
  frames, total p95/p99/worst are 17.011/17.233/24.185 ms. Wake lateness is
  0.199 ms p95 / 0.214 ms p99 and has 0.024 correlation with total time. The
  five worst rows requested no sleep and spent 19.470-24.159 ms in derived
  compute.
- Evidence:
  `docs/artifacts/2026-08-25/g5-corrected-fountain-deadline-attribution.md` and
  `docs/artifacts/2026-08-25/g5-corrected-fountain-lateness.csv`.
- Next: add per-frame static-recompiler work deltas, repeat Fountain, and use
  them to choose one generated-code experiment. No timer or Simulator work.

## 2026-08-25 — Static-work attribution and CPU-QoS rejection

- Goal: distinguish additional guest work from higher host execution cost in
  Fountain compute overruns, then test one implicated behavior.
- Diagnostic: default-off phase CSV now carries burst, guest-cycle, native-
  dispatch, interpreter-fallback, and hook-fallback deltas. Clean patch apply,
  build, and live smoke passed.
- Attribution: in 3,678 visually verified control frames, tail bursts/cycles
  were 0.25%/0.04% lower than the body; host ns/native-dispatch correlated
  0.783 with total time. The 51.412 ms worst frame did not carry excess guest
  work.
- Candidate: macOS user-interactive QoS on the CPU thread returned success and
  cut worst to 18.002 ms, but p95 regressed from 16.975 to 17.031 ms. **QOS
  CANDIDATE REJECTED AND REMOVED; G5 OPEN.**
- Evidence: `docs/artifacts/2026-08-25/g5-static-work-and-qos-rejection.md`
  plus its two retained CSVs.
- Next: matched repeat/control to distinguish rare host preemption from
  systematic dispatch cost. No Simulator work.

## 2026-08-25 — Repeat control and thread-CPU attribution

- Goal: separate rare host preemption from real on-core execution cost.
- Repeat: unchanged Fountain reproduced p95 at 16.975 ms and a smaller
  21.604 ms ordinary-work cluster; the prior 51.412 ms cluster is rare.
- Diagnostic: added default-off thread CPU time. One wrong-stage run was
  discarded. A fresh route exposed and corrected the stale CSS assumption that
  had picked P1's token back up; valid P1 Pikachu/P2 CPU Mario and Fountain
  were visually verified before the clean bracket.
- Result: total p95/p99/worst 16.970/17.184/19.088 ms. Residual off-core time is
  0.018/0.148 ms p95/p99; tail thread CPU rises 0.207 ms, so the tail is mainly
  on-core. **G5 OPEN.**
- Evidence: `docs/artifacts/2026-08-25/g5-repeat-and-thread-cpu-attribution.md`
  and its two retained CSVs.
- Next: classify runtime hook fallbacks by instruction class, then test one
  dominant class. No Simulator work.

## 2026-08-25 — Runtime fallback subclass attribution

- Goal: identify the executed instruction-hook fallback class before changing
  behavior, following the independent stale-`ps1` review's matched-evidence
  discipline.
- Diagnostic: added default-off `mfspr`, `mtspr`, cache, other, and
  `dcbst`/`dcbf`/`dcbi`/`icbi` per-frame counters. The canonical patch applies
  cleanly after the pinned prerequisites; the runner build and populated smoke
  passed; both accounting sums match exactly.
- Route: the all-in-one route reached Fountain but timed out on its roster
  predicate, so it was not timed. CSS inspection proved P1 Pikachu plus one CPU
  Peach; Fountain highlight and coherent live Fountain were visually verified
  before a capture-free 20-cycle bracket.
- Result: across 3,692 trimmed frames, `dcbf` contributed 14,426,100 calls
  (64.295%) and `dcbi` 8,003,986 (35.672%); `icbi` was zero. Total p95/p99/worst
  were 17.007/17.220/30.478 ms. Fallback count correlates -0.059 with total and
  is lower in the slow tail, so it does not explain tail variance. **G5 OPEN.**
- Evidence: `docs/artifacts/2026-08-25/g5-fallback-subclass-attribution.md`
  and `docs/artifacts/2026-08-25/g5-fallback-subclass-fountain.csv`.
- Next: test one semantics-preserving fast path that avoids the generated
  `dcbf`/`dcbi` host-hook/dispatcher round trip only when D-cache emulation is
  disabled; retain only on strict matched Fountain improvement, then verify
  Final Destination. No Simulator work.

## 2026-08-25 — Generated cache-control parity correction

- Goal: execute the report-adjusted fallback experiment only after verifying
  the claimed cache semantics against Dolphin's source.
- Semantic correction: the prior no-op claim was wrong. Dolphin invalidates a
  JIT cache line for `dcbf`, `dcbst`, and supervisor-mode `dcbi` when D-cache
  emulation is disabled. The old specialized fallback did not mirror that
  behavior and was removed.
- Implementation: generated C now matches LLVM by emitting the live effective
  address, calling `ppc_cache_control`, checking exceptions, and continuing the
  native block. Exact privilege, cycle, `icbi`, D-cache-enabled, and
  D-cache-disabled invalidation behavior remains in the runtime helper.
- Verification: DolRecomp passes 14/14 focused tests. All 14 generated GALE01r0
  cache sites use the helper, zero use raw fallbacks, and a populated smoke
  recorded 8,188,076 exactly classified direct cache operations.
- Matched route: profile-free control and candidate both used P1 Pikachu versus
  level-1 CPU Ice Climbers, an explicitly verified Fountain highlight, coherent
  live gameplay, and the same capture-free 20-cycle combat script.
- Result: mean/p95/p99/worst improved from
  20.329/22.581/23.825/33.066 ms to 17.858/20.054/21.319/27.860 ms. Cache
  fallbacks fell from 6,066.022/frame to zero while direct helper calls averaged
  6,064.453/frame with exact subclass accounting. **CORRECTION RETAINED; G5
  OPEN.** Only 19.285% of frames meet 16.7 ms. No Simulator was booted.
- Evidence: `docs/artifacts/2026-08-25/g5-cache-control-parity.md` and its two
  retained CSVs.
- Next: collect a fresh exact-source PGO corpus on the retained cache path with
  source/module/profile hashes, then rerun strict Fountain. Attempt Final
  Destination only if Fountain passes; do not start G6.

## 2026-08-26 — Exact-source cache-control PGO rejection and visual reopen

- Goal: finish the report-adjusted next experiment by training and testing PGO
  on the retained generated cache-control path.
- Training: built the exact source with instrumentation, visually verified P1
  Bowser versus level-1 CPU Zelda on Fountain, ran 30 combat-cycle repeats,
  and cleanly shut down with `fallback=0` and `smc_failed=0`. Exactly one raw
  profile was eligible and merged; four route-debug raws were excluded.
- Build: the PGO-use arm64/macOS 14 dylib is signed, exports only the normal
  module entry, and has SHA-256 `1993ed0c9619875b19e5b7fc711143ee241bf7c3084c0397b0ee281f931b26b5`.
- Route audit: one PGO attempt and two profile-free attempts entered attract
  matches and were rejected before timing. The current cold-boot watcher timed
  out on its first predicate during the opening movie; sustained START can
  also land in attract mode. Visual gates prevented contamination.
- Accepted PGO route: P1 Bowser versus level-1 CPU Bowser, explicit Fountain
  label, live Fountain, Cubeb, and the capture-free 20-cycle script. The
  6,428-frame trimmed bracket measured mean/p95/p99/worst
  16.894/17.860/18.080/1,367.699 ms; 55.009% were <=16.7 ms. The 1.367-second
  frame carried 41,469,067 native dispatches and is not capture overhead, but
  p95 already fails without it.
- Visual result: severe lower-frame warping and Bowser duplication/morphing
  reproduced. The profile-free cache-control path showed the same class.
  `VISUAL-001B` is reopened.
- Result: **PGO REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.**
  No PGO dylib/profile or game data is retained.
- Evidence: `docs/artifacts/2026-08-26/g5-cache-control-pgo-rejection.md`, its
  trimmed CSV, and its visual capture.
- Next: deterministic adjacent-frame profile-free reproduction of
  `VISUAL-001B`, then earliest divergent generated draw/vertex attribution.
  Replace the stale cold-boot predicate before accepting another timing run.
