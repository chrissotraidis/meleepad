# G8 R0 rules normalization and guest-PC-store preflight

Date: 2026-08-31  
Goal: G8 row 7  
Decision: **route harness repaired; guest-PC-store candidate rejected before a product build**

## Why the exact-route harness needed correction

The exact route previously used the active `GameRules` word both to decide
whether to open Custom Rules and to decide whether its rendered mode needed an
input. The opener used a zero mask, so it could return without sending A. A
later live check also showed the cached target value while the rendered row had
not yet been synchronized. That allowed memory evidence to sound more exact
than the visible route.

Revision-1.00's active rules block does change with the rendered menu: the mode
field moved from Time to Stock to Coin as `0x00`, `0x01`, and `0x02` while the
screen showed those transitions. The retained sequence therefore does the
smallest deterministic normalization:

1. open Custom Rules with an unconditional A and settle;
2. force one visible rightward change before converging the mode to Stock;
3. force one visible stock-count change before converging to four;
4. open Additional Rules unconditionally and force one visible time change
   before converging to five minutes; and
5. retain the post-exit Stock/04/05:00 predicates as the final veto.

The focused harness suite passes 27/27. Two fresh processes then completed the
full sequence with exit status zero. Both proved Samus, level-1 CPU Kirby,
Stock/04/05:00, Fountain slot 8, and active combat from guest state. Computer
Use independently showed the four stock icons, five-minute countdown, roster,
and Fountain gameplay. Visible combat was only 49.1 FPS in the first run and
41.6 FPS in the second, and both still showed the tracked geometry/warping
defect. These are route-integrity passes and product-performance failures; the
ordinary 21.9 FPS run remains the controlling floor.

## Guest-PC-store preflight

The no-build preflight used the exact current generated source, exact current
strict PGO profile, and five named hot chunks. Removing every label-adjacent
`ctx->pc` materialization produced the following AArch64 instruction counts:

| Chunk | Exact control | All-drop preflight | Reduction |
|---|---:|---:|---:|
| `80375940` | 105,962 | 96,758 | 8.69% |
| `80321940` | 81,575 | 71,898 | 11.86% |
| `8033D940` | 90,860 | 75,704 | 16.68% |
| `80339940` | 79,749 | 65,277 | 18.15% |
| `80365940` | 91,607 | 80,136 | 12.52% |
| **Total** | **449,753** | **389,773** | **13.34%** |

That reduction is not safe. The controlling DolRecomp C backend initializes
PC materialization for every instruction, then elides it only inside proved
direct loops for instructions classified as transparent. Its memory-loop
regression deliberately preserves the PC at a memory access so a slow path,
exception, hook, or diagnostic observes the exact guest instruction.

A semantics-preserving mechanical screen retained PC materialization for
load/store and other slow-path-capable instructions. On representative hot
chunk `80375940`, strict-PGO instruction count changed only 105,962 to 101,966,
a 3.77% reduction. That misses the predeclared five-percent materiality gate.

There is also direct live evidence against broadening the idea. The earlier
transparent-instruction implementation passed its semantic gate and removed
1.475 MB of generated text, but its matched Fountain reversal regressed from
52.585 FPS to 49.629 FPS. The current generator already retains the narrower
proved-loop form from that work. An isolated older-source emitter test passed
10/10 tests, but it is non-controlling provenance and supplies no product
evidence; its result is discarded.

## Decision and next step

- Reject global and broad guest-PC-store removal. Do not build or replay a
  product module for it.
- Keep precise exception, fallback, hook, SMC, diagnostic, and future netplay
  state semantics.
- Retain the current product module unchanged (SHA-256 begins `af1364e6`).
- Measure the built-in one-in-4,096 exact-route dispatch sample next. Select a
  new generated-region mechanism only if the current slow workload exposes a
  bounded, unclosed concentration; otherwise reject that direction too.

No ROM, generated module/source, profile, raw game screenshot, save, or private
filesystem path is committed with this artifact.
