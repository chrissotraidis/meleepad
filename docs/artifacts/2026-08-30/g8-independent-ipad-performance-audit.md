# G8 independent iPad performance audit (row 7)

Date: 2026-08-30

Status: **AUDIT-232 read-only audit; three named mechanisms; no product change made**

Scope: independent, evidence-driven audit of what will make the iPadOS/iOS
path sustain 60 FPS with stable audio. Sources: retained G8 evidence,
host-PGO exact profile counts, live telemetry, the StaticRecomp core, the
generated GALE01 module source, the runtime configuration, the Metal and
audio paths, and the build scripts. No file was edited, no Simulator booted,
no game data touched. All claims below are falsifiable and cite their source.

## Verified state assumed by this audit

- Non-PGO iPad control: ~37-40 FPS in demanding four-character scenes.
- Exact-source module PGO: ~42-48 FPS; CPU-GPU 91-100%; underruns accumulate.
- Host-runtime PGO (non-PGO module): live intervals 59.0 / 59.5 / 59.9 /
  54.5 / 60.1 FPS; underruns still accumulate.
- The 323,820,968-byte module seen in the very slow app was the
  instrumentation build (19-55 FPS is profiling overhead, not the candidate).
- A fresh 6,537-function exact-source combat profile exists; the plan of
  record is a combined host+module PGO reversal on a fixed path.

## A. Executive diagnosis: three most probable remaining bottlenecks

### A1. Per-instruction interpreter-fallback round trips (new, measured, unaddressed)

The host-PGO profile (`docs/evidence/g8/ipad-host-pgo-live-summary.txt`) is
internally inconsistent with a healthy dispatch loop:

- `SyncIn` = `SyncOut` = 119,117,581 calls.
- `ChunkIndexOf` (1,350,590,498) − `FastDispatchableAt` (1,331,646,004)
  bounds `DispatchableAt` — and therefore burst entries — at **≤ 18,944,494**.
- There are exactly three `SyncIn` call sites in the entire tree:
  burst entry (`StaticRecompCore_Run.cpp:101`), the host-call branch
  (line 186), and `HookInstructionFallback`
  (`StaticRecompCore_Hooks.cpp:403`). `host_call` is null on iOS (no mods
  are configured; `dolphin_runtime.cpp` only sets it when mods load).

Therefore **~100M sync pairs per training session came from
`HookInstructionFallback`** — about 7.5% of all dispatch-loop iterations,
roughly 8,800/frame at the macOS dispatch rate. Each one pays a full
~700-byte `SyncOut`, an interpreted `SingleStepInner`, a full `SyncIn`,
plus `MSRUpdated`/`RoundingModeUpdated`/`ppc_fpscr_updated` (host FPCR
writes) both ways. At even 300-600 ns each that is **2.5-5 ms of every
frame**, hidden inside the `StaticRecompCore::Run` inclusive branch that
the samples attribute to "static-core cost". PGO shrinks these function
bodies but cannot remove work that is architecturally executed.

Static corroboration: 325 `ppc_fallback_instruction` sites survive in the
current generated chunks, dominated by supervisor `mtspr`/`mfspr` forms —
including **`mtspr DMAU` / `mtspr DMAL` (locked-cache DMA;
`0x7CDAE3A6`/`0x7CDBE3A6` at guest `0x80343138`/`0x80343148`) inside the
hot chunk `chunk_0208_text1_80341940.c`**. Locked-cache DMA feeds Melee's
HSD matrix pipeline. The macOS cache-control parity fix already closed this
exact defect class once for `dcbf`/`dcbst` and was worth −12% mean frame
time; the SPR family never received the same treatment. macOS shutdown
counters show `hook_fb=13,688` for a whole session — the iPad workload is
orders of magnitude worse if the inference holds.

### A2. Single-core CPU-GPU serialization is a configuration choice

The app logs `cpuVideoSplit=0`. The vendored Dolphin sets
`DEFAULT_CPU_THREAD = false` for all non-Android platforms
(`Source/Core/Core/Config/MainSettings.cpp:61-65`) and the runtime never
sets `MAIN_CPU_THREAD`. Guest execution, GX opcode decode, the software
vertex loader, EFB work, Metal encoding, and audio production all share the
one thread measured at 91-100% in combat. The macOS "dual-core has direct
reversals" rejections were made in a regime where CPU was inside budget and
the tail was wall/vblank; they do not transfer to a throughput-saturated
thread. Upstream Dolphin ships dual-core as the Android default for exactly
this situation. The 91-100% single-thread saturation is the new,
platform-specific contrary evidence the loop's rules require to reopen it.

### A3. The 54.5 FPS dip is a wait/GPU problem, not CPU throughput

