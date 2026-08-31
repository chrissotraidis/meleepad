# G8 iOS phase-specific attribution and PGO training gate

Date: 2026-08-31

Status: **row 7 remains failed; valid Fountain profile and private candidate ready for matched reversal**

## What changed in the diagnosis

The 21.9 FPS Fountain screenshot is not explained by the M1 being uniformly
too slow. In the same process, with the same app and generated-module hashes,
the slow Fountain/Stage Clear route consumed the CPU-GPU thread continuously.
After Start advanced the game to the next Classic stage, two consecutive rows
reported 60.0 FPS/VPS. Its eight-second CPU-GPU sample contained 200 primary
and 32 secondary `PrecisionTimer::SleepUntil` ticks out of 2,604; the matched
slow sample contained none.

The remaining deficit is therefore phase/workload specific. Slow-sample
generated chunks `func_80275940`, `func_8004D940`, and `func_8000D940` have
zero function-entry count in the exact retained gameplay profile. This does
not prove PGO will fix the deficit, but it makes representative coverage a
small, reversible experiment with a clear reject condition.

## Rejected capture

The exact retained profile-generate module was launched privately and visibly
reproduced severe opening/attract slowdown. The intended Fountain automation
did not advance through the title route, however, so the configured guest-state
trigger never armed. After termination, both raw files reported zero function
count for `chassis_dispatch` and every inspected sampled chunk.

Those files are not training evidence and must not be merged. The exact normal
module was restored with SHA-256
`af1364e6fabe9ee29d2a64ee6268bd80ba3ef2aaa47de9c7741655fae9f3211b`.
The ROM, raw profiles, module, and private paths remain outside Git.

## Refined decision gate

1. Calibrate the complete automated route on the exact control module and
   retain visible proof that Start/menu inputs advance the guest.
2. Repeat with the profile-generate module and retain visible Fountain trigger
   entry and exit.
3. Before merging, require `llvm-profdata show` to report nonzero counts for
   the target chunks. A raw file existing is insufficient.
4. Build a private strict-use candidate only after steps 1-3 pass.
5. Replay the full phase-labeled route. Cold opening, menu, loading, Fountain,
   results, and return each independently fail on any interval below the row-7
   thresholds; a later 60 FPS phase cannot hide an earlier failure.

## PERF-240 acceptance refinement after the visible 21.9 FPS failure

The UI is part of the evidence, not decoration. When the visible label and a
nearby runtime row disagree, retain both and use the lower value for the gate.
The user's 21.9 FPS Fountain screenshot therefore fails the route regardless
of later 60 FPS rows.

The next candidate must pass, in order:

1. a measured mechanism tied to the exact slow Fountain phase;
2. focused semantic, stability, and privacy/ROM-boundary checks;
3. a matched control/candidate/control Fountain reversal, normally requiring
   at least a five-percent improvement without displaced underruns, corruption,
   or another phase regression; and
4. only then, two complete fresh-process boot-to-Fountain acceptance routes.

Passing step 3 is useful engineering progress but is not row-7 acceptance.
Any active interval below 59.0 fails a full route, and one below 55.0 ends that
run as a pass attempt. Physical-iPad promotion remains closed until step 4 is
green in full.

Physical-iPad promotion remains closed until two complete fresh-process
Simulator routes pass this protocol.

## Valid capture and strict-use candidate

After the app's normal 60 Hz neutral publisher was disabled only for explicit
external-pipe automation, the control route visibly reached menu, CSS, stage
select, Fox versus CPU DK on Fountain, and the results screen. The instrumented
repeat entered and exited the gameplay trigger. Its raw profile has SHA-256
`36ba2a35c98cdef8bad634e1ce2cec26126cbef917f512284b94e55beb6bbb2e` and
reported these post-trigger counts:

- `chassis_dispatch`: 1,125,102,880;
- `func_80275940`: 1,286,147;
- `func_8004D940`: 4,694,178;
- `func_8000D940`: 8,743,130.

The retained control screenshot
`screenshots/2026-08-31/g8-perf239-control-fountain-32fps.jpg` shows the same
Fountain route at 32.3 FPS. It is failure evidence, not a candidate comparison.

The merged exact-source profile has SHA-256
`a1e9def7bf4e7a051975a0cf4a2dbfc04073b05f3656dc4b8d064f13fb316454`,
6,556 functions, and 1,364,776,045 `chassis_dispatch` calls. All 237 generated
chunks passed strict profile-use compilation.

The first linked binary was correctly rejected before installation: although
its ABI and profile-section checks passed, its Mach-O load command required
iOS Simulator 26.5 instead of the control's iOS 16.0. Reconfiguring with an
explicit 16.0 deployment target rebuilt every object and relinked. The
corrected private candidate:

- is arm64 `IOSSIMULATOR`, minimum iOS 16.0, SDK 26.5;
- exports the same two public symbols as control;
- contains no `__llvm_prf` or `__llvm_cov` sections;
- passes ad-hoc signature verification; and
- has SHA-256
  `4f3c3fd88db3be4bbf9cdadec148f2b33089c19397a14e2e41d349344255a08e`.

The app is stopped and the active module remains the exact control SHA-256
`af1364e6fabe9ee29d2a64ee6268bd80ba3ef2aaa47de9c7741655fae9f3211b`.
No performance improvement is claimed. Next run the fixed Fox/CPU-DK Fountain
control/candidate/control phase reversal and reject the candidate unless the
same failing phase improves materially without new visual or audio failure.
