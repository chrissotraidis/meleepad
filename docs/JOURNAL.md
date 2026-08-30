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

## 2026-08-26 — Exact-source cache-control PGO rejection and visual re-audit

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
- Visual re-audit: the two Bowsers are the accepted Bowser/Bowser roster and
  both real meshes are coherent. The deformation is confined to Fountain's
  known reference-parity reflection. The profile-free Bowser/Ice Climbers
  screen agrees. The initial `VISUAL-001B` reopening is withdrawn.
- Result: **PGO REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.**
  No PGO dylib/profile or game data is retained.
- Evidence: `docs/artifacts/2026-08-26/g5-cache-control-pgo-rejection.md`, its
  trimmed CSV, and its visual capture.
- Next: throttle-deadline attribution and a focused host-pacing regression.
  In the <=100 ms population, p95-tail CPU-thread work is 0.301 ms lower while
  throttle sleep is 1.972 ms higher and measured wake lateness is 0.526 ms
  higher. Replace the stale cold-boot predicate before another timing run.

## 2026-08-26 — macOS precision-pacing contention rejection

- Goal: execute the report-adjusted throttle-deadline experiment without
  repeating previously rejected pacing changes.
- Report provenance: retained the exact user attachment byte-for-byte as
  `docs/artifacts/2026-08-26/g5-stale-ps1-report-verbatim.txt` and recorded its
  current disposition in `g5-stale-ps1-report-ingestion.md`. The prior
  2026-08-25 verbatim artifact has identical text plus one final newline.
- Host screen: a new 3.02 ms wake-lead plus true busy-spin combination passed
  900/900 synthetic frames at <=16.7 ms; changing only the final spin at the
  existing 1.02 ms lead did not improve p95 and was excluded before build.
- Source/package correction: the first package followed a stale generated-
  module pointer and its bracket was excluded after counters showed 20.4M
  cache fallbacks. Canonical `prepare-game.sh` regeneration selected exact
  corrected suffix `06852d9f...` and reproduced module SHA `2dce1352...`.
  Bootstrap now recognizes composed overlapping patches 0005/0006 by unique
  retained markers and permits the separately verified DolRecomp submodule.
- Route: watcher-first cold trace separated opening-movie GameState values
  from the genuine 0x14-to-zero title lockout; the exact one-second START hold
  then reached menu/CSS. A retained 80 ms stage-cursor correction reached an
  explicit Fountain highlight without overshoot. P1 Pikachu, CPU Peach,
  coherent live Fountain, and Cubeb were visibly verified.
- Result: the 3,074-frame capture-free candidate measured
  19.667/22.357/24.690/141.484 ms mean/p95/p99/worst and only 2.895% <=16.7
  ms. CPU-thread work rose to 19.437 ms mean, requested throttle time vanished,
  cache fallbacks remained zero, and 6,062.409 direct helpers/frame remained
  accounted. **CANDIDATE REJECTED; G5 OPEN; FD NOT RUN; G6 BLOCKED.**
- Cleanup: timer source and patch entry removed; normal runner rebuilt and app
  repackaged as SHA `c26625db...` with corrected module `2dce1352...`. No
  runtime or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-26/g5-macos-pacing-contention-rejection.md`, its CSV,
  retained visual, and `scripts/g5_pacing_preflight.cpp`.
- Next: exact matched Fountain control with the restored runner, corrected
  module, watcher-first route, same roster/stage/audio, and same 20-cycle
  bracket. Do not test another timer variant first.

## 2026-08-26 — Restored-runner control confirms contention and reorients G5

- Goal: complete the required matched control after removing the rejected
  3.02 ms busy-spin timer candidate.
- Route: watcher-first cold boot, P1 Pikachu versus level-1 CPU Kirby, explicit
  Fountain highlight, coherent live combat, Cubeb, and the same capture-free
  20-cycle script. No Simulator was booted.
- Result: 3,673 trimmed frames measured 16.686/17.656/18.984/36.424 ms
  mean/p95/p99/worst and 59.932 FPS average; 54.315% were <=16.7 ms. There
  were zero interpreter/cache fallbacks and 6,057.624 exactly classified
  direct cache controls/frame. The normal timer restores average speed, so the
  busy-spin candidate's 50.845 FPS result was real contention. G5 remains open.
- Attribution: versus the <=16.7 ms body, the p95 tail has nearly flat bursts
  and guest cycles but +13,634 native dispatches/frame (+10.5%) and +5.8%
  CPU-thread nanoseconds/dispatch. CPU-thread time rises 2.576 ms while
  throttle sleep falls 0.904 ms; wake lateness does not explain the tail.
- Evidence: `docs/artifacts/2026-08-26/g5-macos-pacing-restored-control-fountain.csv`,
  its retained visual, and the amended pacing rejection report.
- Next: add default-off dispatch-return classification to identify the control-
  flow boundaries behind the extra tail dispatches. Do not retry the rejected
  1024-cycle budget or another timer variant; do not run Final Destination or
  start G6.

## 2026-08-26 — Dispatch observer rejection and normal DK slow-path proof

- Goal: determine whether the new menu/combat slowdown was diagnostic observer
  cost or a real normal-runner workload regression.
- Diagnostic screen: exact dispatch-return classification visibly reduced
  Stage Select to about 44.5 FPS and was excluded before combat. One-in-256
  classification averaged 17.945 ms / 55.727 FPS in live Pikachu/CPU-DK
  Fountain. Piggybacking on the existing one-in-4096 sampler restored a
  59.935 FPS no-input preflight but still fell to 50-55 FPS under sustained
  interaction. None is eligible for acceptance timing; all attribution code
  and its proposed patch were removed.
- Normal control: rebuilt, signed, and restored runner SHA `c26625db...` with
  corrected module `2dce1352...`; watcher-first cold boot visibly established
  P1 Pikachu, level-1 CPU Donkey Kong, explicit Fountain of Dreams, coherent
  live combat, and Cubeb. No Simulator was booted.
- Result: the 600-row capture-free pre-results bracket measured
  19.761/21.551/23.098/26.278 ms mean/p95/p99/worst, 50.605 FPS average, and
  only 2.000% <=16.7 ms. CPU-thread mean was 19.575 ms with zero interpreter
  or cache fallbacks. Compared with the 59.932 FPS Pikachu/Kirby control, DK
  costs about 3.53 ms more CPU/frame despite fewer dispatches and essentially
  equal guest cycles. **REAL CONTENT-SENSITIVE SLOW PATH; G5 OPEN; FD NOT RUN;
  G6 BLOCKED.**
- Menu boundary: animated menus visibly slowed too. Retain that as a regression
  requirement, but do not claim a clean menu metric because the explicit 44.5
  FPS reading came from rejected instrumentation.
- Evidence:
  `docs/artifacts/2026-08-26/g5-normal-dk-fountain-slowpath.md` and its CSV.
  No normal-runner screenshot was retained; the temporary UI capture expired.
- Next: take a non-invasive, phase-gated native CPU sample of slow DK and a
  matched fast Kirby control, then identify the generated chunks or host
  helpers whose cost per dispatch changes. Do not return to timer tuning or
  add a new branch to every dispatch.

## 2026-08-26 — Fresh DK correction and idle-precharge rejection

- Goal: externally profile the claimed DK slow path without changing the
  dispatch loop, then test the smallest mechanism implicated by the sample.
- Normal correction: watcher-first cold boot visibly established P1 Pikachu,
  level-1 CPU DK, explicit Fountain of Dreams, coherent combat, Cubeb, and
  results. The normal signed runner held 59.8-59.9 FPS during combat and at
  results. No phase logger was enabled, so this is not strict G5 timing, but it
  falsifies deterministic DK attribution. The earlier 50.605 FPS interval is
  retained as a real intermittent slowdown.
- External attribution: 776/886 normal CPU-thread samples were in
  `StaticRecompCore::Run`; 156/886 had known scheduler poll `loop_80349494` at
  the top despite the full-speed title.
- Candidate: a production-header regression failed before the helper and
  passed after implementation. The signed runner precharged the generated
  downcount only when a burst began at the configured idle PC, preserving the
  256-cycle boundary while intending to return after one poll.
- Result: the visually verified Pikachu/CPU-DK/Fountain candidate bracket had
  4,090 capture-free rows and measured 16.742/17.577/19.527/152.055 ms
  mean/p95/p99/worst, 59.731 FPS, and 55.110% <=16.7 ms. A candidate sample
  still put `loop_80349494` atop 183/890 CPU-thread samples. Melee reaches the
  loop after burst entry, so the mechanism misses it. **CANDIDATE REJECTED AND
  REMOVED; G5 OPEN; FD NOT RUN; G6 BLOCKED.**
- Cleanup: normal runner SHA `c26625db...` and corrected module `2dce1352...`
  are restored and signed; no runtime or Simulator remains.
- Evidence: `docs/artifacts/2026-08-26/g5-idle-precharge-rejection.md`, both
  external samples, candidate CSV, and retained normal/candidate/results PNGs.
- Next: locally emit a return after the first taken poll at the exact generated
  idle branch, prove one-poll/wake semantics, then run a matched normal-versus-
  candidate phase pair. Retain only if the sample loses the loop and the
  complete strict distribution improves.

## 2026-08-26 — Menu idle-loop mechanism isolated; candidates rejected

- Goal: address the user-observed menu slowdown by testing the exact generated
  scheduler poll implicated by the normal external sample.
- Normal CSS control: watcher-first cold routing reached coherent character
  select at 59.939 FPS average. Its 1,197-frame bracket measured 16.683 ms mean
  / 16.896 ms p95, with 8.463 ms CPU-thread mean and 0.070 ms mean throttle
  lateness. The external sample put `loop_80349494` in 1,839 samples.
- Immediate-return candidate: charged only three cycles, visibly ran the
  opening movie at 28-31 FPS, and measured 34.955 ms mean / 42.394 ms p95 in
  the retained intro interval. Rejected as a guest-timing change.
- Cycle-preserving candidate: retained the exact approximately 258-cycle loop
  charge and coherent full-speed CSS. It reduced CPU-thread mean to 5.48-5.60
  ms and reduced the poll to 34 samples with matched guest cycles. Two
  20-second brackets nevertheless repeated 18.479/18.468 ms p95 as longer host
  sleeps increased mean wake lateness to 0.375-0.407 ms. Rejected on the full
  distribution.
- Cleanup: generated source restored; normal runner `c26625db...` and corrected
  module `2dce1352...` restored and signed. No runner, frontend, or Simulator
  remains. G5 open; Final Destination not run; G6 blocked.
- Next: host-only preflight for chunking long Apple precision sleeps before the
  unchanged 1.02 ms final-yield window. Only combine it locally with the
  cycle-preserving shortcut if it reduces long-sleep lateness without adding
  sustained busy-spin contention.

## 2026-08-26 — Long-sleep pacing fixed; residual menu tail reattributed

- Goal: recover the cycle-preserving idle optimization's compute headroom
  without its long-sleep wake-lateness regression.
- Preflight: extended the host harness to reproduce 5.5 ms compute / about
  11 ms sleep and interleave one-shot/chunked plus yield/spin modes. A harness
  `%3` typo was caught by ASan/UBSan and corrected to `%4`. At 600 samples,
  500 us chunks plus yield measured 16.692 ms p95; chunks plus true spin
  measured 16.683 ms p95 and 99.833% <=16.7 ms.
- Chunked-yield game result: coherent watcher-gated CSS, matched guest cycles,
  6.42-6.47 ms CPU-thread mean, and wake-lateness p95 0.013-0.016 ms. Two
  brackets still measured 16.933/16.902 ms p95. Rejected.
- Chunked-spin game result: coherent watcher-gated CSS, 6.64-6.88 ms CPU-
  thread mean, and wake-lateness p95 below 0.001 ms. Two brackets still
  measured 16.928/16.890 ms p95. Rejected.
- Cleanup: all Timer/generated-source candidates removed; normal runner
  `c26625db...` and module `2dce1352...` restored and signed. No runtime or
  Simulator remains. The improved host preflight is retained.
- Next: instrument phase-log frame/present sequence and throttle-target
  identity on the normal path. Attribute the residual 16.89-16.93 ms tail
  before any further behavior change.

## 2026-08-26 — CSS tail isolated before VI output

- Goal: distinguish CPU-slice/throttle alignment, SyncGPU, video queue, and
  presentation as causes of the strict CSS tail.
- Identity result: every retained row was a unique VI frame with two CPU
  throttles and roughly 611 CPU slices. Intended-present and last CPU-target
  cadence were exact at 16.683333/16.683334 ms; slice count did not rise in the
  p95 tail.
- Boundary result: `SyncGPU` was about 0.0001 ms and video queue/service about
  0.03 ms. CPU VI output was already 1.092 ms late on average and 1.313 ms at
  p95. Last-throttle-end to VI-output wall time rose from 2.452 ms/body to
  3.176 ms/tail; CPU-thread work rose by about 0.68 ms while timer lateness did
  not rise.
- CSS-only PC result: the existing one-in-4096 sampler, gated to post-throttle
  CSS only, ranked `0x80349494` at 12,895 samples, `0x80345738` at 3,121, and
  `0x80345760` at 3,118. The latter two are the generated MSR.EE disable/restore
  leaf helpers.
- Cleanup: all temporary boundary/sampler code removed; normal runner
  `c26625db...` and module `2dce1352...` restored and signed. No runtime or
  Simulator remains. G5 open; Final Destination not run; G6 blocked.
- Next: focused semantic test and local module-level coalescing of only
  `0x80345738`/`0x80345760`. Retain only if both sampled leaf PCs disappear and
  the matched CSS distribution improves; do not combine the idle shortcut.

## 2026-08-26 — interrupt-leaf coalescing rejected

- Goal: test the next two CSS-only post-throttle PCs without combining any
  rejected idle or timer change.
- Semantics: a fail-before standalone regression then passed exact EE-on/off,
  signed restore compare, GPR3/GPR4/GPR5, MSR, CR0/SO, PC/LR, and 5/7/8-cycle
  cases. Continuation was allowed only with guest time remaining and no pending
  exception.
- Live result: the cold watcher route reached coherent CSS at a 59.9 FPS title.
  The final 3,600 frames measured 16.683329 ms mean / 16.907625 ms p95 /
  17.154916 ms p99 / 27.725250 ms worst. Native dispatches fell by only about
  51/frame and CPU-thread mean remained 8.483023 ms.
- Decision: candidate rejected; its helper, test, CMake define, and wrapper are
  removed. Normal runner `c26625db...` and module `2dce1352...` are restored;
  no runtime or Simulator remains. G5 open; Final Destination not run; G6
  blocked.
- Next: host-only benchmark of the common 67,000-dispatch/frame chassis path,
  beginning with the empty forced-fallback-range check. Do not cold-build
  unless the benchmark shows material signal.

## 2026-08-26 — empty forced-fallback preflight rejected

- Goal: determine whether the common empty forced-fallback range scan could
  materially reduce the roughly 67,000 native dispatches per CSS frame.
- Audit: excluded the first benchmark because Clang erased the known-empty
  guarded loop. The corrected out-of-line benchmark ran nine alternating
  50-million-call trials per path.
- Result: existing scan 1.661782 ns/dispatch, guarded path 1.347417 ns,
  projected saving 0.021062 ms/frame. This is too small for another cold build.
- Cleanup: temporary benchmark source removed; no product, dependency, module,
  package, runtime, or Simulator changed.
- Next: longer watched normal CSS soak with rolling-window detection for the
  separate intermittent major menu slowdown reported by the user.

## 2026-08-26 — menu foreground/background pacing attributed

- Goal: distinguish the user's major animated-menu slowdown from the separate
  approximately 0.2 ms strict-tail miss.
- Long soak: 18,000 normal background CSS frames averaged 59.940 FPS and had no
  rolling 1/2/5/10-second window below 55 FPS, but measured 17.838 ms p95,
  0.925 ms mean wake lateness, and three 52-85 ms hitches.
- Matched raised control: 3,600 normal CSS frames measured 16.927 ms p95 and
  0.070 ms mean wake lateness while CPU work remained comparable. This isolates
  macOS foreground/background scheduling from renderer or guest compute.
- Rejections: lifecycle-balanced user-initiated-allowing-idle-sleep and user-
  interactive activities, each combined with Apple's latency-critical flag,
  remained at 17.834/17.821 ms p95 and 0.926/0.963 ms mean wake lateness. Both
  were removed.
- Cleanup: normal signed runner `c26625db...` and module `2dce1352...` restored;
  no runtime or Simulator remains. G5 open; Final Destination not run; G6
  blocked.
- Next: record real app-active transitions in the phase diagnostic and run a
  longer raised normal control before considering any focus-policy change.

## 2026-08-26 — same-process focus attribution withdrawn

- Goal: test the foreground/background association causally without changing
  process, package, route, or instrumentation.
- Method: one verified normal CSS process ran foreground, background behind
  Activity Monitor, then foreground again. Each state was held at least two
  minutes; the final 3,600 complete rows of each buffered snapshot were used.
- Result: all three tails averaged 16.6833 ms / 59.940 FPS. Their p95 values
  were 16.912/16.928/16.934 ms and mean wake lateness was
  0.077/0.072/0.074 ms. None contained a frame over 25 ms.
- Decision: **FOCUS ATTRIBUTION WITHDRAWN; NO PRODUCT CHANGE; G5 OPEN; FINAL
  DESTINATION NOT RUN; G6 BLOCKED.** The earlier result was cross-process
  variance, not evidence that app focus caused the slow tail. Do not add a
  focus policy or retry process-activity flags.
- Evidence:
  `docs/artifacts/2026-08-26/g5-active-transition-pacing.md` and its combined
  phase CSV. Normal runner and corrected module remained unchanged; runtime
  exited cleanly and no Simulator is booted.
- Next: keep the product normal and trigger evidence capture on the first
  intermittent one-second menu window below 55 FPS, paired with low-overhead
  native sampling. Do not guess a renderer, focus, or timer fix first.

## 2026-08-26 — CSS-armed intermittent hitch captured

- Goal: capture the user's intermittent menu slowdown without boot, movie, or
  observer-state false positives.
- Diagnostic: retained a default-off 60-frame sub-55 trigger with explicit
  MemoryWatcher-gated arming. Its wrapper copies flushed phase evidence before
  taking a post-trigger native sample. Canonical patch reverse-apply, compile,
  no-pre-arm, and induced-stall tests passed.
- Exclusions: a 14.3 FPS title was cold-start averaging; a frame-1350 trigger
  was still inside the 134-second opening/title route. Neither is menu proof.
- Result: after four minutes of verified CSS, frame 26106 triggered at 54.9185
  rolling FPS. The window's 70.344/37.102/33.618 ms hitches had only
  11.281/11.749/12.975 ms CPU-thread work, flat guest work, and tiny
  video/present/audio cost. The lost time is off-core host delay.
- Scope: two/five/ten-second worst windows still held
  57.316/58.866/59.399 FPS. This reproduces an intermittent one-second hitch
  cluster, not a sustained 12-15 FPS menu collapse.
- Result: **DIAGNOSTIC RETAINED; NO PERFORMANCE WORKAROUND; G5 OPEN; FINAL
  DESTINATION NOT RUN; G6 BLOCKED.** Runtime exited cleanly, corrected module
  `2dce1352...` remained unchanged, and no Simulator is booted.
- Evidence: `docs/artifacts/2026-08-26/g5-css-slow-window-capture.md` and its
  phase, marker, and native-sample files.
- Next: return to the required-stage strict tail with the normal product; only
  reopen the major-menu branch for a multi-second sub-55 recurrence.

## 2026-08-26 — current Fountain strict-control cycle (in progress)

- Goal: re-establish a visually verified, audio-inclusive Fountain combat
  baseline on the current signed runner and corrected module before selecting
  another G5 source change.
- Start state: root `de63c22`, clean `main`; local and `origin/main` agree;
  supplied GALE01 revision-0 image still hashes `2393aadd...`; runner
  `9bff54e4...` and module `2dce1352...` verify and target macOS 14. No runtime
  or Simulator was present.
- Next: watcher-first cold route, explicit Fountain highlight and live-combat
  visual gates, then a capture-free combat phase bracket. Do not run Final
  Destination or begin G6 unless Fountain passes.

## 2026-08-26 — dispatch-boundary candidates rejected

- Control: the fresh visually verified Pikachu-versus-level-1-CPU-Mario
  Fountain interval measured 16.686490 ms mean / 17.622406 ms p95 /
  18.651252 ms p99 / 51.633708 ms worst, or 59.928720 FPS. The tail added
  dispatches and CPU-thread time while guest cycles stayed flat.
- Batch 2: rejected before performance testing. It produced 9 lockstep
  divergences in 88 checks versus the byte-identical batch-1 control's four
  known reports across 163 checks.
- Direct-original: matched the control's 163-check lockstep report set and
  improved aligned title animation from 56.944 to 58.420 FPS while cutting
  >25 ms frames from 626 to 41. A visible Main Menu bracket held 59.940 FPS.
- Required-stage result: the same candidate's visually verified Fountain
  combat bracket measured 20.066726 ms mean / 22.767865 ms p95, only
  49.833741 FPS. The menu win therefore cannot be retained.
- Decision: **BOTH CANDIDATES REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN;
  G6 BLOCKED.** Candidate source was removed and the packaged signed module
  remained `2dce1352...`. No runtime or Simulator remains.
- Evidence: `docs/artifacts/2026-08-26/g5-dispatch-boundary-candidates.md` and
  the screenshots/trimmed phase CSVs named there.
- Next: test chassis-specific original-first dispatch with the unchanged
  generic path on a miss. This preserves alias/host-call semantics while
  avoiding their probes on the common linked-address path. Require matched
  lockstep, title/menu, and Fountain before retention.

## 2026-08-26 — original-first fallback candidate rejected

- Semantics: isolated early-boot lockstep matched the control exactly at 163
  checks, the same four known report PCs, five fallback skips, one zero skip,
  and zero undercharges.
- Visible result: the route entered a coherent Brinstar attract battle at only
  15.1 FPS. This reproduces the class of major slowdown reported by the user
  and shows that the lookup-order saving is not a broad active-scene fix. It
  is not labeled a regression because the battle lacks a matched control.
- Decision: **CANDIDATE REJECTED; G5 OPEN.** Source was restored; the packaged
  app remained on signed module `2dce1352...`; no runtime or Simulator remains.
- Evidence: `docs/artifacts/2026-08-26/g5-dispatch-boundary-candidates.md` and
  `g5-original-first-15fps-attract-regression.jpeg` beside it.
- Next: add default-off generic-dispatch branch counts and compare normal
  title/menu with visually verified Fountain control. Optimize only the hot
  branch and preserve the current ordering; do not pay for another ThinLTO
  candidate without a material per-frame target.

## 2026-08-26 — dispatch branch attribution retained; lookup order rejected

- Attribution: a watcher-gated Main Menu interval counted 373,345,803 generic
  dispatches. All 373,345,803 resolved through generated original code; there
  were zero replacement hits, host probes/hits, aliases, and misses.
- Menu classification: matched packaged-control and lookup-candidate cold
  routes both produced approximately 2.9-second and 3.15-second scene-load
  present gaps. The first rows each represented about 174 ordinary guest
  frames and included about 1.22 seconds of normal throttle sleep; Metal
  presentation was approximately 0.03 ms. Stable menu presentation remained
  59.936/59.928 FPS. The lookup change neither caused nor fixed the gaps.
- Fountain: visibly verified P1 Pikachu, level-1 CPU Captain Falcon, explicit
  Fountain of Dreams, Cubeb, live controls, and a 3,078-frame combat bracket
  measured 16.833022/18.587556/20.262101/101.925583 ms
  mean/p95/p99/worst, or 59.407039 FPS. It fails G5 absolutely and is worse
  than the retained control; Final Destination was not run.
- Visual: a 12-frame adjacent burst after an elongated orange hit silhouette
  showed coherent Pikachu and Falcon proportions through the final countdown.
  This is a bounded non-recurrence; the documented recurrence rule remains.
- Decision: **DEFAULT-OFF BRANCH DIAGNOSTIC RETAINED AS PATCH 0010; LOOKUP
  CANDIDATE REMOVED; G5 OPEN; G6 BLOCKED.** The packaged runner/module remain
  `9bff54e4...`/`2dce1352...`; no runtime or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-26/g5-dispatch-branch-attribution-and-lookup-rejection.md`.
