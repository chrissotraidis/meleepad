# G5 reduced-idle Fountain PGO rejection

Date: 2026-08-25

Status: **CANDIDATE REJECTED; G5 FAILS; VISUAL-001B REPRODUCED**

## Candidate provenance

A fresh instrumented arm64 module collected a full, visibly verified two-minute
Fountain of Dreams match with Pikachu against a level-1 CPU Ice Climbers team.
The resulting reduced-idle profile was merged and used to build a strict-FP,
ThinLTO, `-O2` screening candidate. It is deliberately described as
reduced-idle rather than idle-free because LLVM function-entry instrumentation
still counted `loop_80349494` before the host dispatcher returned the known
idle PC.

- merged profile SHA-256:
  `a970050301e866102616be79da7a6c5ec0b6883070073321fd1b7a0fc25974cb`
- candidate module SHA-256:
  `6400b1e99813b34f139564667c97196dab7503a72a68649dce79b1fbbbb6d517`
- module architecture: arm64
- minimum macOS: 14
- runtime: Metal, Cubeb audio, 640x528, no mods

The profile, raw module, extracted game, save, and ROM remain outside tracked
paths.

## Visually verified route

Exactly one native macOS runner was launched with the candidate module. No
Simulator was booted. The native window visibly showed:

1. Pikachu versus level-1 CPU Zelda and `READY TO FIGHT`;
2. Stage Select;
3. the red stage highlight and large label `Fountain of Dreams`;
4. live two-minute Fountain combat before measurement.

The title read 59.9 FPS in the verified combat frame. The same frame also
reproduced impossible scene geometry: oversized and displaced Fountain
background elements and a badly scaled/displaced fighter composition. The
retained frame is `g5-reduced-idle-pgo-fountain-corruption.jpeg`, SHA-256
`5066b6f3fdd08316d4d70841b19042c1c8ab0eb525bb2d9d1bdee5f7c3560c6e`.
This is fresh positive evidence for promotion-blocking `VISUAL-001B`; a high
FPS title does not make the frame visually correct.

## Clean Fountain screening interval

After visual inspection stopped, twenty repetitions of the retained combat
cycle ran without screenshots or UI inspection. The exact audio-inclusive
interval was render records 31,747-36,186 and vblank records 32,774-37,212.
Every record in both slices was a valid numeric value.

| Metric | Candidate render | Retained render | Candidate vblank | Retained vblank |
|---|---:|---:|---:|---:|
| Samples | 4,440 | 5,463 | 4,439 | 5,804 |
| Mean | 16.683456 ms | 16.683 ms | 16.683468 ms | 16.683 ms |
| Median | 16.678416 ms | 16.677 ms | 16.682666 ms | 16.679 ms |
| p95 | 17.215902 ms | 17.115 ms | 17.287146 ms | 17.180 ms |
| p99 | 17.459330 ms | 17.318 ms | 17.306709 ms | 17.291 ms |
| Worst | 88.406792 ms | 59.024 ms | 88.046083 ms | 73.595 ms |
| Frames <=16.7 ms | 54.212% | 54.714% | 61.726% | 59.717% |

Exact extracted byte-stream SHA-256 values:

- render: `efc3631646c8d3220ef148a0952d26b51cc3dd30a93caac4349fe6e66af7425c`
- vblank: `6649ddf7fa460727f4d3a23f28e1fbd8fb4ee77432ab07dfcd9b13b35a76a0b0`

The candidate regressed render p95, p99, worst-case, and <=16.7 ms coverage.
It therefore fails the Fountain screening rule and is rejected without a
Final Destination run. G5 remains unmet.

## Follow-up

The instrumentation-only reset/dump hooks, focused real-module fixture, and
live CPU-thread trigger are now implemented and verified in
`g5-combat-profile-control.md`. The next falsifiable experiment is to collect a
truly combat-only Fountain profile with that control path and screen its
PGO-use candidate against the retained baseline.
