# G8 dispatch phase alias and live-context split

Date: 2026-09-01

Status: **FIXED-PHASE REGION CORPUS REJECTED; LIVE ATTRACT CONTEXT REMAINS THE FAILURE**

## Question

Can PERF-277's five fixed one-in-4,096 regions safely select a generated-code
rewrite, and does a visibly slow attract battle remain slow after exact state
replay?

## Sampling-phase reversal

Patch 0037 was rebuilt into the Release iPad Simulator app. The same retained
four-player attract state was loaded in fresh interval-4,093 processes at
offset zero and offset 137. Both arms contain 946 active rows and nearly
identical guest work:

| Metric | Offset 0 | Offset 137 |
| --- | ---: | ---: |
| Total mean | 18.586 ms | 18.150 ms |
| CPU-thread mean | 17.291 ms | 16.686 ms |
| Guest cycles/frame | 5,882,715 | 5,882,739 |
| Native dispatches/frame | 227,762 | 227,764 |

Despite that matched work, the normalized 16 KiB region distributions have
0.062082 total-variation distance. Individual region shares move materially:
`0x803A8000` changes by 2.378 percentage points, `0x80344000` by 1.969,
`0x80018000` by 1.423, and `0x80360000` by 1.213. The one-in-4,096 result is
therefore phase-aliased. Its five-region 98.1% concentration is rejected as
architecture-selection evidence, not merely marked uncertain.

## Live failure and replay split

A bounded semantic watcher replaced the over-specific Big Blue camera hash.
The normal opening sequence later reached a visible four-player Fourside
battle at 36.2 FPS. Runtime intervals fell through 51.9 and 44.7 FPS/VPS with
the CPU thread at 98-100%, Metal present near 0.05 ms, and rising DMA
underruns.

Across 587 active rows at or above 30 ms, mean total/CPU-thread time is
36.622/33.389 ms. Mean guest work is 6.703 million cycles and 279,192 native
dispatches; p95 reaches 8.121 million cycles and 421,882 dispatches. The
longest 255-row slow cluster again concentrates fixed-phase samples in the
DVD/load, interrupt, and HSD families, but the phase reversal above prevents
using those counts as a speed projection.

The saved state does not retain the sustained failure. Both fresh replays
begin around 58-59 FPS and leave the active battle after about ten seconds,
then hold 60 FPS in a low-work scene. Replay therefore preserves guest combat
state but not all live opening/attract sequencing, asynchronous loader, or
first-pass resource context.

## Reoriented decision

Do not build the proposed five-region resident-C module. The evidence now
supports a narrower hypothesis: live opening/attract sequencing drives extra
DVD/load polling and interrupt work that is absent or already satisfied after
savestate load. The next falsifiable experiment must capture consecutive
dispatch bursts during a live CPU-saturated interval and prove a repeated
polling loop plus its exit condition. Only then preflight a cycle-preserving
fast-forward through that exact loop using `CoreTiming::Idle()` or the
corresponding scheduled-event boundary.

This is distinct from the already-closed `0x80349494` scheduler-idle rewrite.
Do not add another idle PC, skip a loop, or change disc timing from frequency
alone. Require:

1. the load/status value is unchanged across repeated iterations;
2. an external event or interrupt is the sole loop exit;
3. skipped guest cycles, timebase, interrupts, audio, and netplay timing remain
   equivalent; and
4. a same-sequence control/candidate/control removes at least 25% whole-frame
   CPU time without a visual, audio, lifecycle, or underrun regression.

If no such polling loop exists, return to a de-aliased multi-offset region
profile and the semantics-complete region-resident preflight. Row 7 remains
failed; physical-device promotion and G9 remain closed.

## Private evidence

No ROM, save, state, module, profile, screenshot, or log is tracked. Private
SHA-256 values:

- live phase / dispatch:
  `bd1e9672c93fcaceaa4dae03dfa35dd0b4765acde568d6c3f40e3618837edc6d` /
  `e7db7c1e131dbb16710725d4d9e737fb5df857268722804a20fa6c943420c512`;
- offset-zero phase / dispatch:
  `48f8a5a4b0e5fa6e73a6b2722c332525f48a3e6b23af1c468fbc1822dc8a3ae6` /
  `89e876f7fc4bf3f0692c86d8bd1592e5e9a8870318c2245acdce5251c768e7a7`;
- offset-137 phase / dispatch:
  `628da29fb85d2f2cb205fb34bce260786aa16f628c938c84ec59c696bff9791d` /
  `09f22b40f4f9d8146c7a4ab15a590ed93657a70151c15408f438662d530b8939`;
- state / visible slow screenshot:
  `aa2312ab8ac09771aa880ead0946192c5d97cd4cda749cf1eb483772ab5ecdfb` /
  `fa80a70108593d008af66981a6d9c559b13b493e2c79aea790523e4df7d36bcd`.

The app was stopped. The temporary per-game cheat was removed, Dolphin.ini
was restored byte-for-byte, the diagnostic savestate was removed from the app
container, and the ordinary GCI remains at SHA-256
`0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