The dip interval shows **CPU-GPU at 67.6%** while the 59.5 FPS interval
shows 97.5% — the thread was waiting, not computing. The configured
pipeline: `AsynchronousUberShaders` + `GFX_SHADER_COMPILER_THREADS`
default **1** + Simulator-only **framebuffer fetch disabled** (patch
`0027-ios-simulator-disable-framebuffer-fetch.patch`). During transitions,
new pipeline configs draw via ubershaders (heavier GPU cost, heavier still
on the Simulator's non-fetch blending path) while a single worker compiles
specialized MSL pipelines through the slow Simulator compiler service. GPU
over budget → drawable backpressure → CPU idles → FPS dips → audio
production on the same thread's timeline falls behind. When compiles land,
the dip ends.

Audio addendum: underruns during 59-60 FPS intervals are largely
hysteresis. After starvation the mixer re-enters prebuffering and the
adaptive rate is clamped to ±2% (`AudioCommon/Mixer.cpp:104-115`), so the
~60 ms queue refills over many seconds while the cumulative counter keeps
ticking. The queue itself is a lock-free SPSC granule ring with no locks or
copies of note; callbacks are proven alive. Audio is a consequence plus
hysteresis, not an independent cause.

## B. Evidence table

| # | Mechanism | Supporting evidence | Conflicting evidence | Estimated ceiling | Confidence |
|---|---|---|---|---|---|
| 1 | `HookInstructionFallback` full-sync round trips (~8.8K/frame inferred) | Exact profile counts (SyncIn 119.1M vs DispatchableAt ≤18.9M); only 3 SyncIn sites; host_call null on iOS; static DMAU/DMAL/SPRG fallback sites in hot chunk 0208 | macOS sessions show hook_fb only ~14K/session; iPad per-frame number inferred, not yet read from the iPad's own shutdown line | 2.5-5 ms/frame | Medium-high (count arithmetic); medium (cost) until E1 confirms |
| 2 | Single-core CPU-GPU serialization | `cpuVideoSplit=0`; `DEFAULT_CPU_THREAD=false`; thread at 91-100%; GX/Metal/audio all inline | macOS dual-core rejections (different regime); determinism cost for later netplay; lockstep interplay untested | Frees the video+audio share of the saturated thread (~42% of samples sit outside `Run` inclusive, plus GX work nested inside it via the gather-pipe hook) | High (existence); medium (net win) |
| 3 | Ubershader/pipeline-compile GPU spike, Simulator-amplified | 54.5 FPS @ 67.6% CPU (wait-bound); 1 compiler thread; patch 0027 no-FB-fetch | Host contention on the M1 could also produce a wait-bound dip; "AsyncShaderCompiler appeared" comes from a private sample | Recovers the ~5 FPS dip class only | Medium |
| 4 | Generated FP semantics cost (out-of-line FPSCR-exact `ppc_*` helpers per guest FP instruction) | ~89 host bytes/guest instruction (func_80015940 = 363,516 B per 16 KB guest text); module ThinLTO+PGO already applied | This is the semantic contract; lax variants have prior correctness rejections | Large but locked behind semantics — treat as floor, not target | High |
| 5 | Per-dispatch host ladder (cross-TU `ShouldCheck`, 24 MB lookup table, freeze-trace compares, always-on sample map, per-slice `GetGameID`) | 1.33B `ShouldCheck` calls/session; 220 `FastDispatchableAt` + 60 `ShouldCheck` top-of-stack samples (~4.3%); source inspection | Host PGO already shrank the bodies; each item individually sub-ms | 0.5-1.5 ms/frame combined | High existence, medium size |
| 6 | Simulator-vs-device penalty | Host verified as Apple M1, 8-core, 16 GB, simulating an "iPad Pro (M5)"; CPU at M1 speed; translated GPU; no FB fetch; Simulator-service shader compiles | Cannot be quantified without hardware; device deployment is outside the loop's rules | A real M5 iPad is plausibly 1.6-1.8× M1 single-core — potentially the 48→60 gap by itself | High existence; unknowable size |
| 7 | Audio callback/queue mechanics as independent cause | — | Lock-free SPSC ring; callbacks alive; underruns only on empty dequeue; prebuffer+clamp explains counter growth during recovery | ~0 | High |

## C. Ranked experiments

**E1 — Read the counters that already exist (cost ~zero; do first).**
Every clean shutdown prints
`[staticrecomp] shutdown: native=… fallback=… hook_fb=… bursts=…`
(`StaticRecompCore.cpp:214`). On the next iPad run (the already-planned
combined-PGO reversal), retain that line, plus one phase-logged interval
for the per-opcode fallback split patch 0006 already counts
(`AddStaticRecompFallback` buckets). Accept A1 if `hook_fb` is 10^7-10^8
per session (thousands/frame); reject if ~10^4 and re-derive the SyncIn
excess (re-check host-call sources and training-run shape). Rollback: none.

**E2 — Combined host+module PGO reversal on a fixed heavy path (keep the
plan of record).** Accept: the previously-54.5-class scene sustains
≥59.5 FPS AND the DMA-underrun **delta** over ≥60 s of continuous combat is
zero after prebuffer refill. Reject: underruns still accumulate → residual
is structural (E3/E4/E5). Use per-interval underrun deltas with queue
depth, never the cumulative counter.

**E3 — Specialized no-sync handling for the top fallback opcodes (gated on
E1).** Mirror the cache-control parity fix: teach DolRecomp's C backend
(new patch in `patches/dolrecomp/`) to emit direct calls for the supervisor
`mtspr`/`mfspr` family — DMAU/DMAL (locked-cache DMA), SPRG0-3, HID —
into the existing `spr_write`/`spr_read` hooks, which already implement
DMAU/DMAL DMA semantics without any state sync
(`StaticRecompCore_Hooks.cpp:280-294`). Regenerate the module. Expected:
per-frame `hook_fb` collapses toward zero. Accept at ≥5% frame-time gain vs
the E2 candidate on the fixed path. Semantic gate first: focused test that
hook-routed DMAU/DMAL matches the interpreter (the lockstep harness exists
for exactly this). Rollback: revert the dolrecomp patch, regenerate.

**E4 — Dual-core reversal on iPad (`MAIN_CPU_THREAD=true`), one
experimental flag.** Expected: CPU-GPU thread drops well below 90%; FPS and
audio decouple from Metal encode time. Accept: sustained ≥59.5 with zero
underrun delta and no FIFO desync/hang over a full demo cycle; reject on
any correctness artifact (journal the result either way — it previews the
netplay-determinism cost). Rollback: remove the flag.

**E5 — Shader-dip attribution and mitigation.** The app's
`diagnosticSummary` already exposes `vertexShadersCreated` /
`pixelShadersCreated` / `shaderChanges`. Capture its delta across the dip
scene; accept the ubershader/compile explanation if pipelines are created
mid-dip. Then, one variable at a time: raise `GFX_SHADER_COMPILER_THREADS`
1→3 (idle cores exist; the saturated thread doesn't compile), and verify
the Dolphin pipeline-UID cache persists across Simulator relaunches in the
app container (if the reinstall cadence wipes it, every session pays cold
compiles). Rollback: config-only.

**E6 — Release-hygiene batch in the dispatch loop.** (a) Delete the
`[freeze-trace]` per-dispatch PC compares/fprintf
(`StaticRecompCore_Run.cpp:105-108`) — debug leftover in the innermost loop
of every build; (b) gate the always-on `m_dispatch_samples` unordered_map
behind the existing env-var pattern (lines 115-121); (c) hoist the lockstep
check to a cached bool in `Run` so 1.33B cross-TU `ShouldCheck` calls
become a register test; (d) replace the per-slice `SConfig::GetGameID()`
recursive-mutex + string copy (line 91) with a change-callback; (e) guard
`RoundingModeUpdated` in `SyncOut` on actual FPSCR change (it writes host
FPCR unconditionally); (f) shrink the 24 MB per-instruction
`m_chunk_lookup_table` to a `>>14` tile table (~1,500 entries, permanently
L1-resident). Measure as one candidate with a matched fixed-path reversal;
accept at ≥2%, but land (a) regardless as debug-code removal.

**E7 — Burst/state-residency and dispatch batching (deprioritized until
E1).** If bursts are only ~1,600/frame, burst-boundary sync is ~3 MB/frame
of copying — real but second-order behind E3. `dolrecomp_run_blocks`
(module-side loop, no runtime codegen) exists if the per-dispatch ladder
survives E6, but the per-dispatch downcount flush is a documented
interrupt-latency contract — change only with the CachedInterpreter-parity
argument written down.

## D. Do-not-repeat list (already rejected with retained evidence)

- Host-core ThinLTO (PERF-222). Generated-module `-O3` / native tuning
  (PERF-226, PERF-086). Stale/partial PGO profiles (AUDIO-220).
- Audio reserve growth beyond 120 ms (AUDIO-220). Software vertex-loader
  optimization (bounded ~2.6% of thread samples).
- Frame-pointer omission (PERF-213); `preserve_most`/dispatcher frame split
  (PERF-212); sample-based PGO (PERF-211); source-weight/FP-trace codegen
  variants (PERF-088/132).
- Runtime-generated executable memory in any form (product boundary).
- macOS display/scheduler rejections (drawable pools, Rush, fixed policy,
  display link): do not relitigate, and do not cite them against iPad
  CPU-side work — different bottleneck regime.

## E. Specific files/functions

| Area | Path |
|---|---|
| Hot loop, freeze-trace, sample map, GetGameID | `ref/ModernGekko/vendor/dolphin/Source/Core/Core/PowerPC/StaticRecomp/StaticRecompCore_Run.cpp` |
| Fallback hook full sync; DMAU/DMAL hook semantics | `…/StaticRecomp/StaticRecompCore_Hooks.cpp` |
| State copies; unconditional FPCR update | `…/StaticRecomp/StaticRecompCore_Sync.cpp` |
| Lookup table, dispatchability | `…/StaticRecomp/StaticRecompCore_SMC.cpp` |
| Lockstep gate | `…/StaticRecomp/StaticRecompLockstep.cpp` (`ShouldCheck`) |
| Fallback sites in generated code | `ref/ModernGekko-Template/extracted/…/generated/chunks/chunk_0208_text1_80341940.c` (also 0201, 0229); census via `grep ppc_fallback_instruction` |
| Memory/FP helper layer (`g_mem_write_journal` test per store) | `ref/ModernGekko/vendor/dolphin/GXRuntime/include/core/cpu.h` |
| Runtime config (no `MAIN_CPU_THREAD`; shader mode; audio) | `ref/ModernGekko/src/runtime/dolphin_runtime.cpp:487-533` |
| Single-core default | `ref/ModernGekko/vendor/dolphin/Source/Core/Core/Config/MainSettings.cpp:61-65` |
| App thread/QoS/idle-PC/config | `apple/ios/MeleePadCoreHost.mm` |
| Simulator FB-fetch, audio diag, fallback opcode counters | `patches/moderngekko-dolphin/0027-…`, `0028-…`, `0006-…` |
| iOS underrun/prebuffer behavior | `ref/ModernGekko/vendor/dolphin/Source/Core/AudioCommon/Mixer.cpp:560-660` |

## F. Single best next experiment after combined host+module PGO

**E1→E3 as one arc:** read the `hook_fb`/`bursts` shutdown counters from
the combined-PGO run; if `hook_fb` confirms thousands per frame, land the
specialized SPR/locked-cache-DMA fallback elimination. It is the only
remaining candidate that is (a) named by exact profile counts rather than
samples, (b) structural — PGO provably cannot remove it, (c) precedented —
the identical fix shape (cache-control parity) produced the project's
largest retained win (−12% mean frame time), and (d) gateable before any
live replay. Dual-core (E4) has a larger ceiling but a wider blast radius;
run it second, informed by how much E3 recovers.

## G. Flaws and uncontrolled variables in the existing evidence

1. The FPS intervals are hand-read telemetry over an advancing demo, not
   fixed-path brackets; the host-PGO result is n=5 intervals.
2. The 54.5 FPS interval is labeled "shader-heavy" without retained
   shader-counter evidence; 67.6% CPU is equally consistent with host
   contention on the M1 (documented history: PERF-169/183). E5 settles it.
3. The "14.48% host-only opportunity" ratio comes from a 10-second `sample`
   capture with hook-nested video work and dylib unwinding loss; the
   direction is justified, but do not build further percentages on it.
4. The cumulative underrun counter overstates ongoing failure: every empty
   dequeue during prebuffering recovery increments it. Report per-interval
   deltas with queue depth.
5. **All iPad numbers are M1 numbers.** The Simulator runs at host-CPU
   speed through translated Metal without framebuffer fetch. Stop phrasing
   Simulator results as "iPad Pro (M5)" results; a Simulator pass is strong
   evidence for device viability, a Simulator miss is a conservative proxy.
6. Sample attribution conflates guest compute with inline video work: in
   single-core mode, gather-pipe writes run GX decode and Metal encoding
   inside the `chassis_dispatch` inclusive branch.
7. **Correctness/performance coupling with the warp defect:** the warp
   reproduces on macOS (JIT vertex loader) and iOS (software loader), so it
   originates in shared guest-FP/paired-single or GX-runtime code — the
   same HSD matrix/GX region that dominates combat samples and that E3
   touches (locked-cache DMA feeds the matrix pipeline). Visually reverse
   every fallback-elimination or FP-helper change against the known warp
   signature; re-baseline performance after the warp fix lands; do not
   resurrect semantically relaxed FP/matrix fast paths while it is open.

## Constraints restated for the executor

Read-only inputs stay read-only; never commit or expose the ROM, extracted
assets, generated module, saves, profraw/profdata, or private paths. One
variable at a time; fixed-path reversals; distinguish instrumentation,
optimized-candidate, Simulator, and expected-device performance. Netplay
remains later work. Runtime-created executable memory stays out of the
product path.
