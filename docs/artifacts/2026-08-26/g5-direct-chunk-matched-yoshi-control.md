# G5 direct-chunk matched Yoshi control

Date: 2026-08-26

## Question

Did the rejected direct verified-chunk table actually regress required-stage
combat, or did its earlier result only differ because the freshest canonical
control used a different CPU fighter?

## Exact canonical route

The untouched packaged ABI 3 runner/module were used:

- runner SHA-256:
  `9bff54e4fd747aa4088beae1e847149a06fc7046bd4141e9d684aed58c1f355b`;
- module SHA-256:
  `2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.

The first cold watcher exited before the controller FIFO existed and produced
no input. That run was not measured. Reissuing the same memory-gated route
after the runner was live reached CSS normally. Computer Use then visibly
verified P1 Pikachu, level-1 CPU Yoshi, the literal `Fountain of Dreams` label,
live combat, and the Yoshi result screen.

The combat capture also retained the known distorted lower-floor reflection.
It is performance evidence only and does not establish visual correctness.

## Matched 4,743-frame result

Canonical frames 21,625-26,367 use the same roster, stage, input cycle, and
sample count as the rejected candidate. They end about seven seconds before
the result transition.

| Metric | Canonical ABI 3 | Direct-chunk candidate | Delta |
|---|---:|---:|---:|
| Mean frame time | 16.762538 ms | 16.933658 ms | +0.171120 ms |
| Mean FPS | 59.656839 | 59.053986 | -0.602853 |
| p50 | 16.674792 ms | 16.766791 ms | +0.091999 ms |
| p95 | 17.553780 ms | 18.752725 ms | +1.198945 ms |
| p99 | 19.125174 ms | 20.255358 ms | +1.130184 ms |
| Worst | 98.243375 ms | 33.403667 ms | not comparable as a mean-cost signal |
| Frames <=16.7 ms | 54.544% | 44.529% | -10.015 points |
| Frames >25 / >50 ms | 17 / 3 | 1 / 0 | canonical had isolated host stalls |
| CPU mean / p95 | 16.635770 / 17.461621 ms | 16.646930 / 18.567576 ms | tail regressed |
| Dispatches/frame | 134,386.603 | 137,923.653 | +3,537.050 |
| Guest cycles/frame | 8,107,174.487 | 8,107,174.581 | effectively equal |

The complete canonical phase CSV SHA-256 is
`fc0f1865920d0b8e5537f50343d1feaadc16e8a66e02a4cc8718c5e755b84655`.

## Decision

The exact control confirms a modest direct-table regression: about 1.0% more
mean frame time, a 1.20 ms p95 penalty, and about 3,537 more native dispatches
per frame despite equal guest-cycle work. The candidate still fails G5
absolutely and remains removed.

Do not retry the same table shape. Disassembly confirms its loop re-resolves
the chunk index after the preceding `FastDispatchableAt` check. The different
native-dispatch count is not itself proof of lookup cost because it reflects a
different guest execution path. A subsequent last-chunk cache preflight was
also rejected on an absolute 49.13 FPS active How-to interval; see
`g5-last-chunk-cache-rejection.md`.

This result does not close the separate menu defect. Canonical steady Main
Menu can average near 60 FPS while transitions still freeze for 1.90-3.72
seconds; both behaviors remain in the G5 failure scope.
