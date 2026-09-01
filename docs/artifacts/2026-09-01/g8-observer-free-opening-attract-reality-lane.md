# G8 observer-free opening/attract reality lane

Date: 2026-09-01

Status: **OPENING/ATTRACT REALITY LANE PASS; EXACT MANUAL ROUTE STILL OPEN**

## Purpose

PERF-281's exact diagnostic Fountain route contains one isolated 56.7-VPS
interval dominated by off-core wall time. This run asks whether that stall—or
the former sustained 21-36 FPS opening/attract collapse—reproduces in the
ordinary installed product without observers.

## Ordinary-product boundary

A fresh Release Simulator process launched with:

- no phase logger;
- no MemoryWatcher or short user-directory override;
- no external input pipe;
- no profiler, savestate, cheat, or recording; and
- ordinary stable product settings, including the retained GALE01 caller-
  qualified controller-wait yield.

The process ran continuously for about eight minutes through moving opening,
title/menu interaction, and multiple moving four-fighter attract scenes.

## Result

Across 49 ten-second runtime reports:

| Metric | Result |
| --- | ---: |
| FPS mean / minimum | 59.908 / 59.4 |
| VPS mean / minimum | 59.912 / 59.5 |
| Minimum speed ratio | 0.984 |
| DMA underruns | 0 -> 5, isolated transitions |
| Reports below the 59.0 acceptance floor | **0** |

Only two reports are below 59.9: 59.4/59.5 and 59.5/59.5. Both remain above
the written 59.0 FPS/VPS route threshold, recover immediately, and do not
coincide with consecutive underrun growth. There is no recurrence of the
diagnostic route's 56.7 VPS interval and no sustained collapse.

The final retained frame visibly shows a moving four-fighter Dream Land match
at 59.8 FPS with coherent Ice Climbers, Pikachu, Captain Falcon, and another
fighter. This directly reverses the prior ordinary opening/attract reality-lane
floor rather than relying on a savestate or profiler run.

## Decision

Opening/attract performance now passes the row-7 reality-lane threshold on the
normal product. Retain patch 0038. Do not reopen generated-code architecture,
M1-host blame, presentation hacks, or an exposed performance mode for the two
sub-59.9-but-above-threshold intervals.

This is not the second complete exact route and does not close row 7. The next
required evidence is the unchanged-build manual Samus/level-1-CPU-Kirby,
Stock/04, 05:00 Fountain route through menus, five minutes of active input,
results, return, audio, and lifecycle. Physical-iPad promotion and G9 remain
closed until that route passes.

## Private evidence and cleanup

No runtime log, screenshot, ROM, or save is tracked.

- runtime log:
  `6f2bd5bcb11627843fe623de4a069b958ef79b40cfc7d2a7f6547fad125e5d61`;
- final visible screenshot:
  `d2f188398a3b8a0652da73bc086c922dfb1bfe1a5aabcfa7ee8873eb64c68437`.

The app was stopped and the pre-test GCI restored at SHA-256
`0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
