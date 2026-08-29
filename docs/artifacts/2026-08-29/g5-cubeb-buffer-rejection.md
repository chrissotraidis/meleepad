# G5 Cubeb buffer-size rejection

Date: 2026-08-29

Status: **LARGER AUDIO BUFFER REJECTED; CUBEB 512 RETAINED; G5 OPEN**

## Question

Can a larger Cubeb output buffer reduce real-time audio callback wake pressure
on the combined CPU-GPU path while preserving required audio output?

The generic Dolphin `AudioLatency` setting is not consumed by `CubebStream`.
Cubeb instead requests `max(BUFFER_SAMPLES, minimum_latency)` frames, with a
hard-coded 512-frame default. A separate DSP-thread idea was rejected before
build: Melee uses DSP HLE, and `DSPHLE::Initialize` ignores its `dsp_thread`
argument, so `DSPThread=False` would not move HLE work or remove a thread.

## Effective one-variable candidate

A private source candidate changed Cubeb's requested buffer from 512 to 1,024
frames and emitted its values once at startup. A brief boot measured the
CoreAudio device minimum as only 128 frames, proving that the candidate doubled
the effective Dolphin request rather than being masked by the device minimum.

The signed disposable app then used the candidate runner with the unchanged
current-PGO module, verified private Fountain state, fullscreen Metal, Cubeb,
confirmed Game Mode, quiet 18-cycle input, one game, and no Simulator. The
signed candidate runner SHA-256 was
`414228daf4cbc08494b3db0989a73a2d76e3e3ecc4ab19ac1ce2771fb25381a0`;
the module remained
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

## Result

Exact final 2,001-row render windows:

| Metric | 512-frame control | 1,024-frame candidate |
|---|---:|---:|
| Mean / FPS | 16.675122 ms / 59.969577 | 16.691696 ms / 59.910028 |
| p95 | 16.786209 ms | 16.789792 ms |
| p99 | 16.834666 ms | 16.840750 ms |
| Worst | 33.919041 ms | 33.362791 ms |
| At or below 16.7 ms | 71.364% | 70.615% |
| Above 20 ms | 2 | 3 |

The candidate loses mean rate, p95, p99, compliance share, and doubled-frame
count. Its lower single worst value is ordinary run-to-run placement within
the same doubled-frame class, not a causal improvement. Matching vblank rows
also retain the holds: 16.691629 ms mean, 17.530916 ms p95, and 34.148375 ms
worst, with five rows above 20 ms.

The candidate reached Game Mode on before state load and ended with
549,697,015 native dispatches, zero interpreter fallback, zero failed SMC
verification, Cubeb active, and no thermal or performance warning. Private
evidence hashes:

- render log: `9dfd98c726d24415d289366bf0532121b82fb08857a83d13644f3480d8b2e83a`
- vblank log: `06579370555fbaf53328e1f4afce6b06fa8860aef7cafc4f3fb9e85e213f909b`
- selected render window: `9f48a4e0e9ed0080edb7c0e4ed0d7a66093e1fbde535cd2cae226a7bef3bdec7`
- selected vblank window: `a209d3a33b9c38bbad0eb9654696f39341818a1353e2bc454cecb3d687a85f77`
- runtime stderr: `e1c774de0b7524008ed137c4464edcbfe6db9c695708fdb72c5bb1d830125de2`
- Game Policy log: `471a3100407d1f459ded292b3f88c4b26cf49163f5806e1b911cb796c8bca569`

## Reversal and decision

The buffer constant returned to 512, the one-time diagnostic was removed, and
the canonical runner rebuilt to exact SHA-256
`0abc212bbf4e7c6f3a1b295d99b85476d1f8cf80ae59430a97f70a934d4d3e34`.
The private logger configuration was also restored byte-for-byte after an
excluded logging probe. No product source/configuration change, game, or
Simulator remains.

**Retain Cubeb's 512-frame request.** Doubling audio buffering adds latency
without reducing the shared render/vblank hold class. Do not retry generic
`AudioLatency`, DSP-thread toggles under HLE, or larger Cubeb buffers. G5 stays
open; G6 remains blocked.
