# G5 CSS frame-boundary attribution

Date: 2026-08-26

## Question

The normal character-select control averages 59.94 FPS but repeatedly misses
the strict 16.7 ms p95 gate. Idle-poll and timer experiments changed compute
headroom and wake lateness without removing the residual tail. Is that tail
caused by CPU-slice aggregation, throttle timing, `SyncGPU`, the asynchronous
video request queue, or presentation?

## Diagnostic method

All runs used the restored normal generated module
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.
MemoryWatcher started before exactly one runner and gated the cold route through
the genuine title lockout to coherent CSS. No Simulator ran.

Temporary, phase-log-only fields identified:

- unique emulated frame, present count/reason, and emulated timestamp;
- CPU slice and throttle-call counts per presented row;
- the last CPU throttle target/end relative to presenter start;
- CPU VI-output start, `SyncGPU` completion/enqueue, video-thread service, and
  actual-present boundaries.

The diagnostics were compiled and observed at runtime, then removed. They do
not change the packaged normal path or the canonical patch stack.

## Stable frame identity

The first 1,806-row CSS bracket measured 16.683471 ms mean / 16.918834 ms p95
/ 17.272916 ms p99 / 20.419583 ms worst, or 59.940 FPS.

Every retained row was a unique `VideoInterface` frame. `present_frame` and the
emulated timestamp advanced exactly once; present count advanced by two because
`ViSwap` and `Present` each increment the presenter's counter. Each row had two
CPU throttle calls and normally 607-614 CPU slices. Tail slice count was flat:
611.344/body versus 611.370/tail.

Reconstructed target cadence was exact:

| Boundary | Mean interval | p95 interval |
|---|---:|---:|
| Intended presentation | 16.683333 ms | 16.683334 ms |
| Last CPU throttle target | 16.683333 ms | 16.683334 ms |
| Presenter start | 16.683542 ms | 16.918834 ms |
| Actual presentation | 16.683565 ms | 16.925375 ms |

The target is stable; variance begins before the presenter starts.

## Queue and SyncGPU exclusion

The matched 1,799-row queue bracket measured 16.683362 ms mean / 16.926208 ms
p95 / 17.170542 ms p99 / 18.902834 ms worst. The video request queue took
0.029525 ms in body rows and 0.031929 ms in tail rows. Its correlation with
frame time was only 0.104. The CPU was already 1.108296 ms late on average
relative to intended presentation when it enqueued the swap; p95 was
1.371027 ms and worst was 3.519319 ms.

The final 1,810-row SyncGPU bracket measured 16.683298 ms mean / 16.912416 ms
p95 / 17.132292 ms p99 / 20.290708 ms worst. `SyncGPU` was effectively zero:
0.000079 ms in body rows and 0.000105 ms in tail rows. CPU VI-output start was
already 1.092437 ms after the intended target on average, 1.313250 ms at p95,
and 5.381333 ms worst.

The chain is therefore:

`exact throttle target -> variable CPU work -> VI output -> ~0 SyncGPU ->
~0.03 ms queue/service -> present`

In the SyncGPU bracket, wall time correlated 0.995 with total frame time.
CPU-thread work rose from 8.376825 ms/body to 9.057941 ms/tail while throttle
sleep fell from 8.665221 to 8.362006 ms and lateness did not rise. The wall
interval from the last throttle end to VI output was 2.451662 ms/body versus
3.175881 ms/tail. This is an on-CPU guest/runtime tail, not Metal, `SyncGPU`,
queue service, or timer wake lateness.

## CSS-only post-throttle PC sample

The existing one-in-4096 dispatch sampler was temporarily tagged only while
both conditions were true: the CPU was after throttle completion/before VI
output, and watched `GameState` was CSS. The opening path therefore contributed
zero post-throttle samples. A coherent, untouched 45-second CSS interval
ranked:

| PC | Samples | Meaning |
|---|---:|---|
| `0x80349494` | 12,895 | known scheduler idle poll |
| `0x80345738` | 3,121 | tiny leaf that clears MSR.EE and returns old EE (`OSDisableInterrupts`) |
| `0x80345760` | 3,118 | tiny leaf that restores MSR.EE (`OSRestoreInterrupts`) |
| `0x8001956c` | 1,345 | generated game/runtime site |
| `0x800191c0` | 1,326 | generated game/runtime site |
| `0x8001cc04` | 1,316 | generated game/runtime site |

The idle poll remains the largest compute consumer, but its cycle-preserving
collapse already failed to improve the complete p95 distribution. The next
independent removable boundary is the matched interrupt leaf pair: both are
only a handful of instructions yet each requires a native module round trip.

## Decision and next experiment

**ATTRIBUTION RETAINED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.** No
behavior candidate was retained. The normal signed runner
`c26625db7fd1eb504f418ad8ab52a3accc61bb222fd08b369c7804a5465d5598`
and corrected module `2dce1352...` are restored; no runtime or Simulator
remains.

Do not retry timer, sleep, global loop-budget, queue, SyncGPU, or Metal changes.
The next single local experiment is exact module-level coalescing of only
`0x80345738` and `0x80345760` with their generated cycle/MSR/register semantics,
so their caller continuation executes in the same module entry. Start with a
focused semantic test that fails before coalescing. Retain only if the CSS-only
sample loses both leaf PCs and a matched normal CSS distribution improves.
Do not combine this experiment with the rejected idle collapse.

## Retained artifacts

- `g5-boundary-css-phase.csv` — SHA-256 `b972e16c6c2d4292f4f26c5d7b487886836c2ae91158803b8051db84faf56dad`
- `g5-boundary-css.jpeg` — SHA-256 `7c98fb453faff0c70f8c6c3106806acda85438dcec5b2331acb87f66887ff78a`
- `g5-queue-boundary-css-phase.csv` — SHA-256 `a8c07f9dbf687882e85cc35491fadc2848ed3726b7824e10bccfc3e3762ff35d`
- `g5-queue-boundary-css.jpeg` — SHA-256 `28b33fbbfeda27a2768a31f7a8244d41b28b5d32d6fab92baa85e9ed74f119ae`
- `g5-sync-boundary-css-phase.csv` — SHA-256 `444fa12f2a097276221ec7724a8a386df4a83a808315fdbcd0d709e4877f674d`
- `g5-sync-boundary-css.jpeg` — SHA-256 `01d243e66b98e0660cb2169516a1d32a6ee42ab19f044868a14f8a1dfaa7cfaf`
- `g5-css-post-throttle-sites-phase.csv` — SHA-256 `e216d4ff1bdfcedf7b19bc5c30aeef7c4e84beacd9529ed34e97438a00b13e0b`
