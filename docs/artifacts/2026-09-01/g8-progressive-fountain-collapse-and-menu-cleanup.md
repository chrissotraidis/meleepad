# G8 progressive Fountain collapse and menu cleanup

Date: 2026-09-01

Status: **row 7 remains a hard fail; correctness-first attribution active**

## Product reality

A normal installed-app launch with product defaults, visible touch input, no
savestate, no private pipe, and no diagnostic environment traversed the moving
opening, menus, Classic selection, and live combat. Across 215 one-second FPS
samples it measured 6.3 minimum, 56.885 mean, 49 samples below 59, and 21 below
50. Runtime rows reached 55.9 FPS / 56.0 VPS with the CPU-GPU thread at 99.3%
and 80 DMA underruns. This is another complete product-lane failure, not a
replacement for the lower ordinary 21.9 FPS Samus/Kirby Fountain anchor.

The continuous recording and matching console hashes are:

- recording: `4cc3dc08cd975dbeab1885b312a2b8467a4585b01cdbfd315b02b4b8378e420c`
- console: `0c8040a15e714f5f15d5135534d8126a4f56fe1e22f78360e36cd98d94e11a76`

## Frame-aligned attribution

Canonical Dolphin patch 0031 adds default-off counters for actual Metal render
pipeline creation, current-frame draw/primitive work, shader/texture creation,
and bounded periodic dispatch-frame sample flushing. The focused regression
failed before the patch and passes afterward. Disabled product runs pay none of
this instrumentation cost.

An exact diagnostic Fountain run aligns 3,815 combat frames. CPU wall and
thread time correlate with total frame time at 1.000 and 0.994, while Metal
pipeline count/time correlations are only 0.046 and 0.033. The largest first
combat frame is 1,305.539 ms, almost all CPU, with only 1.131 ms of pipeline
creation; steady 27-35 ms frames create no pipeline. Tail frames execute 2.79x
the native dispatches and 2.03x the guest cycles of body frames. Shader or
pipeline prewarming is therefore rejected as the primary sustained cause.

Phase and dispatch evidence hashes:

- phase: `ff5bcf375276de6beafb8dbce3629046de8aa6e8b0c1b2d287236be6376d26c1`
- dispatch: `8b9108fe624bf8b23075ecd856262489efbdbc9018dba0c21d8ebdb02576c0cc`
- guarded route: `937677ab163cfc35bcf5e235e44419f86d71672ee5bd8dd4849def16af222a06`

The enriched dispatch PCs are the already-rejected OS interrupt leaves and do
not authorize another address-specific guest rewrite.

## Current-source host PGO reversal

The ordinary app had silently returned to plain `-O3`; its current module is
81,006,192 bytes. The retained host profile passes strict stale and unprofiled
checks across all nine current static-recompiler runtime units. A disposable
archive replaced exactly those nine members and linked a non-instrumented app.
Binary symbols prove a smaller, profile-shaped `StaticRecompCore::Run` region;
the candidate has no `__llvm_prf_*` sections.

- profile: `b8babe7668fa8732b1b38b5c048d86100c148d24feba44e267dc282311631ea6`
- profile-use core: `d9b74f50aadae274e2ab9d4b539c90590214fe8641afb88ab10d03d49dcfd10e`
- candidate app binary: `c54718e23575201a19c9ccca52f2180a07f4fb154d64d7659f39a6f7066b4f68`

The state-guarded route visibly proved P1 Samus, level-1 CPU Kirby,
Stock/04/05:00, Fountain slot 8, and active combat. Host PGO did not solve the
product. Performance progressed through 47.3, 56.4, 59.7, 43.1, 47.6, 49.7,
28.7, 20.4, 10.3, 16.5, 15.4, and 28.2 FPS. The 10.3 interval reported 10.6
VPS, speed 0.207, and 373 underruns; underruns reached 547. Draws and
primitives remained in the same broad combat class while CPU usage fell with
FPS. Host PGO is useful supporting code generation but is rejected as the
primary fix.

The retained frame also shows silent correctness drift: Samus is visibly
stretched/fragmented and the Fountain lower reflection is smeared. The unified
log contains no SMC, FIFO, desync, fatal, thermal, or memory-warning event.
Optimizing that corrupted state would be invalid. The next mechanism must join
the first coherent and first morphed frames to guest CPU/FPU state and exact
generated work, then locate the earliest divergence.

Candidate evidence hashes:

- console: `f33ed8c990a64152f027e401a46b4b67a6ea90f445ca145a8a28cc47cd3402f1`
- route: `23b522e34c27fdbbf4591848e4ad2f579e32ec625c0a392a53832a1bb089fe65`
- active combat input: `9f824281bc26ba41c2bf3a696e548cf6dd335065bb19d577aa54bfa235a6a152`
- retained frame: `cbf48356ebd284f759b9fa3a14d8dd8748002b6c88316c41dea398fd5c0687ab`

## Three-dot menu cleanup

The user-facing Experimental Performance Mode was removed. Existing installs
delete its stored 90%-clock preference during settings initialization, so
removing the control cannot strand an app in altered timing. The explicit
90%/95%/QoS launch arguments remain developer-only diagnostics.

The live Release menu now contains Render Resolution, Aspect Ratio, Show FPS
Counter, Controller Button Mapping, Touch Control Settings, Game Data & Saves,
Share Diagnostic Log, and Report a Problem. The direct diagnostic action
created the privacy-reviewed report and opened the share sheet without sending
it. The export contained no absolute host path or credential material.

- menu build binary: `479587e326314e24facacf50320cbe39c371ebeaff060485a1cdcdf79637cafc`
- live menu screenshot: `fc95c186a749f3bd9aa726acdb3c6ac138eee02b46bc7a6265f4f32cf266575c`
- generated diagnostic report: `ac3c59d3a15b0642cc4503a73940045e9afb1dd7b8019b7842af985df2bb551e`

The focused fail-before regression, Release Simulator build, live menu/share
exercise, diagnostic privacy check, and full repository gate pass. This menu
cleanup is retained independently of row 7; it makes no performance claim.

## Refined next experiment

1. Keep the ordinary 21.9 FPS run as the sticky product floor.
2. On one exact control process, retain an early coherent Fountain checkpoint
   and the first visibly morphed checkpoint. Keep character, camera, timer,
   input cadence, draw class, and guest route state explicit.
3. Compare guest GPR/FPR/FPSCR/paired-single state, SMC chunk state, fallback
   counts, native dispatches, guest cycles, and frame work across those two
   points. Select the earliest correctness divergence, not the largest late
   profiler symbol.
4. Build only a semantic correction that predicts at least five percent of the
   failing window or removes the visible state corruption. Reverse it on the
   exact route before any ordinary acceptance attempt.
5. Do not call the app playable or promote to physical iPad until the complete
   two-cold-route plus unchanged ordinary five-minute protocol passes.

No ROM, module, profile, save, raw trace, private path, or app bundle is tracked.
