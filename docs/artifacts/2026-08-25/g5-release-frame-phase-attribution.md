# G5 release frame-phase attribution

## Question

After an LLVM-instrumented trainer was visibly running at roughly 12.5-22 FPS,
is the normal release also compute-bound, and which subsystem owns its remaining
frame-time tail on a verified Fountain of Dreams match?

## Controlled release run

- arm64 release module SHA-256:
  `a961abecf0129a3758ee87711614046768ef30035f2fd79170563852e916d87f`
- Metal graphics, Cubeb audio, no mods, isolated revision-0 user directory
- visible route: VS Character Select -> explicit `Fountain of Dreams`
  highlight -> live Pikachu-versus-CPU combat
- the window title held approximately 59.9 FPS during the verified match
- no Simulator was booted

The dependency-only logger is enabled by `MELEEPAD_FRAME_PHASE_LOG`. It buffers
CSV rows at the real present boundary and records present-to-present time,
static-recompiler CPU-loop wall time, configured guest-idle time, throttle
sleep, video construction, backbuffer presentation, and audio mixing. It does
not flush per frame.

The first 5,814-frame interval did not yet separate throttle sleep. It measured
16.683 ms mean, 17.229 ms p95, 17.460 ms p99, 77.213 ms worst, and 52.976% of
frames at or below 16.7 ms. CPU-loop wall time correlated 0.9992 with total
frame time, but source review showed that `CoreTiming::Throttle()` sleeps from
inside that measured loop. Calling the entire interval active compute was
therefore withdrawn before selecting an optimization.

The corrected 4,094-frame combat interval measured:

| Phase | Mean | p95 | p99 | Worst |
|---|---:|---:|---:|---:|
| Present-to-present | 16.683 ms | 17.237 ms | 17.496 ms | 19.112 ms |
| CPU-loop wall | 16.669 ms | 17.229 ms | 17.481 ms | 19.039 ms |
| Throttle sleep | 8.088 ms | 9.681 ms | 10.535 ms | 12.391 ms |
| CPU compute (`wall - throttle - guest idle`) | 8.574 ms | 9.875 ms | 10.924 ms | 16.714 ms |
| Video construction | 0.055 ms | 0.076 ms | 0.104 ms | 0.232 ms |
| Backbuffer present | 0.022 ms | 0.048 ms | 0.067 ms | 0.260 ms |
| Audio mix | 0.780 ms | 1.279 ms | 1.312 ms | 1.464 ms |

Only 53.395% of these frames met 16.7 ms, so G5 remains open. CPU compute had
only 0.0794 correlation with total frame time. The release normally has about
6-8 ms of CPU headroom and deliberately sleeps to hold Melee's approximately
59.94 Hz rate. This run does not support the prior blanket statement that the
current release is CPU-bound.

## Small pacing experiment

Dolphin's existing precision-frame-timing path was already enabled. A bounded
Apple-only experiment increased the final sleep/spin window from 1.02 ms to
2.02 ms. A 1,779-frame active-scene screen regressed present-to-present p95 to
19.314 ms, p99 to 19.852 ms, worst to 21.880 ms, and the <=16.7 ms share to
50.084%. The change was rejected and removed; the normal runner was rebuilt.

## Outcome

The very low visible trainer frame rate was instrumentation overhead, not the
release product rate. The normal release is approximately 59.9 FPS but still
fails the strict G5 tail rule. Metal, present, audio mixing, and steady guest
compute do not explain that tail in this interval, and increasing precision
spin made it worse.

`VISUAL-001B` remains independent and promotion-blocking: the same 59.9 FPS
release continued to show impossible Fountain scale/displacement. The next
source investigation is the first divergent geometry/state frame against a
matched reference, while the frame-phase logger remains available for any
future performance regression.
