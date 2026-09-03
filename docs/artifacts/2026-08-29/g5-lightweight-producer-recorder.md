# G5 lightweight producer recorder

Date: 2026-08-29

Status: **DEFAULT-DORMANT RECORDER RETAINED; COLD COMPUTE BURST AND WARM WALL TAIL SEPARATED; G5 OPEN**

## Question

Can the canonical runner retain an observer-light producer recorder that
distinguishes wall time from actual combined-thread CPU time without phase
counters, presentation callbacks, or per-frame file I/O? If so, does a cold
Fountain match miss the 16.7 ms producer budget because it is computing or
because it is not executing?

## Retained implementation and regression

Patch `0023-lightweight-frame-timing.patch` adds an opt-in recorder at
`PerformanceTracker::Count()`. It reuses Dolphin's existing steady-clock
timestamp and performs one `CLOCK_THREAD_CPUTIME_ID` read for each accepted
render interval. Records stay in a pre-reserved vector and are written once
during destruction to the exact path in `MELEEPAD_LIGHTWEIGHT_FRAME_LOG`.
Only the `render_times.txt` tracker can enable it.

The ordinary product does not set that environment variable. With it absent,
the recorder does not calibrate clocks, reserve memory, read the thread clock,
or create a file. `scripts/test_lightweight_frame_timing_patch.py` compiles the
actual helper extracted from the canonical patch. Its disabled case proves
zero fake-clock calls and no output; its opt-in case proves two calls for two
samples, no file before destruction, one flushed row, and exact wall/thread/
remainder values. The regression failed first because patch 0023 did not yet
exist, then passed after implementation. Repository checks now run it.

Validation:

- canonical Release `moderngekko-run` compiled and linked;
- all 26 scoped `moderngekko.*` tests passed;
- nine strict-classifier tests passed;
- the lightweight-recorder compile/behavior test passed;
- dependency bootstrap, repository checks, and `git diff --check` passed.

## Topology correction

The first completed Fountain trace is excluded from CPU interpretation. Its
isolated config accidentally retained `CPUThread = True`; Dolphin invokes
`CountFrame()` from `Renderer::Swap`, so the measured thread was the separate
GPU thread. Its approximately 2 ms median CPU time exposed the mismatch. The
valid run explicitly used `CPUThread = False`, where CPU and GPU execution
share the measured producer thread. The excluded run is not used below.

## Valid controlled run

The disposable signed app used:

- runner SHA-256
  `2133657a30d7ea7a484120a225b7b9a11c2bed64c821b455f9ecc744217a194e`;
- unchanged current-PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- native 640x528 scale, fullscreen Metal, configured Cubeb audio, EFB prewarm,
  `CPUThread = False`, one exact game process, and no booted Simulator;
- a pre-created private controller FIFO and MemoryWatcher locations;
- quiet `gcpipe.py` output redirected to `/dev/null`.

The watcher-gated in-match state began at Unix ns
`1788054178495341000` and ended at `1788054304335678000`. The first selected
record was a 1,873.181 ms interval that began before the boundary and crossed
stage loading, so it is excluded. The exact combat-only selection is recorder
rows 9,420 through 16,850, or 7,431 intervals.

The private recorder CSV has SHA-256
`ba19381d1e55897a376773f5541d108bbfdd776d2ad85deaadfb3fa33ab82dcb`.
The independent private `render_times.txt` has SHA-256
`ee8131c93ada35ac11c296b081afccd3a3c860733bc8b429c8bf58043818a073`.
All 22,240 recorder wall values match render rows 2 through 22,241 exactly,
with zero absolute difference. No private CSV, log, game data, or screenshot is
committed.

Fresh visual checks showed coherent Fountain selection and a completed results
screen. The run shut down normally, flushed 22,240 recorder rows once, and
left no game or Simulator running.

## Exact combat result

| Metric | Wall interval | Combined-thread CPU | Wall minus thread CPU |
| --- | ---: | ---: | ---: |
| Mean | 16.682591 ms | 11.546056 ms | 5.136541 ms |
| Median | 16.669667 ms | 11.078542 ms | 5.590625 ms |
| p95 | 16.840625 ms | 15.860750 ms | 6.727125 ms |
| p99 | 17.030246 ms | 16.801825 ms | 7.469734 ms |
| Worst | 39.496833 ms | 27.903625 ms | 23.724208 ms |

Wall mean is 59.942726 FPS. Only 4,757/7,431 intervals, or 64.015610%, meet
16.7 ms. There are 2,674 wall misses above 16.7 ms, 92 above 17 ms, eight
above 20 ms, and two above 33 ms. Combined-thread CPU exceeds 16.7 ms in 104
intervals.

All 104 CPU overruns occur in the first ten seconds. That first bin includes
six wall intervals above 20 ms, a 39.496833 ms worst wall interval, and a
27.903625 ms worst CPU interval. From ten seconds onward, no combined-thread
CPU interval exceeds 16.7 ms, but the independent wall tail remains: a
33.251625 ms interval at about 40-50 seconds uses only 9.527417 ms CPU, and a
20.855458 ms interval at about 70-80 seconds uses 11.101583 ms CPU.

## Decision

**Fountain still fails G5.** The retained recorder exposes two causal classes
in one cold match:

1. a cold-combat combined-thread compute burst in the first ten seconds; and
2. a later wall/descheduling or presentation tail with CPU safely below the
   budget.

This does not prove the static-recompiled module alone owns the cold burst;
the measured thread also performs Dolphin CPU/GPU producer work. It does prove
that treating every producer miss as off-core is wrong for a cold match. The
next smallest falsifiable experiment is a second Fountain match in the same
process: disappearance of the first-ten-second CPU burst identifies one-time
warm-up, while recurrence identifies match-start work. Keep the recorder
default-dormant, do not begin Final Destination or G6, and do not reopen the
already rejected scheduler or presentation candidates.
