# G8 Computer Use/audio-overload reversal

Goal: G8 row 7  
Experiment: PERF-287  
Verdict: **sub-55 observer event attributed and reversed; no product change**

## Trigger

After publishing the human acceptance harness, the unchanged ordinary Release
was left running visibly in the sole iPad Simulator. One report violated the
immediate-fail threshold:

| UTC | FPS/VPS | Speed | App CPU | CPU/video | Workload | Underruns |
|---|---:|---:|---:|---:|---|---:|
| 16:21:09.282 | 54.2/54.3 | 0.917 | 81.4% | 67.4%/6.6% | 2 draws, 4 primitives | 4 |

The previous report was 59.9/59.9 with three underruns. The next report
recovered to 59.9/59.9, although underruns reached eight. Resident memory fell
from 293.2 to 114.3 MiB in the failing row, but the emulated graphics workload
was the light static/menu projection and neither CPU nor video was saturated.

The installed executable SHA-256 was unchanged:
`ac4be9ae00f6b3f163785d092a161f423dfaa24f87da0ce0e07d15ebac194cd4`.
The complete trigger runtime log SHA-256 is
`21f433e59dfe6ced486828cd32d026d0456188c26252da12daf0d3ea8f1e1d87`.

## Host correlation

The host log supplies a synchronized external event chain:

- 11:21:08.433 local: `SkyComputerUseService` created a `UserIsActive`
  assertion labelled `Codex Computer Use interaction`;
- 11:21:08.456: the host removed an idle service with
  `JETSAM_REASON_MEMORY_IDLE_EXIT`;
- 11:21:09.282: MeleePad emitted the 54.2/54.3 report; and
- 11:21:09.303: Core Audio reported an `overload` for
  `HostApplicationDisplayID=com.meleepad.MeleePad`, with a 14.548 ms I/O
  duration against an 11.354 ms budget.

The active Computer Use assertion begins 0.849 seconds before the low report,
and Core Audio records the overload 21 ms after it. This directly explains the
audio underrun growth. The low app CPU and trivial guest workload reject the
corrected controller-wait loop or a new static-core ceiling as the immediate
cause.

## Observer-free reversal

A fresh ordinary Release then ran for 180 seconds. The app was terminated
before its log was read. There was no Computer Use, screenshot, accessibility
query, recording, profiler, savestate, external input, or live log access.

| Measure | Clean control |
|---|---:|
| Reports | 16 |
| Minimum FPS/VPS | 59.7/59.7 |
| Minimum speed | 0.989 |
| Reports below 59 FPS/VPS | 0/0 |
| Reports below 0.98 speed | 0 |
| DMA underruns | 0 -> 1 |

At the matched light-work interval, the control remained 59.9/59.9 with zero
underruns. It later retained 59.9/59.9 under 171.4% aggregate app CPU, split
97.5% CPU thread and 67.4% video thread, with 1,058 draws and 74,476
primitives. Generic idle-service jetsam messages also occurred during the
control without an audio overload or cadence loss; therefore jetsam alone is
not classified as causal. The distinguishing synchronized events are the live
Computer Use interaction and Core Audio overload.

The clean control runtime log SHA-256 is
`65d0d0f38da82ed8da922e1ae0a245e359e9fa8e9fb3522de9c1a7bab7030119`.
Private raw host/runtime logs remain outside Git.

## Induced-observer reproduction

A third fresh ordinary process supplied the missing causality check. After the
light projection stabilized at 59.9 FPS/VPS, exactly one Computer Use
`get_app_state` observation was invoked. The host recorded two brief
`Codex Computer Use interaction` assertions from 11:30:16.776 through
11:30:17.371 local. The next complete report at 11:30:19.556 fell to:

- 56.2 FPS / 56.5 VPS / 0.981 speed;
- 82.2% aggregate app CPU, with only 67.9% CPU thread and 5.4% video thread;
- the unchanged two-draw/four-primitive projection; and
- DMA underruns 3 -> 6.

The next report recovered to 59.9/59.9. This induced window contains no Core
Audio overload or idle-service jetsam event, so the Computer Use observation is
sufficient to reproduce a sub-59 pacing/underrun failure by itself. The audio
overload in the original run is an additional synchronized amplifier and is
not required for the observer effect. The induced runtime log SHA-256 is
`09d355dcc702361e0e926cc6a1874ab4305e27481a492d3d564dadd34656e428`.

## Decision

Keep the product unchanged. PERF-287 now contains trigger, observer-free
reversal, and induced-observer reproduction. Computer Use is a demonstrated
measurement perturbation; the concurrent Core Audio overload explains the
more severe original sample. This reinforces the existing prohibition on
Computer Use polling during performance acceptance; it does not weaken any
threshold or turn observer-free automation into manual evidence.

Return to the unchanged-build human acceptance harness. During combat, do not
invoke Computer Use, screenshots, or accessibility inspection. If the short
HEVC-only human route repeats a sub-59 interval, retain and profile that exact
interval. Otherwise the human route can close row 7.
