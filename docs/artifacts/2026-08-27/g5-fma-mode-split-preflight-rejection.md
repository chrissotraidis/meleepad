# G5 dominant scalar-FMA mode split: preflight rejection

## Question

The promoted no-logger Fountain sample placed 356 CPU-thread samples in
`ppc_fmadd_op`. Generated source contains 3,677 calls, and 2,199 of them use
the same compile-time mode: single precision, add, non-negative. Does routing
that dominant mode to a fixed-mode helper remove enough flag handling to
justify a generated-module experiment?

## Falsifiable candidate

A disposable arm64 host preflight cloned the exact promoted
`ppc_fmadd_op(..., true, false, false)` path into a fixed-mode helper. It kept
the existing `ppc_fma`, result writeback, FPSCR, FI/FR, exception, and paired
lane behavior. No repository source, generated module, package, or runtime was
changed.

The semantic gate compared the complete `CPUState` after generic and fixed-mode
execution over fixed IEEE-754 edge patterns and randomized operand bits. Eight
batches of 20,000 cases passed, for 160,000 complete-state comparisons.

## Host timing result

Each timed pair executed 5,000,000 operations per arm through volatile
function pointers. Across 56 paired runs:

| Metric | Generic | Fixed mode |
| --- | ---: | ---: |
| Mean cost | 19.347089 ns | 19.362982 ns |
| Pair wins | 27 | 29 |

The generic/fixed ratio of means is 0.999179. The fixed-mode arm therefore
trends 0.08% slower, with a nearly even 29/27 win split. Earlier short batches
also moved in both directions. There is no repeatable host improvement to
amplify through a costly 237-chunk module build and live deterministic replay.

## Decision

**Reject PERF-059 before a module/game build.** The outer constant flags are
not the material dynamic cost in `ppc_fmadd_op`; adding another exported helper
would add code and maintenance without a causal speed signal. Do not retry the
same outer mode split.

The next FMA investigation, if selected by a fresh sample, must attribute and
optimize a specific operation inside `ppc_fma` or its classification/rounding
path while preserving the exact semantics retained earlier. G5 remains open,
G6/iPadOS remains blocked, and the active package is unchanged.

Evidence: `docs/evidence/g5-fma-mode-split-rejection/host-preflight.txt`.
