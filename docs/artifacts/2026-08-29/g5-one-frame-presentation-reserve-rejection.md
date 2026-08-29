# G5 one-frame presentation-reserve rejection

Date: 2026-08-29

Status: **HOST RESERVE DOES NOT IMPROVE ACTUAL CADENCE; PRODUCT CHANGE REJECTED**

## Question

Can a bounded host-only queue hold one distinct completed game frame ahead of
presentation, absorb the retained off-core producer tail, and improve visible
cadence without changing emulated VI, input, audio, or netplay timing?

## Retained-trace model

The exact 1,092 complete points forming PERF-152's retained 1,091 Fountain
combat intervals were replayed as producer completion timestamps. The source
CSV SHA-256 remains
`0db90c49552c0cd54345a68c81cb19fd3c0d93283bc95579d6169e469f3a8010`.

At a 60 Hz consumer cadence, an initial one-frame lead consumed 1,091 distinct
frames with zero underflows. Queue depth reached two immediately before a
consume, meaning the current frame plus one reserve was sufficient for this
trace, including its 24.617583 ms wall interval. This was only a plausibility
screen: it did not include Metal drawable behavior, resize, UI, screenshots,
or shutdown.

## Source boundary

The current presenter calls `BindBackbuffer`, which synchronously acquires
`CAMetalLayer.nextDrawable`, renders the XFB and UI into that drawable, then
calls `PresentBackbuffer`. Metal appends presentation to the existing global
render command buffer and commits it through `StateTracker::FlushEncoders`.

A real reserve would therefore require an offscreen backbuffer plus a separate
consumer command queue/thread. The global Dolphin `StateTracker` is mutable and
not a cross-thread presentation API, so a candidate would also need an isolated
Metal blit path and explicit resize, surface-change, screenshot, UI, GPU
completion, and shutdown ownership. This is not a harmless queue-size toggle.

## Two-thread Metal preflight

A disposable host-only Objective-C++ harness tested that architecture without
Dolphin or game data. Its producer rendered numbered, distinct 64x64 private
textures at the exact `60000/1001` source cadence. A separate consumer copied
textures to a display-synchronized three-drawable `CAMetalLayer`. The run
injected one 8 ms producer delay and compared queue capacities one and two.
It never reused a frame and asserted sequential indices.

An initial condition-variable notification bug deadlocked before measurement;
the process was stopped, the missing notification was fixed, and that attempt
is excluded. The corrected harness source SHA-256 was
`2483570ff7b9ebef98def5ba44241618142459af97d4b39354236d41ef61af31`.

The optimized 360-frame run reported:

```text
capacity 1: submitted=360 underflows=0 sequence_errors=0 max_queue=1
            zero_presented=1 latency_p95=15.017317 ms latency_worst=16.741666 ms
            presented_p95=16.667000 ms presented_worst=33.333917 ms
capacity 2: submitted=360 underflows=0 sequence_errors=0 max_queue=2
            zero_presented=0 latency_p95=22.417750 ms latency_worst=23.379750 ms
            presented_p95=16.667000 ms presented_worst=33.333875 ms
```

The first sanitizer launch was excluded because LeakSanitizer is unsupported
on this platform. Re-running the same ASan/UBSan binary with leak detection
disabled produced no sanitizer diagnostic and reported over 600 frames:

```text
capacity 1: submitted=600 underflows=0 sequence_errors=0 max_queue=1
            zero_presented=1 latency_p95=18.535704 ms latency_worst=19.035250 ms
            presented_p95=16.667000 ms presented_worst=33.333875 ms
capacity 2: submitted=600 underflows=0 sequence_errors=0 max_queue=2
            zero_presented=0 latency_p95=19.127226 ms latency_worst=19.970834 ms
            presented_p95=16.667000 ms presented_worst=33.333792 ms
```

The capacity-one path already absorbed the injected producer delay because the
Metal drawable pipeline supplied its own buffering/backpressure. Adding a
second retained frame did not improve actual presentation worst-case and made
frames older at submission. The isolated zero `presentedTime` in each
capacity-one run is also consistent with the already-proven fixed 59.94-to-60
selection boundary; it is not evidence that another application queue creates
new distinct source frames.

## Decision and reversal

**Reject the one-frame Dolphin presentation reserve.** It duplicates buffering
already present below Dolphin, adds latency and lifecycle complexity, and does
not improve the actual display tail in the host control. Do not add an
offscreen backbuffer/presentation thread, count stale duplicates as new frames,
or reopen drawable scheduling from this evidence.

The disposable source was removed. No Dolphin, module, runner, ROM, save,
configuration, app, or Simulator state changed. G5 remains open on the genuine
observer-free producer tail; G6 remains blocked.
