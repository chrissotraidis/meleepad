# iPhone scene performance follow-up

Started 2026-09-09 after the owner's build-18 slowdown report. Aim for a bounded
approximately two-hour engineering pass, extending only for a running validation.
The stable baseline remains Preview 4/build18; the earlier matrix candidate is
not promoted. Preserve both game revisions, device data and unrelated files.

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

Private build20 contains diagnostics with byte-identical build18 modules for
both revisions. It was installed in place after a fresh backup; all24 material
files and the ISO metadata match afterward. The iPad was untouched. A fixed
four-player Big Blue route is now validating scene identity without native or
per-dispatch profiling. No speed improvement is claimed.

## Physical scene validation

Build20's first four-minute route successfully reports source-defined scene
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
