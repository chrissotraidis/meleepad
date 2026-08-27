# G5 current-PGO line attribution and gather-check rejection

Date: 2026-08-27

## Question

After the display and timer controls failed, which coherent host or generated
routine remained hot in exact current-PGO Fountain combat, and could removing
JIT-only FIFO discovery work from the static-recompiler gather path materially
reduce the strict frame-time tail?

## Byte-identical line-symbol attribution

The retained current-source PGO module was rebuilt in a disposable directory
with `-gline-tables-only`. The shipping and line-symbol variants have identical
81,959,380-byte `__text` sections with SHA-256
`5df909902be0306ad723a7882178854197afc3da38ae8330555544163de96bae`.
Their Mach-O UUIDs differ because debug metadata changes link identity, so the
sample used the matching disposable dSYM rather than attaching symbols to the
shipping binary.

The signed attribution app loaded the retained Pikachu/CPU-Fox Fountain state
only after 1,001 readiness fields, reported exact post-load GameState
`0x02020102`, settled for 120 fields, sampled for 10 seconds at 1 ms, and shut
down cleanly. Of 1,599 samples in `StaticRecompCore::Run`, 1,531 were in the
generated chassis.

The source lines did not expose another monolithic guest kernel:

- the six paired FIFO stores in `WriteMTXPS4x3` accumulated 99 samples, but
  their deterministic 64-bit gather optimization was already independently
  rejected;
- the large generated `func_8035D940` had 106 non-entry samples spread across
  color/texture-expression construction, resource assignment, render-mode
  work, and other unrelated blocks;
- cross-chunk opcodes were likewise diffuse (`psq_st` 134, `lwz` 120, `bc`
  103, `stw` 97, `lfs` 61, `blr` 52, `bl` 51, and `psq_l` 49); and
- 19 chassis samples reached `JitInterface::CompileExceptionCheck` below
  gather-pipe writes.

The last item was coherent and previously untested. `GPFifo::CheckGatherPipe`
updates the pipe and then calls the JIT-only `CompileExceptionCheck(FIFOWrite)`.
Dolphin's JIT gather paths instead use `FastWrite*` followed by
`FastCheckGatherPipe`. The static-recompiler candidate adopted that sequence
without changing write widths, byte order, or check cadence; the generic
eight-byte loop still checked after every byte.

## Regression-first candidate

A focused two-case source regression first failed against the canonical path:

- all 8/16/32-bit arms had to use `FastWrite*` plus one
  `FastCheckGatherPipe`; and
- the generic eight-byte arm had to preserve its per-byte check boundary.

Both cases passed with the candidate. The candidate runner was then rebuilt
twice to SHA-256
`d0091294323a9b9b02a11dc760a6d00020b4951c866a1652b558043ca93a27eb`.
The intervening reversal control rebuilt to
`dc7c96aac11b19fada69306d24f39d470d2e9dee6e5baedcf590baf0e947da56`.
The signed PGO module remained unchanged at SHA-256
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

## Exact Fountain A/B/A

Each isolated signed app loaded the same state, accepted the final occurrence
of emulated frames `48123..48562`, and produced exactly 440 rows. Guest work
matched at 1,501,757,755 cycles, 51,380,895 native dispatches, and 882 hook
fallbacks. Candidate A/A2 each emitted 905,744 bursts versus 905,756 in the
control; the 12-burst difference is the expected path effect and repeated
exactly.

Percentiles below use linear interpolation, consistent with the other G5
reports.

| Metric | Candidate A | Reversal control | Candidate A2 |
| --- | ---: | ---: | ---: |
| Mean | 16.737733 ms | 16.731540 ms | 16.731611 ms |
| p95 | 17.883089 ms | 17.725747 ms | 17.843200 ms |
| p99 | 18.506464 ms | 18.575725 ms | 18.560185 ms |
| Worst | 132.117125 ms | 129.881708 ms | 129.267458 ms |
| CPU-thread mean | 11.463063 ms | 11.485476 ms | 11.378668 ms |
| CPU-thread p95 | 12.746827 ms | 12.643227 ms | 12.480317 ms |
| Frames <=16.7 ms | 55.682% | 55.000% | 55.000% |
| Wake lateness mean | 0.520719 ms | 0.522584 ms | 0.540535 ms |
| Wake lateness p95 | 1.148723 ms | 1.098006 ms | 1.138964 ms |

The candidate lowers CPU-thread mean by only 0.022-0.107 ms. Total mean is
unchanged, and both candidate p95 values are worse than the reversal control.
This is far below the required 5% retention threshold.

## Decision

**Reject and remove the static gather fast-check candidate.** Canonical source
is restored, its candidate-specific regression is removed, and the rebuilt
runner again has reversal-control SHA-256 `dc7c96...`. Do not retry JIT FIFO
discovery removal, gather-width combination, or the already-rejected paired
FIFO store variants without a new mechanism.

G5 remains open: both candidate repeats and the control fail p95, p99, and
worst <=16.7 ms. Final Destination is not run because Fountain did not pass;
G6 remains blocked. The next experiment must separate the ordinary 17-19 ms
tail from the rare 129-132 ms stall and trigger attribution at the stall,
rather than selecting another edit from the diffuse generated sample.

## Retained evidence

- `docs/evidence/g5-static-gather-fast-check-rejection/pgo-fountain-linesym.sample.txt`
  — SHA-256
  `c91d7380ddd823a9d86bb2d56ec2512053c5a825963294fe73d175bc0c25f5fe`;
- `candidate-a.phase.csv` — SHA-256
  `86ec18b9cbf318b7fb51833582d2cfd7a2223e008b07b145f036ea0dfb2c5666`;
- `control.phase.csv` — SHA-256
  `211a2a07bac079b46b5c2ef9530825b60d280fe971143fdd99094491e3120aa2`;
- `candidate-a2.phase.csv` — SHA-256
  `953cab24ef685b7aa4a36456c8eaa09eb4a326ba4669efc689a9d6d60e6b6fa0`;
  and
- `g5-fastcheck-reversal-test.txt` — failing-before SHA-256
  `3fc51fba08c52f46c1b9f6e67ad7151f99b31c5163fe65f74dcbdb4ef4d5fe6a`.
