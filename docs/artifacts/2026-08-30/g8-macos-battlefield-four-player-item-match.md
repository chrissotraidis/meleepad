# G8 macOS four-player Battlefield item match

Date: 2026-08-30

Status: **G8 row 5 pass; performance materially below game-speed target**

## Acceptance route

The first no-input attempt was excluded because it cycled through presentation
montages and a naturally completed four-player Jungle Japes demo rather than
the required Battlefield match. The first controlled attempt was excluded at
Stage Select because its private cloned memory card still had the special-stage
row locked. Neither excluded attempt contributes timing or pass evidence.

The retained run used one isolated native macOS runner, no Simulator, Metal,
Cubeb with the DSP thread, native 640x528 EFB resolution, buffered render-time
logging, the current frontend-PGO module, a named FIFO controller, and a
repository-excluded unlocked memory card. MemoryWatcher self-verified the cold
title-to-VS-CSS route before any roster input.

Computer Use then visibly verified:

1. P1 Pikachu plus level-1 CPU Peach, Mario, and Ness under the two-minute KO
   format;
2. the literal `Battlefield` label before stage confirmation;
3. coherent live four-player Battlefield combat;
4. an item bottle present on the right platform during live combat; and
5. the natural Time Battle results screen, with Peach first, Ness second,
   Mario third, Pikachu fourth, and all four KO/fall totals visible.

The runner exited normally after the results proof. It reported zero static
fallbacks and `smc_failed=0`; no SsbmPad process or booted Simulator remained.

## Exact build and private boundaries

- Runner SHA-256:
  `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`.
- Module SHA-256:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
- Private unlocked GCI SHA-256:
  `2b03ed571ed6fa052186e981168d43d0eb96b75c95d74a30e5f8e94729f6ca2b`.
- The GCI, extracted game, generated module, and isolated user tree remain
  outside Git.

## Frame timing

The full raw render log is retained at
`docs/evidence/g8/macos-battlefield-full-render-times.txt`, SHA-256
`f89306001020ffb0f41a2c7baec619369340662ea8b63822ac9eed5572e7b3e5`.
It contains 41,817 numeric intervals from cold boot through normal shutdown.

The match bracket is rows 27,825 through 39,590: immediately after the
1,249.716 ms stage-load transition and immediately before the 74.799 ms
results transition. This matches the visibly selected Battlefield and natural
results boundaries.

| Metric | Full observed match bracket |
|---|---:|
| Samples | 11,766 |
| Total host time | 198.890 s |
| Mean / presentation FPS | 16.903808 ms / 59.158 |
| p50 / p95 | 16.680084 / 17.147458 ms |
| p99 / worst | 17.425000 / 1,693.015333 ms |
| Frames <=16.7 ms | 7,096 / 11,766 (60.309%) |
| Frames >33 ms / >100 ms | 3 / 2 |

The two >100 ms observations coincide with foreground visual-evidence work
and are reported, not silently discarded. With only those two capture-scale
pauses separated, the remaining 11,764 presentation intervals average
16.683347 ms / 59.940 FPS, with 17.146209 ms p95, 17.421125 ms p99,
59.323583 ms worst, and 60.320% at or below 16.7 ms.

The more important result is game speed: a two-minute game timer consumed
198.890 seconds of host time between the stage-load and results transitions.
That is approximately 36.2 effective game frames per host second even though
the window title and ordinary presentation cadence stay near 59.9. The host is
re-presenting while emulation falls behind in this demanding four-player
scene. Row 5 allows the target miss to be recorded honestly, so completion and
crash stability pass; this is not a 60 FPS performance pass and reinforces the
open row-7/static-core producer deficit.

## Retained visual evidence

| Evidence | SHA-256 |
|---|---|
| `docs/evidence/g8/macos-battlefield-stage-highlight.jpg` | `bd7eb00bff889950f93bea29083637c3b56e5966ffd6b5e3470f1f6379ef07f2` |
| `docs/evidence/g8/macos-battlefield-four-player-start.jpg` | `b7dde503584c0eb3a34d8ef4cb46895136335923a683e4994ac943ec8f85e03b` |
| `docs/evidence/g8/macos-battlefield-item-live.jpg` | `c8f57aa063a269aca464152b3b53d87672f4c39a1eeb29141743e02188ff7164` |
| `docs/evidence/g8/macos-battlefield-results.jpg` | `e8ececb63236a93bca00f68eef0e36599c068ba383a182976b2167c6fad6157b` |

## Decision

G8 row 5 passes: the explicit four-player Battlefield item match completed
naturally without a crash and has retained frame timing. The short performance
result remains attached to the pass and must not be promoted as 60 FPS.
