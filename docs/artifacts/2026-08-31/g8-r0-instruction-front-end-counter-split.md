# G8 R0 instruction-front-end counter split

Date: 2026-08-31
Decision: **DIAGNOSTIC COMPLETE; ROW 7 STILL FAILS**

## Controlling reality

The product is not playable in the iPad Simulator and is not eligible for
physical-iPad promotion. The controlling observation remains the user's normal
installed-app route: 21.9 visible FPS in P1 Samus versus level-1 CPU Kirby,
Stock/04/05:00, on Fountain of Dreams. The state-driven diagnostic harness
reproduces that exact roster, rules, stage, and combat state, but its faster
windows do not replace the manual floor.

The route harness also had one remaining watcher-attachment race. It formerly
waited for a transient title pointer to become nonzero and then zero; a late
watcher could miss both edges. The first action now taps Start until the
revision-1.00 scene byte reports the CSS state. The independent roster, rules,
stage-slot, and combat predicates remain the vetoes. Focused tests pass 27/27.
This is a diagnostic reliability repair, not a game-speed change.

## Valid measurements

Both samples selected only the live MeleePad process and were taken inside the
state-verified exact match. Counts are hardware-counter totals; displayed
instruction rows are sampling counts and are not substituted for raw totals.

| Counter family | Count | Ratio to cycles |
|---|---:|---:|
| IAT cycles | 1,602,654,441 | 100% |
| Fetch restarts | 75,763,435 | 4.727% |
| L1I cache demand misses | 13,788,897 | 0.860% |
| L1I TLB misses | 6,313,769 | 0.394% |
| L2 TLB misses | 3,171,799 | 0.198% |
| MMU instruction-fetch walks | 3,224,841 | 0.201% |
| Discarded-sampling cycles | 1,674,232,112 | 100% |
| Incorrectly predicted branches | 7,754,840 | 0.463% |
| Conditional mispredictions | 5,866,026 | 0.350% |
| Other mispredictions | 1,888,814 | 0.113% |
| Unpredicted memory dependencies | 253,939 | 0.015% |

The valid discarded sample contains 777 displayed branch-misprediction
samples and 32 memory-dependency samples. They are distributed: examples
include generated `func_` bodies, `chassis_dispatch`,
`OpcodeDecoder::RunFifo<false>`, `LoadBPReg`, shader-UID work, and framework
code. No row owns enough of the sample to justify a one-branch or one-function
rewrite. One earlier trace crossed from combat into the results screen and was
discarded rather than blended into these totals.

The exact route's runtime log independently continues to show the product
failure class: active work includes 34.4/34.0, 41.3/41.4, and 44.9/44.8
FPS/VPS rows with the CPU-GPU thread near saturation and DMA underruns rising.
A visible exact-route frame immediately before the discarded sample read 35.2
FPS. Instruments changes scheduling and later rows include observer and phase
transition effects, so none of those values is acceptance evidence and none
supersedes 21.9 FPS.

## Decision

Instruction delivery remains the broad measured direction, but neither
translation misses nor branch misses is a standalone explanation for the
roughly 2.74x throughput increase required to move 21.9 to 60 FPS. Even an
aggressive branch-penalty bound yields only a single-digit-percent opportunity,
and the translation ratios are smaller. Do not optimize page tables, add broad
branch hints, or rewrite one sampled generated function on these counts.

This also does not reopen previously rejected work: non-LTO chunk compaction,
whole-module footprint-only variants, smaller chunks, generic direct-call
forests, last-chunk caches, broad guarded direct calls, hot/cold splitting,
and unsafe CPU/video splitting remain closed.

## Refined next experiment

The generated source contains 983,723 syntactic `ctx->pc` assignments across
about 9.34 million chunk-source lines; each of five sampled hot chunks contains
roughly 3,465-4,252 assignments. That is only a source-level materiality lead,
not proof that the stores survive optimization or may be removed safely.

Before another app/module build:

1. disassemble the current strict-PGO hot objects and count surviving guest-PC
   stores in the sampled functions;
2. classify every proposed elimination boundary against memory faults, hooks,
   fallback synchronization, SMC, interrupts, and external calls;
3. build only a bounded extracted semantic differential if the surviving
   instruction/store reduction projects at least 5%;
4. reject the direction before a product build if the optimizer already
   removes the stores, the projection is below 5%, or precise state cannot be
   preserved;
5. if it passes, run exact control/candidate/control first, then the two cold
   full routes and final ordinary manual route. The lower visible/runtime value
   decides.

No ROM, generated source, module, trace, profile, save, or private host path is
part of this repository artifact.
