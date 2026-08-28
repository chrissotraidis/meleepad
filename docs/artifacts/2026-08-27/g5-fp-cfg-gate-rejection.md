# G5 CFG-local FP-gate rejection

Date: 2026-08-27

## Question

Could the C backend preserve an exact floating-point-unavailable check at
every possible direct entry while paying that check only once along a
straight-line control-flow region? This is distinct from PERF-067's rejected
per-chunk flag: it adds no runtime cache and no conditional branch at each
sequential FP instruction.

## Regression-first implementation

The candidate marked control-flow leaders, emitted the normal body check at
the first FP instruction in each region and after `mtmsr`, and moved later
exact-CIA checks into the generated direct-entry switches. Focused regressions
failed before the change and then covered:

- direct entry at a later FP instruction with FP disabled;
- `mtmsr` clearing MSR.FP between two FP instructions;
- branch fallthrough and target leaders; and
- generated-source placement of the body and direct-entry gates.

Six focused DolRecomp groups passed. A disposable instrumented module then
matched the canonical early-boot lockstep entry/end pair set, with 1,370
candidate PCs checked, the same 91 known report categories, seven fallback
skips, three zero skips, and zero undercharges. The candidate generated source
contained the same 129,826 total gates as control, but moved 94,146 (72.517%)
out of sequential bodies and retained 35,680 body gates.

## Candidate-specific PGO

The existing control profile could not be reused because the candidate changed
the generated CFG. A candidate instrumented arm64/macOS 14 module therefore
captured the same retained Fountain combat predicate used by PERF-063. The
capture had one start and one successful dump, and shutdown did not overwrite
it. Its merged profile has the exact expected 6,556 functions and 2,727,666
blocks, with 124,385,558,084 aggregate counts (91.8% of the established
control profile). Apple Clang accepted it without missing-data or hash
warnings.

The raw profile, merged profile, savestate, generated C, and dylibs remain
local and outside Git. The raw/merged SHA-256 values are
`818b230f...c9de` and `b60c5d8e...a421`.

The PGO-use module linked successfully, is native arm64, declares macOS 14.0,
exports only `_staticrecomp_get_module` and `_ppc_set_mem_write_journal`, and
passes strict ad-hoc signing. Its signed SHA-256 is
`d081b903...d6d1`. `__text` is 83,193,796 bytes versus the PGO control's
81,959,380 bytes, a 1.506% increase rather than PERF-067's 16.45% expansion.
The disposable signed app passed the package-layout and no-game-data scans.

## Exact Fountain candidate/control/candidate result

Each isolated run used Metal, Cubeb, the same savestate SHA-256
`e4813633...5de`, pre-load readiness frame 1,022, and verified post-load
revision-0 `GameState=0x02020102`. The last occurrence of every emulated frame
`48123..48562` exists in all three logs. All 440 selected rows match exactly:

- 1,501,629,399 guest cycles;
- 51,369,928 native dispatches;
- 905,572 static bursts;
- zero static fallback steps; and
- 882 hook fallbacks.

| Metric | Candidate A | PGO control | Candidate A2 |
| --- | ---: | ---: | ---: |
| Mean / FPS | 16.684630 ms / 59.935 | 16.686899 / 59.927 | 16.687266 / 59.926 |
| p95 | 17.774569 ms | 17.676871 | 17.980123 |
| p99 | 18.098835 ms | 18.225689 | 18.581194 |
| Worst | 20.680334 ms | 19.789125 | 19.988542 |
| CPU-thread mean | 11.525471 ms | 11.760986 | 11.271116 |
| CPU-thread p95 | 13.094989 ms | 13.177791 | 12.742861 |
| Frames <=16.7 ms | 52.500% | 52.500% | 52.500% |

The candidate repeats a real 0.236-0.490 ms CPU-mean reduction, but it does
not improve the acceptance metric. Both p95 values are worse than control,
the pass share is identical, candidate A has the worst maximum, and A2
regresses both p99 and p95. Faster CPU work becomes additional requested
throttle sleep; wake-lateness mean rises from 0.468 ms in control to
0.545/0.594 ms and its p95 rises from 1.075 ms to 1.097/1.235 ms.

## Decision

**PERF-068 REJECTED; G5 OPEN; FINAL DESTINATION AND G6 BLOCKED.** A small CPU
win that repeats but worsens both total p95 runs cannot be retained. All
candidate-specific DolRecomp source and tests are removed. The six focused
test groups pass after reversal, dependency bootstrap recognizes the exact
canonical patch stack, repository safety passes, and no game process or
Simulator remains.

Checkpoint validation also passes the full incremental desktop-tools build,
all 40 applicable CTest entries, all 16 `gcpipe` tests, both canonical/PGO
package-layout and strict-signature checks, and the explicit instrumented
versus release profile-hook test. The raw CTest registry's three unbuilt
upstream bzip executables and one disabled upstream test remain outside the
40-test applicable set, consistent with PERF-067.

Do not retry per-region FP check elision, per-chunk FP flags, or blanket FP
gate inlining. The next step is a read-only pipeline attribution comparing the
already-proven three-drawable host Metal queue with the serialized live
Dolphin path. No new presentation setting or timer variant should be built
until one specific serialization edge is identified and can be removed
without changing guest work.

## Evidence

- `docs/evidence/g5-fp-cfg-gate-rejection/candidate-a.phase.csv` —
  `fcd2c1fe96a5dfa4846d0d5fd98325b3f1dc54916792dfd03293464b3646b426`;
- `docs/evidence/g5-fp-cfg-gate-rejection/control.phase.csv` —
  `46a26aa21d15400ad65de6da279fac1e9dba338df9e4615369ce73410b88066b`;
- `docs/evidence/g5-fp-cfg-gate-rejection/candidate-a2.phase.csv` —
  `9fe1736011d17bf5248e24298dceb40f130cb013588a7a1c6ad1113469e387c0`.
