# ssbmpad status

Last updated: 2026-08-24

## Current goal

**G5 — macOS 60 fps: IN PROGRESS**

The native arm64 package now reproducibly completes Character Select ->
controlled 1v1 -> results using the reference FIFO controller path. A clean
Kirby-versus-CPU-Samus time battle on Venom accepted movement, attacks, and
jumps through the match and reached the results screen. A live process sample
captured Cubeb/CoreAudio mixing while game streaming samples were being
pushed. G4 is therefore met.

The lowest unmet gate is sustained 60 fps. Fountain of Dreams is now measured:
a clean Yoshi-versus-CPU-Zelda trace produced 19.552 ms mean / 22.862 ms p95
and 111.083 ms worst. A process sample placed about 88% of the CPU thread in
generated `chassis_dispatch`, so the required scene is CPU-bound. An isolated
PGO candidate improved an exact Yoshi-versus-CPU-Ice-Climbers pair by 8.5% at
median, 10.0% at p95, and 15.4% at p99, but was rejected for an unbounded
129.740 ms worst frame. A smaller no-EXRAM specialization improved an equal
105-second pair by only 3.0-4.4% across sustained percentiles and regressed the
worst frame from 1320.456 ms to 1385.798 ms, so it was also rejected. That
worst-frame comparison was later found to be measurement-confounded: the
logger flushed every frame and visual evidence capture introduced large
pauses. With buffered logging, a capture-free 90-second clean control had a
55.135 ms worst frame and missed the sustained target at 17.903 ms median /
21.168 ms p95. The corrected PGO replay improved every metric to 16.682 ms
median / 16.846 ms p95 / 17.031 ms p99 / 45.425 ms worst; a macOS 14 rebuild
reproduced the result. That portable module is retained locally as the
best-known build, but its ROM-trained profile is not a committable shipping
input. Final Destination is now unlocked through an isolated ROM-safe save and
measured at 16.678 ms median / 16.946 ms p95 / 17.189 ms p99 / 1385.242 ms
worst. Single-loop inlining, blanket loop outlining, and an Apple Silicon
precision-timer spin experiment are rejected. Timestamp correlation attributes
the remaining steady-state tail primarily to generated-module compute. A
combined portable-PGO/no-EXRAM candidate left median unchanged and regressed a
matched attract p95 from 17.848 ms to 19.335 ms, so it was also rejected. A
smaller static reproduction and causal compute-tail reduction are still
required. A profile-free 1024-cycle generated-loop budget also regressed
matched attract p95 to 22.926 ms and is rejected; the default 256 is retained.
Exact `noinline` reproduction of all 247 PGO-cold helper symbols regressed
matched attract p95 to 21.459 ms, proving symbol outlining alone is also
insufficient.

No Simulator is booted. G6 remains gated on G5.

## Goal ledger

| Goal | State | Evidence / blocker |
|---|---|---|
| G0 Environment ready | Pass | `docs/artifacts/2026-08-24/g0-environment.md`; pinned revisions below |
| G1 SMC pass recorded | Pass | `docs/artifacts/2026-08-24/g1-smc-report.md`; no generator proven, runtime guard retained, `smc_failed=0` |
| G2 Module recompiles and links | Pass | `docs/artifacts/2026-08-24/g2-module-and-package.md` |
| G3 macOS boots to title | Pass | `docs/artifacts/2026-08-24/g3-macos-title-and-input.md`; retained title and A-transition screenshots |
| G4 macOS playable | Pass | `docs/artifacts/2026-08-24/g4-controlled-match.md`; clean CSS -> 1v1 -> results plus live Cubeb/CoreAudio mixing evidence |
| G5 macOS 60 fps | In progress | Portable PGO: Fountain 16.682 ms median / 16.846 ms p95 / 45.425 ms worst; Final Destination 16.678 ms median / 16.946 ms p95 / 1385.242 ms worst; tail reduction remains |
| G6 Simulator core boots | Not started | G5 first; no Simulator booted |
| G7 Shell ported | Not started | G6 first |
| G8 Test matrix green | Not started | G7 first |
| G9 Netplay working | Not started | G8 first; requires a synchronized completed match with an iPadOS endpoint |

## Pinned inputs and dependencies

- Retail image: GALE01 disc 0 revision 0, SHA-256
  `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`.
- Extracted DOL: SHA-256
  `0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448`.
