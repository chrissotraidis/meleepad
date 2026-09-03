# G5 guarded broad direct-call screen

Date: 2026-08-28

Status: **PER-EDGE CALLBACK GUARD REJECTED; INLINE VALIDITY PREFLIGHT NEXT; G5 OPEN**

## Question

Can every statically known cross-chunk linked call continue directly while
preserving the runtime's forced-fallback, host-call, exception, cycle-budget,
and post-invalidation SMC checks, and does doing so improve the exact Fountain
combat workload materially?

## Guarded candidate

The disposable generator emitted a direct generated-function call only when:

- accumulated generated work had not reached the existing 256-cycle budget;
- the runtime callback accepted the target address;
- the callee returned without an exception at the exact linked continuation;
  and
- the callback accepted the local continuation again before resuming it.

The runtime callback defaulted out for REL modules, lockstep, host calls,
forced-fallback addresses, unverified chunks, and failed chunks. It delegated
the final address check to the existing `FastDispatchableAt`, so an instruction
cache invalidation prevented both entry into an invalidated callee and resumption
of an invalidated caller.

A focused generated caller/callee regression covered denied target, accepted
target, exact budget exit, denied continuation after the callee ran, and a
terminal continuation outside the generated function. `dispatch`, `c_cfg`,
`codegen_compile`, and `c_execute` passed 4/4 with the candidate and again after
its removal.

The full GALE01r0 generation emitted 67,012 guarded direct-call sites across
all 237 chunks. Generated source contained 134,005 callback invocations: one
target check per site and a second continuation check where the caller could
resume locally. The former `0x8008593C` boundary correctly returned after its
callee rather than jumping to the out-of-function `0x80085940` label. Arm64
disassembly proves real direct `bl _func_...` calls were emitted.

The first isolated package exposed an independent ABI defect before boot:
`CPU state size mismatch`. ModernGekko has public and GXRuntime mirrors of
`CPUState`; the experiment initially extended only GXRuntime. The unchanged
module-size guard correctly rejected that drift. Adding the same tail callback
field to the public mirror, rebuilding the runner, and retaining the load-time
size check produced a self-consistent disposable package. No compatibility
check was bypassed.

## PGO positive screen

The first signed candidate reused the PERF-072 frontend profile only as a
positive screen. The broad CFG change caused widespread missing/mismatched
profile warnings, so this row cannot support a negative decision. Its signed
module SHA-256 is
`1b3514a712bfde798f7f575fcbb7622ff005e0adad1dbe4eec763173198cea2e`;
`__text` is 92,807,400 bytes.

The last occurrence of emulated frames `48123..48562` produced 440 rows:

- 1,501,629,909 guest cycles;
- 15,897,417 native dispatches;
- 892,043 bursts;
- 882 hook fallbacks; and
- zero fallback steps.

Mean was 16.662572 ms, p95 18.161959 ms, p99 19.932417 ms, worst
34.183541 ms, CPU-thread mean 11.899125 ms, CPU p95 13.246875 ms, and
57.500% of frames met 16.7 ms. Versus the PERF-072 PGO oracle, dispatches fell
69.1% but CPU-thread mean worsened 2.39%. Because the old profile no longer
matched, a clean profile-free pair was required before deciding.

Computer Use inspection retained coherent Pikachu-versus-CPU-Fox Fountain
combat at a 60.0-FPS title. Pikachu, Fox, HUD, platforms, and stage geometry
were intact with no observed character morphing or warping. The app exited
normally with zero fallback steps and zero failed SMC chunks.

## Profile-free matched result

The preserved candidate generator then produced a distinct no-profile module
under cache key `247648c25ec6d4fa`, with no profile flags or warnings. Its raw
module SHA-256 is
`def75672b6e34e9ddacc7f0c5a0122815c39558ac91df8f861334dc3684a7196`;
`__text` is 91,628,384 bytes. The canonical profile-free module is
81,235,476 bytes, so the callback CFG grows text by 10,392,908 bytes / 12.79%.

