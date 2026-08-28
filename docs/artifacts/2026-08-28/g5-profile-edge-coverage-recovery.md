# G5 profile-edge coverage recovery

Date: 2026-08-28

Status: **rotated-path diagnosis corrected; candidate already rejected by PERF-088**

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

## Existing closure

Checkout reconciliation found that PERF-088 had already completed both
experiments this recovery appeared to enable. Its matching coverage build
decoded the same profile and region, then tested:

- 113 deterministic source probabilities: 59.011-62.751% slower across the
  eligible weighted/hot/entry forms; and
- the guarded single-entry/state-promoted `0x80377B6C` trace: 4,096 randomized
  full-state/full-RAM comparisons passed, including 512 FP-disabled cases, but
  ordinary, ThinLTO, and hot ThinLTO timings were 1.343-3.025% slower. The
  one-million-entry confirmation was 443.064 ns canonical versus 454.107 ns
  trace, 2.492% slower.

That retained evidence is authoritative:
`docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md`.

## Decision

Do not rerun source probabilities or either FP trace. The useful new result is
only the precise diagnosis of why the later standalone `llvm-cov` invocation
failed: its generated-source path had rotated. It does not reopen PERF-088 or
justify a game-module build.

G5 returns to the separate pre-results no-queue producer/descheduling tail.
The branch-hint, FP-trace, blanket FP-helper, global direct-chaining, smaller-
chunk, compiler-flag, and whole-symbol-layout branches remain rejected. Final
Destination and G6 remain blocked.

No disc image, extracted game data, profile, generated source, object, module,
app, or savestate is committed.
