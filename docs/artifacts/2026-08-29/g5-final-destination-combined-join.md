# G5 Final Destination combined producer/GPU/presentation join

Date: 2026-08-29

Status: **FOUNTAIN SEPARATION REPRODUCED ON FINAL DESTINATION; G5 OPEN**

## Question and boundary

PERF-187 proves in one corrected Fountain run that ordinary producer stalls
and GPU-ready actual-display holds are independent. Does Final Destination
reproduce both classes under the same verified product configuration?

PERF-188 reused the same disposable in-memory combined hook and exact PGO
module, but loaded the retained Final Destination slot-1 state with SHA-256
`19e5d7b8d66831f2e9032797dae2ef8399f8a6593e19a020d8cde8e176c8f181`.
The authoritative configuration remained verified after launch:

- root `config.ini`: `resolution=640x528`, `fullscreen=true`;
- `GFX.ini`: `InternalResolution = 1`;
- `Dolphin.ini`: `Fullscreen = True`;
- Metal, Cubeb, quiet balanced FIFO input, one native runner, and no Simulator.

Fresh full-screen endpoints show coherent Pikachu/CPU-Yoshi Final Destination
combat and the natural Yoshi-win results screen. The selected boundary starts
when the quiet controller writer opens and ends immediately before the first
results-transition record. It contains 4,407 presentation records, 4,406
intervals, and 73.449035 seconds.

The runner and module are unchanged from PERF-187:

- disposable runner:
  `c53b8e7782c59edde8e5fc4251b16a677fd62361b2d5c7a18b20b1aa819731d3`;
- PGO module:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

Callback observers remain enabled, and current Game Mode activation was not
independently retained from system logs. This is a causal join, not an
observer-free acceptance pass.

## Result

| Metric | Actual presentation | Producer phase |
| --- | ---: | ---: |
| Intervals/rows | 4,406 | 4,406 |
| Mean / implied FPS | 16.670575 ms / 59.985932 | 16.670520 ms / 59.986132 |
| Median | 16.666792 ms | 16.629250 ms |
| p95 | 16.666875 ms | 17.664948 ms |
| p99 | 16.666916 ms | 18.638723 ms |
| Worst | 33.333667 ms | 34.064583 ms |
| At or below 16.7 ms | 4,405 / 4,406 | 2,498 / 4,406 |
| Above 20 ms | 1 | 14 |

GPU work was 0.857246 ms mean, 1.193325 ms p95, 1.236477 ms p99, and
1.808417 ms worst.

## Same-run causal separation

The one actual display hold was 33.333667 ms. Its producer phase was only
17.058208 ms, while its present registration and GPU completion occurred
32.785/31.500 ms before the skipped-refresh deadline. It is another GPU-ready
display-conversion hold, not CPU, static-recompiler, or GPU lateness.

Conversely, all fourteen producer rows above 20 ms map to actual intervals
between 16.666708 and 16.666875 ms. The strongest is a 34.064583 ms producer
row with 33.725494 ms combined-thread wall, 8.092126 ms thread CPU, and
25.633368 ms wall-minus-thread loss; its actual interval is 16.666834 ms.
Metal queue headroom again absorbs the entire observed producer-stall class.

The excluded results transition is late through the chain: 399.978209 ms
producer phase, 288.622803 ms thread CPU, and 383.336917 ms actual interval.
The fresh results endpoint confirms the scene boundary; it is not combat.

## Decision

Final Destination independently reproduces PERF-187's result. Fountain is not
special: on both required stages, ordinary producer stalls and actual display
holds are separate causal classes. Optimizing one cannot be claimed to fix the
other.

G5 remains open. Final Destination actual presentation has one 33.333667 ms
combat hold, and producer phase has fourteen rows above 20 ms with a
34.064583 ms worst. The run also uses diagnostic callbacks and lacks a fresh
Game Mode log. Do not claim stable worst-case 60 FPS.

No diagnostic source remains in the checkout. The canonical runner remains
exactly
`0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`,
26/26 scoped tests remain green, and no game or Simulator remains.

Private evidence hashes:

- combined presentation CSV:
  `ff18adc9f596dfa287d161543101f7edf5237e76836cc77304ef6472ec4246b7`;
- phase CSV:
  `6d2c576661f16790118989e9c73472d404b57cb9a69a1593e1cdfe2f0d58b62d`;
- render/vblank logs:
  `34e40a9247c1b2320438c57217afe87a9d53e27f8774b9271f0fd701781f0fd8` /
  `77bf956f07fe1054c90bad74f72e7276e24fe69885c1f034eae28fb4f974cfcd`;
- combat/results images:
  `3dd87d1cf066be2fc20b5c4a41997185cad1874ff0bb6d603dbd70e78c867d8f` /
  `3e3fd64e0832b8dff8a26bcbe3310df1397f97e1e188998ef627c3021d09c0dd`;
- stderr:
  `a50e6196e4fc3ba8d4ae88ab2f42e19d6e6a168bb2d5827cf2019674296fec5a`;
- authoritative root/GFX configs:
  `b0823b321971720aa71a07f90bc22755f2164a2cbbd1a289af2365709287e2dd` /
  `b41eeebad3db7e3ca519828306ab9567c45b9099feeb51839e45375f07001952`.
