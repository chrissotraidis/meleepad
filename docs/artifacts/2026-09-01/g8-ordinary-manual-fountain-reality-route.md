# G8 ordinary manual Fountain reality route

Date: 2026-09-01

Goal: G8 row 7

Decision: **PARTIAL — sustained 20 FPS failure reversed; strict route still open**

## Question

Does the ordinary installed Release product, driven only through its visible
touch overlay, clear the user's 21.9 FPS Samus-versus-CPU-Kirby Fountain anchor
without a savestate, MemoryWatcher, external input pipe, profiler, or developer
performance mode?

## Product and controls

- one booted iPad Pro 13-inch (M5) Simulator, iOS 26.5;
- ordinary `com.ssbmpad.SsbmPad` Release launch and stable default profile;
- P1 Samus, level-1 CPU Kirby, Stock/04, 05:00;
- Fountain of Dreams selected and confirmed visibly before each qualifying
  attempt;
- all menu, CSS, rules, stage, and combat input delivered through the shipped
  overlay's accessibility actions;
- no diagnostic environment, private input FIFO, savestate, MemoryWatcher, or
  runtime profiler; and
- HEVC screen recording retained outside Git because it is 4,180,118,614 bytes.

The VoiceOver/custom-action main-stick pulse was reduced from 180 ms to 50 ms.
The old pulse crossed multiple CSS icons and could not reach the narrow P2
selector. This changes neither real finger input nor physical controllers. A
focused source regression and fresh Release Simulator build pass.

## What visibly worked

- The complete ordinary UI path set Stock/04/05:00 and selected Samus plus a
  level-1 CPU Kirby without hidden state.
- Multiple Fountain matches loaded, accepted movement, attacks, jumps,
  shoulders, and shield input, reached results, and returned to Character
  Select with coherent characters and stage geometry.
- The exact Fountain attempts total more than eleven minutes of visible combat.
  Individual matches ended at 2:13, 3:19, 2:12, 1:26, and 2:06 because the UI
  automation lost all four Samus stocks; no single attempt therefore supplies
  the required five uninterrupted minutes.
- Background/resume retained the CSS and logged `willResignActive`,
  `didEnterBackground`, `willEnterForeground`, `didBecomeActive`, and speaker
  audio reactivation.
- The ordinary GCI was restored after shutdown to SHA-256
  `0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.

## Runtime result

Across the retained 17:24:00–17:45:50 UTC recording window:

| Measure | Result |
| --- | ---: |
| Runtime reports | 132 |
| FPS mean / min / max | 59.7023 / 46.7 / 63.0 |
| VPS mean / min / max | 59.7061 / 46.7 / 63.0 |
| Speed mean / min / max | 0.9996 / 0.785 / 1.085 |
| Reports below 59 FPS | 3 |
| Reports below 59 VPS | 3 |
| DMA underruns | 56 -> 100 |

The three sub-threshold reports are isolated:

- 17:25:40: 49.4 FPS / 51.0 VPS / 1.085 speed, followed immediately by
  59.9/59.9. This is a delayed/catch-up interval during full Fountain work, not
  recurrence of the controller busy loop.
- 17:27:20: 46.7/46.7 / 0.785 speed during a light results/menu interval with
  only about 58% app CPU, followed immediately by 59.8/59.9.
- 17:41:00: 52.1/52.2 / 0.862 speed during full work, followed immediately by
  60.0/59.9.

Every other report is at or above 59 FPS/VPS. This strongly reverses the old
sustained 20–36 FPS architecture failure, but the written row-7 rule treats any
moving sub-59 interval as failure. The ordinary manual route therefore remains
PARTIAL.

## Evidence integrity

- Runtime log SHA-256:
  `8606eda7b0b1014e483af62d288cb69873425806806c847dc2f0f54bf23c4059`
- Private HEVC recording SHA-256:
  `f4b9123f569b3beb37eddd41e1fc1e5c2a01a849f82bbb15bd985b1fb7abf414`
- Results screenshot SHA-256:
  `4ba0ac9ddc2c3664be086e3623d1ac9f20a4875b57c0fc38e49815b2c3e2ff62`

The recording, ROM, module, save, and full runtime log stay outside Git. The
retained repository screenshot contains no private path or game data beyond a
runtime frame.

## Reorientation

The next step is not another static-recompiler rewrite. The measured
controller-wait mechanism is fixed, normal observer-free attract play passes,
and more than 97% of this heavily observed window reports target cadence.

The remaining row-7 work is:

1. one ordinary human-controlled five-minute exact Fountain match, so control
   skill does not terminate the run early;
2. retain a shorter recording and the same-run runtime log; and
3. if an isolated sub-59 report repeats visibly, attribute that exact host-wait
   interval. Reopen CPU architecture work only if the repeated interval is
   on-core, CPU-heavy, sustained, and distinct from the corrected controller
   wait.

Do not claim stable 60 FPS, physical-iPad promotion, or row-7 completion from
this partial result.
