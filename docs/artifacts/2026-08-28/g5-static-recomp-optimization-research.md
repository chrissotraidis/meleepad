# G5 static-recompilation optimization survey

Date: 2026-08-28

Status: **RESEARCH COMPLETE; INLINE VALIDITY PREFLIGHT NEXT; G5 OPEN**

## Project evidence that controls the decision

The static module is already arm64-native, Release, ThinLTO-built code. A
representative frontend-PGO build lowers Fountain CPU-thread mean to about
11.62 ms, but total frame p95 remains about 18.07 ms. PERF-076 removed 69.05%
of native dispatches in a fair no-profile pair and improved CPU-thread mean by
only 1.66%; its two out-of-line guard callbacks consumed most of the benefit.
PERF-073 and PERF-074 also rejected whole-module IR PGO and global code order.
The next change therefore must alter the hot-path representation, not merely
add another compiler switch or rearrange the same 80+ MB text image.

## Ranked methods

### 1. Inline eligibility table for direct block chaining

QEMU's documented fast path chains translated blocks directly and falls back
to its main loop when the destination is unavailable. It separately maintains
invalidation state so patched links cannot enter stale translated code. The
equivalent AOT representation here is one inline byte load and conditional
branch at a known cross-chunk target, backed by runtime-owned eligibility
state. Verification, forced-fallback ranges, host-call addresses, REL mapping,
lockstep, and icache invalidation must all clear eligibility before a direct
edge can run.

This is the first preflight because it preserves PERF-076's safety contract
without its callback call/return pair. A focused generated harness must compare
callback-guard and inline-table cycles, prove denied target and continuation
after invalidation, and project more than 5% CPU improvement before a game
module is built.

### 2. Profile-derived superblocks or traces

If a guard at every edge is still too expensive, combine the hottest observed
basic-block path into a larger single-entry region and guard only its entry and
exit boundaries. This follows the extended-basic-block model used by mature
binary translators while reducing CPUState spills, dispatcher transitions,
and instruction-cache footprint relative to linking all 67,012 sites. The
existing exact-frame predecessor/destination samples provide the trace input.

The first version must cover one bounded Fountain trace, retain the 256-cycle
budget and exact exception PC, and stop at host-call, forced-fallback, REL, or
SMC-sensitive boundaries. It is preferable to broad generated-function
inlining because the latter already inflated text by 12.79%.

### 3. Keep hot guest state live within those regions

QEMU documents holding its CPU environment and translation-block temporaries
live instead of repeatedly flushing all virtual CPU state. Larger generated
regions give Clang an opportunity to keep the PowerPC PC, cycle count, and hot
registers in arm64 registers across former block boundaries. Optimization
remarks and arm64 disassembly should prove eliminated loads/stores; source
annotations alone are not evidence.

### 4. Profile specific helpers and memory operations

Apple's Game Performance, Time Profiler, and CPU Counters instruments can
separate branch misses, instruction-cache pressure, memory stalls, renderer
work, and off-core waits. The next live trace should identify the top generated
helpers and memory paths before attempting targeted inlining, endian-load
fast paths, paired-single lowering, or RAM-versus-MMIO specialization. Generic
helper inlining is already rejected; only a measured top consumer qualifies.

### 5. Treat renderer and frame pacing as a separate tail problem

Static recompilation can reduce CPU-thread time, but it cannot by itself close
the measured total-frame tail. The PGO compute path averages roughly 11.62 ms
while p95 remains above 18 ms, and prior joined evidence includes long off-core
stalls. A Game Performance trace must correlate CPU, Metal, display/vsync, and
thread-state tracks over the same emulated-frame interval. CPU optimization
continues, but a 60-fps claim still requires the renderer/presentation tail to
meet 16.7 ms.

## Compiler/tool conclusions

- Frontend instrumentation PGO and ThinLTO remain useful and supported, but
  they are already active and do not close G5.
- Whole-module IR PGO and a Mach-O order file were measured and rejected in
  PERF-073/PERF-074; repeating them is not justified.
- LLVM BOLT supports x86-64 and AArch64 **ELF** input, not this arm64 Mach-O
  product, so it is not a direct macOS solution.
- Sampling PGO is possible in LLVM, but `llvm-profgen`'s documented inputs are
  Linux perf or ARM ETM traces. On this M1 Mac, Apple's low-overhead Processor
  Trace is also unavailable because Apple documents M4-or-later hardware.
  Time Profiler and CPU Counters are the applicable local tools.

## Primary references

- QEMU Translator Internals, direct block chaining and invalidation:
  <https://www.qemu.org/docs/master/devel/tcg.html>
- QEMU TCG IR, basic and extended basic blocks plus live temporaries:
  <https://www.qemu.org/docs/master/devel/tcg-ops.html>
- LLVM ThinLTO documentation:
  <https://clang.llvm.org/docs/ThinLTO.html>
- Clang profile-guided optimization documentation:
  <https://clang.llvm.org/docs/UsersManual.html>
- LLVM BOLT input requirements:
  <https://github.com/llvm/llvm-project/blob/main/bolt/README.md>
- Apple Game Performance analysis:
  <https://developer.apple.com/documentation/xcode/analyzing-the-performance-of-your-metal-app/>
- Apple CPU bottleneck analysis:
  <https://developer.apple.com/documentation/xcode/addressing-cpu-bottlenecks>
- Apple Processor Trace hardware requirements:
  <https://developer.apple.com/documentation/xcode/analyzing-cpu-usage-with-processor-trace>

## Next gate

PERF-077 is a data-only preflight, not a full game build. It passes only if the
inline guard preserves invalidation and fallback semantics and its measured
cost projects more than a 5% CPU-thread improvement over the callback design.
Otherwise, skip the broad linked module and implement one profile-derived
superblock with boundary-only guards.
