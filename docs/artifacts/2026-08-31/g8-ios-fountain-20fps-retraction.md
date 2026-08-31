# G8 iOS Fountain 20 FPS retraction

Date: 2026-08-31

Status: **G8 row 7 fail; physical-iPad promotion retracted**

## Why the prior conclusion was invalid

STABILITY-236 retained a real 22-minute single-core stability run, but its
row-7 conclusion relied on long flat-underrun spans and the final 59.9 FPS/VPS
interval from a mixed sequence. It did not report the minimum and complete
distribution for a fixed first-run boot-to-Fountain path. That allowed fast
idle/menu intervals and later recovery to hide severe gameplay slowdown.

The user's first manual Simulator run supplied the missing direct evidence. A
visible Fountain of Dreams match showed **21.9 FPS**. This is gameplay, not a
menu movie or a counter-only artifact.

## Matching runtime evidence

The screenshot was taken at 03:29:50 local time. Its surrounding UTC runtime
rows are the same scene and process:

| UTC | FPS | VPS | Speed | CPU-GPU | DMA underruns |
|---|---:|---:|---:|---:|---:|
| 08:29:43 | 26.9 | 26.8 | 0.423 | 74.1% | 1,071 |
| 08:29:53 | 22.7 | 22.3 | 0.336 | 71.7% | 1,128 |
| 08:30:03 | 21.5 | 21.5 | 0.364 | 74.4% | 1,194 |
| 08:30:13 | 24.0 | 24.1 | 0.408 | 53.8% | 1,240 |

The preceding route had already fallen through 42.2/42.3, 34.0/33.7,
20.2/19.8, and other low FPS/VPS intervals. Because FPS and VPS fall together
and the underrun counter rises continuously, this is a sustained producer and
audio-continuity failure. It is not the separate case where FPS falls but VPS
holds 59.9.

The user screenshot is SHA-256
`71d6f2db5ddb183db45faebe1de03be7034a3fb5efd0921127d71a1bc93be99e`
(1,407,896 bytes). It remains user-supplied evidence and is not copied into
the repository.

## Exact sampled span

An eight-second `sample` captured the same process while the matching runtime
rows held 21.5-24.1 FPS/VPS. On the CPU-GPU thread:

- 1,756 / 2,604 samples were inside `StaticRecompCore::Run` (67.4%);
- 1,648 / 2,604 were below generated `chassis_dispatch` (63.3%);
- the distribution was broad across generated functions; the largest single
  generated bucket, `func_8035D940`, had 143 samples (5.5% of the thread);
- no narrow shader-creation or vertex-loader family explains the sustained
  interval.

This re-establishes the generated static-recompiler path as the current broad
cost center. It does not yet identify a safe source correction.

## Decision

- Reopen G8 row 7 as **Fail**.
- Retract the statement that the current build is a physical-iPad test
  candidate. It is not currently playable in the Simulator.
- Preserve single-core CPU/video execution; the dual-core alternative already
  has a causal malformed-FIFO crash and must not be restored.
- Use the refined row-7 protocol in `docs/GOAL-LOOP.md`: two fresh processes,
  complete boot-to-Fountain routes, every interval retained, and minimum FPS,
  VPS, speed, callbacks, and underrun behavior judged together.
- A later 59.9 interval cannot override an earlier failed interval.

## Next experiment

Symbolize and compare the exact low-FPS sample against a 59.9-FPS interval
from the same build and scene family. Select only a source mechanism with at
least five-percent differential coverage, add a fail-first regression, and
reverse it on the same fresh-process route. Do not spend another full replay
on shader persistence, buffer growth, stale profiles, unsafe dual-core, or a
best/final-interval-only claim.
