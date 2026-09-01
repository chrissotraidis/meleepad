# PERF-263 — synchronized pipeline-persistence replay

Date: 2026-09-01

Status: **persistence attribution refuted by format validation; route still fails**

## Question

PERF-262 found a 91.782 ms active-combat frame containing a first-use Metal
pipeline creation. A fresh-process replay did not reproduce that frame. Did a
valid Dolphin per-game pipeline UID cache cause the reversal?

## Reversal

The unchanged Release executable SHA-256 was
`5d0965325ebaed5749d44cba790f5b8089ebab6c5d6dec6bf18c748e6d29bcec`.
Before launch, the normal user directory appeared to contain a persisted
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
speed. The observation does not meet the row-7 p95, p99, or every-moving-phase
boundary. A later 82.636 ms frame had zero pipeline creation and occurred in
the match/results presentation class, not the prior active-combat pipeline
class.

## Attribution correction

Post-run source and binary-format validation refutes the initial persistence
attribution. The pinned `SerializedGXPipelineUid` is a packed, compiler/platform
independent 579-byte record. A valid file is therefore exactly 8 header bytes
plus an integral number of 579-byte entries. The presumed seed was 151,552
bytes: its 151,544-byte payload leaves a 425-byte remainder. The current
4,096-byte file similarly leaves a 35-byte remainder. Dolphin's loader rejects
and truncates such files; it cannot have loaded the presumed seed.

The non-recurrence may instead be run-to-run variance or an external Metal
compiler/driver cache. It is not evidence that Dolphin UID persistence caused
the improvement. This correction supersedes the earlier conclusion in this
artifact and the same-day loop/status/journal wording.

The source still establishes a viable mechanism to test: valid UID files use
magic `PUID`, version 8, compiler/platform-independent entries, queue all known
pipelines, and—under current defaults—wait before starting. That mechanism now
requires a valid-cache versus no-cache reversal on isolated user roots.

Do not add another player-facing performance mode. Before considering a seed,
first prove that a valid UID file causes a cold-route improvement. Any later
seed must also be ROM-safe, version-gated by `GX_PIPELINE_UID_VERSION`,
deterministic for the pinned graphics configuration, and invalidated safely.
It must not package the ROM, module, saves, profiles, or private paths.

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

Keep synchronized dual-core unmerged. Do not implement or ship a seed yet.
Next reverse one structurally valid pipeline UID cache against an empty cache
on isolated user roots and the same exact route. Independently attribute the
36 ms CPU-heavy combat cluster and the moving front-end/results deficits.
Rendering corruption must be repaired before any acceptance run. Row 7 remains
failed, physical-iPad promotion remains closed, and G9 netplay remains queued.

The app was stopped, the single Simulator remained booted, and every diagnostic
environment variable was cleared. Private caches and all game data remain
untracked.
