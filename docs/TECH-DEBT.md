# ssbmpad technical debt

Last updated: 2026-09-01

This is the short, ranked engineering queue behind the active goal loop. It is
not a substitute for `GOAL-LOOP.md` or evidence in `docs/artifacts/`.

## P0 — G8 row 7: prove the complete iPad route honestly at 60 FPS

### 1. Clear the exact cold load failure

The synchronized CPU/video candidate plus iOS duplicate-XFB presentation now
has enough measured ceiling. The formerly frozen moving transition advances,
and the exact Fountain combat screen reports 59.9 FPS. Its final ten seconds
measure 16.684733 ms mean, 17.150292 ms p95, 18.065917 ms p99, and 20.715625 ms
worst.

The follow-up minute holds 3,597 frames at 16.683199 ms mean (59.9405 FPS).
That is sufficient evidence that another speculative static-code rewrite is
not the next step. The remaining proof is product-facing, not a missing 2.7x
optimization.

The first post-fix ordinary installed-app route directly reverses the former
49-52 FPS XFB freeze, but one moving interval still reaches 55.6 FPS / 55.3
VPS / 0.863 speed. Raising the bounded SyncGPU lead from 200,000 to 1,000,000
guest ticks then removes three matched 57-59 FPS control windows and reduces
transition underruns from 11 to 2 without a crash or visual regression.

The unchanged exact cold route still reports 57.5 then 53.5 FPS/VPS during
load. The first ten seconds create 93 pipelines (80.735 ms total) while the CPU
thread averages 9.199 ms. The following 591-frame interval creates only 16
pipelines (13.107 ms), but CPU-thread execution rises to 16.224 ms with 8.11
million guest cycles and 523,000 native dispatches per frame; Metal present is
only 0.122 ms. Profile exactly emulated frames 3,124-3,714 and rank guest PCs
and host call paths. Change code only if one safe path predicts at least a
five-percent interval reduction. Do not conflate this on-core load with the
preceding pipeline burst or resume broad recompiler work.

A dispatch-sampled repeat does not reproduce the deficit: it holds
59.9-60.0 FPS/VPS and the same numeric phase range falls from 16.224 to 12.197
ms CPU-thread time, 8.11 to 4.43 million static cycles, 523,000 to 206,000
dispatches, and 3,925 to 1,502 Mach syscalls per row. Its PCs form a broad
DVD/state/resource cluster and none exceeds 5.75%. Before profiling another
function, reproduce the failed state twice from fresh processes without
deleting game data or saves and align by state-driven route event plus host
time. Treat the controlling variable as cold process/cache state until that
reversal identifies it; do not infer a permanent gameplay ceiling from the
failed run or a permanent fix from the warm run.

A sampler-free exact repeat after rebooting the same Simulator also holds
59.7-60.0 FPS / 59.8-60.0 VPS. The formerly expensive range remains near
11.37 ms CPU-thread time, 4.16 million static cycles, and 181,000 dispatches
per row. Simulator service state alone is not the trigger. Do not make another
performance-code change without a fresh ordinary failure. The active P0 task
is two ordinary cold installed-app routes on the unchanged build, followed by
the manual five-minute Fountain gate if both pass.

### 2. Complete the exact ordinary acceptance route

Run two complete cold routes and one unchanged-build ordinary manual five-minute
Samus/CPU-Kirby Fountain route. Retain opening, menu/CSS, load, combat, results,
return, controls, FPS/VPS, audio, lifecycle, and FIFO diagnostics. The visible
Classic route proves touch controls and gameplay can hold 59.9 FPS, but it does
not clear the exact manual anchor.

### 3. Cold-transition and resume audio

Sustained visible Classic combat holds the DMA-underrun counter flat while
running 59.9-60.0 FPS/VPS. Load adds one isolated underrun; background/resume
adds five before another flat twenty-second interval. Preserve the current
120 ms buffer and adaptive 15-granule target. Attribute the cold-transition
producer loss before changing permanent latency; do not repeat the rejected
larger-reserve experiment.

### 4. Residual frame tails

The minute-long combat mean is the 59.94 Hz cadence, but p95/p99 remain
17.437/18.697 ms and one 71.070 ms wall outlier occurs. That outlier contains
only 11.870 ms of CPU-thread execution, no pipeline work, and no visible FPS
collapse. Repeat recorder-free and on hardware before changing the emulator.
Optimize only repeatable CPU-heavy clusters that produce visible/VPS loss; do
not chase compensated host-scheduler jitter while rendered cadence remains
59.9-60.0 FPS.

### 5. Bound and regression-test CPU/video separation

iOS now uses synchronized CPU/video threads with a 1,000,000-tick maximum
distance, about 2.06 ms of guest time. Preserve that explicit bound, its source
contract, and the runtime log token. Reject any increase that fails the same
cold control/candidate/control, changes deterministic results, increases
underruns, or revives the old FIFO/crash behavior. Unconstrained dual-core
remains closed.

### 6. Visual and duplicate-XFB regression coverage

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
