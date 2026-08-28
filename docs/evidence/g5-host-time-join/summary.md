# PERF-126/127 retained evidence summary

Date: 2026-08-28

Verdict: **ordinary on-glass cadence passes; strict G5 remains open**

- PERF-126 adds an absolute host timestamp only to the opt-in phase CSV and
  joins 6,856 phase rows to the external Display trace.
- Seven pre-results queued surfaces were not displayed in about 110 seconds,
  matching the 6.6 holds predicted by 59.94 Hz guest output on this fixed
  60.0 Hz M1 panel. Their GPU work completed before the next VSync.
- Separate no-queue gaps contain real producer stalls and predominantly
  off-core wall time; they are not static-recompiler saturation.
- PERF-127 removes phase logging entirely and still records 16 ordinary
  33.333 ms holds plus one 399.993 ms result transition. p95/p99 remain
  16.666417/16.666458 ms.
- PERF-127 has 6,871 queued versus 6,863 displayed swaps. Eight queued surfaces
  are not displayed, confirming fixed-rate conversion is independent of the
  diagnostic logger.
- PERF-128's host-only Metal control produces exactly six 33.333 ms holds over
  6,600 intervals when paced at 16.683 ms, while its unpaced 60 Hz baseline is
  120/120 compliant. This closes the 59.94-to-60 conversion attribution.

Details and hashes:
`docs/artifacts/2026-08-28/g5-host-time-join-and-logger-free-cadence.md`.
