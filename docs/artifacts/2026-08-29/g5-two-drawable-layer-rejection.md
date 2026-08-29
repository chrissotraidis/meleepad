# G5 two-drawable Metal layer rejection

Date: 2026-08-29

Status: **CANDIDATE CATASTROPHICALLY REJECTED; DEFAULT THREE-DRAWABLE POOL RETAINED; G5 OPEN**

## Question

Could reducing the native `CAMetalLayer` resource pool from its default three
drawables to two reduce compositor queue depth and eliminate the remaining
missed-refresh and producer-tail events without changing guest, audio, or
netplay timing?

Apple defines `maximumDrawableCount` as the number of Metal drawables in the
resource pool managed by Core Animation:
<https://developer.apple.com/documentation/quartzcore/cametallayer>.
The current Dolphin Metal backend does not override it. No retained SsbmPad
experiment had tested this native layer boundary; PERF-168 tested a separate
application queue and does not answer the same question.

## One-variable candidate

A private source edit added exactly one call after creating the macOS layer:

```objective-c
[layer setMaximumDrawableCount:2];
```

The incremental build proved the compiled Objective-C selector
`setMaximumDrawableCount:` in `MTLMain.mm.o`. A uniquely identified signed
disposable app used that runner with the unchanged current-PGO module, verified
private Fountain state, fullscreen Metal, Cubeb, confirmed Game Mode, quiet
18-cycle input, one game, and no Simulator. The final signed candidate runner
SHA-256 was
`6213574b0dd110136e1e9b5033e9ad2a10e134d292083e784ba35367f983ca22`;
the module remained
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

## Result

The candidate did not make a subtle pacing tradeoff. It collapsed the stable
Fountain window:

| Metric | Render interval | Vblank interval |
|---|---:|---:|
| Rows | 2,001 | 2,001 |
| Mean / implied rate | 25.662329 ms / 38.967624 FPS | 25.661202 ms / 38.969336 FPS |
| Median | 33.208042 ms | 32.687334 ms |
| p95 | 33.393333 ms | 34.497833 ms |
| p99 | 33.449458 ms | 35.237666 ms |
| Worst | 33.554417 ms | 40.244250 ms |
| Above 30 ms | 1,080 | 1,079 |

The render window contains 245 sub-20-to-over-30 ms rises and 246 matching
over-30-to-sub-20 ms returns. This repeated starvation/return pattern persists
through every shorter suffix checked; it is not a boot or results transition.
A reversal leg is unnecessary because the candidate is catastrophically worse
than the approximately 60 FPS controls.

The run reached Game Mode on before state load and ended with 382,086,277
native dispatches, zero interpreter fallback, zero failed SMC verification,
Cubeb active, and no thermal or performance warning. Private evidence hashes:

- render log: `7d6683c1dad2d2b1ff5ce463d5e1d2d07c0319b7d6c1cd92a465bae687f344d0`
- vblank log: `b253127b8ff64e7ba9182c62e7fdb9180f2c02eb0b1dc8c3a50416899b12956c`
- runtime stderr: `b332b357e7733b597eef38e491a66e497657813872e5ac707b3eed163979161d`
- Game Policy log: `e4e5b0ffeb13de81ded965fa8a89538434c9468ab7e085e0f8fde54c2963d3cc`

## Reversal and decision

The one-line source change was removed and the canonical runner rebuilt. Its
SHA-256 returned exactly to
`0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`,
and the rebuilt object no longer references `setMaximumDrawableCount:`. No
product source or configuration change remains; no game or Simulator remains.

**Keep the native three-drawable default.** Two drawables deprive this combined
CPU-GPU path of the queue headroom it needs and turn rare holds into pervasive
doubled intervals. Do not retry layer-pool reduction or claim it as a latency
optimization. G5 remains open; G6 remains blocked.
