# ssbmpad technical debt

Last updated: 2026-09-01

This is the short, ranked engineering queue behind the active goal loop. It is
not a substitute for `GOAL-LOOP.md` or evidence in `docs/artifacts/`.

## P0 — G8 row 7: prove the complete iPad route honestly at 60 FPS

### 1. Close acceptance after the controller-wait reversal

The primary iPad Simulator CPU collapse now has a measured cause and retained
product fix. A live 27.807 ms / 26.609 ms total/CPU interval spends about
434,000 native dispatches per frame in a deterministic raw-controller queue
wait. Melee repeatedly services callbacks while waiting for its periodic pad
alarm. This is host-busy waiting for emulated time, not Metal, fighter AI, DVD
throughput, generic M1 weakness, or a need to lower resolution.

Patch 0038 uses Dolphin's existing `CoreTiming::Idle()` only at the exact
caller-qualified boundary PC/LR `80019550/801A4064`. The LR guard matters
because the service routine is shared. The iOS GALE01 host enables the pair as
ordinary runtime configuration; there is no player-facing performance mode.

The same-sequence candidate/control reversal at emulated frames 7,500-9,500
reduces CPU-thread time 13.600 -> 9.529 ms (29.9%), native dispatches
380,751 -> 107,535 (71.8%), and charged busy-loop cycles 6.346M -> 3.116M
(50.9%) while maintaining target cadence and progressing visuals. The rebuilt
default product, with no diagnostic environment, measures 16.714 ms mean over
15,021 active rows, reports 59.6-60.2 FPS/VPS, and has no strict-slow cluster
longer than two frames. See
`docs/artifacts/2026-09-01/g8-caller-qualified-controller-wait-yield.md`.

The architecture question is therefore no longer the immediate P0. Do not
return to the phase-aliased five-region corpus, a broad resident-C rewrite,
compiler-flag sweeps, or host blame unless a fresh accepted product route
reproduces a different sustained CPU-heavy failure.

The remaining P0 is honest acceptance: run two complete fresh-process routes
and the unchanged-build manual five-minute Samus/CPU-Kirby Fountain route.
Retain moving opening, menus/CSS, load, active input, combat, results, return,
audio, lifecycle, coherent geometry, and 59.9-60.0 FPS/VPS. The current attract
soak proves the mechanism and target cadence, but does not substitute for the
manual control/results/lifecycle row.

The first post-yield exact route now clears the hardest parts: state-verified
Samus/level-1-Kirby Fountain, over five minutes of input, results, CSS return,
and background/resume all remain coherent at 59.9-60.0 FPS. Its final six
minutes contain zero CPU-heavy slow rows. One earlier ten-second interval still
reports 56.7 VPS because of isolated 136/391 ms off-core wall stalls with only
13/18 ms CPU time. Next repeat the ordinary product route without phase,
MemoryWatcher, or external-pipe observers. Do not tune the static core for this
single host-wait event unless it reproduces visibly. See
`docs/artifacts/2026-09-01/g8-first-post-yield-fountain-acceptance.md`.

### 2. Cold-transition and resume audio

Sustained visible Classic combat holds the DMA-underrun counter flat while
running 59.9-60.0 FPS/VPS. Load adds one isolated underrun; background/resume
adds five before another flat twenty-second interval. Preserve the current
120 ms buffer and adaptive 15-granule target. Attribute the cold-transition
producer loss before changing permanent latency; do not repeat the rejected
larger-reserve experiment.

### 3. Residual frame tails

The minute-long combat mean is the 59.94 Hz cadence, but p95/p99 remain
17.437/18.697 ms and one 71.070 ms wall outlier occurs. That outlier contains
only 11.870 ms of CPU-thread execution, no pipeline work, and no visible FPS
collapse. Repeat recorder-free and on hardware before changing the emulator.
Optimize only repeatable CPU-heavy clusters that produce visible/VPS loss; do
not chase compensated host-scheduler jitter while rendered cadence remains
59.9-60.0 FPS.

### 4. Bound and regression-test CPU/video separation

iOS now uses synchronized CPU/video threads with a 1,000,000-tick maximum
distance, about 2.06 ms of guest time. Preserve that explicit bound, its source
contract, and the runtime log token. Reject any increase that fails the same
cold control/candidate/control, changes deterministic results, increases
underruns, or revives the old FIFO/crash behavior. Unconstrained dual-core
remains closed.

### 5. Visual and duplicate-XFB regression coverage

The product correction is iOS-only
`GFX_HACK_SKIP_DUPLICATE_XFBS=false`. Default-off boundary counters proved the
control discarded 100 of 101 stable-identity XFB updates, while the candidate
presented advancing pixels. Preserve a focused source/config regression and
repeat one transition video after future Dolphin updates so upstream duplicate
detection changes cannot silently restore the freeze.

The blurred/blocky lower Fountain reflection is closed as official-Dolphin
reference parity. The separate real-mesh issue is closed by the retained
scalar-single/`frsp` correction and its 402.7-second, 2,110-frame corpus. Reopen
only on adjacent-frame evidence of actual fighter deformation; do not retry
EFB-to-RAM or non-deferred-copy controls for the reference reflection.

## P1 — cold pipeline behavior

A structurally valid 446-entry pipeline UID cache reduced matched runtime
pipeline creation from 10 / 16.96 ms to 3 / 2.43 ms, but did not improve total
pacing, added a 99.7 ms CPU-heavy hitch, and did not remove the visible
transition freeze. Do not bundle a game-derived seed. Forced termination also
leaves partial UID files whose sizes fail Dolphin's 8 + N*579 validation; keep
cache-integrity/lifecycle cleanup on the queue after row 7.

## P1 — acceptance and physical-device promotion

After the mechanisms above pass, row 7 still requires two complete fresh-process
cold routes and one unchanged-build ordinary manual five-minute Fountain run,
with moving opening, menus, CSS, loading, combat, results, return, controls,
audio, lifecycle, and coherent rendering retained. Only then test a physical
iPad. Simulator success is not device or release proof.

## P2 — G9 netplay

Host/Join and a synchronized two-instance match with at least one iPadOS
endpoint remain queued behind G8. Preserve deterministic CPU/GPU configuration
and diagnostic state in every row-7 change so performance work does not make
netplay harder later.

## Closed directions — do not repeat without new evidence

- lowering emulated CPU clock or exposing a performance mode;
- generic M1/thermal/resource exhaustion;
- FastDisc or file preload;
- shader/pipeline seeding as the general freeze fix;
- QoS, affinity, Game Mode, activity hints, or timer variants;
- broad ThinLTO/PGO/code-size changes without an exact binary preflight;
- interrupt-leaf/direct-call/guest-PC-store rewrites already below the five
  percent gate or live-regressed; and
- hiding failures by averaging phases, lowering resolution, or changing the
  FPS counter.
