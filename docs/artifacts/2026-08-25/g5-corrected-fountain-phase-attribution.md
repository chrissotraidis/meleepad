# Corrected Fountain phase attribution

Date: 2026-08-25

Status: **G5 FAILS; VIDEO/PRESENT/AUDIO EXCLUDED AS THE DOMINANT TAIL**

## Context and identity

This run executes the next step selected after the independent stale-`ps1`
report. The report's scalar-single/`frsp` correctness actions were already
completed; it explicitly did not explain G5's remaining frame tail. This run
therefore attributes that tail before another behavior change.

- Exact corrected PGO module SHA-256:
  `524dd2df5a65ce36b16692350faac5f44ee42858e2771a92327711b5f3c06639`
- Generated-source identity suffix: `e02b042a2f09321f`
- Phase runner packaged SHA-256:
  `62343cd8096d2cfcc2375e7382d6948fbf73ccd64ac615421e48041d616c29e2`
- Backend/audio: Metal/Cubeb
- Isolated user directory: `/private/tmp/g5phase2.0UvtbJ`
- Full local phase log SHA-256:
  `4d2e8a407b12049264a8c4301691dd58880f414887a6c244144ea1b2e08f41ed`
- Retained trimmed CSV:
  `g5-corrected-fountain-phase.csv`, SHA-256
  `926f8017e8d3b45ab0a9d4a30d821fd62d3794053ebfd8d595f3da7b11d15a77`

No Simulator was booted.

## Visual route and clean bracket

The native window visibly passed the title and Character Select state barriers.
Stage Select explicitly highlighted `Fountain of Dreams`, then live Fountain
showed player-one Pikachu against CPU Pikachu at a 59.9 FPS title. No screen
capture or UI inspection occurred during the measured interval.

The controller ran `fountain-combat-cycle.json --repeat 20` from Unix time
`1787702969` through `1787703035`, a 66-second capture-free bracket. The phase
log grew from 15,313 to 19,236 lines during the bracket. To exclude transition
edges conservatively, the retained CSV discards 120 rows at each end and
contains frames 15,432 through 19,114 inclusive.

## Distribution

| Phase | Mean | Median | p95 | p99 | Worst |
|---|---:|---:|---:|---:|---:|
| Total | 16.683329 | 16.687083 | 17.015708 | 17.226911 | 18.985583 |
| CPU wall | 16.669349 | 16.673255 | 17.004282 | 17.201273 | 18.982820 |
| Derived compute | 10.458831 | 10.395369 | 11.599082 | 12.539627 | 18.009742 |
| Throttle sleep | 6.210518 | 6.284167 | 7.349954 | 7.730242 | 8.152084 |
| Video build | 0.054864 | 0.052958 | 0.077417 | 0.100802 | 0.160292 |
| Present | 0.023801 | 0.018083 | 0.051658 | 0.106411 | 0.271084 |
| Audio mix | 0.780416 | 0.790583 | 1.281158 | 1.317566 | 1.453167 |

`Derived compute = CPU wall - CPU idle - throttle sleep`; CPU idle is zero in
all 3,683 retained rows. Only 1,957 rows (53.136%) are at or below 16.7 ms.
There are no frames above 40 ms in this clean interval.

The two largest rows distinguish two mechanisms:

- frame 18,362: 18.985583 ms total, 12.677778 ms derived compute, and
  6.305042 ms throttle sleep;
- frame 17,149: 17.974708 ms total, 18.009742 ms derived compute, and
  0.000750 ms throttle sleep, a genuine compute overrun.

## Interpretation and next falsification

Video build, present, and audio are too small to dominate this tail. Most
frames still have several milliseconds of deliberate throttle sleep, while
the p99 tail combines modestly elevated compute with pacing variance. One
retained frame independently exceeds the budget in compute alone.

The current `cpu_throttle_sleep_ms` counter measures the duration spent inside
`SleepUntil`; it does not expose the requested deadline or wake-up lateness.
The smallest next step is therefore diagnostic-only: extend the default-off
phase logger with requested throttle duration and positive wake lateness, then
repeat this exact Fountain route. That measurement decides whether the next
one-variable behavior test belongs in deadline pacing or generated compute.
Do not change timer behavior, renderer, audio, PGO, or generated code before
that attribution. Final Destination follows only after a Fountain candidate
passes the complete strict distribution.

