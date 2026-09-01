# ssbmpad technical debt

Last updated: 2026-09-01

This is the short, ranked engineering queue behind the active goal loop. It is
not a substitute for `GOAL-LOOP.md` or evidence in `docs/artifacts/`.

## P0 — G8 row 7: prove the complete iPad route honestly at 60 FPS

### 1. Cross the Big Blue full-load ceiling

The ordinary cold product now supplies the controlling failure that the exact
one-on-one route did not. A hands-off four-fighter Big Blue attract match falls from
59.9-60.0 FPS to sustained 31.8-32.3 FPS, reaches 21.1 FPS, drives the CPU
thread to 96-99.7%, and raises DMA underruns from 0 to 447. The visible labels
show 31.6 and about 24.9 FPS. This supersedes the stale conclusion that only
ordinary acceptance remained.

Minimal follow-up attribution measures about 8.11 million guest cycles and
416,000 native dispatches per presented attract row. CPU work is roughly
29-41 ms while Metal present is about 0.05 ms. The workload is the full
486 MHz / 60 Hz GameCube frame budget; the current static core therefore needs
roughly twice the allowed host time. Target speed remains possible in
principle, but requires a roughly 50% or greater CPU-thread reduction, not
another isolated five-percent tweak.

Visual extraction and controlled factorials narrow this further. Four-player
Hyrule Temple holds 59.9 FPS under the same HEVC recorder. Controlled
one-on-one Big Blue holds 59.9 FPS, generic four-player Big Blue sustains
55.6-57.8 FPS, and the exact Ness/Peach/Ice Climbers/Bowser Big Blue match
again holds 59.9 FPS without loggers. Recording, stage geometry, four players,
and the exact roster/AI together are all insufficient causes. The residual is
attract/demo state itself. See
`docs/artifacts/2026-09-01/g8-attract-only-dispatch-delta.md`.

The remaining credible in-scope route is region-resident generated C:
single-entry regions keep guest GPR/FPR/paired state live across internal
control flow while the canonical arbitrary-entry path remains available for
uncommon entries, helpers, exceptions, cycle exits, and SMC invalidation. The
stock LLVM backend is closed: its exact equivalent slice is 6.12 times larger
and 4.84-4.93 times slower than C. Small interrupt, direct-call, PGO, layout,
and one-function register-cache candidates cannot supply the gap.

Before another product module, build a representative data-free region-state
corpus. It must pass full state/RAM/cycle/exception equivalence, improve the
selected work by at least 35%, project at least 25% whole-frame CPU gain from
measured host time, remain neutral on the passing controlled route, and retain
a credible path to the roughly 50% total reduction. If it cannot, record that
this no-JIT static-C architecture cannot guarantee worst-case 60 FPS on the M1
Simulator host instead of cycling compiler flags.

The fixed-phase attract-minus-controlled corpus is rejected. Identical
interval-4,093 state replays at offsets zero and 137 match cycles and dispatches
within 0.01%, yet their normalized 16 KiB distributions differ by 6.2% total
variation. Individual regions move by 1.2-2.4 percentage points. Do not select
generated regions from PERF-277's apparent 98.1% concentration.

Do not treat the exact-roster pass as evidence that only cold resources remain:
the ordinary attract interval is sustained, executes the full 8.11-million-
cycle budget, and carries a repeatable 2.24x sampled-dispatch rate. The current
decision is whether live sequence-only DVD/load and interrupt work is a
cycle-preserving event poll that can be fast-forwarded safely. Only if that is
refuted should a multi-offset aggregate select region-resident code.

The exact roster factorial is complete. Its no-logger live arm holds 59.9 FPS;
its matched diagnostic arm averages 5.81 million cycles and 177,500
dispatches. The attract arm's roughly 8.11 million cycles and 416,000
dispatches are therefore attract-specific. A later live attract battle reaches
36.2 FPS with 33.389 ms mean CPU time across 587 rows at or above 30 ms; p95
work reaches 8.121 million cycles and 421,882 dispatches. The same saved state
replays near 58-60 FPS with only 5.883 million cycles and 227,800 dispatches.
The immediate debt is a present-aligned consecutive-edge trace of the live
slow interval, proving the repeated load/status value and external exit event
before any cycle-preserving polling fast-forward.

### 2. Complete the exact ordinary acceptance route

After the architecture gate produces a viable product candidate, run two
complete cold routes and one unchanged-build ordinary manual five-minute
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
