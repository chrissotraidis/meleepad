# G5 last-chunk cache rejection

Date: 2026-08-26

## Question

Can the existing but unused `m_last_chunk_index` field avoid most accesses to
the RAM-sized per-instruction chunk table while preserving every generated
dispatch and semantic boundary?

## Candidate

The temporary DOL-only change checked whether the next guest PC remained
inside the previously resolved module chunk. On a hit it returned that same
chunk index; on a miss it executed the untouched canonical lookup and updated
the cache. REL modules retained the complete resolver path. No ABI, generated
module, timing, SMC-state, host-call, exception, cycle, or event boundary
changed.

The candidate existed only in the ignored dependency checkout and an isolated
signed app copy. The product runner/module remained
`9bff54e4fd747aa4088beae1e847149a06fc7046bd4141e9d684aed58c1f355b` /
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.

## Semantic screen

The same bounded 5,000,000-dispatch lockstep configuration reached the
canonical 88-report set. The mapping transformation is also locally exact:
the fast return is allowed only when the address lies within the module range
for the previously returned index; every other address uses the original
lookup. No new semantic class was observed.

## Live failure

The memory-gated route did not establish CSS. It opened the title readiness
gate at 41.87 seconds, then entered an opening/demo sequence and timed out on
the CSS predicate. Those route timings are excluded from performance claims.
Long B returned cleanly to the title, and subsequent bounded input reached
coherent four-player attract combat and the `How to Play` Mario/Bowser scene.

The visibly active How-to interval covered frames 19,396-20,874:

| Metric | Result |
|---|---:|
| Frames | 1,479 |
| Mean / FPS | 20.352699 ms / 49.133532 FPS |
| p50 / p95 / p99 | 21.724250 / 24.562912 / 26.008498 ms |
| Worst | 47.517541 ms |
| Frames <=16.7 ms | 18.120% |
| Frames >25 / >50 ms | 47 / 0 |
| CPU mean / p95 | 20.229854 / 24.423280 ms |
| Native dispatches/frame | 40,099.933 |
| Guest cycles/frame | 8,103,489.294 |

The screenshots and title counter also observed 39.2 and 37.5 FPS in attract
combat and 48.6-50.7 FPS in How-to. These are absolute candidate failures,
not matched regression claims. No exact Fountain result is claimed because
the required route was not established.

Complete candidate phase CSV SHA-256:
`d7392a91c99f944556afe7771f15d73e55b0b13e73968df353de7fa0fcdca8a0`.

## Decision

**LAST-CHUNK CACHE REJECTED AND REMOVED; G5 OPEN; G6 BLOCKED.**

The shortcut was too small and too scene-dependent to solve the observed
active slowdown, and the failed exact route provides no required-stage reason
to retain it. The source and both local runners were rebuilt to canonical.
The isolated app/run were moved to recoverable Trash locations; no game
process or Simulator remained.

Do not retry another chunk-lookup micro-optimization. The next experiment must
target the much larger active-scene CPU cost while retaining the explicit
separation between steady menu presentation, load-transition gaps, and combat.
