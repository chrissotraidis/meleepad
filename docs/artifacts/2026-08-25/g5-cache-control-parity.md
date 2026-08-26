# G5 generated cache-control parity

Date: 2026-08-25

## Why this step changed

The independent stale-`ps1` report required source-mechanism verification and
matched evidence before retaining an optimization. Applying that discipline to
the fallback-class result exposed a wrong premise in the prior report:
Dolphin's interpreter does not treat `dcbf`, `dcbst`, and supervisor-mode
`dcbi` as no-ops when D-cache emulation is disabled. It invalidates the
corresponding JIT cache line as a compatibility heuristic.

The C backend had a second problem. It emitted every cache operation as a raw
instruction fallback followed by `return`, while the LLVM backend already used
the runtime's exact `ppc_cache_control` helper and continued the native block.
The old specialized host fallback did not reproduce Dolphin's invalidation
semantics either.

## Retained correction

- C CFG no longer classifies `dcbst`, `dcbf`, `dcbi`, or `icbi` as terminating
  generic fallbacks; their normal cycle costs remain 5/5/5/4.
- C emission computes the live effective address, calls `ppc_cache_control`,
  checks the exception result, and continues the generated block.
- `HookCacheControl` consumes that live guest address directly. It no longer
  applies REL-address translation intended for linked code constants.
- The runtime helper preserves `dcbi` privilege behavior, the D-cache-enabled
  store/flush/invalidate paths, `icbi`, and Dolphin's D-cache-disabled JIT-line
  invalidation heuristic.
- The obsolete specialized fallback shortcut was removed. Legacy generated
  modules therefore use the exact interpreter fallback; newly generated
  modules do not enter it.
- Default-off phase logging accounts for direct cache-helper calls with the
  same aggregate-plus-subclass atomic overhead as the control fallback logger.

DolRecomp's focused suite passes 14/14, including an execution regression that
proves two cache helpers execute in order, preserve the following `addi`
instructions, use effective address `0x80001040`, and charge 13 total cycles.
The generated GALE01r0 audit found all 14 cache sites using the helper and zero
raw cache fallbacks. Scalar-single/`frsp` helper counts remain unchanged.

The macOS 14 candidate module is arm64, ad-hoc signed, exports
`_staticrecomp_get_module`, exports no profile hooks, and has SHA-256
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.
A populated smoke recorded 8,188,076 direct cache operations with an exact
aggregate/subclass sum and zero cache fallbacks.
After removing the obsolete legacy fallback, the rebuilt native runner loaded
the same candidate module, produced 2,163 additional phase rows, and shut down
cleanly with `fallback=0` and `smc_failed=0`.

## Matched Fountain comparison

Both profile-free modules used the same app, Metal backend, null audio,
P1 Pikachu versus level-1 CPU Ice Climbers, explicit Fountain highlight, and
the same 20-cycle combat script. Roster, stage, coherent live gameplay, and
coherent gameplay after the candidate bracket were visually verified. No UI
inspection or capture occurred inside either timing interval. Each edge was
trimmed by 120 rows.

| Metric | Control fallback | Direct cache helper | Change |
|---|---:|---:|---:|
| Frames | 2,986 | 3,412 | same timed input workload |
| Mean | 20.329 ms | 17.858 ms | -12.153% |
| Median | 20.470 ms | 17.839 ms | -12.858% |
| p95 | 22.581 ms | 20.054 ms | -11.188% |
| p99 | 23.825 ms | 21.319 ms | -10.520% |
| Worst | 33.066 ms | 27.860 ms | -15.744% |
| FPS from mean | 49.191 | 55.997 | +6.806 FPS |
| Frames <=16.7 ms | 0.938% | 19.285% | +18.347 points |
| Cache fallbacks/frame | 6,066.022 | 0 | removed |
| Direct cache helpers/frame | 0 | 6,064.453 | preserved work |

The small difference in operation count is ordinary scene timing variation;
the candidate's cache aggregate equals its four subclasses on every retained
row. Remaining hook fallbacks average 2.002/frame and are `mtspr`, not cache
operations.

Retained CSVs:

- `g5-cache-control-parity-fountain-control.csv`, SHA-256
  `b99c41b59f77ade66262bc5b9de51a30480c94b83a49a447e4421337e4188e08`
- `g5-cache-control-parity-fountain-candidate.csv`, SHA-256
  `1f299fc013d33c9fec3168e3dac1568dc83b86cdb9df8d9a735389c8504e27d1`

## Decision and next experiment

Retain the correction for both correctness and performance. It removes a real
semantic mismatch and produces a broad matched improvement, not merely a title
counter change. It does not pass G5: candidate p95 is 20.054 ms and only
19.285% of frames meet 16.7 ms.

The generated control-flow shape has materially changed, so prior PGO data is
stale for the formerly dominant dispatcher route. The next single experiment
is an exact-source profile-generate/profile-use cycle on this retained cache
path with documented source/module/profile hashes and a visually verified
Fountain corpus. Re-run strict Fountain first; run Final Destination only if
that candidate clears Fountain. G6 remains prohibited and no Simulator was
booted.
