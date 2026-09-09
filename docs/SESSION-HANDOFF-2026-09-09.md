# Session handoff — September 9, 2026

Work is stopped for today at the owner's request. There is no active goal.
This follow-up did **not establish a reliable gameplay performance improvement**.
Do not present the diagnostics or an isolated favorable comparison as a speed fix.

## Preserved state

- Branch: `codex/decomp-connected-performance`. Work is committed locally;
  no push, merge, new public IPA, or release was made during this follow-up.
- Stable baseline: Preview 4/build 18, main commit `83b81ed`.
- iPhone: private build 20, with the unchanged stable v1.00/v1.02 game modules
  and new scene diagnostics. Final in-place restoration and normal startup were
  verified, then the app was stopped for cooldown. Selected game: v1.02, 1x, 4:3.
- Preservation checks matched 24 material save/configuration files and unchanged
  ISO size/timestamps. Do not reinstall destructively or replace game data.
- iPad was untouched in this follow-up; its last recorded build is 18.
- Private matrix candidate builds 19 and 21 are **not promoted**.
- Three existing untracked Online Play images under `docs/images/` are unrelated
  to this investigation and remain untouched.

Implementation is in `43e9123` (scene diagnostics); findings are in `eb5032a`.
Earlier experiment/history commits are `c4d5c72`, `19b45e5`, and `c0a1759`.

## What we learned

The owner's logs confirm real slowdowns and audio starvation, including
37.9–45.6 FPS reports. Thermal pressure contributes, but does not explain every
slow interval. Increasing the audio buffer cannot fix sustained execution below
game speed.

Build 20 adds nonblocking scene snapshots at CPU frame boundaries. These
distinguish combat from results without pausing the CPU for routine sampling.
The exceptionally heavy late workload in the new run was **the results screen**;
older unclassified measurements must not be described as proven combat results.
Diagnostics passed focused concurrency/lifecycle tests, patch verification,
device compilation, signing verification, and physical startup/log checks.

Scene-filtered profiling identifies matrix functions as meaningful guest costs,
but profiling itself adds overhead. One normal combat comparison of candidate 21
showed a 5.02% lower mean frame interval; thermal and workload differences, and
an invalid-temperature repeat, prevented confirmation. Candidate 21 was rejected
for promotion and build 20 restored. Correctness tests and faster host arithmetic
do not establish a sustained iPhone speedup.

The decompilation recovers original GameCube behavior. It does not automatically
replace MeleePad's translated PowerPC execution, floating-point state handling,
or Dolphin-derived graphics/audio layers with optimized Apple-native code.
Those remaining costs need measured attribution before another implementation.

## Resume later — bounded next step

1. Read the [scene investigation](IPHONE-SCENE-PERFORMANCE-GOAL.md) and
   [owner-run review](IPHONE-OWNER-RUN-2026-09-09.md). Verify the current checkout
   and installed build before assuming today's state still holds.
2. Establish a repeatable, demonstrably unpaused combat fixture with matching
   thermal starts. A combat routing label alone does not prove unpaused play.
3. Measure useful video command processing versus FIFO/status polling in that
   fixture before choosing one larger engine optimization. Existing video-thread
   samples are older evidence, not current attribution. Native Instruments
   connectivity failed even though CoreDevice/AFC worked.

Stop the next experiment if it cannot produce comparable physical measurements;
record that limit instead of continuing broad sweeps. Do not repeat rejected
math or FIFO sleep-threshold sweeps, promote build 21 from one favorable pair,
or run multiple simulators. Hardware tests should use the attached devices.

## Evidence locations

- [Detailed scene protocol, results, and acceptance limits](IPHONE-SCENE-PERFORMANCE-GOAL.md)
- [Earlier decompilation experiment](DECOMP-PERFORMANCE-GOAL-LOOP.md)
- [Performance notes](PERF.md) and [technical debt](TECH-DEBT.md)
- Private, ignored directory: `ref/revision-102/scene-followup/` contains
  `HANDOFF.md`, retained build 20 `MeleePad.app`, unpromoted `matrix/MeleePad.app`,
  normal startup receipts, preservation comparisons, run logs,
  `combat-comparison.json`, and `profile-analysis.json`.
- Earlier private owner logs/candidates: `ref/revision-102/decomp-connected/`.

Keep private game modules, disc images, saves, device identifiers, and signing
material out of commits and public artifacts. No further run is scheduled by
this handoff.
