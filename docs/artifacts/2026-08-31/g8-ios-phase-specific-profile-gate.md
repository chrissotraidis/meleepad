# G8 iOS phase-specific attribution and PGO training gate

Date: 2026-08-31

Status: **row 7 remains failed; first fresh profile capture rejected**

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

Physical-iPad promotion remains closed until two complete fresh-process
Simulator routes pass this protocol.