- Next: compare per-address native-dispatch distribution in ordinary Fountain
  frames versus the p95 tail before changing another coherent hot loop. Do not
  retry whole-dispatch ordering, host-probe removal, timers, or isolated
  low-frequency leaves.

## 2026-08-26 — Fountain frame-address and menu-transition attribution

- Visual gate: P1 Pikachu, level-1 CPU Donkey Kong, literal Fountain of Dreams,
  live scripted combat, Cubeb, and a 59.9-61.0 title were observed. The known
  reference-parity lower-floor reflection remained visibly blurred/mirrored.
- Combat: frames 20,687-24,496 measured 16.663833 ms p50 and 17.881404 ms p95.
  Tail frames added about 8,008 native dispatches, distributed across many PCs;
  no single leaf is a material target.
- Menu/transitions: four 1.87-3.17 second rows were CPU-bound and executed
  55-99 million dispatches. Samples resolve to Melee `lbDvd`, `DVDCancel`, and
  interrupt-protected synchronous disc waits; Metal presentation stayed tiny.
- Decision: **DIAGNOSTIC RETAINED; PRODUCT UNCHANGED; G5 OPEN; FINAL
  DESTINATION NOT RUN; G6 BLOCKED.** The temporary runtime closed cleanly and
  no Simulator is booted.
- Next: test Dolphin's existing fast-disc setting as one isolated variable,
  with the corrected deterministic Pikachu/CPU-DK/Fountain route. Reject on
  behavior, determinism/netplay, visual, or measured-transition regression.
- Evidence:
  `docs/artifacts/2026-08-26/g5-fountain-frame-address-attribution.md`.

## 2026-08-26 — fast-disc control rejected

- Isolation: `FastDiscSpeed = True` existed only in a temporary app's
  GALE01r0 layer; the user configuration, product app, module, game inputs,
  and saves were untouched. MemoryWatcher preceded the accepted cold boot.
- Visual gate: coherent CSS, P1 Pikachu, level-1 CPU Donkey Kong, literal
  Fountain of Dreams, live combat, Cubeb, and a 59.9 FPS title were observed.
- Transition result: four 1.85-3.23 second rows remained, with 54-93 million
  dispatches and negligible Metal present time. Each aggregates roughly
  111-193 ordinary guest frames, so it is a scene-change logger gap rather
  than sustained animated-menu FPS.
- Fountain result: the first 2,500 complete combat rows measured 16.671104 ms
  p50 and 17.826824 ms p95. Tail PCs map broadly across HSD/GX rendering work.
- Decision: **FAST-DISC REJECTED/REMOVED; G5 OPEN; FINAL DESTINATION NOT RUN;
  G6 BLOCKED.** The temporary app was restored and re-signed; the isolated
  user directory was moved to Trash; no runtime or Simulator remains.
- Next: preflight coherent cross-segment dispatch reduction with exact SMC,
  exception, host-call, cycle, and event-delivery constraints.
- Evidence: `docs/artifacts/2026-08-26/g5-fast-disc-rejection.md`.

## 2026-08-26 — live Main Menu slowdown rechecked

- Goal: respond to the user's renewed report of clearly major menu slowdown
  without hiding it behind CSS or combat averages.
- Route: restored canonical signed runner/module, phase logger only,
  MemoryWatcher before boot, genuine 134-second title lockout to CSS, then
  deliberate one-second B presses back through VS Mode to Main Menu. Computer
  Use visibly verified each scene; no candidate module or Simulator ran.
- Steady Main Menu: frames 13,064-18,105 averaged 16.684521 ms / 59.936 FPS,
  with 16.946444 ms p95, 17.345228 ms p99, and a 102.551834 ms worst hitch.
  No rolling 1/2/5/10-second window fell below 59.294 FPS. The sustained
  12.5-30 FPS state did not recur in this run, but pacing is not perfect.
- Transitions: four 1.90-3.72 second CPU-bound gaps executed 58-92 million
  dispatches with only 0.019-0.031 ms Metal present time. These are real
  visible freezes, separate from steady animated-menu cadence and Fountain's
  frequent strict tail.
- Input note: ordinary short B taps were missed; one-second holds worked. Keep
  input-duration reliability separate from renderer diagnosis.
- Decision: **SUSTAINED COLLAPSE NOT REPRODUCED; TRANSITION FREEZES AND A
  102.6 MS MENU HITCH REPRODUCED; G5 OPEN; G6 BLOCKED.** No product change.
- Evidence:
  `docs/artifacts/2026-08-26/g5-live-main-menu-reproduction.md`.
- Next: retain the low-overhead slow-window trigger for a recurring sustained
  menu state, but continue the coherent generated-dispatch/codegen experiment
  for the required Fountain tail. Do not retry fast-disc or accept a title
  counter as proof.

## 2026-08-26 — generated chunk-size candidate rejected

- Preflight: the LLVM backend is unavailable in this build, expects LLVM
  19/20 rather than the installed 22.1.8, and rejects non-x86-64 production
  targets. No toolchain mutation was justified.
- Candidate: generated the C backend with 1,024 instructions/chunk instead of
  4,096. It produced 947 hashed chunks and an approximately 72 MB module and
  existed only in a temporary signed app.
- Semantic screen: candidate lockstep recorded 499 checks, seven reports, six
  fallback skips, three zero skips, and zero undercharges; no new divergence
  class appeared in the bounded comparison.
- Visual gate: coherent P1 Pikachu versus CPU Yoshi on literal Fountain, live
  controls, 60.0 title, and known reference-parity lower-floor reflection.
- Performance: frames 13,510-17,163 measured 16.739333 ms mean, 17.866794 ms
  p95, 20.801313 ms p99, and 59.740 FPS. Native dispatches rose to
  161,477.597/frame because smaller generated functions cross boundaries more
  often. The candidate fails G5 absolutely.
- Decision: **C1024 REJECTED/REMOVED; G5 OPEN; G6 BLOCKED.** Canonical module
  `2dce1352...` was restored and the 617 MB candidate tree moved to Trash.
- Evidence:
  `docs/artifacts/2026-08-26/g5-generated-chunk-size-rejection.md`.
- Next: reduce cross-segment return/redispatch cost coherently; preserve SMC,
  exception, host-call, cycle, and bounded-event semantics. Do not retry LLVM
  or smaller C chunks.

## 2026-08-26 — dispatch-frame diagnostic canonicalized

- Clean-chain audit: SunPad plus patches 0002-0010 now apply under `set -e`.
  Patch 0009 required a behavior-neutral missing blank-line context repair.
- Patch 0011 contains only the default-off present-frame/native-PC sampling
  diagnostic. It clean-applies after the full chain, reverse-checks, and
  reproduces all five live source files byte-for-byte.
- The normal path adds no new unsampled dispatch branch; only the existing
  one-in-4,096 sample point records a frame/PC pair when the environment
  variable is enabled.
- Decision: **DIAGNOSTIC RETAINED; PRODUCT DEFAULT UNCHANGED.**

## 2026-08-26 — 8,192-instruction C chunks rejected semantically

- Rationale: the inverse 1,024 experiment added about 33,000 dispatches and
  2.6 ms CPU/frame, so a larger-chunk control was a coherent test of
  cross-segment boundary cost without adding runtime batching.
- Isolation: temporarily extended only the ignored generator's accepted C
  chunk range. A stale sibling generator explicitly warned and emitted 4,096;
  that compile was stopped and trashed. The corrected temporary tool pair
  emitted 119 hashed 8,192-instruction chunks versus canonical 237.
- Build: the isolated 83 MB module linked successfully with SHA-256
  `8bba5fca26361bf0cebe34d05a9d1f54fec262349f244e683e5cf8d701f9e292`.
  It was never copied into the app or active module cache.
- Matched semantic gate: candidate recorded 1,245 checks / 91 reports / seven
  fallback skips / three zero skips / zero undercharges. Canonical C4096 under
  identical settings recorded 1,398 / 88 / seven / three / zero. Candidate
  alone added large memory-journal mismatch entries at `0x80339460`,
  `0x803394C4`, and `0x80339510`.
- Decision: **C8192 REJECTED BEFORE VISUAL/PERFORMANCE TESTING; G5 OPEN; G6
  BLOCKED.** Generator source/binary were restored to the 4,096 limit; the
  548 MB candidate and tools were moved to Trash; product remained canonical.
- Evidence:
  `docs/artifacts/2026-08-26/g5-c8192-semantic-rejection.md`.
- Next: preserve the existing generated segment boundaries in any dispatcher
  optimization, or first improve the verifier so a boundary transformation can
  be proven equivalent. Do not retry larger monolithic chunks.

## 2026-08-26 — direct verified-chunk table rejected on Fountain

- Mechanism: temporary ABI 4 added a generated function-pointer table parallel
  to the unchanged 237 chunk ranges. After the chassis's ordinary SMC and
  host-call guards, it called the already-resolved chunk directly instead of
  repeating the module's address-to-function search. Segment boundaries,
  cycle flushes, exceptions, host calls, and event checks were unchanged.
- Semantic gate: candidate recorded 1,401 checks / 88 reports / seven fallback
  skips / three zero skips / zero undercharges. The matched canonical control
  recorded 1,398 / 88 / seven / three / zero with the same printed report
  sequence. The candidate therefore passed the bounded lockstep screen.
- Visual correction: the retained selector route visibly produces CPU Yoshi,
  not Ness. Computer Use verified P1 Pikachu, CPU Yoshi, literal Fountain of
  Dreams, coherent live combat, and the normal Yoshi winner screen.
- Performance: clean frames 17,000-21,742 measured 16.933658 ms mean,
  16.766791 ms p50, 18.752725 ms p95, 20.255358 ms p99, 33.403667 ms worst,
  and 59.053986 FPS. CPU-thread mean/p95 were 16.646930/18.567576 ms;
  native dispatches averaged 137,923.653/frame with flat 8,107,174.581 guest
  cycles/frame. It fails G5 absolutely.
- Decision: **DIRECT CHUNK TABLE REJECTED/REMOVED; ABI 3 AND GENERIC DISPATCH
  RESTORED; G5 OPEN; G6 BLOCKED.** Product app/module were never changed;
  temporary app/build/evidence moved to Trash.
- Evidence:
  `docs/artifacts/2026-08-26/g5-direct-chunk-table-rejection.md`.
- Next: do not retry module lookup/layout shortcuts. Attribute the repeated
  Fountain-only regression before another dispatch implementation change.

## 2026-08-26 — exact canonical Yoshi control confirms direct-table regression

- Route hygiene: an initial cold watcher exited before the controller FIFO
  existed and produced no input; it was not measured. The same memory-gated
  route was reissued only after the canonical runner was live.
- Visual gate: Computer Use verified P1 Pikachu, level-1 CPU Yoshi, literal
  Fountain of Dreams, active combat, and the normal Yoshi result screen. The
  capture is performance evidence only; the distorted lower-floor reflection
  remains outside a visual-correctness claim.
- Canonical result: frames 21,625-26,367 measured 16.762538 ms mean,
  17.553780 ms p95, 19.125174 ms p99, and 59.656839 FPS. Guest cycles matched
  the candidate, while canonical native dispatches were about 3,537/frame
  lower.
- Attribution: versus the same 4,743-frame Pikachu/Yoshi Fountain control, the
  rejected direct table added 0.171120 ms mean and 1.198945 ms p95. Its
  regression is confirmed; both paths still fail strict G5.
- Decision: **DIRECT TABLE REMAINS REJECTED; G5 OPEN; G6 BLOCKED.** The next
  bounded preflight is whether the loop can carry its already-verified chunk
  index and avoid duplicate resolution without changing semantic boundaries.
  The separate 1.90-3.72 second menu-transition freezes remain open.
- Evidence:
  `docs/artifacts/2026-08-26/g5-direct-chunk-matched-yoshi-control.md`.

## 2026-08-26 — last-chunk cache rejected on active-scene failure

- Preflight: the core contained an unused `m_last_chunk_index`. A temporary
  DOL-only fast path returned it only when the new PC remained within that
  exact module chunk; every miss and all REL mappings retained canonical
  lookup behavior.
- Semantic screen: the bounded 5,000,000-dispatch run reached the canonical
  88-report set, with no new divergence class observed.
- Route honesty: the memory-gated route entered an opening/demo sequence and
  timed out before CSS. Its 41.87-second readiness result is excluded. Long B
  returned to title; later input reached coherent attract and How-to scenes.
- Performance: active How-to frames 19,396-20,874 measured 20.352699 ms mean,
  24.562912 ms p95, and 49.133532 FPS. The title showed 48.6-50.7 FPS and
  attract combat 37.5-39.2 FPS. These are absolute candidate failures, not a
  matched regression against canonical.
- Decision: **LAST-CHUNK CACHE REJECTED/REMOVED; G5 OPEN; G6 BLOCKED.** Source
  and both local runners were rebuilt canonical; product runner/module hashes
  remained `9bff54e4...` / `2dce1352...`; temporary app/run moved to Trash.
- Evidence: `docs/artifacts/2026-08-26/g5-last-chunk-cache-rejection.md`.

## 2026-08-26 — CPU counters split combat from How-to

- Computer Use visually gated live four-player Pokemon Stadium combat at
  50.3 FPS and the real Mario/Bowser How-to fight at 46.1 FPS in one uniquely
  identified diagnostic runner.
- Apple CPU Counters measured the four-player CPU thread at 53.6% instruction
  delivery / 33.1% useful, but How-to at 20.2% delivery / 74.7% useful.
  Therefore a broad generated-code outlining theory does not explain both
  slow paths.
- How-to frames 19,250-19,450 independently averaged 21.252 ms total and
  20.493 ms CPU-thread work with about 41,372 dispatches/frame.
- Two combat-hot chunks had 36-38% smaller standalone `-Oz` native text, but
  both full-link routes reproduced the byte-identical canonical dylib. No
  materially different artifact existed, so semantic/performance testing was
  correctly skipped.
- Decision: **BROAD OUTLINING REJECTED; G5 OPEN; G6 BLOCKED.** Exact canonical
  objects/module/product restored. Next is a clean visually gated How-to native
  sample combined with its frame-PC log, followed by one named routine/helper.
- Evidence:
  `docs/artifacts/2026-08-26/g5-front-end-pressure-preflight.md`.

## 2026-08-26 — THP attribution and inline FP gate rejected

- Existing How-to CPU Counter stacks mapped 68.09% of CPU samples to generated
  `0x8032D940` and 11.54% to `0x80331940`. GALE01 symbols identify THP video
  decompression; the instructional fight is a movie, not normal live combat.
- A regression-first emitter candidate skipped `ppc_fp_available` only when
  `MSR.FP` was already set. Generated-C compile, enabled execution, and exact
  disabled-FP exception behavior passed.
- The candidate lockstep screen passed at 1,401 checks / canonical 88 reports /
  seven fallback skips / three zero skips / zero undercharges.
- Candidate text grew 855,404 bytes. Computer Use then verified coherent
  four-player combat at 39.1 FPS; clean frames 8,050-8,250 averaged 26.055 ms /
  38.380 FPS and 25.037 ms CPU-thread work. How-to/Fountain were not run after
  this absolute ordinary-combat failure.
- Decision: **INLINE FP GATE REJECTED/REMOVED; G5 OPEN; G6 BLOCKED.** Canonical
  generator/tests/tools/module/product restored; candidate moved to Trash.
  Next: default-off THP-time external-write address histogram.
- Evidence: `docs/artifacts/2026-08-26/g5-thp-fp-gate-rejection.md`.

## 2026-08-26 — locked-cache THP gain rejected on matched combat

- A temporary one-in-64 external-write histogram was excluded from timing but
  proved the address mechanism: 99.588560% of 8,389,081 sampled writes hit
  locked cache, 8,365,843 were one byte, and the leading PCs were THP decode.
- A direct in-bounds locked-cache store retained the existing lockstep journal
  and passed 1,401 checks / 88 canonical reports / seven fallback skips /
  three zero skips / zero undercharges.
- Computer Use verified the same Mario/Bowser How-to movie. Mean fell from
  21.251930 to 16.564629 ms and CPU-thread work from 20.492810 to
  13.597789 ms, confirming material per-byte MMU overhead.
- The original candidate Fountain range was ambiguous in a mixed log and was
  excluded. Fresh immutable files then visually and numerically matched P1
  Pikachu versus CPU Pikachu on literal Fountain using the same 1,877-row
  twelve-cycle sequence.
- Canonical measured 16.801288 ms / 59.519246 FPS / 18.391276 ms p95. The
  candidate measured 17.932665 ms / 55.764160 FPS / 20.200351 ms p95, with
  flat guest cycles and zero static fallback steps.
- Decision: **LOCKED-CACHE CANDIDATE REJECTED/REMOVED; THP ATTRIBUTION
  RETAINED; G5 OPEN; G6 BLOCKED.** Canonical source runner and packaged
  runner/module hashes are restored; no runtime or Simulator remains.
- Next: a host-only THP-scoped preflight must separate locked-cache
  translation/journaling cost from the byte store. Do not retry a global
  memory path, per-PC shortcut, or per-write observer.
- Evidence:
  `docs/artifacts/2026-08-26/g5-locked-cache-fast-path-rejection.md`.

## 2026-08-26 — locked-cache byte-write chassis host preflight

- A temporary arm64 Release target linked Dolphin's real `core`, initialized
  its actual L1 buffer, and timed five fresh processes. Each path used the
  median of 11 rounds x 2,000,000 permuted one-byte stores over 16 KiB.
- Median process results were 6.765 ns/write for canonical `MMU::Write<u8>`,
  5.446 ns after bypassing `Memcheck`, 1.356 ns for null journal check plus
  direct store, 2.289 ns with stable MSR propagation restored, and 1.018 ns
  for the raw store.
- Attribution: `Memcheck` costs about 1.319 ns; the remainder of generic
  `WriteToHardware` beyond journal/direct costs about 4.090 ns. Preserving the
  MSR check still leaves about 4.476 ns/write of theoretical headroom.
- Decision: **ATTRIBUTION RETAINED; NO PRODUCT CHANGE; G5 OPEN; G6 BLOCKED.**
  The microbenchmark does not override two global locked-cache runtime
  rejections. Temporary target/source/MMU wrapper were removed, the build
  cache returned to tests-off, and the source runner rebuilt canonical.
- Next: inspect the exact generated `0x8032D940`/`0x80331940` THP chunks
  offline for contiguous store runs and define a bulk semantic regression
  before another game build. Do not retry a per-write or per-PC shortcut.
- Evidence:
  `docs/artifacts/2026-08-26/g5-locked-cache-write-chassis-preflight.md`.

## 2026-08-26 — paired PSQ transactions retained; stale module cache fixed

- Offline inspection counted 384 paired-store sites across THP's two dominant
  generated chunks. Dolphin writes non-`W` pairs as one 16/32/64-bit memory
  transaction; GXRuntime performed two independent lane writes.
- Regression-first coverage now proves exact external address, combined value,
  size, and count for float, U8, U16, S8, and S16 pairs while preserving the
  `W=true` single-lane path. `gxruntime_tests`, 16/16 controller tests,
  bootstrap, repository audit, and patch apply/reverse checks pass.
- Attribution audit rejected the first runtime result: the module builder had
  reported a cache hit and packaged the canonical module, so those metrics are
  excluded and their temporary files moved to Trash.
- `moderngekko-port` now fingerprints GXRuntime headers/core sources and the
  module template. It built new key `1e1debc9fb83a31a`, wrote
  `module_sources=7dcfd35e31be989b`, then hit that exact key on repeat.
- The genuine distinct candidate visibly completed coherent Pikachu versus
  level-1 CPU Mario on literal Fountain. Frames 12,864-14,740 measured
  16.709787 ms / 59.845168 FPS / 18.216709 ms p95 with zero fallbacks.
- The genuine Mario/Bowser How-to movie improved from canonical 21.251930 ms /
  47.055 FPS / 20.492810 ms CPU-thread mean to 16.677963 ms / 59.959 FPS /
  11.094652 ms. Candidate p95 remains 17.875625 ms.
- The new cache-built module was promoted into the signed local product;
  codesign and macOS-14 checks passed, and a visual opening-THP smoke measured
  16.672 ms over the latest 120 frames.
- Decision: **PAIR TRANSACTIONS RETAINED; CACHE IDENTITY RETAINED; G5 OPEN;
  G6 BLOCKED.** Next is retained-candidate Fountain body/tail attribution and
  one newly sampled live-rendered hotspot, not another global MMU/timer/FP
  shortcut.
- Evidence:
  `docs/artifacts/2026-08-26/g5-paired-store-transactions-retained.md`.

