# G5 tail trigger and audio-null rejection

Date: 2026-08-27

## Question

The gather-check A/B/A had a 129-132 ms worst frame in all three runs. Was
that a recurring M1 scheduler stall, an audio callback event, or part of the
ordinary 17-19 ms Fountain tail?

## Triggered System Trace screen

The retained default-off 60-field trigger was armed only after a readiness-
gated load of the same Pikachu/CPU-Fox Fountain state. An all-process Xcode
System Trace used a rolling three-second window so context switches and thread
states immediately around a qualifying <55 FPS interval could be retained.

The first attempt exposed a harness error rather than a game event. Without an
explicit `--time-limit`, `xctrace` recorded only six seconds and spent the rest
of the bounded wait saving. The <55 FPS marker appeared only after timeout,
while the profiler was being torn down. Frames then expanded to 25-57 ms with
unchanged guest work. The trace had already ended and could not attribute the
cluster. It is rejected as observer teardown, not retained evidence.

The corrected attempt set a 120-second recording lifetime and stopped the
runner before profiler teardown on timeout. Ninety armed seconds produced no
marker. The runner exited normally, no teardown marker appeared, and macOS
reported no thermal or performance warning. This rejects a frequently
recurring whole-machine stall but does not prove that the rare event cannot
recur.

Reconciliation of the prior A/B/A shows that its worst row was not random:
all three occurrences were emulated frame `48436` with identical guest work
(3,678,553 cycles, 127,447 dispatches, and 2,325 bursts). CPU-thread work was
only 13.8-14.0 ms, but CPU wall was 128.8-131.7 ms and the frame accumulated
the only 7.0-8.4 ms audio-mix burst in each window. That justified an audio
backend control, but not an audio product edit.

## Exact Cubeb / no-output / Cubeb reversal

The first command used the invalid backend spelling `Null`; the runtime
correctly rejected it and fell back to Cubeb. That run is retained as Cubeb A,
not mislabeled as a candidate. The actual Dolphin identifier is
`No Audio Output`.

Cubeb A, no-output, and Cubeb A2 used the same PGO module and state, held the
controller FIFO writer open, selected the last occurrence of emulated frames
`48123..48562`, and matched exactly:

- 1,501,629,399 guest cycles;
- 51,369,928 native dispatches;
- 905,572 bursts; and
- 882 hook fallbacks.

| Metric | Cubeb A | No audio output | Cubeb A2 |
| --- | ---: | ---: | ---: |
| Mean | 16.684553 ms | 16.684921 ms | 16.687118 ms |
| p95 | 17.599196 ms | 17.667642 ms | 17.630748 ms |
| p99 | 18.158385 ms | 19.276647 ms | 18.394674 ms |
| Worst | 20.334500 ms | 27.013125 ms | 20.348125 ms |
| CPU-thread mean | 11.715388 ms | 11.962443 ms | 11.650360 ms |
| CPU-thread p95 | 12.739635 ms | 13.956084 ms | 12.925057 ms |
| Audio-mix mean | 0.620455 ms | 0.000000 ms | 0.754306 ms |
| Audio-mix worst | 1.373709 ms | 0.000000 ms | 1.424000 ms |
| Frames <=16.7 ms | 54.318% | 53.182% | 53.864% |

No-output removes mixer work as intended but loses p95, p99, worst, CPU mean,
CPU p95, and the <=16.7 ms share against both Cubeb brackets. Frame `48436`
is 16.36/16.55/16.49 ms in the fresh trio; the old 129 ms event did not recur
in either Cubeb reversal. The no-output run therefore cannot receive causal
credit for removing it.

## Upstream and Smooth Early Presentation screen

The pinned Dolphin fork is based on `e13ab348f13cd67879f6db6e9d7185410f8f62c6`
(2026-07-28). Current official Dolphin master was fetched read-only at
`4f8af23db516d8b6e9cd00e7b261a65b026514a8` (2026-08-27). The relevant
Metal, Cubeb, and timer diff contains only a CoreTiming include rename and
frame-buffer metadata/layout work; it has no newer scheduling mechanism that
addresses this tail. A broad upstream merge is therefore not justified.

The pinned base already contains `SmoothEarlyPresentation`. An isolated
`SmoothEarlyPresentation=True` run matched the Cubeb controls at exactly
1,501,629,399 cycles, 51,369,928 dispatches, 905,572 bursts, and 882 hook
fallbacks. It measured 16.682863 ms mean, 17.699800 ms p95, 18.362257 ms p99,
31.299666 ms worst, and 55.455% of frames at or below 16.7 ms. CPU-thread
mean/p95 were 11.626638/12.885785 ms. Compared with both unmodified Cubeb
brackets, p95 and worst are worse; reject the setting. `Rush Frame
Presentation` was not tested because Dolphin's own setting documentation says
it changes throttle cadence and generally worsens pacing, so it does not
preserve the measured control.

## Decision

**Reject no-audio output and do not change Cubeb from this evidence.** Audio
is required by G5, and disabling it also makes the measured tail worse. The
old 129-132 ms row is a real, content-aligned environmental event worth
tracking, but it is not the steady p95 cause and is not reproducible in the
fresh matched reversal.

G5 remains open because both Cubeb controls still exceed 16.7 ms at p95,
p99, and worst. The upstream and hidden-presentation screens found no
retained scheduling change. Final Destination is not run; G6 remains blocked.
The next experiment must return to the exact generated-code evidence rather
than retry audio or presentation settings.

## Retained evidence

- `docs/evidence/g5-audio-null-rejection/cubeb-a.phase.csv` — SHA-256
  `242c59f8eb33dd865ece34eba8d21b85a981f28ed74899292a80ce6a82c94c32`;
- `docs/evidence/g5-audio-null-rejection/null-audio.phase.csv` — SHA-256
  `500f9f8aad6964daeee8327012c9341c60e58836d76c865bd633343831efb4e5`;
  and
- `docs/evidence/g5-audio-null-rejection/cubeb-a2.phase.csv` — SHA-256
  `19a941a330570f3172f665897e845fee1bfd56046bb4342cb235b6fbf69f4612`;
  and
- `docs/evidence/g5-audio-null-rejection/smooth-early.phase.csv` — SHA-256
  `8b377406e3cce8bb758e4c1f3417913bf205432061d18c77b4fe529ae71778fd`.

System Trace bundles and RAM-bearing savestates remain local and excluded.
