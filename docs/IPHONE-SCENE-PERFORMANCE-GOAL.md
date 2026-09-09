# iPhone scene performance follow-up

Started 2026-09-09 after the owner's build-18 slowdown report. Aim for a bounded
approximately two-hour engineering pass, extending only for a running validation.
The stable baseline remains Preview 4/build 18; the earlier matrix candidate is
not promoted. Preserve both game revisions, device data and unrelated files.

## Outcome

Complete: retain the nonblocking scene diagnostics and private build 20 with
unchanged stable game modules. Do not promote the matrix optimization. One
combat pair narrowly passed the screening threshold, but confirmation failed
the matched-temperature gate and baseline variation remained material. The
phone is returned to build 20; the iPad and public release are unchanged.

This pass improves diagnosis, not proven iPhone FPS. Combat and results are now
separated in actual device logs, and one source-supported candidate has a
bounded, documented non-promotion decision.

## Plan executed

1. Add revision-aware scene snapshots at the existing CPU frame boundary.
   Publish bounded synchronized data for the existing ten-second performance
   log; do not pause the CPU, read guest memory from UI code, write per-frame
   files or enable per-dispatch profiling. Include transition counts so a
   sample covering multiple scenes cannot be mistaken for one scene.
2. Test supported/unsupported revisions, initial validity, transitions, reset,
   coherent reads and overhead. Build the physical-device app using unchanged
   stable game modules. Establish identity and preserve data on installation.
3. Capture an identified slow scene on the attached iPhone. Distinguish VS
   combat, sudden death, results, menu and unknown states. Attempt native
   profiling only when connectivity is available; no Simulator or QuickTime.
4. Select one optimization justified by the scene/profile evidence. Compare
   matched workload, settings and starting temperature with the stable control.
   Retain only repeatable frame-time benefit without correctness/audio regression.
   Otherwise document rejection and the exact next target. No automatic release.

Progress and evidence will be appended here. Instrumentation is not an FPS fix.

## First implementation

Patch 0058 adds a single CPU-frame producer and a synchronized snapshot read by
the existing ten-second log. A producer uses `try_lock` and skips contention;
it does not wait, allocate, read the clock, write logs or pause the CPU. Guest
RAM is read only on the CPU thread. The snapshot includes validity, revision,
routing word, session, sampled-frame count and scene-transition count. Pending
and previous mode bytes do not count as actual scene transitions. Unreadable
state invalidates the sample; recovery counts as a transition for conservative
mixed-window rejection. Unsupported revisions disable sampling.

The runtime-scoped session resets before boot and after runtime destruction,
including create failures and early exits. The labels distinguish source-defined
VS character selection, stage selection, combat, sudden death and results;
other modes remain conservatively labeled. A combat label does not prove the
in-game pause menu is closed. Comparing session/frame/transition counters across
reports is required; one scene name does not identify the whole preceding window.

The standalone patch-extraction test exercises revision addresses, validity,
resets, transitions, invalid reads, contended producer skipping and concurrent
snapshot reads. Bootstrap verifies the complete patch series. Physical core and
Release app builds pass. An isolated host recorder benchmark measured 5.0–5.5 ns
per uncontended call with a synthetic read callback; this excludes actual guest
memory reads and is not physical-device overhead acceptance.

Private build 20 contains diagnostics with byte-identical build 18 modules for
both revisions. It was installed in place after a fresh backup; all 24 material
files and the ISO metadata match afterward. The iPad was untouched. A fixed
four-player Big Blue route is now validating scene identity without native or
per-dispatch profiling. No speed improvement is claimed.

## Physical scene validation

Build 20's first four-minute route successfully reports source-defined scene
changes. Its unchanged-module combat samples show 51–54 FPS, serious thermal
pressure and approximately 99% CPU-thread usage with a constant transition count.
The late 111,205-primitive projection is now positively identified as
`vs-results`, routing `02020104`; its final two reports are 28.3–28.4 FPS at
serious thermal pressure. Thus earlier unclassified matrix-experiment tails
must not be called combat improvements. Exact earlier state cannot be recovered
retroactively, but the matching late workload in this route is results.

This first run began thermally serious and is scene validation, not a fair
speed comparison with earlier nominal-start baselines. CoreDevice and AFC work;
Instruments still lists both devices offline. One separate run of the existing
phase/dispatch-time profiler is collecting ranking evidence. Its overhead is
explicitly excluded from performance acceptance. Combat is the first target;
results remain a separate performance issue.

## Optimization selection from combat-only profiling

The separate existing profiler captured 6,439 phase rows and 230,851 dispatch
samples inside unchanged-session/transition VS-combat windows, excluding 250 ms
at each wall-clock boundary. Calibrated dispatch samples rank PSMTXConcat 7.79%,
HSD_MtxInverseTranspose 5.25% and HSD_MtxScaledAdd 2.46% of sampled guest time.
Those are sample shares, not whole-app or GPU savings; profiling overhead and
clock calibration affect them. Estimated sampled dispatch coverage is about
71% of recorded CPU-thread time, and native Instruments profiling remains
unavailable. Individual sampled dispatch timings can include host scheduling
and do not replace native stack attribution.

