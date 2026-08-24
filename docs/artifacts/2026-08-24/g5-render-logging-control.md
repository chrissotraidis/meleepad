# G5 render-logging control

Date: 2026-08-24

## Question

Were the recurring approximately 1.3-second frames evidence of a product
runtime hitch, or was the measurement/evidence workflow perturbing the game?

## Measurement correction

Dolphin's `PerformanceTracker::LogRenderTimeToFile` wrote every frame with
`std::endl`, forcing a stream flush on every presented frame. The retained
dependency patch replaces that flush with a buffered newline; the stream still
flushes when it closes. The correction is reproducible through
`patches/moderngekko-dolphin/0002-buffer-render-time-logging.patch` and
`scripts/bootstrap-dependencies.sh`.

The native arm64 runner was rebuilt and installed into the signed app without
changing the clean O2 + ThinLTO GALE01 module. The module remained SHA-256
`5bbd12e0704d6ce2221603d3fc016eb9aba88756b88d2139809c8b6ee1b09b82`.

## Control

The run used Metal, 640x528 internal resolution, Cubeb audio, the FIFO
controller, Yoshi versus level-1 CPU Ice Climbers, and Fountain of Dreams. The
matchup, stage, active combat, and completed results were visually verified.
No screenshot, sample, or GUI action occurred during the selected controller-
only interval. Its endpoints are the frames immediately after the active-
combat visual checkpoint and before the later match/results event.

The first 90 seconds of that interval contain 4,948 frames:

| Metric | Buffered clean control |
|---|---:|
| Mean | 18.187197 ms |
| Median | 17.903042 ms |
| p95 | 21.168417 ms |
| p99 | 21.998833 ms |
| Worst | 55.134917 ms |
| Frames <=16.7 ms | 662 (13.38%) |
| Frames >40 ms | 1 |

Raw evidence:

- `g5-buffered-clean-yoshi-ice-fountain-90s-render-times.txt` — SHA-256
  `1402c6c808814de8546379805af3b3fa499d825d75d38ad1c561f17b7309fba9`

The full exploratory log deliberately included the visual checkpoints. Its
multi-second outliers occurred around those checkpoints, including a
1387.878 ms frame shortly before shutdown when the results evidence was
captured. Those frames are not valid gameplay-performance evidence.

## Decision

**Retain the logger correction.** The controller-only control did not reproduce
the approximately 1.3-second hitch. Prior worst-frame conclusions that mixed
screen capture or per-frame stream flushing into the trace are invalid and
must be rerun. G5 remains open because the valid Fountain interval still
misses 16.7 ms at median and p95, and Final Destination is still unmeasured.

The next experiment is a matched buffered clean-versus-PGO Fountain pair with
no visual capture inside either measured interval.
