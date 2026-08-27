# G5 finite-normal FPRF hot path: preflight rejection

## Question

After PERF-059 ruled out scalar-FMA mode flags, exact arm64 offset mapping
located the repeated floating-point samples. In `ppc_fmadd_op`, the most
frequently displayed offsets land in final force-single, classification, and
FPSCR writeback. In `ppc_fmuls`, the largest displayed groups likewise land at
classification and the final combined FPRF/FI/FR store, not at `fmul`.

Could the overwhelmingly common finite-normal result return its sign class
early while a cold helper handles zero, subnormal, infinity, and NaN?

## Falsifiable candidate

A disposable exact-GXRuntime host harness preserved the existing FMA helper
and replaced only `classify_f32` at final writeback. The common path checked
the exponent and returned positive-normal `0x04` or negative-normal `0x08`.
A `noinline,cold` helper preserved every special classification.

The semantic gate compared one million original/candidate 32-bit
classifications and 100,000 complete `CPUState` results spanning all eight
single/double, add/subtract, positive/negative scalar-FMA modes. Six aggregate
timing batches passed both gates.

## Corrected host result

The first synthetic recurrence eventually overflowed and mostly exercised the
cold path, so it was excluded. The corrected benchmark keeps results finite
and normal, alternates arm order, and executes the complete helper through
function pointers. Across 54 paired runs of 5,000,000 operations per arm:

| Metric | Control | Candidate |
| --- | ---: | ---: |
| Mean cost | 7.144759 ns | 9.364704 ns |
| Pair wins | 54 | 0 |

The candidate/control cost is 1.311x. Disassembly explains the counterintuitive
result: the current longer classification uses independent predicated integer
work that Apple M1 can overlap, while the explicit exponent branch serializes
the common path.

## Decision

**Reject PERF-060 before module/game build.** Do not split normal and special
FPRF classification, and do not infer performance from a shorter source or
instruction count on Apple Silicon. No repository source, module, package, or
runtime changed. G5 remains open and G6/iPadOS remains blocked.

Evidence: `docs/evidence/g5-fprf-hotpath-rejection/host-preflight.txt`.
