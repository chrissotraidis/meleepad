# G5 current Final Destination baseline

Date: 2026-08-28

Status: **CURRENT BUILD IMPROVES FINAL DESTINATION; STRICT G5 STILL FAILS**

## Question

Does Final Destination still fail after the retained scheduler-idle setting,
current combat frontend-PGO module, native internal resolution, EFB pipeline
prewarm, display synchronization, and fullscreen product configuration? Is the
remaining failure unique to Fountain of Dreams?

## Reconciliation and excluded runs

The supplied PERF-106 attachment is the already-ingested native ARM64 startup
`SIGTRAP`. Patch 0013 defers state-load requests until Core is Running or
Paused, and PERF-123 is the retained passing regression. It adds no new crash
work.

The first PERF-135 Final Destination match completed coherently, but its timing
file was excluded after the Computer Use state check following Close
transparently relaunched the app and truncated `render_times.txt`. A repeat
retained its file, but post-run configuration reconciliation found the
top-level frontend had forced `fullscreen=false`; it is retained privately as
a windowed control only. Its conservative 2,801-frame combat window measured
16.666398 ms mean, 16.952416 ms p95, 17.107792 ms p99, and 45.701125 ms worst.

The first corrected fullscreen attempt visibly landed on Yoshi's Story rather
than Final Destination. It was rejected before any timing interval. The final
attempt returned through CSS and verified the red `Final Destination` label
before selecting the stage, then verified actual Final Destination combat and
match completion. These exclusions are harness errors, not product results.

## Verified fullscreen run

The signed disposable bundle retained:

- runner SHA-256
  `951168863076c3e3e714b3f684627c972590c7ef9dec4d25ff3b38c5fbef9156`;
- current frontend-PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- native `InternalResolution = 1`, Metal, Cubeb, DSP thread, buffered render
  logging, EFB prewarm, and both frontend/runtime fullscreen settings; and
- a ROM-safe isolated unlocked GCI and FIFO controller. No disc image, GCI,
  savestate, module, or app is committed.

Computer Use visibly confirmed real macOS fullscreen, actual Final Destination,
coherent Pikachu-versus-CPU-Yoshi combat at a 59.9-60.0 FPS title reading, and
natural match completion. No fighter morphing or stage corruption was visible.
The app's bundle is in the games category, has `LSSupportsGameMode=true`, and
the system log proves PID 72071 entered a real fullscreen Space. This run did
not recover the earlier explicit `Game mode enabled` log phrase, so it is a
fullscreen-eligible baseline, not a new independent Game Mode activation
claim. PERF-114/116 remain the activation proof for the product topology.

The screenshot and savestate operations occurred before the selected interval.
The buffered log was closed normally, then copied without another UI query.
Its SHA-256 is
`3021801b98353c2e50e57d9533170823a3b10345f27ea9c8e71e658f32b7ab2e`.

Because a live `wc` can lag the C++ stream buffer, the selected window starts
405 rows after the observed pre-interval line count and ends well before the
58-second input sequence finishes. Lines `30100..32900` are therefore a
conservative 2,801-frame interior combat window:

| Metric | Current fullscreen Final Destination |
| --- | ---: |
| Mean / FPS | 16.683246 ms / 59.940 |
| Median | 16.677625 ms |
| p95 | 17.209583 ms |
| p99 | 17.399125 ms |
| Worst | 24.292208 ms |
| Frames at or below 16.7 ms | 1,602 / 2,801 (57.194%) |
| Frames above 33 ms | 0 |

The 24.292208 ms worst row is followed by 9.350917 ms, consistent with a late
producer callback followed by catch-up. Several independent interior windows
retain p95 around 16.94-17.21 ms, so the strict failure is not created by that
one outlier.

## Decision

Final Destination is materially better than the 2026-08-24 portable-PGO
baseline (16.946083 ms p95, 17.189292 ms p99, 1385.242250 ms worst), and the
current run has no severe frame above 33 ms. It still fails D2's strict
16.7 ms p95/p99/worst boundary. Fountain is therefore not the only remaining
producer-tail scene, although its reflection correctness defect remains
separate.

Retain no product code change from PERF-135. A local Final Destination slot-1
state is now available at SHA-256
`19e5d7b8d66831f2e9032797dae2ef8399f8a6593e19a020d8cde8e176c8f181`.
Use it for one default-dormant phase-logged attribution of the 24 ms class,
then compare CPU-thread, wall-minus-thread, video, audio, throttle, and Metal
waits to the existing Fountain descheduling evidence. Do not reopen rejected
compiler, timer, drawable, QoS, dual-core, or presentation variants. G5 stays
open and G6 stays blocked.
