# iPhone owner gameplay: 2026-09-09

## Status

The owner's running build 18 was read over wired AFC without launching,
pausing, replacing or stopping the app. This is fresh manual gameplay evidence,
separate from the earlier A–B–A–B experiment. The installed game remains v1.02,
1x, 4:3, normal emulated CPU clock, stable performance profile, low-power mode
off. No benchmark route or per-dispatch capture was enabled.

The session began at 17:21:43 JST. Two copies retain 84 and then 108 performance
reports, with the final report at 17:40:28 JST. The DMA underrun counter reached
340. These are empty-queue events, not 340 seconds of silence or necessarily
340 individually audible clicks. The raw logs and device identifiers remain
private under `ref/revision-102/decomp-connected/owner-20260909-173634/`.

## Confirmed slow periods

| Report time (JST) | Reported FPS | Mean frame interval | Thermal state | DMA underrun delta |
| --- | ---: | ---: | --- | ---: |
| 17:27:21 | 40.1 | 21.45 ms | fair | 46 |
| 17:27:31 | 44.1 | 21.64 ms | fair | 45 |
| 17:27:41 | 37.9 | 25.98 ms | fair | 67 |
| 17:35:28 | 45.6 | 18.29 ms | serious | 15 |
| 17:35:38 | 45.5 | 22.37 ms | serious | 49 |
| 17:35:48 | 51.4 | 22.95 ms | serious | 47 |

Reported FPS/speed and frame-interval summaries have different sampling windows;
do not invert an instantaneous FPS reading and treat it as the ten-second mean.
The later three reports contain 111 underruns. CPU-thread utilization was
94.1%, 98.2% and 97.0%; video-thread utilization was 63.7%, 74.2% and 72.1%.
One frame reached 54.02 ms in the middle report. The CPU thread is close to its
available execution budget; this does not identify whether its time is spent
in game logic, graphics submission, synchronization or other work.

There was also a resign/resume event at 17:33:54–17:33:59. Its following report
contains 11 underruns and a 77.84 ms maximum. Keep that lifecycle transition
separate from steady gameplay. The first CPU-usage report after a reset is not
a valid interval baseline; do not interpret anomalous thread percentages there
as sustained utilization.

After 17:35:58 the retained reports return to 59.9 FPS and approximately
16.69 ms mean intervals, without further underruns, while thermal state remains
serious. This does not prove a fix or sustained combat acceptance: the game
workload or an in-game pause may have changed. Host `paused=0` does not establish
that combat is active. Severe dips also occurred at fair thermal state earlier.
**Thermal pressure is a contributor, not a complete explanation.**

## Hardware context

The connected devices are an iPhone 14 and a 12.9-inch iPad Pro (6th generation).
Apple specifies an [A15 Bionic in iPhone 14](https://support.apple.com/en-au/111850)
and an [M2 with a 10-core GPU in that iPad Pro](https://support.apple.com/en-gb/111841).
The stronger iPad hardware is consistent with the owner's better experience;
this session is not a controlled cross-device comparison and supplies no
relative-speed multiplier or measured GPU occupancy.

## Audio-path investigation

The current iOS DMA mixer makes only a small resampling correction, clamped to
0.98–1.02, to stabilize queue depth. When the DMA queue empties, it increments
the counter, supplies silence and re-enters prebuffering. See the patched
Dolphin `Source/Core/AudioCommon/Mixer.cpp`, `MixerFifo::Mix` and `Dequeue`.
The later slow reports show speed ratios 0.755 and 0.769: roughly a quarter
below full speed. A two-percent queue correction cannot compensate for a
sustained producer deficit of that scale. More reserve may hide a short stall,
but adds latency and cannot restore missing game throughput. A broader audio
stretching experiment would change audio behavior, not make gameplay faster.
No buffer, pitch, game-speed or mixer change is retained from this inspection.

## Next implementation boundary

The missing diagnostic is a scene snapshot alongside the existing timing rows,
including enough transition information to reject mixed-scene comparisons.
Source-defined mode IDs must distinguish VS combat, sudden death and results.
Use the pinned decompilation's `src/melee/gm/gmvsmode.c` and the already verified
revision-specific routing addresses, not projection hashes as scene names.

Do not read live guest RAM unsynchronized from the UI timer or call
`Core::RunOnCPUThread` for every log sample: that helper calls `PauseAndLock`.
Instead, capture a small bounded snapshot at the existing CPU-thread
`Core::OnFrameEnd` boundary, and let the UI consume a synchronized copy. Verify
revision/start/stop invalidation, unsupported revisions, transition handling
and logging overhead before deployment. No such runtime patch has been added
or installed in this pass; this is the concrete implementation plan.

Then profile a confirmed sustained slow combat window, separating CPU game work
from video submission/waits. Revisit the guarded matrix candidate only in a
matched scene. It remains unpromoted following the earlier comparison.

## Retained changes

Documentation and private log evidence only. Build 18 stays on the phone;
ISO, saves, preferences and iPad are untouched. No public release, runtime
performance change or general iPhone playability claim is made.
