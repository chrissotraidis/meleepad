# G8 iPad audio continuity and combat attribution

Date: 2026-08-30

Status: **G8 row 7 fails under sustained Simulator combat; mechanism named**

## Question

Does the iPad path maintain continuous audio during demanding combat, and is
the failure primarily an audio-buffer sizing problem, renderer/vertex-loader
cost, or execution cost in the ahead-of-time GALE01 module?

## Instrumentation

Default-dormant source diagnostics now expose CoreAudio output callback/frame
counts plus the Dolphin mixer DMA queue depth, target, and empty-dequeue count.
They do not change audio scheduling or emulation behavior. The focused source
regression is `tests/test-ios-audio-diagnostics.sh`; the canonical dependency
patch is `patches/moderngekko-dolphin/0028-ios-audio-continuity-diagnostics.patch`.

## Live result

The source-consistent 120 ms control app booted the retained imported GALE01
image and reached the four-character combat sequence on the iPad Pro 13-inch
(M5) iOS 26.5 Simulator. Static/title intervals reached 59.9 FPS. Demanding
combat then measured 39.9 and 37.6 FPS with the CPU-GPU thread at 99.0-99.2%.
DMA underruns rose from 99 to 258 in 30 seconds. Audio callbacks continued, so
the output unit remained alive; the emulated producer could not keep the DMA
queue supplied while the game ran below real time.

A 160 ms requested-latency experiment increased the queue target from 15 to 20
granules but did not change the producer rate. During combat it fell as low as
41 FPS / 0.671 speed and accumulated 216 underruns, then recovered immediately
at the title. The larger buffer only delayed starvation and was reverted.

## CPU attribution

A separate 10-second live combat sample contains 7,017 CPU-GPU-thread samples.
The dominant branch is `StaticRecompCore::Run` (3,921 inclusive), with 3,137
below `chassis_dispatch`; another 619 samples place `StaticRecompCore::Run` at
the top of stack. `func_80015940` and `func_80341940` are the largest named
generated functions. `VertexLoader::RunVertices` accounts for 64 inclusive
samples plus 20 top-of-stack samples, below two percent of the thread sample
count. The sanitized retained counts are in
`docs/evidence/g8/ipad-combat-sample-summary.txt`.

This capture identifies generated/static-core execution as the primary steady
combat cost. Metal shader compilation still aggravates cold transitions, but
it does not explain the sustained CPU-GPU saturation after those transitions.

## PGO reversal

The retained macOS frontend profile was preflighted against the current iOS
module with `-Werror=profile-instr-out-of-date`. The strict build failed:
affected generated chunks each contained one mismatched function, including
the hot `chunk_0005_text1_80015940.c`; later chunks also had no profile data.

A disposable tolerant build was completed only to bound potential upside. It
used matching records and ignored stale/unprofiled records. The resulting
module was 83,558,520 bytes versus 82,821,272 bytes for control. Live telemetry
confirmed that exact candidate was loaded. In the same four-character combat
path it measured 40.5, 40.2, and ultimately 39.9 FPS with the CPU-GPU thread at
98.2-99.4%; underruns rose from 282 to 506. That is no material improvement
over control. The stale partial profile is rejected and is not integrated.

## Decision

- Row 7 stays non-green. Output callbacks survive, but sustained combat audio
  continuity fails because game production falls materially below real time.
- Do not increase the audio reserve again; it cannot repair a producer-rate
  deficit.
- Do not reopen software vertex-loader optimization from this capture.
- Do not promote the stale partial PGO profile.
- The next performance experiment must either generate a fresh,
  combat-representative profile for the current generated source or remove a
  measured cost in the generated dispatch/static-core path. It must pass a
  strict profile-compatibility gate and then a control/candidate live reversal.

No game process or Simulator remained running after the experiment.
