# G5 scheduler and EFB-prewarm retained summary

Date: 2026-08-28. All source recordings remain local under `/private/tmp` and
contain no disc image. This summary retains the decisive measurements and
SHA-256 identities without committing multi-gigabyte Instruments traces.

## Natural runnable-thread stalls

- PERF-104, emulated frame 48980: total 74.578625 ms, CPU wall 74.126204 ms,
  CPU thread 21.186160 ms, derived off-core gap 52.940044 ms, Metal
  `nextDrawable` 0.035250 ms, no EFB miss, 8,107,191 guest cycles and 147,853
  native dispatches. The 12,001-row 250-us thread-info ring retained run state
  1 around the event; a matching 75.196 ms sampler window accumulated only
  21.943 ms CPU. The thread was runnable rather than blocked in a Dolphin
  wait.
- PERF-105, emulated frame 48683: total 37.532791 ms, CPU wall 35.603732 ms,
  CPU thread 24.026032 ms, no EFB miss. The marker-aligned System Trace window
  contains about 12.008 ms fragmented non-running time while higher-priority
  Brave child I/O, VM pageout, NVMe, and scheduler-balancing work ran. This
  identifies host contention, but its per-process attribution is observer-
  caveated because Instruments was recording on the same M1 host. A later
  24.36 ms high-priority trace-stop call is outside the marker window and is
  excluded.
- PERF-104 SHA-256: marker `dc2989d6c873c3a4f5b432bcf30762a5f1ed78a947bb14981838ed7192ae0db7`,
  phase `58d0dce6346ac85cbccb6820f4e150d047f0112f6f16b36015cf912dcc86b1c8`,
  ring `a70944ea87d6ffb2e6be9f858005169411e96cb39fe127677c6af1134f1ea593`.
- PERF-105 SHA-256: marker `6b41aed4f6efe26eeac5f5f0416282139eac7227ace289e7abd654d84c08dfd7`,
  phase `3eb6b78ecbf12b750240a1902ed36a3065f55989697dbed9f3fb83f044c2fb19`,
  trace TOC `e62a7a80b170b81ffb60107dab7d7dfd6c400d4fb961ce0fabb93fa36bec7752`.

## Game Mode screen

Three isolated, signed, true-native frontend-PGO bundles were launched through
LaunchServices: PERF-106 had `LSSupportsGameMode=false`, PERF-107 had it true,
and PERF-108 reversed to false. Each exact combat interval has 6,723 rows.
Game Policy logs recognized PERF-107 as a game and granted game/frontmost
assertions, but also recorded Game Mode paused before the window became visible;
continuous active status was not proven.

| Run | Total mean | p95 | p99 | worst | CPU mean | CPU p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| PERF-106 off | 16.782716 | 18.110000 | 19.937083 | 156.549042 | 15.868141 | 17.601172 |
| PERF-107 candidate | 16.686547 | 16.950750 | 17.273083 | 130.735875 | 13.481391 | 14.587238 |
| PERF-108 reverse | 16.685514 | 17.019833 | 17.494291 | 125.815667 | 13.717072 | 15.206213 |

The candidate beats the immediate reversal by only 0.069083 ms at p95 and
1.7% CPU mean. PERF-106 is a slower baseline, so the reversal is not decisive.
Retain correct Game Mode eligibility metadata, but claim no causal performance
win from this screen.

## Cold EFB-to-VRAM compilation and prewarm

- All three new A/B/A bundle identities stalled at emulated frame 48436 on one
  EFB-to-VRAM pipeline miss: shader compilation cost 133.494500, 111.807042,
  and 107.823833 ms. A warmed repeat of PERF-106 compiled the same miss in
  1.014417 ms and completed the frame in 17.660334 ms. New bundle identity,
  rather than Game Mode, confounded the A/B/A worst frame.
- PERF-110 logged the three cold UIDs: R4 at startup frame 183, RGBA8 at frame
  48064, and XFB at frame 48436. All optional UID fields were zero. Their
  shader costs were 117.797000, 109.517750, and 112.073125 ms.
- PERF-111 precompiled those exact existing UIDs in `CompileSharedPipelines`.
  Frames 48064 and 48436 then recorded zero EFB miss/compile; frame 48436 fell
  from 133.447167 to 17.234125 ms. The prewarm changes timing only, not shader
  generation or rendering semantics.
- PERF-110 SHA-256: UID log `3328d0547022209d96f5813294871acd6ee53b4541c91965f35a85ebc73e9e27`,
  phase `5cf911e21be8a181e3a7aef2d77ae9171ad367d34605d1710d89928c67b77f09`.
- PERF-111 SHA-256: UID log `3b1a40e7bfaa224f7752cf5813a906bb8c9022a04184959d3fdaa800e46c655d`,
  phase `983787efa5acd33d86b5f173e3e4016a47f417ee3b16fb5ce099d32e2d9381f1`.

## Retained implementation and cleanup

Patch 0020 makes UID logging default-dormant and the three-UID prewarm opt-in;
the packaged wrapper opts in. The signed disposable bundle passed layout,
plist, embedded-marker, dependency, and code-sign checks; runner SHA-256 is
`5480f3bd2a4c96ccfa588cc79a81d499dad217e0a79864274f22a232a46e14f0`.
Seven exact obsolete Instruments `.ktrace` scratch files plus PERF-109's raw
scratch were deleted after their valid trace bundles were retained, recovering
about 11 GiB. No game or Instruments process remained afterward.
