# ssbmpad status

Last updated: 2026-08-25

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
A 2:1 Fountain/attract combined PGO profile improved attract p95 slightly to
17.682 ms but worsened mean and p99 to 17.744/20.654 ms, so it was rejected.
The controlled FIFO route was then re-established end to end and used for
visible Fountain and Final Destination 1v1s. A direct 2:1 Fountain/Final
Destination PGO profile also failed its matched attract screen: median/p95
regressed from 16.684/18.077 ms to 16.778/18.383 ms and worst rose from 19.088
ms to 57.091 ms. That candidate is rejected and the retained Fountain-only
module is restored. Revision-0 source attribution then identified
`loop_80349494` as the scheduler idle loop. Configuring Dolphin's existing
`StaticRecompIdlePC` facility removes it from the hot-dispatch histogram and
roughly halves host dispatch/cycle work in comparable attract runs. The
optimization is retained, but it is not a G5 pass: profile-free active scenes
still ran around 40-55 FPS and reached 16.9 FPS on Jungle Japes. Further work
must train and measure visually verified required-stage combat with idle
skipping active, rather than profile idle polling.

The next C-emitter experiment inlined the common `MSR.FP` enabled check while
preserving the existing FP-unavailable exception fallback. A clean matched
1,000-frame screen improved p95/p99 by 3.1%/3.4%, but regressed worst frame
from 27.987 to 34.777 ms and the <=16.7 ms share from 49.80% to 49.20%.
Four-player scenes still ran around 45-48 FPS. The candidate is rejected under
the strict retention rule and dependency source is restored.

No Simulator is booted. G6 remains gated on G5.

The Fountain visual report is split as `VISUAL-001A/B`. The blurred/blocky
lower reflection is closed as reference parity: it appears in profile-use,
profile-free, no-module, and signed official Dolphin 2606a native-scale Metal
runs. EFB-to-RAM and non-deferred-copy experiments were unnecessary and were
reverted. The separate fighter-body report was not reproduced in an initial
9.8-second interaction clip, but a later four-player montage retained one fresh
suspected vertical fighter stretch. `VISUAL-001B` is reopened and conservatively
blocks promotion until uncontaminated adjacent frames or a matched reference
sequence classify it.

## Goal ledger

| Goal | State | Evidence / blocker |
|---|---|---|
| G0 Environment ready | Pass | `docs/artifacts/2026-08-24/g0-environment.md`; pinned revisions below |
| G1 SMC pass recorded | Pass | `docs/artifacts/2026-08-24/g1-smc-report.md`; no generator proven, runtime guard retained, `smc_failed=0` |
| G2 Module recompiles and links | Pass | `docs/artifacts/2026-08-24/g2-module-and-package.md` |
| G3 macOS boots to title | Pass | `docs/artifacts/2026-08-24/g3-macos-title-and-input.md`; retained title and A-transition screenshots |
| G4 macOS playable | Pass | `docs/artifacts/2026-08-24/g4-controlled-match.md`; clean CSS -> 1v1 -> results plus live Cubeb/CoreAudio mixing evidence |
| G5 macOS 60 fps | In progress | FP fast path rejected on worst frame; four-player scenes remain 45-48 FPS; `VISUAL-001B` reopened |
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
- **PERF-012:** A separate three-minute attract profile merged at 1:2 weight
  with the original Fountain corpus improved attract p95 and vblank tail but
  regressed render mean/p99 to 17.744/20.654 ms. It was rejected before real
  stages; useful broader PGO must train Fountain and Final Destination.
- **PERF-013 (fixed):** Revision-0 generated source proves `loop_80349494` is
  the OS scheduler idle loop, not an active-gameplay helper. The retained
  GALE01r0 game-settings patch routes that PC through ModernGekko's existing
  `CoreTiming().Idle()` path. It disappears from the top dispatch sites and
  sharply reduces idle dispatch/cycle counts without changing guest behavior.
  Profile-free active combat still fails G5, so this closes wasted idle work,
  not the performance gate.
- **PERF-014:** Inlining the common `MSR.FP` enabled check preserved the
  exception fallback and passed generated-C plus PowerPC reference tests. A
  clean matched screen improved p95/p99 from 20.622/21.597 to
  19.979/20.854 ms, but worst regressed from 27.987 to 34.777 ms and the
  <=16.7 ms share slipped. It is rejected; see
  `docs/artifacts/2026-08-25/g5-fp-fast-path-and-watcher-audit.md`.
- **INPUT-004:** Static-recomp watched memory is fixed and reproducibly
  packaged. Direct bounded MEM1/MEM2 reads are used only for an active static
  module; ordinary cores retain the MMU path, and initial zero is now
  published. Generated revision-0 instructions corrected the mixed-revision
  predicates to `GameState=0x80477D68` and title lockout `0x804D4594`. A cold
  replay observed the complete 20-to-zero lockout transition, sent one START,
  reached Main Menu, and visibly reached four-slot VS CSS after bounded menu
  readiness windows. The final `GM_VS` watcher notification still timed out
  despite visible CSS, so the route is a visual pass but not yet a fully
  self-verifying predicate pass. Required-stage profiling remains visually
  gated. Evidence:
  `docs/artifacts/2026-08-25/g5-static-recomp-memory-watcher-route.md`.
- **VISUAL-001A (closed as reference parity):** The blurred/blocky Fountain
  floor reflection appears in PGO, profile-free, no-module, and signed official
  Dolphin 2606a JIT64 SC + Metal native-scale runs. It is not an ssbmpad visual
  regression. EFB-to-RAM and non-deferred-copy controls were reverted.
- **VISUAL-001B (reopened):** The initial 9.8-second interaction clip and
  49-frame review were coherent, but a fresh four-player frame shows an orange
  fighter in a suspected implausible vertical stretch. The adjacent capture was
  contaminated and a later sample was coherent, so subsystem attribution is
  still open. The user explicitly reconfirmed that bizarre character morphing
  and body warping must remain tracked independently of the reference-matching
  Fountain reflection. Promotion is blocked conservatively pending clean
  temporal or matched-reference evidence. Evidence:
  `docs/artifacts/2026-08-25/g5-fountain-visual-warping.md`.