## 2026-08-26 — paired PSQ loads rejected on live Fountain combat

- Goal/step: G5, test the symmetric paired-load transaction hypothesis after
  paired stores materially improved THP.
- Regression/build: exact external-read transaction tests failed first and
  then passed; full GXRuntime tests passed; distinct source cache key
  `60192f7ab4d77b40` rebuilt and repeated as an exact hit.
- Runtime: Computer Use verified Pikachu versus level-1 CPU Yoshi on literal
  Fountain. Menus held 59.9-60.0 FPS; combat fell to 53.7 FPS. Frames
  57,144-61,721 measured 19.178837 ms mean, 21.220959 ms p95, 52.141 FPS,
  and only 3.189% <=16.7 ms. CPU-thread mean was 18.779152 ms; guest cycles
  were flat and fallbacks zero.
- Decision: **candidate rejected and removed; paired-store build restored; G5
  open; G6 blocked.** The signed product was never modified.
- Evidence:
  `docs/artifacts/2026-08-26/g5-paired-load-transaction-rejection.md` and
  `docs/evidence/g5-paired-load-rejection/pikachu-yoshi-fountain.phase.csv`.
- Next: build a diagnostic-equivalent retained module with source line tables,
  take a no-frame-PC-log Fountain native sample, and map the two broad hot
  chunks to one named routine/helper before changing product code.

## 2026-08-26 — line-symbol Fountain attribution; GQR0 split rejected

- A line-table-only diagnostic module retained an exact 81,633,512-byte
  `__text` and exact retained `__text` SHA. Computer Use verified Bowser versus
  level-1 CPU Ness on literal Fountain before a normal 20-second native sample.
- Six source-line PCs totaling 283/8,892 chassis samples map to
  `WriteMTXPS4x3`, which performs six GQR0 paired loads and six paired stores
  to the GX FIFO. The known `0x80349494` scheduler loop remains excluded.
- A guarded default-float GQR0 helper failed at link first, then passed exact
  paired/single/quantized-fallback/HID2 tests, GXRuntime 1/1, and DolRecomp
  14/14. Distinct cache key `714512b16f05c99a` built successfully.
- Visually verified Bowser/CPU-Ness Fountain frames 41,579-47,064 measured
  20.823964 ms / 48.022 FPS / 23.354708 ms p95. CPU-thread mean was
  20.331661 ms; guest cycles stayed near 8.107M, dispatches rose to 149,651,
  and fallbacks stayed zero. Adjacent retained screens show coherent meshes.
- Decision: **GQR0 helper split rejected and removed; attribution retained; G5
  open; G6 blocked.** The retained paired-store key is active, promoted product
  was never modified, and no runtime or Simulator remains.
- Next: host-only exact ordered GX FIFO matrix-batch preflight before another
  module build. Do not retry this call split or global/guest-PC shortcuts.
- Evidence:
  `docs/artifacts/2026-08-26/g5-line-symbolized-fountain-attribution.md` and
  `docs/artifacts/2026-08-26/g5-gqr0-store-fast-path-rejection.md`.

## 2026-08-27 — 64-bit gather-pipe width candidate rejected

- A temporary real-GPFifo benchmark verified identical big-endian bytes and a
  stable roughly 8x isolated advantage for `Write64` over eight `Write8`
  calls. A regression-first one-arm candidate passed matched bounded
  lockstep: 1,398 checks, 91 reports, seven fallback skips, three zero skips,
  and no undercharge.
- An exact rebuilt control and candidate each completed a 7,430-row
  load-to-results Fountain interval. The candidate regressed from 18.678609
  to 19.578675 ms mean and from 20.974708 to 22.605417 ms p95.
- The wall-time input script could shift actions across emulated frames, so a
  no-P1-input pair was run. It aligned at 7,431 rows, but CPU AI still diverged
  from 148,239.920 to 183,024.690 dispatches/frame. Candidate mean was only
  0.255 ms lower and p95 was 1.726 ms worse.
- A shared-state replay was attempted without product edits. `SIGUSR1`
  terminated the branded runner because only Dolphin's standalone main
  installs that handler; native save shortcuts produced no state file. No
  causal shared-state claim is made.
- Decision: **candidate rejected/removed; G5 open; G6 blocked.** Canonical
  runner rebuilt, `gcpipe` passes 16/16, focused CTest passes 4/4, promoted
  codesign and hashes are unchanged, and no runtime or Simulator remains.
- Next: expose a verified save/load state path or emulated-frame-gated input
  replay before integrating another performance candidate.
- Evidence:
  `docs/artifacts/2026-08-27/g5-gpfifo64-rejection.md`.

## 2026-08-27 — deterministic save/load harness retained

- The 64-bit gather rejection exposed wall-time input and CPU-AI divergence,
  so a shared state became the lowest G5 measurement prerequisite.
- Failing before: `SIGUSR1` killed the branded runner because only Dolphin's
  standalone main installed handlers. After adding scoped default-off
  handlers, the process survived and logged the request but wrote no file.
- Root cause: the custom runtime skipped `UICommon::CreateDirectories()` after
  selecting its user directory. The retained fix adds that standard step and
  installs save/load handlers only when
  `MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1` on supported desktop hosts.
- Live proof: `SIGUSR1` wrote a 9.2 MB `GALE01.s01`; after visible attract
  progress, `SIGUSR2` rewound the scene, the process survived, and telemetry
  continued. The RAM-bearing state remains local and uncommitted.
- Patch 0013 reverse/forward checks and bootstrap pass. Focused CTest passes
  4/4, `gcpipe` passes 16/16, and repository safety passes.
- The canonical packager promoted signed runner
  `5121b6be59b19094f1995ec483626ff9a7206f73850ed2556aa144427c6dc546`
  with the unchanged retained module; both declare macOS 14.0 minimum. The
  previous app remains in the timestamped local backup.
- Decision: **harness retained; G5 open; G6 blocked.** Next is a visually
  verified late-Fountain shared state loaded into control and candidate with
  aligned frame, guest-cycle, and dispatch counts.
- Evidence:
  `docs/artifacts/2026-08-27/g5-deterministic-savestate-harness.md`.

## 2026-08-27 — emulated-frame shared-state bracket

- The first late-Fountain state attempt was reclassified as test latency: the
  game had only about 20 seconds left and continued running before `SIGUSR1`.
  Source inspection confirmed Dolphin pauses the static core through
  `SyncOut` before serialization and returns through `SyncIn` after load.
- A fresh Pikachu/level-1-CPU-Fox Fountain state saved at 1:45.69 and visibly
  restored from a divergent 1:37.79 scene to 1:47.02 with the saved 40%/0%
  damage state. Its SHA-256 is recorded locally but the RAM-bearing file is
  excluded from the repository.
- Equal presentation-row repeat runs failed to match. Patch 0014 now publishes
  Dolphin's savestated VI/Movie frame through an atomic and logs it beside the
  existing presentation index. Two equal 440-emulated-frame controls then
  matched exactly at 3,567,157,803 cycles, 59,374,686 dispatches, and 905,158
  bursts.
- The `GPFifo::Write64` arm was rerun in an A/B/reverse-A bracket. Warm
  candidate rows ranged 22.391-23.311 ms mean; reverse controls ranged
  21.459-22.360 ms. The ranges overlap and the fastest reverse control won.
  Candidate p95 also ranged 24.597-25.897 ms, with a 30.585 ms cold row.
- Decision: **patch 0014 retained; gather arm removed; G5 open; G6 blocked.**
  Future candidates must use shared state plus equal emulated-frame intervals.
  Next is one newly attributed compute hotspot inside the retained window.
- Verification: patch reverse/forward passes, Release runner rebuild passes,
  bootstrap passes, `gcpipe` 16/16, focused CTest 4/4, repository check passes,
  canonical package codesign passes, runner/module hashes are
  `9d0fdf87...`/`2fe01870...`, both declare macOS 14.0 minimum, and no game
  process or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-27/g5-emulated-frame-shared-state-verdict.md`.

## 2026-08-27 — transparent instruction PC-elision rejection

- Exact late-Fountain Apple counters attributed 48.674% of CPU-thread time to
  instruction delivery. A regression-first DolRecomp candidate removed PC
  writes before non-branch instructions already classified as transparent.
- The narrowed implementation preserved branch/timebase semantics, passed
  DolRecomp 14/14 and the current 1,398-check live lockstep report set, removed
  28.5% of generated `ctx->pc` stores, and shrank text by 1,475,528 bytes.
- Equal emulated frames reversed the apparent gain: candidate 20.149624 ms
  mean / 21.983167 ms p95 versus canonical 19.016881 / 20.575625 ms, with only
  three guest cycles and one dispatch of work difference.
- Decision: **candidate removed; G5 open; G6 blocked.** Active module key
  `1e1debc9fb83a31a` is restored. Next is a newly measured dynamic hotspot in
  the exact shared-state window, not another static code-size shortcut.
- Evidence:
  `docs/artifacts/2026-08-27/g5-transparent-pc-elision-rejection.md`.

## 2026-08-27 — FP-availability inline rejection

- A host preflight saved 0.413-0.463 ns per enabled-FP check; a compile probe,
  focused semantics, bootstrap, and a 1,367-PC lockstep screen passed.
- One load at emulated frame zero trapped in `DVDThread::WaitUntilIdle` while
  the emulation thread was starting. Requiring frame >1,000 before `SIGUSR2`
  loaded the retained state cleanly and is now a harness rule.
- Equal-frame A/B/A was mixed then negative: repeat candidate 19.035697 ms
  mean / 20.830500 ms p95 versus canonical 19.001550 / 20.675166 ms; its first
  CPU-thread gain did not reproduce.
- Decision: **candidate removed; G5 open; G6 blocked.** Canonical active key
  `1e1debc9fb83a31a` is restored.
- Evidence:
  `docs/artifacts/2026-08-27/g5-fp-availability-inline-rejection.md`.

## 2026-08-27 — PSMTXConcat replacement preflight rejection

- Exact late-Fountain lines `27446..27861` map to the complete SDK
  `PSMTXConcat` body at guest `0x803408D4..0x8034099C`; the coarse symbol map
  is wrong for this local routine.
- A disposable exact-DOL replacement matched full CPU state, 48 output bytes,
  and 64 scratch-stack bytes across 20,000 randomized finite trials. Integrated
  cost fell from 169-202 ns to 52-61 ns per call.
- The same dylib added 2.04-2.40 ns to each non-hit public replacement probe.
  At roughly 130,000 dispatches/frame this costs 0.27-0.31 ms, requiring over
  2,200 matrix hits/frame just to break even. Sampling predicts only a
  few-hundredths-of-a-millisecond net opportunity.
- Decision: **candidate removed before live testing; G5 open; G6 blocked.** The
  active pointer remains canonical and the packaged app was untouched. Next:
  identify a larger coherent exact-window kernel or a general optimization
  with no per-dispatch tax; do not add a common-path guest-PC shortcut.
- Evidence:
  `docs/artifacts/2026-08-27/g5-psmtxconcat-replacement-preflight-rejection.md`.

## 2026-08-27 — computed-label entry decoder rejection

- Exact line-zero samples inside generated chunks were attributed to initial
  intra-chunk `ctx->pc` decoding rather than an unnamed guest routine.
- A regression-first computed-label candidate retained the canonical 4,096-
  instruction chunks, passed focused tests 3/3, and linked the complete 237-
  chunk module under ThinLTO.
- Linked native code proved the canonical dense switch is already a constant-
  time 32-bit relative jump table. The candidate's 64-bit pointer tables moved
  5.10 MB out of text but added 7.75 MB of read-only data, growing total VM by
  2.70 MB; the hot chunk stack frame also doubled. Standalone timings were
  mixed and did not repeat a meaningful gain.
- Decision: **candidate removed before lockstep/live testing; G5 open; G6
  blocked.** Canonical generated output and focused tests pass 3/3. Active
  module and package were untouched; no game process or Simulator remains.
- The supplied incident `9AE31C76-671C-42F8-89AF-D64EE5BA5059` was also
  reconciled to the already-documented premature savestate-load trap while the
  emulation thread was still starting. It adds no new canonical crash.
- Evidence:
  `docs/artifacts/2026-08-27/g5-computed-label-entry-decoder-rejection.md` and
  `docs/artifacts/2026-08-27/g5-fp-availability-inline-rejection.md`.

## 2026-08-27 — scalar FMA semantics retained and promoted

- Exact-window attribution selected `ppc_fma` as the largest untested runtime
  helper, but regression-first work found a correctness defect rather than a
  speed opportunity: 3,677 generated scalar FMA sites missed normal `fmadds`
  FI/FR and NI-mode single-subnormal flushing.
- DolRecomp patch 0002 routes all eight scalar FMA forms through the existing
  exact instruction helper; Dolphin patch 0015 adds single/double,
  add/subtract, negative, lane, FI/FR, NI, and VE-gated sNaN regressions.
- Fresh DolRecomp 14/14 and GXRuntime 1/1 pass. Bounded lockstep matched at
  1,367 PCs, 91 reports, zero undercharges, and byte-identical divergence
  entries. Clean patch apply/reverse/source identity and bootstrap pass.
- Equal emulated frames kept work within 22 cycles/four dispatches. Warmed
  candidate was 19.127040 ms / 52.282 FPS / 21.457875 ms p95 versus canonical
  18.967010 / 52.723 / 20.397875; the cold 40.343472 ms candidate is retained
  as a host/cache outlier, not source causality.
- The official exact-ISO build produced key `d852344fce9334dc`. Signed package
  and active module have identical `__text` SHA-256 `ac3089f2...`; strict
  codesign, `gcpipe` 16/16, focused CTest 4/4, and repository safety pass.
- Computer Use retained a coherent packaged Pikachu/CPU-Fox Fountain frame at
  52.5 FPS with no visible character morphing. The runtime was stopped and no
  Simulator was booted.
- Decision: **retain/promote exact FMA semantics; not a performance win; G5
  open; G6 blocked.** Next is a fresh exact-window native sample of the
  promoted build, excluding known scheduler and corrected FMA work.
- Evidence:
  `docs/artifacts/2026-08-27/g5-scalar-fma-semantics-retained.md`.

## 2026-08-27 — diagnostic-overhead gate rejection

- The fresh promoted sample separated real CPU work from observer cost: full
  phase logging put 429 top samples in thread/wall clocks, while a normal
  no-logger packaged run still showed only 53.3-55.3 FPS on the retained
  Pikachu/CPU-Fox Fountain state. A live four-player Brinstar attract scene
  also reached 22.9 FPS, confirming a genuine heavy-scene product slowdown.
- A failing-before source contract drove one default-off diagnostic gate. The
  Release candidate removed `ShouldCheck` from the normal sample and reduced
  `StaticRecompCore::Run` self samples 309 to 274, but rolling-title gain was
  only 0.8-1.1 FPS.
- Exact emulated frames rejected the candidate: 18.997244 ms / 52.639 FPS /
  20.771917 ms p95 versus promoted control 18.926719 / 52.835 / 20.781917.
  Work matched within 14 cycles and three dispatches. All candidate source and
  its regression were removed; package/module remained promoted and unchanged.
- The restored Release runner rebuild passes; focused CTest passes 4/4,
  `gcpipe` passes 16/16, repository safety passes, and no runtime or Simulator
  remains.
- The pasted incident `9AE31C76-...` is the already-documented temporary
  fp-inline frame-0 load crash, not a new promoted-build failure.
- Decision: **candidate removed; G5 open; G6 blocked.** Next is line-symbol
  attribution inside `func_8035D940`/`func_8033D940`, the largest unexplained
  no-logger generated work.
- Evidence:
  `docs/artifacts/2026-08-27/g5-diagnostic-overhead-gate-rejection.md`.

## 2026-08-27 — multiword range helpers retained and promoted

- A promoted no-logger line-table sample placed 251/11,849 CPU-thread samples
  in generated `lmw`/`stmw` work. Clang already unrolled the register loops;
  repeated RAM classification and store bookkeeping were the remaining cost.
- A failing-before GXRuntime contract drove whole-range helpers with exact
  per-word fallback. Permanent tests cover base-register overwrite, mirrors,
  EXRAM, journal offsets, and reservation cache-line invalidation.
- Host preflight excluded unprofitable short stores. An inline implementation
  was rejected structurally (+665,028 bytes `__text`); the retained shared
  helper instead removes 331,796 bytes from `__text`.
- Exact `48123..48562` A/B/A2 reproduced a 0.21-0.24 ms CPU-thread gain:
  candidate means 18.719603/18.681924 ms versus control 18.848329 ms. Work is
  equal or within eight cycles/four dispatches. Candidate A had two host-tail
  stalls, so no tail-latency improvement is claimed.
- Clean patch forward/reverse/source identity, dependency bootstrap,
  GXRuntime, DolRecomp 14/14, official 237-chunk build, and strict packaging
  pass. Official key is `b2d4b69da942f7c2`; the tested and official unsigned
  dylibs are byte-identical.
- Direct UI inspection retained coherent active Pikachu/Fox Fountain combat
  at a 54.7 FPS title reading with no visible morphing. The process was stopped
  and no Simulator is booted.
- Decision: **retain/promote the small improvement; G5 remains open; G6 remains
  blocked.** Next is a fresh no-logger sample of the promoted module and a new
  coherent dynamic cost, excluding inline/short multiword forms and prior
  rejected common-path shortcuts.
- Evidence:
  `docs/artifacts/2026-08-27/g5-multiword-range-helpers-retained.md`.

## 2026-08-27 — deterministic GPFIFO64 retry rejected

- Fresh promoted no-logger sampling and a byte-identical `__text` line-table
  twin reconfirmed the six `WriteMTXPS4x3` paired stores as a concrete hot
  path after PERF-057.
- The retained savestate harness resolved the missing prerequisite from the
  old gather-width rejection. A failing-before contract drove one explicit
  8-byte `GPFifo::Write64` arm.
- Candidate A/A2 and a same-build local reversal selected frames
  `48123..48562` and exactly matched 1,501,629,399 cycles, 51,369,928
  dispatches, 905,572 bursts, and 882 hook fallbacks.
- Candidate means 16.680304/16.884788 ms lost to reversal 16.516704 ms. A's
  0.048 ms CPU-mean advantage did not repeat in A2, and p95 stayed above the
  strict gate. The candidate is rejected and removed.
- The signed packaged runner executed different work in the nominal interval;
  that row is retained as contaminated evidence and not used as a control.
- Decision: **G5 open, G6 blocked.** Do not retry gather width or the same
  matrix writer. Next aggregate non-entry `func_8035D940` lines and select a
  different coherent dynamic cost.
- Evidence:
  `docs/artifacts/2026-08-27/g5-gpfifo64-deterministic-rejection.md`.

## 2026-08-27 — dominant scalar-FMA mode split rejected at preflight

- Fresh promoted attribution left `ppc_fmadd_op` as a cross-routine cost: 356
  CPU-thread samples and 3,677 generated calls. The single/add/non-negative
  constant mode accounts for 2,199 calls.
- A disposable fixed-mode clone passed eight 20,000-case complete-`CPUState`
  semantic batches, including edge bit patterns and randomized operands.
- Fifty-six paired five-million-operation timing runs averaged 19.362982 ns
  for the specialization versus 19.347089 ns generic. The near-even 29/27 win
  split and 0.999179 ratio of means provide no repeatable host speed signal.
- Decision: **reject before module/game build**. No repository source, active
  module, package, game process, or Simulator changed. Do not retry outer FMA
  flag splitting; if fresh sampling still selects FMA, attribute an exact
  inner classification/rounding operation first. G5 remains open; G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-27/g5-fma-mode-split-preflight-rejection.md`.

## 2026-08-27 — finite-normal FPRF preflight rejected

- Exact arm64 offset attribution moved the remaining scalar-FMA question from
  outer mode flags to force-single/classification/FPSCR writeback.
- A disposable finite-normal fast path passed six aggregate semantic batches:
  one million classification comparisons and 100,000 complete-state scalar-FMA
  comparisons per batch.
- Corrected finite-normal timing rejected it decisively: 54 paired five-million
  operation runs averaged 9.364704 ns candidate versus 7.144759 ns control;
  the candidate lost all 54 pairs.
- Decision: **PERF-060 rejected before module/game build; G5 open; G6 blocked.**
- Evidence:
  `docs/artifacts/2026-08-27/g5-fprf-hotpath-preflight-rejection.md`.

## 2026-08-27 — stale current-source PGO oracle rejected

- Current generated source was linked with the excluded old exact-no-input
  profile only as an oracle. Clang reported widespread missing data and
  mismatched function hashes; the disposable module grew `__text` by 2.35 MB.
- Its nominal `48123..48562` package interval executed 3,567,157,806 cycles and
  measured 24.378538 ms mean / 53.859334 ms p95 / 18.377052 ms CPU mean.
