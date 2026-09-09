# Additional Melee GitHub research — September 9, 2026

The strongest additional performance lead is in the shared recompiler, not a
new finished Melee port. This pass inspected repository histories, source files,
and status documents. It did not build these projects or establish an FPS gain.
The prior [Simulator comparison](NATIVE-PORT-LEARNING-GOAL.md)
remains a no-promotion result.

## Additional projects screened

| Project / inspected revision | What the source establishes | Use for MeleePad |
| --- | --- | --- |
| [ssbmsim](https://github.com/barrelofsulfuricacid-gif/ssbmsim/tree/00877d769499) | Native headless gameplay research, Linux x86 with a 32-bit ABI; replay diagnostics and offline asset conversion | Learn replay admission and first-divergence diagnostics; not an Apple renderer or a proven replacement game engine |
| [MeleeXR](https://github.com/astelmach20/meleexr/tree/6da7005486bb) | README explicitly says Phase 0, nothing runs yet | Track Aurora/ARM portability work; no runtime optimization to adopt today |
| [Melee-Recomp](https://github.com/sennecaelen/Melee-Recomp/tree/3123b75a35c0) | `pc/src/gx_pc.c` presents a clear-color framebuffer; geometry rendering is not implemented | Early host portability work, not evidence of fast rendered gameplay |
| [melee-macos-recomp](https://github.com/McDandle/melee-macos-recomp/tree/39e30dec9fa7) | One published proof-of-concept commit; this is already the base examined through melee4mac | Do not count its inherited work as an independent optimization |
| [melee4linux](https://github.com/Project516/melee4linux/tree/a276aeb70f98) | Default branch points to the same melee4mac commit already reviewed | No additional default-branch performance patch found; other branches were not exhaustively audited |
| [MeleeLight Decomp Edition](https://github.com/kodycode/meleelight-decomp-edition/tree/fb75307df7a0) | Browser-game physics adaptation; README acknowledges incomplete environmental collision and disabled netplay | Useful examples of source-to-behavior attribution, not a replacement for Melee's full simulation/rendering |
| [GCWII-Recomp-Test](https://github.com/MrPoloGit/GCWII-Recomp-Test/tree/d61eb9c13e56) | General DolRecomp/ModernGekko integration with platform/build fixes | Follow its underlying dependencies; launcher changes are not combat speedups |

Searches included forked repositories. Matching-decomp automation repositories
and forks with only matching/build changes were not treated as independent
native engines. This is a targeted survey, not an exhaustive inventory.

## Best new performance hypothesis: narrower state transfer between functions

[DolRecomp September 5 commit 40637c4683bd](https://github.com/ExpansionPak/DolRecomp/commit/40637c4683bd)
changes the LLVM backend's call-liveness analysis, native ABI policy, memory
services, floating-point services and exit handling. Its
[`abi_policy.cpp`](https://github.com/ExpansionPak/DolRecomp/blob/40637c4683bd/src/backend/llvm/abi_policy.cpp)
computes outputs needed by callers and propagates input/output/escape masks.
[`native_abi.cpp`](https://github.com/ExpansionPak/DolRecomp/blob/40637c4683bd/src/backend/llvm/native_abi.cpp)
uses those masks to select native function arguments and results.

The performance hypothesis is fewer unnecessary loads/stores of emulated CPU
state across native calls. This is relevant to our generated-code overhead;
it is not an upstream measured iPhone result. The native-register ABI itself
was introduced August 24, so that feature alone is not new. The September 5
implementation changes are the reason for a fresh source comparison.

Our [August 28 LLVM preflight](artifacts/2026-08-28/g5-llvm22-arm64-preflight.md)
was decisively negative: its exact 1,024-instruction sample produced 396,548
text bytes versus C's 64,756, and ran about 4.84–4.93 times slower. Broad
state materialization at exits and memory slow paths was a central problem.
The new code touches that mechanism, but does not prove it fixes it.

**Next bounded experiment:** establish the precise old source revision and
local modifications, then compare the new backend on the retained exact sample
and a complete function/caller region (needed to exercise its function ABI).
Check full CPU state, RAM, exceptions and ordered MMIO against the C backend;
measure code size and repeated execution time. First confirm the new runtime
service ABI can integrate with our pinned core. Stop on incompatibility,
divergence, code-size explosion or no material speed gain. Do not regenerate
the entire game or package another app before this gate passes. Apple target
support and strict FP behavior must be verified, not inferred from Linux ARM.

## Useful validation lesson: make gameplay comparisons repeatable

ssbmsim's [replay guide](https://github.com/barrelofsulfuricacid-gif/ssbmsim/blob/00877d769499/docs/replays.md)
distinguishes final-state checks, all-frame recorded fields and an instrumented
Dolphin oracle. For our next app A/B, use a fixed initial state, emulated-frame
input sequence and RNG state, rather than wall-clock menu automation. Record
revision, module identity, settings and frame range with the result. First prove
control-versus-control repetition before attributing differences to a candidate.
This addresses the differing costumes/workloads in our latest Simulator pair.

Do not adopt that project's comparator unchanged:
[`verify_ssbm_oracle_acceleration.py`](https://github.com/barrelofsulfuricacid-gif/ssbmsim/blob/00877d769499/tools/verify_ssbm_oracle_acceleration.py)
removes selected idle, hitlag and inherited-pose fields before comparison. Its
passes therefore have a narrower meaning than complete state equality. The
[public status](https://github.com/barrelofsulfuricacid-gif/ssbmsim/blob/00877d769499/docs/status.md)
reports that a complete 10,505-frame recording ran but diverged; canonical
qualification remains unmet. Its UCF 0.84 target also differs from vanilla
MeleePad. Borrow the diagnostic structure, not its acceptance claims or rules.

## Larger architectural option

ssbmsim's [architecture](https://github.com/barrelofsulfuricacid-gif/ssbmsim/blob/00877d769499/docs/architecture/ssbm_native_runtime.md)
uses direct native references and offline endian-normalized assets, eliminating
guest CPU state and hardware emulation from its headless gameplay path. Along
with melee-native's direct-C/Aurora approach, this supports a long-term avenue:
replace a coherent subsystem rather than optimize a few translated loads.

That is a substantial port. Headless speed cannot predict rendered iPhone speed;
removing rendering/audio also removes work our application must perform. Native
pointer layouts, callback order, floating-point semantics and gameplay-dependent
render state require validation. It is a fallback research direction if the
bounded recompiler experiment fails, not a promised quick upgrade.

## Decision

1. Prioritize the changed compiler boundary implementation for a small feasibility
   check; no fresh full-game build yet.
2. Require repeatable frame-driven gameplay before another app performance A/B.
3. Keep direct-C subsystem migration as the larger option, with explicit scope.

No stable runtime, ISO, save, device installation or release changed in this
research pass. Private source snapshots are under the ignored
`ref/native-port-learning/github-survey/` directory.

## Follow-up: compiler built and tested on Apple Silicon

The owner requested further testing. The September 5 backend was cloned at
`40637c4683bd2820ac5b23607ee344720beb26df` into an ignored research directory.
The production compiler checkout remains at
`93b881c8f73df1d64a88491f2aa50c7c9ed2384d` and was not changed.

### Build and correctness gate

The new backend builds locally after isolated LLVM 22 API adjustments:
typed target triples, renamed intrinsic declarations, updated PGO constructor,
and omission of ELF-only cold-function section names on Mach-O. These are
experimental compatibility edits, not an upstream-supported configuration.
The exact patch is retained as `github-survey/llvm22-macos-compat.patch` beneath
`ref/native-port-learning/`.

CTest: **29/32 passed**. Execution tests for LLVM semantics, paired-single,
interception and all three native-ABI modes passed. Three failures remain:

- `llvm_pipeline`: the test's object-magic helper accepts ELF on non-Windows,
  but this host produces Mach-O.
- `llvm_codegen`: the AArch64 cold-escape disassembly assertion fails; its
  symbol selection omits the Mach-O underscore. This is a platform-test lead,
  not proof that all generated escape paths are correct.
- `modern_codegen`: generated `func_80003D40_budget` returns four i64 lanes,
  while the assertion expects three. Do not change the expectation merely to
  obtain a pass; the runtime contract needs independent validation.

### Exact retained Melee sample

Reconstructed the original 4 KiB sample at `0x80323940` from the owner's local
v1.00 DOL; SHA-256 matches the August experiment exactly:
`f82de9173e8d42fbd3b755124188e318ca1de9b2ebd676dd84555a51d01f4e3a`.
This is deliberately the old reproducibility fixture, **not a v1.02 gameplay
measurement**. No game-derived bytes are committed.

Both backends here are from the September 5 compiler with the same new CPU
layout. C is compiled with `-O2 -ffp-contract=off -fno-fast-math`; LLVM uses
exact semantics and the host target. Therefore this compares backend choices
within the new revision, not the shipping MeleePad module against a replacement.
The updated LLVM partitioner emits 45 objects; C emits one. The harness calls
the corresponding LLVM function at `0x803248DC`, versus the C chunk dispatcher
with that same entry PC, and checks identical exit state at `0x80324940`.

Each reported timing is the median of nine alternating C/LLVM samples of one
million calls, including identical state restoration. The original single-seed
full CPU/RAM comparison passed for every timed run.

| Mode | Repeated change versus current-revision C | Result |
| --- | --- | --- |
| Default native ABI | 4.06%, 5.19%, 11.21% slower | No speed advantage |
| Compact native ABI | 6.95%, 6.80%, 7.54% slower | No speed advantage |
| ABI off, state in memory | Initial: 4.83% slower, 5.02% faster, 5.01% faster; confirmation: 4.68% slower, 4.40% slower, 5.01% faster | Inconsistent; no repeatable gain |

All LLVM objects for the sample total 187,560 text bytes versus C's 30,388
(about 6.17 times larger). Partitioning and compiler versions differ from the
old experiment, so this is not a clean historical speedup measurement.
The upstream synthetic complete-call-chain benchmarks also executed in all
three modes, but do not establish Melee gameplay performance or a C-backend gain.

### Expanded differential test finds a cycle-accounting mismatch

Ran 256 cases per mode varying finite input values, saved registers, condition
state, cycle budgets and FP enablement. **240 ordinary cases matched per mode;
16 FP-disabled cases diverged in every mode.** At the first failing case both
reach exception PC `0x800`, with SRR0 `0x803248F0`, matching RAM and other
CPU bytes. The C cycle budget is -30, LLVM -22: the C block charges 14
instructions up front, while LLVM charges the six instructions through the
fault. This is a compatibility difference, not a demonstrated wrong gameplay
result or proof that C's exception accounting is architecturally preferable.
It still prevents claiming interchangeable full-state behavior.

### Decision after testing

**Do not promote or build a full Simulator app from this backend.** The
normal-path advantage is not repeatable, generated code is much larger, and
integration/cycle-accounting questions remain. This closes the newly proposed
stock-backend trial with actual execution evidence. Do not repeat a full
compiler build without a specific change addressing these failures.

The next meaningful larger experiment would need a complete hot function/caller
region with a new state-transfer design, selected from a repeatable gameplay
trace. The current result does not justify a wholesale compiler migration or
claim that native-C gameplay is unviable. The first practical prerequisite is
still a frame-driven control-versus-control replay fixture; wall-clock Simulator
routes were not repeatable enough to attribute small app differences.

Reproduction files and logs are retained under
`ref/native-port-learning/github-survey/`: `build-slice.py`, `slice-harness.c`,
`check-matrix.py`, `slice-matrix.c`, `ctest.log`, `slice-repeat-*.txt`,
`compact-repeat-*.txt`, `context-repeat-*.txt`, `context-confirm-*.txt`,
`matrix-*.txt`, `slice-size.txt`, and `llvm22-macos-compat.patch`.
No app, module pointer, Simulator, physical device, ISO or save was modified.

## Rechecked the 120 FPS claim

On the owner's follow-up, GitHub still reported melee4mac HEAD as
`a276aeb70f9879204d891d967f1c9442523568e1`.
[PR 12](https://github.com/t3dotgg/melee4mac/pull/12) explicitly describes
60 Hz gameplay plus predicted visual updates for 120 Hz displays, and says
physical 120 Hz output remains to be checked. The implementation computes
`current + (current - previous) * 0.5` for eligible pose components, performs
an extra geometry render, then restores saved transforms. This is a real extra
render, not a duplicate framebuffer and not 120 Hz physics.

Executed its focused high-refresh suite locally:
`python3 -m unittest discover -s native/macos/tests -p test_high_refresh.py`;
**6 tests passed**, including compiled pose prediction/restoration checks.
This validates those contracts, not live display output or performance.
The precise X posts were not supplied and could not be identified by search;
do not attribute every online claim to this one implementation.

Our preceding LLVM sample test did not test or disprove this rendering feature.
The next fair comparison for that claim is each native macOS app on the same
Mac, same v1.02 scene, resolution and settings, with simulation, rendering and
presentation counted separately. An iOS Simulator comparison is useful for
mobile integration but is not a like-for-like native macOS benchmark. If the
60 Hz baseline has headroom, then measure the extra render cost and verify
motion on an actual 120 Hz display before considering a high-refresh option.

The [completed native Mac comparison](NATIVE-MACOS-COMPARISON-GOAL.md) now records
actual same-Mac combat tests, the 120 FPS shortfall in Onett, and the next
decompilation-guided profiling experiment.
