# G5 generated chunk-size preflight and rejection

Date: 2026-08-26

## Question

Can the generated C module reduce large host-function and jump-table cost by
lowering the default 4,096-instruction chunk size, while preserving lockstep,
visible behavior, and the required Fountain frame-time distribution?

## LLVM preflight

`moderngekko-port ... --backend llvm` immediately reported that the LLVM
backend is unavailable in this build. The installed Homebrew LLVM is 22.1.8,
while DolRecomp currently accepts LLVM 19 or 20. More importantly,
`llvm_backend.cpp` rejects production targets other than x86-64 Linux and
Windows. No package or toolchain was installed or changed: using LLVM for
Apple arm64 would be a backend port, not a bounded G5 experiment.

## Isolated C1024 candidate

The one variable was `DOLRECOMP_C_CHUNK_INSTRUCTIONS=1024`, reduced from the C
backend default of 4,096. The candidate generated 947 hashed chunks and a
roughly 72 MB module, versus the canonical roughly 78 MB module. It was staged
only in a temporary ad-hoc-signed app; the product package remained untouched.

A short headless lockstep screen completed with 499 checks, seven reports,
six fallback skips, three zero skips, and zero undercharges. The matched
canonical screen completed with 392 checks, eight reports, five fallback
skips, two zero skips, and zero undercharges. The candidate did not introduce
a new divergence class, but this was only a bounded preflight, not semantic
acceptance.

## Visual route

Computer Use verified coherent 59.9 FPS CSS, P1 Pikachu, CPU Yoshi, the literal
Fountain of Dreams stage, live 60.0 FPS combat, coherent fighter geometry, and
only the known reference-parity Fountain lower-floor reflection. The route is
retained under the accurate CPU-Yoshi filename; it is not labeled CPU DK.

## Fountain result

Candidate frames 13,510-17,163 (3,654 frames) measured:

| Metric | Result |
|---|---:|
| Mean / FPS | 16.739333 ms / 59.740 FPS |
| Median / p95 / p99 | 16.667062 / 17.866794 / 20.801313 ms |
| Worst | 58.535875 ms |
| Frames <=16.7 ms | 55.090% |
| Frames >25 / >50 ms | 17 / 2 |
| CPU-thread mean / p95 | 16.048816 / 17.602515 ms |
| Native dispatches mean | 161,477.597 |
| Guest cycles mean | 8,107,177 |

The candidate fails the absolute G5 p95 requirement. It also increased native
dispatches relative to the roughly 128,000/frame control because smaller
generated functions create more cross-chunk returns. No matched exact-roster
control was justified after the absolute failure.

## Decision

**LLVM BACKEND PATH REJECTED AS OUT OF SCOPE; C1024 CANDIDATE REJECTED AND
REMOVED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.**

The temporary app was restored to canonical module SHA-256
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`
and re-signed. The 617 MB generated candidate directory was moved to Trash.
No runtime or Simulator remained.

Do not retry smaller generated chunks. The result shows that function-size
reduction alone trades larger functions for more dispatch boundaries. The
next codegen experiment must reduce cross-segment return/redispatch cost while
preserving SMC verification, exceptions, host calls, exact cycle accounting,
and bounded event delivery.
