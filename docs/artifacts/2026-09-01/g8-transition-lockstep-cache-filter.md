# G8 transition lockstep cache-side-effect filter

Date: 2026-09-01
Goal: G8 row 7
Verdict: **diagnostic integrity improved; row 7 remains a hard fail**

## Question

The retained Fountain runs combine catastrophic FPS/VPS decay with character
and stage deformation. The next mechanism question is therefore whether the
static recompiler first diverges from Dolphin's interpreter around the exact
menu-to-combat transition, before spending another build on throughput.

## Bounded transition

Frame workload attribution locates the first sustained Fountain render load at
phase frame 2,442 (`primitives > 40,000`). The preceding phase rows account for
approximately 880.8 million native guest-block dispatches. The lockstep screen
was therefore bounded to dispatches 878,000,000 through 886,000,000 on the
state-verified P1 Samus versus level-1 CPU Kirby, Stock/04/05:00 Fountain route.
This is private-input mechanism evidence, not a product FPS run.

## Verifier defect and correction

The first bounded screen reported `0x80342EAC`/`0x80342ECC` and
`0x80342EDC`/`0x80342EFC`. Those are `dcbi` and `dcbf` loops. The verifier's
instruction-fallback path already skips blocks with side effects that its RAM,
locked-cache, VMEM, and MMIO journal cannot replay, and its own comment names
cache operations as an example. Generated cache operations use the dedicated
`HookCacheControl`, however, and that hook did not set the same unsafe-block
latch. The shadow therefore replayed a block after the native cache had already
been mutated and produced false differences.

Patch `0032-lockstep-skip-cache-side-effects.patch` makes the dedicated cache
hook mark only an actively journaled block unsafe. The normal path adds one
branch whose condition is false when lockstep is disabled; product cache
semantics and all product defaults are unchanged. A focused regression failed
before the source change and passes afterward. Canonical bootstrap reproduction,
the incremental iOS core build, Release app link, install, and exact route all
pass.

## Post-filter result

The corrected bounded route completes and the four cache-loop entry PCs no
longer report. It still produces 21 distinct reports, so the cache false
positive was not the complete explanation. The earliest remaining interval is
`0x80358ABC -> 0x80358AE8`, followed by `0x80358AE8 -> 0x80358AE0` and
`0x80358AE0 -> 0x80358C00`. Later reports include floating-point plus memory
differences at `0x8035AA64`, memory differences at `0x8035B9DC`, and additional
allocation/setup-family differences. These are not yet proven product defects:
the next screen must distinguish an unjournaled bulk/cache-adjacent side effect
from a true generated-instruction mismatch.

Instrumentation itself causes deep one-second FPS dips and cannot qualify or
rank the product. The ordinary 21.9 FPS floor, animated-menu failure, visible
deformation, and physical-iPad prohibition remain unchanged.

## Evidence identities

- canonical patch: SHA-256
  `698be5b898ae02eea1691c2dd9ac2f654d005c4e20feb6895f910d6e84f9b61a`
- rebuilt Simulator core archive: SHA-256
  `5550f569e03e1e0057485847a51f449550611298b09d597d22918838deafe940`
- linked Release Simulator executable: SHA-256
  `f53dc3249201b53a1cdc920e998a341157cb99c4daa950914c25426c8fd7cb68`
- retained private console: SHA-256
  `507ea262a4056ae158f8dbad8b8067bf4c9ac21c0568952fe4728d7b1dff9732`
- retained private route log: SHA-256
  `da86f1ea01d7f55ab8b5449399f56dfb9b7673a59ab655497e4836db0e33d088`

The private console, route log, ROM, generated module/source, app, and build
products remain outside Git.

## Next falsifiable step

Minimize only the first remaining `0x80358ABC -> 0x80358AE8` interval by forcing
diagnostic dispatch boundaries around its internal calls or by extracting that
interval into a native-versus-interpreter differential. Reject it as another
journal blind spot if the earliest mismatch disappears when bulk and
cache-adjacent side effects are isolated. If a specific generated operation
still differs from the interpreter from identical entry state and memory,
correct that semantic operation first, then repeat the exact transition and
ordinary reality lane before reopening performance optimization.
