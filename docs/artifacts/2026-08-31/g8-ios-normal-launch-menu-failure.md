# PERF-246 — normal-launch menu/CSS failure

Date: 2026-08-31  
Goal: G8 row 7 (audio continuity and product-speed acceptance)  
Decision: **FAIL remains; the cold front end is now a separate controlling phase**

## Question

Does the current control build remain near full speed while a user launches the
installed iPad Simulator app normally and navigates the visible front end, or is
the previously measured Fountain failure preceded by another user-visible slow
phase?

## Method and identity

- One booted iPad Pro 13-inch (M5) Simulator on iOS 26.5.
- Normal installed product process and default touch overlay; no savestate and
  no private pipe-input mode.
- Control module size: 81,006,192 bytes (the retained `af1364e6...` control).
- Visible overlay presses traversed the opening/title, main menu, VS menu, Melee
  menu, and character select.
- The complete private runtime log is retained outside Git as
  `/private/tmp/ssbmpad-perf246-normal-touch-route.log`, SHA-256
  `f260b625f521aac1a252079aabb8ab8df41bd18ca4068d2a010b7413582cea3f`.
  No game image, module, save, or private path is committed.

This run did not reach a valid matched Fountain combat setup, so it is not a
replacement for the user's retained 21.9 FPS Fountain control and makes no new
combat-performance claim.

## Result

The normal front-end route itself fails the row-7 threshold during visible
transitions:

| Runtime time | FPS | VPS | Speed ratio | DMA underruns |
|---|---:|---:|---:|---:|
| 16:26:41 | 59.9 | 59.9 | 1.000 | 10 |
| 16:26:51 | 51.0 | 51.1 | 0.853 | 20 |
| 16:27:01 | 49.1 | 57.6 | 1.026 | 41 |
| 16:27:11 | 59.9 | 59.9 | 1.001 | 41 |
| 16:27:21 | 58.9 | 58.9 | 0.970 | 41 |
| 16:27:51 | 52.6 | 60.0 | 1.000 | 54 |

The first transition contains two consecutive sub-59 FPS intervals and adds
31 underruns before recovering. A later transition again presents only 52.6
FPS and adds 12 underruns even though emulation VPS remains 60.0. This proves
that the current build has at least two distinct visible failure classes:

1. presentation/audio disruption during normal front-end transitions; and
2. the already retained sustained emulation/audio collapse in Fountain combat.

A later stable character-select screen cannot erase either failure.

## Loop correction

The row-7 protocol now treats moving opening/attract content, title/menu
transitions, CSS/stage selection, match loading, and combat as independent
acceptance phases. The threshold begins when the product starts presenting
moving game content, not only after the first combat frame. Instrumented pipe
routes remain diagnostic-only; before they can qualify a candidate, the same
binary must pass the cold normal touch-driven route.

The next optimization cycle must first reproduce and split the slowest normal
route. If Fountain remains slower, it controls the generated-code experiment;
if a front-end transition is independently diagnosed, that experiment must
reverse the exact transition without regressing Fountain. No average or warmed
tail can combine the two failures into a pass.

## Cleanup

The app was stopped and `SSBMPAD_EXTERNAL_PIPE_INPUT` was removed from the
Simulator launch environment. The product configuration and private Dolphin
settings were restored; this step changes documentation only.
