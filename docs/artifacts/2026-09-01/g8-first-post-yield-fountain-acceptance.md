# G8 first post-yield Fountain acceptance route

Date: 2026-09-01

Status: **COMBAT/RESULTS/LIFECYCLE PASS; COMPLETE ROUTE PARTIAL**

## Route identity

A fresh Release Simulator process used the repository's state-gated revision-
1.00 route. MemoryWatcher proved:

- P1 Samus;
- level-1 CPU Kirby;
- Stock/04 and 05:00;
- Fountain of Dreams; and
- live match state `0x80477D68=02020102`.

The iOS product used its ordinary stable performance configuration plus patch
0038's product-enabled caller-qualified wait yield. The short runtime-user-dir,
external pipe, MemoryWatcher, and phase logger were diagnostic-only route
instrumentation; no ROM, save, or product setting changed.

## Combat, results, return, and lifecycle

The live match began visibly at 59.9 FPS with coherent Samus and Kirby models.
Movement, jumps, A/B attacks, and direction changes ran continuously for more
than five minutes. The match completed normally to a visible Kirby-win results
screen at 59.9 FPS. Long Start input returned to Character Select with Samus
and CPU Kirby preserved at 60.0 FPS.

The final six-minute phase window contains 21,600 consecutive rows:

| Metric | Result |
| --- | ---: |
| Total mean / p95 / p99 | 16.683 / 18.031 / 18.881 ms |
| CPU-thread mean / p95 / p99 | 8.023 / 8.804 / 9.530 ms |
| Native dispatch mean / p95 | 80,905 / 85,297 |
| Charged cycles mean / p95 | 2.453M / 2.643M |
| Strict CPU-heavy slow rows | **0** |

Runtime reports hold 59.9-60.0 FPS/VPS through sustained combat and results.
DMA underruns rise from 3 to 8 during the long route rather than continuously
tracking combat load.

Simulator Home then produced `willResignActive`, save-flush grace, and
`didEnterBackground`. Foregrounding the same process produced
`willEnterForeground`, `didBecomeActive`, and speaker-audio reactivation.
Character Select remained coherent at 60.0 FPS after resume.

## Remaining transition miss

The route is not a complete row-7 pass. One ten-second interval reports 59.5
FPS / 56.7 VPS. The responsible second has two wall-heavy rows:

- 135.647 ms wall, 12.735 ms CPU thread, including 114.504 ms in the existing
  scheduler idle seam; and
- 390.990 ms wall, 18.278 ms CPU thread, with no shader/pipeline creation and
  only 0.205 ms Metal present.

Both rows request, queue, execute, and present an XFB. Guest work remains about
3.5-3.9 million cycles and 121k-133k dispatches. This is not recurrence of the
controller busy loop or a GPU workload ceiling. It is an off-core/idle or
diagnostic-host stall and recovers immediately with 61 and 63 presented rows
in the next two seconds.

The next falsifiable route is an ordinary fresh process with phase,
MemoryWatcher, and external pipe disabled. A repeat visible dip keeps row 7
failed and earns focused host-wait attribution; its absence classifies this as
diagnostic/Simulator scheduling and moves to the manual product route. Do not
change the controller-wait fix or begin another generated-code rewrite for this
single off-core event.

## Private evidence and cleanup

No phase log, runtime log, screenshot, ROM, or save is tracked.

- phase/runtime:
  `91dd620c3645dcfddcffd58dc795463381efc2ad8fa38a63a7a07777528b381d` /
  `2495ead637966175b344d3bddcd1c71c9e99b6cbff443232f4d871808c24c261`;
- combat-start/results:
  `b846d852b187e402872219eb3a65a6581e832b80fe2fa97df42cdf2441d7a730` /
  `1c7bc3b1e56f25927abd815996fe33334c47c5619dde552e7a3131baaaad0baf`.

The app was stopped, the temporary short symlink was removed, exactly one
Simulator remains booted, and the pre-test GCI was restored at SHA-256
`0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
