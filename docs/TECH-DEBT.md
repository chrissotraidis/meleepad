# ssbmpad technical debt

Last updated: 2026-09-01

This is the short, ranked engineering queue behind the active goal loop. It is
not a substitute for `GOAL-LOOP.md` or evidence in `docs/artifacts/`.

## P0 — G8 row 7: prove the complete iPad route honestly at 60 FPS

### 1. Prove the retained architecture over the complete route

The synchronized CPU/video candidate plus iOS duplicate-XFB presentation now
has enough measured ceiling. The formerly frozen moving transition advances,
and the exact Fountain combat screen reports 59.9 FPS. Its final ten seconds
measure 16.684733 ms mean, 17.150292 ms p95, 18.065917 ms p99, and 20.715625 ms
worst.

The follow-up minute holds 3,597 frames at 16.683199 ms mean (59.9405 FPS).
That is sufficient evidence that another speculative static-code rewrite is
not the next step. The remaining proof is product-facing, not a missing 2.7x
optimization.

This changes the problem from a 2.7x throughput deficit to proof and cleanup.
Run a longer uninterrupted exact-Fountain capture, then two complete cold
routes and one ordinary manual five-minute route. Retain FPS/VPS, pixels,
controls, audio-underrun deltas, results, return, lifecycle, FIFO diagnostics,
and a coherent frame. Do not substitute the short diagnostic run for that
acceptance sequence.

### 2. Rendering correctness

Fountain's lower reflection/geometry remains malformed at 59.9 FPS, and earlier
runs showed character morphology. Fast corrupted output is a failure. Locate
the earliest divergent frame and attribute it to FIFO ordering, XFB/EFB state,
generated semantics, or Metal translation. The duplicate-XFB policy is retained
only if this investigation does not tie it to new corruption.

### 3. Residual frame tails

The minute-long combat mean is the 59.94 Hz cadence, but p95/p99 remain
17.437/18.697 ms and one 71.070 ms wall outlier occurs. That outlier contains
only 11.870 ms of CPU-thread execution, no pipeline work, and no visible FPS
collapse. Repeat recorder-free and on hardware before changing the emulator.
Optimize only repeatable CPU-heavy clusters that produce visible/VPS loss; do
not chase compensated host-scheduler jitter while rendered cadence remains
59.9-60.0 FPS.

### 4. Duplicate-XFB regression coverage

The product correction is iOS-only
`GFX_HACK_SKIP_DUPLICATE_XFBS=false`. Default-off boundary counters proved the
control discarded 100 of 101 stable-identity XFB updates, while the candidate
presented advancing pixels. Preserve a focused source/config regression and
repeat one transition video after future Dolphin updates so upstream duplicate
detection changes cannot silently restore the freeze.

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