The same exact candidate interval reproduced all candidate work counters:
1,501,629,909 cycles, 15,897,417 dispatches, 892,043 bursts, 882 hook
fallbacks, and zero fallback steps. The closest retained canonical
profile-free control differs by only 510 cycles / 0.000034% and otherwise has
51,369,928 dispatches, 905,572 bursts, 882 hooks, and zero fallbacks.

| Metric | Canonical no-profile | Guarded no-profile |
| --- | ---: | ---: |
| Mean | 16.652905 ms | 16.925164 ms |
| p95 | 18.923917 ms | 18.677083 ms |
| p99 | 20.314375 ms | 20.273042 ms |
| Worst | 26.630167 ms | 128.024166 ms |
| CPU-thread mean | 15.699995 ms | 15.439466 ms |
| CPU-thread p95 | 17.430385 ms | 17.319378 ms |
| Frames <=16.7 ms | 62.273% | 60.000% |
| Native dispatches | 51,369,928 | 15,897,417 |

The candidate removes 35,472,511 dispatches / 69.05% but improves CPU-thread
mean by only 0.260529 ms / 1.66%, and CPU p95 by only 0.64%. It misses the 5%
materiality rule, total compliance falls, and the required 16.7-ms tail remains
open. The large dispatch reduction with a very small compute gain is direct
evidence that two out-of-line callback guards per linked call consume most of
the saved dispatcher work.

## Decision and next experiment

**Reject and remove the per-edge callback guard.** This decision rejects this
guard representation, not safe block linking as a category. All generator,
test, public ABI, GXRuntime ABI, runtime callback, and bootstrap experiment
edits are removed. The canonical profile-free module pointer is restored.

The next bounded preflight is a data-only inline validity representation. It
must preserve dynamic forced-fallback eligibility and SMC invalidation without
an out-of-line callback on every target and continuation. First measure a
focused host/generated harness; build the game only if the projected saving
can exceed 5%. If a cheap inline representation cannot do that, move to
profile-derived superblocks that place guards only at trace boundaries. Do not
retrain or retry this callback design.

The follow-up design survey and project-specific ranking are retained in
`g5-static-recomp-optimization-research.md`.

This work also found a reproducibility bug independent of the rejected
candidate: `moderngekko-port`'s post-build copy did not refresh the top-level
`dolrecomp` executable when only its generator dependency changed. The retained
`prepare-game.sh` fix explicitly uses `cmake -E copy_if_different` before
generation, preventing a stale executable from silently producing a module
under the wrong source identity.

Final Destination and G6 remain blocked by G5.

## Restored-product validation

After removing the experiment, the restored desktop-tools build passed all
40 applicable CTest entries. The canonical package then passed repository
checks, package layout, arm64 identity, strict deep signing, `git diff
--check`, shell syntax, and 16/16 `gcpipe` tests. Its frontend, runner, and
module SHA-256 values are respectively `4b6cc111...fcad3`,
`93ebc462...63cd5`, and `44366f2e...5b90`. No MeleePad process or booted
Simulator remained after validation.

## Evidence

- `docs/evidence/g5-guarded-direct-call-rejection/guarded-pgo-positive-screen.phase.csv`
  — PGO positive screen, SHA-256
  `a44cfbf2675466781b238eea80caadb3fe6dc8bc3a9c116ced370723362ad0b3`;
- `docs/evidence/g5-guarded-direct-call-rejection/guarded-nopgo-fountain.phase.csv`
  — matched no-profile candidate, SHA-256
  `03c6d49b1cae8eeb06aa11e8e8f1bbeb33f19ee27a956763d9e6e35e58952500`;
- `docs/evidence/g5-guarded-direct-call-rejection/fountain-combat.png` — live
  coherent combat frame, SHA-256
  `85f862d59cb7d5a4dfd79ce7dd2ba5b465fd8989a92dba1cbf847324b35a2ea7`.
