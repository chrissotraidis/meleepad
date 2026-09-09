# Decompilation-informed performance loop

Started 2026-09-09. Budget: approximately three hours of investigation, implementation,
and validation, as requested by the owner. Baseline: Preview 4/build 18, main
`83b81ed2416c0d64fc36556289dbffe4af306a0a`.

## Outcome

The investigation produced a reproducible local-register optimization for three
matrix routines and a verified native-to-decompiled-source attribution tool.
The final private candidate passes 79,000 synthetic/adversarial comparisons and
300 additional comparisons sampled during actual Classic combat. Its isolated
host timings are promising. **Physical-iPhone performance is not established:**
iOS rejected the unchanged control launch because the device is locked.
Build 19 is staged locally; build 18 has not been replaced.

The remaining retention gate is a comparable physical control/candidate pair,
including warmed frame/audio tails. No public release or gameplay-speed claim
follows from this research alone.

## Working loop

1. Attribute existing native samples to exact decompiled functions. Generated
   16 KiB chunk names are not game-function names. Distinguish animation, graphics
   matrix submission, collision, and scalar math before choosing a connected region.
2. Estimate attainable whole-thread coverage, including boundary/guard overhead.
   Read the decompiled callers and existing runtime correctness constraints.
3. Implement one reversible, revision-specific candidate. Preserve intermediate
   rounding, guest memory and register state, exceptions, cycle accounting and
   fallback behavior. Do not trade simulation accuracy for speed.
4. Compare against the unchanged module with adversarial state/memory tests.
   Only then build/install on the physical iPhone and compare heavy scenes at
   1x/4:3, including a warmed repeat and frame/audio tails. Internal dispatch
   timing stays off for native profiling and acceptance runs.
5. Keep only a repeatable whole-game improvement. Record a failed experiment
   once, then move only if the evidence supports a distinct target. Stop around
   the time budget instead of extending an inconclusive benchmark campaign.

## Boundaries

Preserve the stable release, v1.00 support, existing device images/saves/settings,
and unrelated images in the worktree. Use a separate branch and private artifacts
under `ref/revision-102/decomp-connected/`. No public release is requested in this
pass. No Simulator netplay or QuickTime recording. Physical netplay acceptance
remains a separate requirement; numerical equivalence tests do not establish it.

Do not repeat the rejected inverse/trig/scalar leaf rewrites, global FP-check
removal, or FIFO sleep-threshold changes without materially new evidence. The
earlier [performance ledger](IPHONE-102-PERFORMANCE-GOAL-LOOP.md) remains authoritative.

## Evidence ledger

- Goal created and branch `codex/decomp-connected-performance` opened. Both
  physical iPhone and iPad are available. No candidate installed yet.
- Existing clean native profile identifies generated bodies, helper calls and
  runtime costs, but the matrix-labelled chunk spans multiple unrelated functions.
  First task: resolve native sample offsets to source before selecting a region.
- Rebuilt source-line information for 16 selected generated chunks. The resulting
  module's complete 81,323,120-byte executable section, addresses, constants and
  unwind section match the shipped module. This permits attribution of the saved
  physical profiles without changing the sampled workload. The private analyzer
  resolves inline-helper call sites as well as direct generated instruction lines;
  unresolved samples remain explicitly unassigned.
- Across two captures, the mapped matrix concatenation cost is about 4.8–4.9%
  of CPU-thread samples, inverse-transpose about 3.9–4.1%, and matrix writers
  about 7.4–7.9%. These are source-attributed samples, including work charged
  once to the nearest mapped caller, not predicted savings. About 52–54% of
  the full CPU thread is mapped by this selected-chunk pass. Main joint-matrix
  construction is much smaller than its broad chunk name suggested.
- Candidate 1: partition five hot matrix functions at decompilation-verified
  boundaries into separate native functions. Preserve their translated bodies,
  all helper calls, and the original return-dispatch budget/exception behavior.
  This tests compiler optimization within smaller functions rather than another
  math-formula replacement or broad compiler-flag sweep. Private iOS module
  compilation/linking passed. Rejected before device installation: 100,000
  full-state/RAM/ordered-MMIO comparisons passed, but isolated timing was flat
  or slightly worse. Smaller functions alone did not remove the relevant work.
