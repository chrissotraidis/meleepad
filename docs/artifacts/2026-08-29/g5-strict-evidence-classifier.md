# G5 strict producer/presentation evidence classifier

Date: 2026-08-29

Status: **REPOSITORY-NATIVE CLASSIFIER RETAINED; THREE PRIOR JOINS REPRODUCED; G5 OPEN**

## Problem

PERF-187/188 prove two independent tails in the same required-stage runs:
rare GPU-ready fixed-display holds and separate producer intervals above the
16.7 ms budget. Hand joins correctly separated them, but there was no durable
tool preventing a later report from hiding a producer miss behind a display
classification, silently dropping a zero-present callback, or pairing the
wrong phase row.

## Retained implementation

`scripts/classify-g5-intervals.py` accepts the combined Metal presentation CSV,
the same-run phase CSV, and explicit inclusive presentation-index bounds. It
emits text or machine-readable JSON. It deliberately reports
`g5_pass_claimed=false`; visual endpoints, audio, Game Mode, configuration,
observer cost, both required stages, and the rest of D2 remain outside one CSV
classifier.

The tool hard-fails unless:

- both input schemas contain all required timing, CPU, audio, frame-identity,
  and Metal-readiness columns;
- the explicit presentation bounds exist and contain every index;
- every selected presentation record joins one-to-one to a phase record within
  1 ms using the common Unix clock;
- joined emulated-frame identities match; and
- indices and timestamps remain strictly increasing.

A presentation interval above 16.7 ms is labeled
`fixed_rate_conversion` only when all of these are true:

- it is exactly two 60 Hz refreshes within 0.25 ms;
- the configured exact source rate (`60000/1001`) is slower than the fixed
  display rate (`60`);
- no undisplayed callback lies inside the span;
- Metal command status is completed; and
- registration, scheduling, GPU end, and command completion all precede the
  first missed-refresh deadline.

Any unmet condition becomes `ambiguous_presentation_miss`. A zero
`presented_ca_s` is retained separately as `undisplayed_surface`; it is never
filtered away.

Producer timing is independent. Every in-window phase `total_ms > 16.7` is a
producer miss even if the corresponding display event is fixed-rate
conversion. The first selected phase row is excluded because its interval
begins before the explicit boundary. Each miss retains CPU wall, thread CPU,
wall-minus-thread, and audio mix values. `thread_cpu_over_budget` is descriptive
only; a within-budget value is not mislabeled as off-core because intentional
waits can also contribute wall-minus-thread time.

## Test-first boundary

The initial nine data-free regressions fail without the classifier and now
pass. They cover:

- a GPU-ready two-refresh conversion hold;
- an independent producer miss under nominal presentation;
- simultaneous conversion and producer misses;
- a late-GPU ambiguous hold;
- an undisplayed surface;
- missing required columns;
- an out-of-tolerance clock join;
- exclusion of the pre-boundary first phase interval; and
- preservation of a thread-CPU-over-budget producer miss.

`scripts/check-repository.sh` now runs the suite. The full repository check
passes.

## Reproduction against retained private evidence

The exact previously selected bounds were recovered from the authoritative
raw CSVs and the published window statistics. No image, ROM, save, module, or
private CSV is added to Git.

| Run | Presentation bounds | Intervals | Fixed | Ambiguous / undisplayed | Producer misses | Thread CPU >16.7 / within |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| PERF-187 Fountain | 1108..6784 | 5,676 | 2 | 0 / 0 | 2,583 | 2 / 2,581 |
| PERF-188 Final Destination | 1898..6304 | 4,406 | 1 | 0 / 0 | 1,908 | 0 / 1,908 |
| PERF-189 rate-aligned Fountain | 1373..6784 | 5,411 | 1 | 0 / 0 | 2,393 | 1 / 2,392 |

These producer counts exactly reproduce the published at-or-below-16.7 counts:
`5676 - 3093`, `4406 - 2498`, and `5411 - 3018`. The fixed event identities and
producer phases also reproduce the hand join:

- Fountain presentation 3971: 33.333500 ms, 30.946 ms minimum readiness
  margin, 16.511875 ms producer;
- Fountain presentation 6314: 33.333458 ms, 15.012 ms margin,
  16.714625 ms producer; and
- Final Destination presentation 4965: 33.333667 ms, 31.391 ms margin,
  17.058208 ms producer.

All classifications are complete, while `producer_budget_pass` and
`strict_all_observed_intervals_pass` remain false. The tool therefore makes
the existing failure more reproducible; it does not redefine success.

## Decision and next experiment

Retain the classifier and tests. Do not use the observer-bearing PERF-187/188
phase distributions as acceptance evidence. Their causal value is strong, but
the split shows why another broad generated-code edit is not justified: only
2/2,583 Fountain misses and 0/1,908 Final Destination misses have thread CPU
above the budget in these traces.

The next scoped G5 experiment is a default-dormant, observer-light producer
recorder using only frame wall time and `CLOCK_THREAD_CPUTIME_ID`, buffered in
memory and written at shutdown. It must run on the canonical package with
Cubeb, confirmed Game Mode, explicit visual combat/results bounds, and no
presentation callback. That will decide whether current product producer
failures are on-core or wall/wait dominated without replaying closed codegen,
display, QoS, timer, fixed-priority, or unrelated-process routes.

No game or Simulator ran for PERF-192. Tool/test SHA-256:

- classifier: `1db8d126124c6b7013352cf6f28f1875ffb6df91c2aea29f92188eb2fb9d0152`;
- tests: `de486740e0ec7ddb97552f1760961a43677a9e9cde806e67bb0f2f9efaaf3c9a`.
