# G5 canonical phase join and time-constraint rejection

Date: 2026-08-27

Status: **ATTRIBUTION RETAINED; SCHEDULER CANDIDATE REJECTED; G5 OPEN**

## Question

PERF-069 proved that product-scoped Metal display synchronization fixes the
ordinary presentation cadence, but full matches still contain missed
refreshes. This step joined actual `MTLDrawable.presentedTime` intervals to
the canonical module's existing emulated-frame phase rows, then tested the
smallest scheduler candidate consistent with the result.

No ROM, savestate, generated game data, memory card, or private PGO profile is
retained here. The raw evidence contains timing counters and runtime logs only.

## Joined canonical result

The full Fountain match used the canonical non-PGO module and naturally
transitioned to results after 115.270 seconds. Following the established
two-second warm-up, 6,670 actual presentation intervals remained. Matching
the ending presentation row's frame identifier to phase row `frame - 1`
produced a 0.674781 correlation between presentation gaps and phase total;
nearby offsets ranged from 0.094732 to 0.306143.

| Metric | Result |
| --- | ---: |
| Actual intervals | 6,670 |
| p95 | 16.666667 ms |
| p99 | 33.332875 ms |
| Worst | 133.332917 ms |
| At or below 16.7 ms | 98.306% |
| Misses | 113 |

The phase split shows that ordinary misses are mostly compute pressure, not
Metal acquisition or display work:

| Phase metric | Compliant intervals | Missed intervals |
| --- | ---: | ---: |
| Total | 16.874137 ms | 23.134129 ms |
| CPU wall | 16.482190 ms | 22.617864 ms |
| CPU thread | 16.079824 ms | 19.623207 ms |
| Video build | 0.465052 ms | 0.097427 ms |
| Audio mix | 0.865692 ms | 0.946850 ms |
| Guest cycles | 3,494,514.6 | 3,678,560.4 |
| Native dispatches | 119,694.0 | 126,282.8 |

Missed rows execute about 5.3% more guest cycles and 5.5% more native
dispatches than compliant rows. The worst interval is different: its aligned
phase row measured 132.806292 ms total and 131.944005 ms CPU wall, but only
31.829401 ms CPU-thread time. That row contains about 100 ms off-core in
addition to the ordinary compute pressure. The tail is therefore mixed:
common misses are on-core overruns, while the rare worst case is an off-core
stall.

The phase logger itself is intrusive: this joined run has materially more
misses than the stripped canonical full match in PERF-069. It is suitable for
classifying the misses, not for replacing the stripped product's acceptance
numbers.

## Soft real-time screen

Apple documents `THREAD_TIME_CONSTRAINT_POLICY` as a soft real-time facility,
warns that it offers no guarantee, and notes that compute-bound or inaccurate
requests may be demoted. The canonical module's roughly 16 ms CPU demand has
no safe real-time budget, so it was not exposed to the experiment. The
already-faster, private PGO oracle was screened instead with a default-off
diagnostic policy:

- period: 16.666667 ms;
- computation: 12 ms;
- constraint: 16 ms;
- preemptible: true.

The Mach call returned success and logged converted absolute units
`period=400000 computation=288000 constraint=384000`. After the same
two-second warm-up, the 773-interval short bracket measured 16.666499 ms p95,
16.666500 ms p99, 116.664750 ms worst, and 99.871% compliance. Its matching
PGO display-sync control in PERF-069 had been 100% compliant with a
16.666709 ms worst. The candidate introduced a long stall into an otherwise
perfect bracket and is decisively rejected; a full match was not justified.

Reference: [Apple Kernel Programming Guide, Mach scheduling and thread
priorities](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/KernelProgramming/scheduler/scheduler.html).

## Reversal and decision

All time-constraint code and the temporary actual-presentation logger were
removed. The existing desktop build was rebuilt successfully. Its arm64
runner contains `metal layer display sync: product policy enabled` and
contains neither the time-constraint marker nor the presentation-logger CSV
header. The retained signed canonical app remains unchanged.

Two disposable diagnostic app bundles and eight isolated temporary user trees
were removed after retaining the timing evidence, recovering about 1.4 GB.
The ROM, canonical apps, source inputs, saves, and repository evidence were
untouched.

**PERF-070 is retained as attribution; the scheduling candidate is rejected;
G5 remains open; Final Destination and G6 remain blocked.** Do not retry QoS,
priority raising, dual-core, real-time/time-constraint scheduling, timer, or
presentation-setting variants. The next compute step must use the current PGO
oracle to design a reproducible, data-free product path or another causal
generated-code change; it must not commit a ROM-trained profile.

## Evidence identities

Raw evidence is in
`docs/evidence/g5-phase-join-time-constraint-rejection/`.

- joined phase CSV: `f9a929d41d88acb38c33b84ddc75931993da8624226f0dc32188d977693d0d2d`
- joined presentation CSV: `9e5756bc04f77a7ad84f6dee04daa82d6fdc181671200741ffd0e0873bb46645`
- time-constraint presentation CSV: `c111d1a8b73649c8d69d3b5ad89b04e96bee5d8ba5fe3173a763e5b8327cff8d`
- disposable time-constraint runner: `d09d8ba00c25d6ae94ebc1fb922dccf94b39c3e6395c3612ea47433096ac46ec`
- unchanged PGO oracle module: `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`
- retained canonical app runner: `93ebc4626307486602ed4525276ea9ed2c309b13c9a7805257981d3616563cd5`
- retained canonical module: `44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`
- restored incremental source runner: `a80bcb89edc4f79af266806df179ff33ca3d9d935dcfbc4158cd6c275ff79d4a`