- Decision: **PERF-061 rejected; no private profile/module promoted.** Do not
  retry the stale profile. G5 remains open and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-27/g5-stale-pgo-oracle-rejection.md`.

## 2026-08-27 — packaged revision-idle configuration retained

- The signed package and same-module local runner were executing different
  work because the app's Sys layout and extracted-DOL boot path prevented
  `GALE01r0.ini`'s `StaticRecompIdlePC` from reaching the core.
- A failing package-layout check, compile-command audit, and temporary two-point
  trace established the full mechanism. The traces were removed.
- The retained fix adds explicit app-bundle mode, packages Sys in
  `Contents/Resources`, records `boot.bin` revision, and seeds the exact idle
  setting into the current-run layer before CPU initialization.
- Clean signed package A/A2 selected identical 440-field work at 1,501,629,399
  cycles and 51,369,928 dispatches. Means improved to 16.514379/16.574602 ms
  (60.553/60.333 FPS) from the old package's 18.626525 ms.
- Strict p95 still fails at 18.281042/18.259292 ms; only 65.682%/57.500% of
  rows meet 16.7 ms. Average 60 is real, stable 60 is not yet proven.
- Decision: **PERF-062 retained; G5 open; G6 blocked.** Next attribute the
  exact idle-enabled package tail; do not retry scheduler, timer, stale-PGO,
  package-path, or gather-width changes.
- Evidence:
  `docs/artifacts/2026-08-27/g5-packaged-idle-config-retained.md`.

## 2026-08-27 — fresh current-source combat PGO retained as oracle

- A combat-gated profile from exact promoted source key `b2d4b69da942f7c2`
  covered 6,556 functions and built without stale/mismatched-profile warnings.
- Exact `48123..48562` candidate/control/candidate work matched at
  1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, and 882 hooks.
- Candidate CPU-thread mean repeated at 11.888651/11.606481 ms versus control
  15.941134 ms. Total p95 improved to 17.608188/17.775729 ms from 18.123332
  ms, but strict 16.7 ms still fails.
- Disabling precision frame timing preserved compute but worsened wake-lateness
  p95 to 2.124091 ms and total p95 to 18.227265 ms; ordinary sleep is rejected.
- Whole-module disassembly shows selective PGO behavior rather than blanket
  outlining: `ppc_fp_available` direct sites fall by 10,502 and several FP/PSQ
  call classes shrink while `__text` grows 723,904 bytes.
- Computer Use retained a coherent 59.9 FPS-title Pikachu/CPU-Fox Fountain
  frame. No fighter morphing appears; the lower reflection is reference parity.
- Decision: **PERF-063 is a local oracle, not a reproducible product module;
  G5 open; G6 blocked.** Next diff exact PGO optimization remarks/eliminated
  hot calls and test one untried semantics-complete common case. Do not retry
  timer, blanket FP inlining, global PSQ load, cold-symbol outlining, or outer
  FMA mode splits.
- Evidence:
  `docs/artifacts/2026-08-27/g5-current-source-combat-pgo-oracle.md`.

## 2026-08-27 — PGO inline decisions resolved; one-site clone rejected

- A byte-identical ThinLTO remark relink emitted 244 private YAML shards with
  44,741 successful and 241,479 missed inline decisions.
- Successful hot calls are aggregate: 41,671 FP-availability, 746 long-load,
  585 scalar-multiply, 464 FMA, 61 PSQ-load, and 36 PSQ-store sites. Hot
  threshold 3,000 versus cold 325/45 explains the prior blanket-inline loss.
- Coverage mapping resolved the hottest short `lmw` to revision-0
  `0x8036E8B4`, about 3.09M training executions. Retained preflight shows only
  about 1 ns/call available from one fixed short-range inline, far too little
  to explain 4.2 ms/frame. Reject before module/source change.
- The validated candidate is installed locally as
  `build-macos/SsbmPad-PGO.app`; canonical `SsbmPad.app` is unchanged. Strict
  signature, package layout, architecture, minimum OS, and no-game-data scan
  pass.
- Decision: **no static one-site candidate; G5 open; G6 blocked.** Preserve
  selective PGO as the oracle and avoid a large derived guest-address list.

## 2026-08-27 — Current-PGO pacing controls rejected

- Exact PGO p95 tails do less guest work and retain about 11.7 ms CPU-thread
  mean, while throttle wake lateness rises to 0.859-0.976 ms.
- A MemoryWatcher-gated buffered logger with no phase counters independently
  fails at 17.956 ms p95 / 22.767 ms p99 / 113.255 ms worst.
- VSync and PresentDrawable-only fail with 130.294/79.016 ms stalls and change
  nominal boundary work; both are rejected and their processes stopped.
- A new `DISPATCH_TIMER_STRICT` host mode passes 16.691 ms p95 but fails the
  absolute p99/worst gate at 16.712/18.358 ms. ASan/UBSan caught and verified
  the fix for an initial fifth-mode `%4` harness bug. No Dolphin build followed.
- Decision: **PERF-064 rejects all three controls; G5 open; Final Destination
  and G6 blocked.** Next measure actual Metal `presentedTime` in a host-only
  scheduled-presentation harness before considering any product pacing move.
- Evidence:
  `docs/artifacts/2026-08-27/g5-pgo-pacing-controls-rejection.md`.
- Follow-up: a pipelined host Metal harness passed two 600/600 scheduled
  `presentedTime` runs at <=16.667 ms worst with zero drops, proving the M1
  display path can hold 60 Hz. The live Dolphin scheduled-present candidate
  shifted 4.5-6.1 ms into Metal, stalled for 132.188 ms, and changed boundary
  work; fullscreen still failed at 17.493 ms p95. The product edit is removed.
  Do not retry display pacing; return to a fresh current-PGO compute sample.

## 2026-08-27 — Current-PGO line attribution and static gather check rejected

- A disposable `-gline-tables-only` current-PGO module reproduced the retained
  module's 81,959,380-byte `__text` exactly, enabling source-line attribution
  without changing executable instructions.
- The 10-second Fountain sample placed 1,531/1,599 CPU-GPU-thread samples in
  the generated chassis. The large generated function and opcode mix were
  diffuse; 19 samples coherently reached JIT-only exception discovery below
  static gather writes.
- A focused test failed first, then proved that a candidate preserved
  8/16/32-bit write boundaries and the generic arm's per-byte check cadence
  while using Dolphin's `FastWrite*`/`FastCheckGatherPipe` route.
- Exact 440-field candidate/control/candidate windows matched
  1,501,757,755 cycles, 51,380,895 dispatches, and 882 hook fallbacks. The
  candidate repeated a 12-burst reduction and only 0.022-0.107 ms CPU-mean
  gain; p95 regressed from 17.726 ms to 17.883/17.843 ms.
- Decision: **PERF-065 rejected; source and canonical runner restored; G5
  open; Final Destination and G6 blocked.** Next separate ordinary 17-19 ms
  tail frames from rare 129-132 ms stalls and capture the latter at trigger.
- Evidence:
  `docs/artifacts/2026-08-27/g5-static-gather-fast-check-rejection.md`.
- Checkpoint validation: full desktop build passed; both canonical and PGO
  package-layout/signature checks passed; repository/bootstrap checks passed;
  40/40 applicable CTest entries and 16/16 script unit tests passed. The raw
  vendored CTest registry also contains three unbuilt bzip benchmark/fuzzer
  executables and one disabled upstream test; these are explicitly excluded
  from the applicable 40-test result. ASan/UBSan builds of both retained host
  pacing harnesses passed, and the Metal control again delivered 100/100
  intervals at or below 16.7 ms.

## 2026-08-27 — Tail trigger corrected; audio removal rejected

- Three prior 129-132 ms rows were reconciled to the same emulated frame
  `48436`, identical guest work, 13.8-14.0 ms CPU-thread work, and the only
  7.0-8.4 ms Cubeb mix burst in each window.
- The first rolling System Trace attempt auto-ended after six seconds; its
  marker appeared only during later profiler teardown and is excluded. With
  an explicit 120-second trace lifetime and game-before-profiler timeout
  cleanup, 90 armed seconds produced no marker or thermal warning.
- An invalid `Null` backend spelling correctly fell back to Cubeb and was
  relabeled as Cubeb A. The exact backend identifier is `No Audio Output`.
- Fresh Cubeb/no-output/Cubeb brackets matched 1,501,629,399 cycles,
  51,369,928 dispatches, 905,572 bursts, and 882 hook fallbacks. No-output
  worsened p95 to 17.668 ms versus 17.599/17.631 ms, p99 to 19.277 ms versus
  18.158/18.395 ms, and worst to 27.013 ms versus about 20.34 ms.
- Current official Dolphin master has no newer relevant Metal/Cubeb/timer
  scheduling mechanism. An exact-work `SmoothEarlyPresentation=True` run
  measured 17.700 ms p95 / 18.362 ms p99 / 31.300 ms worst, losing p95 and
  worst against both Cubeb controls.
- Decision: **PERF-066 rejects audio removal and hidden presentation-setting
  changes; G5 open; Final Destination and G6 blocked.** Keep Cubeb and return
  to the exact generated-code evidence.
- Evidence:
  `docs/artifacts/2026-08-27/g5-tail-trigger-and-audio-rejection.md`.

## 2026-08-27 — Per-chunk FP-availability cache rejected

- A test-first emitter candidate retained a CIA-specific FP gate at every
  possible generated entry, cached only a successful check inside one native
  invocation, and invalidated the cache after the only continuing MSR write,
  `mtmsr`. Direct-entry and mid-function MSR-disable regressions passed.
- Six focused DolRecomp groups passed without warnings. A disposable signed
  module matched the canonical lockstep screen at 1,401 checked PCs, 91
  reports, seven fallback skips, three zero skips, and zero undercharge.
- The retained Fountain profile recorded 4,234,689,456 FP-availability calls
  versus 803,473,272 entries into all FP-containing chunks, justifying a full
  build with a conservative minimum 81.026% call-removal bound.
- Linked `__text` instead grew from 81,235,476 to 94,598,884 bytes (+16.45%).
  Exact emulated frames `48123..48507` matched 1,330,434,029 cycles,
  45,572,090 dispatches, 801,319 bursts, and 772 hook fallbacks in all three
  runs. Candidate/control/candidate CPU-thread means were
  23.750/16.114/23.650 ms; p95 was 26.925/18.113/26.622 ms.
- Decision: **PERF-067 rejected; G5 open; Final Destination and G6 blocked.**
  All candidate source and candidate-specific tests are removed. Do not retry
  per-chunk flags or a branch at every FP instruction; a next FP experiment
  must reduce shared call-site cost without multiplying generated control flow.
- Checkpoint validation passed the repository and dependency-bootstrap checks,
  incremental native desktop build, both package-layout/signature checks, all
  40 applicable CTest entries, all 16 `gcpipe` Python tests, and the explicit
  instrumented-versus-release profile-hook test. Candidate marker searches are
  empty; the canonical app/module remain unchanged.
- Evidence:
  `docs/artifacts/2026-08-27/g5-fp-availability-cache-rejection.md`.

## 2026-08-27 — CFG-local FP-gate elision rejected

- A regression-first candidate retained exact-CIA gates at every possible
  direct entry, restarted checks at CFG leaders and after `mtmsr`, and moved
  94,146/129,826 gates (72.517%) out of sequential bodies.
- Six focused DolRecomp groups passed. An instrumented arm64 module preserved
  the known lockstep report set with zero undercharge; its candidate-specific
  Fountain profile had the exact expected 6,556 functions and 2,727,666
  blocks and compiled without profile warnings.
- PGO `__text` grew 1.506%. Exact 440-frame candidate/control/candidate runs
  matched 1,501,629,399 cycles, 51,369,928 dispatches, 905,572 bursts, zero
  fallbacks, and 882 hook fallbacks.
- Candidate CPU-thread mean improved by 0.236-0.490 ms, but total p95 worsened
  from 17.677 ms to 17.775/17.980 ms and the <=16.7 ms share remained 52.5%.
- Decision: **PERF-068 rejected; G5 open; Final Destination and G6 blocked.**
  Candidate source/tests are removed; focused reversal tests, dependency
  bootstrap, repository safety, the incremental desktop-tools build, 40/40
  applicable CTest entries, 16/16 `gcpipe` tests, both package/signature
  checks, and profile-hook separation pass. Next identify the specific live
  Dolphin serialization edge absent from the passing three-drawable host
  Metal queue before any new rendering/pacing edit.
- Evidence:
  `docs/artifacts/2026-08-27/g5-fp-cfg-gate-rejection.md`.

## 2026-08-27 — Actual Metal presentation and acquisition attribution

- A default-off `MTLDrawable.presentedTime` logger proved the CPU-side phase
  logger is not the acceptance signal. Two ordinary no-phase controls put only
  53.3-53.6% of actual intervals at <=16.7 ms.
- Changing only `CAMetalLayer.displaySyncEnabled` produced two 780/780 short
  brackets at <=16.7 ms and an exact 440/440 bracket with 16.666667 ms worst.
  Exact guest work remained 1,501,629,399 cycles, 51,369,928 dispatches,
  905,572 bursts, zero fallbacks, and 882 hooks. The M1 is not the throughput
  ceiling.
- A natural full-match repeat measured 16.666667/16.666709/99.999791 ms
  p95/p99/worst and 99.925% compliance. Pre/post-`nextDrawable` timestamps put
  both long stalls 103-131 ms before Metal; acquisition took only 0.05 ms.
- Combined-thread user-interactive QoS, `CPUThread=True`, Computer Use
  foreground raising, and a 106-second unbound-MemoryWatcher window all
  retained missed refreshes. All behavior candidates except the not-yet-
  promoted display-sync edge are rejected.
- Rolling System Trace attempts were bounded to five seconds due low disk. A
  valid trace captured only profiler startup; a genuine 33.333 ms trigger
  aborted during Instruments save and is excluded. Exactly three raw ktrace
  files created by these attempts, three failed trace bundles, three
  superseded diagnostic apps, and two isolated temp user copies were removed.
  ROM, canonical apps, source inputs, saves, and repo evidence were untouched.
- Decision: **PERF-069 materially advances actual presentation but G5 remains
  open; Final Destination and G6 stay blocked.** Strip the diagnostics and
  test only layer display sync on the reproducible canonical app next.
- Evidence:
  `docs/artifacts/2026-08-27/g5-metal-presentation-attribution.md` and
  `docs/evidence/g5-metal-presentation-attribution/`.

## 2026-08-27 — Canonical macOS layer display sync retained

- Removed the actual-time/acquisition logger and diagnostic environment
  override from product source. Patches 0009/0017 add one opt-in macOS-only
  ModernGekko policy; SsbmPad's package enables it and the package regression
  requires the compiled policy identity.
- The package regression failed against the old runner, then the reproducible
  build passed bootstrap, layout, arm64, and strict ad-hoc signing. Runner and
  canonical non-PGO module SHA-256 values are `93ebc462...6563cd5` and
  `44366f2e...505b90`.
- The signed product smoke loaded exact Fountain state and logged the product
  policy with Metal, Cubeb, and the existing controller profile, without any
  diagnostic display-sync environment variable.
- Canonical actual-presentation A/B/reverse-A closed at 778/779/780 intervals.
  No-sync controls measured 18.147/18.561 ms p95 with 55.141%/57.564% at
  <=16.7 ms. The synchronized candidate measured 16.666667 ms p95,
  16.666750 ms worst, and 779/779 compliance.
- A full canonical match naturally reached results after 113.369 seconds.
  p95/p99 were 16.666625/16.666667 ms and 99.850% complied, but ten misses
  left 66.666334 ms worst.
- Decision: **retain the canonical layer-display-sync product improvement;
  G5 remains open; Final Destination and G6 stay blocked.** Next join actual
  missed refreshes to canonical emulated-frame/CPU-thread phase rows.
- Checkpoint validation passes dependency bootstrap and patch reversal,
  40/40 applicable CTest entries, 16/16 `gcpipe` tests, profile-hook
  separation, repository safety, package layout, arm64 identity, strict
  signing, shell syntax, and diff whitespace.

## 2026-08-27 — Canonical phase join and real-time candidate rejected

- Joined the canonical actual-presentation CSV to phase rows by stable frame
  identifiers. With the established two-second warm-up, 6,670 intervals align
  best to `frame - 1` at 0.674781 correlation.
- The 113 misses average 19.623 ms CPU-thread work versus 16.080 ms for
  compliant rows and execute about 5% more guest cycles/dispatches. The
  133.333 ms worst is different: 131.944 ms CPU wall but 31.829 ms CPU thread,
  exposing about 100 ms off-core.
- A default-off Mach `THREAD_TIME_CONSTRAINT_POLICY` screen was limited to the
  faster PGO oracle. The API returned success, but a 773-interval short bracket
  introduced a 116.665 ms stall and fell from the prior 100% control to
  99.871% compliance. The candidate is rejected; no full match was run.
- Removed the scheduling candidate and temporary presentation logger, rebuilt
  the arm64 desktop runner, and verified the product display-sync marker is
  present while both diagnostic markers are absent.
- Retained the raw timing/log evidence, then removed two disposable diagnostic
  apps and eight isolated temporary user trees, recovering about 1.4 GB. ROM,
  canonical apps, source inputs, saves, and repository evidence were untouched.
- Decision: **PERF-070 attribution retained; scheduling candidate rejected;
  G5 open; Final Destination and G6 blocked.** Next select a reproducible,
  PGO-informed compute path; do not retry scheduler or priority variants.
- Evidence:
  `docs/artifacts/2026-08-27/g5-phase-join-and-time-constraint-rejection.md`
  and `docs/evidence/g5-phase-join-time-constraint-rejection/`.

## 2026-08-27 — Local PGO package workflow retained

- Extended `prepare-game.sh` with an optional validated private-profile input
  while preserving its canonical one-argument behavior.
- Added `package-local-pgo-app.sh`: it preserves the canonical active-module
  pointer, builds/selects the profile-hashed module, rejects a manifest path
  leak or hash mismatch, packages and signs the local app, then restores the
  pointer on all exits.
- A genuine 247-step current-source profile-use build completed without profile
  mismatch warnings and reproduced the retained signed PGO module SHA-256
  `bd089303...af26f5a`. The manifest contains only profile SHA-256
  `3f9d2aa4...f572ac12`.
- A repeat logged `cache hit` and completed in 24 seconds. A deliberate
  packaging failure after that cache hit returned status 1 and still restored
  the canonical pointer.
- Both disposable proof apps were removed. The ignored reusable module cache
  remains; tracked files contain no ROM, profile, generated module, app, or
  private path.
- Checkpoint validation passes dependency bootstrap/reversal, repository
  safety, shell syntax, diff whitespace, 40/40 applicable CTest entries,
  16/16 `gcpipe` tests, profile-hook separation, both package-layout checks,
  arm64 identity, and strict deep ad-hoc signing.
- Decision: **PERF-071 local package bridge retained; local training recipe and
  G5 remain open; Final Destination and G6 blocked.**
- Evidence: `docs/artifacts/2026-08-27/g5-local-pgo-package-workflow.md`.

## 2026-08-28 — Local PGO training workflow retained

- Added a distinct C/Clang `--pgo-generate` mode plus local training-app,
  training-run, and profile-merge scripts. The canonical active-module pointer
  is restored on success and failure; all private/game-bearing inputs and
  products remain outside Git.
- A real instrumented Fountain match reset and dumped counters only under the
  revision-0 combat predicate. The merged profile has 6,556 functions,
  2,727,666 blocks, and 135,462,879,791 counts, only 873 counts below the prior
  oracle but not byte-identical.
- A fresh 247-step profile-use build passed package layout, arm64, macOS-14,
  and strict-signature checks. Its `__text` size matches the prior PGO oracle,
  while 127,816 bytes differ inside `func_80345940`; the local binary is not
  promoted over the canonical oracle.
- Validation caught the reusable PGO oracle app's older runner. PERF-071
  repackaged it from the cached known profile: its current product runner is
  `93ebc462...6563cd5`, its known module remains `bd089303...af26f5a`, layout
  and strict signing pass, and the canonical module pointer was restored.
- A cooled foreground clean smoke loaded the retained state only after frame
  1,000 and rendered coherent Pikachu/CPU-Fox Fountain. Its exact 440-frame
  window matched 1,501,757,755 cycles and 51,380,895 dispatches at 16.664 ms
  mean / 60.011 FPS and 11.621 ms CPU-thread mean, but failed G5 at 18.065 ms
  p95 and 22.509 ms worst. It exited normally with zero runtime fallbacks; no
  Simulator was booted.
- The supplied incident `7B988C01-591F-412F-89BB-A16A913E5680` is from the
  older disposable FPCFG app during emulation startup, not this workflow. The
  report does not supersede the retained frame-gated load rule.
- Decision: **PERF-072 workflow retained; G5 open; Final Destination and G6
  blocked.** Next screen IR-level PGO on the exact deterministic workload;
  CS-PGO+LTO and BOLT are excluded by host/platform preflight.
- Checkpoint validation passes bootstrap/reversal, the desktop-tools rebuild,
  CLI/script rejection cases, repository/shell/diff checks, 40/40 applicable
  CTest entries, 16/16 `gcpipe`, profile-hook separation, package layout,
  arm64 identity, strict signing, and pointer restoration. Disposable proof
  apps/users/compiler preflights and completed-cache intermediates were
  removed; final modules/manifests/profile and evidence remain.
- Evidence:
  `docs/artifacts/2026-08-28/g5-local-pgo-training-workflow.md` and
  `docs/evidence/g5-local-pgo-training-workflow/`.

## 2026-08-28 — IR-level PGO rejected on exact Fountain work

- Temporarily screened LLVM IR-level instrumentation with
  `-fprofile-generate` under a distinct local cache identity. The fresh signed
  training module contains the IR profile sections and completed one
  predicate-gated Pikachu/CPU-Fox Fountain match with a normal exit.
- The merged private profile is explicitly `Instrumentation level: IR`, with
  866 post-optimization functions, 3,947,902 blocks, and 52,990,495,633
  counts. A fresh 247-step profile-use build completed with no profile mismatch
  warnings; package layout, arm64 identity, and strict signing pass.
- The IR-PGO module grew `__text` from 81,959,380 to 84,388,556 bytes. Its
  exact emulated frames `48123..48562` matched the frontend-PGO control at
  1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, and 882 hook
  fallbacks.
- Runtime performance regressed: 16.737756 ms mean / 59.745 FPS,
  18.047575 ms p95, 18.978414 ms p99, 69.163166 ms worst, and 12.084786 ms
  CPU-thread mean. The worst occurred at steady emulated frame 48,394, not the
  state-load boundary. Only 55.682% of frames met 16.7 ms.
- Direct UI inspection and a retained visual-only recapture show coherent
  Fountain gameplay at a 60.0-FPS title with no character morphing in the
  captured frame. Both runtime processes exited normally with zero fallback
  steps; no Simulator was booted.
- Restored the two temporary compiler/cache-identity substitutions, rebuilt
  `moderngekko-port`, passed dependency bootstrap and patch reverse-check, and
  verified the canonical active pointer remains profile-free. The unrelated
  untracked netplay document was not touched.
- Repository safety, package layout, 40/40 applicable CTest entries, and 16/16
  `gcpipe` pass. The frontend-specific profile-hook script reaches successful
  IR reset/dump but returns 1 because its final parser expects frontend-only
  `Function count:` records; the live raw profile and merge prove the IR hooks
  without changing the retained product test.
- Decision: **PERF-073 rejects whole-module IR PGO; G5 remains open; Final
  Destination and G6 remain blocked.** Next use the retained profiles to choose
  one bounded hot-region or dispatch-edge transformation rather than another
  whole-module compiler mode.
- Evidence: `docs/artifacts/2026-08-28/g5-ir-pgo-rejection.md` and
  `docs/evidence/g5-ir-pgo-rejection/`.

## 2026-08-28 — Profile-derived Mach-O order file rejected

- Temporarily linked the locally trained frontend-PGO module with a tight
  order file containing `chassis_dispatch`, common runtime helpers, and four
  hottest generated regions under an experiment-only cache identity.
- `nm` proves Apple `ld` honored the full requested order. The signed arm64
  candidate retains the 81,959,380-byte text size; package layout and strict
  signing pass.
- One foreground Metal/Cubeb run, isolated user directory, no Simulator, and
  frame-gated state load produced coherent Pikachu/CPU-Fox Fountain combat and
  exited normally. The exact 440-frame interval matched PERF-072 at
  1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, 882 hook
  fallbacks, and zero fallback steps.
- Ordered CPU-thread mean improved only 0.083 ms / 0.714%. Total mean regressed
  to 16.852325 ms, compliance remained 55.682%, and worst rose to
  133.106958 ms. The candidate is rejected.
- Restored the linker/cache-identity inputs and canonical profile-free module
  pointer. No product source remains changed; the unrelated untracked netplay
  document was not touched.
- Decision: **PERF-074 rejects global code placement; G5 remains open; Final
  Destination and G6 remain blocked.** Next measure and eliminate one specific
  frequent dispatcher edge with a focused semantic regression first.
- Evidence: `docs/artifacts/2026-08-28/g5-order-file-rejection.md` and
  `docs/evidence/g5-order-file-rejection/`.

## 2026-08-28 — Ten hot cross-chunk direct calls rejected

- A default-off sampled predecessor/destination runner collected 12,539 edge
  samples at 1/4,096 over exact emulated frames `48123..48562`, accurately
  reconstructing the 51.38-million-dispatch workload and one hot linked-call
  sequence in generated `func_80369940`.
- A focused generated caller/callee regression failed before direct
  continuation, then passed normal return and exact 256-cycle-budget exit with
  the ten-edge candidate. `dispatch`, `c_cfg`, `codegen_compile`, and
  `c_execute` passed 4/4.
- A fresh isolated frontend-PGO package passed layout, arm64, and strict
  signing. Disassembly proves ThinLTO lowered the constant target lookups to
  direct `_func_...` calls rather than retaining `chassis_dispatch`.
- One foreground Metal/Cubeb run, no Simulator, and frame-gated state load
  produced 440 rows for emulated frames `48123..48562`. Dispatches fell from
  51,380,895 to 46,668,247 (9.17%), while CPU-thread mean improved only from
  11.620875 to 11.485026 ms (1.17%). Total mean was 16.666753 ms, p95
  18.052291 ms, p99 18.633750 ms, worst 22.057000 ms, and 55.000% compliance.
  Hook fallbacks stayed 882 and fallback steps stayed zero; the 741-cycle
  boundary difference is 0.000049% and is not claimed as exact equivalence.
- Live UI inspection and a retained recapture showed coherent Pikachu/CPU-Fox
  Fountain combat at 60.0 FPS with intact character models and stage geometry.
  Both processes exited normally.
- The safety audit found the decisive flaw: nested generated calls bypass the
  outer `FastDispatchableAt` check that enforces forced-fallback ranges and
  post-invalidation target-chunk verification. The unchanged scene had no
  failed SMC chunks, but that is not product proof.
- Removed only the experimental generator, test, and bootstrap edits, rebuilt
  canonical tools, and passed the four focused tests. Repository safety,
  bootstrap, 40/40 applicable CTest entries, 16/16 `gcpipe`, canonical package
  layout, arm64 identity, and strict signing also pass. No game or Simulator
  remains active. The unrelated untracked netplay document remains untouched.
- Decision: **PERF-075 rejects the address-specific direct-call candidate; G5
  remains open; Final Destination and G6 remain blocked.** Next build a cheap
  target-validity guard, require an invalidated-callee failure before the fix,
  and then screen broader statically known calls under the same cycle and
  exception rules.
- Evidence: `docs/artifacts/2026-08-28/g5-hot-direct-call-rejection.md` and
  `docs/evidence/g5-hot-direct-call-rejection/`.

## 2026-08-28 — Guarded broad direct-call callback rejected

- Added a disposable target-validity callback plus a post-callee continuation
  recheck. Focused generated tests cover denied/accepted targets, exact
  256-cycle exit, continuation invalidation, and terminal return; 4/4 pass.
- The full GALE01r0 module emitted 67,012 guarded sites across 237 chunks.
  Arm64 disassembly proves real direct `_func_...` calls, and the former
  `0x8008593C` boundary returns instead of jumping outside its generated
  function.
- The first launch was safely rejected with `CPU state size mismatch`: the
  experiment extended GXRuntime but not ModernGekko's public CPU-state mirror.
  Mirroring the disposable tail field and rebuilding the runner preserved the
  load-time guard and produced a valid isolated package.
- The old-PGO positive screen cut dispatches to 15,897,417 but worsened
  CPU-thread mean to 11.899125 ms; widespread profile mismatch required a
  profile-free pair before deciding.
- A clean no-profile candidate reproduced 1,501,629,909 cycles, 15,897,417
  dispatches, 892,043 bursts, 882 hooks, and zero fallbacks. The closest
  canonical control differs by 510 cycles and has 51,369,928 dispatches.
  Candidate CPU-thread mean improves only 1.66% from 15.699995 to 15.439466 ms,
  CPU p95 only 0.64%, while compliance falls to 60.000%, p95 remains 18.677083
  ms, worst reaches 128.024166 ms, and text grows 12.79%.
- Live Computer Use inspection retained coherent Pikachu/CPU-Fox Fountain
  combat at a 60.0-FPS title with intact characters, HUD, and stage geometry.
  Both measured apps exited normally with zero failed SMC chunks.
- Removed every candidate generator, test, public/GXRuntime ABI, runtime
  callback, and bootstrap edit; restored the canonical profile-free pointer.
  Retained the independent `prepare-game.sh` fix that explicitly refreshes the
  top-level `dolrecomp` executable and prevents stale-generator module builds.
- Decision: **PERF-076 rejects per-edge callback validity; G5 remains open;
  Final Destination and G6 remain blocked.** Next preflight an inline data-only
  validity representation and require a projected >5% gain; otherwise move to
  profile-derived superblocks with boundary-only guards.
- Evidence: `docs/artifacts/2026-08-28/g5-guarded-direct-call-rejection.md` and
  `docs/evidence/g5-guarded-direct-call-rejection/`.
- Restored-product validation then passed 40/40 applicable CTest entries,
  repository checks, package layout, arm64 identity, strict signing, shell
  syntax, `git diff --check`, and 16/16 `gcpipe` tests. No game or Simulator
  remained active.
- Researched the remaining static-recompiler options from QEMU, LLVM, and Apple
  primary sources. Rank an inline runtime-owned eligibility table first; if its
  focused preflight cannot project more than 5%, skip the broad module and use
  one profile-derived superblock with boundary guards. BOLT is ELF-only, and
  the renderer/display tail remains a separate measured problem. See
  `docs/artifacts/2026-08-28/g5-static-recomp-optimization-research.md`.

## 2026-08-28 — Broad inline validity rejected in host preflight

- Preserved PERF-076 binaries supplied the exact arm64 callback and
  `FastDispatchableAt` disassembly. Added a data-free host benchmark modeling
  its target guard, direct callee, continuation-PC check, second guard,
  host-call query, cold REL branch, address lookup, and verified-state load.
- The model self-check rejects invalidated, disabled, and forced-fallback
  targets. AppleClang `-O3 -Wall -Wextra -Werror` builds it cleanly, and
  disassembly matches the old accepted callback control shape.
- Two rotated 15-repetition runs, each using 32 million edges per
  representation per repetition, measured callback-to-inline savings of
  5.874625 and 5.966854 ns/edge. PERF-076 bounds direct edges at
  40,309.672–80,619.343/frame, so the added projection is only
  0.236804–0.481044 ms/frame.
- Even the most optimistic projection plus PERF-076's measured 0.260529 ms
  gain reaches only 0.741573 ms / 4.72%, below the 0.785000 ms / 5% threshold.
  No product ABI, runtime, generated source, module, app, game, or Simulator
  changed.
- Decision: **PERF-077 rejects broad per-edge inline validity before a game
  build; G5 remains open.** Next statically screen the dominant
  `8036C8D8..8036C91C` sample chain and build one boundary-guarded superblock
  regression only if it excludes cache-control, host-call, exception,
  indirect-control, and cycle-budget hazards.
- Evidence:
  `docs/artifacts/2026-08-28/g5-inline-validity-preflight-rejection.md` and
  `scripts/g5_direct_guard_preflight.cpp`.

## 2026-08-28 — Dispatch-only trace coverage rejected

- Added a deterministic exact-frame analyzer for dominant non-self dispatch
  chains. It stops at successor ambiguity rather than rounding the
  `8033FB64 -> 8036C8E4` 79.53% connector into the 80% set.
- Conservatively scanned the selected generated ranges: 394 guest instructions
  across chunks `8033D940`, `80369940`, and `80375940` contain no cache-control
  or indirect-system hazard. Exact successor, exception, and cycle checks are
  still required.
- Added a data-free trace semantics regression. Its first run caught an
  unsigned-enum `-256` harness bug; an explicit `INT64_C(256)` then passed all
  six invalidated-entry, fallback, completion, divergence, exception, and
  exact-budget paths with AppleClang warnings-as-errors.
- The seven-node trace represents 647 samples / about 2.65M dispatches / 5.16%
  of the exact window, projecting only 0.076 ms/frame from PERF-075's measured
  12.684 ns/dispatch slope.
- All 278 edges passing 80% dominance and five samples reach only a theoretical
  0.843 ms / 5.37% before any guard, miss, footprint, or sample-selection cost;
  204 edges are required just to cross 5% in that zero-overhead model.
- Decision: **PERF-078 rejects dispatcher-only trace chaining; G5 remains
  open.** Retain the analysis and semantics tools. Next preflight one truly
  merged generated region and require material CPUState spill elimination
  beyond dispatch savings before changing the product.
- Evidence:
  `docs/artifacts/2026-08-28/g5-dispatch-trace-coverage-rejection.md`,
  `scripts/analyze-dispatch-edge-traces.py`, and
  `scripts/g5_trace_semantics_preflight.c`.

## 2026-08-28 — Small merged-state region rejected

- Compiled the actual current hot generated chunk separately and confirmed the
  switch/label shape materializes PC, cycle state, and guest GPR values around
  `0x8036C91C`; values are stored and immediately reloaded because every label
  must remain an arbitrary entry.
- Added a data-free canonical-versus-single-entry model for the exact
  `0x8036C91C..0x8036C934` slice. It passes 4,096 randomized comparisons of all
  CPU-state bytes except the intentionally different RAM pointer plus all 4 KiB
  of RAM.
- Arm64 drops from 159 to 128 instructions, 32 to 27 loads, and 36 to 23
  branches. Repeated five-million-iteration runs improve 21.37-21.79%, saving
  1.231-1.264 ns per region; a fresh repeat saved 1.216 ns / 21.29%.
- Absolute coverage rejects the candidate: the sampled site projects about
  819 executions/frame and only 0.001036 ms/frame. Even granting the saving to
  every one of 116,775 dispatches/frame yields less than 0.148 ms/frame.
- Decision: **PERF-079 rejects the small merged region before a game build; G5
  remains open.** Retain the semantic/timing harness. Next select by inclusive
  host cost mapped to guest PCs, then preflight one larger expensive region.
- Evidence:
  `docs/artifacts/2026-08-28/g5-merged-state-preflight-rejection.md` and
  `scripts/g5_merged_state_preflight.c`.

## 2026-08-28 — Guest-cost selection and complete-function preflight

- Added a deterministic macOS `sample` to generated guest-PC mapper. It maps
  1,127 direct samples and independently rediscovers the two already-closed
  matrix-FIFO and PSMTXConcat hotspots.
- The largest unclosed region is only 52/1,531 chassis samples / 3.40%; no new
  single region can clear 5% even if deleted.
- Mechanically narrowed the complete `0x803248DC` guest function. Entry
  narrowing alone was neutral despite reducing its isolated object from
  323,112 to 8,452 text bytes.
- Explicitly caching six live GPRs and eight FPR/PS1 pairs plus retaining the
  exact first FP gate reduced the object to 8,088 text bytes and repeated a
  9.70-10.92% local gain. All 4,096 state/stack cases pass, including 512
  FP-disabled entries and every initial 0..-255 cycle budget.
- Decision: **PERF-080/081 reject one-function specialization; G5 remains
  open.** The measured projection is only 0.33-0.37% overall. Test the existing
  SSA-based LLVM backend on Apple ARM64 instead of building address lists.

## 2026-08-28 — LLVM 22 Apple ARM64 backend feasibility retained

- A disposable DolRecomp copy relaxed only its LLVM version/target gates,
  migrated six LLVM 22 API calls, and made object-format tests accept Mach-O.
- LLVM 22.1.8 emitted genuine Mach-O arm64 objects and linked a native arm64
  semantic test executable.
- `llvm_backend`, `llvm_execute`, and `llvm_pipeline` pass 3/3. The execution
  test covers state, RAM, float/paired work, exceptions, fallbacks, cache
  control, and other runtime boundaries.
- Decision: **PERF-082 retains Apple ARM64 LLVM as the next bounded candidate;
  G5 remains open.** Full private GALE01 generation is running. No canonical
  patch, module, app, game process, or Simulator changed.
- Evidence: `docs/artifacts/2026-08-28/g5-llvm22-arm64-preflight.md`.

## 2026-08-28 — LLVM hot-slice footprint boundary measured

- Early full-game objects projected an approximately 678 MB text image, so a
  private mini-DOL isolated the exact 1,024-instruction
  `0x80323940..0x8032493F` slice around the leading unclosed Fountain region.
- LLVM emitted 396,548 text bytes / 99,136 host instructions; strict product-
  flag C emitted 64,756 / 16,183. LLVM also contains 41,455 loads and 37,786
  stores versus C's 3,693 and 1,586.
- Source inspection attributes the expansion to broad dirty-state
  materialize/reload sequences duplicated at arbitrary exits and rare
  memory/MMIO boundaries.
- A shared side-exit passed the focused semantics but grew the slice to
  411,760 bytes / 102,939 instructions due PHI/move pressure. LLVM's stock O2
  and size-oriented Oz pipelines both grew it to 421,876 / 105,468. All
  disposable variants are removed.
- Decision: **PERF-082 remains a performance-feasibility baseline, not a
  product candidate; G5 remains open.** Resume the original full compile. Even
  a positive live result must be followed by targeted cold-boundary
  compaction before promotion.

## 2026-08-28 — LLVM exact hot-slice runtime rejected

- Renamed only the LLVM object export and linked both exact-slice objects into
  one arm64 harness. C and LLVM both end at `0x80324940`, match every relevant
  CPU-state/RAM byte, and change the same nine RAM bytes.
- A concurrent screen measured 173.554 ns for C versus 844.008 ns for LLVM.
  Two uncontended 100,000-iteration repeats measured 100.103/97.536 ns for C
  versus 487.871/480.811 ns for LLVM. The retained harness repeated 95.992
  versus 464.884 ns: an overall repeatable 4.84-4.93x regression.
- Decision: **PERF-082 rejected before module link; G5 remains open.** Stop the
  full private compile at 130/947 objects and retain its partial output. No
  product source, module pointer, package, game process, or Simulator changed.

## 2026-08-28 — Canonical refresh and structural static-recomp research

- Launched exactly one current signed canonical arm64 product, loaded the
  retained Fountain state, captured a coherent Pikachu/Fox frame, sampled the
  CPU thread, and shut the runner down cleanly. No Simulator was booted.
- The exact 440-emulated-frame interval executed 1,501,629,399 guest cycles and
  51,369,928 native dispatches. It measured 16.814891 ms total mean,
  18.761260 ms p95, 21.389482 ms p99, and 29.560250 ms worst; only 56.3636%
  met 16.7 ms. CPU-thread mean/p95 were 15.735743/17.683831 ms.
- The visible frame read 60.0 FPS and retained coherent character/stage
  geometry. The known reference-parity Fountain floor-reflection distortion
  remains; the strict retained phase trace still fails G5.
- QEMU's CPU-state optimization, extended-basic-block, helper-effect, and
  direct-chaining designs plus Dolphin's ARM64 register cache were compared
  with PERF-079/081/082. The next applicable method is a profile-guided C
  translation region that keeps live guest state in locals and synchronizes
  only at exact exits.
- Decision: **PERF-083 retains research and the fresh baseline; G5 remains
  open.** First build a data-free region-state semantic/timing preflight. No
  game build follows unless defensible coverage times measured gain projects
  above 5% CPU-thread improvement.
- Evidence:
  `docs/artifacts/2026-08-28/g5-static-recomp-structural-followup.md`.

## 2026-08-28 — Function-family coverage rejects leaf-only state caching

- Extended the guest-cost mapper to resolve exact sampled PCs through the
  GALE01 function map and classify every generated `bl`/`blrl` in each span.
  Replaced an initial quadratic scan with sorted PCs and prefix call counts;
  the complete 756-span run now finishes in about five seconds.
- The symbol names are grouping aids only. Exact generated control flow proves
  at least one coarse boundary (`HSD_PadRenewGameStatus` map start
  `0x80377B54` versus generated prologue `0x80377B6C`), so no optimization is
  selected from a name alone.
- The 7,458-sample promoted profile-free line run puts all no-call work at
  23.531751%; removing the two already-closed matrix/GX spans leaves
  14.293349%, requiring a 34.981% local gain to project 5%.
- The independent 1,127-sample current-PGO line run puts all no-call work at
  32.830515%; the same exclusion leaves 17.302565%, requiring 28.897% local.
- Decision: **PERF-084 rejects leaf-only state caching; G5 remains open.** The
  real PERF-081 complete-function gain is only 9.70-10.92%. Next build a data-
  free guarded parent/callee preflight for `0x80377B6C..0x80377CE4` and its
  `0x803408A0` call boundary. No generator, module, app, process, or Simulator
  changed.
- Evidence: `docs/artifacts/2026-08-28/g5-function-family-coverage.md` and
  `scripts/analyze-macos-sample-guest-cost.py`.

## 2026-08-28 — Exact matrix-copy family preflight rejected by coverage

- Exact generated source identifies parent calls `0x80377C04/0x80377C18` as
  mutually exclusive calls to paired-single matrix copy
  `0x803408A0..0x803408D0`, not the adjacent concat body.
- Added a data-free fast-path harness with canonical fallback for FP, LSQE,
  GQR, journal, external, and address gates. Identical, overlapping, and
  disjoint copies, matching/nonmatching reservations, and out-of-range fallback
  pass 20,000 full CPU-state and 24-MiB-RAM comparisons.
- Nine alternating million-call repeats improve 77.795167 to 23.738208
  ns/call: 54.056958 ns saved / 69.486268% local.
- Exact line-profile coverage is 5/8,452 (0.059158%) and 0/1,311 for copy. The
  adjacent concat body is 307/8,452 (3.632276%) and 67/1,311 (5.110603%). Even
  at zero wrapper cost their measured gains project only about 2.55%/3.53%.
- Decision: **PERF-085 rejects the two-address matrix chunk wrapper; G5
  remains open.** Retain the semantic/timing harness, but do not modify
  generated dispatch or build a module. Next require a representation that
  aggregates several high-cost callful families.
- Evidence: `docs/artifacts/2026-08-28/g5-matrix-copy-family-preflight.md` and
  `scripts/g5_psmtxcopy_preflight.c`.

## 2026-08-28 — AppleClang generated-C flag matrix rejected

- Recompiled PERF-082's exact private 1,024-instruction hot slice with strict
  O2/O3/Os/Oz, vectorizer, unroll, Apple-M1, and native variants. Every paired
  implementation ends at `0x80324940` and matches all relevant CPU-state/RAM
  bytes.
- O3/Os and disabled vectorization/unrolling remain within noise. Fresh-process
  Apple-M1/native medians improve only 1.287%/1.059%, while the identical O2
  control itself moves 1.483%. Oz cuts text 37.8% but runs 26.040% slower.
- Research against QEMU TCG and Dolphin's JIT confirms that the material route
  is larger-region register retention, stable-state specialization, and dirty
  synchronization at observable exits—not another compiler flag.
- Decision: **PERF-086 rejected before module link; G5 remains open.** Next
  select a profile-qualified callful region and build a full-state/RAM local-
  state differential preflight. No generator, module, app, process, or
  Simulator changed.
- Evidence:
  `docs/artifacts/2026-08-28/g5-c-flag-matrix-rejection.md` and
  `docs/evidence/g5-c-flag-matrix-preflight/results.csv`.

## 2026-08-28 — Profile-weighted internal layout retained

- Exact line lookup across profile-free and current frontend-PGO modules puts
  the same `0x80377B6C..0x80377CE4` source interval across 148,788 versus
  11,780 host bytes, proving that PGO reorganizes hot basic blocks inside a
  giant generated function rather than merely ordering whole symbols.
- Added a data-free generated-entry transformer and screened computed-label and
  biased-hot forms against PERF-086's exact differential harness. Both preserve
  full relevant CPU state/RAM and the same nine writes.
- Computed entry improves five fresh million-entry runs by 0.757-3.100%
  (1.785% median); biased hot entry improves 2.283-3.694% (2.904% median).
  Both are below the 5% gate and cannot explain the approximately 26% PGO CPU
  gain. Invalid `nan` rows from a malformed harness argument are excluded.
- The retained profile exposes 11,548 counters for `func_80375940`, but its
  matching instrumented binary has no LLVM coverage map. The next disposable
  training build must add coverage mapping so `llvm-cov` can associate counts
  with exact source branches; do not guess counter indices.
- Decision: **PERF-087 rejects entry-only layout but retains internal edge
  weights as the next bounded static-recompilation route; G5 remains open.**
  Next export one current-profile chunk's edge probabilities into profile-free
  generated source and require semantic, layout, size, and >5% timing gates.
  Metal shader compilation remains a separate tail candidate; no product app,
  module, game process, or Simulator changed.
- Evidence:
  `docs/artifacts/2026-08-28/g5-profile-weighted-block-layout.md` and
  `scripts/transform-generated-entry-switch.py`.

## 2026-08-28 — Exact profile edges and EFB tail attribution

- Added coverage mapping to the private PGO-generation identity. A clean
  instrumented module exposed both LLVM coverage sections, passed profile-hook
  and package checks, and decoded the retained Fountain profile without a hash
  mismatch.
- Exact `0x80377B6C..0x80377D58` coverage contains 119 branch records. The
  fail-closed source transformer weighted 113 executed records and skipped six
  never-executed records; its four tests pass.
- All 992 arbitrary-entry/full-RAM cases pass for canonical, weighted, and PGO
  objects. Weights compact the selected interval 7.69x but produce contradictory
  `cold hot minsize` IR and regress 59-63%. Hot and biased-entry forms do not
  repair it.
- A 12,872-byte single-entry GPR-cached trace passes 4,096 full-state/RAM cases,
  including 512 FP-disabled cases, but the one-million-entry ThinLTO/hot run is
  443.064 versus 454.107 ns, 2.492% slower.
- Retained default-dormant frame counters time synchronous VRAM/RAM EFB shader
  and pipeline misses. The native runner, focused counter test, strict package,
  bootstrap, and repository checks pass.
- Exact Fountain frames `48123..48562` execute 1,501,757,755 cycles and
  51,380,895 dispatches. One 18.048 ms frame contains a 1.198 ms VRAM pipeline
  miss, but subtracting it changes neither 18.651 ms p95 nor 184/440 frames over
  16.7 ms. The 73.470 ms worst has no miss and about 48.6 ms off-core wall time.
- Decision: **PERF-088 rejects source weights, the selected trace, and EFB
  prewarming as the G5 tail solution; counters/tooling retained; G5 open; G6
  and Final Destination blocked.** Next run the same exact counter window on
  the retained frontend-PGO oracle. No game process or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md`.

