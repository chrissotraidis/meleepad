# G5 warm dispatch-region rejection

Date: 2026-08-29

Status: **EXACT WARM REGION RESOLVED TO ALREADY-CLOSED HSD/GX FAMILY; NO PRODUCT CHANGE; G5 OPEN**

## Question

Do the remaining warm Fountain combined-thread CPU overruns concentrate in a
new guest-PC region that can support a bounded static-recompiler optimization?

## Corrected harness

Three setup attempts are excluded. The first two omitted the FIFO that
Dolphin's pipe backend scans at initialization; the third filled the private
temporary volume while copying a savestate. Their traces and cloned user trees
were removed. The valid route creates the FIFO before boot, keeps one quiet
writer open, and redirects scripted input output away from the live terminal.

One signed native process used exact runner
`472ccfc2527b1690f6518117c98733fd0de8df1015b7b18ba9d28b400cd6f5c2`
and PGO module
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`
in single-core, 640x528/fullscreen, Metal/Cubeb configuration. No Simulator or
unrelated process was used.

Two visually confirmed canonical Fountain savestate legs ran in that one
continuous process. The second load produces an unambiguous emulated-frame
reset at lightweight row 10,842. A conservative 6,650-row body from emulated
frames 48,064 through 54,713 ends before the visually observed results flow.

The detailed phase observer and dispatch sampler are enabled, so this is
mechanism evidence only. Its wall distribution cannot satisfy G5 acceptance.

## Exact warm join

All 6,650 lightweight rows join one-to-one to phase rows using exact emulated
frame plus nearest common-clock timestamp. Dispatch samples use the exact phase
`frame` value: offset zero has 0.292 median absolute sample-count error against
`static_native_dispatches / 4096`, while offsets -1 and +1 have 0.762 and 0.768.

The observer-bearing body measures:

- 16.679830 ms mean / 59.952649 FPS;
- 16.901500 ms p95, 17.438542 ms p99, and 33.316917 ms worst wall interval;
- 12.343869 ms mean, 13.575042 ms p95, and 18.437417 ms worst thread CPU; and
- five combined-thread CPU rows above 16.7 ms.

The five overrun frames contain 175 one-in-4,096 dispatch samples versus
146.46 expected from the 6,645 within-budget frames. No PC dominates:

| Guest PC | Overrun samples | Expected samples | Excess |
|---:|---:|---:|---:|
| `0x8035D548` | 3 | 0.443 | 2.557 |
| `0x803622DC` | 4 | 1.462 | 2.538 |
| `0x80361AF8` | 3 | 0.506 | 2.494 |
| `0x80360638` | 3 | 0.704 | 2.296 |
| `0x803408D4` | 5 | 3.072 | 1.928 |

The broader `0x80360000..0x8036FFFF` region contains 66/175 overrun samples
versus 47.61 expected. Its 18.39-sample excess explains 64.4% of the total
28.54-sample excess, but remains distributed across many entries. The largest
16 KiB slice, `0x80360000..0x80363FFF`, contains 34 samples versus 21.63
expected.

## Prior-mechanism closure

These are not newly discovered addresses. `0x803408D4`, `0x80360638`,
`0x80361AF8`, `0x803622DC`, and `0x8035D548` all recur in the retained
PERF-075 predecessor/destination stream. That family already received stronger
causal screens than this five-frame sample can justify:

- ten address-specific direct calls removed 9.17% of dispatches but improved
  CPU-thread mean only 1.17%;
- a safe broad guarded path removed 69.05% of dispatches but improved CPU-thread
  mean only 1.66%, while growing text and retaining the tail;
- inline-validity, trace-forest, merged-state, register-cache, LLVM, and
  structural follow-ups all failed their materiality or semantic screens.

Rebuilding one of those mechanisms against the same HSD/GX-heavy family would
repeat a closed experiment. The exact overrun evidence therefore rejects an
isolated PC rewrite, another direct-call design, or a small merged region.

## Visual correction

Initial inspection nearly mislabeled Fountain's intentionally oversized
flower/tree background during a close camera zoom as a new geometry warp. The
observer-free replay corrects that interpretation: Pikachu and Fox remain
proportionate at load and after live movement/attacks. The second endpoint also
shows the expected zoomed-out stage and coherent Fox.

The lower reflected floor remains visibly smeared/blocky at close zoom. That
known renderer defect stays tracked; this evidence does not close it or claim
full visual parity.

- `docs/evidence/g5-warm-dispatch-attribution/observer-free-load.jpeg`, SHA-256
  `6ecc208b7ffa37959a2568fd183429385d6a81c648a171794e290fc035aac197`;
- `docs/evidence/g5-warm-dispatch-attribution/observer-free-live.jpeg`, SHA-256
  `1dd88dec98c7af8614a21219086e5803d2508936232020910c3b4f0921db9030`.

## Decision

**REJECT ANOTHER LOCAL STATIC-RECOMPILER REWRITE FOR THIS WARM CLASS.**

The exact warm overruns are real static-core work, but their guest-PC excess is
distributed inside an already-closed family. No product optimization is
retained. Keep G5 open on observer-light compute and wall tails and preserve the
separate lower-floor reflection defect. G6 remains blocked.

Private CSV traces have SHA-256 values:

- lightweight: `98a71756c439129c6cb502e8ea6f6d9b52ed2644977eb408f30e000360ae38de`;
- phase: `b27e8cd96f03d64574da269f0f89079df02d5ec2fab5527576675838d5b7e0f2`;
- dispatch: `bf9c1ee0c3578c9abd088b4456f9df252c1e94cd967470c542bb5096080eda2f`.

ROM data, savestate, module, and private CSVs are not committed. No game or
Simulator remains.