This new scene-specific evidence justifies one focused retry of the previously
validated guarded matrix candidate. Private build 21 will combine the identical
build 20 host/diagnostics with the previously tested v1.02 module. Both normal
runs will disable detailed capture. Evaluate unchanged-transition combat
windows separately from results, with matched settings and thermal state;
repeat only if the first pair is promising. The route is not an exact saved-state
replay, so modest changes within workload/run variation remain inconclusive.

Acceptance screen set before the candidate run: use consecutive reports that
both identify valid VS combat with identical session and transition counts,
with sampled scene-frame boundaries fully inside 3,500–9,000. Compare weighted
mean frame intervals, fraction over 20 ms and underruns per observed second.
A first pair must improve mean intervals by at least 5% without worse slow-frame
fraction or materially worse audio starvation (more than 10% per second) to
justify a repeat. Both runs must start in the same reported thermal state.
Repeat a promising pair; reject promotion if it does not reproduce or if
workload differences prevent a defensible comparison. This is a screening
criterion, not statistical proof of a general FPS gain.

## First combat comparison

The predeclared window filter yields nine ten-second combat reports for each
build. Build 20: 18.030 ms weighted mean, 8.37% over 20 ms, 139 underruns (1.54/s).
Build 21: 17.125 ms, 1.14% over 20 ms, 53 underruns (0.59/s). The mean reduction is
5.02%, narrowly passing the screen. Both started serious, but the candidate
briefly became fair; its sampled primitive range also fell to about 25,854
versus 32,460 minimum in the control. Those confounds prevent promotion from
this pair alone. One reverse control and one candidate repeat will decide this
pass; no additional candidate or open-ended testing is planned.

## Other leads checked without adding experiments

The boot allocation warning has a plausible optional-cache origin: the static
core initializes an `EmptyBlockCache` derived from `JitBaseBlockCache`, whose
base initializer attempts a large lazy entry-point map and permits a null
result. This is not evidence of a new sustained combat bottleneck; no memory
mapping or cache option was changed.

The older retained native control profile also shows substantial video-thread
CPU time in `FifoManager::RunGpuLoop` and `SetCPStatusFromGPU`. That suggests a
future measurement separating useful command processing from polling/waiting,
not another blind FIFO sleep-threshold change (those were already rejected).
These are older native samples and are not newly attributed to this run's
combat window. Shader/vertex-decoder changes likewise need current cost evidence.

## Final comparison and decision

| Run | Build | Start thermal | Combat mean | Frames over 20 ms | Underruns/s |
| --- | --- | --- | ---: | ---: | ---: |
| Control A1 | 20 | serious | 18.030 ms | 8.37% | 1.54 |
| Candidate B1 | 21 | serious | 17.125 ms | 1.14% | 0.59 |
| Control A2 | 20 | fair | 17.640 ms | 4.04% | 1.09 |
| Candidate B2 | 21 | nominal | excluded | excluded | excluded |

A2 used nine eligible ten-second combat windows. B2's nominal start failed the
predeclared matching condition against A2's fair start. Its driver and exact
app process were stopped, and its partial log retained as an invalid run.
It was not substituted into the acceptance table or counted as a confirmation.
The first pair's candidate had both a cooler thermal interval and some lower
rendering workload. There is therefore no repeatable causal improvement strong
enough to promote. No additional run or candidate was added to this pass.

Build 20 was reinstalled in place and its normal startup checked. All 24 backed-up
material files and ISO metadata match before/after the final installation.
The v1.00 and v1.02 game modules remain byte-identical to stable build 18.
The normal runtime is stopped after verification so it does not keep heating
the phone. Build 21 remains a private, unpromoted experiment.

### Next focused work

Use scene-aware logs from real play to select a sustained combat case. Before
another small matrix A/B, establish a reproducible initial game-state/input
fixture and a matching thermal start; the existing route is not an exact replay.
For a potentially larger engine improvement, measure useful video command
processing separately from FIFO/status polling in that same confirmed scene.
The previous native sample points to that boundary, but does not prove how much
current combat CPU time is avoidable. Do not repeat blind sleep-threshold or
leaf-math changes. Restoring native profiler connectivity remains useful, while
existing instrumented dispatch ranking must stay separate from speed acceptance.

Private evidence: `ref/revision-102/scene-followup/` contains all run logs,
profile CSVs and analysis, comparison JSON, packages and preservation checks.
The implementation is reproducible through patch 0058 and
`python3 scripts/test_gameplay_scene_snapshot.py`. No game-derived code, game
assets, raw logs or device identifiers were added to Git; no release was made.
