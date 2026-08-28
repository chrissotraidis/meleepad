# G5 frontend-PGO wall-tail attribution

Date: 2026-08-28

Status: **PERF-089 PROVES THE STATIC-RECOMPILED CPU THREAD MEETS THE EXACT FOUNTAIN BUDGET; TOTAL-FRAME TAIL REMAINS; G5 OPEN**

## Question

Does the best retained frontend-PGO module still lose the strict Fountain
frame budget in generated CPU execution, or is the remaining tail outside
on-core statically recompiled work? Do synchronous EFB shader or pipeline
misses account for that tail?

## Exact equal-work replay

The retained frontend-PGO module was packaged with the PERF-088 instrumented
runner and strict-signed. The module SHA-256 is
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
the runner SHA-256 is
`b4c80e25fa6ae43b971f4915b08fa0b896944713d51bc41ad524347f4f1575c2`.

After the established startup delay and retained-state load, exact Fountain
frames `48123..48562` produced 440 rows with the same work as PERF-088:

- 1,501,757,755 guest cycles;
- 51,380,895 native dispatches;
- 905,756 static bursts; and
- 882 hook fallbacks.

| Metric | Result |
| --- | ---: |
| Total mean / median | 16.665712 / 16.656354 ms |
| Total p95 / p99 / worst | 18.255583 / 19.823000 / 25.517167 ms |
| Frames at or below 16.7 ms | 225 / 440 |
| CPU-wall mean / p95 / worst | 16.285053 / 17.857372 / 25.105812 ms |
| CPU-thread mean / p95 / worst | 11.675688 / 12.983682 / 16.283635 ms |
| CPU-thread frames at or below 16.7 ms | 440 / 440 |
| CPU throttle requested | 0.000000 ms on all 440 frames |
| CPU throttle sleep mean / worst | 0.000511 / 0.004751 ms |
| Video-build mean / p95 / worst | 4.598900 / 6.139417 / 7.423625 ms |
| Present mean / p95 / worst | 0.020436 / 0.044083 / 0.269291 ms |
| Audio mean / p95 / worst | 0.513431 / 0.900291 / 1.341375 ms |

The statically recompiled CPU thread therefore meets the 16.7 ms budget in
every selected frame. Total-frame p95 and worst still fail, so this is not a
G5 pass.

## EFB miss result

Exactly one selected frame had an EFB pipeline miss:

| Emulated frame | Total | CPU wall | CPU thread | Shader | Pipeline |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 48436 | 19.931292 ms | 19.426197 ms | 16.283635 ms | 1.243583 ms | 0.200958 ms |

Removing its 1.444541 ms compile time changes mean from 16.665712 to
16.662429 ms, but leaves p95 at 18.255583 ms and leaves all 215 frames above
16.7 ms above the threshold. EFB prewarming remains rejected as the strict
tail solution.

## Wall-minus-thread result

CPU wall minus CPU-thread time isolates intervals in which the emulation
thread was not accumulating on-core execution time:

| Statistic | Wall minus thread |
| --- | ---: |
| Mean / median | 4.609365 / 4.694253 ms |
| p95 / p99 | 6.179674 / 6.820023 ms |
| Worst | 12.630013 ms |

This is not the known Dolphin throttle path. The requested-sleep counter is
zero for every selected frame, measured throttle sleep is only 0.000511 ms
mean / 0.004751 ms worst, and its correlation with the wall/thread gap is
-0.056343. Subtracting it leaves a 6.179258 ms p95 and 12.629638 ms worst gap.

The 25.517167 ms worst frame is emulated frame `48245`. It has 25.105812 ms
CPU wall, 12.475799 ms CPU-thread work, 0.067542 ms video build, and no EFB
miss. Its 12.630013 ms wall/thread gap is therefore not slow generated
instruction execution.

Video-build time and the wall/thread gap both average about 4.6 ms, but their
frame-level correlation is only 0.358382. Gap minus video has a near-zero
mean, while its p99 is 4.438524 ms and worst is 12.562471 ms. Aggregate phase
overlap therefore explains the center but not the strict tail. The next test
must identify CPU-thread wait states or OS descheduling directly rather than
subtracting overlapping phase aggregates.

## Decision

**PERF-089 retains frontend PGO as the only successful static-recompilation
optimization and proves that its on-core CPU execution passes this exact
Fountain budget. G5 remains open because total-frame p95, p99, and worst fail.**

Do not retry broad compiler flags, source branch weights, a single-entry hot
trace, whole-module IR PGO, scheduler priority, or display-pacing variants.
Next classify the CPU thread's non-running intervals with thread-state/wait
evidence on the same PGO oracle. SyncGPU is default-false in this exact
configuration, so a FIFO wait must be observed rather than assumed. Only after
a causal candidate passes should
the full Fountain and Final Destination matrix run. G6 remains blocked.

The private phase CSV SHA-256 is
`dc53db2db019898b0c0eec0fdfdbb27de0c289d360446dfab9a681971fe923bf`.
The game exited normally and no Simulator ran.
