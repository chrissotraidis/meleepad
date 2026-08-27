# G5 deterministic 64-bit gather-pipe rejection

## Question

The promoted no-logger Fountain sample still placed the six consecutive
`WriteMTXPS4x3` paired stores at guest PCs `8033FAF0..8033FB04` on the hot
path. The earlier 64-bit gather-pipe candidate had been rejected without a
shared-state comparison. Now that the retained harness can load the same local
state and select emulated frames `48123..48562`, does routing each 8-byte
external store through `GPFifo::Write64` produce a causal gain?

## Fresh attribution

A 20-second promoted no-logger sample contained 14,646 CPU-thread samples,
11,690 in `StaticRecompCore::Run`. A disposable line-table twin was rebuilt
from the exact 237 generated chunks with the product's Release/ThinLTO flags
and an LTO object map. Its 81,235,476-byte `__text` is byte-identical to the
official module, SHA-256
`d1bd6f36ded2d8c9031fba3078cbf3cf6e64a75ea97dbb163c532b2fbeb265dd`.
The mapped run again attributed generated lines 20887, 20897, 20907, 20917,
20927, and 20937 to the six FIFO matrix stores. This confirms the old
attribution still applies after PERF-057; the diagnostic timing itself is not
used as acceptance evidence.

## Candidate and reversal

The current hook expanded an 8-byte gather-pipe write into eight checked
`Write8` calls. A failing-before source contract required an explicit
`case 8` calling `Write64`. The one-arm candidate built successfully and used
the unchanged official module SHA-256
`2fa34d164bf1833df32a1215c558396475b2a9cb3ae41f143c3790a40dbb27d7`.
Candidate A/A2 and a same-build local reversal each selected exactly 440 rows
and identical work:

- 1,501,629,399 guest cycles;
- 51,369,928 native dispatches;
- 905,572 static bursts; and
- 882 hook fallbacks.

| Metric | Candidate A | Local reversal | Candidate A2 |
|---|---:|---:|---:|
| Mean / FPS | 16.680304 ms / 59.951 | 16.516704 / 60.545 | 16.884788 / 59.225 |
| p95 | 17.472292 ms | 18.600167 ms | 18.597291 ms |
| p99 | 18.090459 ms | 19.978833 ms | 27.458917 ms |
| Worst | 20.333084 ms | 23.740959 ms | 101.670708 ms |
| CPU-thread mean | 15.928752 ms | 15.976463 ms | 16.015628 ms |
| CPU-thread p95 | 17.022845 ms | 18.115156 ms | 17.926302 ms |
| Frames <=16.7 ms | 52.727% | 65.000% | 64.773% |

Candidate A's roughly 0.048 ms CPU-mean advantage does not repeat: A2 is
roughly 0.039 ms slower than reversal. Both candidate means are slower, A2's
p95 is tied with reversal, and A2 contains a 101.7 ms host stall. This is not
a reproducible improvement and remains above the strict 16.7 ms p95 gate.

## Packaged-control contamination

The signed packaged runner produced 3,567,157,782 cycles and 59,374,687
dispatches over the same nominal rows, unlike both the candidate and the local
reversal. Its mean was 18.626525 ms. The package and current diagnostic build
use different CMake product configurations and binary identities, so that row
is retained only as evidence of control contamination and is not used for the
candidate verdict. The same-build reversal is the valid control.

## Decision

**Reject and remove the 8-byte gather-width arm. G5 remains open and G6 remains
blocked.** The fresh attribution is retained, but it does not justify retrying
`Write64`, global gather-width, or the same matrix-writer shortcut again. The
next experiment must aggregate non-entry source lines inside the remaining
large `func_8035D940` cost and select a different coherent instruction family.

The candidate source is removed, the canonical local runner is rebuilt, and
no game process or Simulator remains.

## Evidence

Raw no-logger and line-mapped samples, candidate A/A2, the same-build local
reversal, and the contaminated packaged control are under
`docs/evidence/g5-gpfifo64-deterministic-rejection/`. The RAM-bearing state,
generated chunks, diagnostic module, and local runner binaries remain
excluded.
