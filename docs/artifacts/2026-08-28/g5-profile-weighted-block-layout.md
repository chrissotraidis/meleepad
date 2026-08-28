# G5 profile-weighted generated-block layout

Date: 2026-08-28

Status: **PERF-087 RETAINS PROFILE-WEIGHTED INTERNAL LAYOUT; ENTRY-ONLY FORMS REJECTED; G5 OPEN**

## Question

Which static-recompilation optimization explains the large current-source
frontend-PGO CPU gain, and can a much smaller representation reproduce it?

PERF-086 rejected ordinary compiler flags. This screen separates whole-function
and entry-switch placement from profile-weighted placement of basic blocks
inside DolRecomp's very large generated chunk functions.

## Exact internal-layout evidence

The same generated source lines in `func_80375940` were resolved in disposable
profile-free and current-source frontend-PGO line-table modules. Source line
23696 is guest `0x80377B6C`; line 24527 is guest `0x80377CE4`.

| Module | First line offset | Last line offset | Host-address spread |
| --- | ---: | ---: | ---: |
| Profile-free | 20,908 | 169,696 | 148,788 bytes |
| Frontend PGO | 628 | 12,408 | 11,780 bytes |

The profile-guided compiler packs that exact hot source interval about 12.6
times more tightly inside the same generated function. This is distinct from
the rejected Mach-O order-file experiment, which could only arrange whole
symbols. It is consistent with LLVM using branch frequencies and probabilities
for machine-block placement, fallthrough selection, tail duplication, hot/cold
decisions, and selective inlining.

## Entry-only preflights

`scripts/transform-generated-entry-switch.py` preserves all generated cases
and provides two disposable source forms:

- a computed-label table for every legal aligned entry; and
- one `__builtin_expect` hot-entry gate followed by the unchanged cold switch.

Both forms were compiled from PERF-086's exact private 1,024-instruction slice
and linked against the retained differential harness. Both end at guest
`0x80324940`, match every relevant CPU-state and RAM byte, and change the same
nine RAM bytes as canonical.

The computed-label form reduced object text from 64,756 to 61,524 bytes and
improved five fresh million-entry runs by 0.757-3.100%, with a 1.785% median.
The biased-entry form reduced text to 62,100 bytes and improved five corrected
fresh million-entry runs by 2.283%, 3.566%, 2.904%, 2.487%, and 3.694%, with a
2.904% median. An earlier invocation mistakenly passed `--iterations` to a
harness that accepts a bare integer and produced `nan`; those rows are invalid
and excluded.

Entry lookup/layout is therefore real but below the retained 5% preflight gate.
It cannot account for the approximately 26% CPU-thread mean reduction in the
current frontend-PGO oracle.

## Applicable researched methods

1. **Retain representative frontend PGO as the near-term mechanism.** Train on
   deterministic required-stage combat and regenerate the private profile when
   generated source changes. LLVM and Apple both stress that profiles must
   represent expected use and remain source-compatible.
2. **Expose exact guest-edge weights to generated control flow.** A bounded
   generator experiment should attach `__builtin_expect_with_probability` or
   equivalent LLVM branch-weight metadata to every edge in one selected hot
   chunk, not merely its entry switch. Compare its block order and timing with
   profile-free and frontend-PGO objects.
3. **Form a profile-derived single-entry trace only if weights alone are
   insufficient.** Merge a hot parent/callee path, keep proven-live guest state
   in locals, and synchronize dirty state only at helpers and observable exits.
   QEMU's direct chaining and CPU-state optimization support this structure,
   while PERF-079/081 already prove local state retention can help.
4. **Keep renderer stalls as a separate gate.** Faster generated CPU code does
   not remove synchronous Metal shader compilation or rare off-core/presentation
   stalls. These require their own causal counters and prewarming decision.

Whole-function order files, BOLT on Mach-O, smaller chunks, ordinary compiler
flags, entry-only dispatch rewrites, and isolated low-coverage helpers are not
next steps; this repository already has direct negative evidence for each.

## Next falsifiable experiment

Select one current-PGO hot generated chunk and export its per-edge profile
counts. Emit source-level probabilities for that chunk only, compile it without
PGO, and require:

- full CPU-state/RAM equivalence at all legal entries and exits;
- a host block layout materially closer to the frontend-PGO object;
- no more than 5% text growth; and
- greater than 5% equal-work local improvement before any game-module build.

If that screen fails, use the same edge data to form one guarded single-entry
trace with local guest-state promotion. Do not attempt a whole-generator rewrite
before the bounded screen passes.

The retained frontend profile exposes `func_80375940` as 11,548 raw counters.
PERF-132 corrects the earlier `no coverage data found` interpretation: the
coverage object contained valid counters but referenced a rotated generated-
source path. A byte-identical cached source plus a single-object coverage-map
rebuild recovers source-associated branch counts. The hot interval executes
about 6.94 million times and contains two hazard-free straight-line traces
with 26 and 51 FP guards. The next bounded candidate coalesces only redundant
FP checks inside those single-entry traces while preserving ordinary arbitrary
entry paths. See
`docs/artifacts/2026-08-28/g5-profile-edge-coverage-recovery.md`.

## Primary references

- LLVM branch-weight metadata:
  <https://llvm.org/docs/BranchWeightMetadata.html>
- LLVM block-frequency terminology:
  <https://llvm.org/docs/BlockFrequencyTerminology.html>
- Clang profile-guided optimization and profile collection controls:
  <https://clang.llvm.org/docs/UsersManual.html>
- Apple profile-guided optimization overview:
  <https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/xcode_profile_guided_optimization/Introduction/Introduction.html>
- QEMU translator internals and direct block chaining:
  <https://www.qemu.org/docs/master/devel/tcg.html>

No product module, app, game process, Simulator, or private generated source is
added by this screen.
