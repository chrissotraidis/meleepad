# G8 revision-0 cold host profile and loop-hoist reversal

Date: 2026-09-01

## Verdict

G8 row 7 remains a hard fail. The user's ordinary visible first-run 21.9 FPS
Fountain result remains the controlling product floor. A bounded host-loop
candidate shortens the scripted cold-combat slowdown, but two candidate runs
still fall to 21.1 and 20.2 FPS. It is retained only as a small composable
optimization, not as a row-7 pass or physical-iPad promotion.

The next optimization cycle moves one boundary outward. It must correlate the
repeatable cold transition spike with per-frame generated-dispatch work,
pipeline/shader creation, presentation, and audio starvation. It must not
reopen already-rejected guest regions or describe later 60 FPS recovery as a
fix.

## Host profile

Apple's Time Profiler capture did not yield a usable trace in this environment,
so a direct 1 ms process sample was used. The warm exact-combat capture contains
20,000 process samples and 12,060 CPU-GPU-thread samples. The cold first-combat
capture contains 12,347 CPU-GPU-thread samples; it is observer-contaminated and
is attribution evidence only.

| CPU-GPU top-of-stack cost | Warm | Cold first combat |
| --- | ---: | ---: |
| `StaticRecompCore::Run` self | 632 / 12,060 (5.240%) | 892 / 12,347 (7.224%) |
| lockstep `ShouldCheck` | 79 / 12,060 (0.655%) | 116 / 12,347 (0.940%) |
| `FastDispatchableAt` | 217 / 12,060 (1.799%) | 314 / 12,347 (2.543%) |
| named dispatch/state helpers, warm | 376 / 12,060 (3.118%) | — |
| `Run` self plus `ShouldCheck`, cold target | — | 1,008 / 12,347 (8.164%) |

The cold profile therefore cleared the five-percent structural screen for one
bounded host-loop candidate. Shader compiler workers were concurrently active,
but the CPU-GPU thread did not spend material sampled time blocked on them.
That rejects “prewarm shaders” as a sufficient standalone explanation; it does
not reject a transition-time interaction between generated work and pipeline
creation.

The warm sample also attributed 793 / 12,060 samples (6.575%) to the aggregate
FIFO/gather family. Its exact mechanisms are already closed by the deterministic
GPFIFO64 and static-gather reversals, so this profile does not reopen them.

Retained trace hashes:

- warm process sample:
  `cc56a14305c85d3e7a87f8b75000688acd261dfa7b512d131e642d66193bc968`
- cold first-combat process sample:
  `8aea74a2a37f7e49657d835312edaea51765729f155fdf83f242bf9901dda214`

## Candidate

Patch 0030 caches loop-invariant lockstep, REL-module, and idle-PC state;
removes the disabled lockstep map check from every native dispatch; and makes
dispatch sampling and the old freeze trace default-off diagnostics. Explicit
environment gates preserve both diagnostics. A focused source regression and
the full repository gate pass. The candidate `Run` object grows from 4,080 to
4,348 bytes because of its startup gates, but its default hot path removes
roughly 18 instructions per native dispatch plus the disabled `ShouldCheck`
call.

## A/C/A exact-route reversal

All valid routes proved P1 Samus versus level-1 CPU Kirby, Stock/04/05:00,
Fountain slot 8, and active combat through guest-state predicates. These are
mechanism-lane routes with private input and are not product acceptance.

| Build | First 30 full combat seconds mean | Minimum | Samples below 59 | Longest continuous below 59 | Audio |
| --- | ---: | ---: | ---: | ---: | --- |
| candidate A1 | 57.79 FPS | 21.1 | 3 | 2 s | no observed delta |
| control C | 55.74 FPS | 11.7 | 7 | 5 s | no observed delta |
| candidate A2 | 57.69 FPS | 20.2 | 4 | 2 s | +1 underrun |

Candidate mean improvement is only 3.5-3.7%, below the five-percent live mean
target. Its minimum improves by 8.5-9.4 FPS and its longest bad run repeats at
two seconds instead of the control's five. This is useful but insufficient:
both candidate runs reproduce a roughly 20 FPS collapse and fail row 7.

One attempted A2 route was discarded before these results because the short
diagnostic symlink pointed one directory above the actual runtime directory.
The app rejected the override and never opened the pipe. The corrected route
used the exact runtime directory and completed normally; the discarded attempt
contributes no performance evidence.

Retained evidence hashes:

- candidate A1 console / route:
  `5b5cc73c6b52fde4950f3dd06809d6b77d7d8db659d945914e8cfcb1d0018cda` /
  `32f27f8dfdb0bb396dee017549eb10696c946be71153b1328bd8df439c7e539b`
- control C console / route:
  `bf882f48338562a8e9860496532cf11679842759e3cd6ae4c38f033a6e9a5c3e` /
  `662264ca33cd2c2f2187ddd25d0426a4520dc622d668ecfb99a3efa63f42c3e7`
- candidate A2 console / route:
  `d58025ea160a3211fcbbe1ae066fe419e2bf81997e4f5331eb806455ef650da5` /
  `bd64cd5840a1b8aa2171f6178f3a2671697e2ce9a791966c270fedd739340a88`

## Refined next experiment

1. Begin with a fresh normal installed-app reality run. Retain the moving
   opening, menu, load, and first combat minute; the 21.9 FPS anchor remains
   until an ordinary same-route run actually supersedes it.
2. On a separate exact diagnostic run, capture the fixed transition window at
   frame granularity. Correlate total/cpu/present time with static native
   dispatches, draw and primitive deltas, shader/pipeline creation deltas, and
   DMA underruns.
3. Select one outer-boundary candidate only if that aligned window assigns at
   least five percent removable time to it. Prefer eliminating synchronous
   first-use work or a repeated host lookup over broad code-size or guest-region
   changes.
4. Reverse candidate/control/candidate on the same window. A partial change can
   remain only if its tail improvement repeats and its correctness risk is low;
   it cannot change row 7 from fail while any phase remains below 59 FPS/VPS.
5. Run the full two-cold-route plus ordinary manual five-minute acceptance only
   after the focused reversal contains no failed phase.

Raw profiles, logs, imported game data, generated module output, and diagnostic
runtime paths remain private and untracked.