## 2026-08-28 — Frontend-PGO on-core budget pass and wall-tail attribution

- Repeated PERF-088's exact Fountain frames `48123..48562` with its EFB
  counters and the retained frontend-PGO module. All 440 rows match
  1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, and 882 hook
  fallbacks.
- Total p95/p99/worst remain 18.256/19.823/25.517 ms, so G5 remains open.
  CPU-thread p95/worst are only 12.984/16.284 ms and every CPU-thread row is at
  or below 16.7 ms. The statically recompiled on-core path meets the exact
  Fountain budget.
- CPU wall minus CPU-thread time measures 4.609 ms mean, 6.180 ms p95, and
  12.630 ms worst. The worst row has no EFB miss and only 12.476 ms CPU-thread
  work. Video-build time overlaps the center of this gap but correlates only
  0.358 with it and does not explain the strict tail.
- The requested-throttle counter is zero on every selected row. Measured
  throttle sleep is 0.000511 ms mean / 0.004751 ms worst and has -0.056
  correlation with the gap, excluding the already-rejected timer path.
- One 1.445 ms EFB compile occurs at emulated frame 48436; subtracting it
  changes neither p95 nor any of the 215 frames above 16.7 ms.
- Decision: **PERF-089 retains frontend PGO and proves its CPU-thread compute
  budget on this exact window; total-frame G5 remains open; G6 and Final
  Destination remain blocked.** Next directly classify CPU-thread waits versus
  OS descheduling. No game process or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-28/g5-pgo-wall-tail-attribution.md`.

## 2026-08-28 — Precision wait, native-resolution, presenter, and Metal attribution

- PERF-090 added origin-specific precision-timer counters. The exact Fountain
  replay measures only 0.000372 ms/frame mean and excludes the timer as the
  approximately 4.87 ms wall/thread gap.
- Corrected the private measurement baseline from a drifted 3x internal
  resolution to native 640x528. A matched native/3x reversal places both total
  p95 values at about 17.85 ms and rejects resolution as the tail fix.
- PERF-092 splits ordinary presenter construction. `BindBackbuffer` owns 99.7%
  of its video-build time; flush/rectangle, XFB, and UI work are negligible.
- PERF-093 directly splits Metal bind work. On exact native emulated frames
  `48123..48562`, `[CAMetalLayer nextDrawable]` averages 4.784 ms, measures
  5.737 ms p95, and accounts for 99.600% of bind time. CPU-thread
  mean/p95/worst are 11.544/12.654/15.782 ms with all 440 rows under budget,
  while total p95 is 17.756 ms and only 243/440 total rows meet 16.7 ms.
- Decision: **drawable availability is the ordinary-frame bottleneck on this
  exact PGO/native Fountain window; G5 remains open; G6 and Final Destination
  remain blocked.** Retain dormant counters as patch 0019. Next inspect the
  drawable lifecycle and run one display-sync-preserving equal-work A/B/A
  candidate. No game process or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-28/g5-frame-wait-and-metal-bind-attribution.md`.

