# G5 profile-edge and EFB-pipeline attribution

Date: 2026-08-28

Status: **PERF-088 REJECTS SOURCE WEIGHTS AND ONE HOT TRACE; RETAINS EFB MISS COUNTERS; G5 OPEN**

## Question

Can exact frontend-PGO edge counts be represented in generated C strongly
enough to recover the current PGO CPU gain? If not, does synchronous Metal EFB
pipeline creation explain the remaining strict frame tail?

## Exact coverage mapping

The local PGO-generation route now also emits Clang coverage mapping. Its cache
identity includes `coverage-mapping`, so an older instrumentation module cannot
be reused accidentally. The resulting arm64 module contained both
`__llvm_covfun` and `__llvm_covmap`, retained the profile reset/dump hooks, and
passed strict app signing and package-layout checks.

`llvm-cov` decoded the retained Fountain `.profdata` against that newly mapped
module without a hash mismatch. This proves source/counter compatibility even
though the coverage module was built after the profile. The private profile,
module, generated C, and ROM-derived data remain outside Git.

For generated source lines `23695..24786`, corresponding to the selected
`0x80377B6C..0x80377D58` region, exact JSON contained 119 branch records:

- 113 executed records received deterministic source probabilities;
- six never-executed records were intentionally left unchanged;
- the first FP guard failed 127 times in 6,946,209 executions
  (`0.001828335%`), while every later FP guard in the selected region had zero
  failures;
- the two guest control-flow edges at `0x80377BF4` and `0x80377C10` were taken
  every time; and
- the non-equal integer comparison split 85.021297% / 14.978703% with zero
  equal cases.

`scripts/apply-llvm-cov-branch-weights.py` rejects coverage/source mismatches,
unfamiliar conditions, mixed executed/unexecuted records, and ambiguous
short-circuit shapes. Its four focused tests pass.

## Source-weight rejection

Three line-table arm64 objects compiled the same complete generated chunk at
product `-O2` semantics:

| Arm | Text | `23696..24527` host-address spread |
| --- | ---: | ---: |
| Profile-free | 419,648 bytes | 265,136 bytes |
| Source-weighted | 232,684 bytes | 34,464 bytes |
| Frontend PGO | 414,152 bytes | 6,268 bytes |

Source weights therefore compacted the selected region 7.69 times, but not in
the same way as PGO. Optimized IR exposed the failure mechanism: the weighted
function acquired contradictory `cold hot minsize` attributes because local
probabilities supplied no absolute function-entry count. An explicit `hot`
attribute and a biased entry gate did not remove the cold/minsize decision.

`scripts/g5_profile_weighted_preflight.c` compared every CPU-state byte except
the intentionally distinct RAM pointer and all 5 MiB of RAM across 992 legal
entry/FP-state cases. Canonical, weighted, and PGO objects all passed. Timings
nevertheless rejected every source-weight form:

- weights alone: 62.304% slower;
- weights plus `hot`: 62.751% slower; and
- weights plus `hot` and a biased entry: 59.011% slower.

This is a semantic pass but an unequivocal performance failure. Do not ship or
broaden C-level probability hints for this generated-function shape.

## Guarded trace rejection

The prescribed fallback narrowed the actual generated function to entry
`0x80377B6C`, cached GPRs 0/1/2/3/4/31, retained the exact first FP-unavailable
gate, and let the compiler discard unreachable arbitrary-entry code. The
resulting object was 12,872 text bytes.

`scripts/g5_profile_trace_preflight.c` passed 4,096 randomized full-state and
full-RAM comparisons, including 512 FP-disabled entries. It still failed the
greater-than-5% local timing gate:

- ordinary separate objects: 1.343% slower;
- product-equivalent ThinLTO: 2.838% slower;
- ThinLTO plus a clean `hot` function attribute: 3.025% slower; and
- the longer one-million-entry confirmation: 443.064 ns canonical versus
  454.107 ns trace, 2.492% slower.

No generated module or game candidate is justified. The trace and state cache
are rejected before a product build.

## Frame-correlated EFB pipeline evidence

Patch `0018-efb-pipeline-phase-timing.patch` adds default-dormant counters to
the existing frame-phase logger. On a cache miss it records shader-generation /
Metal-library time and render-pipeline creation time separately for VRAM and
RAM EFB copies. It performs no logging or atomics unless the existing
`SSBMPAD_FRAME_PHASE_LOG` diagnostic is enabled. The focused counter regression
passes, the native runner rebuilds, bootstrap and patch-scope checks pass, and
the signed package passes strict layout/signing checks.

The signed instrumented runner SHA-256 is
`b4c80e25fa6ae43b971f4915b08fa0b896944713d51bc41ad524347f4f1575c2`.
The unchanged canonical module SHA-256 is
`44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`.

After the known-safe startup delay, `SIGUSR2` loaded the retained Fountain
state. The exact `48123..48562` interval contained 440 rows and identical known
work:

- 1,501,757,755 guest cycles;
- 51,380,895 native dispatches;
- 905,756 static bursts; and
- 882 hook fallbacks.

Exactly one interval frame compiled an EFB pipeline:

| Present frame | Emulated frame | Total | Shader | Pipeline |
| ---: | ---: | ---: | ---: | ---: |
| 2241 | 48436 | 18.047583 ms | 1.020291 ms | 0.177250 ms |

This proves a real synchronous 1.197541 ms hitch. However, subtracting all EFB
compile time changes neither the 18.650750 ms p95 nor the 184/440 frames above
16.7 ms. A separate 73.469541 ms worst frame at emulated frame 48243 had zero
EFB misses; CPU wall was 69.624085 ms while CPU-thread work was 21.001454 ms,
showing a roughly 48.6 ms off-core stall. Prewarming is therefore rejected as
the G5 tail solution, though the counters remain useful for cold-start quality.

The private phase CSV SHA-256 is
`3fb2dd0efcf29a6e3df6fdb4b6e4a8a8fcca1e479b52d7c039059c2a24583c83`.
The game exited normally. No Simulator ran.

## Decision

**PERF-088 rejects source branch weights, hot-entry hints, and the selected
single-entry/state-promoted trace. It retains exact coverage tooling and EFB
miss attribution. G5 remains open; G6 and Final Destination remain blocked.**

Next, repeat the retained exact window with the best frontend-PGO oracle and
these counters. This separates its remaining CPU tail from rare off-core
stalls without another static-recompiler rewrite. Do not build an EFB prewarmer
unless a future required-stage distribution shows misses affecting p95.
