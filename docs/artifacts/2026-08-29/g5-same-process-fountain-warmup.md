# G5 same-process Fountain warm-up comparison

Date: 2026-08-29

Status: **MOST COLD COMPUTE OVERRUNS ARE ONE-TIME WARM-UP; WARM MATCH STILL FAILS G5**

## Question

Does PERF-193's first-ten-second combined-thread CPU burst disappear when a
second Fountain match runs in the same process with all process, module,
shader, and game caches retained?

## Invalid first comparison

An initial two-match diagnostic is excluded from the stage-specific decision.
It retained both timing windows correctly, but the relative stage-navigation
sequence was not visually checked before match two. Its recurrence result is
not relabeled as Fountain evidence.

## Verified same-process comparison

The accepted repeat used one continuous signed app process with:

- runner SHA-256
  `2133657a30d7ea7a484120a225b7b9a11c2bed64c821b455f9ecc744217a194e`;
- unchanged current-PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- `CPUThread = False`, native 640x528 scale, fullscreen Metal, configured
  Cubeb audio, and EFB prewarm;
- one pre-created private FIFO and MemoryWatcher location set;
- quiet controller output redirected to `/dev/null`;
- no Simulator.

Fresh visual checks explicitly showed Fountain highlighted before both match
starts. The process remained alive through match one, results, return to CSS,
and match two. Match two retained Pikachu and the same CPU opponent selection;
no source, module, product config, or unrelated process changed between legs.

Watcher-gated boundaries:

| Leg | Start Unix ns | End Unix ns | Combat-only recorder rows |
| --- | ---: | ---: | ---: |
| Match 1, cold | 1788055878586808000 | 1788056004403285000 | 7,779-15,209 (7,431) |
| Match 2, warm | 1788056124391667000 | 1788056250301533000 | 22,092-29,521 (7,430) |

Each leg excludes its first selected interval because that interval began
before the watcher boundary and crossed stage loading: 1,880.718750 ms for
match one and 2,062.276792 ms for match two.

The private two-match recorder CSV has SHA-256
`0ecd0010dc5d495b1f3a95592a505d3db0fa3fb2a322f6c44c152d53d90625c5`.
The independent private render log has SHA-256
`9cb0fde04af361669c7fe5365d98f445e450117d27ef5f85a99c7d29276c6652`.
Their 30,258 common lifecycle intervals match exactly at the recorder-to-
render +1 row offset. The unmatched first/last lifecycle rows are outside the
two selected combat windows. No private timing file, screenshot, save, or game
data is committed.

## Exact results

| Metric | Match 1, cold | Match 2, same-process warm |
| --- | ---: | ---: |
| Wall mean | 16.680840 ms | 16.670874 ms |
| FPS from mean | 59.949019 | 59.984858 |
| Wall p95 | 16.896521 ms | 16.863511 ms |
| Wall p99 | 17.282896 ms | 17.061000 ms |
| Wall worst | 30.972167 ms | 29.475375 ms |
| Wall <=16.7 ms | 4,712/7,431 (63.410039%) | 4,794/7,430 (64.522207%) |
| Wall >20 ms | 12 | 3 |
| Combined-thread CPU p95 | 15.423541 ms | 13.487680 ms |
| Combined-thread CPU p99 | 16.968863 ms | 14.694877 ms |
| Combined-thread CPU worst | 21.992667 ms | 18.309959 ms |
| Combined-thread CPU >16.7 ms | 105 | 8 |
| Wall-minus-thread worst | 17.256459 ms | 15.100374 ms |

The first ten seconds isolate the warm-up mechanism:

| First-ten-second result | Match 1, cold | Match 2, warm |
| --- | ---: | ---: |
| Selected rows | 597 | 601 |
| Wall >16.7 ms | 221 | 168 |
| Wall >20 ms | 10 | 1 |
| Thread CPU >16.7 ms | 104 | 2 |
| Worst wall | 23.580250 ms | 23.034125 ms |
| Worst thread CPU | 21.992667 ms | 18.309959 ms |

Match one has one additional CPU overrun after ten seconds; match two has six.
The warm match's 29.475375 ms worst interval uses 14.444000 ms of thread CPU
and loses 15.031375 ms outside that thread. Its worst thread-CPU interval is
the 23.034125 ms opening wall row, with 18.309959 ms CPU.

## Decision

The same-process reversal reduces combined-thread CPU overruns from 105 to
eight and first-ten-second overruns from 104 to two. **Most of the cold match
compute burst is one-time warm-up.** It is not valid to classify the entire
cold burst as recurring static-recompiled gameplay cost.

The warm match still fails G5: `29.475375 > 16.7` ms, only 64.522207% of rows
meet the budget, eight intervals compute past the budget, and a separate wall-
only tail remains. G6 and Final Destination stay blocked.

The next smallest causal experiment is to enable the already-retained phase
logger only for a verified same-process warm match and join its eight CPU
overruns to dispatch, GPU, audio, wait, and shader phases. That identifies
what must be prewarmed or optimized without reopening rejected scheduler or
presentation changes.
