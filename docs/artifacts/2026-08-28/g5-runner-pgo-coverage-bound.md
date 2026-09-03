# G5 runner/runtime PGO coverage bound

Date: 2026-08-28

Status: **PERF-134 REJECTED BEFORE BUILD; G5 OPEN**

## Question

The current private frontend profile optimizes the generated game module, not
the ModernGekko/Dolphin runner. Could a second PGO pass over runner/runtime
code create enough producer slack to reduce the natural no-queue tail?

## Existing-sample bound

The retained current-module-PGO Fountain sample already separates the module
from the runner. On the combined `CPU-GPU thread`:

| Inclusive frame | Samples |
| --- | ---: |
| `StaticRecompCore::Run` in `MeleePadRunner` | 9,279 |
| child `chassis_dispatch` in `gGALE01_recomp.dylib` | 9,030 |
| runner-only maximum | 249 |

The runner-only difference is 2.683479% of the static-recompiler hot loop.
That is an intentionally generous upper bound: it assumes a runner PGO build
can delete every sample outside the already-profiled module, including runtime
hooks and unavoidable call/return/control work. Real PGO cannot do that.

The hot generated functions and module-local PowerPC helpers remain under
`chassis_dispatch`; they are already compiled with the current frontend
profile and would not be changed by profiling `MeleePadRunner` or Dolphin's
`core` target.

## Decision

**Reject runner/runtime PGO before an instrumented Dolphin build.** Its
impossible best case is below the existing 5% product-build preflight gate,
and it cannot address the independently proven runnable-thread descheduling
events. Do not instrument all of Dolphin, rebuild the runner with a game
profile, or count module children as runner opportunity.

This is a selection bound, not a performance acceptance run. G5 remains open
for the natural no-queue producer/descheduling tail.

## Retained private identities

- sample SHA-256:
  `eb3ffc4e1cc5255a120c55ab0f36810955db5a7479cf289c4ff6fc414b284180`
- runner SHA-256:
  `5af0d7f69bb90ae138475fcb2aa379f615775ec3bdd02b9b049df12f47be01a8`
- current frontend-PGO module SHA-256:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`

No runner, module, product source, game, or Simulator changed.
