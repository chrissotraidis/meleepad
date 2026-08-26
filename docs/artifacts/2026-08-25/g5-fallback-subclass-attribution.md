# G5 fallback subclass attribution

Date: 2026-08-25

## Question

The prior thread-CPU replay showed that Fountain's slow tail is mainly on-core.
This diagnostic asks which instructions account for the 5,000-7,000 static-
recompiler instruction-hook fallbacks per frame, so the next behavior change
can target an executed path rather than a broad static category.

This follows the independent stale-`ps1` review's evidence discipline: do not
optimize a hypothesized mechanism until the matched runtime path identifies it.
The review itself remains preserved verbatim in
`g5-independent-scalar-single-review-verbatim.txt`; its scalar-single, `frsp`,
matched-PGO, and visual-closure actions were completed before this diagnostic.

## Diagnostic change

The default-off `SSBMPAD_FRAME_PHASE_LOG` path now classifies every instruction
fallback as `mfspr`, `mtspr`, cache, or other, and subdivides cache fallbacks by
XO into `dcbst`, `dcbf`, `dcbi`, and `icbi`. The aggregate and subclass counters
are retained together so both invariants can be checked per trace:

- `hook_fallbacks == mfspr + mtspr + cache + other`
- `cache == dcbst + dcbf + dcbi + icbi`

The canonical Dolphin patch applies cleanly after the pinned prerequisite
stack, and the native `SsbmPadRunner` incremental build passed. A 658-row boot
smoke populated every expected column and both invariants. It also showed why
the subdivision was necessary: cache was dominant, but only 85 of 10,857,256
cache calls were `icbi`.

## Fountain route and bracket

The first all-in-one route reached an explicit Fountain highlight but timed out
on its roster predicate. It was not timed. Returning to CSS showed a valid P1
Pikachu and one CPU Peach. The route then returned to Stage Select, the
Fountain label/highlight was visually verified, and the launched match was
visually verified as coherent live Fountain gameplay before the bracket.

No screenshot or UI inspection occurred inside the timing interval. The input
cycle ran 20 times. Of 3,932 bracket rows, 120 rows were removed from each edge,
leaving the 3,692 rows in `g5-fallback-subclass-fountain.csv` (SHA-256
`289c710db3e1cf8272cb4f418213f7ce38c2539098fca0d4eddb7d6cffc8cc3c`).

## Result

Both accounting invariants hold exactly. The executed fallback mix is:

| Class | Total | Mean/frame | Share |
|---|---:|---:|---:|
| `dcbf` | 14,426,100 | 3,907.394 | 64.295% |
| `dcbi` | 8,003,986 | 2,167.927 | 35.672% |
| `mtspr` | 7,390 | 2.002 | 0.033% |
| `dcbst` | 0 | 0 | 0% |
| `icbi` | 0 | 0 | 0% |
| `mfspr` / other | 0 | 0 | 0% |

## Erratum after source-parity audit

The original version of this report incorrectly described `dcbf` and `dcbi`
as no-ops when D-cache emulation is disabled. Dolphin's reference interpreter
calls `JitInterface::InvalidateICacheLine(address)` for `dcbf`, `dcbst`, and
supervisor-mode `dcbi` in that configuration as a compatibility heuristic for
games that omit `icbi`. The specialized static-recompiler fallback measured
above failed to mirror that behavior. Its low fallback volume in tail frames
is still valid attribution, but the no-op semantic conclusion is withdrawn.

Total frame time was 16.683 ms mean, 16.684 ms median, 17.007 ms p95,
17.220 ms p99, and 30.478 ms worst. Hook fallbacks correlate -0.059 with total
time. Tail frames contain about 110 fewer fallbacks than the body while thread
CPU rises by 1.019 ms. The fallback volume does not cause tail variance.

## Decision

Keep the default-off classifier. The corrected experiment routes generated C
cache operations through the existing exact cache-control helper, matching the
LLVM backend and Dolphin's interpreter semantics without terminating the
generated block. Its matched result is retained in
`g5-cache-control-parity.md`; the stale specialized fallback was removed.

G5 remains open. G6 remains prohibited, and no Simulator was booted.
