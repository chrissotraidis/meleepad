# G5 menu idle-loop experiments

Date: 2026-08-26

## Question

The user reported major animated-menu slowdowns. A fresh normal-runner combat
sample also placed Melee's scheduler poll `loop_80349494` at the top of the
CPU thread. Can the exact generated idle branch be shortened without changing
guest timing, and does doing so improve the strict menu distribution?

## Matched normal menu control

MemoryWatcher started before the signed normal runner and gated the cold route
through the genuine title lockout to `GameState=0x02020100`. The retained
visual shows a coherent character-select screen. The 1,197-frame, capture-free
20-second bracket used CSV data rows 8,647 through 9,843.

| Metric | Normal CSS control |
|---|---:|
| Mean / median | 16.683499 / 16.679584 ms |
| p95 / p99 / worst | 16.896375 / 17.084541 / 17.467959 ms |
| FPS from mean | 59.939 |
| Frames <=16.7 ms | 56.976% |
| CPU-thread mean / p95 | 8.463245 / 9.485554 ms |
| Throttle sleep mean / p95 | 8.605240 / 9.059332 ms |
| Throttle lateness mean / p95 | 0.069926 / 0.127846 ms |
| Guest cycles mean | 8,107,218.730 |
| Native dispatches mean | 67,051.812 |

The external 10-second sample put 3,883 samples in the active native core;
`loop_80349494` accounted for 1,839 samples. The menu can therefore average
59.94 FPS while still failing the strict p95 gate and spending almost half of
active native-core time in this poll. The slowdown is intermittent rather than
a permanent half-rate menu mode.

## Candidate 1: immediate exact-idle return

The first local generated-source experiment returned after the first taken
poll at `0x80349494`, charging only the poll's three guest cycles. It was
visually rejected during the opening movie at about 28-31 FPS. Its trimmed
2,713-row phase interval measured 34.954762 ms mean / 42.394250 ms p95,
28.608 FPS, and 34.705388 ms mean CPU-thread time. It also expanded native
dispatches to 1,465,629/frame. Returning without preserving the loop's normal
cycle charge changes scheduling semantics and is not valid.

## Candidate 2: cycle-preserving poll collapse

The second experiment performed one RAM read, then advanced generated
`downcount` by the exact number of three-cycle iterations needed to cross the
unchanged 256-cycle C-loop budget. It returned at the same idle PC, so the
existing `CoreTiming::Idle()` path received the same approximately 258-cycle
charge. The cold watcher route reached the same coherent CSS screen at normal
speed.

The mechanism worked:

- guest cycles remained matched at 8,107,192/frame in bracket 1 and
  8,107,206/frame in bracket 2;
- CPU-thread mean fell to 5.603357 ms and 5.480814 ms;
- the external sample reduced `loop_80349494` from 1,839 samples to 34.

But the complete distribution regressed twice:

| Metric | Candidate bracket 1 | Candidate bracket 2 |
|---|---:|---:|
| Frames | 1,184 | 1,176 |
| Mean | 16.684482 ms | 16.684907 ms |
| p95 | 18.479250 ms | 18.468458 ms |
| p99 | 19.431875 ms | 19.729708 ms |
| Worst | 21.633667 ms | 53.302416 ms |
| FPS from mean | 59.936 | 59.934 |
| Frames <=16.7 ms | 54.223% | 54.082% |
| CPU-thread mean | 5.603357 ms | 5.480814 ms |
| Throttle sleep mean | 11.339016 ms | 11.387828 ms |
| Throttle lateness mean / p95 | 0.374787 / 0.558056 ms | 0.407461 / 0.556347 ms |

Removing about 2.9 ms of CPU work lengthened the precision timer's host sleep
and exposed much larger wake lateness. The gain is real compute headroom, but
the repeated p95 regression makes the standalone shortcut ineligible.

## Decision and next experiment

**BOTH CANDIDATES REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.**
The generated source, signed runner, and packaged module were restored. Normal
runner SHA-256 is `c26625db7fd1eb504f418ad8ab52a3accc61bb222fd08b369c7804a5465d5598`;
the corrected module is `2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.
No runtime or Simulator remains.

Do not canonicalize either generated shortcut and do not retry a global loop
budget. The next single experiment is a host-only preflight for chunking long
Apple precision sleeps before the existing 1.02 ms final-yield window. This is
newly justified by the matched increase from 0.070 to 0.375-0.407 ms mean wake
lateness when idle-loop compute was removed. Only if that preflight improves
long-sleep lateness without adding sustained busy work should it be combined
locally with the cycle-preserving shortcut and re-run on the matched CSS gate.
Combat and canonical code generation remain downstream of that menu result.

## Retained artifacts

- `g5-normal-css-menu-phase.csv` — SHA-256 `4a8cab375d1204635e04090612a2cdfcdbdcd77e3c3af6ccaef1377653e924fb`
- `g5-normal-css-menu.jpeg` — SHA-256 `c1dabdda8d4e11c453519cb402dc2ef3faec2d1f46928bd091a71100aa20de94`
- `g5-normal-css-menu.sample.txt` — SHA-256 `0cd1f8f22cf5dba6fc595ee3564297af95189dbd75763a8192358f03edf18a56`
- `g5-exact-idle-return-intro-phase.csv` — SHA-256 `1b113da85ba8821bc8a8a252746b6a97112705165b63a69d380a3e47f02ef520`
- `g5-cycle-preserving-idle-css-phase.csv` — SHA-256 `dc4797787ab272521ef20883f66670e7bb4df35e5a91d9bc08d0aa39a61a83a3`
- `g5-cycle-preserving-idle-css.jpeg` — SHA-256 `fb48d7f11b43dd7b3bd2873e67ab748d753fc659bcca39ace8ce5389dafc1a65`
- `g5-cycle-preserving-idle-css.sample.txt` — SHA-256 `8c889308cbbdc58ba78bb63108254b3329310d651bbeffd511158d4c08e39e9a`
- `g5-cycle-preserving-idle-cold-start.sample.txt` — SHA-256 `621363cd29966dd075e8bf44eba0e2d85e95e162e74efde7144b13f6668272c7`
