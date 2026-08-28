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

G5 remains open. The prewarm closes a reproducible 110-ms hitch, but the
full-match Fountain p95/worst gate still requires a fresh prewarmed run and the
natural runnable-descheduling tail remains outside the recompiled on-core path.

## Implementation

- `patches/moderngekko-dolphin/0020-efb-vram-prewarm.patch` adds default-
  dormant UID logging and opt-in prewarm of R4, RGBA8, and XFB.
- `apple/macos/SsbmPad` enables the bounded prewarm in the packaged product.
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

Retain the bounded EFB prewarm and diagnostic sampler. Do not claim G5, a
Game Mode performance win, or an M1-specific defect. Do not return to compiler
flags, QoS, time constraints, timer variants, or drawable mutation. The next
single experiment is a full true-native frontend-PGO Fountain combat run from
the packaged prewarm path, observed only by the lightweight external sampler.
If its exact compile hitches stay absent, use the remaining natural marker to
quantify scheduler pressure without Instruments in the measurement window.

Decisive retained numbers and source-file hashes are in
`docs/evidence/g5-scheduler-and-efb-prewarm/summary.md`.
