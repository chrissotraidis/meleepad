# G5 same-process Final Destination warm-up (PERF-198)

## Question

After the one-time static-recompiler warm-up, is Final Destination still
compute-bound, or is its remaining miss class predominantly wall/host timing?

## Method

One signed, single-core Metal/Cubeb process loaded the same verified Final
Destination state twice. Both legs used the same quiet input sequence and
reached results. Fresh visual checks confirmed coherent Pikachu-versus-Yoshi
combat on literal Final Destination. Simulator and unrelated processes were
untouched. Only the default-dormant lightweight recorder was enabled.

The corrected trace has 17,499 rows and one exact second-load frame reset. The
comparison uses the same 5,890 post-load combat frames in each leg (emulated
frames 30,295 through 36,184), excluding savestate load work and results.

## Results

| leg | mean FPS | wall p95 | wall p99 | wall worst | wall >20 ms | CPU p95 | CPU worst | CPU >16.7 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cold | 59.721505 | 16.790042 | 16.865041 | 388.145417 | 4 | 8.299125 | 28.000917 | 1 |
| warm | 59.959490 | 17.268541 | 17.499708 | 26.497500 | 3 | 8.764209 | 13.438375 | 0 |

The warm leg has no CPU frame above the 16.7 ms budget. Its three intervals
above 20 ms are 25.267167, 26.342000, and 26.497500 ms, while
wall-minus-thread reaches 20.478291 ms. This is not stable 60 FPS: only 59.406%
of warm intervals are at or below 16.7 ms and the unchanged G5 gate requires a
16.7 ms worst case.

Raw private trace SHA-256:
`eabb14a73f5f8d3585a1c8e076b4b32d8348942366f4de3a67c34f04ec115bd1`.
ROM, state, module, and raw trace remain private.

## Decision

Final Destination's warm combat is no longer static-core-bound in this run.
Do not spend the next iteration on another guest-PC/static-recompiler rewrite.
The next falsifiable experiment should join the three warm wall outliers to
the retained render/vblank/presentation timelines with exact frame identity,
then change only the subsystem named by that join. G5 remains open and G6 is
blocked.
