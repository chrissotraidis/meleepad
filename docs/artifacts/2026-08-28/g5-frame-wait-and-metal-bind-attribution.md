# G5 frame-wait and Metal drawable attribution

Date: 2026-08-28

Status: **`nextDrawable` BACKPRESSURE LOCALIZED; G5 OPEN**

## Question

PERF-089 proved that the retained frontend-PGO module's CPU-thread work fits
the 16.7 ms budget in the deterministic Fountain combat window, while CPU wall
time remains several milliseconds higher. Is that gap precision-timer
residency, OS descheduling, ordinary presenter work, or Metal drawable
acquisition?

## Measurement controls

All retained comparisons below use one signed native arm64 runner, the same
frontend-PGO module, Metal, Cubeb, the isolated retained Fountain savestate,
and emulated frames `48123..48562`. Each selected window has 440 rows and
exactly:

- 1,501,629,399 charged guest cycles;
- 51,369,928 native dispatches;
- 905,572 static-recompiler bursts;
- zero interpreter fallback steps; and
- 882 hook fallback instructions.

The module SHA-256 is
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
No Simulator was booted and only one game process existed during each run.

## Heavy-profiler boundary

An exact-window Instruments System Trace could not be saved while the data
volume was nearly full; the invalid trace and its exact newly-created raw
ktrace were removed. A short `sample(1)` capture suspended the observed thread
enough to manufacture apparent `PrecisionTimer::SleepUntil` residency and is
not accepted as causal evidence.

A disposable `proc_pidinfo` sampler did establish that the hottest thread is
`CPU-GPU thread`. Across one exact 12-second replay it observed 9,155 running,
6,647 waiting, and two uninterruptible samples out of 15,804, with 6.861 CPU
seconds. This justified direct in-process phase counters rather than another
observer-heavy stack sample.

## PERF-090: precision timer excluded

`PrecisionTimer::SleepUntil` now reports coarse-sleep and final-spin duration,
and `CoreTimingManager` attributes calls to ordinary throttling or presentation.
The default-dormant regression
`scripts/g5_precision_timer_timing_preflight.cpp` proves origin-specific and
Metal subphase counter deltas.

Exact-window phase CSV:

- path: `/private/tmp/ssbmpad-perf090-precision-run.ykmFOK/perf090-precision.phase.csv`
- SHA-256: `fb5329dec09db1848ac73fd90bddc1121b604e0b67b7e9df047707c79315b1b2`
- runner-log SHA-256:
  `1e8300c4743fbf05006ad4866e225063068b838bdeeed4f0c079c4922925051b`

The precision timer consumes only 0.000372 ms/frame mean, 0.000541 ms p95,
and 0.000834 ms worst. Its correlation with CPU-wall-minus-thread is -0.065.
It is not the approximately 4.87 ms mean gap.

One cold EFB compile at emulated frame 48436 costs 113.828 ms and explains the
132.349 ms worst frame only. Excluding that row, video-build time correlates
0.564 with the wall/thread gap and gap minus video averages -0.083 ms. This
redirected the next measurement into the presenter.

## PERF-091: native-resolution correction, not a speed fix

