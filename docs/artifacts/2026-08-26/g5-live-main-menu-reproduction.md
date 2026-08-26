# G5 live Main Menu reproduction

Date: 2026-08-26

## Question

The user again observed clearly major menu slowdown. Does the restored
canonical product currently sustain a low frame rate in the animated Main
Menu, and are the already-recorded multi-second scene gaps the same symptom?

## Controlled route

The restored signed macOS runner and canonical module were started directly,
with the ordinary user configuration and extracted GALE01r0 data. Only the
default-off frame-phase logger was enabled. MemoryWatcher started before the
runner and drove the genuine 134-second title lockout through Main Menu and VS
CSS. Computer Use then used deliberate one-second B presses to return through
VS Mode to the animated Main Menu. No candidate module or Simulator ran.

Computer Use visibly observed:

- the opening/title animation at 59.9 FPS;
- an opening-demo combat scene briefly titled 58.6 FPS;
- coherent four-slot VS CSS at 59.9 FPS;
- coherent VS Mode and Main Menu animation at 59.9 FPS.

Short B taps were missed, while one-second presses were accepted. That is an
input-duration issue and is not attributed to rendering performance.

## Steady Main Menu result

The untouched Main Menu bracket covered frames 13,064-18,105 (5,042 frames):

| Metric | Result |
|---|---:|
| Mean / FPS | 16.684521 ms / 59.936 FPS |
| p50 / p95 / p99 | 16.677583 / 16.946444 / 17.345228 ms |
| Worst | 102.551834 ms |
| Frames <=16.7 ms | 57.358% |
| Frames >25 / >50 ms | 4 / 1 |
| Worst rolling 1 / 2 / 5 / 10 seconds | 59.294 / 59.601 / 59.806 / 59.873 FPS |

This run does not reproduce a sustained 12.5-30 FPS Main Menu state. It does
reproduce a visible 102.6 ms hitch, so the menu is not promoted as perfectly
paced or accepted as G5 proof.

## Transition result

The complete cold route contained five CPU-bound present gaps:

| Frame | Total | CPU wall | CPU thread | Native dispatches | Guest cycles |
|---:|---:|---:|---:|---:|---:|
| 6,129 | 3,716.970 ms | 3,692.725 ms | 2,421.992 ms | 85,321,318 | 1,791,748,264 |
| 7,350 | 2,585.453 ms | 2,568.767 ms | 1,703.576 ms | 62,663,357 | 1,256,703,271 |
| 7,913 | 2,971.187 ms | 2,952.572 ms | 2,201.785 ms | 91,847,667 | 1,443,086,016 |
| 11,254 | 1,902.067 ms | 1,889.809 ms | 1,426.707 ms | 57,536,924 | 924,140,564 |

Frame 1 was an additional 3.208-second cold-start row and is excluded from the
menu-transition set. Metal present time in the four listed rows was only
0.019-0.031 ms. Like the earlier captures, each row aggregates many ordinary
guest frames while presentation is absent. The visibly major transition
freezes are therefore real, but they are distinct from steady animated-menu
throughput and from the Fountain strict-tail miss.

## Decision

**SUSTAINED MAIN MENU COLLAPSE NOT REPRODUCED; MULTI-SECOND TRANSITION FREEZES
REPRODUCED; 102.6 MS MAIN MENU HITCH REPRODUCED; G5 OPEN; G6 BLOCKED.**

Do not use the 59.9 title alone to claim menu stability. Do not retry the
rejected fast-disc setting: it did not remove these rows. The next menu work
must capture the user's sustained low-FPS state if it recurs, while the active
G5 optimization remains the coherent generated-dispatch/codegen path required
to improve Fountain's strict tail.

The runner closed cleanly and no Simulator remained. Temporary evidence:

- `phase.csv` SHA-256
  `a8aba0b474644a9e8b8ec661f7ae8407b7616d65e87d4adaf37d18a9925a37bf`
- `route.log` SHA-256
  `3ca65b4c79513640e1d445e95b415dd6dc3edb6c7b6b8890a58688fc7f06ddb9`
