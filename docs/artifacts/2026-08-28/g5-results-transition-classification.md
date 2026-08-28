# G5 results-transition classification

Date: 2026-08-28

Status: **intentional guest XFB drought; not a slow rendered frame**

## Question

PERF-127 contains an approximately 400 ms displayed-surface hold at the
match/results boundary. Is that interval a renderer stall, a statically
recompiled CPU overrun, or a period in which Melee intentionally produces no
new XFB?

## Repeated natural result

Four independent runs reach the same output boundary at emulated frame 54872.
The three uninterrupted full-match runs execute exactly 211,892,535 guest
cycles, 14,356,543 native dispatches, 17,393 static bursts, 164,682 cache
controls, and 54 modeled `mtspr` fallbacks in the single aggregated phase row.
PERF-131, entered from a state saved immediately before the boundary, differs
by only 17,359 cycles, 1,651 dispatches, and five bursts before converging on
the same boundary.

| Run | total | CPU wall | CPU thread | throttle sleep |
|---|---:|---:|---:|---:|
| PERF-124 | 391.782 ms | 388.676 ms | 283.454 ms | 101.133 ms |
| PERF-126 | 446.397 ms | 443.038 ms | 314.904 ms | 147.927 ms |
| PERF-130 | 448.727 ms | 445.684 ms | 307.467 ms | 149.377 ms |
| PERF-131 | 435.032 ms | 431.951 ms | 282.475 ms | 143.880 ms |

The preceding output is emulated frame 54845. The next output is 54872: Melee
advances 27 internal VI fields without submitting a new XFB. The 81 precision
throttle calls are three timing slices per field. On-core work is approximately
10.5-11.7 ms per internal field and remains below the 16.7 ms CPU budget;
throttle sleep accounts for the remaining real time. Video build is at most
0.088 ms, `nextDrawable` is at most 0.031 ms, and presentation is at most
0.663 ms across these runs.

## PERF-131 time profile

PERF-131 loaded the retained pre-boundary state before the event and recorded
a 12-second Time Profiler trace. In the exact 420.553 ms boundary window, the
CPU-GPU thread accumulated 284 one-millisecond samples, matching its measured
282.475 ms of CPU-thread time. Static generated code owns the work; Metal does
not:

- `StaticRecompCore::Run`: 242 inclusive samples;
- `chassis_dispatch`: 167 inclusive samples;
- generated `func_80015940`: 45 leaf samples;
- generated `func_80341940`: 38 leaf samples;
- generated `func_80335940`: 22 leaf samples; and
- generated `func_80019940`: 20 leaf samples.

That profile is consistent with 27 ordinary guest fields compressed into one
output-phase row, not one field taking 435 ms. Cache-control helper and
invalidation frames are visible but remain well below one percent of sampled
CPU time, so coalescing them cannot repair the strict G5 tail.

## Decision

Do not change guest timing, synthesize duplicate XFBs, or optimize Metal for
this event. The visible hold is a deterministic guest transition with no new
frame to display. It remains a user-visible transition characteristic, but it
is excluded from the rendered-frame performance failure set.

G5 remains **FAIL** for the separate pre-results no-queue producer stalls.
Those include a 144.530 ms phase with only 19.900 ms of CPU-thread work and are
predominantly host descheduling. Continue only from a repeated producer-side
cause; do not reopen Rush Frame Presentation, drawable lifecycle, cache-control
coalescing, or the fixed 59.94-to-60 panel-conversion branch.

## Raw evidence

Local root:
`/private/tmp/ssbmpad-perf114-115-gamemode.1aRWbj/run-131-transition-profile`

- `phase.csv` SHA-256:
  `74361afd5dd36639573251a7e286a06494de914c700ede345709b0a563607da7`
- `time-profile.xml` SHA-256:
  `23a328de043c7f7a3e2b592f1861dd1393588e2b9ec7198c8604cad207267a26`
- `stderr.log` SHA-256:
  `09bdb3f2c9d1423113677d3462fe374b4ed7e64eac0e31cd5dd66ad0aa935f8c`
- private pre-boundary state SHA-256:
  `43cf5e2610d97d1e9f417929acd1302b067c7938a8b308501efbb165aabc34a5`

No disc image, extracted game data, savestate, module, app, or raw trace is
committed.
