# G5 warm static-core attribution

## Question

What executes during the eight combined-thread CPU overruns left in a verified
second Fountain match after the one-time cold warm-up has already completed?

## Identity correction

Patch 0024 extends the default-dormant lightweight recorder with the current
emulated-frame index. Disabled mode still performs no recorder clock read and
creates no output. Enabled mode adds one already-available integer to each
buffered record; it does not add another clock, syscall, or per-frame flush.

This closes an ambiguity in the first attempted phase join. Host timestamps
alone can slide across a delayed/catch-up pair, so that attempt is excluded.
The retained join requires the same emulated frame and then selects the nearest
common-clock record within 8 ms.

## Verified route

Two visually confirmed Fountain matches ran in one continuous native process
with the exact PGO module, single-core mode, 640x528/fullscreen, Metal, Cubeb,
quiet pipe input, one runner, and no Simulator. The warm match contains 7,431
post-boundary combat intervals after excluding the stage-load crossing row.

The detailed phase observer is intentionally enabled in this run. Therefore
its frame-rate distribution is diagnostic only and cannot pass or fail the
observer-light G5 acceptance row.

## Exact join

All 7,431 lightweight warm-match rows join one-to-one to a phase row with the
same emulated-frame identity; none are unmatched. The phase timestamp precedes
the lightweight endpoint by 1.556 ms at the median (4.714 ms maximum), which
is consistent with their two instrumentation sites.

The observer-bearing warm window averages 16.685665 ms / 59.931682 FPS and has
a 33.376166 ms worst wall interval. Exactly eight rows exceed 16.7 ms of
combined-thread CPU, matching the eight rows selected for attribution.

| Emulated frame | Light thread CPU | Phase CPU thread | Static native dispatches | Static cycles |
|---:|---:|---:|---:|---:|
| 23,072 | 18.218 ms | 18.039 ms | 454,463 | 7,204,376 |
| 23,114 | 16.749 ms | 16.360 ms | 384,176 | 6,397,715 |
| 25,661 | 16.936 ms | 16.407 ms | 136,116 | 3,919,043 |
| 25,663 | 18.004 ms | 17.534 ms | 142,114 | 4,123,089 |
| 25,664 | 17.468 ms | 17.076 ms | 140,389 | 4,054,557 |
| 27,522 | 17.009 ms | 16.629 ms | 128,042 | 3,893,104 |
| 29,131 | 17.547 ms | 17.325 ms | 120,308 | 3,526,890 |
| 29,646 | 16.884 ms | 16.358 ms | 118,174 | 3,605,983 |

Across these eight rows, phase CPU-thread time has a 16.852 ms median versus
11.591 ms for within-budget rows. Static native dispatches have a 138,253
median versus 113,306, and static cycles have a 3,986,800 median versus
3,349,872.

Video build, Metal presentation, audio mixing, EFB pipeline misses, static
fallback steps, and hook fallbacks do not increase coherently in the eight
rows. Video build is actually lower because ordinary paced rows wait for a
drawable. All eight rows have zero static fallback steps and zero EFB pipeline
misses.

## Decision

**THE EIGHT WARM CPU OVERRUNS ARE STATIC-CORE COMPUTE; G5 REMAINS OPEN.**

Do not optimize Metal, audio, EFB traffic, fallback handling, or unrelated host
processes for this class. Use the retained one-in-4,096 dispatch/frame sampler
to identify guest-PC regions enriched specifically in these same-emulated-
frame overruns. Because this trace uses the detailed observer, a later
observer-light run remains mandatory for any performance claim.

Private CSV traces, ROM data, save state, module, and screenshots are not
committed. The game and Simulator are shut down.