## 2026-08-28 — Runnable descheduling separated; cold EFB prewarm retained

- PERF-104 triggered on a natural 74.578625 ms Fountain frame with 21.186160
  ms CPU-thread work and a 52.940044 ms wall/thread gap. Its 250-us rolling
  sampler reported the emulation thread runnable around the event. PERF-105's
  marker-aligned System Trace reproduced 12.008 ms fragmented non-running time
  among higher-priority host work; process attribution is observer-caveated.
- A LaunchServices Game Mode off/on/off screen was not decisive. The on run
  beat its reverse by only 0.069 ms p95, and logs did not prove continuous
  active mode. Retained the current eligibility plist keys without claiming a
  performance win.
- All three fresh bundles stalled at emulated frame 48436 on 108-134 ms of
  EFB-to-VRAM shader compilation. PERF-110 directly logged the only three cold
  UIDs as R4, RGBA8, and XFB. PERF-111 precompiled exactly those existing
  pipelines; frames 48064 and 48436 recorded zero EFB miss, and frame 48436
  improved from 133.447167 to 17.234125 ms.
- Added canonical patch 0020, packaged opt-in, strict package assertions, and
  the default-dormant triggered sampler. The patch cleanly applied/reversed;
  the native runner rebuilt; a disposable signed app passed layout and strict
  signature checks.
- Removed seven obsolete exact Instruments scratch traces and PERF-109's raw
  scratch after retaining their valid trace bundles, recovering about 11 GiB.
- Decision: **bounded prewarm retained; G5 remains open; G6 and Final
  Destination remain blocked.** Next run one full true-native frontend-PGO
  Fountain combat interval through the packaged prewarm path with only the
  lightweight sampler. Do not resume static flags or rejected scheduler/
  presentation variants.
- Evidence:
  `docs/artifacts/2026-08-28/g5-runnable-descheduling-and-efb-prewarm.md` and
  `docs/evidence/g5-scheduler-and-efb-prewarm/summary.md`.

## 2026-08-28 — Full prewarmed Fountain validation and fourth UID

- PERF-112 completed all 6,723 true-native frontend-PGO Fountain combat frames
  with the lightweight sampler. Total mean/p95/p99/worst are
  16.682/17.584/18.540/48.962 ms; four frames exceed 33 ms, so G5 still fails.
- The first 41.385 ms marker has 25.619 ms off-core gap, 14.809 ms in the final
  presentation region, 0.053 ms `nextDrawable`, no EFB miss, and runnable
  thread-state samples. Remaining severe tails are host scheduling/GPU-queue
  timing rather than statically recompiled on-core execution.
- PERF-112 discovered half-scale XFB as a fourth UID; its 1.036 ms cold compile
  produced only a 17.523 ms frame. PERF-113 added that exact pipeline to startup
  and proved zero combat EFB misses through frame 51604; frame 51484 is 17.480
  ms with no compile.
- Decision: **four-pipeline prewarm retained; G5 open; G6/Final Destination
  blocked.** Next run a prewarmed LaunchServices Game Mode on/off reversal,
  now without cold compilation confounding the severe tail.
- Evidence:
  `docs/artifacts/2026-08-28/g5-runnable-descheduling-and-efb-prewarm.md` and
  `docs/evidence/g5-scheduler-and-efb-prewarm/summary.md`.

## 2026-08-28 — Prewarmed Game Mode reversal retained

- PERF-114/115/116 ran full true-native frontend-PGO Fountain combat through
  LaunchServices with exact common work and zero EFB/interpreter misses.
  Game Policy explicitly logged fullscreen Game Mode on for A and A2; B was
  ineligible.
- On/off/on total p95 is 17.288/17.725/17.462 ms; worst is
  24.337/179.211/24.381 ms. Both Game Mode runs have zero >33 ms frames; the
  off reversal has six. Retain Game Mode as a severe-tail mitigation, not a G5
  pass.
- A signed topology harness retained the product's LaunchServices wrapper
  parent and direct runner child. Gameplay advanced and Game Policy logged
  fullscreen session active, Game Mode enabled, and status on. No launcher
  redesign is required.
- Fresh installs now default to fullscreen; existing saved preferences and the
  menu toggle remain intact. A signed package passed default-config, Game Mode,
  prewarm, layout, and signature checks.
- Decision: **fullscreen default retained; G5 open; Final Destination/G6
  blocked.** Next obtain non-perturbing actual synchronized display cadence
  under Game Mode; do not use the rejected presented-handler observer.
- Evidence: `docs/artifacts/2026-08-28/g5-prewarmed-gamemode-reversal.md` and
  `docs/evidence/g5-prewarmed-gamemode-reversal/summary.md`.

## 2026-08-28 — True-native correction and full-match off-core stall

- Audited the runner's real configuration path after `GFX.ini` reverted to
  scale 3. `moderngekko-run` maps the top-level frontend
  `resolution=1920x1080` to scale 3 and overwrites the GFX file; PERF-091's
  nominal native run was still 3x. Corrected both settings in a fresh private
  clone and retained the byte-identical slot-1 save.
- A 3x/native/3x exact-window reversal has effectively identical guest work.
  Native improves total mean to 16.571 from 16.683/16.677 ms and strict pass
  count to 250 from 243/241, but p95 remains 17.055 ms. Retain native as the
  required baseline; reject it as the tail solution.
- The logger-free PGO full match naturally reached the post-match memory-card
  prompt at a 59.9-FPS title reading. The combat span contains 6,723 phase rows
  with 17.001/17.336/54.523 ms total p95/p99/worst. The 451.066 ms results/save
  transition and subsequent prompt rows are excluded.
- The one >33 ms combat row has ordinary work, 17.223 ms CPU-thread time,
  36.874 ms off-core wall time, 0.031 ms `nextDrawable`, 1.458 ms audio, and no
  EFB miss. The severe stall is pre-Metal and mostly off-core.
- Decision: **PERF-096/097/098 retain true native and pre-Metal attribution;
  G5 remains open; G6 and Final Destination remain blocked.** Next identify a
  concrete kernel wait/scheduling edge without repeating rejected QoS,
  time-constraint, dual-core, timer, or presentation variants. No game process
  or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-28/g5-true-native-and-full-stall-attribution.md`.

## 2026-08-28 — Joined-presentation observer rejected

- Re-audited the Metal lifecycle against retained PERF-064/069/070 evidence.
  `nextDrawable` is the synchronous CPU-side backpressure point, but prior
  synchronized `presentedTime` windows prove that such wait can coexist with
  correct onscreen cadence.
- A first joined run was excluded because the savestate signal opt-in was
  omitted and `SIGUSR2` terminated the runner before combat. The next two
  placements registered `addPresentedHandler` before scheduling and inside
  Dolphin's existing scheduled handler. A regular zero-file versus live FIFO
  controller reversal excluded controller endpoint state.
- All three completed joined runs deterministically changed exact Fountain
  work from 1,501,629,399 to 3,567,157,795-3,567,157,803 cycles and from
  51,369,928 to 59,374,684-59,374,688 dispatches. They also collapsed
  `nextDrawable` from 4.784 to 0.018-0.023 ms mean. The callback changes queue
  behavior and is not an observer.
- Decision: **PERF-094/095 rejected; logger removed; G5 remains open.** Keep
  PERF-093 as CPU-side attribution and PERF-069's stripped actual-presentation
  comparisons as onscreen evidence. Next target the rare pre-acquisition
  full-match stalls or obtain a non-perturbing observer. No game process or
  Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-28/g5-frame-wait-and-metal-bind-attribution.md`.

## 2026-08-28 — External display cadence and startup state-load guard

- Goal: measure actual Game Mode Fountain display cadence without the rejected
  drawable callback, and diagnose the supplied PERF-106 crash report.
- Work: built a Display-only Instruments template; reproduced the state-load
  crash at exact `emulated_frame=0`; deferred state requests until Core is
  Running/Paused; rebuilt; repeated the early signal successfully; captured a
  full 115-second process-attributed Display trace.
- Result: **PARTIAL**. The crash regression passes. Fountain's 6,862 display
  intervals have 16.666417 ms p95/p99, but 15 two-refresh misses plus one
  366.660 ms transition gap fail the strict 16.7 ms worst-case gate. G5 stays
  open, Final Destination and G6 stay blocked.
- Evidence:
  `docs/artifacts/2026-08-28/g5-external-display-cadence-and-savestate-startup.md`.
- Next: align guest present boundaries to Display events in a shared timebase
  and distinguish 59.94-to-60 phase slips from genuine late work before making
  another pacing change.
- Checkpoint validation: canonical patch 0013 reverse-checks cleanly; the
  desktop runner rebuild passes; 40/40 applicable CTest entries and 16/16
  controller-pipe tests pass; repository, shell-syntax, and whitespace checks
  pass; and the rebuilt signed macOS package passes its strict layout check.

## 2026-08-28 — Shared-clock join and logger-free cadence control

- Goal: distinguish guest/display rate conversion, real producer stalls, and
  phase-logger overhead in the external Fountain cadence trace.
- Work: added default-dormant host frame-end timestamps as patch 0021; joined
  PERF-126 phase, Display, queue, swap, and Metal-completion tables; queried
  the M1 panel modes; repeated the full trace as PERF-127 with no phase logger.
- Result: **PARTIAL**. Ordinary p95/p99 are 16.666417/16.666458 ms. Eight queued
  surfaces are not displayed, consistent with 59.94-to-60 fixed-rate
  conversion, but separate no-queue gaps and the 399.993 ms result transition
  keep strict G5 open. The logger-free run reproduces the miss count, so phase
  logging is excluded as its cause.
- Evidence:
  `docs/artifacts/2026-08-28/g5-host-time-join-and-logger-free-cadence.md`.
- Next: isolate repeated missing present-command-buffer assignments from
  downstream queue drops; change only a repeated producer-side cause.
- Validation: patch 0021 reverse-checks cleanly; the runner rebuild,
  dependency bootstrap, repository safety, 40/40 applicable CTest entries,
  16/16 controller-pipe tests, shell syntax, signed package layout, and strict
  signature all pass. The optional standalone `clang-format` executable is
  not installed; AppleClang compiled the touched source successfully.

## 2026-08-28 — Host-only 59.94-to-60 conversion control

- Goal: prove or falsify fixed-panel cadence conversion without changing
  guest speed or running Dolphin.
- Work: extended the retained Metal harness with an optional producer cadence;
  compiled it under AppleClang; ran an unpaced baseline and a 6,600-interval
  16.683 ms producer control.
- Result: **PASS for attribution**. The baseline is 120/120 compliant with
  16.666625 ms worst. The 59.94 Hz control has exactly six 33.333 ms holds,
  16.666667 ms p99, 33.333208 ms worst, and no callback loss. The game's seven
  pre-results queued-surface holds are fixed-rate conversion, not slow static
  recompilation or late GPU work.
- Decision: do not alter guest speed or duplicate content. Continue G5 only
  from no-queue producer stalls and the results transition.

## 2026-08-28 — Rush Frame Presentation rejected

- Goal: test the one existing untried Dolphin mechanism that moves throttling
  away from input-to-present work without changing guest speed.
- Work: cloned the exact isolated user/state, enabled only
  `RushFramePresentation`, captured 45 seconds of phase and Display data, and
  compared exact emulated frames 48123..52195 to PERF-126.
- Result: **REJECT**. Exact guest work matches, but actual 33.333 ms holds rise
  from four to ten, CPU-thread failures double, and drawable stalls above 10 ms
  rise from two to four. Audio remains normal.
- Attribution: the existing post-render sleep is effectively zero; no-observer
  Game Mode controls have no long acquisition wait, so a drawable rewrite is
  not justified by the observer-specific tails.
- Next: retain no product change and investigate the separate approximately
  400 ms results/menu transition.

## 2026-08-28 — Results transition classified

- Goal: decide whether the roughly 400 ms results hold is a slow rendered
  frame before optimizing it.
- Work: saved an isolated pre-boundary state, captured a targeted Time Profiler
  trace, and compared emulated frame 54872 across PERF-124, 126, 130, and 131.
- Result: **NOT A SLOW RENDERED FIELD**. Three natural runs execute the exact
  same 211,892,535 guest cycles and 14,356,543 dispatches while Melee advances
  from output frame 54845 to 54872 without submitting an XFB. CPU work stays
  below budget per each of the 27 internal fields; video/Metal work is tiny.
- Profile: generated guest code owns the CPU samples. Cache-control plumbing is
  visible but below one percent and cannot recover the needed scheduler slack.
- Decision: do not duplicate stale frames or alter guest timing. Keep G5 open
  for the separate pre-results no-queue producer stalls and continue from a
  repeated host/producer cause.
- Evidence:
  `docs/artifacts/2026-08-28/g5-results-transition-classification.md`.

## 2026-08-28 — Profile-edge coverage recovered

- Goal: turn PERF-087's PGO block-layout observation into one bounded source
  candidate without rebuilding the full module on a 99%-full disk.
- Work: remapped the rotated generated-source path, compiled only the exact
  `func_80375940` chunk with coverage mapping, and consumed the retained
  Fountain profile.
- Result: **COUNTERS RECOVERED**. The hot matrix interval executes about 6.94
  million times. It contains two straight-line traces with 26/34 and 51/51 FP
  guards; neither trace branches, calls, writes MSR, performs cache control, or
  invokes a host boundary. Every guard after the first records zero exits.
- Decision: next build a data-only differential trace preflight that preserves
  the first exact FP exception and all arbitrary entries while removing only
  redundant checks. Require full semantics and >5% local speed before a game
  build. G5 remains open; G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-28/g5-profile-edge-coverage-recovery.md`.

## 2026-08-28 — PERF-132 duplicate corrected

- Reconciliation: PERF-088 had already recovered matching coverage and tested
  the source-weight and single-entry FP-trace candidates. The later standalone
  failure was only a rotated source-path error.
- Existing result: source weights were 59.011-62.751% slower; the trace passed
  4,096 state/RAM cases but was 1.343-3.025% slower, including a 2.492% loss in
  the million-entry confirmation.
- Decision: withdraw PERF-132's proposed trace follow-up, do not repeat it, and
  return G5 to the separate pre-results no-queue producer/descheduling tail.
- Evidence:
  `docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md` and
  `docs/artifacts/2026-08-28/g5-profile-edge-coverage-recovery.md`.

## 2026-08-28 — PERF-133 absolute scheduled presentation rejected

- Goal: test the only remaining simple Metal early-commit path without
  changing guest timing or presenting duplicate content.
- Work: extended the host-only three-drawable harness with
  `presentDrawable:atTime:` and an optional 25 ms producer stall; compiled it
  with ASan/UBSan; compared layer display sync on and off; verified the API
  clock against Mach absolute seconds.
- Control: minimum-duration presentation delivered 600/600 intervals with
  16.666667 ms p95, 16.666708 ms p99, 16.666875 ms worst, and zero drops.
- Result: **REJECT**. Absolute scheduling dropped all 601 requested drawables
  with sync on or off, with and without the injected stall. The host clock
  domains agreed within 26 microseconds, so this is not a timing conversion
  error.
- Decision: remove the disposable harness extension and do not build a
  Dolphin candidate. The product is unchanged; G5 remains open for the natural
  no-queue producer/descheduling tail.
- Evidence:
  `docs/artifacts/2026-08-28/g5-absolute-scheduled-presentation-rejection.md`.

## 2026-08-28 — PERF-134 runner/runtime PGO bounded out

- Goal: determine whether profiling the runner, rather than only the generated
  game module, can create material producer slack.
- Work: separated the retained current-PGO sample's runner parent from its
  module child and computed an impossible-best-case coverage bound.
- Result: `StaticRecompCore::Run` has 9,279 samples and module-local
  `chassis_dispatch` has 9,030. All runner-only work is just 249 samples /
  2.683479% of that hot loop.
- Decision: **REJECT before build**. Even deleting every runner-only sample
  misses the 5% preflight gate; runner PGO also cannot remove the natural
  runnable-thread descheduling. No instrumented Dolphin build is justified.
- Evidence:
  `docs/artifacts/2026-08-28/g5-runner-pgo-coverage-bound.md`.

## 2026-08-28 — PERF-135 current Final Destination baseline

- Goal: refresh Final Destination on the retained current-PGO/native/prewarmed
  build and determine whether G5's remaining producer tail is Fountain-only.
- Harness audit: excluded a truncated-log relaunch, a windowed control, and a
  visually wrong-stage fullscreen attempt. Verified the final run's real
  fullscreen state, `Final Destination` stage label, actual stage, coherent
  combat, 59.9-60.0 FPS title readings, Cubeb audio, and natural completion.
- Result: the conservative 2,801-frame combat interior measured 16.683246 ms
  mean / 17.209583 ms p95 / 17.399125 ms p99 / 24.292208 ms worst; 57.194%
  met 16.7 ms and none exceeded 33 ms.
- Decision: **IMPROVED, G5 FAILS**. Final Destination shares the remaining
  producer-tail class; do not promote G6. Retain no product edit.
- Next: use the new private hashed FD slot-1 state for one default-dormant
  phase attribution of the 24 ms class and compare it to Fountain's off-core
  descheduling evidence.
- Evidence:
  `docs/artifacts/2026-08-28/g5-current-final-destination-baseline.md`.

## 2026-08-28 — PERF-136/137 Final Destination off-core reversal

- Goal: attribute the retained current Final Destination producer tail and
  test whether the observed transient filesystem/browser load caused it.
- Harness: excluded a dual-launch trace and a pre-handler signal exit; the
  accepted runs each used exactly one process and loaded the verified private
  FD state only after phase initialization.
- PERF-136: 2,001 exact combat rows measured 17.149958 ms p95 and 27.640792 ms
  worst; CPU-thread p95/worst were only 6.729403/9.792909 ms. The worst row
  lost 19.608531 ms off-core with 0.117750 ms video build.
- PERF-137 reversal: after `fseventsd` and Brave load cleared, p95 remained
  17.148000 ms and worst was 30.737000 ms. That row did 2.589508 ms CPU work,
  lost 24.645359 ms off-core, and spent 0.140500 ms in video build.
- Decision: **COMMON HOST TAIL; TRANSIENT LOAD REJECTED**. Final Destination
  and Fountain are not compute-bound on the current M1 build. Do not reopen
  static compiler, GPU, audio, timer, QoS, dual-core, or presentation routes.
  G5 stays open; G6 stays blocked.
- Evidence:
  `docs/artifacts/2026-08-28/g5-final-destination-off-core-reversal.md`.

## 2026-08-28 — PERF-138/139/140 task-event attribution

- Goal: distinguish hidden in-process blocking/system activity from genuine
  whole-app execution loss in the remaining Final Destination tail.
- API audit: macOS exposes no supported per-thread voluntary/involuntary
  switch counter. Audio-only interval workgroups, generic workgroups, and
  display-link callbacks do not protect the emulator CPU thread.
- Correction: the first task-event snapshot placement ran per CPU slice and
  generated hundreds to thousands of Mach queries per frame; PERF-138/139
  timing is excluded. Patch 0022 now queries supported `TASK_EVENTS_INFO` once
  per presented frame. A 100,000-call preflight repeats at about 0.66
  microseconds mean / 0.71 microseconds p95.
- PERF-140: fresh endpoints visually prove continuous Final Destination combat
  from 1:32 to 0:46. Exact emulated frames 31834..33834 measure 18.717375 ms
  p95 / 21.867375 ms worst; misses average 11.203778 ms wall-minus-thread
  versus 9.541436 ms for compliant rows.
- Result: misses have fewer task context switches and fewer Mach/Unix syscalls,
  not more. **HIDDEN WHOLE-PROCESS BLOCKING ACTIVITY REJECTED; HOST EXECUTION
  LOSS RETAINED.** G5 remains open and G6 remains blocked.
- Next: with explicit authority, pause only the persistently busy Logitech
  updater for a matched retained-state control and immediately resume it.
  Until then, do not blame it or WindowServer.
- Evidence:
  `docs/artifacts/2026-08-28/g5-task-event-attribution.md`.

## 2026-08-29 — PERF-141 Logitech updater isolation

- Goal: test whether the persistently busy Logitech Options+ updater causes
  Final Destination's remaining whole-app execution-loss tail.
- Work: resolved the exact root-owned launch daemon, obtained explicit user
  authority, verified PID 276 stopped at 0% CPU, and reran the same signed
  current-PGO app, private FD state, and 43.2-second balanced input sequence.
  One bad `gcpipe` invocation was excluded before combat input and preserved
  privately; the corrected run used the exact FIFO and an unconditional runner
  cleanup trap.
- Result: **SEVERE TAIL IMPROVED; FUNDAMENTAL LIMIT REJECTED**. Exact frames
  `31813..33813` improve from 18.717 to 17.195 ms p95, 19.466 to 17.365 ms p99,
  and 21.867 to 17.975 ms worst. Frames above 20 ms fall from ten to zero, but
  mean remains 16.683 ms and only 57.571% meet 16.7 ms.
- Visual boundary: fresh endpoints show coherent Pikachu/Yoshi combat from
  1:31.68 to 0:46.84. Final Destination's neon edge/background cycle is normal
  stage presentation; no fighter morphing recurred.
- Decision: Logitech may aggravate intermittent severe stutter, but stopping
  it does not pass G5. The user requested it remain stopped, so no A/B/A
  reversal or exclusive-causality claim is made. Retain no product change;
  continue from the residual required-stage pacing failure. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-logitech-updater-isolation.md`.

