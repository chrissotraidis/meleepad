# G5 Fountain baseline and PGO investigation

Date: 2026-08-24

## Scope

This investigation measures the native arm64 macOS runner on Fountain of
Dreams with Metal, 1x internal resolution, Cubeb audio, and the reference FIFO
controller. It does not satisfy G5: the required limit is a worst presented
frame of 16.7 ms on both Fountain of Dreams and Final Destination.

The packaged app and production module were restored after every experiment.
The production module SHA-256 after cleanup is:

`5bbd12e0704d6ce2221603d3fc016eb9aba88756b88d2139809c8b6ee1b09b82`

## Clean Fountain baseline

A clean two-minute diagnostic match reached active Fountain combat and the
results screen. The first clean trace used Yoshi versus CPU Zelda. Its 5,176
active-combat frames measured:

| Metric | Clean Yoshi vs Zelda |
|---|---:|
| Mean | 19.552338 ms |
| Median | 19.325875 ms |
| p95 | 22.862167 ms |
| p99 | 28.010209 ms |
| Worst | 111.083041 ms |
| Frames <= 16.7 ms | 193 / 5,176 (3.73%) |

The visible counter was roughly 50.1-50.4 FPS in active combat. A process
sample attributed 3,408 of 3,876 sampled CPU-thread stacks to generated
`chassis_dispatch` work (about 88%). Metal draw/present stacks were a small
minority. Fountain is CPU-bound in the generated game module.

Evidence:

- `g5-fountain-clean-active.png`
- `g5-fountain-clean-sample.txt`
- `g5-fountain-clean-render-times.txt`
- `g5-fountain-clean-render-times-sparse.txt`

The sparse source is retained because truncating an already-open log left the
file descriptor at its old offset. The zero-stripped companion is the measured
trace. Later comparisons rotate the log before launch and use line boundaries.

## Isolated PGO experiment

The C backend was rebuilt outside the production cache with AppleClang
instrumentation, strict floating-point flags, O2, and ThinLTO:

`-O2 -ffp-contract=off -fno-fast-math -flto=thin`

An instrumented Fountain match exercised boot, menus, movement, jumps,
normals, and specials. Clean shutdown produced a 43 MB `.profraw`, merged to a
22 MB `.profdata` containing 6,531 functions and 2,733,180 blocks. The hottest
counts were generated `get_ram_ptr`, `bswap32`, `mem_read32`,
`loop_80349494`, and `chassis_dispatch`, consistent with the process sample.

The profile-use candidate was then built with the same O2, strict FP, and
ThinLTO settings. The candidate was installed only for controlled runs and was
removed afterward.

## Initial comparison (measurement-confounded)

The useful controlled pair is Yoshi versus CPU Ice Climbers on Fountain. Both
traces use an equal 110.0 seconds of active combat and exclude the
match-to-results transition.

| Metric | Clean | PGO candidate | Change |
|---|---:|---:|---:|
| Frames | 5,098 | 5,688 | +590 |
| Mean | 21.576785 ms | 19.335680 ms | 10.4% lower |
| Median | 21.499666 ms | 19.669708 ms | 8.5% lower |
| p95 | 24.931458 ms | 22.447500 ms | 10.0% lower |
| p99 | 30.173750 ms | 25.534250 ms | 15.4% lower |
| Worst | 86.467083 ms | 129.739542 ms | regression |
| Frames <= 16.7 ms | 80 (1.57%) | 695 (12.22%) | +10.65 points |
| Frames > 40 ms | 7 | 1 | 6 fewer |

Raw equal-window evidence:

- `g5-clean-iceclimbers-fountain-110s-render-times.txt` — SHA-256
  `6cb12e78037804a67cd62c922edf8aed69647048c6301a0fd3952578a5796633`
- `g5-pgo-iceclimbers-fountain-110s-render-times.txt` — SHA-256
  `d2864853e03db121977976669800bac9b5acbf9d1c7d0bea4f1551a5aca793bf`

This comparison predates the buffered frame logger and allowed visual evidence
capture to perturb the full run. Its worst-frame conclusion is therefore
superseded by the corrected pair below.

## Corrected buffered comparison

