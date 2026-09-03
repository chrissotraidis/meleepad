# G5 Rush Frame Presentation rejection

Date: 2026-08-28

Status: **candidate rejected; product unchanged**

## Question

Can Dolphin's existing `RushFramePresentation` path create enough host-side
slack to avoid the no-queue `nextDrawable` stalls without changing guest speed,
audio, or exact emulated work?

## Mechanism audit

The current presenter acquires the drawable, renders the XFB, and calls the
existing presentation-time sleep immediately before submission. Exact control
counters show that post-render sleep averages only about 0.000043 ms. The
actual pacing boundary is the blocking `[CAMetalLayer nextDrawable]`, not a
long sleep while a drawable is held. Moving the sleep earlier therefore has no
measured budget to recover.

`RushFramePresentation` is an existing default-off Dolphin setting that skips
some intermediate throttles and presents as soon as possible. Dolphin's own UI
warns that it generally worsens frame pacing. It does not change the guest
target clock, so it was eligible for one isolated screen.

## PERF-129 method

An isolated clone of `user-114` changed only:

`RushFramePresentation = True`

The runner, frontend-PGO module, native resolution, fullscreen/Game Mode,
four-pipeline prewarm, and Fountain slot-1 state were exact. The state SHA-256
remained
`e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
The module remained
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

The 45-second Display-only trace covered exact emulated frames 48123..52195.
Candidate and PERF-126 control both execute:

- 14,188,382,922 guest cycles;
- 483,914,704 native dispatches;
- 8,402,762 static-recompiler bursts;
- zero interpreter fallback steps; and
- 8,154 hook fallbacks.

## Result

| Metric | PERF-126 control | PERF-129 Rush |
|---|---:|---:|
| total p95 | 17.808 ms | 17.901 ms |
| total p99 | 19.621 ms | 20.284 ms |
| CPU-thread mean | 11.810 ms | 11.909 ms |
| CPU-thread p95 | 13.472 ms | 13.544 ms |
| CPU-thread rows >16.7 ms | 13 | 26 |
| `nextDrawable` p95 | 6.416 ms | 6.183 ms |
| `nextDrawable` worst | 22.832 ms | 22.948 ms |
| `nextDrawable` rows >10 ms | 2 | 4 |
| audio mean | 0.841 ms | 0.830 ms |

The candidate's actual Display trace contains ten 33.333 ms holds in 44.982
seconds. The comparable first 45 seconds of the logger-free PERF-127 control
contains four. The candidate adds rather than removes long drawable waits and
doubles CPU-thread budget failures. Audio is unchanged, so there is no
compensating benefit.

The earlier no-Instruments Game Mode controls are also important. On the same
exact 4,073 emulated frames, PERF-114 and PERF-116 have CPU-thread p95 of
12.838/12.816 ms and zero `nextDrawable` rows above 10 ms. The Display-observed
PERF-126 and PERF-129 runs rise to 13.472/13.544 ms CPU-thread p95 and contain
2/4 acquisition stalls above 10 ms. The Display instrument is the best
external observer available, but it is not free. Those observer-specific tails
do not justify a drawable lifecycle rewrite in the shipped path.

## Decision

Reject Rush Frame Presentation. The private candidate remains isolated and no
product config or source changed. Do not retry it, move presentation sleeps,
or mutate the drawable lifecycle from this evidence.

The fixed 59.94-to-60 conversion remains closed by PERF-128. PERF-130/131 next
classify the approximately 400 ms match/results interval as 27 intentional
guest fields without a new XFB, not a slow rendered field. Continue G5 only
from the separate pre-results producer stalls.

## Raw evidence

Local root:
`/private/tmp/meleepad-perf114-115-gamemode.1aRWbj/run-129-rush-display`

- `phase.csv` SHA-256:
  `990d5bf8f251cf1d9b7e86d8f34a663a4bee831ae449ac1e673d8e942e204ae5`
- `displayed-surfaces-interval.xml` SHA-256:
  `7c4e29afd21e7c944384c1822d6985a373adf878d918bec92b699f3b6d17c21a`
- `display-surface-queue.xml` SHA-256:
  `4e4052f38d0646c6581a5fbad8bffc87fae9a0a21a6820dc69d34f1e9dcf70e2`
- `display-surface-swap.xml` SHA-256:
  `90cd21951f4e8a770d9f2d816637524219aff5cad091c0d5fcb90fed60e765fb`
- `stderr.log` SHA-256:
  `390c9f7faac5656d66323e7d6f1a0b527642481a57cd282d86126e6aeaf9dc0d`

No disc image, extracted game, state, module, app, or raw trace is committed.
