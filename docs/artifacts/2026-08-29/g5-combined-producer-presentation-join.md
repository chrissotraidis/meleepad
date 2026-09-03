# G5 combined producer/GPU/presentation join

Date: 2026-08-29

Status: **INVALID G5 CONFIGURATION; SUPERSEDED BY PERF-187**

> PERF-187 correction: this run's copied private user directory regenerated
> authoritative root `config.ini` as 1920x1080 and windowed. Its native-scale/
> fullscreen descriptions and G5 comparability are invalid. Preserve the data
> only as a causal preflight. The corrected 640x528/fullscreen same-run join is
> `g5-corrected-combined-producer-presentation-join.md`.

## Question

Earlier evidence observed two residual classes in separate runs: app-side
producer/vblank stalls and rare actual-display holds after GPU completion.
Do producer stalls necessarily become visible presentation misses when both
clocks are recorded in the same run?

## Disposable diagnostic and boundary

A default-dormant `MELEEPAD_COMBINED_PRESENT_LOG` hook retained, in memory, the
current emulated/present frame identity plus command-buffer scheduled, GPU
start/end, completion, and drawable `presentedTime` values. It wrote once at
clean shutdown. The existing detailed phase logger supplied producer wall and
thread-CPU timing in the same Unix/continuous-time calibration.

The disposable signed runner was
`c53b8e7782c59edde8e5fc4251b16a677fd62361b2d5c7a18b20b1aa819731d3`.
The known PGO module remained exactly
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
The run used Metal, Cubeb, native internal scale, one native process, no
Simulator, an isolated copy of the established slot-1 Fountain state, and
quiet balanced FIFO input.

A fresh post-load image confirms coherent Pikachu/Fox Fountain gameplay at the
start. The retained measurement begins when the quiet controller writer opens
and ends immediately before record 8,165's abrupt scene transition. It spans
57.844 seconds, 3,471 presentation records, and 3,470 intervals. There is no
fresh image at the exact pre-transition endpoint, so this artifact makes no
broad visual-stability claim for the whole interval. The callback and detailed
phase loggers are observers; this is causal localization, not an observer-free
acceptance run.

## Joined result

| Metric | Actual presentation | Producer phase |
| --- | ---: | ---: |
| Intervals/rows | 3,470 | 3,470 |
| Mean / implied FPS | 16.666705 ms / 59.999861 | 16.664972 ms / 60.006102 |
| p95 | 16.666792 ms | 17.806277 ms |
| p99 | 16.666792 ms | 18.746381 ms |
| Worst | 16.666916 ms | 33.532833 ms |
| At or below 16.7 ms | 3,470 / 3,470 | 1,810 / 3,470 |
| Above 20 ms | 0 | 13 |

GPU work remained small: 4.922329 ms mean, 6.244063 ms p95,
6.675108 ms p99, and 7.314125 ms worst. Registration intervals had
17.210550/17.261676 ms p95/p99, one row above 20 ms, and a 29.767250 ms
worst.

Every one of the thirteen producer rows above 20 ms joined to an actual
presentation interval between 16.666625 and 16.666834 ms. The strongest case
was:

- producer total: 33.532833 ms;
- combined-thread wall / thread CPU: 33.147895 / 14.028794 ms;
- wall minus thread CPU: 19.119101 ms; and
- corresponding actual presentation: 16.666750 ms.

The Metal queue therefore absorbed all observed pre-transition producer
stalls. App render/vblank timestamps do not, by themselves, prove a visible
display hitch.

The excluded transition demonstrates the opposite boundary. Its producer
phase was 450.285458 ms with 312.615105 ms thread CPU; the corresponding
actual interval was 433.334208 ms, and registration/GPU completion occurred
371.805/375.302 ms after the skipped-refresh deadline. A producer arriving
hundreds of milliseconds late does propagate after queue headroom is exhausted.

## Decision and reversal

PERF-176 remains valid only for its measured app render/vblank relationship.
This invalidly configured preflight suggested that ordinary producer stalls
can be buffered, but cannot establish the product boundary. PERF-187 proves
the separation under verified 1x/fullscreen conditions.

This does not pass G5. It is a short observer-bearing Fountain window, prior
sustained actual-display runs still contain rare holds, Final Destination is
not covered, and the PRD's producer-versus-presented acceptance ambiguity is
unchanged. Do not optimize the off-core producer tail on the assumption that
it is visibly hitching without a joined actual-presentation miss.

The diagnostic source was removed. The canonical build-tree runner returned
exactly to SHA-256
`0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`,
contains no diagnostic marker, and all 26 scoped `moderngekko.*` tests pass.
No game or Simulator remains.

Private evidence hashes:

- combined presentation CSV:
  `a00b7e8b0106db77e892be38cc7ca123801c0f73eb2b748e9cdbc81e997c8fb6`;
- phase CSV:
  `f763f5ec0ea27bc3439c3e9a8a74999b25899b0201bb0f34632b0eb972a147fe`;
- render/vblank logs:
  `d5487dee0baad1953c03e01642d426c338b7132058b435eee6c0f3557f9116f5` /
  `06136aa29857e465676c90ee1c20e9c1bcc0270f17d830f50d4f0cec5a581204`;
- post-load image:
  `ae5ce29274eed89077d9422462b92b37c8e178d3f9fd9b154a45816838478422`;
- stderr:
  `29fb00fba9ec7fcf530843c16ac2de66edf0473ca85968891ddc880603e2f453`.
