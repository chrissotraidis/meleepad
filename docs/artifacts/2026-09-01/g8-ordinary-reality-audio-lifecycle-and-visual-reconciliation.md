# PERF-267 — ordinary reality, audio/lifecycle, and visual reconciliation

Date: 2026-09-01

Status: **ordinary front end still fails; gameplay/lifecycle materially improved; stale visual blocker corrected**

## Ordinary installed-app lane

The published `ec8a1ef` app was terminated and relaunched from the installed
iPad Simulator product with no private pipe, MemoryWatcher, phase logger,
profiler, savestate, or diagnostic environment. One continuous screen recording
started before launch.

The moving opening and title were predominantly 59.9-60.0 FPS/VPS, directly
reversing the previous 49-52 FPS duplicate-XFB failure. The route still does
not pass. One cold moving interval reported 55.6 FPS, 55.3 VPS, and 0.863 speed,
while the DMA-underrun counter rose. Across the transition-heavy front end the
counter ultimately reached 44 before the run was stopped at the title. This is
ordinary product failure evidence; the faster scripted Fountain result does
not supersede it.

Private evidence hashes:

- ordinary cold video:
  `a6359f4381b886054c3caeb9d1c72ab6bdab234900a7d2aade7964f1dbde3f43`;
- ordinary runtime log:
  `d02651aa661beaacc9bcafaa8791896b34b23138a35809b5a0717d41f6268b68`.

## Visible-control mechanism and gameplay

A separate default-off `MELEEPAD_TRACE_BUTTON_EDGES=1` replay tested the title
behavior without changing controller data. Every visible touch generated a
complete delivered FIFO edge, including `0x0000 -> 0x1000 -> 0x0000` for START
and `0x0000 -> 0x0200 -> 0x0000` for B. A direct one-shot pipe START was also
ignored in the same title state. Repeated visible START presses eventually
crossed the acceptance window and entered the menus, so this is not a stuck
overlay button or missing RELEASE defect.

Only visible touch controls then selected Ness, entered Classic, resumed the
paused first stage, moved in both directions, jumped, and attacked. Live combat
held 59.9-60.0 FPS/VPS near real-time speed. The DMA counter moved 28 -> 29
around loading/gameplay transition and then remained flat through multiple
ten-second combat intervals.

The trace replay is mechanism evidence, not a replacement for the unchanged
ordinary five-minute Fountain acceptance route.

## Lifecycle and audio

The same running match was backgrounded with the Simulator Home control and
foregrounded without process replacement. The log proves, in order:

- `lifecycle willResignActive`;
- `runtime paused for system event`;
- save-flush grace start/end and `didEnterBackground`;
- `willEnterForeground` / `didBecomeActive`;
- audio session reactivated on Speaker; and
- `runtime resumed after system event`.

The original match returned visibly at 59.9 FPS. Resume recovery added isolated
underruns from 29 to 34, then the counter stayed flat for the final twenty
seconds while callbacks, queue depth, FPS, and VPS continued normally. This
passes the no-*sustained*-underrun interpretation for the observed combat and
lifecycle window, but not the complete cold-route audio gate: moving cold
transitions still create audible-risk underruns and the exact five-minute route
has not been run ordinarily.

Private evidence hashes:

- post-resume Classic screenshot:
  `fdc4068b667d26bbd1981ef5cadd33a90d708540afd56e864ff5680b7c3ba8b2`;
- edge/lifecycle runtime log:
  `6802d16bfcde7f3f47463d0de2170d25a2e5c25c6421d16a5e78ad7e87c170f8`.

## Visual evidence reconciliation

The active 2026-09-01 queue had accidentally reopened the lower Fountain
reflection as malformed output. Existing retained evidence already closes that
claim:

- profile-use, profile-free, interpreter, EFB-to-RAM, and non-deferred-copy
  controls all show the same lower reflection; and
- signed official Dolphin 2606a using JIT64 SC, Metal, HLE, and native scale
  reproduces it with SHA-256
  `908272b7c3953031cc73a4e1c4ea46693159b7b00cfd1fcd2e1fe9d454a53aa9`.

That reflection is reference parity, not an meleepad rendering defect. The real
fighter-mesh issue was independently fixed by the scalar-single/`frsp`
correction and closed after a 402.7-second, 2,110-frame matched corpus. Current
iPad exact-Fountain and Classic captures show coherent real fighter meshes.
Keep a recurrence watch, but do not block row 7 or retry destructive EFB-copy
settings on the reference-matching reflection.

## Decision

Keep synchronized CPU/video execution and duplicate-XFB presentation. Stop
treating rendering-reference parity as an open blocker. Row 7 remains failed
on stronger evidence: the ordinary cold moving route still contains a 55 FPS
interval and transition underruns, and the required ordinary exact five-minute
Fountain run remains missing. Next reproduce the cold sub-59 interval with the
lowest-overhead phase boundary needed to distinguish guest compute from host
descheduling, then reverse only that measured mechanism. Physical-iPad
promotion and G9 remain closed.

The app was stopped and `MELEEPAD_TRACE_BUTTON_EDGES` was removed. Exactly one
Simulator remains booted with no game process. ROM, generated source/module,
saves, logs, recordings, and private paths remain untracked.
