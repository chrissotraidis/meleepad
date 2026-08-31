# G8 iOS mixed-LTO rejection

Date: 2026-08-31

Status: **PERF-244 rejected before a full Fountain route; G8 row 7 remains failed**

## Question

Can frontend-PGO retain its internal block layout while preventing the
profile-driven ThinLTO code expansion observed in PERF-242/243?

## Candidate construction

All 237 exact-source generated chunks were compiled with the valid merged
Fountain profile, strict profile mismatch errors, iOS Simulator 16.0 minimum,
`-O2`, `-ffp-contract=off`, and `-fno-fast-math`, but without ThinLTO. The
small module-export and GXRuntime helper objects retained the existing
ThinLTO link path. No source or product configuration changed.

The private candidate:

- is arm64 `IOSSIMULATOR`, minimum iOS 16.0, SDK 26.5;
- exports the same public symbol set and dependencies as control;
- contains no profiling or coverage sections;
- passes strict ad-hoc signature verification;
- is 68,614,592 bytes; and
- has SHA-256
  `5bc6b4e12d1cefeaa167f5a70fa210289905a038a6715d0b03e450ab12c217a5`.

## Structural result

The intended mechanism occurred:

| Binary/function | Control | Mixed-LTO | Change |
|---|---:|---:|---:|
| whole-module `__text` | 80,343,252 | 59,480,268 | -25.967% |
| `func_8000D940` span | 341,536 | 258,368 | -24.35% |
| `func_8004D940` span | 321,280 | 313,964 | -2.28% |
| `func_80275940` span | 360,488 | 300,008 | -16.78% |

This clears the predeclared structural gate. It does not establish that less
code is faster.

## Runtime integrity and absolute failure

The signed product loaded the exact 68,614,592-byte module, reached a coherent
title, accepted Start, continued into natural attract gameplay, and logged no
fatal, crash, malformed FIFO, mismatch, or desync condition. It therefore
clears a bounded runtime-integrity smoke.

Performance immediately rejects it. In the first ten complete intervals after
the external-pipe fresh launch:

| Metric | Mixed-LTO | PERF-242 control B |
|---|---:|---:|
| FPS mean / minimum | 20.570 / 10.4 | 47.820 / 29.3 |
| VPS mean / minimum | 20.530 / 10.2 | 47.810 / 29.7 |
| speed-ratio mean / minimum | 0.340 / 0.165 | 0.810 / 0.547 |
| DMA-underrun delta | +425 | +334 |

Visible four-character Fountain attract gameplay reported 23.3 FPS. The
subsequent sustained heavy route contained 19.1, 13.1, 10.7, and 10.4 FPS
intervals with corresponding VPS/speed collapse and rising underruns. This is
far below the immediate-failure threshold and approximately 57% worse than the
bounded control mean. The candidate does not earn an exact Fox/CPU-DK Fountain
route.

The runtime log remains private and has SHA-256
`e3c96ba7007d92c085ed916f93388c00603909721bb711fdb9d2cbd8f34f247d`.

## Interpretation

Code footprint alone is not the current solution. Removing ThinLTO from the
generated chunks saves 20.9 MiB of text but destroys transformations needed by
the existing static-recompiler path. The result is consistent with the prior
`-Oz` local timing rejection: a smaller generated representation can execute
substantially slower.

This does not prove every ThinLTO inline/import is beneficial. It proves only
that removing the entire generated-chunk ThinLTO pipeline is the wrong level
of control. PERF-243's instruction-delivery pressure remains real, but a
footprint-only candidate cannot be inferred from it.

## Decision and next experiment

- Reject the mixed-LTO candidate and do not copy it into any product build.
- Restore the exact 81,006,192-byte control module SHA-256 `af1364e6...`.
- Unset the two private external-pipe trace variables; stop the app.
- Do not retry non-ThinLTO generated chunks, smaller chunks, `-Oz`, broad
  outlining, or generic unroll/inline flags.
- Before another module build, use a bounded control-only CPU-counter capture
  on visually confirmed four-character Fountain to split the existing 42.22%
  instruction-delivery class into available cache/fetch versus branch/discard
  events. A next source candidate must name the dominant event and preserve
  ThinLTO; code size by itself is no longer a mechanism.

No ROM, extracted data, generated source/object/module, profile, save, trace,
or private path is committed.
