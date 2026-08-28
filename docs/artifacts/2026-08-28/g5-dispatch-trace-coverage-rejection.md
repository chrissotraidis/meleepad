# G5 dispatch-trace coverage preflight

Date: 2026-08-28

Status: **DISPATCH-ONLY TRACE FOREST REJECTED; MERGED-STATE PREFLIGHT NEXT; G5 OPEN**

## Question

Can a boundary-guarded profile trace amortize safety checks across enough
native dispatch transitions to project a material CPU gain without broad
per-edge guards?

## Deterministic edge analysis

`scripts/analyze-dispatch-edge-traces.py` now reads the retained PERF-075 edge
stream, restricts it to an exact emulated-frame interval, chooses only the
dominant non-self successor of each dispatch entry, and stops a chain at an
ambiguous edge. The command used was:

```sh
python3 scripts/analyze-dispatch-edge-traces.py \
  docs/evidence/g5-hot-direct-call-rejection/dispatch-edge-samples.csv \
  --first-frame 48123 --last-frame 48562 \
  --minimum-samples 20 --minimum-dominance 0.80 --maximum-nodes 16
```

The selected Fountain region separates into:

- `8036C8D8 -> 8033FB64`, 103 samples, 100% successor dominance; and
- `8036C8E4 -> 80377B6C -> 8036C904 -> 8033FBA0 -> 8036C91C -> 803789F8`,
  bottleneck 74 samples, minimum dominance 84.09%.

The connector `8033FB64 -> 8036C8E4` has 101/127 samples / 79.53% dominance.
A speculative runner can include it safely by checking the exact successor
and exiting on a miss, but it is correctly excluded by the 80% report rather
than rounded into a pass.

## Static and semantic screen

The involved generated paths occupy chunks beginning at `8033D940`,
`80369940`, and `80375940`. Conservative instruction scans over the local GX,
shape, and pad ranges covered 394 guest instructions, including their local
calls and branches. None contains `dcbf`, `dcbi`, `dcbst`, `icbi`, `rfi`,
`bctr`, `bcctr`, `sc`, `tw`, or `twi`. This establishes that the proposed
trace does not execute an in-trace icache invalidation or indirect system
boundary; exact successor, exception, and 256-cycle checks remain mandatory.

The data-free focused regression
`scripts/g5_trace_semantics_preflight.c` covers:

1. invalidated/forced entry refusal;
2. wrong-entry canonical fallback;
3. exact complete state and cycle accumulation;
4. unexpected-successor exit;
5. exception exit; and
6. exact `-256` cycle-budget exit before the next block.

Its first run failed four paths because a C enum containing high guest
addresses selected an unsigned representation, so unary minus on the enum's
`256` member became a large positive value. Moving the budget to an explicit
signed `INT64_C(256)` fixed the harness. AppleClang `-O2 -std=c11 -Wall
-Wextra -Werror` then passed 6/6. The source SHA-256 is
`a0b383702e9280533fcbe9138a0d5304153c2dadadf635f4bf8863b03f762823`.

## Coverage bound

The combined seven-node path accounts for 647 edge samples, or approximately
2,650,112 of 51,380,895 dispatch transitions / 5.16% in the exact window. The
measured PERF-075 slope is 12.684 ns saved per removed dispatch, so this trace
projects only about 0.076 ms/frame / 0.49% of the 15.700 ms no-profile CPU
mean before its entry guard.

Broadening the selection does not produce a robust product candidate. At 80%
dominance and five minimum samples, all 278 selected edges account for 7,137
samples / 56.89% of dispatches. Applying the same measured slope yields an
optimistic 0.843 ms/frame / 5.37% before **any** entry guard, exact-successor
check, trace miss, code/data footprint, or winner-selection error from
five-sample edges. The top 204 edges are required merely to cross 5% in that
zero-overhead model. PERF-076 already demonstrated that broad linking loses
most of its theoretical gain once safety and footprint costs are real.

## Decision

**Reject a dispatcher-only trace wrapper or 200+-edge trace forest.** The
focused semantics are valid and retained, but the available dispatch saving is
insufficiently separated from the 5% threshold to justify product ABI changes
or a full game module.

The remaining superblock hypothesis is narrower and different: emit a small
representative hot sequence in one generated C region so Clang can keep guest
state live across former boundaries. The next preflight must compare arm64
loads/stores and measured host cost against separate chunk calls. Continue
only if state-spill elimination supplies material gain beyond dispatch removal.

No game, module, app, product ABI, or Simulator changed. Final Destination and
G6 remain blocked by G5.
