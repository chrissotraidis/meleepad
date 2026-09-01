# G8 attract-only dispatch delta

Date: 2026-09-01

Status: **EXACT ROSTER PASSES; ATTRACT DELTA IS PROVISIONAL PENDING SAMPLE DE-ALIASING**

## Question

Does the retained Big Blue slowdown follow the exact
Ness/Peach/Ice Climbers/Bowser roster, or does attract/demo state execute a
different and narrower workload?

## Controlled exact-roster result

The isolated unlock GCI was installed only after preserving the ordinary
Simulator GCI. The controlled route visibly selected:

- P1 Ness;
- CPU Peach;
- CPU Ice Climbers; and
- CPU Bowser.

The game visibly labeled the selected stage `F-Zero Grand Prix / Big Blue`.
The no-logger live match held 59.9 FPS from early combat through the final
thirty seconds. This refutes the exact roster, four-player AI, and Big Blue
geometry together as a sufficient cause of the ordinary 21-35 FPS collapse.

A default-off Simulator state was retained and loaded in two fresh diagnostic
processes. Across 3,000 active exact-roster rows in the matched one-in-4,096
dispatch-sampling arm:

| Metric | Mean | Median | p95 |
| --- | ---: | ---: | ---: |
| Total frame | 16.690 ms | 16.679 ms | 17.073 ms |
| CPU thread | 14.025 ms | 13.844 ms | 16.072 ms |
| CPU wall | 16.121 ms | 16.112 ms | 16.403 ms |
| Video build | 0.050 ms | 0.045 ms | 0.082 ms |
| Metal present | 0.226 ms | 0.222 ms | 0.439 ms |
| Static guest cycles | 5,808,922 | 5,792,125 | 6,561,491 |
| Native dispatches | 177,545 | 177,908 | 200,595 |

The dispatch observer is attribution evidence, not product FPS evidence. The
ordinary no-logger visible arm controls the 59.9 FPS statement.

## Matched attract delta

The retained PERF-271 attract window has 96.85 one-in-4,096 samples per frame.
The exact-roster window has 43.32, a 2.24x ratio consistent with the measured
416,000 versus roughly 178,000 native dispatches. The extra work is highly
concentrated. Five 16 KiB regions account for approximately 52.50 of the 53.53
additional samples per frame, or 98.1% of the incremental dispatch stream:

`scripts/analyze-dispatch-delta.py` reproduces the normalized region and PC
ranking from the two retained CSV windows; its focused regression is part of
`scripts/check-repository.sh`.

| Region | Attract samples/frame | Exact samples/frame | Increment |
| --- | ---: | ---: | ---: |
| `0x80018000-0x8001BFFF` | 17.820 | 0.009 | 17.811 |
| `0x80344000-0x80347FFF` | 14.819 | 0.077 | 14.742 |
| `0x80338000-0x8033BFFF` | 10.961 | 1.903 | 9.058 |
| `0x80374000-0x80377FFF` | 6.955 | 0.447 | 6.508 |
| `0x801A4000-0x801A7FFF` | 4.387 | 0.008 | 4.379 |

This ranking is **provisional**. Raw rows repeat a nearly identical 23-PC
motif within and across frames. Because the observer selected every 4,096th
native dispatch, a periodic guest path can phase-lock to that power-of-two
stride and exaggerate a subset of PCs. The normalized dispatch-count delta is
real, but the five-region concentration is not safe architecture-selection
evidence until it repeats with a coprime interval and multiple offsets.

The largest PC deltas are `0x80345760` and `0x80345738`, each adding about
7.4 samples per frame and appearing roughly 200-250 times more often than in
the controlled match. Generated-code inspection identifies these as the
interrupt disable/restore path despite a coarse symbol entry naming the
enclosing range `OSPanic`. Other attract-only leaders map into Melee DVD/load
and pad-timing work (`lbDvd_80018F68`, `lb_8001955C`, `lb_80019628`), a DVD
state callback (`cbForStateGettingError`), the game-mode loop
(`gm_801A4014`), and `HSD_EraseRect`.

This does not yet prove which operations dominate host time; sample frequency
is not a cycle-accurate cost model. It does prove that the previous provisional
eight-region universal rewrite was selected from the wrong denominator. The
incremental attract deficit has a five-region corpus with an explicit passing
control.

## Reoriented decision

Do not optimize the controlled roster and do not begin an eight-region
whole-game rewrite. First repeat the same attract/control comparison at the
coprime interval 4,093 with at least two offsets. Accept a region into the
corpus only when its normalized excess repeats across phases. Patch 0037 adds
default-off interval and offset controls while preserving the product's
4,096/0 diagnostic default.

Only after that de-aliasing gate, build a data-free region-resident preflight
over the surviving attract-excess regions, beginning with the repeated
DVD/interrupt loop if it remains dominant.
Preserve arbitrary entry, exception, cycle, SMC, helper, and state/RAM
semantics. Compare the canonical path and region-resident path on exact traces
from both attract and controlled windows.

The first candidate earns a product module only if it:

1. passes full state/RAM/cycle/exception equivalence;
2. reduces the selected attract-path host time by at least 35%;
3. projects at least 25% whole-frame CPU gain using measured attract time, not
   dispatch count alone;
4. leaves the controlled exact-roster path neutral within run variance; and
5. retains a credible composition path to the approximately 50% CPU reduction
   required by the ordinary failure.

If the first three regions cannot meet those gates, extend the same preflight
to `0x80374000` and `0x801A4000`. If all five fail, record the static-C ceiling
and stop repeating flags, PGO, or isolated helpers.

## Private evidence

No ROM, GCI, state, module, profile, log, or screenshot is tracked. Private
hashes retained outside Git:

- verified roster screenshot:
  `f0c154606799e8d844abc07e2b34922f598d1953599a1c1570e3fa2d5283de4c`;
- early live Big Blue screenshot:
  `ddc10678cdf88a48287eb705a22644e2fd73960161538b2137901e8127f27a04`;
- late live Big Blue screenshot:
  `54975c9bfba31713846dba1cba62eeae1c5a3104c99e86b33f92e0aaf691c901`;
- exact-roster state:
  `4d51afff70b5ebd1d42191e95cc79ef84047c18884e411a6ec2d255bce95355b`;
- phase/burst replay:
  `436ad11b49efc4d23a09e224541a1d3fd6c78cdd08a7b4b9fb82df1523404853` /
  `e0eab23f124aafa3c696fd48f8f042b3a9f9eba989e3a35c762aa4cfa070ae9b`;
- matched dispatch sample:
  `51f730e50901614cc620c0c9ce5d8b9c921bd17cfaf701728e24066856990494`;
  and
- matched sampled phase log:
  `e403d43b22b8639dfaf84605143611669e9ff6b1472d7ffe25f2443ce86254eb`.

The app was stopped, diagnostic environment was cleared, and the ordinary GCI
was restored at SHA-256
`0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
Row 7, physical-iPad promotion, and G9 remain closed.