The authoritative isolated user tree had drifted to
`InternalResolution = 3`. The G5 contract is native 640x528, represented by
`InternalResolution = 1`. A private clone changed only that setting; the slot-1
save SHA-256 remained
`e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
The source tree, ROM, retained 3x user tree, and save were not modified.

| Metric | Native 1x | Warm reversal 3x |
|---|---:|---:|
| total mean | 16.663 ms | 16.701 ms |
| total p95 | 17.856 ms | 17.852 ms |
| total worst | 23.430 ms | 33.931 ms |
| CPU-thread p95 | 12.673 ms | 12.609 ms |
| video-build p95 | 5.562 ms | 6.005 ms |
| rows <=16.7 ms | 236/440 | 250/440 |

Native resolution is the required gate baseline, but the reversal does not
support resolution as the performance fix. Continue G5 at 1x and do not claim
the 3x-to-1x correction closes the tail.

Native CSV SHA-256:
`8a227d3e02a9777a42ea247ff05fd441997cea28332e37195e0e945d70ce28b0`.
Warm 3x reversal CSV SHA-256:
`b54807a57eb84014e2367c1eda127887be99f9e6a38237ea46ba91524a6caae5`.

## PERF-092: presenter localization

Direct counters split presenter construction into flush/rectangle,
`BindBackbuffer`, XFB blit, and onscreen UI. On the native exact window,
`BindBackbuffer` averages 4.676 ms and accounts for 99.7% of the 4.690 ms
video-build mean. Flush/rectangle, XFB, and UI average only 0.001, 0.004, and
0.009 ms.

- CSV:
  `/private/tmp/ssbmpad-perf092-present-phases.qjwRcr/perf092-present-phases.csv`
- CSV SHA-256:
  `293f2d1cab3b4f1c035c0077bf5fffa3ca85a5ea37ad311c0ab9701144822e84`
- runner-log SHA-256:
  `b8b6f9ca2dbc41a20a984712bd3ade9f88f7f0f7433f5fb7133a70fc7c02c2e8`

## PERF-093: direct Metal result

The final split times surface checks, `[CAMetalLayer nextDrawable]`, backbuffer
texture update, and framebuffer setup directly inside Metal
`BindBackbuffer`.

| Metric | Mean | p95 | Worst |
|---|---:|---:|---:|
| total frame | 16.665 ms | 17.756 ms | 20.842 ms |
| CPU wall | 16.298 ms | 17.423 ms | 20.461 ms |
| CPU thread | 11.544 ms | 12.654 ms | 15.782 ms |
| video build | 4.817 ms | 5.773 ms | 6.622 ms |
| `BindBackbuffer` | 4.803 ms | 5.760 ms | 6.608 ms |
| surface checks | 0.000033 ms | 0.000083 ms | 0.000209 ms |
| `nextDrawable` | 4.784 ms | 5.737 ms | 6.585 ms |
| backbuffer update | 0.001095 ms | 0.001667 ms | 0.008375 ms |
| framebuffer setup | 0.017724 ms | 0.031000 ms | 0.090584 ms |

`nextDrawable` accounts for 99.600% of `BindBackbuffer`. Every CPU-thread row
meets 16.7 ms, but only 243/440 CPU-side total rows do. Precision-timer work,
rendering resolution, EFB compilation, XFB drawing, UI drawing, framebuffer
setup, and the on-core static module are excluded as the source of this
CPU-side gap. The gap is Core Animation drawable-pool backpressure. It is not
by itself proof of an onscreen missed refresh: retained stripped-product
`MTLDrawable.presentedTime` evidence already showed synchronized exact windows
at 440/440 compliant while display pacing moved into Metal.

- CSV:
  `/private/tmp/ssbmpad-perf093-metal-bind.XRHlCJ/perf093-metal-bind.csv`
- CSV SHA-256:
  `7da757261dc7559bc3b7f4ce7153df4fdc6c2e7bc0cef3ccbd3e478f8e2cfebb`
- runner-log SHA-256:
  `ec89c50877c57fa9d7d5be6dc4bcadae12a43624847d91aae4fd751d2a771e89`

## Decision and next experiment

Retain frontend PGO and native resolution. Do not retry compiler flags, source
weights, timer variants, EFB prewarming, or resolution changes. Canonical patch
`0019-frame-wait-attribution.patch` keeps all new counters dormant unless the
phase log is enabled.

The lifecycle audit confirms that the existing scheduled handler retains each
drawable until the command buffer is scheduled, then presents it. Direct
`PresentDrawable`, VSync, scheduled-duration presentation, and fullscreen were
already rejected and must not be repeated merely because the wait is now
localized.

PERF-094/095 attempted to join `presentedTime` to these exact counters. Moving
`addPresentedHandler` from pre-scheduling to the existing scheduled handler
did not make it observational: all three completed joined runs changed the
selected workload from 1,501,629,399 cycles / 51,369,928 dispatches to
3,567,157,795-3,567,157,803 cycles / 59,374,684-59,374,688 dispatches and
collapsed `nextDrawable` from 4.784 ms to 0.018-0.023 ms mean. The logger
changes queue behavior and is rejected; none of its actual-interval results is
acceptance evidence. Its code was removed.

Retain PERF-093 as CPU-side backpressure attribution and PERF-069's stripped
actual-presentation comparisons as the onscreen authority. The next G5 step
must target the remaining rare pre-acquisition full-match stalls or obtain a
non-perturbing actual-presentation observer. Do not mutate drawable lifecycle
or claim that removing the measured wait would improve onscreen cadence. G5
remains open; Final Destination and G6 remain blocked.
