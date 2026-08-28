# G5 complete-function register-cache preflight

Date: 2026-08-28

## Question

Can a complete hot guest function—not a modeled instruction slice—benefit from
single-entry generation and explicit guest-register caching while retaining the
canonical arbitrary-entry chunk as fallback?

## Actual generated function

`scripts/make-single-entry-chunk.py` mechanically narrowed the current
`func_80321940` entry to guest function `0x803248DC` and its one internal return
PC `0x80324990`. LLVM dead-code elimination reduced the isolated arm64 object
from 323,112 to 8,452 text bytes. Narrowing entry alone did not improve runtime:
two corrected million-call runs measured canonical 176.310/176.951 ns versus
176.474/177.185 ns.

The reason is structural: emitted C still explicitly reads/writes `CPUState`,
so the compiler cannot invent guest-register caching merely because unrelated
labels disappear.

The same mechanical tool then cached the six live GPRs and eight live FPR/PS1
pairs and retained only the exact first FP-unavailable gate at `0x803248F0`.
The function contains no `mtmsr`; later FP gates are redundant only in this
single-entry form. The resulting object is 8,088 text bytes.

`scripts/g5_single_entry_preflight.c` compares all CPU-state bytes except the
intentionally different RAM pointer plus the complete 128-byte touched stack
window. All 4,096 randomized cases pass, including 512 FP-disabled entries and
all initial downcount values from 0 through -255.

Two million-call repeats measured:

| Run | Canonical | Cached single entry | Saving | Local gain |
| --- | ---: | ---: | ---: | ---: |
| 1 | 176.404542 ns | 157.149125 ns | 19.255417 ns | 10.915488% |
| 2 | 176.381750 ns | 159.267125 ns | 17.114625 ns | 9.703172% |

FP caching without GPR caching reached 8.72%; GPR-only caching reached 1.12%.
The combined design is real, but this exact region owns only 52/1,531 chassis
samples. It projects about 0.33-0.37% of generated CPU time, far below 5%.

## Decision

Do not build a one-function game candidate or infer that function splitting
alone helps. Retain both preflight tools. A viable implementation must apply
SSA/register state across a large portion of generated work while spilling at
helpers, exceptions, cycle exits, SMC boundaries, and arbitrary-entry fallback.
DolRecomp's existing LLVM backend already implements that architecture, so the
next bounded experiment is enabling its ordinary object output for LLVM 22 on
Apple ARM64. No product source, module, app, game, or Simulator changed.
