# G5 corrected combined producer/GPU/presentation join

Date: 2026-08-29

Status: **TWO INDEPENDENT COMBAT TAILS PROVEN IN ONE RUN; G5 OPEN**

## PERF-186 invalidation and corrected configuration

After PERF-186 was published, a direct configuration audit found that its
copied private user directory had regenerated authoritative root
`config.ini` with `resolution=1920x1080` and `fullscreen=false`. Editing only
downstream `GFX.ini` and `Dolphin.ini` did not override `moderngekko_run`.
PERF-186 is therefore a useful diagnostic preflight only; its native-scale and
fullscreen descriptions and any G5 comparability are invalid.

PERF-187 corrected all three layers and verified the authoritative root file
after launch:

- root `config.ini`: `resolution=640x528`, `fullscreen=true`;
- Dolphin `GFX.ini`: `InternalResolution = 1`; and
- Dolphin `Dolphin.ini`: `Fullscreen = True`.

A fresh full-screen image immediately after slot-1 load shows coherent
Pikachu/Fox Fountain combat. A fresh endpoint shows the natural Fox-win
results screen. The exact selected boundary begins when quiet balanced FIFO
input opens and ends immediately before the first results-transition record.
It spans 94.650457 seconds, 5,677 presentation records, and 5,676 intervals.

## Identity and diagnostic boundary

The same disposable in-memory-only combined hook was reused:

- runner:
  `c53b8e7782c59edde8e5fc4251b16a677fd62361b2d5c7a18b20b1aa819731d3`;
- unchanged PGO module:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- Metal, Cubeb, exactly one native runner, no Simulator, isolated user/save
  directory, and quiet controller output.

The drawable and detailed phase callbacks are observers. The result is a
same-run causal join with fresh visual endpoints, not an observer-free G5
acceptance pass. Current Game Mode activation was not independently retained
from system logs, so this artifact does not claim it.

## Corrected result

| Metric | Actual presentation | Producer phase |
| --- | ---: | ---: |
| Intervals/rows | 5,676 | 5,676 |
| Mean / implied FPS | 16.672624 ms / 59.978560 | 16.674362 ms / 59.972310 |
| Median | 16.666750 ms | 16.677500 ms |
| p95 | 16.666833 ms | 17.485730 ms |
| p99 | 16.666834 ms | 18.182427 ms |
| Worst | 33.333500 ms | 35.904291 ms |
| At or below 16.7 ms | 5,674 / 5,676 | 3,093 / 5,676 |
| Above 20 ms | 2 | 14 |

GPU work was 1.497398 ms mean, 1.613675 ms p95, 1.673547 ms p99,
and 1.969958 ms worst. This returns to the established native-scale GPU class
and excludes M1 GPU saturation.

## The two tails are independent

Both actual 33.333 ms display holds occurred with a nominal producer phase and
GPU work complete well before the skipped refresh:

| Record | Actual interval | Producer phase | Registration vs deadline | GPU end vs deadline |
| ---: | ---: | ---: | ---: | ---: |
| 3,971 | 33.333500 ms | 16.511875 ms | 32.784 ms early | 31.056 ms early |
| 6,314 | 33.333458 ms | 16.714625 ms | 17.030 ms early | 15.119 ms early |

Conversely, all fourteen producer rows above 20 ms map to actual presentation
intervals between 16.666708 and 16.666792 ms. They include:

- two on-core-heavy producer rows at 35.904291/35.011708 ms with
  31.927009/29.197916 ms thread CPU; and
- a 34.332916 ms producer row with only 12.442623 ms thread CPU and
  21.448809 ms wall-minus-thread loss.

The Metal queue absorbed every producer stall. The actual display holds are
the already-established GPU-ready fixed-display conversion class; they are not
caused by that frame's static-recompiler work, off-core producer loss, or GPU
lateness.

The excluded results transition is separately late throughout the chain:
447.486708 ms producer phase, 327.344322 ms thread CPU, and a 450.002167 ms
actual interval. This is a natural scene transition outside the combat
boundary, not a hidden combat miss.

## Decision and restoration

This same-run join replaces the earlier inference that ordinary producer
stalls necessarily become visible hitches. Optimizing the producer tail may
increase headroom, but it cannot remove the two observed GPU-ready display
holds. Conversely, presentation/display work cannot remove the independent
producer rows if D2 is interpreted as a producer-work budget.

G5 remains open under either reading: actual presentation fails twice at
33.333 ms, while producer phase has fourteen rows above 20 ms and a 35.904 ms
worst. The test also covers only Fountain, not Final Destination, and uses
observer callbacks. Do not claim stable worst-case 60 FPS.

No diagnostic source remains in the checkout. The canonical runner is still
exactly
`0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`,
26/26 scoped tests pass, and no game or Simulator remains.

Private evidence hashes:

- combined presentation CSV:
  `0a9f93ca7d85959c2179dc83afd6b3ef17ffc0e5957861c9f083c3d2420b28e7`;
- phase CSV:
  `08228acd2c3e71eb3d96acab62e6d0f12994ef84979fb230aaa2f4c2ce77cd5c`;
- render/vblank logs:
  `23da5e43dc07d9e277093ee556b70e418d9a22022a751ae3523fa388f6a9801b` /
  `954f7bda01ee42d8546c3a808c8ba7f36cf4ec3e95628c22ac9c9505473ac9b1`;
- combat/results images:
  `2d42f2c9d216588fb0106c37dbd4ecb91403ecd4d49129036a5a0121c18f2b68` /
  `a003ca9e1003101a8d8d5027ef6f64ad6c5565843c61cc1e61669cf541a002ed`;
- stderr:
  `0387640efe6055cef7056dac390fd8380de56ddee928996147c79025a1c3fb65`;
- authoritative root/GFX configs:
  `b0823b321971720aa71a07f90bc22755f2164a2cbbd1a289af2365709287e2dd` /
  `b41eeebad3db7e3ca519828306ab9567c45b9099feeb51839e45375f07001952`.
