# G5 external display cadence and savestate-startup guard

Date: 2026-08-28

Status: **G5 FAILS; diagnostic crash fixed**

## Questions

1. Does the Game Mode build actually put new surfaces on the M1 MacBook Air's
   display every 16.7 ms through a representative Fountain match?
2. Why did the opt-in `SIGUSR2` state-load harness crash PERF-106 during
   startup, and can the request be made safe without changing normal gameplay?

## Crash-report ingestion and exact reproduction

The supplied PERF-106 report is an ARM64-native `SIGTRAP` on the main thread
inside `PlatformMacOS::MainLoop`. Its emulation thread is still named
`Emuthread - Starting` and is waiting for the asynchronous shader compiler.
The supplied report hashes to
`1d406dbbf4f195239fc814c615bb19c8bc9d72efb22b42a0303e12617bf83cc1`.

PERF-122 reproduced the failure deliberately by sending the opt-in diagnostic
`SIGUSR2` request while the phase log still reported `emulated_frame=0`.
The request was consumed immediately, and Dolphin stopped at
`DVDThread.cpp:175`, `WaitUntilIdle`, because the CPU lifecycle was not ready
for a state load. The fresh crash report is
`MeleePadRunner.real-2026-08-28-140738.ips`, SHA-256
`5b8299eec21c409a52801dd47a74c3e6ea5125d91ddf96619c6a14dc6312750c`.

The smallest fix is in canonical patch 0013. `Platform::UpdateRunningFlag`
now consumes pending save/load requests only when Core is Running or Paused.
The request flag remains set during Starting or Uninitialized, so no signal is
lost. Shutdown behavior is unchanged. This path exists only when
`MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1`; it is not a spontaneous product
gameplay crash.

PERF-123 is the passing-after regression. `SIGUSR2` was again delivered at
exact `emulated_frame=0`; the runner survived, the load remained pending, and
the same request was consumed once Core became runnable. A subsequent
68-second Display trace and normal shutdown completed.

## Non-perturbing display observer

The prior `MTLDrawable.addPresentedHandler` observer changed the work being
measured, so it remains rejected. Instruments' stock Metal and Animation
Hitches templates also saturated or produced impractically large captures.

A local Instruments template named `MeleePad Display Cadence` was therefore
created with only the Display instrument. Its local path is:

`~/Library/Application Support/Instruments/Templates/MeleePad Display Cadence.tracetemplate`

PERF-121 proved a bounded ten-second capture contains the required
`displayed-surfaces-interval`, `display-vsyncs-interval`, and
`display-surface-swap` tables without any callback inside MeleePad.

## PERF-124 full Fountain result

PERF-124 attached that template to the signed native runner after the retained
Fountain state was live. The trace used no rolling `--window`, ran for the full
115-second limit, and terminated the runner normally.

- Host: MacBook Air M1, native ARM64, macOS 26.5.2.
- Runner SHA-256:
  `32cebb614e880324e61ea5ca900f43e182327f541a2e055c25e30d014bdb8e79`.
- Frontend-PGO module SHA-256:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
- Savestate SHA-256:
  `e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
- Trace duration: 115.333254 seconds; Display data span: 114.997791 seconds.
- Process-attributed rows selected after the two compositor setup rows: 6,863
  on surfaces 77, 97, and 109, yielding 6,862 consecutive start intervals.
- Interval min/mean/median: 16.666208 / 16.753783 / 16.666334 ms.
- Interval p95/p99/max: 16.666417 / 16.666417 / 366.659583 ms.
- Distribution: 6,846 one-refresh intervals, 15 two-refresh intervals, and
  one 366.660 ms interval; 16 intervals exceed 16.7 ms.
- Phase logger: exact combat emulated frames 48123 through 54845 are present;
  all recorded EFB-to-VRAM pipeline-miss counters are zero.

The 366.660 ms interval at trace time 107.690-108.056 seconds is consistent
with the match/results transition. It is not the only failure: two-refresh
intervals occur from 3.275 seconds onward, including well before the result
transition. Excluding the long transition therefore still leaves Fountain
above the strict worst-case gate.

The trace's p95 and p99 demonstrate that ordinary presentation is on a real
60 Hz display cadence. The exact verdict is nevertheless **FAIL**, because G5
requires every measured interval to be at most 16.7 ms. This is not evidence
of a general 12.5-FPS product and it does not establish stable 60 FPS.

## Interpretation and next experiment

PERF-089 already proved the statically recompiled on-core path meets 16.7 ms
on the exact retained window. PERF-070 joined ordinary presentation misses to
higher CPU-thread work, while severe gaps were off-core. PERF-114 through
PERF-116 then proved Game Mode mitigates the latter class. PERF-124 independently
confirms rare actual-display misses remain.

The guest VI cadence is derived from the emulated hardware timing and is close
to 59.94 Hz, while the host display refreshes at 60 Hz. That relationship can
produce occasional phase slips, but changing guest speed would alter gameplay,
audio, and deterministic/netplay behavior and is not authorized by these data.
The next experiment must first separate phase-slip repeats from genuine late
frames using a shared observer timestamp. It may not retry rejected timer,
QoS, time-constraint, drawable-lifecycle, or broad compiler variants, and it
must not count duplicated stale content as a new game frame.

## Retained raw evidence

Raw evidence remains local under:

`/private/tmp/meleepad-perf114-115-gamemode.1aRWbj/run-124-display-full-fountain`

Key SHA-256 values:

- `displayed-surfaces-interval.xml`:
  `5aaf45d9eefa4f2e9b0b869e316b7139e6ecdaedca4bf305a3f825c4dea87588`
- `display-vsyncs-interval.xml`:
  `066a2f286e19d571e84b1136c22c80e307e20b38bb56fc17a414c6d816cfc1d0`
- `display-surface-swap.xml`:
  `2b5f6779cd72c6816f5526a4b42648aa15afa1c5cb89d003e54f1fdefa636093`
- `phase.csv`:
  `5b5a47910e2c6c6c1aada0ff358c4a61f7bf21685cb8e42b40c8b4231cfade53`
- `stderr.log`:
  `cce2381470698676d94f0fe13a48e2d9cf6299640e4c9df0a5030f32a2f4025b`
- `trace-boundary.txt`:
  `7d81c4c0e1129ce4b843dde578e96329a1a3d14cf76d92f7ce3ec0b73658dc1a`

No disc image, extracted game data, savestate, generated module, trace, or
crash report is committed.

## Checkpoint validation

- Canonical patch 0013 applies/reverses cleanly against the pinned checkout.
- `MeleePadRunner` rebuild: pass.
- Applicable CTest entries: 40/40 pass (three unbuilt upstream benchmark/
  fuzzer executables and one disabled upstream test excluded as before).
- Controller-pipe Python tests: 16/16 pass.
- Repository safety, shell syntax, and `git diff --check`: pass.
- Fresh signed macOS package layout and strict signature: pass.
