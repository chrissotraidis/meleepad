# G5 host-time join and logger-free display cadence

Date: 2026-08-28

Status: **ordinary cadence isolated; G5 still fails**

## Question

PERF-124 proved rare onscreen misses but could not align them exactly to the
emulator, and it still had the existing phase logger enabled. Are the 33 ms
holds late game frames, display-rate conversion, or diagnostic overhead?

## PERF-125 exclusion

The first disposable wrapper exited before boot because its implicit current
user/game path was not the isolated PERF path. It produced no trace and is not
a performance result.

## PERF-126 shared host clock

Canonical patch 0021 adds `host_frame_end_unix_ns` to the default-dormant
phase CSV. It reconstructs the wall-clock time at the already measured
`frame_end` from adjacent steady/system clock reads. When
`SSBMPAD_FRAME_PHASE_LOG` is absent, no new code executes in the frame path.

PERF-126 used the exact retained Fountain state, isolated `user-114`, Game
Mode/fullscreen, native resolution, the prewarmed frontend-PGO module, and the
Display-only Instruments observer. Its 115.392-second trace retained:

- 6,848 process-attributed display intervals over 114.981135 seconds;
- p95/p99 16.666368/16.666624 ms;
- 6,831 intervals at or below 16.7 ms, 13 at 33.333 ms, and four longer gaps;
- 6,860 queued swaps versus 6,852 displayed swaps; exactly eight queued
  surfaces were not displayed; and
- 6,856 phase rows inside the Display trace's absolute time range.

The join separates two mechanisms.

### Fixed-rate conversion

Seven queued surfaces were not displayed before the result transition over
about 110 seconds. A 59.94 Hz source feeding a 60.0 Hz fixed panel predicts
6.6 rate-conversion holds in 110 seconds; the observed rate corresponds to
59.936 Hz. Representative skipped surfaces were queued roughly 0.35-0.63 ms
after the associated phase end and their Metal command buffers completed
roughly two milliseconds after commit, still well before the next VSync. They
were not late GPU work.

The M1 MacBook Air exposes only a 2560x1600 @ 60.0 Hz current mode. Core
Graphics reports no 59.94 mode, and IOKit reports minimum and maximum variable
refresh rate zero. Changing the guest to 60.0 Hz would alter gameplay, audio,
and deterministic/netplay timing. Submitting duplicate stale frames would
hide the hold without producing a new game frame. Both are rejected.

PERF-128 then tested the conversion independently with the retained host-only
three-drawable Metal harness. The unpaced 60 Hz control delivered 120/120
intervals at or below 16.7 ms with 16.666625 ms worst. The same workload paced
at 16.683 ms for 6,600 intervals produced exactly six 33.333 ms holds:
16.681712 ms mean, 16.666625 ms p95, 16.666667 ms p99, 33.333208 ms worst, and
99.909% at or below 16.7 ms. No callback was dropped. This is the predicted
59.94-to-60 conversion behavior without Dolphin or guest code and closes that
attribution.

### Genuine late work

Other gaps had no queued replacement. The largest combat cluster covered
emulated frames 49137..49144. Total/CPU-wall time reached
46.264/45.667, 69.575/68.281, and 144.530/140.094 ms while CPU-thread time was
only 17.214, 20.277, and 19.900 ms. That is predominantly off-core/runnable
descheduling, consistent with PERF-104/105 rather than static-recompiler work.
Smaller no-queue gaps include frames where a subsequent `nextDrawable` wait
grew to roughly 21-23 ms. The result transition is a separate 446.397 ms phase
with 443.038 ms CPU wall and 314.904 ms CPU-thread time.

## PERF-127 shipped-path control

PERF-127 removed the entire in-process phase logger while preserving the same
runner, state, module, user directory, Game Mode, prewarm, and external Display
observer. It completed normally and retained:

- 6,859 process-attributed intervals over 114.964250 seconds;
- min/mean/median 16.661708/16.761080/16.666333 ms;
- p95/p99/max 16.666417/16.666458/399.992666 ms;
- 6,842 intervals at or below 16.7 ms, 16 at 33.333 ms, and one 399.993 ms
  match/results transition; and
- 6,871 queued swaps, 6,863 displayed swaps, and exactly eight queued surfaces
  not displayed.

In the stable 20-100 second window, queue production measured 59.926 Hz and
actual displayed swaps 59.851 Hz. The logger-free run reproduces the same
miss count and eight-surface conversion loss, so phase logging did not create
the observed behavior.

External Metal frame assignment also proves several no-queue gaps begin before
the compositor: present-command-buffer assignments themselves pause for about
33 ms at trace times 29.953, 53.636, 80.685, and around the result transition.
Other 33 ms display holds retain normal command-buffer production and belong
to downstream rate conversion/queue selection.

## Decision

The product is not broadly slow: ordinary on-glass p95/p99 are exact one-refresh
cadence, and the static-recompiled on-core budget was already proven. Strict
G5 remains **FAIL** because real no-queue 33 ms gaps and the result transition
remain. The 59.94-to-60 surface holds are a distinct fixed-panel conversion
boundary and may not be disguised as new game frames.

Retain patch 0021 for default-dormant exact joins. Do not retry VSync,
`PresentDrawable`, scheduled presentation, drawable-lifecycle, timer, QoS,
time-constraint, or broad compiler variants. The next causal work is limited
to the no-queue path: distinguish missing present-command-buffer assignments
from downstream queue drops, then optimize only a repeated producer-side
cause. Final Destination and G6 remain blocked.

## Retained evidence

PERF-126 raw root:
`/private/tmp/ssbmpad-perf114-115-gamemode.1aRWbj/run-126-display-host-time`

PERF-127 raw root:
`/private/tmp/ssbmpad-perf114-115-gamemode.1aRWbj/run-127-display-logger-free`

PERF-127 SHA-256 values:

- `displayed-surfaces-interval.xml`:
  `eac594c231fc209cd5192a84c4360a5a30f3a715e5fc3795fbfbb0ce72d03e21`
- `display-surface-queue.xml`:
  `7b8210bb16a9f42f83a72e2b4978fee22ed3d31c553414a21adbdcbac96ca90a`
- `display-surface-swap.xml`:
  `6f744312d2ac795161fe732c1bb341d4ee2b649bb5e064f1dccceeecdcad03aa`
- `metal-command-buffer-frame-assignment.xml`:
  `6523f99a021580f4a498fb31fe5387f0d85e75abf5754b0b0a54919c8b9d48bc`
- runner:
  `951168863076c3e3e714b3f684627c972590c7ef9dec4d25ff3b38c5fbef9156`
- module:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`

No disc image, extracted game, savestate, module, app, or trace is committed.

## Validation

- Patch 0021 clean reverse-apply: pass.
- Desktop runner rebuild: pass.
- Dependency bootstrap and repository-safety check: pass.
- Applicable native CTest entries: 40/40 pass.
- Controller-pipe tests: 16/16 pass.
- Shell syntax, signed macOS package layout, and strict signature: pass.
- The standalone `clang-format` command is unavailable on this host;
  AppleClang compiles the changed source successfully.