## 2026-08-29 — PERF-142/143/144 Fountain baseline and symbolized sample

- Goal: retest Fountain with the authorized updater stop retained, then use a
  fresh native sample to select the next coherent producer optimization.
- Harness: two FIFO-setup failures were excluded before input. The accepted
  runs pre-created the private named FIFO, used exactly one game process, and
  installed unconditional cleanup. The Logitech updater stayed `Ts` at 0% CPU;
  no configuration or launchd state was edited.
- PERF-142: exact frames `49598..51598` measure 16.677958 ms mean, 17.542125 ms
  p95, 18.216125 ms p99, and 34.499292 ms worst. Only 1,049/2,001 (52.424%)
  meet 16.7 ms. The worst row combines 13.545 ms CPU-thread work with 20.483 ms
  off-core time.
- Visual boundary: fresh images show coherent Pikachu/Fox Fountain combat from
  1:44.88 to 0:59.04. No real-mesh warping recurred; the blurred reflection is
  the documented reference-parity behavior.
- PERF-143/144: a fresh sample selected previously unclosed `func_80339940`;
  the line-table rerun used byte-identical `__text`. The function contributes
  106/2,031 active recompiler top-of-stack samples (5.219% impossible-best-case)
  but is diffuse across guest blocks. The hottest resolved line has only three
  samples (0.148%).
- Decision: **G5 FAILS; LOCAL `func_80339940` REWRITE REJECTED**. Logitech is
  not the root cause. Require a shared operation with at least 5% fresh
  projected coverage before another product build. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-fountain-stopped-updater-and-symbolized-sample.md`.

## 2026-08-29 — PERF-145/146 low-overhead Fountain pacing reversal

- Goal: determine whether the current-PGO Fountain severe tail survives
  without the detailed phase logger's per-slice thread-CPU observations.
- Harness: two independent private user/app copies enabled only Dolphin's
  buffered render-time logger. `SSBMPAD_FRAME_PHASE_LOG` was absent. Both used
  the same verified Fountain state, balanced input, one native process, no
  Simulator, and the updater still `Ts` at 0% CPU.
- PERF-145: final presented rows `1413..3413` measure 16.666682 ms mean,
  16.780083 ms p95, 16.824416 ms p99, and 19.897333 ms worst; 72.264% meet
  16.7 ms.
- PERF-146: the same row window measures 16.666737 ms mean, 16.784000 ms p95,
  16.833458 ms p99, and 19.996833 ms worst; 70.965% meet 16.7 ms.
- Mechanism: the slow intervals are immediately followed by 13.4-13.5 ms
  catch-up intervals; both two-frame sums remain near 33.33 ms. Mean is exactly
  60 FPS, but strict worst-frame pacing still fails.
- Visual boundary: both runs show coherent Pikachu/Fox Fountain combat from
  about 1:44.5 to 0:59, with no fighter-mesh recurrence.
- Selection audit: fresh PERF-144 guest-cost attribution maps 1,390 samples;
  every leading family is already closed and no new local candidate clears 5%.
- Decision: **DETAILED OBSERVER CONFOUND CONFIRMED; RESIDUAL G5 PACING FAILS**.
  Keep phase logging for mechanism attribution, not product-speed claims. Next
  observe actual drawable presentation cadence without another scheduling
  change. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-low-overhead-fountain-pacing-reversal.md`.

## 2026-08-29 — PERF-147/148 current actual-presentation deferral

- Goal: determine whether low-overhead app-side jitter reaches the actual
  display or is absorbed by Metal display synchronization.
- Harness: a disposable default-dormant presented-handler recorded acquire,
  registration, and `presentedTime` timestamps on the current runner/module.
  Phase logging was absent. Same Fountain state/input, one process, no
  Simulator, updater stopped. The hook and private runner were removed after
  the runs; the canonical runner was rebuilt without its marker.
- PERF-147: 2,001 actual intervals measure 16.666750 ms p95, 16.666792 ms p99,
  and 33.333375 ms worst; 1,998/2,001 meet 16.7 ms and three miss one refresh.
- PERF-148: p95/p99/worst are 16.666792/16.666833/33.333500 ms; 1,999/2,001
  meet 16.7 ms and two miss one refresh. Neither boundary contains a dropped
  `presentedTime == 0` callback.
- Attribution: all five misses were registered after one normal 16.596-16.792
  ms producer interval and acquired their drawable in 3.955-5.745 ms. Metal or
  macOS deferred an on-time present request by one refresh.
- Observer caveat: callback runs also gained app-side 33 ms intervals absent
  from PERF-145/146, so the measured miss rate is not claimed observer-free.
  Historical actual-display full-match evidence independently retains misses.
- Visual boundary: both runs show coherent Pikachu/Fox Fountain combat with no
  fighter-mesh recurrence.
- Decision: **ACTUAL DISPLAY PACING QUANTIFIED; RARE REFRESH DEFERRAL FAILS
  G5**. Next log command-buffer scheduled/GPU/completed timestamps without
  changing scheduling. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-current-actual-presentation-deferral.md`.

## 2026-08-29 — PERF-149/150 GPU readiness and display deferral

- Goal: distinguish late GPU completion from compositor-only deferral on the
  current Fountain actual-display misses.
- Harness: a disposable default-dormant Metal recorder retained acquisition,
  registration, scheduled, GPU start/end, completion, and `presentedTime`
  timestamps in memory and wrote once at shutdown. Presentation scheduling,
  current-PGO module, native Metal/Cubeb configuration, and verified Fountain
  state were unchanged. One native process ran, no Simulator was booted, and
  Logitech remained kernel-stopped at 0% CPU.
- PERF-149: the short final 2,001 actual intervals all pass, with
  16.666667/16.666708/16.666749 ms p95/p99/worst.
- PERF-150: the sustained 95.884-second combat boundary retains 5,744 actual
  intervals at 16.692862 ms mean, 16.666833 ms p95, 16.666834 ms p99, and
  33.333542 ms worst. Nine intervals miss one refresh; 99.843% meet 16.7 ms.
- Attribution: all nine records were registered 12.397-32.797 ms before the
  skipped refresh and their GPU work ended 10.408-30.918 ms before it. GPU
  duration was 1.565649 ms mean / 1.689158 ms p95 / 2.522875 ms worst.
  **GPU LATENESS REJECTED; READY-FRAME DISPLAY DEFERRAL RETAINED.**
- Visual boundary: coherent Pikachu/Fox Fountain combat proceeds to the
  natural results screen. No fighter-mesh recurrence appears; the known lower
  reflection remains reference parity.
- Reversal: removed the complete private observer, rebuilt the canonical
  runner, and verified its diagnostic marker absent. No product edit remains.
- Decision: strict G5 still fails. Do not retry renderer, GPU, drawable,
  present API, display-sync, timer, QoS, or guest-code variants from this
  evidence. Any next candidate must preserve deterministic guest/audio/netplay
  timing and produce distinct frames rather than hide the fixed-panel
  conversion hold with stale duplicates. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-gpu-readiness-and-display-deferral.md`.

## 2026-08-29 — PERF-151/152 NTSC boundary and light producer split

- Goal: separate fixed-panel conversion holds from genuine late game frames,
  then classify the remaining low-overhead producer tail without the detailed
  phase observer.
- Source/runtime audit: GALE01's current VI registers and Dolphin timing derive
  exactly to `60000/1001 = 59.94005994 Hz` (16.683333 ms). Core Graphics lists
  only 60.000000 Hz modes on this M1 panel. In PERF-127's observer-free stable
  20-100 second trace, 4,794 surfaces queued, 4,788 displayed, and six were not
  selected versus a five-hold rate-conversion expectation.
- PERF-151 exclusion: a direct executable launch did not reproduce the package
  workload and is not a result.
- PERF-152: a packaged default-dormant recorder took one monotonic and one
  thread-CPU timestamp per presenter entry into memory. Disk availability fell
  to 116 MiB; shutdown emitted filesystem rename errors and truncated the CSV.
  Only 1,091 complete combat intervals before the malformed row are retained.
- Result: wall p95/worst are diagnostic-only 17.786/24.618 ms. Thread CPU is
  12.758 ms p95 / 13.852 ms p99 / 14.735 ms worst, with zero rows above 16.7
  ms. All three >20 ms wall rows lose 5.686-12.657 ms off-core.
- Decision: **FIXED-RATE HOLDS SEPARATED; CURRENT CAPTURED PRODUCER TAIL IS
  OFF-CORE.** Do not change VI/audio/netplay timing or count stale duplicates
  as new frames. Disk pressure excludes acceptance use. Remove the recorder,
  restore the private config, rebuild canonical, and recover disk headroom
  before selecting a new host-descheduling mechanism. G5 remains open; G6
  blocked.
- Visual boundary: fresh Pikachu/Fox Fountain endpoints are coherent and show
  no fighter-mesh recurrence.
- Evidence:
  `docs/artifacts/2026-08-29/g5-ntsc-display-boundary-and-light-producer-tail.md`.

## 2026-08-29 — PERF-153/154 quiet input-harness reversal

- Goal: retest the genuine observer-free producer tail after recovering disk
  headroom, then determine whether streamed controller progress contaminates
  the severe tail.
- PERF-153: canonical packaged app/module/state with stock buffered logging and
  live `gcpipe` progress measured 16.708388 ms mean / 16.793208 ms p95 /
  16.891375 ms p99 / 33.330875 ms worst in the final 2,001 rows. Five 33 ms
  and one 30 ms gaps appeared; eight rows exceeded 20 ms.
- PERF-154 reversal: identical product and FIFO timing with only controller
  stdout redirected to `/dev/null` measured 16.666653 ms mean / 16.796250 ms
  p95 / 16.848875 ms p99 / 22.544875 ms worst. Every 30-33 ms gap disappeared;
  only three rows exceeded 17 ms and two exceeded 20 ms.
- Mechanism: the remaining pairs are 22.544875+11.455625=34.000500 ms and
  10.996834+22.290125=33.286959 ms. Mean is exactly 60 FPS, but strict worst
  still fails.
- Host audit: no thermal/performance warning and 59% memory free. WindowServer,
  Codex, OpenCodex/Bun, and Brave were active, but spot CPU values are not
  causal evidence and no unrelated user process was stopped.
- Decision: **STREAMED-HARNESS SEVERE TAIL EXCLUDED; RESIDUAL PACING FAILS
  G5.** Silence controller progress in all future perf windows. This is not a
  product edit or pass. A matched unrelated-process pause needs explicit user
  authority. G6 remains blocked.
- Visual boundary: both Pikachu/Fox Fountain runs are coherent with no fighter-
  mesh recurrence.
- Evidence:
  `docs/artifacts/2026-08-29/g5-quiet-input-harness-reversal.md`.

## 2026-08-29 — PERF-165/167 latency-QoS and complete Logitech isolation

- Goal: determine whether direct latency-QoS is a new supported macOS
  descheduling mechanism, then test the newly authorized complete Logitech
  stop without touching unrelated applications.
- Source audit: Apple XNU commit `f6217f891ac0bb64f3d375211650a4c1ff8ca1ea`
  labels the field timer latency QoS and consumes it in timer coalescing.
  User-interactive QoS maps to tier 0, so the prior rejected QoS run already
  covered it. No preflight or product build was justified.
- Harness correction: excluded setup attempts caught a broad self-matching PID
  search, early signal-handler timing, `SIGUSR1` save versus `SIGUSR2` load,
  stale fullscreen IDs, and one invalid two-process capture fallback. The
  verified state remained `e4813633...`; no excluded attempt is a speed result.
- PERF-165: exactly one native runner used the current-PGO module, verified
  Fountain state, Metal/Cubeb, stock buffered logger, and 45-second quiet
  balanced input while updater PID 276 and agent PID 629 were both stopped at
  0% CPU. Final 2,001 rows measure 16.675053 ms mean / 16.794959 ms p95 /
  16.838917 ms p99 / 33.249209 ms worst; 70.215% meet 16.7 ms.
- PERF-167 visual-only proof: Dolphin framebuffer screenshots advance from
  1:48.24 to 1:33.83 with coherent Pikachu/Fox models and no real-mesh warp.
  The known Fountain reflection distortion remains.
- Decision: **LATENCY-QOS IS NOT NEW; ALL-LOGITECH ISOLATION FAILS G5.** No
  product change remains. G5 stays open and G6 blocked. A causal unrelated-app
  reversal requires explicit reversible authorization.
- Evidence:
  `docs/artifacts/2026-08-29/g5-latency-qos-and-logitech-agent-isolation.md`.

## 2026-08-29 — PERF-168 one-frame presentation-reserve rejection

- Goal: determine whether one distinct completed frame held ahead of display
  can absorb the retained off-core producer tail without changing guest,
  input, audio, or netplay timing.
- Trace screen: replaying PERF-152's exact 1,091 combat intervals at a 60 Hz
  consumer cadence needed at most the current frame plus one reserve and had
  zero underflows, so the idea advanced to a host-only Metal control.
- Source audit: Dolphin currently renders XFB/UI directly into a synchronously
  acquired drawable and commits through the mutable global Metal state tracker.
  A real reserve would require an isolated consumer queue/thread plus explicit
  surface, resize, screenshot, UI, GPU-completion, and shutdown ownership.
- Exclusion: the first disposable harness deadlocked on a missing initial
  condition-variable notification before any measurement. It was stopped and
  corrected rather than retried unchanged.
- Corrected 360-frame result: capacity one versus two both had zero underflows
  and sequential distinct frames, but actual worst remained
  33.333917/33.333875 ms. Capacity two raised ready-to-submit p95 from
  15.017317 to 22.417750 ms.
- Sanitized 600-frame repeat: after disabling unsupported LeakSanitizer, ASan
  and UBSan emitted no diagnostic. Actual worst again remained
  33.333875/33.333792 ms; capacity two again added latency and no cadence gain.
- Decision: **ONE-FRAME PRESENTATION RESERVE REJECTED.** Metal's drawable path
  already absorbed the injected 8 ms stall. Do not add a second app-level
  queue/offscreen presentation thread or duplicate stale content. The
  disposable source was removed; product and runtime remain unchanged. G5 is
  open on another causal producer mechanism, and G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-one-frame-presentation-reserve-rejection.md`.

## 2026-08-29 — PERF-169 title-thread and overloaded-host rejection

- Goal: test whether ModernGekko's once-per-second FPS-title thread causes the
  remaining isolated clean hitches.
- Disposable screen: unchanged signed app/current PGO module/Fountain state,
  fullscreen Metal/Cubeb, quiet 45-second balanced input, one game, and no
  Simulator. Only private `show_fps_in_title=true/false/true` changed.
- Exclusion: the common final 1,401 rows degraded monotonically across A/B/A:
  41.685, 38.389, then 32.110 FPS. Guest work totals also differed. No Game
  Mode session was confirmed, and read-only snapshots showed substantial,
  changing normal host activity. No unrelated process was changed. All three
  legs are excluded as product-speed or title-option evidence.
- Retained causal screen: a one-second updater should phase-lock hitches within
  one/two adjacent modulo-60 frame bins. PERF-154's >17 ms rows occupy phases
  26/21/48; PERF-165's occupy 4/24/34/35/18/56/30. Their best adjacent bins
  contain only 1/3 and 2/7 respectively.
- Decision: **FPS TITLE THREAD REJECTED AS CLEAN-TAIL CAUSE.** Preserve the
  useful option. The disposable setting is restored, product remains unchanged,
  and no game or Simulator remains. G5 stays open; G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-title-thread-and-overloaded-host-rejection.md`.

## 2026-08-29 — PERF-170 runtime-diagnostics cost rejection

- Goal: determine whether ModernGekko's always-on `after_frame_event`
  diagnostics snapshot hook is material enough to lazy-gate for G5.
- Source audit: the hook hashes 88 projection bytes, increments one relaxed
  atomic, and stores twelve relaxed statistic values. It performs no lock,
  allocation, I/O, syscall, GPU operation, or wait. The public snapshot API has
  future diagnostics value even though the current launcher has no caller.
- Host preflight: an exact-shaped `-O3 -mcpu=apple-m1` loop repeated ten million
  calls five times at 59.410-62.788 ns/call, about 0.00036% of 16.7 ms.
- Sanitizer: ASan/UBSan with unsupported leak detection disabled ran 100,000
  calls without a diagnostic at 92.040 ns/call.
- Decision: **DIAGNOSTICS LAZY-GATING REJECTED.** Roughly sixty nanoseconds is
  far below materiality and cannot solve millisecond off-core gaps. Preserve
  the public behavior. The disposable source was removed; product remains
  unchanged, G5 stays open, and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-runtime-diagnostics-cost-rejection.md`.

## 2026-08-29 — PERF-171 PGO package Game Mode refresh

- Goal: verify the fastest reusable local PGO package is current and eligible
  for the next confirmed Game Mode G5 run.
- Audit: canonical `SsbmPad.app` passed the Game Mode-aware layout check. The
  ignored PGO app remained signed and retained module `bd089303...`, but its
  stale `Info.plist` lacked both the games category and `LSSupportsGameMode`,
  so package layout failed.
- Repair: ran `package-local-pgo-app.sh` with the validated read-only revision-0
  ISO and known private profile. The existing script preserved/restored the
  canonical active pointer and retained the stale app as timestamped backup.
- Result: refreshed PGO app contains games-category/Game Mode metadata, current
  runner `e1f3c1d8...`, unchanged PGO module `bd089303...`, native arm64 and
  macOS-14 identities, passing layout, and a valid strict deep signature. The
  canonical active module returned to profile-free `03e7936e...`.
- Decision: **FASTEST PACKAGE READINESS RESTORED; G5 NOT CLAIMED.** No game or
  Simulator ran. Require a naturally clean host plus confirmed fullscreen Game
  Mode before using it for Fountain/Final Destination acceptance. G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-pgo-package-gamemode-refresh.md`.

## 2026-08-29 — PERF-172 current Game Mode activation probe

- Goal: prove the refreshed PGO runner topology actually reaches Game Mode on,
  rather than converting eligibility metadata into an activation claim.
- Setup: signed disposable LaunchServices wrapper stayed parent of exact
  current runner `e1f3c1d8...` and known PGO module `bd089303...`; isolated
  user tree, Metal/Cubeb/fullscreen/prewarm, one game, and no Simulator.
- Exclusion: the first stream command selected zsh's `log` builtin and failed
  before launch. The corrected command used `/usr/bin/log`.
- Result: Game Policy found `SsbmPadRunner` via Info.plist, acquired identified-
  game/frontmost/fullscreen/console grants, activated a fullscreen gaming
  session, logged `Game mode enabled`, enabled DPS, and reported `Game mode
  status is now on`. The initial paused state preceded the fullscreen grant.
- Boundary: no state load, input, screenshot, visual check, or timing occurred;
  current external host activity invalidates performance evidence. The runner
  reached core init and shut down with zero fallback/failed SMC verification.
- Reversal: stopped runner, wrapper, and log stream; no game or Simulator
  remains. Disposable data stays private.