The logger correction described in `g5-render-logging-control.md` removes the
per-frame stream flush. Both corrected windows use the same native arm64
runner, Metal, 640x528, Cubeb audio, FIFO controller, Yoshi versus level-1 CPU
Ice Climbers, Fountain, ten-second warm-up, and repeated 90-second movement /
attack / jump workload. No screenshot, sample, or GUI action occurs inside
either selected interval.

| Metric | Clean | PGO candidate | Change |
|---|---:|---:|---:|
| Frames | 4,948 | 5,394 | +446 |
| Mean | 18.187197 ms | 16.683219 ms | 8.3% lower |
| Median | 17.903042 ms | 16.682250 ms | 6.8% lower |
| p95 | 21.168417 ms | 16.846334 ms | 20.4% lower |
| p99 | 21.998833 ms | 17.030541 ms | 22.6% lower |
| Worst | 55.134917 ms | 45.424584 ms | 17.6% lower |
| Frames <=16.7 ms | 662 (13.38%) | 3,292 (61.03%) | +47.65 points |
| Frames >40 ms | 1 | 1 | unchanged |

Raw corrected evidence:

- `g5-buffered-clean-yoshi-ice-fountain-90s-render-times.txt` — SHA-256
  `1402c6c808814de8546379805af3b3fa499d825d75d38ad1c561f17b7309fba9`
- `g5-buffered-pgo-yoshi-ice-fountain-90s-render-times.txt` — SHA-256
  `ab67cfe79805b9c217925e93bc08ae7d5941c0a87d64c7f224d2548f0764036b`

The initial PGO artifact targeted the host default macOS 26. It was rebuilt
from the same local profile with `MACOSX_DEPLOYMENT_TARGET=14.0`. A 30-second
portable-module confirmation reproduced the original PGO interval almost
exactly: 16.682590 ms mean, 16.682291 ms median, 16.874583 ms p95,
17.195042 ms p99, and 21.963375 ms worst, with no frame above 40 ms. The signed
portable module installed in the local app is SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.

## Decision

The portable PGO module is **retained locally as the best-known module and as a
code-generation oracle**. It improves every corrected metric, including worst
frame. It does not meet G5: p95 is 16.846 ms, p99 is 17.031 ms, and worst is
45.425 ms rather than at most 16.7 ms.

It is also not yet a reproducible shipping optimization. The 22 MB profile was
trained from the local retail-image run and remains local under the repository's
no-game-derived-output rule (SHA-256
`d291607ab22ee48085d5587b39369a0ae9e2a639132a904d6b5d5d4570c892c6`).
The next falsifiable experiment uses the PGO binary as an oracle to reproduce
its hot-loop inlining through a static generator/runtime change. Final
Destination remains locked and unmeasured.

## Static single-loop reproduction attempt

The clean generated definition of the hottest sampled helper,
`loop_80349494`, was temporarily changed to `always_inline`. A full macOS 14
arm64 O2 + ThinLTO rebuild removed the helper symbol as intended. The candidate
was replayed with the same Yoshi-versus-level-1-CPU-Ice-Climbers Fountain
matchup, Cubeb audio, ten-second warm-up, and repeated movement / attack / jump
workload. No screenshot, sample, or GUI action occurred inside the selected
90-second interval.

| Metric | Forced-inline candidate |
|---|---:|
| Frames | 4,796 |
| Mean | 18.763255 ms |
| Median | 18.292687 ms |
| p95 | 22.040042 ms |
| p99 | 24.030541 ms |
| Worst | 1296.872542 ms |
| Frames <=16.7 ms | 1,130 (23.56%) |
| Frames >40 ms | 5 |

Raw evidence: `g5-buffered-inline-loop-yoshi-ice-fountain-90s-render-times.txt`,
SHA-256
`5e84f0d92cb55a241c82af04181d7fa3f97dc8e19a62f75e5849ad6a397e5551`.

The experiment is **rejected**. Median and tail timing are worse than the clean
buffered control, so the isolated 1296.873 ms event is not needed to make the
decision. The generated source and module cache were restored byte-for-byte,
and the signed portable PGO module was restored in the local app at SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.
