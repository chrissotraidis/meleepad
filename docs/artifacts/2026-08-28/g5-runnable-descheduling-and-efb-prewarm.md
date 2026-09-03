# G5 runnable descheduling and cold EFB prewarm

## Outcome

This step separates two independent sources of long frames and retains one
bounded product correction:

1. Natural severe Fountain stalls are runnable-thread descheduling on the
   loaded M1 host. PERF-104 measures a 52.940 ms wall/thread gap while the
   emulation thread remains runnable. PERF-105's marker-aligned System Trace
   shows the gap fragmented among higher-priority host work, with profiler
   attribution treated cautiously.
2. The deterministic frame-48436 stalls in three fresh bundles are not
   scheduler stalls or static-recompiler work. Each is a cold Metal compile of
   the same XFB EFB-to-VRAM shader. UID logging also finds startup R4 and later
   RGBA8 cold variants. Precompiling these three exact existing UIDs removes
   both observed combat compiles; frame 48436 becomes 17.234 ms.

G5 remains open. PERF-112's fresh prewarmed full match measures 16.682 ms mean,
17.584 ms p95, 18.540 ms p99, and 48.962 ms worst across 6,723 combat frames.
Four frames exceed 33 ms. The first captured 41.385 ms frame has a 25.619 ms
wall/thread gap and 14.809 ms inside the final `PresentBackbuffer` region while
the sampler continues to report the thread runnable. The natural scheduling/
queue tail remains outside the recompiled on-core path.

## Implementation

- `patches/moderngekko-dolphin/0020-efb-vram-prewarm.patch` adds default-
  dormant UID logging and opt-in prewarm of R4, RGBA8, XFB, and half-scale XFB.
- `apple/macos/MeleePad` enables the bounded prewarm in the packaged product.
- `apple/macos/Info.plist` declares the app's games category and current
  `LSSupportsGameMode` eligibility key. A three-bundle screen did not prove a
  causal Game Mode performance benefit.
- `scripts/g5_triggered_thread_sampler.cpp` retains the lightweight rolling
  thread-state trigger used by PERF-104.
- `scripts/test-macos-package-layout.sh` prevents the product wrapper, Game
  Mode keys, or runner prewarm implementation from disappearing silently.

The canonical patch applies and reverses cleanly against the pinned Dolphin
tree. A fresh signed disposable app passed the package-layout test and strict
code-sign verification.

## Decision

PERF-112 found the fourth half-scale XFB UID compiling once for 1.036 ms at
frame 51484; it did not cause a severe frame. PERF-113 extends the set to four
and records exactly those four UIDs at startup, zero combat EFB misses through
frame 51604, and 17.480 ms at frame 51484. Retain the bounded prewarm and
diagnostic sampler. Do not claim G5, a Game Mode win, or an M1-specific defect.
The next experiment is a prewarmed Game Mode on/off reversal through
LaunchServices, without the former cold-compile confound.

Decisive retained numbers and source-file hashes are in
`docs/evidence/g5-scheduler-and-efb-prewarm/summary.md`.
