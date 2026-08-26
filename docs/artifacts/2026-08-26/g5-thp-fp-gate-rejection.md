# G5 THP inline FP-gate rejection

Date: 2026-08-26

## Attribution

The Apple CPU Counters trace retained by PERF-041 also contained time-profile
stacks for the visually gated How-to interval. On the CPU thread:

- `func_8032D940` contained 68.09% of samples;
- adjacent `func_80331940` contained 11.54%;
- `psq_store_value`, `ppc_psq_store`, `psq_load_value`, and `ppc_psq_load`
  together accounted for a large part of the leaf cost;
- `ppc_fp_available` alone was 4.40%; and
- generic hardware writes plus the external-write hook were also material.

The GALE01 symbol map identifies the hot guest range as Nintendo THP video
decode: `THPVideoDecode`, `__THPDecompressiMCURow640x480`, and
`__THPDecompressiMCURowNxN`. The apparent Mario/Bowser fight is therefore a
THP instructional movie, not ordinary live combat.

## Candidate

Generated FP and paired-single instructions previously called
`ppc_fp_available` unconditionally. The candidate emitted an inline check of
architectural `MSR.FP` and called the helper only when the bit was clear. This
is semantically exact: set means available; clear still uses the existing
lazy-FP/exception helper.

A regression first failed specifically because the inline gate was absent.
After the change:

- generated-C codegen/compile passed;
- enabled-FP scalar-single execution passed; and
- disabled FP reached vector `0x800`, saved the instruction address in SRR0,
  set `PPC_EXC_FP_UNAVAILABLE`, and left the destination unchanged.

The reproducible patch was applied only long enough to build and test the
candidate; it is not retained after rejection.

## Semantic screen

The candidate module SHA-256 was
`645b4b4fe5c7b011037f30fa53c013c7f0370510d07055a56af36e90652bbb7a`.
The matched 5,000,000-dispatch, 20-print, 512-step lockstep screen passed:

- 1,401 checks;
- canonical 88-report set;
- seven fallback skips;
- three zero skips; and
- zero undercharges.

The lockstep log SHA-256 was
`51258da6c491cb1bd567423c73ae966b41700c41455d43835b542b88288e92aa`.

## Live result

Computer Use verified coherent four-player attract combat at 47.5 FPS and then
39.1 FPS. The latter retained screenshot is
`docs/evidence/g5-fp-gate-rejection/four-player-39.1fps.jpeg` (SHA-256
`29c1d3a6ad434649687e3c1164337ea6fdecbdad80cdf15c9eac8b4fb32e0550`).

The clean local bracket, frames 8,050-8,250, measured:

| Metric | Candidate |
|---|---:|
| Frames | 201 |
| Mean / FPS | 26.055370 ms / 38.379804 FPS |
| p95 / worst | 28.096375 / 184.405500 ms |
| Frames <=16.7 ms | 0% |
| CPU-thread mean / p95 | 25.036673 / 27.727948 ms |
| Video build / present mean | 0.061610 / 0.018317 ms |
| Guest cycles/frame | 8,106,810.721 |
| Native dispatches/frame | 215,831.507 |

An earlier 201-frame window contained a 2.795-second transition and is excluded
from the decision. The clean bracket and visible 39.1 FPS state are already an
absolute ordinary-combat failure, so How-to and Fountain were not run.

The candidate `__text` was 82,488,616 bytes versus canonical 81,633,212 bytes:
+855,404 bytes (+1.05%). Adding a condition at every generated FP instruction
increased code footprint enough to overwhelm the sampled helper saving.

## Decision

**INLINE FP GATE REJECTED AND REMOVED; G5 OPEN; G6 BLOCKED.** Generator source,
focused tests, bootstrap patch stack, active-module pointer, and local tools are
canonical. Active source module is `258da42...`; packaged module/runner remain
`2dce1352...` / `9bff54e4...`. No product app was modified. The candidate cache
and diagnostic app/logs were moved to Trash and are recoverable.

Next: add a default-off address histogram to the THP-time external-write path.
Determine whether decoded PSQ stores repeatedly take the generic MMU hook for
a small RAM address range. Do not retry global FP gates or inline PSQ expansion.
Only if the histogram proves one stable RAM mapping should a focused,
MMU-validated contiguous-buffer fast path be considered.
