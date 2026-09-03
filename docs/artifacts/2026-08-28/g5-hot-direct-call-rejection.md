# G5 hot direct-call screen

Date: 2026-08-28

Status: **TEN-EDGE DIRECT LINK REJECTED; DISPATCH COST CONFIRMED; G5 OPEN**

## Question

Can the exact PERF-072 Fountain workload improve materially if the generated
caller at `0x8036C87C..0x8036C944` continues through ten measured cross-chunk
linked calls instead of returning through the native runtime dispatcher?

## Edge attribution

A disposable, default-off diagnostic runner sampled the previous native
dispatch PC and destination once per 4,096 dispatches. It ran the same
isolated user tree, retained PGO module, frame-gated state load, Metal/Cubeb,
and exact emulated frames `48123..48562` as PERF-072. The interval contained
12,539 samples, estimating 51,359,744 dispatches versus the actual 51,380,895.

The hottest pairs reconstruct one dense guest call sequence inside generated
chunk `func_80369940`:

| Caller -> destination | Samples | Estimated dispatches |
| --- | ---: | ---: |
| `8037C4EC -> 8036C8B0` | 121 | 495,616 |
| `803408D4 -> 8036C8D8` | 115 | 471,040 |
| `8036C8B0 -> 803408D4` | 108 | 442,368 |
| `8036C880 -> 80378698` | 106 | 434,176 |
| `8036C8D8 -> 8033FB64` | 103 | 421,888 |
| `8036C8E4 -> 80377B6C` | 101 | 413,696 |
| `8033FB64 -> 8036C8E4` | 101 | 413,696 |
| `8036C904 -> 8033FBA0` | 95 | 389,120 |
| `803408D4 -> 8036C880` | 92 | 376,832 |
| `80377B6C -> 8036C904` | 91 | 372,736 |

The corresponding linked call sites are `8036C87C`, `8036C890`,
`8036C8AC`, `8036C8C4`, `8036C8D4`, `8036C8E0`, `8036C900`,
`8036C918`, `8036C934`, and `8036C944`.

## Focused semantics and isolated build

The temporary generator candidate set LR exactly as before, returned through
the old path when accumulated generated cycles reached the 256-cycle budget,
called the existing replacement/host/original dispatcher otherwise, and
continued only when there was no exception and PC exactly matched the linked
return address.

A focused generated caller/callee regression failed before the change with
the callee still pending:

```text
profiled direct call pc=8037C4EC lr=8036C8B0 r3=41 downcount=-2
```

After the change it completed caller and callee in one entry with external LR
restored, `r3=42`, and `downcount=-7`. A second case starting at `-254`
proved the budget exit preserved callee PC, linked LR, unchanged `r3`, and
exact `-256` downcount. `dispatch`, `c_cfg`, `codegen_compile`, and
`c_execute` passed 4/4.

The isolated frontend-PGO candidate passed arm64 package layout and strict
deep signing. Its signed module SHA-256 is
`a068623d40f13afa9bebd641f32b46020cc24e2fa3d1cb52cd7f5b50d9cf3872`;
`__text` is 81,827,648 bytes. The old profile rejected one changed generated
function, so this is a positive screen rather than a clean negative screen.
Disassembly nevertheless proves ThinLTO constant-folded the constant lookup
into direct `bl _func_...` instructions; the result did not accidentally keep
the outer dispatcher.

## Exact-work runtime result

One native arm64 foreground process ran with no booted Simulator. The load
signal was withheld until emulated frame 1,050. The last occurrence of every
emulated frame `48123..48562` produced 440 rows:

- 1,501,757,014 guest cycles;
- 46,668,247 native dispatches;
- 898,669 bursts;
- 882 hook fallbacks; and
- zero fallback steps.

The 741-cycle boundary difference is 0.000049% of the interval and accompanies
the expected coalescing of call work across outer dispatch boundaries. It is
not claimed as exact-work equivalence.

| Metric | PERF-072 frontend PGO | Ten hot direct calls |
| --- | ---: | ---: |
| Mean / FPS | 16.663618 ms / 60.011 | 16.666753 ms / 60.000 |
| Median | 16.553833 ms | 16.628167 ms |
| p95 | 18.065125 ms | 18.052291 ms |
| p99 | 19.130250 ms | 18.633750 ms |
| Worst | 22.509416 ms | 22.057000 ms |
| CPU-thread mean | 11.620875 ms | 11.485026 ms |
| CPU-thread p95 | 12.770189 ms | 12.588202 ms |
| Frames <=16.7 ms | 55.909% | 55.000% |
| Native dispatches | 51,380,895 | 46,668,247 |

The candidate removed 4,712,648 dispatches, or 9.17%, but reduced CPU-thread
mean by only 0.135849 ms, or 1.17%. Total mean and compliance did not improve.
The p99 and worst reductions are useful attribution but do not satisfy the 5%
materiality rule or the absolute G5 tail requirement.

Direct UI inspection showed coherent Pikachu/CPU-Fox Fountain combat at a
60.0-FPS title. The retained frame shows intact characters, HUD, platforms,
and stage geometry with no observed morphing. Both the measurement run and
visual recapture exited normally.

## Safety audit and decision

The current native runtime calls `FastDispatchableAt` before each cross-chunk
entry. That check rejects forced-fallback addresses and requires the target
chunk to be verified after an instruction-cache invalidation. Calling a
different generated chunk from inside the module bypasses that outer check.
The ten-edge experiment therefore cannot be generalized or promoted without
a cheap target-validity guard, even though the unchanged Fountain scene had
zero failed SMC chunks.

**Reject the address-specific ten-edge candidate.** It confirms dispatcher
boundaries have measurable cost, but its 1.17% CPU gain is too small and its
current form weakens the SMC verification boundary. All generator, test, and
bootstrap experiment edits were removed; rebuilt canonical focused tests pass.

The next bounded experiment is a guarded broad direct-call path. It must first
prove that a verified caller refuses an invalidated or forced-fallback callee,
then screen whether linking statically known calls under the existing
256-cycle/exception/host-call rules removes enough outer dispatches to exceed
the 5% threshold. Do not retrain this ten-address candidate or promote it.
Final Destination and G6 remain blocked by G5.

Checkpoint validation passed repository safety, dependency bootstrap and patch
state, 40/40 applicable CTest entries, 16/16 `gcpipe` tests, canonical macOS
package layout, arm64 identity, and strict deep signing. The three optional
upstream benchmark/fuzzer executables are not produced by the tools-only build
and the upstream `playTests` row remains disabled. No MeleePad process or
Simulator remains active. The unrelated untracked netplay document was not
touched.

## Evidence

- `docs/evidence/g5-hot-direct-call-rejection/dispatch-edge-samples.csv` —
  sampled predecessor/destination stream, SHA-256
  `969d1f3d06b5910c5da14f9d9d36ebfcc108ad8d6e47596c9c5848ac259279d9`;
- `docs/evidence/g5-hot-direct-call-rejection/hot-direct-calls-fountain.phase.csv`
  — exact 440-frame candidate interval, SHA-256
  `7d2702a6847bc5bfb1e4dfc610f4436f4cf2db76d71e1fbfdfd6e137b4607ef9`;
- `docs/evidence/g5-hot-direct-call-rejection/fountain-combat.jpeg` — coherent
  live candidate frame, SHA-256
  `577e76cef076db0bcea9c728ee4d197ab2a7ca27e1e228fee50c40fa7e9e1efc`.
