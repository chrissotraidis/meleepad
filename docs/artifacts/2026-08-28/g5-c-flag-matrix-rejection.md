# G5 AppleClang generated-C flag matrix

Status: **PERF-086 REJECTED; G5 OPEN**

## Question

Can a materially better AppleClang optimization mode make the existing
generated C fast enough before changing DolRecomp's translation architecture?

This is a bounded preflight, not a product benchmark. It reuses PERF-082's
exact 1,024-instruction private hot slice and its data-free retained harness.
The harness enters at guest `0x803248DC`, executes to `0x80324940`, and compares
every relevant `CPUState` and RAM byte before timing alternating candidates in
one arm64 process.

The product already builds generated translation units at strict `-O2
-ffp-contract=off -fno-fast-math` with interprocedural optimization enabled.
Every candidate retained the two strict floating-point flags. `-Ofast` was not
tested because it would violate the required guest floating-point semantics.

## Host and method

- host: Apple M1, arm64;
- compiler: Apple clang 21.0.0 (`clang-2100.1.1.101`);
- private source SHA-256:
  `f71a7702b470fd01d180d984b85814f841459f80bab562421798b273c46809ff`;
- retained harness SHA-256:
  `fa38650355cdcd37c21f1d7dd611d9d0874e62d1fc38e5b4cacfea59a35ca00c`;
- exact semantic result for every candidate: PASS, ending PC `0x80324940`,
  identical state and RAM, nine changed RAM bytes;
- first screen: nine alternating 500,000-entry samples per implementation;
- confirmation: three fresh nine-sample, 1,000,000-entry processes for the
  apparent winners and an identical-flag control.

The baseline and candidate came from the same exact C source. A preprocessor
rename changed only the candidate's exported symbol so both implementations
could be linked into one harness. Runtime helper objects were held constant.
No game data is retained in the repository.

## Results

| Variant | Text bytes | Host instructions | First candidate ns | Change vs paired O2 |
|---|---:|---:|---:|---:|
| O2 identity control | 64,756 | 16,189 | 98.179 | -0.745% |
| O3 | 65,244 | 16,311 | 98.817 | -0.271% |
| Os | 64,128 | 16,032 | 98.899 | -0.839% |
| Oz | 40,280 | 10,070 | 125.264 | **+26.040% slower** |
| O2, vectorizers disabled | 64,756 | 16,189 | 97.452 | -1.863% |
| O2, unrolling disabled | 64,756 | 16,189 | 98.771 | -1.069% |
| O2, `-mcpu=apple-m1` | 64,756 | 16,189 | 94.925 | -2.460% |
| O2, `-mcpu=native` | 64,756 | 16,189 | 98.152 | -3.482% |

Fresh-process confirmation put the paired changes at:

| Variant | Repeat 1 | Repeat 2 | Repeat 3 | Median |
|---|---:|---:|---:|---:|
| O2 identity control | -1.534% | +0.147% | -1.483% | -1.483% |
| no vectorizers | -2.036% | -1.870% | -1.057% | -1.870% |
| Apple M1 | -1.453% | -0.565% | -1.287% | -1.287% |
| native | -1.059% | -2.111% | -0.621% | -1.059% |

The identical O2 control itself moves by roughly 1.5%, demonstrating the
layout/process noise floor. Neither CPU tuning result separates from that
noise, and none reaches the 5% preflight gate. `-Oz` confirms the tradeoff
suggested by PERF-082: dramatically reducing generated text alone can slow the
actual hot path because it changes instruction selection and optimization.
This also agrees with the earlier product-level `-Oz` attempt, where ThinLTO
reoptimized the per-source choice and did not produce a distinct product
binary.

Raw summarized measurements are retained at
`docs/evidence/g5-c-flag-matrix-preflight/results.csv`. Private executables and
generated source remain under `/private/tmp/ssbmpad-cflag-matrix.EzXdrf` and
`/private/tmp/ssbmpad-llvm-slice.siHMxr` only.

## Research reconciliation

The applicable primary-source designs all optimize a larger translation unit,
not one emitted C statement at a time:

- QEMU TCG keeps frequently modified guest CPU state in host globals/registers,
  specializes stable CPU-mode state per translation block, chains blocks, and
  delays selected state flushes until a real boundary:
  <https://www.qemu.org/docs/master/devel/tcg.html> and
  <https://github.com/qemu/qemu/blob/master/docs/devel/tcg-ops.rst>.
- Dolphin's JIT explicitly combines basic-block linking with GPR/FPR register
  caches; its ARM64 FPR cache tracks whether a guest value is resident and
  dirty before flushing:
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/PowerPC/Jit64/Jit.cpp>
  and
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/PowerPC/JitArm64/JitArm64_RegCache.cpp>.
- LLVM profile-guided block placement and late hot/cold splitting can improve
  instruction delivery, but the current module's frontend/IR PGO and Mach-O
  order-file experiments are already rejected. Those tools also cannot remove
  semantic guest-state synchronization that the C source exposes at region
  boundaries: <https://llvm.org/docs/Passes.html>.
- Apple's CPU guidance says to measure instruction delivery, branch behavior,
  and cache/pipeline stalls on actual Apple silicon. PERF-083 already did that
  on this M1 and found the CPU thread dominant:
  <https://developer.apple.com/documentation/xcode/addressing-cpu-bottlenecks>.

## Decision and next experiment

**Reject compiler-flag tuning as the G5 route.** Do not build a module for O3,
Os, Oz, vectorizer, unroll, or `-mcpu` variants without a new source-level
mechanism that first clears the local 5% gate.

The next smallest structural experiment is an exact callful region with an
explicit local guest-state frame:

1. Select several adjacent high-cost parent/callee paths whose combined exact
   sample coverage can project at least 5% overall.
2. Promote only the live GPR/FPR/PS1/CR/XER fields used by that region into C
   locals; retain `CPUState*` for memory and runtime services.
3. Synchronize dirty locals before helpers that can observe state, exception or
   host-call exits, unknown indirect control flow, and the final region exit.
4. Reload only fields a helper can clobber. Preserve exact cycle, PC/LR,
   reservation, FP, LSQE/GQR, and write-journal behavior.
5. Require randomized full-state/full-RAM differential equivalence and a
   measured local gain whose profile-weighted projection exceeds 5% before a
   module or game build.

This is deliberately narrower than a new backend and broader than the rejected
single-leaf wrappers. It tests the core register-retention mechanism used by
QEMU and Dolphin while keeping the existing canonical fallback path.

No generator, module, app, package, game process, or Simulator changed.
