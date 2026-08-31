# G8 iOS host-runtime PGO direction

Date: 2026-08-30

Status: **PERF-231 MATERIAL IMPROVEMENT; G8 row 7 remains open**

The prior macOS runner-PGO rejection bounded host-only work at 2.68%. The
fresh iPad exact-module-PGO sample has a different shape: 3,758 inclusive
`StaticRecompCore::Run` samples versus 3,214 under the module dispatcher, a
14.48% host-runtime opportunity. That platform-specific evidence clears the
five-percent experiment gate without reopening the rejected macOS route.

An isolated iOS Simulator build instrumented only the nine static-recompiler
runtime translation units. The canonical core archive and provisioned linker
response remained unchanged. A representative built-in sequence included
38.2-52.8 FPS demanding scenes, CPU-GPU saturation, and DMA starvation. LLDB
explicitly flushed a valid 31,768-byte profile before shutdown.

Strict profile use passed stale and unprofiled-function errors. Against a
fresh matched control, `Run` shrank 18.5%, `FastDispatchableAt` 11.5%,
`DispatchableAt` 11.1%, and lockstep `ShouldCheck` 56.3%. The profile-use app
then ran with the unchanged 82,821,272-byte non-PGO game module.

Live heavy intervals improved into the 59.0-59.9 FPS range even with the
non-PGO module. A later shader-heavy interval still fell to 54.5 FPS, and DMA
underruns continued to accumulate. This is a material independent gain, not
audio-continuity acceptance. Row 7 remains open until a fixed combined host
PGO plus exact-source module-PGO run sustains real time with no sustained DMA
underrun.

Evidence: `docs/evidence/g8/ipad-host-pgo-live-summary.txt`.

The app was terminated and the sole Simulator shut down. No private profile,
module, app, game data, save, or build output is committed.
