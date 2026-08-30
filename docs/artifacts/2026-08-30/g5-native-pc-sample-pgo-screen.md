# G5 native-PC sample-PGO screen (PERF-211)

Date: 2026-08-30

Status: **USEFUL SAMPLE PROFILE CANNOT BE CONSTRUCTED; NO MODULE BUILD; G5 OPEN**

## Question

The earlier static-recompiler survey rejected LLVM sample PGO because its
documented profile generator requires Linux perf or ARM ETM/branch traces that
are unavailable on this M1. PERF-206 now supplies a local external native-PC
ring. Does that new data make sample PGO a genuinely distinct optimization
route beyond the retained exact frontend instrumentation profile?

## Toolchain and binary prerequisites

AppleClang 21 accepts `-fprofile-sample-use`, and `llvm-profdata` is installed.
The installed Xcode toolchain does not contain `llvm-profgen` or
`llvm-symbolizer`, however. More importantly, the exact shipped frontend-PGO
module has only its Mach-O `__text` mapping: it contains no `__DWARF` line
sections and no LLVM pseudo-probe section. `atos` can name generated functions
but cannot map the retained PCs to source lines, inline contexts, or pseudo
probes.

The PERF-206 ring is periodic PC sampling. It contains no taken-branch stack,
last-branch records, ARM ETM trace, or call-site context. Its bounded stack
extension can identify native callers through frame records, but generated
guest chunks do not preserve a source/inlining context suitable for LLVM's
sample-profile format.

## Information comparison

A symbol-only flat profile could at most label generated functions hot. The
retained frontend instrumentation profile already supplies exact function
entries, block counts, branch weights, and scene-specific coverage for those
same chunks. PERF-202 independently proves its selected warm PCs have stable
multi-million-hit coverage. Replacing that profile with sparse function
samples would discard information rather than add a new causal signal.

Creating a useful probe-based profile would require all of the missing pieces:

1. a new pseudo-probe training build;
2. branch/context trace collection rather than the retained PC ring;
3. a compatible profile generator absent from this Xcode; and
4. a second profile-use build whose input no longer matches the accepted
   product image.

That is not a bounded conversion of existing evidence, and the M1 lacks the
locally documented Processor Trace hardware route.

## Decision

Do not synthesize a symbol-only sample profile, rebuild the full module with
pseudo probes, install an unrelated profiling toolchain, or claim the PC ring
contains branch context. Sample PGO remains technically supported by Clang but
cannot add useful information on this machine from the retained evidence.
Frontend PGO remains the best-known module; no build or runtime is justified.

No product, module, configuration, ROM data, save, audio, graphics, or netplay
state changed. No game or Simulator ran. G5 remains open and G6 remains
blocked.
