# G8 row-7 exact-combat dispatch subtraction

Date: 2026-08-31

Status: **PERF-255 GUEST-REGION CANDIDATE REJECTED; ROW 7 REMAINS FAILED**

## Controlling product result

The user's normal first Simulator route visibly reports 21.9 FPS in P1 Samus
versus level-1 CPU Kirby, Stock/04/05:00, on Fountain of Dreams. Matching
runtime evidence reaches 20.2 FPS / 19.8 VPS with increasing audio underruns.
That ordinary visible result remains the product floor. The measurement below
can select or reject a mechanism; it cannot replace the failed manual run.

## Question and method

Does the exact slow combat route concentrate dispatches in a bounded guest PC
or region that could justify another generated-code specialization?

The built-in one-in-4,096 native-dispatch sampler was enabled on two fresh
exact routes using the same installed binary and route harness. The shorter
run stopped through the product core's normal stop method immediately after
the route's first combat wait. The longer run used the same route and retained
about 30 additional seconds of active combat before the same graceful stop.

The CSV frame field remained zero for every row, so frame-index isolation is
invalid and is explicitly rejected. Instead, this preflight subtracts the
short whole-PC histogram from the long histogram. Raw logs and traces remain
private and untracked. Their retained hashes were:

- long CSV: `8d7ae4b7148e226e6f8c76292515a285e488963d510aff93924af97ed64c6e64`
- short CSV: `a5fe352cb04cefd69d8ebe835bdd8388e435a771168a1e5074b712c053567bb9`
- long console: `f3d6b83f8f2c7441ee68b5eb64a13eacab1765a8ddef2ce0146aac49fd1ce203`
- short console: `0ef5a35e1b853fa7caa4862eb533ae541c45eb25214cd558d20e75c5b26f655`

## Arithmetic check

| Counter | Short | Long | Added combat |
| --- | ---: | ---: | ---: |
| native dispatches | 1,107,088,852 | 1,368,310,134 | 261,221,282 |
| sampled rows | 270,286 | 334,061 | 63,775 |
| fallbacks | 3,033,347 | 3,963,371 | 930,024 |
| native exceptions | 91,821 | 120,619 | 28,798 |
| hook fallbacks | 15,956 | 18,420 | 2,464 |
| bursts | 5,527,244 | 8,315,961 | 2,788,717 |
| emulated cycles | 18,265,833,439 | 24,141,918,445 | 5,876,085,006 |

The 261,221,282 added native dispatches predict 63,774.727 one-in-4,096
samples. The observed delta is 63,775. This closes the gross arithmetic even
though normal route-to-route variability produces 1,389 negative and 65,164
positive per-PC sample deltas.

## Distribution

The largest individual positive deltas are:

| Guest PC | Samples | Share of net delta |
| --- | ---: | ---: |
| `80345738` | 3,496 | 5.482% |
| `80345760` | 3,461 | 5.427% |
| `8001cc04` | 1,230 | 1.929% |
| `800191c0` | 1,204 | 1.888% |
| `8001956c` | 1,118 | 1.753% |
| `803382ac` | 1,084 | 1.700% |

The paired interrupt leaves at `80345738` and `80345760` total 10.909%. Their
coalescing was already measured and rejected because it removed only about 51
dispatches per frame with no CPU or p95 improvement.

The leading signed 16 KiB regions are also distributed:

| Region | Samples | Share |
| --- | ---: | ---: |
| `80018000` | 8,375 | 13.132% |
| `80344000` | 6,967 | 10.924% |
| `80338000` | 6,397 | 10.031% |
| `80360000` | 6,286 | 9.857% |
| `8033c000` | 5,332 | 8.361% |
| `8036c000` | 4,970 | 7.793% |
| `8035c000` | 4,780 | 7.495% |

No individual PC exceeds 5.49% and no region exceeds 13.14%. Exact generated
source and prior retained experiments map the leaders to already-closed
families: interrupt leaves, DVD/error/timing work, and HSD/GX/matrix work.
Coarse revision-1.02 symbol names are not used where they disagree with the
revision-1.00 generated source.

The added window contains only 2,464 hook fallbacks and 930,024 total
fallbacks against 261.2 million native dispatches. This exact current-source
route therefore also rejects reopening the narrow `mtspr` proposal. Its result
does not erase the older cache-fallback correction; it shows that the retained
current source no longer has that old dominant hook-fallback volume.

## Decision

Reject another region-specific generated-code, direct-call, interrupt, DVD,
or HSD/GX rewrite before a product build. The exact workload is broad and its
largest families have already failed measured live or structural gates.

The next experiment moves outward to an exact-workload host profile. Measure
the remaining per-dispatch ladder as a batch—lookup/checking, state sync,
exception/fallback handling, sampling/diagnostics, and slice bookkeeping—and
perform a no-build materiality screen. A source candidate must expose at least
five percent removable measured cost while preserving correctness. Ordinary
cold/manual visible performance remains the final authority.

After the run, the app was stopped, all diagnostic Simulator environment
variables were unset, private trace material was moved to Trash, and exactly
one iPad Simulator remained booted.
