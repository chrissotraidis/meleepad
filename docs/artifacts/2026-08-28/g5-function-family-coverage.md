# G5 function-family coverage and leaf-cache bound

Date: 2026-08-28

Status: **LEAF-ONLY STATE CACHE REJECTED; INTERPROCEDURAL PREFLIGHT NEXT; G5 OPEN**

## Question

PERF-083 selected profile-guided generated-C regions with live guest state as
the next structural route. Can the simpler first implementation cache state
only inside guest functions that contain no direct or indirect guest calls and
still project above the 5% CPU-thread retention gate?

## Reproducible attribution

`scripts/analyze-macos-sample-guest-cost.py` now optionally reads the GALE01
function map, resolves every mapped guest PC to a function span, scans the
matching generated C tree once, and reports the number of `bl` and `blrl`
instructions in each span. Sorted guest PCs plus prefix call counts keep the
complete-map run near five seconds instead of rescanning the full instruction
set for every symbol.

The symbol names are diagnostic grouping labels, not semantic authority. The
decomp map has known coarse boundaries in this executable: for example its
`HSD_PadRenewGameStatus` span starts at `0x80377B54`, while generated control
flow shows the sampled routine's prologue at `0x80377B6C`. Selection therefore
uses exact guest PCs and generated call instructions; it does not infer a
replacement from a symbol name.

Two independent retained line-symbol Fountain profiles give the same
architectural result:

| Profile | Mapped samples | All no-call share | Unclosed no-call share | Local gain needed for 5% |
| --- | ---: | ---: | ---: | ---: |
| promoted profile-free line sample | 7,458 | 23.531751% | 14.293349% | 34.981% |
| current-PGO line sample | 1,127 | 32.830515% | 17.302565% | 28.897% |

"Unclosed" removes the two leading no-call spans at `0x8033F954` and
`0x803407C4`, whose exact hot subregions independently reproduce the already-
closed matrix FIFO and PSMTXConcat work. Counting them again would overstate a
new leaf-cache opportunity.

The larger profile resolves 7,457/7,458 samples into 756 sampled function
spans. Its 165 no-call spans own 1,755 samples; removing the two closed spans
leaves 1,066 samples. The smaller profile resolves all 1,127 samples into 316
spans; 77 no-call spans own 370 samples, and 195 remain after the same
exclusion.

Input/output hashes:

- promoted profile-free line sample:
  `df7c5ebc7d4ab26bfa09830435e69a9f74adf79d11aa20c66391977b7a3ce4b3`
- complete promoted attribution CSV:
  `6d36c52fef3413e8922dfcb571f1ca6e123130fd8a5106662599166ea80f3bad`
- current-PGO line sample:
  `c91d7380ddd823a9d86bb2d56ec2512053c5a825963294fe73d175bc0c25f5fe`
- complete current-PGO attribution CSV:
  `ff5d125d98a7134d9607f4f563a72f643ef80dc586e67c2ac3bc04ca2388ad5`

The profiles remain private local inputs. The committed analyzer and these
hashes make the classification reproducible without publishing game-derived
generated code.

## Decision

Reject a leaf-only state-cache implementation before modifying DolRecomp or
building a game module. Its defensible coverage requires a 28.897-34.981%
local improvement merely to reach 5%, before entry/exit synchronization,
guards, footprint, and sample error. The real complete-function cache in
PERF-081 repeated only 9.70-10.92%; the 21.29-21.79% modeled result in PERF-079
was a seven-instruction region with negligible absolute cost. Neither supports
the required leaf-family gain.

This does not reject profile-guided state retention. It proves the next
representation must cross selected guest calls. The smallest actual sampled
case is the routine at `0x80377B6C..0x80377CE4`, which has mutually exclusive
calls at `0x80377C04` and `0x80377C18` to the exact matrix kernel at
`0x803408A0`. The next data-free preflight must compare canonical dispatch with
a guarded parent/callee region, preserve cycle, exception, FP, SMC,
forced-fallback, and host-call exits, and then combine its measured gain with
exact parent/callee coverage. No product build follows unless an aggregatable
interprocedural mechanism projects above 5%.
