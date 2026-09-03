# G5 task-event attribution

Date: 2026-08-28

Status: **WHOLE-PROCESS BLOCKING ACTIVITY REJECTED; HOST EXECUTION LOSS RETAINED**

## Question

Do Final Destination's remaining 12-25 ms wall-minus-thread gaps coincide
with extra blocking/system activity inside MeleePad, or does the whole app
receive less execution during the slow rows?

The supplied PERF-106 attachment was first reconciled as historical. Its
native ARM64 startup `SIGTRAP` is already closed by patch 0013 and the passing
PERF-123 signal-at-frame-zero regression. It adds no new crash work.

## Supported-interface audit

The current Apple SDK exposes no supported per-thread voluntary/involuntary
context-switch counter. `RUSAGE_THREAD` is not available on macOS, interval
workgroups are documented as audio-only, generic workgroups do not grant a
scheduling policy, and `CAMetalDisplayLink` is a drawable/presentation
callback rather than CPU-thread protection. Private APIs were not used.

Patch 0022 therefore extends the already default-dormant phase logger with
one supported `TASK_EVENTS_INFO` snapshot per presented frame. It records
whole-task context switches plus Mach and Unix syscall deltas only while
`MELEEPAD_FRAME_PHASE_LOG` is enabled. Non-Apple builds return zeros.

An initial per-CPU-slice placement compiled after replacing the unavailable
`RUSAGE_THREAD` selector, but PERF-138/139 exposed hundreds to thousands of
extra Mach queries per frame. Those timing distributions are invalid and are
excluded. The query was moved to `FramePhaseLogger::Log`, rebuilt, and the
canonical patch passed reverse/forward round-trip validation. A separate
100,000-call benchmark repeated three times at 0.658-0.672 microseconds mean,
0.708-0.709 microseconds p95, and 0.792-0.875 microseconds p99. One query per
frame cannot explain millisecond-scale tails.

## PERF-140 exact combat window

PERF-140 used one signed disposable app, the same retained current-PGO module
and Final Destination state, and balanced left/right input. Fresh visual
endpoints show coherent Final Destination combat from timer 1:32 to 0:46,
with recognizable Pikachu/Yoshi geometry, HUD, stage, and hit effects. The
final 2,001 rows are continuous emulated frames `31834..33834` wholly within
that verified interval.

| Metric | Mean | p95 | p99 | Worst | Correlation with off-core |
| --- | ---: | ---: | ---: | ---: | ---: |
| Total | 16.684369 ms | 18.717375 | 19.465708 | 21.867375 | 0.746603 |
| CPU wall | 16.560087 ms | 18.505130 | 19.200072 | 22.472539 | 0.718707 |
| CPU thread | 6.223618 ms | 7.852454 | 9.832510 | 16.567951 | -0.748336 |
| Wall minus CPU thread | 10.336469 ms | 13.199745 | 13.599291 | 14.588549 | 1.000000 |
| Task context switches | 47.357821 | 74 | 92 | 258 | -0.106177 |
| Task Mach syscalls | 2328.253373 | 5357 | 7238 | 11414 | -0.549928 |
| Task Unix syscalls | 1283.870065 | 1321 | 1369 | 1450 | -0.245431 |

Only 1,044/2,001 rows (52.174%) meet 16.7 ms; ten exceed 20 ms and none
exceeds 24 ms. This diagnostic run is not an acceptance pass and its timing
distribution does not supersede the logger-free PERF-135 baseline.

The useful result is directional. Compliant rows average 9.541436 ms
wall-minus-thread, 49.769 task context switches, 2,885.678 Mach syscalls, and
1,289.873 Unix syscalls. Misses average more off-core time (11.203778 ms) but
fewer context switches (44.727), fewer Mach syscalls (1,720.154), and slightly
fewer Unix syscalls (1,277.322). The 21.867 ms worst row has 11.770 ms
wall-minus-thread with only 45/46/1,295 context-switch/Mach/Unix events. Extra
system activity inside the process does not accompany the slow class; the app
does less whole-task work while wall time advances.

Private SHA-256:

- runner: `0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`
- module: `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`
- state: `19e5d7b8d66831f2e9032797dae2ef8399f8a6593e19a020d8cde8e176c8f181`
- phase: `4dd432f910ec3101ed7837ca94824aa5a5425fafedce21cda809cb593d826763`
- start image: `0d4559f208e5cad25f00dcea6a1356f81181c5935e2500ec23728741cbdd0749`
- end image: `30512327c889e0a9ec1b1987711c922d27d83c682efa46c55caaefce38dc2398`

No ROM, save, module, app, or private log is committed.

## Decision

PERF-140 strengthens the host-execution-loss attribution and rejects a hidden
whole-process blocking/syscall burst as the common cause. It does not identify
which external runnable source wins the CPU, so it does not justify another
compiler, timer, priority, workgroup, display-link, or renderer change.

The next falsifiable test remains a matched, reversible isolation of the
persistently busy Logitech updater, immediately resumed after the control.
That affects software outside the repo and still requires explicit authority.
Until then, do not blame Logitech or WindowServer. G5 remains open and G6
remains blocked.
