# G5 dispatch branch attribution and lookup-order rejection

Date: 2026-08-26

Status: **DIAGNOSTIC RETAINED; LOOKUP CANDIDATE REJECTED; G5 OPEN**

## Question

Which branch of the generated module's generic dispatcher dominates normal
Melee menu execution, and can the common original-code lookup be made cheaper
without changing replacement, host-hook, original-code, or physical-alias
precedence?

The signed packaged control was never replaced. It remained:

- runner SHA-256 `9bff54e4fd747aa4088beae1e847149a06fc7046bd4141e9d684aed58c1f355b`;
- module SHA-256 `2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.

No Simulator was booted.

## Default-off branch attribution

Patch `0010-module-dispatch-branch-counts.patch` adds an opt-in module build
mode that duplicates `dolrecomp_call`'s exact ordering while counting:

1. replacement hits;
2. installed host probes and hits;
3. generated-original hits;
4. physical-address alias attempts and their sub-branches;
5. complete misses.

The mode reuses the existing optional `staticrecomp_profile_reset` and
`staticrecomp_profile_dump` host trigger. It is absent from normal modules and
does not change the release dispatcher.

A watcher-gated Main Menu interval produced:

```text
dispatches=373345803
replacement_hits=0
host_probes=0
host_hits=0
original_hits=373345803
alias_attempts=0
alias_replacement_hits=0
alias_host_probes=0
alias_host_hits=0
alias_original_hits=0
misses=0
```

Every counted call used generated original code. The installed-host branch was
not merely cold: `ctx->host_call` was null for the entire interval. Timing from
the instrumented module is deliberately excluded because hundreds of millions
of counter increments perturb the run.

The diagnostic hook smoke reset and dumped zeroed counters successfully. The
normal packaged module exports neither diagnostic hook.

## Menu transition classification

The lookup candidate emitted the large, uniform GALE01 text1 run before the
small boot text0 run inside `dolrecomp_find_original`. The ranges are disjoint,
and public dispatch precedence remained unchanged. A focused generator
regression failed before the change and passed afterward; the restored normal
generator again passes its original 9/9 dispatch tests after rejection.

Two deterministic cold title-to-CSS routes exposed the same long present gaps
in the unchanged packaged control and the candidate:

| Transition row | Packaged control | Lookup candidate |
|---|---:|---:|
| First long row total | 2,885.843 ms | 2,901.641 ms |
| Guest cycles | 1,402,478,587 | 1,410,588,809 |
| Native dispatches | 64,956,666 | 65,718,797 |
| CPU-thread work | 1,704.138 ms | 1,719.540 ms |
| Throttle sleep | 1,226.560 ms | 1,221.609 ms |
| Second long row total | 3,153.230 ms | 3,134.933 ms |
| Second-row guest cycles | 1,532,297,103 | 1,524,159,031 |

The first candidate row is approximately 174 ordinary 8.107-million-cycle
guest frames and approximately 174 16.68 ms wall intervals. Metal presentation
cost was only `0.029 ms`. This is a scene-load interval in which Melee advances
guest time under normal pacing without submitting display frames. The window
title's present-based FPS falls during the gap, but the lookup candidate neither
causes nor fixes it.

Between the two load rows, stable menu presentation remained effectively the
same:

| Metric | Packaged control | Lookup candidate |
|---|---:|---:|
| Frames | 543 | 542 |
| Mean / p95 / p99 / worst | 16.6845 / 17.7866 / 17.9888 / 18.0836 ms | 16.6866 / 17.6942 / 17.9478 / 18.1867 ms |
| Mean FPS | 59.9358 | 59.9283 |
| CPU-thread mean / p95 | 10.8539 / 12.9528 ms | 10.7225 / 12.9555 ms |

The attempted no-module interpreter comparison was excluded. An initial run
silently auto-discovered the bundled module and therefore became the fresh
packaged control above. The corrected unbundled run later lost valid watched
addresses at PC `0x00000C00` and did not reach the title gate in the bounded
window.

## Required Fountain result

The candidate was routed visibly through:

- P1 Pikachu;
- level-1 CPU Captain Falcon;
- the literal `Fountain of Dreams` stage-select label;
- coherent live combat with Cubeb;
- the standard 20-cycle movement, attack, jump, and special script.

Frames 55,279 through 58,356 form the 3,078-frame bounded combat interval:

| Metric | Lookup candidate |
|---|---:|
| Total mean / p95 / p99 / worst | 16.833022 / 18.587556 / 20.262101 / 101.925583 ms |
| Mean FPS | 59.407039 |
| Frames <=16.7 ms | 50.292% |
| Frames >25 / >50 ms | 7 / 1 |
| CPU-thread mean / p95 / p99 | 16.582606 / 18.405322 / 19.774645 ms |
| Native dispatches mean / p95 | 138,795.450 / 148,733.750 |
| Guest cycles mean / p95 | 8,107,171.291 / 8,137,976.650 |

The retained current control used a different CPU opponent, so no precise
character-matched delta is claimed. Its 17.622406 ms p95 and 59.928720 FPS are
nevertheless better, and the candidate fails the absolute G5 tail requirement
decisively. It was rejected without running Final Destination.

The first post-script screenshot caught orange Pikachu elongated during a
Captain Falcon hit. Twelve adjacent app-only frames show both fighters at
coherent proportions through the final countdown and `Time!`; this is a
bounded non-recurrence, not a new persistent mesh defect. The existing visual
recurrence rule remains in force.

## Decision

- Retain the default-off branch counter as canonical dependency patch 0010.
- Remove the lookup-order generator change and its focused temporary test.
- Remove temporary route helper files.
- Keep the signed packaged product on the unchanged control module.
- Keep G5 open; do not run Final Destination or start G6.

The all-original count does not justify bypassing public dispatch semantics,
and the single disjoint-range guard removal did not solve either scene-load
present gaps or strict Fountain tails. The next diagnostic should compare
per-address native-dispatch distribution between ordinary Fountain frames and
the strict p95 tail, then select a coherent hot loop only if that evidence
identifies a material source. Do not retry whole-dispatch reordering, host
probe removal, timer variants, or isolated low-frequency leaves.

## Evidence

- `g5-dispatch-branch-counts-menu.txt`
- `g5-dispatch-counts-hook-smoke.txt`
- `g5-dispatch-counts-packaged-menu-control.csv`
- `g5-lookup-order-menu-candidate.csv`
- `g5-lookup-order-fountain-candidate.csv`
- `g5-lookup-order-fountain-stage-select.png`
- `g5-lookup-order-fountain-live-combat.png`
- `g5-lookup-order-fountain-temporal-burst/frame-00.png` through
  `frame-11.png`
