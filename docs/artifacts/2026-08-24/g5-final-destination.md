# G5 Final Destination unlock and PGO trace

Date: 2026-08-24

## ROM-safe unlock setup

The retail image was not modified. The existing MeleePad GCI was backed up
before any experiment and restored byte-for-byte afterward at SHA-256
`5ea943cfc3e2325244d2d28f6cde2293b2a2de99747ca959e609a67a646ea97e`.

A separate 90,176-byte GALE01 GCI was generated in a temporary user directory.
The initial no-mod boot showed the five locked bottom-row stages. A temporary
native ModernGekko entry hook then set only the eleven-bit stage mask at the
verified GALE01 revision-0 address `0x80459F60`. The revision-0 stage-check
function was mapped instruction-for-instruction from revision 2
`gm_80164430` to `0x80163C28`; the first revision-2 address tested was rejected
after an unchanged stage-grid comparison.

With the corrected temporary hook, all hidden stage thumbnails appeared and
Final Destination booted. Melee rewrote the isolated GCI through its normal
save path. After a full shutdown and restart with `--no-mods`, all stages and
Final Destination remained available. The temporary hook and generated GCI
remain outside the repository; no code mod was loaded for the performance run.

## Controlled Final Destination trace

The clean no-mod run used the signed portable PGO module, native arm64 runner,
Metal, 640x528 internal resolution, Cubeb audio, FIFO controller, Yoshi versus
level-1 CPU Ice Climbers, a ten-second warm-up, and the same repeated movement /
attack / jump workload used for Fountain. No screenshot, sample, or GUI action
occurred inside the selected 90-second interval.

| Metric | PGO Final Destination |
|---|---:|
| Frames | 5,312 |
| Mean | 16.941267 ms |
| Median | 16.677709 ms |
| p95 | 16.946083 ms |
| p99 | 17.189292 ms |
| Worst | 1385.242250 ms |
| Frames <=16.7 ms | 3,060 (57.61%) |
| Frames >40 ms | 3 |

Raw evidence:
`g5-buffered-pgo-yoshi-ice-final-destination-90s-render-times.txt`, SHA-256
`7884f259548cd76cb793268746d535577e0ed3d597bb3a31b6ffb8ee80bf6ab1`.

## Decision

Final Destination is no longer blocked, but G5 remains open. Median meets the
16.7 ms target by 0.022 ms; p95, p99, and worst do not. Together with the
corrected Fountain PGO trace, this establishes a shared tail/code-generation
problem rather than a Final-Destination-specific rendering bottleneck.