- Candidate 2: retain floating-point register lanes and status in local native
  state across matrix concatenation, inverse-transpose and scaled-add, then
  commit architectural state at the original return boundary. Arithmetic and
  paired-single bit conversions retain the existing runtime semantics. Guards
  require ordinary bounded finite matrices, supported memory/FP modes and
  safe aliases; all other cases execute the unchanged translated body.
  This is a private prototype, not a retained release change.
- The complete candidate module passes 30,000 randomized/adversarial
  full-state/RAM/MMIO comparisons, another 30,000 continuation/interior-entry
  comparisons, and 9,000 additional alias/FP edge comparisons. Original ABI,
  code ranges, SMC ranges and source-chunk metadata match the control.
  Initial missing-constant and NaN-payload failures were caught locally and
  led to stricter guards before these passing runs. These tests establish
  the tested behavior, not universal equivalence or netplay acceptance.
- Isolated full-module host measurements: concatenation roughly 140–151 ns
  to 50–54 ns; inverse-transpose 350–354 ns to 260–268 ns; scaled-add
  104–110 ns to 64–66 ns. Applying those reductions to the old physical
  sample shares gives an optimistic ceiling around 5% of CPU-thread time.
  This assumes comparable device code generation and sufficient guard hits;
  it is neither measured iPhone savings nor an FPS prediction.
- Private build 19 is staged and signature-verified. The host machine-code
  section and v1.00 module are unchanged; only the v1.02 candidate and private
  bundle version differ. It is **not installed**. The attempted physical
  control launch was rejected because the iPhone is locked. Build 18 remains
  installed; existing game data was backed up without resetting it.
- A separate, isolated local opening-sequence run observed approximately 99.997%
  concatenation, 95.8% inverse-transpose and 99.9998% scaled-add guard acceptance
  among calls entering through the module dispatcher. It compared 100 live
  input states per routine against the full original module, including all
  24 MiB of guest RAM and CPU state; those 300 comparisons passed. The test
  used Null graphics/audio, so it provides guard/correctness evidence only.
  Internal same-chunk entries are not counted by that diagnostic wrapper.
  The first run was initially mislabeled Classic: source scene IDs identify
  `0x18` as the opening movie and `0x03` as Classic. Timed input began before
  the controller pipe connected and missed the Start presses. The revised
  diagnostic drives menus from observed scene IDs; opening hit rates must not
  be presented as combat coverage.
- A subsequent review adds one conservative fallback: a concatenation stack
  frame must not overlap the constant table. Otherwise a saved incoming FP
  register could overwrite the table after its entry check. Both modules
  rebuilt successfully; all 69,000 full-state, continuation and alias cases
  pass again. The stricter private build 19 is staged and signature-verified,
  still uninstalled.
- Reading `HSD_MtxInverseTranspose` identified unnecessary checks on the
  previous destination and input translation slots. Its arithmetic uses only
  the input 3x3 block; the original copy/continuation paths remain intact.
  Restricting the finite-value guard to actual arithmetic inputs passes all
  69,000 earlier cases plus 10,000 cases with arbitrary unused-slot and
  destination contents. Both complete modules rebuild successfully.
- The corrected local route reaches Classic state `0x03030101`. The pinned
  `gm_Mode_Classic_States` maps state 1 to `GS_VS`, confirming the gameplay
  phase rather than inferring it from elapsed time. A further 100 comparisons
  per routine, after 300,000 eligible calls in that phase, pass against the
  original module with complete CPU state and 24 MiB RAM equality. In the
  preceding complete route, final guards accepted over 99.99% of observed
  dispatcher entries for all three routines. This remains a local Null-renderer
  correctness/coverage check, not iPhone or netplay acceptance.
- Final isolated host timing ranges: concatenation control 142–184 ns versus
  candidate 51–53 ns (the control warms across rounds); inverse-transpose
  352–358 ns versus 257–265 ns; scaled-add 104–107 ns versus 64–66 ns.
  Keep the roughly 5% optimistic CPU-time projection separate from measured
  whole-game benefit, which remains unknown.