- Decision: **CURRENT GAME MODE ACTIVATION PROVEN; G5 NOT CLAIMED.** Gate the
  next clean combat run on the same activation line. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-current-gamemode-activation-probe.md`.

## 2026-08-29 — PERF-173 confirmed-Game-Mode Fountain window

- Goal: test the strict G5 Fountain boundary with the refreshed current-PGO
  package only after macOS explicitly activates Game Mode for that process.
- Setup: disposable signed wrapper, exact `e1f3c1d8...` runner and
  `bd089303...` PGO module, verified private Fountain state, fullscreen Metal,
  Cubeb, EFB prewarm, one game, no Simulator, and quiet 18-repeat balanced
  combat input.
- Runtime gate: Game Policy logged the identified game, active fullscreen
  session, `Game mode enabled`, and `Game mode status is now on` before
  `SIGUSR2` state load. Shutdown recorded 696,674,344 native dispatches, zero
  fallback, and zero failed SMC verification; thermals recorded no warning.
- Result: exact final 2,001 rows average 16.666485736 ms / 60.000651 FPS,
  p95 16.807334 ms, p99 16.916375 ms, and worst 17.477083 ms. No row exceeds
  20 ms, but only 69.165417% meet 16.7 ms. The largest rows have short catch-up
  successors, including 17.477083 -> 15.861250 ms.
- Boundary: no fresh UI-driven screenshot was taken, so no new visual claim is
  attached. No source or product setting changed. Fountain still fails strict
  G5; do not run Final Destination or G6.
- Evidence:
  `docs/artifacts/2026-08-29/g5-confirmed-gamemode-fountain-window.md`.

## 2026-08-29 — PERF-174/175 sustained pre-results and rate alignment

- Goal: extend the confirmed-Game-Mode Fountain evidence and test whether exact
  60000/1001-to-60 host-rate alignment removes the residual holds.
- Harness correction: an actively polled 36-cycle attempt is excluded from
  speed claims. A silent persistent-session repeat ran without session polling
  during gameplay. Both attempts reached their first 621-629 ms transition at
  exact render row 6,784, followed by results-like transitions 6-8 seconds
  apart. Rows after 6,783 are excluded from combat metrics.
- Control: the clean final 2,001 pre-transition rows average 16.666780026 ms /
  59.999592 FPS, p95 16.785125 ms, p99 16.835750 ms, and worst 16.946375 ms;
  zero exceed 17 ms. The wider 4,001-row pre-transition window has four rows
  above 33 ms and remains a strict G5 failure.
- Candidate: private `EmulationSpeed = 1.001`, with exact same PGO app, state,
  Metal/Cubeb, fullscreen Game Mode, and quiet 18-cycle input. Final 2,001 rows
  measure 16.675137619 ms mean, 16.791291 ms p95, and 33.281208 ms worst.
- Reversal: removed the experimental setting and restored `Dolphin.ini` to
  exact SHA-256 `1f3a69fa...`. Zero fallback/failed SMC, no thermal warning,
  no game or Simulator, and no product source change.
- Decision: rate alignment rejected; G5 open, Final Destination and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-sustained-pre-results-and-rate-alignment-rejection.md`.

## 2026-08-29 — PERF-176 current render/vblank stall join

- Goal: determine whether current confirmed-Game-Mode pre-results holds begin
  upstream in vblank/CPU execution or only after submission in the compositor.
- Method: read-only join of the retained clean render/vblank logs; no game,
  observer, profiler, setting, source edit, or Simulator.
- Result: all six post-boot pre-results render intervals above 20 ms pair with
  vblank stalls at an exact +172-row offset. The four 33.218-33.292 ms render
  rows pair with 33.969-34.979 ms vblank rows.
- Decision: current holds begin in the combined CPU-GPU/vblank host-execution
  path. Existing supported scheduling routes are rejected; Apple's affinity
  tag is not P-core pinning, so no no-op patch was built. G5 remains open,
  Final Destination and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-current-render-vblank-stall-join.md`.

## 2026-08-29 — PERF-177 reference, shader, and streaming rejection

- Goal: find a distinct supported host-execution mechanism in SunPad, current
  Slippi/Dolphin, runtime shader workers, or extracted-disc streaming.
- Result: Slippi retains ordinary pthread workers and Apple's cache-affinity
  hint, not a hidden scheduler policy. The current pipeline UID cache predates
  both clean runs and was unchanged, proving no new on-demand pipeline UIDs.
  A retained profile gives shader compilation only 15/12,067 samples.
- DVD boundary: runtime boots `DirectoryBlobReader`; `LoadGameIntoMemory` only
  wraps file discs, and FastDisc already failed. No inert A/B was launched.
- Decision: shader, DVD, affinity, and Slippi-transfer guesses rejected. No
  source/config/process change. G5 open; Final Destination and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-reference-shader-and-streaming-rejection.md`.

## 2026-08-29 — PERF-178 FPS-title Spotlight rejection

- Goal: test whether once-per-second FPS window-title changes cause the current
  Fountain tail through newly observed AppKit/CoreSpotlight indexing.
- Mechanism: unified logging proves live title changes trigger recurring
  window-tab indexing and CoreSpotlight `index-items` batches.
- Test: a private one-variable `show_fps_in_title=false` run used the same PGO
  app, isolated Fountain state, fullscreen Metal, Cubeb, confirmed Game Mode,
  quiet input, one game, and no Simulator. Recurring combat indexing vanished.
- Result: the final 2,001 rows still average 16.675156588 ms / 59.969452 FPS,
  with 16.801375 ms p95 and a 33.398500 ms worst frame. The matched title-on
  control was 59.969577 FPS with a 33.919041 ms worst. Removing the side effect
  did not remove the failure.
- Reversal: restored the private config byte-for-byte to SHA-256 `b0823b...`;
  no source change, game, or Simulator remains.
- Decision: title indexing is real but not the primary G5 cause. Keep the FPS
  title option and continue from PERF-176's combined CPU-GPU/vblank host-
  execution stall class. G5 open; Final Destination and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-fps-title-spotlight-rejection.md`.

## 2026-08-29 — PERF-179 two-drawable Metal layer rejection

- Goal: test whether reducing the native Metal layer pool from its default
  three drawables to two removes remaining queue/compositor holds without
  changing guest, audio, or netplay timing.
- Candidate: one private `setMaximumDrawableCount:2` call, proven in the built
  Objective-C object and packaged in a unique signed Game Mode app with the
  unchanged PGO module and Fountain state.
- Result: catastrophic regression. The final 2,001 render rows average
  25.662329 ms / 38.967624 FPS, with 33.393333 ms p95, 33.554417 ms worst, and
  1,080 rows above 30 ms. Vblank independently averages 25.661202 ms with
  34.497833 ms p95. Repeated doubled/short returns show pool starvation.
- Reversal: removed the source call and rebuilt the canonical runner to exact
  SHA-256 `0abc212b...`; the selector is absent, and no game or Simulator
  remains.
- Decision: default three-drawable pool retained; do not retry queue-depth
  reduction. G5 open; G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-two-drawable-layer-rejection.md`.

## 2026-08-29 — PERF-180 current Main Menu window

- Goal: determine whether the exact current PGO/Game Mode package still has a
  sustained 12.5-30 FPS Main Menu mode.
- Route: one cold packaged process, no savestate or Simulator. MemoryWatcher
  proved the title lockout and `0x01000000` menu class, followed by a five-
  second settle and untouched 60-second wall hold with the controller FIFO
  kept open.
- Result: the conservative 3,413-row buffered bracket averages 16.683976 ms /
  59.937749 FPS, with 18.793042 ms p95, 19.611250 ms worst, no row above 20 ms,
  and 59.743392 FPS worst rolling 60-frame cadence. The old sustained collapse
  does not reproduce, but delayed/early pacing remains.
- Boundary: no fresh visual claim; buffered line counts are an interior timing
  bracket rather than exact wall endpoints. Zero fallback/failed SMC and no
  thermal or performance warning.
- Decision: reject a current sustained 12.5-FPS menu diagnosis; do not claim
  perfect smoothness or G5. Continue the shared pacing/descheduling work. G6
  blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-current-main-menu-window.md`.

## 2026-08-29 — PERF-181 Cubeb buffer rejection

- Goal: reduce real-time audio callback wake pressure without disabling the
  required Cubeb output.
- Preflight: DSP-thread toggling is inert for DSP HLE. Cubeb ignores generic
  `AudioLatency`; a one-time startup diagnostic measured the device minimum at
  128 frames, proving a 512-to-1,024 request change is effective.
- Result: final 2,001 Fountain render rows regress from the 512 control's
  59.969577 FPS / 16.786209 ms p95 / two >20 ms rows to 59.910028 FPS /
  16.789792 ms p95 / three doubled rows. Vblank retains five >20 ms rows.
- Reversal: restored Cubeb 512, removed the diagnostic, rebuilt exact canonical
  runner SHA-256 `0abc212b...`, and restored the excluded logger probe byte-for-
  byte. No game or Simulator remains.
- Decision: larger Cubeb buffer rejected; it adds latency without removing the
  shared render/vblank hold. G5 open; G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-cubeb-buffer-rejection.md`.

## 2026-08-29 — PERF-182 independent G5 boundary audit

- Goal: independently challenge the accumulated conclusion before another
  speculative build.
- Method: read-only review of D2, newest G5 artifacts, and current runtime/
  Metal/audio source; no edit, build, launch, process, or GUI action.
- Result: no evidence-qualified public product-local mechanism remains.
  Compute, GPU, presentation, scheduler/timer, audio, shader, disc, title, and
  known Logitech routes all have causal closures. Foundation animation
  tracking is only a signpost observer by Apple's documentation.
- Boundary: fixed-panel conversion holds and genuine producer failures must
  stay separate. The PRD is not changed or weakened; producer rows still fail
  16.7 ms.
- Decision: do not repeat a product build. The smallest unresolved causal test
  is explicitly authorized reversible isolation of unrelated runnable host
  load, followed by both required stages. Leave unrelated processes alone
  until that scope exists. G5 open; G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-independent-boundary-audit.md`.

## 2026-08-29 — PERF-183 Activity Monitor isolation A leg

- Goal: identify the exact external-load scope and retain the unchanged A leg
  without pausing an unauthorized user process.
- Host audit: Activity Monitor fluctuated at 0.6-7.3% CPU with root `sysmond`
  at 0-4%; Brave was small, Claude idle, OpenCodex's spike transient, and
  Logitech remained stopped. No process was changed.
- Result: confirmed-Game-Mode Fountain final 2,001 rows measure 59.790259 FPS,
  16.795167 ms p95, 33.468333 ms worst, and seven doubled render rows. Vblank
  has matching stalls and a 36.375250 ms worst.
- Boundary: historical quiet controls are context only. No causal verdict is
  valid until an explicitly scoped Activity-Monitor-only stopped B and resumed
  A2 exist. `sysmond` and every other app/service stay untouched.
- Decision: retain A and wait for exact scope; G5 open, G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-activity-monitor-isolation-a-leg.md`.

## 2026-08-29 — PERF-184 non-blocking correction and pivot

- Correction: Activity Monitor does not need to be paused for the goal loop to
  continue. PERF-183's B/A2 proposal was an optional causal diagnostic, not a
  prerequisite or blocker; treating it as the only next action was incorrect.
- Decision: park B/A2 indefinitely. Do not signal Activity Monitor, `sysmond`,
  or any unrelated app/service. Preserve PERF-183 only as a non-causal A
  observation.
- Pivot: resume the G5 unblocking ladder with scoped macOS work that does not
  depend on changing unrelated processes. G5 remains open and its 16.7 ms
  requirement is unchanged; this correction is not a performance pass.

## 2026-08-29 — PERF-185 park-and-pivot native regression

- Goal: verify the restored macOS baseline after parking optional external
  isolation, without launching the game or changing unrelated processes.
- Method: run all 26 `moderngekko.*` CTest cases from the existing desktop-app
  build in parallel with failure output enabled.
- Result: 26/26 pass in 4.84 seconds, including runtime/module loading, CPU/GX,
  audio, frontend configuration, MemoryWatcher utilities, and netplay protocol.
- Decision: baseline integrity is retained. This is not performance evidence;
  G5 remains open. Continue with a new falsifiable product-local mechanism or
  another independent macOS step under the park-and-pivot rule.
- Evidence: `docs/artifacts/2026-08-29/g5-park-pivot-regression.md`.

## 2026-08-29 — PERF-186 combined producer/presentation join

- Goal: determine whether producer/vblank stalls and actual-display holds are
  one causal chain by recording producer thread timing, Metal GPU completion,
  and drawable presentation in the same run.
- Method: a disposable dormant hook buffered GPU/presentation records until
  shutdown; the existing detailed phase logger supplied the same-timebase
  producer data. One isolated native PGO Fountain state used quiet balanced
  input; no Simulator or unrelated process change occurred.
- Result: the 57.844-second pre-transition boundary contains 3,470 actual
  intervals, all at or below 16.7 ms (16.666916 ms worst), while thirteen
  producer rows exceed 20 ms and one reaches 33.532833 ms. Every producer
  stall maps to a nominal 16.666625-16.666834 ms actual interval. The later
  scene transition is separately late in producer, GPU, and presentation.
- Decision: Metal queue headroom absorbs the observed ordinary producer tail;
  PERF-176's claim that it necessarily becomes a visible hitch is narrowed.
  This short observer-bearing window is not G5, prior sustained display holds
  remain, and Final Destination is untested.
- Reversal: diagnostic source removed; canonical runner restored exactly to
  `0abc212b...`; 26/26 scoped native tests pass; no game or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-29/g5-combined-producer-presentation-join.md`.

## 2026-08-29 — PERF-187 corrected 1x/fullscreen combined join

- Invalidation: after PERF-186 publication, direct configuration inspection
  found authoritative root `config.ini` regenerated as 1920x1080/windowed.
  PERF-186's scale/fullscreen and G5-comparability claims are invalid.
- Correction: set and verify root `resolution=640x528`, `fullscreen=true`,
  `InternalResolution = 1`, and Dolphin fullscreen before launch. Fresh full-
  screen combat and natural-results endpoints bound a 94.650-second Fountain
  match; one runner, Metal/Cubeb, quiet input, and no Simulator were retained.
- Result: actual display mean/p95/p99/worst are
  16.672624/16.666833/16.666834/33.333500 ms. Two actual holds were registered
  and GPU-complete well before their missed deadlines with nominal producer
  phases. All fourteen producer rows above 20 ms map to nominal actual
  intervals; producer worst is 35.904291 ms.
- Decision: fixed-display conversion and producer stalls are independent in
  the same run. Both fail the unchanged G5 gate under their respective
  interpretations. Do not claim stable worst-case 60 FPS or optimize one tail
  as though it causes the other.
- Restoration: disposable hook is absent from checkout; canonical runner is
  exact `0abc212b...`; 26/26 scoped tests pass; no game or Simulator remains.
- Evidence:
  `docs/artifacts/2026-08-29/g5-corrected-combined-producer-presentation-join.md`.

## 2026-08-29 — PERF-188 Final Destination combined join

- Goal: determine whether PERF-187's independent producer/display tails are
  Fountain-specific by repeating the exact joined diagnostic on the retained
  verified Final Destination state.
- Method: verified root 640x528/fullscreen, `InternalResolution = 1`, Metal,
  Cubeb, exact PGO module, quiet input, one native runner, no Simulator, and
  fresh full-screen combat/results endpoints.
- Result: the 73.449-second combat boundary has 4,406 actual intervals at
  16.670575 ms mean / 16.666875 ms p95 / 33.333667 ms worst. Its one actual
  hold has a nominal 17.058208 ms producer phase and GPU completion 31.500 ms
  early. All fourteen producer rows above 20 ms map to nominal actual
  intervals; producer worst is 34.064583 ms.
- Decision: Final Destination reproduces Fountain's two independent tails.
  Both required stages fail G5; do not optimize or describe either tail as the
  cause of the other.
- Evidence:
  `docs/artifacts/2026-08-29/g5-final-destination-combined-join.md`.

## 2026-08-29 — PERF-189 exact-rate actual-presentation rejection

- Goal: reopen PERF-175's exact `1001/1000` host-rate candidate only against
  direct actual presentation, now that PERF-187/188 separate producer and
  display tails.
- Method: clone corrected 1x/fullscreen Fountain and change only private
  `Dolphin.ini` to `EmulationSpeed = 1.001`; retain the same runner/module,
  state, Metal/Cubeb, quiet input, one native runner, and no Simulator.
- Result: the 90.213-second combat boundary still has one GPU-ready
  33.333666 ms actual hold after 30.413 seconds. Producer phase is nominal at
  16.909166 ms and GPU completion is 31.017 ms early. All eighteen producer
  rows above 20 ms are separately buffered.
- Decision: exact rate alignment fixes neither causal class and is rejected.
  Do not increase wall-rate scale without a new mechanism.
- Reversal: remove the private setting and restore `Dolphin.ini` byte-for-byte
  to control SHA `1f3a69fa...`; canonical runner exact; no game/Simulator.
- Evidence:
  `docs/artifacts/2026-08-29/g5-rate-alignment-actual-presentation-rejection.md`.

## 2026-08-29 — PERF-190 frame-interpolation rejection

- Goal: determine whether a genuinely distinct host-generated frame can close
  fixed 59.94-to-60 display holds without changing guest/audio/netplay timing
  or duplicating stale output.
- MetalFX: supported on Apple M1/Metal 4 and fast, but color-only interpolation
  produces a literal 50/50 two-position ghost. Reject without Dolphin motion
  vectors/depth.
- VideoToolbox: macOS 26 low-latency optical flow starts a 640x528 NV12 session;
  steady processing is 2.380 ms mean / 2.498 ms p95 / 2.849 ms worst. It
  reconstructs 4-64 px synthetic motion far better than blending, but fails a
  128 px jump.
- Visual stress: three private retained Melee adjacent-file pairs reproduce
  smeared fighter limbs/silhouettes and effects, including in the lowest-change
  Ness pair. The capture was only about three images/second, so this is a
  conservative artifact screen, not 60 Hz source-quality proof.
- Decision: reject integration. Chronological interpolation requires roughly
  one 16.683 ms source frame of added display/input latency, is macOS/iOS
  26-only, leaves producer stalls untouched, cannot force compositor selection,
  and risks the exact morphing class under active visual scrutiny.
- Reversal: host probes only; product source/module/runner/config unchanged; no
  game or Simulator remains. G5 open, G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-frame-interpolation-rejection.md`.

## 2026-08-29 — PERF-191 fixed-priority preflight rejection

- Goal: screen public `THREAD_EXTENDED_POLICY{timeshare=false}` as a distinct
  response to runnable/off-core producer loss before changing Dolphin.
- Source audit: XNU maps it to fixed scheduling, distinct from precedence,
  QoS, and realtime time constraint. Applying legacy policy clears requested
  pthread QoS unless reapplied; sustained fixed execution also has a demotion
  failsafe.
- Preflight: a data-free periodic 11 ms worker competed with eight harness-
  owned threads. An initial timeshare/fixed/timeshare ordering favored fixed,
  so no conclusion was drawn until order reversal.
- Reversal: fixed/timeshare/fixed produced 5/300, 2/300, and 3/300 budget
  misses. Worst wall times were 29.628, 17.669, and 20.546 ms. Fixed mode does
  not reliably bound the tail.
- Decision: reject before product integration. Do not add a policy helper,
  flag, or `CpuThread` hook. No build, game, Simulator, or unrelated process
  change occurred. G5 open, G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-fixed-priority-preflight-rejection.md`.

## 2026-08-29 — PERF-192 strict G5 evidence classifier

- Goal: make the independent producer/presentation classification durable and
  fail closed on wrong joins, dropped callbacks, or ambiguous readiness.
- Implementation: add `scripts/classify-g5-intervals.py`, explicit bounds,
  one-to-one common-clock/emulated-frame joins, strict GPU-ready two-refresh
  rules, independent producer budget reporting, and no G5 pass claim.
- Regression: nine data-free tests fail before implementation and now pass;
  `scripts/check-repository.sh` runs them and passes.
- Replay: PERF-187/188/189 reproduce 2/1/1 fixed-rate holds, no ambiguous or
  undisplayed records, and 2,583/1,908/2,393 producer misses. Thread CPU is
  above budget in only 2/0/1 rows. Published hand counts and event phases match.
- Decision: retain the tool; do not treat observer-bearing diagnostic traces
  as acceptance or return to broad codegen. Next build a default-dormant,
  observer-light wall/thread producer recorder for the canonical package.
- Runtime: no game, Simulator, build, ROM, save, module, or private trace
  changed.
- Evidence:
  `docs/artifacts/2026-08-29/g5-strict-evidence-classifier.md`.

## 2026-08-29 — PERF-193 lightweight producer recorder

- Goal: retain a reproducible, default-dormant wall/thread-CPU recorder with
  negligible observer work, then classify the cold Fountain producer tail.
- Regression: the data-free compile/behavior test failed before patch 0023
  existed. It now proves disabled mode makes zero clock calls and no file,
  while opt-in mode buffers and flushes once at destruction.
- Correction: exclude an initial dual-core trace that measured the separate
  GPU thread. The valid run explicitly uses `CPUThread = False`.
- Result: 7,431 exact combat intervals average 16.682591 ms / 59.942726 FPS,
  with 16.840625 ms p95 and 39.496833 ms worst. All 104 thread-CPU overruns
  occur in the first ten seconds; later CPU stays within budget while separate
  33.251625/20.855458 ms wall holds remain.
- Verification: the recorder matches all 22,240 independent render-log values
  exactly at the expected one-row offset; Release links, 26/26 scoped tests,
  nine classifier tests, bootstrap, and repository checks pass.
- Decision: retain default-dormant patch 0023. G5 remains open and G6 blocked.
  Next run a second Fountain match in the same process to test one-time warm-
  up versus recurring match-start work.
- Evidence:
  `docs/artifacts/2026-08-29/g5-lightweight-producer-recorder.md`.

## 2026-08-29 — PERF-194 same-process Fountain warm-up

- Goal: distinguish one-time cold warm-up from compute that repeats at every
  Fountain match start.
- Correction: exclude an initial diagnostic whose second-stage highlight was
  not visually verified. Repeat both legs in one process with fresh visual
  Fountain confirmation before each watcher-gated start.
- Cold result: 7,431 rows at 59.949019 FPS mean, 30.972167 ms worst, and 105
  thread-CPU overruns; 104 occur in the first ten seconds.
- Warm result: 7,430 rows at 59.984858 FPS mean, 29.475375 ms worst, and eight
  thread-CPU overruns; only two occur in the first ten seconds.
- Integrity: 30,258 common recorder/render intervals match exactly at the
  expected +1 row offset. One signed process and module remained alive across
  both matches; no Simulator or unrelated process change was used.
- Decision: most cold compute overruns are one-time warm-up, but warm Fountain
  still fails G5 on both compute and separate wall tails. Next join a verified
  warm match's eight CPU rows to retained phase timing. G6 remains blocked.
- Evidence:
  `docs/artifacts/2026-08-29/g5-same-process-fountain-warmup.md`.
