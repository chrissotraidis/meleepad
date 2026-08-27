# G5 paired-single load transaction rejection

Date: 2026-08-26

## Question

Dolphin reads a non-`W` paired-single load as one 16-, 32-, or 64-bit
transaction, while GXRuntime performs two scalar lane reads. Would the same
coalescing retained for paired stores reduce the remaining Fountain CPU tail?

## Semantic and artifact screen

A regression-first GXRuntime test recorded external-read count, address,
value, and size for float, U8, U16, S8, and S16 pairs, plus the unchanged
`W=true` scalar path. It failed against the two-read implementation, then the
candidate passed the focused and full GXRuntime suites. The source-built
module used distinct cache key `60192f7ab4d77b40`, recorded
`module_sources=0ce6b0df8fa41ce8`, reproduced an exact cache hit, and had
unsigned SHA-256
`d8092f615fbff352dc464c08df88980e5b4120fac0b2634de950933f9aa3c7e8`.

## Live Fountain result

Computer Use verified P1 Pikachu, level-1 CPU Yoshi, literal Fountain of
Dreams, and coherent live combat in the isolated candidate app. CSS and Stage
Select held 59.9-60.0 FPS; combat visibly fell to 53.7 FPS. One sampled frame
caught a stretched/blurred Pikachu silhouette, but one frame is insufficient
to reopen `VISUAL-001B` without persistence across adjacent frames. The
temporary Computer Use screenshot URLs expired after process exit, so no
missing image is represented as retained evidence.

The immutable combat bracket contains frames 57,144-61,721:

| Metric | Paired-load candidate |
|---|---:|
| Frames | 4,578 |
| Mean / FPS | 19.178837 ms / 52.141 |
| p50 / p95 | 19.209958 / 21.220959 ms |
| p99 / worst | 23.250584 / 37.409709 ms |
| Frames <=16.7 ms | 3.189% |
| CPU-thread mean / p95 | 18.779152 / 20.721910 ms |
| Video-build mean / p95 | 0.057955 / 0.083000 ms |
| Present mean / p95 | 0.020467 / 0.049167 ms |
| Audio mean / p95 | 0.988102 / 1.307666 ms |
| Guest cycles/frame | 8,107,174.65 |
| Native dispatches/frame | 138,791.69 |
| Static fallback steps | 0 |

The nearest retained paired-store Fountain capture used CPU Mario rather than
CPU Yoshi, so no relative percentage is claimed. The absolute result is a
decisive G5 failure: flat guest cycles, zero fallbacks, tiny renderer/present
work, and about 18.8 ms of CPU-thread work.

## Decision and cleanup

**PAIRED-LOAD CANDIDATE REJECTED; PAIRED-STORE FIX RETAINED; G5 OPEN; G6
BLOCKED.** Candidate helper, regression, bootstrap entry, and patch were
removed. The active module pointer is restored to key `1e1debc9fb83a31a`
(`a85cf8c5...` unsigned); the promoted signed product was never changed and
remains `2fe01870...`.

Do not retry this global load change or combine it with another candidate.
Next, take a source-line-symbolized native Fountain sample without per-frame
PC logging, reducing broad hot chunks `0x8035D940` and `0x8033D940` to one
named guest routine/helper before another product change.

## Retained evidence

- `docs/evidence/g5-paired-load-rejection/pikachu-yoshi-fountain.phase.csv`
  — SHA-256
  `cf30ac6d12357b92daff090ce7e814bf34df37522560120655d42c279dd834d6`
