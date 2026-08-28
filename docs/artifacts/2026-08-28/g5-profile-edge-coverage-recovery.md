# G5 profile-edge coverage recovery

Date: 2026-08-28

Status: **source-associated counters recovered; bounded trace candidate selected**

## Question

PERF-087 proved that frontend PGO packs the hot `func_80375940` interval about
12.6 times more tightly than the profile-free object, but `llvm-cov` originally
reported no coverage. Can the existing private profile be mapped back to exact
generated source without rebuilding the 82 MB module, and does it identify a
small semantics-complete optimization?

## Recovery

The prior coverage object did contain counters. Its recorded generated-source
path had been removed when the private build cache rotated. `llvm-cov` therefore
reported a missing source file, which was incorrectly summarized as missing
coverage data.

The byte-identical generated source remains in the reproducible private PGO
cache. A single 2.8 MB object for
`chunk_0221_text1_80375940.c` was rebuilt with the exact training flags plus
Clang coverage mapping. It consumes the existing Fountain profile SHA-256
`3f9d2aa4dbd5aa34465c8b975e5c6c369518e0db23137b2e424295a0f572ac12`
and reports:

- 31,306 generated-source lines, 47.20% covered;
- 14,480 branch sites, 43.01% covered; and
- about 6.94 million executions through the hot matrix interval beginning at
  revision-0 guest PC `0x80377B6C`.

The coverage object SHA-256 is
`41cf5223ce92205763d328470bc7a5f481825b338620b9c9573964e31aa42baa`.
The generated source SHA-256 is
`086e74b345633fee2505ccb348fdebb3adddf69df849d6d80cd9488aa32cb6f6`.
Both remain private and outside git.

## Exact hot-path result

The first FP-availability guard at guest PC `0x80377B78` records 127
FP-unavailable exits versus about 6.94 million normal continuations. Every
subsequent FP guard in the observed hot path records zero exits and about 6.94
million continuations.

The larger `0x80377B6C..0x80377CE4` region is not eligible for blind guard
coalescing: it contains three conditional branches, two linked calls to
`0x803408A0`, one unconditional branch, and an exit to `0x80377D58`.

It does contain two bounded straight-line traces:

| Trace | Guest instructions | FP guards | branch/call/MSR/cache hazards |
|---|---:|---:|---:|
| `0x80377B6C..0x80377BF0` | 34 | 26 | 0 |
| `0x80377C20..0x80377CE8` | 51 | 51 | 0 |

Neither trace branches, calls a helper boundary, writes MSR, performs cache
control, or invokes a host service. Once the first FP instruction in a trace
has proven MSR[FP], no instruction inside that trace can revoke it. The normal
generated form nevertheless performs the same availability test before every
FP instruction.

## Decision

Do not add generic branch hints or remove FP checks globally. The next bounded
preflight is a single-entry representation of these two exact traces:

- keep the first FP check with its exact exception CIA;
- omit only later redundant checks along the specialized straight-line path;
- preserve every ordinary label and arbitrary-entry path unchanged;
- compare full CPU state, RAM, exception state/CIA, cycle charge, and every
  legal entry against canonical generated code; and
- require greater than 5% equal-work local improvement with no more than 5%
  text growth before building a game module.

This follows PERF-087's profile-derived trace fallback and is distinct from
the rejected blanket FP-helper inlining, global direct chaining, smaller
chunks, compiler flags, and whole-symbol layout experiments. G5 remains open;
Final Destination and G6 remain blocked.

No disc image, extracted game data, profile, generated source, object, module,
app, or savestate is committed.
