# G5 triggered sampler schema repair (PERF-205)

Date: 2026-08-30

Status: **DIAGNOSTIC SCHEMA REPAIRED; FIVE END-TO-END CASES PASS; NO FPS CLAIM; G5 OPEN**

## Question

Can the retained external thread sampler still trigger specifically on a slow
warm phase row after the lightweight phase CSV gained a host timestamp column?

## Failing regression

The sampler parsed fields by fixed position: CSV column 2 as
`emulated_frame`, then column 3 as `total_ms`. The current schema is:

```text
frame,emulated_frame,host_frame_end_unix_ns,total_ms,...
```

An end-to-end data-free case supplied emulated frame 500, host timestamp
`1788067000000000000`, and a true total of 10.0 ms under a 16.7 ms threshold.
Before the repair it failed as intended:

```text
current-below-threshold: expected 3, got 0
trigger_emu=500 trigger_total_ms=1.78807e+18
```

The tool was therefore falsely triggering on every in-range current-schema
row. Any future capture selected that way would be untrustworthy.

## Repair and verification

The sampler now resolves `emulated_frame` and `total_ms` from the first CSV
header row, parses only those named fields, validates complete numeric
conversion, and exits with an explicit usage/schema error when either required
column is absent. It retains compatibility with the older schema and does not
depend on column order.

`scripts/test_triggered_thread_sampler.py` compiles the real sampler and a
private named-thread target, then exercises five end-to-end cases:

1. current schema, 10.0 ms: no trigger / exit 3;
2. current schema, 20.0 ms: trigger / exit 0;
3. legacy schema, 20.0 ms: trigger / exit 0;
4. reordered schema, 20.0 ms: trigger / exit 0; and
5. missing `total_ms`: schema rejection / exit 2.

Focused result:

```text
Triggered thread sampler tests passed
```

The test is now part of `scripts/check-repository.sh`. Full result:

```text
Ran 9 tests in 0.417s
OK
Lightweight frame timing patch tests passed
Triggered thread sampler tests passed
Repository checks passed
```

## Boundary and decision

This is a diagnostic correctness repair, not a product optimization. The
sampler records external thread CPU time and run/sleep state; it does not name
native PCs and cannot replace the rejected CPU Counters route. PERF-195 already
attributes warm Fountain CPU overruns to static-core compute, while PERF-196
provides sampled guest-PC regions. Repeating a live game run with this repaired
tool alone would add no new causal dimension.

No app, module, ROM data, game process, Simulator, or performance setting
changed. Make no FPS or G5 acceptance claim. G5 remains open and G6 remains
blocked.
