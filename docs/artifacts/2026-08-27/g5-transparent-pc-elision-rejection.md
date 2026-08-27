# G5 transparent instruction PC-elision rejection

## Question

Apple CPU Counters on the exact late-Fountain state attributed 48.674% of the
CPU thread to instruction delivery, versus 40.665% useful work, 6.858%
processing, and 3.803% discarded work. The C backend already classified a
small set of instructions as guest-PC-transparent, but outside proved direct
loops it still wrote `ctx->pc` before every instruction. Would removing those
redundant stores lower the shared-state Fountain window?

## Regression and semantic gate

A regression-first DolRecomp test required straight-line `addi` and `xori` to
avoid PC materialization while preserving it at `blr`. It failed before the
candidate. The first implementation also removed PC stores around `b`/`bc`
and broke the existing timebase-loop regression, so the candidate was narrowed
to non-branch instructions; the established direct-loop proof remained the
only mechanism allowed to elide branch PC stores.

The narrowed candidate passed all 14 DolRecomp CTests and bootstrap
reproducibility. It reduced generated `ctx->pc` stores from 982,754 to 702,961
(-28.5%) and `__text` by 1,475,528 bytes. A bounded live lockstep screen matched
the promoted control at 1,398 checks, 91 reports, seven fallback skips, three
zero skips, zero undercharges, and zero maximum cycle deficit. A disposable,
ad-hoc-signed app visibly rendered coherent Pikachu/CPU-Fox combat on literal
Fountain; the promoted product was not replaced.

## Shared-state reversal

Both runs loaded the same local, repository-excluded Fountain state. The last
occurrence of emulated frames 48123 through 48562 supplied 440 consecutive rows
from each phase log.

| Metric | PC-elision candidate | Fresh canonical control |
|---|---:|---:|
| Mean / effective FPS | 20.149624 ms / 49.629 | 19.016881 ms / 52.585 |
| p95 | 21.983167 ms | 20.575625 ms |
| p99 | 22.878041 ms | 22.530375 ms |
| Worst | 23.463583 ms | 24.218334 ms |
| CPU-thread mean | 19.766180 ms | 18.601693 ms |
| Frames <=16.7 ms | 0.227% | 1.364% |
| Guest cycles | 3,567,157,803 | 3,567,157,806 |
| Native dispatches | 59,374,686 | 59,374,687 |
| Static bursts | 905,158 | 905,141 |
| Static fallback steps | 0 | 0 |
| Hook fallbacks | 882 | 882 |

The three-cycle, one-dispatch difference is negligible, while the candidate is
1.133 ms slower in mean frame time and 1.407 ms slower at p95. Earlier slower
controls were therefore host/path-state variation, not evidence of a retained
candidate gain.

## Decision

**CANDIDATE REJECTED AND REMOVED; G5 OPEN; G6 BLOCKED.** A large static code
reduction plus semantic success did not improve the exact live workload. Do
not retry global transparent-instruction PC-store removal. The next candidate
must address a newly measured dynamic cost inside the exact shared-state
window, not static instruction count or module size alone.

The canonical generator source and active module key
`1e1debc9fb83a31a` are restored. No game process or Simulator remains.

## Evidence

- `docs/evidence/g5-exact-window-attribution/exact-fountain.sample.txt`
- `docs/evidence/g5-exact-window-attribution/exact-fountain-linesym.sample.txt`
- `docs/evidence/g5-pc-elision-shared-state/candidate.phase.csv`
- `docs/evidence/g5-pc-elision-shared-state/reverse-control.phase.csv`
