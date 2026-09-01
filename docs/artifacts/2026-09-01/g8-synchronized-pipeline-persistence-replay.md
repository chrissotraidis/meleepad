# PERF-263 — synchronized pipeline-persistence replay

Date: 2026-09-01

Status: **known-pipeline persistence reverses the prior combat hitch; route still fails**

## Question

PERF-262 found a 91.782 ms active-combat frame containing a first-use Metal
pipeline creation. Does Dolphin's existing per-game pipeline UID cache remove
that class on a fresh process using the unchanged synchronized CPU/video
candidate and the same installed user data?

## Reversal

The unchanged Release executable SHA-256 was
`5d0965325ebaed5749d44cba790f5b8089ebab6c5d6dec6bf18c748e6d29bcec`.
Before launch, the normal user directory contained the persisted
`Cache/GALE01.uidcache` written during the preceding exact match. The app then
started as a fresh process and completed the same state-verified P1 Samus,
level-1 CPU Kirby, Stock/04/05:00 Fountain route.

The replay passed the exact emulated-frame location of the prior 91.782 ms
pipeline hitch without any active-combat frame above 50 ms. Across 6,301
consecutive emulated frames 3500 through 9800:

- mean was 16.707134 ms;
- p95 was 17.593500 ms;
- p99 was 19.172209 ms;
- worst was 36.328459 ms;
- 78.114585% met the 16.95 ms diagnostic budget.

Runtime intervals mostly reported 59.8-60.0 FPS/VPS at approximately real-time
speed. This reverses the prior first-use pipeline hitch but does not meet the
row-7 p95, p99, or every-moving-phase boundary. A later 82.636 ms frame had
zero pipeline creation and occurred in the match/results presentation class,
not the prior active-combat pipeline class.

## What this changes

The Metal backend does not expose durable driver pipeline-cache data on this
path. Dolphin instead persists serialized game-specific GX pipeline UIDs,
loads them on the next process, queues every known missing pipeline, and—under
the current product defaults—waits for those known pipelines before starting.
The replay therefore demonstrates that the existing UID persistence mechanism
works. It also explains why it cannot protect the very first route from a UID
that has never yet been observed.

Do not add another player-facing performance mode. Before considering a seed,
prove that the UID data is ROM-safe, version-gated by
`GX_PIPELINE_UID_VERSION`, deterministic for the pinned graphics configuration,
and invalidated safely. A seed candidate must improve a clean user directory,
not merely a warm replay, and must not package the ROM, module, saves, profiles,
or private paths.

## Independent failures retained

The fresh-process route still showed severe cold/front-end and transition
intervals, including moving values in the 30s and a later results presentation
around 19 FPS. The retained results frame also makes clear that visual
correctness is not ready for promotion, while the known malformed Fountain
reflection remains open. These classes must be judged separately from the
pipeline reversal.

Private evidence hashes:

- phase CSV:
  `761c56d92a3f5ef7ce86e9723db96c6a684f0b3712feb063abcdc8c21108c58c`;
- spike marker:
  `ce29096d7d7c03f64f3847b6bb60ab0503986ec5ae23acaf62181f9f14db572d`;
- post-combat screenshot:
  `2addc68902d9f5afa0489b87022a6891d34adba34392984b38b92b4b702571fd`.

## Decision

Keep synchronized dual-core unmerged. Pipeline UID persistence is a validated
part of the solution, not a complete solution. Next audit a safe deterministic
first-install seed path and, independently, attribute the 36 ms CPU-heavy
combat cluster and the moving front-end/results deficits. Rendering corruption
must be repaired before any acceptance run. Row 7 remains failed, physical-iPad
promotion remains closed, and G9 netplay remains queued.

The app was stopped, the single Simulator remained booted, and every diagnostic
environment variable was cleared. Private caches and all game data remain
untracked.
