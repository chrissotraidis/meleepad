# G8 post-netplay ordinary attract reversal

Goal: G8 row 7  
Experiment: PERF-285  
Verdict: **single-app opening/attract remains at target cadence; row 7 remains PARTIAL**

## Question

The NET-293 iPad/Mac pair fell to roughly 39-41 FPS while two emulators ran on
the same M1. Does a fresh ordinary installed iPad Simulator app reproduce a
sustained slowdown after those netplay changes, or was that result specific to
the paired workload?

The immediately preceding ordinary run was not a clean answer. Before any UI
inspection it contained isolated one-second 56.7 and 57.6 FPS readings that
recovered on the next sample. A later `get_app_state`/screenshot observation
coincided with new simulator system-service work and a 50.7/48.4 FPS pair. This
repeat therefore prohibited all UI observation until after termination.

## Method

- commit: `fe7bd58943792e053a4456ac9f35569bdaf55097`
- device: the sole booted iPad Pro 13-inch (M5), iOS 26.5 Simulator
- installed executable SHA-256:
  `ac4be9ae00f6b3f163785d092a161f423dfaa24f87da0ce0e07d15ebac194cd4`
- ordinary `com.meleepad.MeleePad` Release launch
- persisted stable profile, 1x render scale, native 60-FPS mode
- no `MELEEPAD_*` environment, savestate, profiler, external pipe, recording,
  screenshot, accessibility query, or Computer Use polling
- run from 10:56:16 through 10:59:37 local; terminate first, inspect second
- retained source log SHA-256 at inspection:
  `3ab6a78b871740346c8785ac480e3fb96190f373a443cc55b90b639f4a029f3d`

The installed app's `runtime.log` contains 17 consecutive ten-second reports.

## Result

| Measure | Result |
|---|---:|
| Runtime reports | 17 |
| FPS range | 59.9-60.0 |
| VPS range | 59.9-60.0 |
| Speed-ratio range | 0.998-1.002 |
| Reports below 59.0 FPS/VPS | 0 |
| DMA underruns | 0 -> 4 |
| Thermal state | nominal throughout |

The high-work reports also remained at cadence:

| Time (UTC) | FPS/VPS | App CPU | CPU thread | Video thread | Draws | Primitives | Underruns |
|---|---:|---:|---:|---:|---:|---:|---:|
| 15:58:24 | 60.0/60.0 | 95.7% | 56.3% | 28.6% | 758 | 45,254 | 0 |
| 15:58:34 | 59.9/59.9 | 126.0% | 68.9% | 49.5% | 839 | 46,451 | 0 |
| 15:58:54 | 60.0/60.0 | 102.1% | 57.4% | 35.7% | 858 | 55,451 | 1 |
| 15:59:04 | 59.9/59.9 | 146.7% | 85.0% | 55.0% | 933 | 52,451 | 1 |

The run returned to the low-work projection by 15:59:14 and stayed at 59.9
FPS/VPS. Underruns increased from one to four during the later transition, then
remained flat through the final report. There is no sustained slowdown and no
repeat of either pre-observer one-second dip at the retained ten-second
resolution. Because the run intentionally had no live visual observer, it is
supporting runtime evidence rather than standalone visible acceptance.

## Decision

Do not profile or modify the static core from this result. The ordinary
single-app opening/attract path continues to fit the Simulator at target
cadence. NET-293's 39-41 FPS is evidence about simultaneous dual-emulator load
and failed cross-platform netplay, not a replacement solo-performance anchor.

Row 7 remains PARTIAL for exactly one higher-ranked gate: an unchanged Release,
human-controlled, uninterrupted five-minute Samus versus level-1 CPU Kirby,
Stock/04, 05:00 Fountain match with short visible recording, responsive input,
coherent rendering, music/SFX, results/return, and the same-run runtime log.
Profile only a slowdown that repeats visibly in that route. G9 remains queued
behind row 7 and independently still fails cross-platform synchronization.
