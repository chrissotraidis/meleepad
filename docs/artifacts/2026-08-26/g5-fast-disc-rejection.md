# G5 fast-disc rejection

## Question

Do Dolphin's existing fast-disc semantics remove the multi-second menu/scene
transition gaps without changing behavior or worsening Fountain pacing?

## Isolation and route

`FastDiscSpeed = True` was added only to the temporary diagnostic app's
GALE01r0 game-settings layer. The normal user configuration, signed product
app, module, ROM/extracted game, and saves were not modified. MemoryWatcher
was armed before the valid cold boot. Computer Use verified coherent CSS,
P1 Pikachu, level-1 CPU Donkey Kong, the literal Fountain of Dreams label,
live combat, and Cubeb audio.

The first attempted isolated-user-directory setups were excluded before any
measurement because their controller FIFO had not been present at backend
startup. The accepted run used the already verified standard controller pipe
and only the temporary game-settings layer differed.

## Result

Fast-disc did not remove the long rows:

| Frame | Total | CPU wall | Present | Native dispatches |
|---:|---:|---:|---:|---:|
| 6,129 | 3,234.531 ms | 3,213.694 ms | 0.021 ms | 77,044,921 |
| 7,351 | 2,687.531 ms | 2,670.290 ms | 0.029 ms | 62,094,378 |
| 7,907 | 3,020.678 ms | 3,001.406 ms | 0.019 ms | 93,477,335 |
| 12,516 | 1,854.030 ms | 1,842.095 ms | 0.044 ms | 54,109,504 |

These rows contain approximately 111-193 ordinary frames' worth of charged
guest cycles and 35-74 frames' worth of requested throttle time. They are
presentation-log aggregation across scene changes, not evidence that an
animated menu continuously renders at 12-15 FPS. Their negligible Metal
present time and unchanged `lbDvd`/`DVDCancel` samples remain useful
classification, but fast-disc does not improve them.

The first 2,500 complete live-combat rows after the visually verified
Fountain gate measured:

- p50: 16.671104 ms
- p95: 17.826824 ms
- ordinary samples: 31.218/frame
- tail samples: 33.032/frame

This does not pass G5 and is not materially better than PERF-033's
17.881404 ms p95. Tail deltas map broadly across HSD matrix/material/animation
work and GX state setters rather than a disc path.

## Decision

**FAST-DISC REJECTED AND REMOVED; G5 OPEN; FINAL DESTINATION NOT RUN; G6
BLOCKED.** The temporary app was restored and re-signed, the isolated user
directory was moved to Trash, the runtime exited cleanly, and no Simulator was
booted.

Next: preflight a coherent reduction in HSD/GX cross-segment dispatch
boundaries while retaining SMC verification, exceptions, host-call ordering,
guest cycle accounting, and bounded event delivery. Do not optimize the
aggregated DVD rows or retry isolated leaves.