- SunPad: `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- ModernGekko: `048c426ba3db0369e40826d22ad3adcce7fe7c58`.
- Dolphin/RecompCore submodule: `e13ab348f13cd67879f6db6e9d7185410f8f62c6`.
- DolRecomp: `93b881c8f73df1d64a88491f2aa50c7c9ed2384d`.
- RecompCore: `af7a1a4854ee243b92926875e5a6b66663b0fda0`.
- ModernGekko Template: `1ee85bb5e09c38f493a09f5fa6e9dc8228b23e42`.
- melee: `8b5e380f412dc6bad8cc0557fa8fd95fee6815ed`.
- m-ex: `c9f25da0e59e8c387895371934e98eb5046796b3`.

## Test matrix

The macOS build/package/title, controlled-gameplay, and live-audio-stack rows
are proven. Lifecycle and performance rows remain open. All iPadOS and iOS
rows are not run because the loop forbids moving to G6 before G5 passes.

## Open defects and decisions

- **INPUT-001:** Supplied disc is GALE01 revision 0 rather than the PRD's
  preferred revision 2. Proceed per PRD Section 5.1 and keep module identity
  tied to the actual SHA-256.
- **INPUT-002 (superseded):** Native Quartz was not reliable enough for replay;
  the shipped reference FIFO path now provides reproducible controlled input.
- **INPUT-003 (fixed):** The FIFO parser/controller binding was corrected and
  replayed successfully through a complete clean 1v1.
- **LAUNCHER-001 (fixed):** Removed the unsolicited recursive Documents scan at
  startup; Browse remains explicit.
- **LAUNCHER-002 (fixed):** Replaced the frontend's blocking child wait with a
  nonblocking event-pumping wait so macOS no longer marks it unresponsive while
  the runner is active.
- **PERF-001:** Fountain of Dreams is CPU-bound and fails G5: the clean exact
  trace is 19.326 ms median / 22.862 ms p95 / 111.083 ms worst.
- **PERF-002 (fixed):** Forced Ninja response files broke CMake's Apple IPO
  probe while the cache identity still claimed ThinLTO. The macOS configure path
  now uses platform-default response files and a distinct cache identity.
- **PERF-003:** Corrected buffered C-backend PGO improves Fountain mean 8.3%,
  median 6.8%, p95 20.4%, p99 22.6%, and worst 17.6%. The portable macOS 14
  module is retained locally as the best-known build, but the ROM-trained
  profile remains local and cannot be the reproducible shipping solution.
  PGO still fails the 16.7 ms p95/p99/worst gate.
- **PERF-004:** A GameCube-only RAM specialization improved an equal Fountain
  pair by 3.0-4.4% across mean/median/p95/p99 but was rejected below the 5%
  retention threshold. Its reported 1385.798 ms worst-frame comparison is
  invalidated by the measurement correction below and is not a product claim.
- **PERF-005 (fixed):** The frame-time logger forced a file flush every frame,
  while screenshots inside exploratory runs introduced multi-second pauses.
  Logging is now buffered through a reproducible dependency patch. A 90-second
  capture-free Fountain control had a 55.135 ms worst frame, disproving the
  previously inferred recurring approximately 1.3-second product hitch for
  that run; sustained timing still fails G5.
- **PERF-006:** Forcing the hottest sampled generated polling helper,
  `loop_80349494`, to inline removed its symbol but regressed the matched
  Fountain replay to 18.293 ms median / 22.040 ms p95 / 24.031 ms p99. The
  experiment was rejected, generated/cache state was restored, and the local
  portable PGO module remains the best-known build.
- **PERF-007:** Final Destination is unlocked in an isolated local GCI and was
  verified after a clean no-mod restart. Its matched portable-PGO run measured
  16.678 ms median / 16.946 ms p95 / 17.189 ms p99 / 1385.242 ms worst. The
  stage blocker is closed, but G5 still fails on shared tail behavior.
- **PERF-008:** Blanket `noinline` on all 969 generated loop helpers collapsed
  an active attract battle to 4.1 FPS and was rejected. A default-off Apple
  Silicon precise-spin timer improved a matched attract p99 by only 0.63%,
  left p95 effectively unchanged, retained multi-second tails, and was also
  rejected. Default source, profile, cache, and app state were restored.
- **PERF-009:** Timestamp correlation attributes frames above 17 ms primarily
  to generated-module work rather than timer overshoot. Combining PGO with the
  no-EXRAM specialization left median unchanged and regressed a matched attract
  p95/p99 to 19.335/20.477 ms, so the combination was rejected before
  required-stage replay. The portable-PGO app was restored.
- **PERF-010:** Raising the generated loop return budget from 256 to 1024
  cycles reduced potential dispatcher boundaries but regressed matched attract
  median/p95/p99 to 16.757/22.926/24.989 ms and vblank in parallel. The
  profile-free experiment was rejected and default 256 restored.
- **PERF-011:** All 247 PGO-only loop helpers had profile entry counts zero
  through nine. A profile-free candidate outlined exactly those helpers and
  retained the hot polling helper, but regressed attract median/p95/p99 to
  16.814/21.459/22.548 ms. PGO branch weights and internal block layout, not
  helper symbol presence alone, are material.
