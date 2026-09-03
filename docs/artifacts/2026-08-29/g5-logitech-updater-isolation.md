# G5 Logitech updater isolation

Date: 2026-08-29

Status: **SEVERE TAIL IMPROVED; FUNDAMENTAL G5 LIMIT REJECTED**

## Question

Does the persistently busy root-owned Logitech Options+ updater cause the
remaining Final Destination wall-minus-thread tail?

The updater had repeatedly consumed about 25-31% of one CPU while PERF-140
showed that slow rows lost whole-process execution rather than adding MeleePad
blocking or syscall activity. The user explicitly authorized stopping that
exact process. PID 276 was verified as the single
`com.logi.optionsplus.updater` launch daemon and entered state `Ts` at 0% CPU.
No Logitech configuration, launchd plist, application, or file was changed.

## Harness

PERF-141 used the same signed disposable native arm64 app, current-PGO module,
private Final Destination slot-1 state, controller profile, and balanced
43.2-second input sequence as PERF-140. The retained identities are:

- runner: `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`
- module: `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`
- state: `19e5d7b8d66831f2e9032797dae2ef8399f8a6593e19a020d8cde8e176c8f181`

One first invocation is excluded because `gcpipe.py` correctly rejected an
unneeded `--memory-user-dir` argument before sending combat input. Its runner
was terminated and its partial private evidence was moved aside. The accepted
rerun used the retained FIFO directly and installed an unconditional runner
cleanup trap.

Fresh private screenshots bound continuous Final Destination combat from
1:31.68 to 0:46.84. Pikachu and Yoshi remain recognizable and coherent at both
ends; the neon-magenta stage edge and changing background are normal Final
Destination presentation, not fighter morphing. The final 2,001 rows are
continuous emulated frames `31813..33813`.

## Exact result

| Metric | PERF-140 updater active | PERF-141 updater stopped | Delta |
| --- | ---: | ---: | ---: |
| Total mean | 16.684369 ms | 16.683097 ms | -0.001272 ms |
| Total p95 | 18.717375 ms | 17.194541 ms | -1.522834 ms |
| Total p99 | 19.465708 ms | 17.365208 ms | -2.100500 ms |
| Total worst | 21.867375 ms | 17.975333 ms | -3.892042 ms |
| CPU-wall p95 | 18.505130 ms | 17.059698 ms | -1.445432 ms |
| CPU-thread mean | 6.223618 ms | 6.910926 ms | +0.687308 ms |
| Wall minus CPU-thread mean | 10.336469 ms | 9.640539 ms | -0.695930 ms |
| Wall minus CPU-thread p95 | 13.199745 ms | 10.605265 ms | -2.594480 ms |
| Frames <=16.7 ms | 1,044/2,001 (52.174%) | 1,152/2,001 (57.571%) | +5.397 points |
| Frames >20 ms | 10 | 0 | -10 |

The stopped run remains at the same 59.94-FPS mean, but removes PERF-140's
long tail. Its private evidence hashes are:

- phase CSV: `bf04670f775331de9829a0beafae855085987901f4ca68e866a7be5ae8aebc0c`
- start image: `c0600482a5bcb235160504dce6890a41d11562a1aca7c9b9be9f57c1a3973a0b`
- end image: `77488e4b0f1f654256c17fcf83fb3469a7eb8f1440a0b892153bece5cdeca282`

No ROM, save, module, app, screenshot, or private timing log is committed.

## Decision

The updater is a plausible contributor to intermittent severe stutter, but it
is not the fundamental limiter: with it fully stopped, Final Destination still
measures 17.194541 ms p95, 17.365208 ms p99, and 17.975333 ms worst. This is not
a same-session A/B/A reversal because the user directed that the Logitech
process remain stopped, so do not claim exclusive causality for the tail
improvement.

Retain no MeleePad product change and do not optimize Logitech behavior inside
the repository. Continue G5 from the residual required-stage pacing failure;
G6 remains blocked.
