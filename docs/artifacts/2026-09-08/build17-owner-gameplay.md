# Build 17 owner gameplay and merge assessment

The owner tested the installed physical iPhone build on 2026-09-08 and reported
that it felt faster, including with four players, but still slowed down. This is
qualitative improvement feedback, not a stable-60-FPS acceptance claim.

A read-only app-container pull preserved the running game. The session starts
at 12:05:16 UTC and identifies build 17, verified USA revision 2 (v1.02), the
original 81,964,624-byte module, 1x EFB 640x528 and original 4:3. Internal
performance capture and the benchmark route are absent from the session.

The last 60 performance summaries in the pull all report iOS thermal state
`serious`; eight report under 55 FPS. Two particularly relevant samples:

| UTC | FPS | CPU thread utilization | Video thread utilization | Audio underruns, cumulative |
| --- | ---: | ---: | ---: | ---: |
| 12:27:38 | 59.9 | 57.6% | 26.3% | 778 |
| 12:27:48 | 41.4 | 92.9% | 49.8% | 804 |
| 12:27:58 | 44.9 | 85.8% | 56.0% | 824 |

The CPU worker approaches one fully occupied core during the slowdown and
underruns increase by 46 across those last two intervals. This supports the
existing CPU/thermal sensitivity diagnosis. It does not isolate a particular
game function, prove thermal throttling is the sole cause, or attribute the
entire interval to the screenshot-free scene description. The existing startup
`Failed to allocate memory space: 0x3` message also occurs in the control build;
the session continues into gameplay and it is not evidence that this change
caused the later slowdown.

## Decision

Merge the small normal-loop specialization and the default-off profiling/route
support as an incremental improvement. The changed loop preserves the original
execution body and game modules, has passing build/targeted checks, and has
physical normal-path and diagnostic-path evidence. The earlier native pair
supports lower loop overhead; neither that pair nor this user run establishes
a precise FPS improvement. Rejected private math modules are not in the PR.
No public IPA or physical online-match acceptance is implied by the merge.

## Next logging work

The ten-second FPS and utilization summaries are too coarse to explain short
stalls. Add low-overhead per-interval frame-time p95/max and missed-frame counts,
plus interval audio-underrun deltas, using the existing frame boundary. Avoid
per-dispatch CPU clocks in normal play: their measured observer cost is material.
A bounded native trace should then target a flagged slow interval in an actual
owner match. Keep this logging change separate from the already-tested build-17
merge so the merged implementation matches the physical evidence.

Private raw log SHA-256: `80c9f3c4a2e34f239e813becc40b3dd47e2121ea904a32eb23c7ba58f3589de2`.
The raw log stays under ignored `ref/revision-102/performance-loop/build17-owner/`.
