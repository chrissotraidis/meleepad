# G5 same-process active-transition pacing

Date: 2026-08-26

## Question

The prior five-minute CSS soak had substantially higher timer wake lateness
while the app was obscured than a separate raised-window run. Does that
difference actually follow application focus inside one unchanged process?

## Method

The restored normal signed package used the corrected module and the existing
MemoryWatcher route to reach verified VS CSS. In that single process, Computer
Use raised MeleePad, raised Activity Monitor to obscure it, and raised MeleePad
again. Each state was held for at least two minutes. Because the phase writer
is buffered, the retained comparison uses only the final 3,600 complete rows
from snapshots taken at the end of each stable state.

No runtime, module, renderer, audio, timer, QoS, or process-activity setting
changed between segments.

## Result

| Metric | Foreground 1 | Background | Foreground 2 |
|---|---:|---:|---:|
| Mean / FPS | 16.683286 ms / 59.940 | 16.683312 ms / 59.940 | 16.683328 ms / 59.940 |
| p95 | 16.911721 ms | 16.927723 ms | 16.933971 ms |
| p99 | 17.210464 ms | 17.209359 ms | 17.197952 ms |
| Worst | 19.008958 ms | 19.337708 ms | 23.264000 ms |
| Frames <=16.7 ms | 58.000% | 57.417% | 57.417% |
| CPU-thread mean | 8.513234 ms | 8.474156 ms | 8.561078 ms |
| Wake lateness mean | 0.077155 ms | 0.072065 ms | 0.074139 ms |
| Wake lateness p95 | 0.134182 ms | 0.133020 ms | 0.133433 ms |
| Frames >25 / >50 ms | 0 / 0 | 0 / 0 | 0 / 0 |

The background tail is statistically the same as both foreground tails. The
earlier cross-process association between obscured state and approximately
0.925 ms mean wake lateness did not reproduce when focus changed inside one
process. Focus state is therefore not causal evidence for the slowdown.

## Decision

**FOCUS ATTRIBUTION WITHDRAWN; ACTIVITY CANDIDATES REMAIN REJECTED; G5 OPEN;
FINAL DESTINATION NOT RUN; G6 BLOCKED.** Do not add a focus policy and do not
retry `NSProcessInfo` activity flags. The current normal menu ran continuously
at 59.940 FPS across all three states, so this run also did not reproduce the
reported sustained major slowdown.

The next diagnostic should preserve the normal product and capture the first
intermittent one-second window below 55 FPS, if one occurs, together with the
corresponding phase rows and a low-overhead native sample. This treats the
major slowdown as an intermittent state-transition problem rather than
assuming focus, renderer, or timer causality. The separate strict <=16.7 ms G5
tail remains unresolved.

## Retained artifact

- `g5-active-transition-css-phase.csv` contains the final 3,600 complete rows
  from each stable state with an added `segment` column.