- Reuse investigation: 100,000 consecutive inverse-call input records from
  Classic gameplay show 51.0% reuse in a 128-entry LRU and 60.0% in 256 entries
  with the full observed key. Keeping only arithmetic inputs plus FPSCR gives
  54.0% and 61.9%; increasing capacity to 1,024 adds no hits in this sample.
  This does not justify adding a broad cache now: inverse-transpose is only
  about 4% of the old CPU profile, and even ideal reuse leaves a small ceiling
  before lookup, key construction and architectural-state restoration costs.
  No result cache was implemented or enabled.

## What the decompilation changes

The recovered source provides function boundaries, data layouts and the exact
inputs each calculation uses. This pass used all three: to attribute native
costs, preserve return/exception behavior, and remove unnecessary guard checks.
That is a concrete use of the decompilation in the implementation.

It is still a GameCube-targeted codebase. For example, the upstream
[`PSMTXConcat` implementation](https://github.com/doldecomp/melee/blob/ae5898ee0dfda41b34fdf846f7d680a33e14779d/extern/dolphin/src/dolphin/mtx/mtx.c#L136)
contains PowerPC assembly. MeleePad's current native module translates such
operations while maintaining guest registers, memory, floating-point behavior
and the hardware interface. Source completion does not remove that work.

Locally, the original DOL has 3,882,272 bytes of executable sections; the
baseline native module has 81,323,120 bytes of executable code including
translation and compatibility helpers. This size comparison illustrates the
different representation; it does not establish a cache bottleneck or a speed
ratio. A broader native-source port would also need to resolve guest pointer
layouts, endianness, SDK/hardware calls and cross-boundary state semantics.

The immediate next step is to validate this candidate on the iPhone. If it
fails that gate, retain the attribution tooling and reject the runtime change;
do not respond by layering more matrix microbenchmarks onto it.

## Reusable research tools

`scripts/analyze-native-guest-cost.py` replaces broad chunk-name guesses with
source attribution for exported arm64 Time Profiler CPU samples. It checks the
sampled module UUID, equivalent debug module's complete `__TEXT` sections and
addresses, and matching dSYM UUID. It resolves direct lines and inline-helper
call sites, adjusts caller return PCs, and charges each sample once. Functions
with identical names at different guest addresses remain separate. Unmapped
work stays in the denominator. Six synthetic tests and a replay of the saved
physical profile pass; the latter reproduces 52.06% mapped CPU coverage.

Use the exact generated source tree from the debug build: DWARF v4 does not
authenticate source contents. The script's binary checks do not remove that
precondition. For example, with paths to private local artifacts:

```sh
python3 scripts/analyze-native-guest-cost.py \
  --trace-xml "$TRACE_XML" --baseline "$SAMPLED_MODULE" \
  --debug-module "$EQUIVALENT_DEBUG_MODULE" --dsym "$MATCHING_DSYM" \
  --generated "$MATCHING_GENERATED_CHUNKS" --symbols "$DECOMP_SYMBOLS" \
  --output "$PRIVATE_REPORT"
```

`scripts/prepare-matrix-local-state-experiment.py` makes the candidate
reproducible without committing game-derived bodies. It authenticates seven
input files against the tested v1.02 source/runtime hashes, refuses an existing
output directory, and writes only private generated sources and an experiment
manifest. Unsupported revisions or changed runtime semantics fail before any
output is created. Three synthetic input/preservation tests pass. Regeneration
of the initial candidate reproduced all five source files byte for byte.
The final guarded candidate also reproduces all five files byte for byte.
The experiment is not wired into normal builds, installation or releases.

```sh
python3 scripts/prepare-matrix-local-state-experiment.py \
  --generated "$MATCHING_GENERATED_ROOT" --runtime "$MATCHING_GXRUNTIME" \
  --output "$FRESH_PRIVATE_EXPERIMENT_DIR"
```

Compile its two replacement chunks plus `lift.c` using the original module's
flags and link against the unchanged other objects. In particular, preserve
floating-point contraction/fast-math settings, ABI and revision checks. The
generated output includes game-derived code and must stay private.

## Pending retention gate

Run the unchanged build-18 physical control, then the candidate with comparable
starting thermal state and the same fixed four-fighter route. Compare the
uninstrumented warmed frame-time/audio windows as well as the native profile;
repeat only if that first pair is promising. Restore the stable module if the
candidate regresses or the result remains inconclusive. A locked device does
not turn a host microbenchmark into physical acceptance.
