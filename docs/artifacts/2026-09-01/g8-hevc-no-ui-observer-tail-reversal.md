# G8 HEVC no-UI observer-tail reversal

Date: 2026-09-01

Goal: G8 row 7

Decision: **HEVC-only exact combat passes; manual tail is observer-contingent**

## Question

PERF-283's ordinary visible route overwhelmingly ran at target cadence but
contained three isolated sub-59 reports while HEVC recording and Computer Use
state/screenshot polling were both active. Does the same exact Fountain
workload reproduce those tails under HEVC alone?

## Method

Two fresh Release Simulator processes used the already-retained diagnostic
route only to prove P1 Samus, level-1 CPU Kirby, Stock/04, 05:00, Fountain, and
active match state `02020102`. After the state barrier:

- HEVC recording started;
- controller input continued quietly through the existing FIFO;
- no Computer Use state read, screenshot, runtime-log read, profiler, phase
  logger, or other observer touched the live window; and
- the endpoint was inspected only after input and recording stopped.

This is a mechanism experiment, not an ordinary/manual acceptance run. The
private pipe and MemoryWatcher disqualify it from row-7 acceptance but make it
useful for isolating the observer tail.

## Results

### Movement-cycle run

The movement cycle reached a coherent Kirby-win result after 1:46 of combat.

| Window | Reports | FPS min / mean / max | VPS min / mean / max | Sub-59 | Underruns |
| --- | ---: | ---: | ---: | ---: | ---: |
| Full HEVC | 33 | 59.9 / 59.909 / 60.0 | 59.9 / 59.909 / 60.0 | 0 | 3 -> 11 |
| Full-work combat | 9 | 59.9 / 59.9 / 59.9 | 59.9 / 59.9 / 59.9 | 0 | 3 -> 11 |

### Held-shoulder survival run

A second fresh route held the emulated L shoulder for 0.8-second intervals,
then briefly released and attacked. It retained 3:19 of coherent exact
Fountain combat before a normal Kirby-win result.

| Window | Reports | FPS min / mean / max | VPS min / mean / max | Sub-59 | Underruns |
| --- | ---: | ---: | ---: | ---: | ---: |
| Full HEVC | 36 | 59.9 / 59.944 / 61.3 | 59.9 / 59.936 / 61.2 | 0 | 1 -> 3 |
| Full-work combat | 20 | 59.9 / 59.970 / 61.3 | 59.9 / 59.965 / 61.2 | 0 | 1 -> 3 |

Full-work combat used 125.36% mean app CPU and reached 138.5% without losing
cadence. The endpoint is a coherent results screen visibly reading 59.9 FPS.

## Interpretation

HEVC recording alone does not reproduce PERF-283's 49.4/51.0, 46.7/46.7, or
52.1/52.2 FPS/VPS reports. Across 69 combined HEVC-only reports—including 29
full-work combat reports—none falls below 59.9 FPS/VPS. This rejects the
recorder and the exact product workload as sufficient causes of those tails.

The reversal does not prove that Computer Use screenshot capture is the sole
cause; route input and match duration differ. It does prove that the tails are
observer-contingent rather than a repeatable sustained static-core or Metal
limit. No product optimization follows from them.

The only remaining row-7 performance acceptance step is one ordinary
human-controlled uninterrupted five-minute match with a short HEVC recording
and no Computer Use polling during combat. Reopen host-tail attribution only
if that route visibly repeats a sub-59 interval.

## Evidence and cleanup

- movement HEVC SHA-256:
  `44871253474867f8720db40174cdccfa7203f8e0da4986d5ce1e634d49f3d5b6`;
- movement endpoint SHA-256:
  `b42a78a6b0b5aecf8720cefc8bc102f67c3fd45364e6bbb656add99b3f33572f`;
- shield HEVC SHA-256:
  `8f499c033b81f0f384f20ec2ae8b940a203ed90c4ad7b7da0d092fbcc045153a`;
- retained shield-results screenshot SHA-256:
  `fef0ea704537dd21ee5fa20cf6254fda70916fccdf7bea1e629866bd41397e51`;
- movement/shield runtime-log SHA-256:
  `fcafbfcc5e45709b8178af024611b4a87fa904c7ac5ddecc11846e11f8b40221` /
  `c24382ef3d8c0a273591721abbc0c3c63abdc12c91d12e8102a53d13d0924f6d`.

The app was stopped, the temporary short symlink was removed, one Simulator
remains booted, and ordinary GCI was restored to SHA-256
`0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
No ROM, save, module, log, or video is tracked.
