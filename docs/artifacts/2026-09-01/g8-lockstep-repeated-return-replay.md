# G8 lockstep repeated-return replay

Date: 2026-09-01
Goal: G8 row 7
Verdict: **one more verifier artifact removed; row 7 remains a hard fail**

## Question

After the cache-side-effect filter, the earliest bounded lockstep report was
`0x80358ABC -> 0x80358AE8`. The native module charged 257 guest cycles, but a
per-instruction shadow trace reached `0x80358AE8` after only 19 instructions.
The generated return dispatcher then continues inside the same native chunk
and revisits that return address. Was the checker comparing the full native
interval with only the shadow's first visit to a repeated endpoint?

## Failed broad correction

Requiring every shadow block to reach its endpoint only after covering the
native cycle charge was too broad. Endpoints that do not recur ran to the
512-step cap and produced new control-flow false reports. That version was
rejected and is not retained.

## Targeted correction

Patch `0033-lockstep-replay-loop-interval.patch` changes only an explicitly
repeated diagnostic PC. When `STATICRECOMP_LOCKSTEP_REPEAT` names the entry,
the shadow must both reach the native endpoint and cover the native interval's
charged cycles. All other blocks retain the prior first-endpoint behavior.
Lockstep remains disabled in product defaults, so this has no product-path
runtime cost or semantic effect.

The focused regression failed before the source change and passes afterward.
Canonical reverse-apply, bootstrap reproduction, incremental Simulator core
build, Release link, install, and the exact P1 Samus versus level-1 CPU Kirby,
Stock/04/05:00 Fountain route pass.

## Result

With repeat entry `0x80358ABC`, the old report count is zero. The first
surviving report is now:

`0x80358AE8 -> 0x80358AE0: r28 native=0x3, interpreter=0x15`

This rejects `0x80358ABC -> 0x80358AE8` as a verifier interval-boundary
artifact. It does not prove the next report is a product defect. The targeted
run contains 28 distinct reports; that count is not compared numerically with
the prior 21 because repeat mode changes check selection and deduplication.

The observer-heavy run's FPS labels are mechanism evidence only. They do not
supersede the ordinary visible 21.9 FPS floor, animated-menu failures, visible
geometry corruption, or the physical-iPad prohibition.

## Evidence identities

- canonical patch: SHA-256
  `026fbbe9723e1109697d4085f7e25cf29796c60b29caef1cc1d197a90a9ba301`
- rebuilt Simulator core archive: SHA-256
  `4d4a323b5bf15e1102157a865057f518e379b07900941b8ae02c23faa183ffef`
- linked Release Simulator executable: SHA-256
  `553ce2028eac9274e71cef5c30c95d05a1774e18ecaff3521caff6f96e93d414`
- retained private console: SHA-256
  `ba8fe35b1a7085b65e02245f08e56cadbb48561e1d8f68b142fc3d9874cf3c85`
- retained private route log: SHA-256
  `74d4fb5adedb470f15080497b1a4cb93d3eb98da57ea380f7eee68d81ca20680`

The private console, route log, ROM, generated module/source, app, and build
products remain outside Git. The app is stopped and all diagnostic Simulator
environment variables are unset.

## Next falsifiable step

Trace only `0x80358AE8 -> 0x80358AE0` from identical entry state. Determine
whether its `r28` mismatch is another repeated-endpoint/journal boundary or a
specific generated instruction mismatch. If it is real, correct that semantic
operation and rerun the bounded route; if it is diagnostic, repair only that
checker boundary. Return to an instrumentation-free reality lane only after
the earliest transition screen is semantically clean.
