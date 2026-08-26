# G5 menu pacing follow-up rejections

Date: 2026-08-26

## Question

The cycle-preserving idle-poll collapse removed about 2.9 ms of CSS CPU work
but increased long-sleep wake lateness and regressed p95. Could bounded macOS
sleep chunks recover the strict menu tail without restoring the redundant
guest poll work?

## Retained host preflight extension

`scripts/g5_pacing_preflight.cpp` now accepts synthetic-work and sleep-chunk
arguments and compares four interleaved modes: current one-shot sleep plus
yield, chunked sleep plus yield, chunked sleep plus true spin, and one-shot
sleep plus true spin. The matched long-sleep screen used 5.5 ms synthetic work,
a 16.683333 ms frame period, the unchanged 1.02 ms final window, 500 us sleep
chunks, and 600 samples/mode.

| Mode | Mean | p95 | p99 | Worst | <=16.7 ms |
|---|---:|---:|---:|---:|---:|
| One-shot + yield | 20.320772 | 20.783265 | 20.791544 | 22.498459 | 4.833% |
| Chunked + yield | 16.685016 | 16.692421 | 16.705378 | 16.724583 | 98.500% |
| Chunked + true spin | 16.683457 | 16.683458 | 16.685627 | 16.712500 | 99.833% |
| One-shot + true spin | 20.349176 | 20.775463 | 20.787130 | 20.791250 | 3.667% |

The extended harness was compiled with ASan/UBSan after an initial `%3` mode
selection bug left the fourth result vector empty. The sanitizer identified
the empty percentile input; changing the interleave to `%4` fixed the harness.
The corrected full run completed normally.

## Candidate A: 500 us chunks plus final yield

The local Apple timer used 500 us intermediate `sleep_until` chunks before the
existing 1.02 ms final scheduler-yield window. It was combined only locally
with the already verified cycle-preserving idle-poll collapse. The cold watched
route reached coherent CSS.

| Metric | Bracket 1 | Bracket 2 |
|---|---:|---:|
| Frames | 1,181 | 1,200 |
| Mean | 16.683344 ms | 16.683643 ms |
| p95 | 16.933042 ms | 16.902167 ms |
| p99 | 17.324750 ms | 17.203875 ms |
| Worst | 19.966958 ms | 56.486542 ms |
| FPS from mean | 59.940 | 59.939 |
| Frames <=16.7 ms | 58.002% | 57.000% |
| CPU-thread mean | 6.415168 ms | 6.465796 ms |
| Wake lateness mean / p95 | 0.003872 / 0.015764 ms | 0.002823 / 0.012597 ms |

This fixed the prior 0.375-0.407 ms mean wake lateness but did not beat the
normal control's 16.896375 ms p95 or pass 16.7 ms. The external sample kept the
poll collapsed: `loop_80349494` fell to 29/8,136 CPU-thread samples.

## Candidate B: 500 us chunks plus final true spin

The final Apple wait used `atomic_signal_fence` instead of scheduler yield.
The same cold watched route reached coherent CSS. Wake lateness became
effectively zero, but the full distribution still failed:

| Metric | Bracket 1 | Bracket 2 |
|---|---:|---:|
| Frames | 1,207 | 1,200 |
| Mean | 16.683238 ms | 16.683245 ms |
| p95 | 16.928416 ms | 16.890292 ms |
| p99 | 17.123417 ms | 17.120750 ms |
| Worst | 18.970125 ms | 17.924000 ms |
| FPS from mean | 59.940 | 59.940 |
| Frames <=16.7 ms | 58.326% | 57.500% |
| CPU-thread mean | 6.883626 ms | 6.642652 ms |
| Wake lateness mean / p95 | 0.000175 / 0.000196 ms | 0.000251 / 0.000404 ms |

The repeat barely crossed the normal control by 0.006 ms at p95, while the
first bracket was 0.032 ms worse. Neither bracket passed the absolute gate.
With wake lateness removed, the remaining 16.89-16.93 ms p95 is not a sleep-
primitive problem.

## Decision and next experiment

**BOTH PRODUCT CANDIDATES REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN; G6
BLOCKED.** The timer and generated idle changes were removed. The normal signed
runner `c26625db...` and corrected module `2dce1352...` are restored; no runtime
or Simulator remains. The extended host preflight is retained because it
reproduces the newly observed long-sleep failure and catches future pacing
ideas before a game build.

Do not retry sleep leads, chunk sizes, yield/spin substitutions, or generated
loop budgets. The next single experiment is diagnostic only: add frame/present
sequence identity and throttle-target timing to the existing phase log, then
use a normal watcher-gated CSS bracket to determine whether the residual tail
is CPU-slice aggregation, present-boundary scheduling, or logging alignment.
No behavior changes are authorized until that attribution is complete.

## Retained artifacts

- `g5-chunked-idle-css-phase.csv` — SHA-256 `291732f39f4d79fc2b538902b450168bdbfb0326b2ec620dfebd13f39bb5933a`
- `g5-chunked-idle-css.jpeg` — SHA-256 `177b2365a31ae1ce4542c4b9397fb13723271b2e143ac3882227f1ebdb433b73`
- `g5-chunked-idle-css.sample.txt` — SHA-256 `79fef5ca2d532bc6a0b8b0d19ebd5286f0b0d6a29f23ff87ae534842b10f7cd5`
- `g5-chunked-spin-idle-css-phase.csv` — SHA-256 `aaed6ba2a2370bd291a5a9678155ef98122031816bec5dd9a124222f528ad38f`
- `g5-chunked-spin-idle-css.jpeg` — SHA-256 `e0a8f6c155328d00a609d3ea902e361239985c423047619badd59731dc45788c`
