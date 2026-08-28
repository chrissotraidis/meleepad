# G5 IR-level PGO screen

Date: 2026-08-28

Status: **IR-LEVEL PGO REJECTED; G5 OPEN**

## Question

Can LLVM IR-level instrumentation and profile use improve the exact retained
Pikachu/CPU-Fox Fountain workload beyond the frontend-PGO build retained by
PERF-072, without changing guest work or runtime semantics?

## Isolated experiment

The local `--pgo-generate` compiler flag was temporarily changed from
`-fprofile-instr-generate` to `-fprofile-generate`, with a distinct
experiment-only cache identity. A fresh 247-step build produced a signed arm64
training module with SHA-256
`b55f07e3bcd3d9e79765f73df06195f47ebffd1f5679e9f7f2a1c986c1ef6487`.
Its Mach-O image contained LLVM IR profile counter, data, value, name, bitmap,
and vtable sections.

The single training process used Metal, Cubeb, an isolated user directory, and
no Simulator. It reached the live attract sequence before the established
frame-gated state load, then visibly rendered coherent Pikachu versus CPU Fox
on Fountain. The combat predicate reset and dumped counters exactly once and
the app exited normally.

- raw profile SHA-256:
  `82310916d952e90e882e3c0bef74b60e0c6501e5fc574c6f2ba4990046d6e462`;
- merged profile SHA-256:
  `6304c8cd7793a643947d375224de30ccdb9a216f678b5d41f3ec2e3974ff461b`;
- LLVM instrumentation level: `IR`;
- 866 post-optimization functions, 3,947,902 blocks, and
  52,990,495,633 aggregate counts.

The indexed profile drove another clean 247-step profile-use build with no
missing-profile or mismatch warnings. The signed arm64 module SHA-256 is
`47a8ce8bd07c436247ca2ae08524bcf6f14604a755a357962112cc1d24701e5c`.
Its `__text` is 84,388,556 bytes, 2,429,176 bytes larger than PERF-072's
frontend-PGO module. Package layout and strict signing pass.

## Exact-work runtime result

After the build completed, thermal preflight reported no warning or
performance limit. Exactly one foreground game process ran with Metal, Cubeb,
an isolated user directory, frame-phase logging, and no Simulator. The state
load was withheld until the log reached emulated frame 3,252. Direct UI
inspection then confirmed coherent Pikachu/CPU-Fox Fountain combat and a
60.0-FPS window title.

The last occurrence of every emulated frame `48123..48562` produced 440 rows
and exactly matched PERF-072's guest work:

- 1,501,757,755 guest cycles;
- 51,380,895 native dispatches;
- 905,756 bursts;
- 882 hook fallbacks; and
- zero fallback steps.

| Metric | Frontend PGO | IR PGO |
| --- | ---: | ---: |
| Mean / FPS | 16.663618 ms / 60.011 | 16.737756 ms / 59.745 |
| Median | 16.553833 ms | 16.638813 ms |
| p95 | 18.065125 ms | 18.047575 ms |
| p99 | 19.130250 ms | 18.978414 ms |
| Worst | 22.509416 ms | 69.163166 ms |
| CPU-thread mean | 11.620875 ms | 12.084786 ms |
| CPU-thread p95 | 12.770189 ms | 13.348795 ms |
| Frames <=16.7 ms | 55.909% | 55.682% |

IR PGO's 0.018 ms p95 movement is noise beside a 0.464 ms / 3.99% CPU-thread
mean regression and the larger code image. The 69.163 ms worst occurs at
emulated frame 48,394, 271 frames into the selected interval rather than on
the state-load boundary. It records 68.041 ms CPU wall and 17.785 ms CPU
thread, followed by two additional 21 ms frames inside steady combat.

## Decision

**Reject IR-level PGO for this generated module.** It is technically viable on
arm64 Mach-O with ThinLTO, but it does not improve the exact workload and does
not pass G5. Do not promote the local app or replace the retained frontend-PGO
workflow. The two temporary flag/cache-identity substitutions were restored;
the desktop tool rebuilt, dependency bootstrap and patch reverse-check pass,
and the canonical active-module pointer again selects the profile-free module.

The next generated-code investigation should use the retained profiles to
identify a specific hot region or dispatch edge whose transformation can be
tested without growing the entire 84 MB text image. Final Destination and G6
remain blocked.

## Validation notes

- repository safety, diff whitespace, dependency bootstrap, and patch
  reverse-check: pass;
- 40/40 applicable CTest entries and 16/16 `gcpipe` tests: pass;
- IR-PGO and canonical package layout, arm64 identity, and strict signing:
  pass;
- canonical active-module pointer restoration: pass;
- `scripts/test-profile-hooks.sh` is not an IR-profile acceptance test: its
  final `awk` requires frontend profiles' `Function count:` records, while the
  IR format reports `Block counts:`. It returns 1 after the IR reset/dump
  calls succeed. The actual IR run produced exactly one raw file, the runtime
  logged `profile capture dumped: result=0`, and the merge accepted the dump
  hook. No product test was weakened for this rejected experiment.

## Evidence

- `docs/evidence/g5-ir-pgo-rejection/ir-pgo-fountain.phase.csv` — exact
  440-frame interval, SHA-256
  `01684798082017de3bbf35c45bb889de93134479c3f3637a4f2241541cac2d6d`;
- `docs/evidence/g5-ir-pgo-rejection/fountain-combat.jpeg` — retained live
  visual-only recapture, SHA-256
  `053323c0cad06f72e702f9021b014ba8515dc54de29e05797e0b0d5c0639249d`.
