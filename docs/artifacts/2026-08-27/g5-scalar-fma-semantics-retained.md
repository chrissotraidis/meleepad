# G5 scalar FMA semantics retained

## Question

The exact late-Fountain native sample placed `ppc_fma` at the top of 118 CPU-
thread samples, making it the largest untested runtime helper after exhausted
scheduler, GX FIFO, FP-availability, and guest-PC candidates. Could the helper
be made faster, and did generated scalar FMA already preserve Dolphin's exact
instruction semantics?

## Failing-before result

DolRecomp emitted all eight scalar `fmadd[s]`, `fmsub[s]`, `fnmadd[s]`, and
`fnmsub[s]` variants through the legacy value-returning `ppc_fma` helper. The
exact GALE01 DOL contains 3,677 such generated calls.

A standalone regression failed in two instruction-visible ways:

- normal `fmadds 1.1 * 2.2 + 3.3` produced the same numeric result but left
  FI/FR at `0x00060000`; Dolphin-exact execution leaves `0x00020000`;
- with FPSCR NI set, a single-precision `0x1p-140` result survived instead of
  flushing to zero.

These are correctness and determinism defects. They are relevant to the prior
character-warping report and eventual netplay even though they did not explain
the remaining frame-time deficit by themselves.

## Retained correction

Patch `patches/dolrecomp/0002-scalar-fma-semantics.patch` routes all eight
generated scalar FMA forms through the existing instruction-shaped
`ppc_fmadd_op`. The production GXRuntime implementation already matches
Dolphin's `NI_madd`/`NI_msub`, ForceSingle, exception gating, lane writes,
FPRF, and supported FI/FR behavior. A standalone DolRecomp implementation
keeps generated-C tests self-contained.

Patch `patches/moderngekko-dolphin/0015-gxruntime-scalar-fma-tests.patch`
adds focused single/double, add/subtract, negative, paired-lane, FI/FR, NI-
flush, and VE-gated signaling-NaN coverage.

The regenerated exact DOL has 237 chunks, exactly 3,677 `ppc_fmadd_op` calls,
and zero legacy `ppc_fma` calls. The expected SMC warning is unchanged.

## Preflight and structural result

The corrected helper is not an isolated speed win. Across five-million-call
host runs, the old helper measured about 5.40-5.57 ns/call and exact execution
about 5.74-5.92 ns/call, a 0.236-0.376 ns cost. The linked candidate is still
structurally healthy: it is 66,048 bytes smaller overall and its `__text` is
66,240 bytes smaller than control, with the same exports.

Bounded lockstep matched candidate and control at 1,367 distinct PCs, 91
reports, seven fallback skips, three zero skips, zero undercharges, and zero
maximum deficit. Their divergence-entry files are byte-identical (SHA-256
`e689f99da86d8c6399376f3fa76563942303b0df8a3c85ad21a250f4503c708d`).
The generic early-boot screen did not distinguish the focused FMA vectors, so
the instruction regressions—not lockstep alone—prove the correction.

## Equal-emulated-frame live result

Every accepted row covers the last occurrence of emulated frames
`48123..48562` from the same repository-excluded Fountain savestate. The load
signal was withheld until the phase log reported emulated frame at least
1,000; all candidate/control/package loads completed without a crash.

| Metric | Candidate A cold | Canonical B | Candidate A2 |
|---|---:|---:|---:|
| Mean / FPS | 40.343472 ms / 24.787 | 18.967010 / 52.723 | 19.127040 / 52.282 |
| p95 | 61.275000 ms | 20.397875 ms | 21.457875 ms |
| p99 | 72.440375 ms | 21.625500 ms | 23.618875 ms |
| CPU-thread mean | 26.739098 ms | 18.569476 ms | 18.696447 ms |
| Frames <=16.7 ms | 0.000% | 0.455% | 1.364% |
| Guest cycles | 3,567,157,803 | 3,567,157,795 | 3,567,157,781 |
| Native dispatches | 59,374,688 | 59,374,684 | 59,374,687 |
| Static bursts | 905,029 | 905,179 | 905,019 |

The first candidate is a cold host/cache outlier and is not attributed to
source. The warmed candidate and control remain close in mean, but candidate
tail latency is worse. Work differs by at most 22 guest cycles, four native
dispatches, and 160 bursts; all rows have zero static fallback steps and 882
hook fallbacks. This correction is retained for semantics, not promoted as a
performance improvement.

## Visual and package proof

Two separated disposable-candidate Fountain frames showed coherent Pikachu,
Fox, and stage geometry. The final signed packaged app also loaded the state
cleanly and retained
`docs/evidence/g5-scalar-fma-semantics/packaged-fountain-combat.jpeg`, whose
window title reported 52.5 FPS. No character stretching or morphing is visible
in that capture. This is a bounded non-recurrence observation, not a new broad
visual-closure claim.

The official content key is `d852344fce9334dc`. The unsigned active module is
SHA-256 `a23fc7172b511f4aa307993b902e0b8918aabaa85e1c4bafc27227db108faf73`;
the signed packaged copy is
`3bc444f82366769c6e36247f4c0cfee48c5e0c6783d86f887882877613e69055`.
Both copies have identical 81,567,272-byte `__text` with SHA-256
`ac3089f2a6103e98fe6ad6f2f1a1d62966a77fabb4ceb848be315d986004674d`.
The packaged runner remains
`9d0fdf87df13593aabdc58371b2c2791a7c8910c9451af0504d3a1dd283da3c5`.
Runner and module are native arm64 with macOS 14.0 minimum.

## Verification

- clean patch apply, reverse-check, and source identity pass;
- dependency bootstrap recognizes all patches through DolRecomp 0002 and
  Dolphin 0015;
- DolRecomp passes 14/14 from a fresh build;
- GXRuntime passes 1/1 from a fresh build;
- `gcpipe` passes 16/16;
- focused frontend, GameCube, netplay-protocol, and memory-watcher CTest passes
  4/4;
- the exact ISO validates and the official 237-chunk ThinLTO build completes;
- strict deep code-sign verification and repository safety checks pass;
- no game process or Simulator remains.

## Decision and next experiment

**Retain and promote scalar FMA exactness; do not call it a speed win; G5
remains open; G6 remains blocked.** Fountain remains around 52 FPS with p95
above 20 ms, so Final Destination and iPad promotion are not authorized.

Next, take a fresh exact-window native sample from the promoted module, exclude
the known scheduler wait and now-correct FMA helper, and rank the next distinct
dynamic cost. Do not retry global MMU/locked-cache, gather width, dispatcher
budget, broad FP, transparent PC stores, computed labels, or per-dispatch
guest-PC replacement probes without new evidence.

## Evidence

Raw phase CSVs, runner logs, lockstep entries/logs, and the packaged screenshot
are retained under `docs/evidence/g5-scalar-fma-semantics/`. The RAM-bearing
savestate and ROM-derived generated source remain excluded.
