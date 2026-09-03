# G5 static-recompilation structural follow-up

Date: 2026-08-28

Status: **RESEARCH COMPLETE; REGION-STATE PREFLIGHT NEXT; G5 OPEN**

## Current evidence

The current signed arm64 product remains compute-bound in the retained
Fountain state. A fresh 440-emulated-frame interval executes exactly
1,501,629,399 guest cycles and 51,369,928 native dispatches. It measures
16.814891 ms total mean, 18.761260 ms p95, 21.389482 ms p99, and 29.560250 ms
worst; only 56.3636% of frames are at or below 16.7 ms. CPU-thread work is
15.735743 ms mean and 17.683831 ms p95. Video build, present, and audio remain
secondary at 0.775074, 0.020328, and 0.863537 ms mean respectively.

The visible Fountain frame is coherent at a 60.0-FPS title reading. Pikachu,
Fox, and stage geometry are coherent; the known reference-parity distorted
floor reflection remains. This is not a G5 pass because the retained phase
trace fails the strict tail gate.

PERF-079 and PERF-081 establish the useful mechanism: making a generated
region genuinely single-entry and keeping live guest state in C locals removes
host loads, stores, and branches and repeats 9.70-21.79% local gains. Those two
selected regions were too small to matter globally. PERF-082 establishes that
the existing LLVM backend is not a route around this work: its exact hot slice
is 6.12 times larger and 4.84-4.93 times slower than generated C.

## Researched methods, ranked for this product

### 1. Profile-guided C translation regions with live guest state

Generate an extended basic block (single entry, multiple exits) from a hot
guest path. Load only the live GPR/FPR/CR fields into C locals at entry, keep
them live across former dispatch boundaries, and synchronize only dirty fields
at a real exit. QEMU documents extended basic blocks, translation-block
temporaries, CPU-state optimization, and direct block chaining; Dolphin's
ARM64 JIT implements an explicit guest-register cache. This is the closest
match to meleepad's measured instruction-delivery, CPUState traffic, and
approximately 116,750 dispatches/frame.

The first preflight must be data-free and bounded. It will select a hot path
from the retained guest-PC sample, preserve exact cycle accounting, and cover
normal completion, conditional side exits, helper/exception exits, SMC
invalidation, host calls, and forced fallbacks. It must compare full resulting
CPU/RAM state, arm64 load/store/branch counts, text size, and equal-work timing.
No game build follows unless measured coverage times local gain projects above
5% CPU-thread improvement.

### 2. Helper-effect classification inside those regions

QEMU's IR distinguishes helpers that read globals, write globals, raise, or
have no side effects. DolRecomp currently passes `CPUState*` broadly, which can
force conservative guest-state materialization around calls. A small effect
table for only the helpers reached by the selected region can allow clean
locals to remain live while dirty fields are synchronized only when required.
This belongs inside method 1; a global annotation rewrite would be too broad.

### 3. RAM-specialized memory operations with explicit slow exits

QEMU and Dolphin separate ordinary RAM/ROM accesses from MMIO and exception
paths. DolRecomp already has ordinary-memory fast paths, so this is not a
default rewrite. It qualifies only if the next exact sample attributes a
material share to address classification or helper calls. Any candidate must
retain endian behavior, mirrors, EXRAM, reservations, journaling, external
callbacks, and DSI/alignment semantics.

### 4. Chunk-scoped native replacements

The exact PSMTXConcat replacement was 3.23-3.29 times faster but the supported
global replacement probe taxed every dispatch. A wrapper installed only at
the owning generated chunk avoids that global tax and is a valid mechanism for
several proven replacements. PSMTXConcat alone projects well below 5%, so it
is secondary to region-state retention and must not trigger a full build by
itself.

## Methods not worth repeating now

- ThinLTO is already active; O3 plus native tuning was measured and rejected.
- Instrumentation PGO, whole-module IR PGO, and a Mach-O order file were
  measured and did not close G5.
- LLVM BOLT's documented input is ELF, not this arm64 Mach-O product, and code
  layout does not remove CPUState traffic.
- DolRecomp's current LLVM backend failed the exact size and runtime preflight.
- More isolated low-frequency guest replacements cannot reach the 5% gate.
- Runtime-created executable code, patched JIT links, and `MAP_JIT` are outside
  the iPad-compatible product path.

## Primary references

- QEMU translator internals, CPU-state optimization and direct chaining:
  <https://www.qemu.org/docs/master/devel/tcg.html>
- QEMU TCG IR, extended basic blocks, temporaries, and helper effects:
  <https://www.qemu.org/docs/master/devel/tcg-ops.html>
- Dolphin ARM64 guest-register cache:
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/PowerPC/JitArm64/JitArm64_RegCache.cpp>
- LLVM ThinLTO:
  <https://clang.llvm.org/docs/ThinLTO.html>
- LLVM BOLT requirements:
  <https://github.com/llvm/llvm-project/blob/main/bolt/README.md>

## Next falsifiable step

Build one disposable C region-state harness from a representative hot path.
Reject the architecture unless it passes full state/RAM semantics and its
measured local gain, multiplied by defensible current sample coverage, exceeds
5% CPU-thread improvement. Only a passing preflight earns a private module and
equal-emulated-frame Fountain A/B/A run.
