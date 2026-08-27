# G5 emulated-frame shared-state verdict

## Question

Can the retained savestate signal harness produce the same active Fountain of
Dreams workload repeatedly, and does the previously rejected 64-bit gather-pipe
write become a reproducible win when control and candidate execute that exact
workload?

## Live state proof

One native arm64 runner used Pikachu against a level-1 CPU Fox on literal
Fountain of Dreams. `SIGUSR1` wrote
`/private/tmp/ssb-tail.5OWsxL/StateSaves/GALE01.s01` at 00:44:08 with SHA-256
`e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
The state is RAM-bearing local test data and is not committed.

The first post-save image showed active combat at 1:45.69, Pikachu 40%, Fox
0%. The game then visibly diverged to 1:37.79 with both at 0%. `SIGUSR2`
restored active combat at 1:47.02 with Pikachu 40% and Fox 0%. This corrects
the earlier late-save attempt: that attempt reached `Time!` because the game
continued running while the test moved from a screenshot to the save signal,
not because static-recompiler CPU state was unsynchronized.

## Why presented frames were insufficient

Two nominally equal 420-present-row replays initially had zero exact
cycle/dispatch/burst tuple matches. At 30-45 FPS, one presentation row can
cover a variable number of emulated VI fields, so presentation indices do not
define equal guest work.

Patch 0014 adds a diagnostic-only `emulated_frame` column to the existing
phase CSV. Dolphin's already-serialized `MovieManager` frame advances at VI
field boundaries. The CPU thread publishes it through one atomic and the
presentation logger samples that value; no gameplay behavior changes.

## Exact repeatability

Two control loads selected the same emulated interval `48123..48562` (440
fields). Both produced exactly:

- 3,567,157,803 guest cycles;
- 59,374,686 native dispatches;
- 905,158 static-recompiler bursts.

Their host results were 23.276326/26.202666 ms and 23.254137/25.599917 ms
mean/p95. Host scheduling varied slightly while guest work was bit-identical.

## Gather-write bracket

The distinct candidate restored only `case 8 -> GPFifo::Write64` beside the
retained gather-pipe 1/2/4-byte arms. The module and savestate were unchanged.
Each accepted warm row below has the exact control work totals above.

| Order | Build | Mean ms | FPS | p95 ms | CPU-thread mean ms |
|---|---|---:|---:|---:|---:|
| A1 | control | 23.276326 | 42.962 | 26.202666 | 22.822748 |
| A2 | control | 23.254137 | 43.003 | 25.599917 | 22.810476 |
| B cold | candidate | 23.041025 | 43.401 | 30.584583 | 22.172490 |
| B1 | candidate | 22.390803 | 44.661 | 24.597458 | 21.941602 |
| B2 | candidate | 23.311171 | 42.898 | 25.896583 | 22.490298 |
| A cold | reverse control | 21.911730 | 45.638 | 24.612500 | 21.464886 |
| A3 | reverse control | 21.458617 | 46.601 | 24.112750 | 21.054500 |
| A4 | reverse control | 22.360439 | 44.722 | 26.282750 | 21.904469 |

The fastest reverse-order control beat the fastest candidate, and the warm
ranges overlap. The candidate's apparent B1 improvement therefore follows
machine drift, not a reproducible source effect. All rows also remain far
above the strict 16.7 ms G5 ceiling.

## Decision

**Retain patch 0014; reject and remove the 64-bit gather arm; G5 remains open;
G6 remains blocked.** Future candidates must use a shared state plus an equal
emulated-frame interval and must report guest cycles, dispatches, and bursts.
Do not use equal wall time or equal presentation-row count as causal proof.

The next G5 experiment is one newly attributed compute hotspot inside this
exact shared-state window. Do not retry gather width, global MMU/locked-cache,
timer, dispatcher-budget, broad FP, or guest-PC shortcuts.

## Verification

- patch 0014 reverse-check, reverse, forward-check, and reapply pass;
- `moderngekko-run` Release rebuild passes after candidate removal;
- dependency bootstrap recognizes all patches through 0014;
- `gcpipe` passes 16/16;
- focused frontend/GameCube/netplay/memory-watcher CTest passes 4/4;
- repository safety checks pass;
- canonical signed package runner SHA-256 is
  `9d0fdf87df13593aabdc58371b2c2791a7c8910c9451af0504d3a1dd283da3c5`;
- retained module SHA-256 remains
  `2fe01870bfa0fbedc51aa20105ba0738c3b367e98c9566629001a8236e2fa1b3`;
- runner and module both declare macOS 14.0 minimum;
- no game process or Simulator remains.

## Evidence

All retained files are under
`docs/evidence/g5-shared-fountain-state/`. The three JPEGs prove save,
divergence, and restoration. CSVs 04-11 are the 440-emulated-frame control,
candidate, and reverse-control intervals. The state file itself is excluded.
