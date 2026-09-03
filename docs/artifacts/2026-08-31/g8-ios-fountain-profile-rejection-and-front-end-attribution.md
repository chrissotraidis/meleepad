# G8 iOS Fountain profile rejection and front-end attribution

Date: 2026-08-31

Status: **PERF-242 candidate rejected; PERF-243 mechanism narrowed; G8 row 7 remains failed**

## Question

Does the valid Fountain-trained exact-source profile reverse the visible slow
phase, and, if not, what broad machine cost should constrain the next build?

## Exact control failure

The control module is the retained 81,006,192-byte arm64 iOS Simulator image
with SHA-256
`af1364e6fabe9ee29d2a64ee6268bd80ba3ef2aaa47de9c7741655fae9f3211b`.
A fresh external-pipe route visibly selected P1 Fox, CPU Donkey Kong, and the
literal Fountain of Dreams tile, then completed the two-minute match and
reached results.

The 18 complete ten-second combat rows measured:

| Metric | Control A |
|---|---:|
| FPS mean / minimum | 41.772 / 17.0 |
| VPS mean / minimum | 41.778 / 17.0 |
| speed-ratio mean / minimum | 0.704 / 0.288 |
| DMA underruns | 94 -> 884 (+790) |

This is an exact route failure. It is not a candidate comparison and does not
pass row 7.

## Candidate reversal and rejection

The candidate is the strict-use 82,710,960-byte arm64 iOS Simulator module
with SHA-256
`4f3c3fd88db3be4bbf9cdadec148f2b33089c19397a14e2e41d349344255a08e`.
It uses the valid 6,556-function merged profile containing 1,364,776,045
`chassis_dispatch` entries and nonzero counts for the three previously
uncovered slow-phase chunks.

The exact automated candidate route did not complete: fixed input delays fell
into attract mode, and the alternate MemoryWatcher client could not bind its
UNIX socket because the Simulator container path exceeded the platform socket
length. Those attempts are invalid and are not reported as a Fountain
comparison.

A clean candidate run and a fresh control reversal then used the same normal
product input publisher and natural title/attract route. Both exhibited the
same short-tap harness limitation, so it is not attributed to the candidate.
The first ten ordinal performance rows are a bounded route-integrity screen:

| Metric | Candidate | Control B | Candidate change |
|---|---:|---:|---:|
| FPS mean | 35.210 | 47.820 | -26.37% |
| FPS minimum | 19.1 | 29.3 | worse |
| VPS mean | 36.100 | 47.810 | worse |
| speed-ratio mean | 0.609 | 0.810 | -24.82% |
| speed-ratio minimum | 0.322 | 0.547 | worse |
| DMA-underrun delta | +387 | +334 | +15.87% |

This is not an exact-guest-state speed comparison, but it is sufficient to
fail the loop's route-integrity gate: the candidate materially regresses other
required visible phases and audio starvation. It therefore does not earn
another full Fountain replay.

The reversal also retained visible control failure. A later four-character
Fountain attract scene reported 30.7 FPS; its image is
`docs/evidence/g8/perf242-control-four-player-fountain-30.7fps.jpg`
(SHA-256 `e6af0828...fbfd52f`). No result here describes the control as
playable.

## Binary explanation and rejected flag screens

The candidate's `__text` grows from 80,343,252 to 82,023,340 bytes (+2.091%).
The three newly trained generated functions change as follows after ThinLTO:

| Function | Control span | Candidate span | Control/candidate `bl` count |
|---|---:|---:|---:|
| `func_8000D940` | 341,536 | 434,256 (+27.15%) | 2,140 / 1,213 |
| `func_8004D940` | 321,280 | 339,248 (+5.59%) | 2,144 / 410 |
| `func_80275940` | 360,488 | 376,152 (+4.35%) | 882 / 315 |

PGO is driving substantial link-time helper inlining and code expansion.
Two bounded flag screens were rejected before a product build:

- `-fno-unroll-loops` produced byte-identical text for all three non-LTO PGO
  objects; unrolling is not the cause.
- `-fno-inline-functions` made three representative ThinLTO mini-links
  1.30%, 2.27%, and 1.43% larger than their standard equivalents. A blanket
  inline clamp does not reverse the mechanism.

These screens do not prove that code growth alone caused the full live
regression, and no broad compiler flag is promoted from them.

## Crowded-combat CPU-counter result

A separate fresh control run reached visible four-character Brinstar attract
gameplay at 31.1 FPS. This is the same crowded-combat workload class, not the
literal Fountain route. The `performance` rows surrounding the bounded window
held 16.7-32.2 FPS, 16.9-32.3 VPS, speed ratios 0.319-0.565, 413-579 draws,
and continuously growing DMA underruns.

The previously rejected `xctrace` CLI attach route was not repeated.
Instruments UI recorded a four-second, host-wide Apple M1 `CPU Counters`
trace and filtered it to the exact Simulator app PID 75863. The MeleePad track
reports:

| Apple CPU Bottlenecks class | Share |
|---|---:|
| Instruction delivery | 42.22% |
| Instruction processing | 21.22% |
| Discarded | 6.66% |
| Useful | 30.03% |

The 342 MiB trace and privacy-bearing result screenshot remain private. The
result screenshot SHA-256 is
`0756f13dd254ce7b3457a853e5c3a7a0553049ae222d463e7570346a036cf03a`.
CLI export emits overlapping-Simulator-dylib warnings, so the UI's filtered
summary is the retained metric source. Instruments analysis later imposed
severe observer load; post-capture runtime rows are excluded.

This confirms material instruction-front-end pressure for crowded combat on
the M1 Simulator host. It does not quantify literal Fountain and cannot be
used as physical-iPad evidence.

## Decision and next experiment

- Reject and remove the Fountain-composite PGO candidate from active use.
- Restore the exact control module `af1364e6...`; stop the app and Instruments.
- Keep G8 row 7 failed and physical-iPad promotion closed.
- Do not retry smaller chunks, `-Oz`, hot/cold splitting, unroll flags, or a
  blanket inline clamp; they already have direct negative evidence.
- Next build one structurally distinct mixed-LTO preflight: retain strict
  frontend-PGO block weights in generated chunks but compile those chunks to
  native Mach-O without ThinLTO, while leaving the small GXRuntime/runtime
  helpers on the existing ThinLTO path. Before any live install, require a
  distinct signed module, no profile mismatch, no growth in the three named
  functions, and a whole-module text reduction relative to control. Only then
  run the fixed Fountain control/candidate/control phase reversal and retain
  it solely for a measured >=5% gain with no visual or audio regression.

No ROM, extracted game data, generated module, profile, trace, private path,
or save is committed.
