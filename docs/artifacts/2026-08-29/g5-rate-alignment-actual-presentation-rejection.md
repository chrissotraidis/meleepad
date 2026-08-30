# G5 exact-rate actual-presentation rejection

Date: 2026-08-29

Status: **1001/1000 RATE ALIGNMENT STILL MISSES ACTUAL REFRESH; REJECTED**

## Reopened question

PERF-175 rejected `EmulationSpeed = 1.001` because its app-side producer log
retained a 33 ms hold and did not improve p95. PERF-187/188 subsequently prove
that app producer stalls and actual-display holds are independent. Could exact
`60000/1001`-to-60 wall-rate alignment still remove the actual display class,
even though it does not fix producer timing?

## Exact isolated candidate

PERF-189 cloned PERF-187's corrected Fountain setup and changed only private
`Dolphin.ini` from the default speed to `EmulationSpeed = 1.001`. It retained:

- authoritative `resolution=640x528`, `fullscreen=true`;
- `InternalResolution = 1`, Metal, Cubeb, one native runner, no Simulator;
- the same Fountain slot-1 state and quiet balanced input;
- disposable runner
  `c53b8e7782c59edde8e5fc4251b16a677fd62361b2d5c7a18b20b1aa819731d3`;
- PGO module
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

Fresh full-screen endpoints show coherent Pikachu/Fox Fountain combat and the
natural Fox-win results screen. The pre-results boundary contains 5,412
presentation records, 5,411 intervals, and 90.212828 seconds. The combined
callbacks remain diagnostic observers, and current Game Mode activation is
not independently claimed.

## Candidate result

| Metric | Actual presentation | Producer phase |
| --- | ---: | ---: |
| Intervals/rows | 5,411 | 5,411 |
| Mean / implied FPS | 16.669889 ms / 59.988402 | 16.669174 ms / 59.990975 |
| Median | 16.666792 ms | 16.649959 ms |
| p95 | 16.666875 ms | 17.683104 ms |
| p99 | 16.666917 ms | 18.346337 ms |
| Worst | 33.333666 ms | 34.792000 ms |
| At or below 16.7 ms | 5,410 / 5,411 | 3,018 / 5,411 |
| Above 20 ms | 1 | 18 |

GPU work was 1.483861 ms mean, 1.611000 ms p95, 1.666125 ms p99, and
1.798583 ms worst.

The actual 33.333666 ms hold occurred only 30.413 seconds into the selected
window. Its producer phase was nominal at 16.909166 ms; registration and GPU
completion were 32.792/31.017 ms before the skipped-refresh deadline. The
rate-aligned candidate therefore reproduces the same GPU-ready display hold
class rather than removing it.

All eighteen separate producer rows above 20 ms were again buffered into
actual intervals at or below 20 ms. Rate alignment fixes neither independent
tail under the strict gate.

## Reversal and decision

**Reject exact host-rate alignment against actual presentation.** The candidate
still misses a real refresh and adds a product-wide wall-rate policy without
satisfying G5. Do not retry a larger speed scale: that changes wall-clock game
and audio pacing and has no causal basis for the compositor-selected hold.

The isolated setting was removed after evidence capture. Its private
`Dolphin.ini` returned byte-for-byte to the control SHA-256
`1f3a69fa0b44bb01dbea8b59c39ca88793c3c08d3d1c8ac3233685dd1e29c2b2`.
No product source/config changed. The canonical runner remains exactly
`0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`,
and no game or Simulator remains.

Private evidence hashes:

- combined presentation CSV:
  `e45a579777b16e560e3b8b318a15eb01b66a23f9b98469aa5abb6add21f549c7`;
- phase CSV:
  `f1d34bf7b7edab628e3aa74a01020a018c6304cde5676fcf32ed3e178a2a5c5a`;
- render/vblank logs:
  `6b45be74fa19459358e724f0a135f2f0941034673721943a32ba111ffca20f47` /
  `537805630dab23af12bf5b7be70219b27325542a8e232ae7dca14ed17b787e18`;
- combat/results images:
  `a87e9d82ac8bf73bba6250c91d1c6ce648b2d30504ea06b1e7379b8d5d8d95fd` /
  `67989cd46d6b8415cd6070b1cd175ab1b1d7a3644d2c9e2ea4eae9251f87cd87`;
- stderr:
  `500d5c9d6fbc8cf458eccffcf66f846c936c5eab6692293f73230ac13b67d615`;
- candidate `Dolphin.ini` before reversal:
  `a5e806a1b8daa246c92f34dac30eec181e49346730f98e41890f8b3248ea598b`.
