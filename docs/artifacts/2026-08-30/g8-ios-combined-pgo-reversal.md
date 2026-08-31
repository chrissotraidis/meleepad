# G8 iOS combined host and game-module PGO reversal

Date: 2026-08-30

Status: **PERF-232 MATERIAL IMPROVEMENT; G8 row 7 remains open**

PERF-231 proved that iOS host-runtime PGO independently lifts demanding scenes,
but its live reversal used the non-PGO game module. This follow-up trained the
exact surviving generated source and combined both useful profiles in one
non-instrumented candidate.

The training module covered all 6,537 frontend functions and recorded
513,652,565 calls to `chassis_dispatch`. Its private profile is valid and dense.
The first strict-use attempt correctly rejected an unobserved integer-interpreter
fallback file. The corrected isolated build kept three unobserved fallback
translation units profile-free while applying strict exact-source PGO to all 237
generated chunks and every observed runtime helper. This avoids treating a
future fallback path as cold, the mechanism behind an earlier stale-PGO
regression. All profiled sources passed `profile-instr-out-of-date` as an error.

The resulting 83,490,248-byte module has SHA-256
`3b6f7bca149f49a17cf7d9d180a29bfe7f70677f5a100d17fc921c7fefceb50d`.
It was paired with the retained host-runtime-PGO app. Neither component contains
instrumentation sections.

## Live reversal

The cold process initially sustained multiple 59.9 FPS intervals, then fell to
32.5, 51.2, and 33.4 FPS during the Ice Climbers stage/intro transition. It
recovered to sustained 59.9-60.0 FPS and visibly entered four-character combat.
That first heavy resource sequence then measured 53.4, 50.9, 38.9, 50.4, 37.9,
and 54.6 FPS while texture creation rose from 422 to 1,739, pixel shaders from
69 to 186, and DMA underruns from 174 to 310.

The warmed in-process repeat was materially better: long stretches held
59.8-60.0 FPS and underruns increased only 321 to 340 over its final 30 seconds.
It was not clean. One transition reported 36.5 presentation FPS / 50.1 VPS, and
a later demanding interval measured 59.2 FPS. Cold shader/resource construction
is therefore a large independent cause, but warming alone does not prove audio
continuity or stable 60 FPS.

The retained combat screenshot also continues to expose the separately tracked
camera/geometry presentation defect; performance work must not hide that open
correctness gate.

## Warm residual

A subsequent ten-second sample captured 6,625 CPU-GPU-thread samples. The
inclusive `StaticRecompCore::Run` branch held 4,616 (69.7%), with 4,034 (60.9%)
below generated `chassis_dispatch`. `VertexLoader::RunVertices` was only 194
(2.9%). Async shader workers were predominantly waiting, though one live Metal
pipeline creation was sampled. Texture/EFB-copy work remained secondary.

The next falsifiable performance experiment is not another generic compiler,
buffer, dual-core, or vertex-loader variant. It must first test whether retaining
or prewarming Metal pipeline/resource state removes the cold-process collapse.
The warm residual still requires a separately measured generated-dispatch
mechanism; a pipeline-cache win alone cannot be called a row-7 pass.

Evidence:

- `docs/evidence/g8/ipad-combined-pgo-live-summary.txt`
- `docs/evidence/g8/ipad-combined-pgo-four-character-combat.jpg`

The app was terminated and the sole Simulator shut down. No ROM, extracted game
data, module, profile, save, or build output is tracked.
