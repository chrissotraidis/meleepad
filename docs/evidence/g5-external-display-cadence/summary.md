# PERF-117 through PERF-124 retained evidence summary

Date: 2026-08-28

Verdict: **G5 FAIL; startup diagnostic crash fixed**

- PERF-117 proved Instruments Display tables identify SsbmPad's actual
  onscreen surfaces.
- PERF-121 proved the minimal `SsbmPad Display Cadence` template captures the
  required tables without an in-process drawable callback.
- PERF-122 reproduced the supplied startup crash by requesting a state load at
  `emulated_frame=0` while Core was Starting.
- Canonical patch 0013 now leaves state requests pending until Core is Running
  or Paused.
- PERF-123 repeated the exact early signal after rebuilding: the process
  survived and consumed the deferred request after startup.
- PERF-124 retained 6,862 actual-display intervals across 114.964458 seconds:
  p95/p99 are 16.666417/16.666417 ms, but 15 intervals are 33.333 ms and one
  is 366.660 ms. Sixteen intervals exceed 16.7 ms, so Fountain does not pass.
- Exact combat frames 48123 through 54845 have zero EFB-to-VRAM pipeline
  misses. The remaining issue is rare cadence loss, not broad 12.5-FPS
  execution or cold EFB compilation.

Detailed method, interpretation, hashes, and local raw paths:
`docs/artifacts/2026-08-28/g5-external-display-cadence-and-savestate-startup.md`.
