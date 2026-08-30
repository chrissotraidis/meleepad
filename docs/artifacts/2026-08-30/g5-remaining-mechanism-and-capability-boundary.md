# G5 remaining mechanism and capability boundary (PERF-214)

Date: 2026-08-30

Status: **PRODUCT-LOCAL MECHANISM INVENTORY EXHAUSTED; EXTERNAL 59.94/VRR DISPLAY CAPABILITY REQUIRED; G5 OPEN**

## Purpose

PERF-212 and PERF-213 closed the last unreviewed ARM64 dispatcher/frame flag
ideas below the retained 5% build threshold. This checkpoint reconciles the
current superseding evidence rather than selecting another historical “next
experiment” from an older artifact. It does not weaken PRD D2, pass G5, or
authorize G6.

PRD D2 requires the macOS worst-case frame interval to remain at or below
16.7 ms with audio throughout Final Destination and Fountain of Dreams. It is
not an average-FPS gate. Display-rate conversion is therefore not an excuse
for producer stalls, and a producer-only average is not completion.

## Current failure classes

### 1. Warm generated-code compute is not the common strict tail

PERF-207's observer-bearing warm Fountain body contains 6,731 frames. Its
combined CPU/GPU thread measures 12.273 ms mean and only one frame above
16.7 ms, while six wall intervals exceed 20 ms. The native-PC excess in the
rare compute rows is distributed across already-profiled 8033/8035/8036/8038
generated families; no new leaf owns a material share.

The current frontend profile begins only after verified warm Fountain combat,
covers the full match, and independently reproduces identical counts for its
enriched PCs. PGO refresh, IR PGO, sample PGO, order files, hot/cold splitting,
O3/native tuning, targeted replacements, local state retention, broad direct
calls, inline validity, and dispatcher ABI/frame changes all have direct
semantic or materiality rejections. The canonical module remains
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

This does not prove generated code is globally optimal. It proves that the
retained warm strict failure does not identify a new product-local static
recompiler change large enough to earn another build.

### 2. Warm Fountain's largest wall tails are drawable backpressure

PERF-207 maps the three 31.5-34.7 ms start-to-start tails to preceding
`CAMetalLayer.nextDrawable` waits of 16.9-21.8 ms. Thirty-one of 32 timed
semaphore samples inside the six wall tails share the complete
libdispatch -> QuartzCore -> `-[CAMetalLayer nextDrawable]` chain. Instrumented
emulated idle, throttle sleep, single-core FIFO synchronization, and guest CPU
work cannot explain those waits.

The product already acquires the drawable after independent presenter work,
uses the supported three-drawable maximum, releases its sole reference through
the scheduled command-buffer path, and satisfies Apple's opaque/RGB/
framebuffer-only/direct-to-display prerequisites. Two drawables, Rush present,
direct/scheduled/absolute present variants, display-sync changes, a one-frame
reserve, timeout/transaction changes, Metal 4 ordering, and frame generation
all have direct reversals or API-contract rejections.

### 3. Warm Final Destination is also wall-bound after warm-up

PERF-198's 5,890-frame warm Final Destination body has zero CPU rows above
16.7 ms, CPU worst 13.438 ms, and three wall intervals above 20 ms with a
26.498 ms worst. PERF-199 maps those producer stalls to vblank/host execution
loss with ordinary thread CPU, not static-core, GPU, audio, or EFB cost.

Game Mode is active. Pthread QoS, override QoS, fixed scheduling, fixed plus
QoS, timers, process activities, title updates, generic workgroups, and
interval workgroups have been measured or rejected by public contract. The
installed SDK still states that interval workgroups support only audio
workloads; generic workgroups grant no scheduling policy.

### 4. GPU-ready frames are deferred by fixed-rate conversion

PERF-150 contains 5,744 actual Fountain presentation intervals. For every one
of its nine 33.333 ms misses, the command buffer completed 10.3-30.7 ms before
the skipped refresh. GPU work is only 1.566 ms mean and 2.523 ms worst. A
separate Display trace observes the same two-refresh surface holds without an
in-process drawable callback.

Melee produces distinct frames at 59.94005994 Hz. The current M1 MacBook Air
built-in panel is fixed at 60.00 Hz. A controlled display-link harness proves
that an exact 60 Hz source can hit every refresh, while a 59.94005994 Hz source
necessarily has callbacks with no new source frame. Guest speed changes,
duplicating stale content as a “new” frame, and motion interpolation are not
valid D2 proofs; the latter also visibly smears retained Melee stress pairs.

Current `system_profiler SPDisplaysDataType` reports only the built-in Color
LCD at `1440 x 900 @ 60.00Hz`. The retained Quartz/IOKit audit reports no
59.94 mode and no variable-refresh range. No external display is connected.

### 5. Menus and vertex loading do not identify a separate material fix

The current coherent Main Menu/CSS controls sustain approximately 59.94 FPS
mean. Visible menu degradation consists of isolated pacing hitches and scene
transitions where many guest frames advance without an XFB presentation; the
1.85-3.23 second rows are aggregated scene-change work, not a continuous
12-15 FPS rendered state. Fast-disc and dispatch shortcuts do not remove them.

macOS already uses Dolphin's generated ARM64 vertex loader. The strongest
older verified Fountain sample attributes only nine samples to
`VertexLoaderManager::RunVertices`. PERF-207's six wall-tail frames contain two
`RunVertices` stack samples among 70 samples, but their combined-thread CPU is
within budget and the tail is dominated by drawable waiting. AOT vertex-format
specialization cannot meet the 5% product-build threshold on this evidence.

## Closed mechanism inventory

The following product-local categories now have direct current or retained
rejections:

- static recompiler: frontend/IR/sample PGO, compiler flags, ThinLTO/layout,
  helper/leaf replacements, direct linking, validity tables, merged/register
  state, dispatch ABI/frame traffic, and frame-pointer omission;
- renderer/GPU: EFB prewarm, shader/streaming attribution, drawable count and
  lifetime, presentation variants, reserve queues, Metal API migration, and
  interpolation;
- pacing/scheduler: precision timers, exact-rate speed adjustment, display
  links, QoS/overrides, fixed policy, Game Mode alternatives, process activity
  hints, and public workgroups;
- subsystem/external noise: audio buffer size, input streaming, title update,
  Spotlight logging side effect, and matched Logitech isolation; and
- PRD-ranked vertex specialization: measured below materiality on macOS.

“Closed” means do not repeat the same experiment without new causal evidence.
It does not claim that no implementation could ever be improved.

## Capability boundary and resumption condition

The current machine cannot falsify the fixed-panel conversion class under the
unchanged D2 semantics. The next required capability is a real macOS display
mode that is either:

1. fixed at the Melee source cadence (59.94 Hz), or
2. variable-refresh with a verified range containing 59.94005994 Hz.

That capability is **necessary, not sufficient**. On such a display, the
canonical app must repeat the same audio-on Final Destination and Fountain
matches with observer-light producer timing and actual-presentation evidence.
Any remaining interval above 16.7 ms would reopen only the named producer
class; it would not authorize broad compiler or renderer retries.

Alternative resumption requires genuinely new evidence naming a product-local
leaf or public API not covered above. Changing the hard requirement, counting
stale duplicates, using private scheduling/display-driver interfaces, or
starting iPadOS does not satisfy this boundary.

No ROM, save, generated game module, private trace, source, package, app,
runtime, or Simulator changed in this inventory. G5 remains unpassed and G6
remains blocked.
