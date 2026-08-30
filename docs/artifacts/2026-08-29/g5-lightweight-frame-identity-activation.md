# G5 lightweight frame identity activation (PERF-197)

## Question

Can the retained lightweight recorder provide exact emulated-frame identity
when the heavier phase observer is disabled, without adding work to the
default path?

## Finding and correction

Patch 0024 added `emulated_frame` to the lightweight CSV, but
`VideoInterface.cpp` advanced the shared index only when
`SSBMPAD_FRAME_PHASE_LOG` was enabled. A lightweight-only smoke therefore
recorded zero for every frame. A regression was made to fail on that missing
activation before the implementation changed.

Canonical patch
`patches/moderngekko-dolphin/0025-lightweight-frame-index-activation.patch`
now enables the existing frame-index store when either phase or lightweight
logging is requested. When both are disabled, the path retains the same one
branch and performs no atomic store.

## Verification

- Patch 0025 applies and reverses cleanly and is included by bootstrap.
- The lightweight-only signed-app smoke contains 2,496 nonzero, unique,
  monotonic frame identities (300 through 2,795).
- Smoke SHA-256:
  `f562570272a19c3db33b87f7a69708a285133d5efa623f129f040c9c33dc4efd`.
- All 26 scoped `moderngekko.*` tests and repository checks pass.
- The fix is published in commit `10dcb11`.

This is an evidence-identity repair, not a frame-rate optimization or G5 pass.
