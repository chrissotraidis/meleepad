# G5 FP-availability inline rejection

## Question

The exact Fountain sample placed out-of-line `ppc_fp_available` checks among
the leading dynamic helper costs. A host preflight measured 0.413-0.463 ns
saved per enabled-FP check by inlining the common MSR bit test and retaining
the existing slow lazy-FP/exception path.

## Candidate gates

- a compile probe failed before the change because its optimized body was an
  unconditional branch to `ppc_fp_available`;
- after the change, generated ARM64 tested MSR[FP], returned immediately when
  set, and branched to `ppc_fp_available_slow` otherwise;
- the focused GXRuntime test passed enabled, unavailable-exception, and
  lazy-disabled states;
- bootstrap and patch reverse-check passed;
- a bounded lockstep run checked 1,367 distinct PCs, reproduced all 91 known
  report categories, skipped 7 fallback and 3 zero cases, and recorded zero
  undercharges/max deficit;
- a disposable signed app visibly rendered coherent Pikachu/CPU-Fox Fountain.

The first live load was sent while the phase log still reported emulated frame
zero. Dolphin trapped at `DVDThread::WaitUntilIdle` because the emulation
thread was still starting. The supplied crash report confirmed this lifecycle
error. Retrying only after emulated frame 1,000 produced a clean load and the
saved jump above frame 48,000. Future savestate runs must keep that readiness
gate.

The full report supplied on 2026-08-27 is incident
`9AE31C76-671C-42F8-89AF-D64EE5BA5059`, process 24720 from the disposable
`MeleePad-fp-inline.app`. It trapped on the main thread 27.86 seconds after
launch while the emulation thread was still named `Emuthread - Starting` and
waiting for asynchronous shader compilation. The executable UUID
`40F7BF02-D790-3451-A619-755F50B2120C` matches the retained disposable app.
This is corroborating evidence for the harness sequencing error, not a new
canonical engine crash or a fault in a later candidate.

## Equal-frame A/B/A result

Each row covers the last occurrence of emulated frames 48123-48562.

| Metric | Candidate A | Canonical B | Candidate A2 |
|---|---:|---:|---:|
| Mean / FPS | 19.070964 ms / 52.436 | 19.001550 / 52.627 | 19.035697 / 52.533 |
| p95 | 20.372667 ms | 20.675166 ms | 20.830500 ms |
| p99 | 22.228750 ms | 22.060875 ms | 23.453042 ms |
| CPU-thread mean | 18.389578 ms | 18.595254 ms | 18.579110 ms |
| CPU-thread p95 | 19.866381 ms | 20.235260 ms | 20.253204 ms |
| Frames <=16.7 ms | 0.909% | 3.182% | 0.227% |

The first candidate's CPU reduction did not repeat; A2 is effectively tied
with control and has worse total p95/p99. Work differs by at most 19 guest
cycles, four dispatches, and 161 bursts over the full window, with zero static
fallbacks and 882 hook fallbacks in every row.

## Decision

**CANDIDATE REJECTED AND REMOVED; G5 OPEN; G6 BLOCKED.** The canonical active
module key `1e1debc9fb83a31a` is restored. Do not retry this helper split
without new dynamic evidence. No game process or Simulator remains.

## Evidence

- `docs/evidence/g5-fp-availability-shared-state/candidate.phase.csv`
- `docs/evidence/g5-fp-availability-shared-state/reverse-control.phase.csv`
- `docs/evidence/g5-fp-availability-shared-state/candidate-repeat.phase.csv`
