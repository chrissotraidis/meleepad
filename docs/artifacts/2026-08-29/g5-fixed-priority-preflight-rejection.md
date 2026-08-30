# G5 fixed-priority preflight rejection

Date: 2026-08-29

Status: **DISTINCT PUBLIC POLICY; REVERSAL FAILS; NO PRODUCT BUILD**

## Question

The retained required-stage producer tail is intermittent wall time while the
combined CPU-GPU thread is runnable but off-core. Does macOS's public
`THREAD_EXTENDED_POLICY` with `timeshare=false` provide a genuinely new fixed-
priority scheduling mode that reduces this class, unlike the already-rejected
precedence, QoS, and time-constraint candidates?

## Source semantics

The macOS 26.5 SDK exposes `thread_extended_policy_data_t.timeshare`. Apple
XNU at the previously audited public commit
[`f6217f891ac0bb64f3d375211650a4c1ff8ca1ea`](https://github.com/apple-oss-distributions/xnu/tree/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea)
confirms that `false` maps to `TH_MODE_FIXED` rather than timeshare:

- [`thread_policy.h`](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/mach/thread_policy.h#L96-L116)
  defines the public policy;
- [`thread_policy.c`](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/kern/thread_policy.c#L358-L384)
  selects `TH_MODE_FIXED`;
- precedence changes relative importance instead
  ([source](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/kern/thread_policy.c#L461-L481));
  and time constraint selects realtime with period/computation/constraint
  ([source](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/kern/thread_policy.c#L391-L458)).

This is therefore distinct enough for a host preflight. It is not an alias for
a prior experiment.

The source also exposes two safety/interpretation constraints:

- public `thread_policy_set` removes requested pthread QoS before applying a
  legacy policy and restores it only on failure
  ([source](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/kern/thread_policy.c#L311-L332));
  and
- XNU demotes sustained unsafe fixed execution after its failsafe threshold,
  temporarily returning the thread to timeshare
  ([priority source](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/kern/priority.c#L155-L195),
  [scheduler source](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/kern/sched_prim.c#L152-L167)).

Any real candidate would need policy and QoS snapshot/readback/restoration,
failsafe-event evidence, and independent UI/input/audio/lifecycle validation.

## Self-contained host preflight

A private data-free C++ harness created eight temporary CPU competitors and a
periodic worker. The worker consumed exactly 11 ms of thread CPU each
16.683333333 ms interval, yielding between frames. Each arm discarded 30
warm-up frames and measured 300. It set and read back the extended policy and
restored timeshare between arms. No app, game, ROM, save, Simulator, or
unrelated process was involved.

The first timeshare/fixed/timeshare ordering appeared promising:

| Arm | Mean wall | p95 | p99 | Worst | Above 16.683333 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| A timeshare | 11.487 ms | 14.118 | 17.278 | 18.782 | 4/300 |
| B fixed | 11.293 ms | 13.147 | 14.899 | 16.296 | 0/300 |
| A2 timeshare | 11.504 ms | 14.753 | 18.594 | 21.353 | 7/300 |

That result only authorized an order reversal, not a product build. The exact
fixed/timeshare/fixed reversal failed:

| Arm | Mean wall | p95 | p99 | Worst | Above 16.683333 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| B fixed | 11.437 ms | 13.377 | 19.876 | 29.628 | 5/300 |
| A timeshare | 11.382 ms | 13.768 | 15.901 | 17.669 | 2/300 |
| B2 fixed | 11.342 ms | 12.921 | 16.388 | 20.546 | 3/300 |

The fixed arms' off-core worst values were 18.626 and 9.540 ms versus 6.664 ms
for the enclosed timeshare arm. Fixed mode can improve some percentiles, but
it does not reliably bound the severe tail and is worse in the required
reversal.

## Decision

**Reject fixed priority before Dolphin integration.** The first apparent win
was ordering/environmental variance. The reversed brackets contradict a
causal tail improvement, and the policy adds QoS-clearing, failsafe, starvation,
priority-inversion, UI/input, and audio-underrun risks. Do not add a policy
helper, environment flag, package setting, or `CpuThread` hook from this
evidence.

If a future independent mechanism changes the causal basis, the least unsafe
placement would be an opt-in RAII scope inside single-core `CpuThread`, directly
around `system.GetCPU().Run()`, with exact extended-policy and QoS restoration
before teardown. This is implementation guidance, not authorization to retry.

Private host source/binary SHA-256:

- source: `9521005c59549b6b94ab72b8b8693a1cf732a24b0ef249da4e9a32f0bd43c382`;
- binary: `b572f99b93f1b39ee0dfc62e2077aca6c722e809a958748585f4da9c47d14f32`.

No product file or runtime state changed. No game or Simulator remains. G5
stays open and G6 remains blocked.
