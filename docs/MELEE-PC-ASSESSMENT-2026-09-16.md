# melee-pc comparison and Apple performance assessment

Assessment date: September 16, 2026.

**Second-pass correction:** the [performance evidence audit](MELEE-PC-SECOND-AUDIT-2026-09-16.md)
withdraws the priority ranking below. These are architectural hypotheses,
not demonstrated improvements. No proposed import currently qualifies as a
performance upgrade for MeleePad.

**Recommendation: borrow selected techniques; retain MeleePad's current engine.**
melee-pc offers a credible alternative architecture and useful graphics/porting
examples. This assessment establishes neither that it is faster than MeleePad
on Apple hardware nor that its game code is safe to copy into our distribution.
The strongest new performance lead is reducing iOS software vertex decoding,
followed by a measured, larger graphics-command boundary optimization. A full
native-source port should be treated as a separate engine project.

## Scope and exact inputs

- Downloaded a shallow source checkout, including its vendored Aurora, to
  `/Users/chrissotraidis/GitHub/melee-pc-assessment-20260916` (about 52 MiB).
- Inspected melee-pc commit
  [`a64b6ad96c48f72eb26a41ef172581a7b1c2d262`](https://github.com/999sian/melee-pc/tree/a64b6ad96c48f72eb26a41ef172581a7b1c2d262).
  Its commit date is September 16; latest listed prerelease at inspection was
  `v0.1.5-beta`. HEAD and that prerelease must not be assumed identical.
- MeleePad HEAD: `5d498004c71923af9f989a751448ed302cf777e2`, with existing dirty
  Slippi/application/build work inspected in place and preserved.
- Local ModernGekko: `048c426ba3db0369e40826d22ad3adcce7fe7c58`;
  its active `vendor/dolphin`: `e13ab348f13cd67879f6db6e9d7185410f8f62c6`,
  with local patches. The separate `vendor/dolphin_legacy` directory is not
  the build input used for the final comparison here.
- melee-pc's vendored Aurora records upstream base
  `d0c931da2ed3f41d0e42736c2ab52a78c7cf1a9d`; the enclosing melee-pc commit
  identifies the actual modified code reviewed.
- Read build rules, endian/pointer conversion, archive relocation, GX command
  handling, vertex upload/shader access, render queue, pipeline cache, native
  math, audio, file cache, pacing, test tools, licensing, releases and open issues.
  This is a targeted engineering assessment, not a line-by-line audit of all
  2,705 tracked files.

No existing app, game module, game data, save, Simulator, physical device,
release or dependency pin was changed. Only this report, aggregate evidence,
and isolated research files were added. No foreign implementation was copied
into MeleePad's production code.

## What is different, and what is actually better?

| Area | melee-pc at the inspected commit | MeleePad at the inspected checkout | Assessment |
|---|---|---|---|
| Game execution | Compiles adapted decompiled C into native game functions | Compiles translated PowerPC code; preserves guest CPU state and console behavior | Their approach can remove register-state, dispatch and instruction-modeling work. Architectural potential, not a measured Apple speed advantage. |
| Graphics | Native GX services, Aurora command processing and Dawn/WebGPU | Dolphin-derived GX command processing with Metal | Different tradeoffs. Both still process graphics commands; Aurora is not a complete elimination of FIFO/decoding. |
| iOS vertex processing | No demonstrated iOS integration in this checkout; Aurora supports shader reads from uploaded indexed arrays | iOS explicitly selects the portable software decoder to avoid Dolphin's runtime-generated ARM64 decoder | The clearest Apple-specific technique to investigate. |
| Apple deployment | macOS remains listed as in development; stock CMake rejects Apple Clang | Existing native macOS and iOS integration, lifecycle, controls and local build pipeline | MeleePad is the stronger existing Apple integration baseline. |
| Game coverage | README claims VS, Classic, Adventure, All-Star, Stadium, saves and other modes | Existing gameplay, saves, multiple revisions, plus documented rendering/performance debt | Their broader mode claims are useful test targets, not independently verified superiority. |
| Online | Rollback, replay export, UCF and matchmaking remain roadmap work | Experimental fixed-delay release path and separate local Slippi work | Replacing the engine would jeopardize existing integration; theirs is not a Slippi upgrade. |
| Distribution model | Builds game code from decompilation, loads assets from the user's disc | Public shell, locally generated private game module | Their simpler executable delivery has a different source-rights situation; it is not interchangeable with ours. |

Their [pinned README](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/README.md)
is the source for feature/status claims. The web-rendered page encountered
during research was older than the downloaded README, so the pinned checkout
controls this report. High-refresh interpolation is roadmap work, not a
demonstrated 120/144/240 Hz implementation at this snapshot.

## Apple portability: tested blockers, not just build flags

**Compiler/endian conversion.**
[CMakeLists.txt:9–12](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/CMakeLists.txt#L9)
requires GCC because its on-disc structures use `scalar_storage_order`.
An actual stock configure using installed Apple Clang 21 stopped at this check,
before fetching the large renderer dependencies.

A small host probe included their actual `src/pc/disc.h`, copied synthetic bytes
`12 34 56 78` into `DiscU32`, and read the field. Apple Clang warned that the
attribute was ignored and returned `78563412`, instead of `12345678`.
Suppressing the warning or removing the CMake guard therefore produces incorrect
data interpretation. This affects nested records, scalar arrays and bitfields,
not merely a few calls to byte-swap. Their Android GCC launcher targets the
Linux-hosted Android NDK sysroot; Android ARM64 support does not solve Apple
Clang/Mach-O support.

**Pointer and archive layout.**
Their `disc.h` has an external-pointer handle table, so it is inaccurate to say
every pointer must fit below 4 GiB. However, archive relocation still checks for
a low-address archive allocation and adds that address into 32-bit slots:
[archive.c:13–24](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/src/sysdolphin/baselib/archive.c#L13).
Windows/Linux have specialized low-memory allocators; Apple's path falls back
to `calloc`. The desktop link rules also use non-PIE/ELF-style placement options.
This is an unresolved Apple allocation/relocation design, not evidence that a
Mac port is impossible. The external handle table alone does not repair it.

**Renderer support exists below the game layer.** Aurora contains a real
`MetalBinding.mm`. The problem is not an absence of Metal in WebGPU: it is
integrating this game port's data model, build, native window/surface, lifecycle,
input and audio. MeleePad's UIKit/AppKit shell can potentially be retained, but
its engine interface would need adaptation.

[Issue 37](https://github.com/999sian/melee-pc/issues/37) reports a contributor
getting a fork into the game on macOS; the maintainer requests a PR and says
they lack a Mac to test. That is a useful lead, not a tested Apple solution in
the assessed checkout. No open PR was returned by the API during inspection.

## Ranked reuse opportunities

### 1. Reduce iOS vertex decoding work — highest-value new investigation

Our `ref/ModernGekko/src/runtime/dolphin_runtime.cpp:539–547` explicitly forces
`VertexLoaderType::Software` on iOS. Dolphin's native ARM64 vertex loader
generates executable code, so switching that setting is not an acceptable
ordinary iOS solution. This restriction is conditional on iOS; do not assume
the same decoder cost on macOS.

Aurora's
[command_processor.cpp:386–400](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/extern/aurora/lib/gx/command_processor.cpp#L386)
uploads indexed source arrays into storage buffers and reuses their uploaded
ranges. Its shader generator fetches packed/indexed attributes. Native
`GXSetArray` supplies an explicit byte extent and endian flag; melee-pc's
`src/pc/vtxarray.c` obtains extents by scanning model display lists at load time.

**How to incorporate the learning:** profile our decoder by vertex format and
vertex count, then choose one of two bounded prototypes: a statically compiled
decoder for the dominant formats, or an optional Metal vertex-fetch path for
those formats. Keep the existing decoder as the fallback. This can preserve
the existing engine and avoid replacing all graphics with Dawn.

There is no drop-in scanner: our boundary supplies guest addresses, not their
native HSD objects. Array extents, guest-memory translation and mutation must be
handled explicitly. Validate NBT3's three indices, matrix indices, endian
conversion, clipping/bounding-box side effects, dynamic skinning, particles,
memory reuse and cache invalidation. A pointer alone is not a durable cache key.
Aurora itself resets ranges on vertex invalidation and relevant array changes.

Expected benefit: potentially less CPU time and thermal load on iOS. Magnitude
is unknown until profiling and matched gameplay measurements. Extra buffer
uploads or GPU fetches could outweigh the savings, especially on macOS.

### 2. Optimize a coherent graphics-command boundary — larger potential, higher risk

Native calls avoid executing translated SDK instruction sequences and guest
register marshalling. But their
[GXCallDisplayList](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/extern/aurora/lib/dolphin/gx/GXDispList.cpp#L49)
still writes and publishes command data; Aurora also has its own command
processor and worker queue. The lesson is coarser host work with controlled
ordering, not simply deleting the FIFO.

Our previous [GX upload experiment](NATIVE-PORT-LEARNING-GOAL.md) already passed
6,000 differential cases and improved isolated helpers, but its Simulator pair
did not support promotion. The [matrix experiment](IPHONE-SCENE-PERFORMANCE-GOAL.md)
also failed to establish a repeatable physical improvement. This new repository
does not overturn those results.

First measure translated GX setup, useful video decoding, status polling and
blocking independently in the same scene. If a larger command sequence is
dominant, prototype one revision-checked native service that preserves the
ordered FIFO byte stream, guest state visible at callbacks and cycle/interrupt
behavior. Direct renderer-state bypass would be a separate, more invasive
design. Unknown entry points and patched Slippi code must retain the old path.

### 3. Pipeline preparation and bounded render queues — compare policies

Aurora has a bounded worker queue, frame-slot ownership, asynchronous pipeline
creation, and a versioned persistent cache with first-use ordering. These are
useful references for queue pressure, cold-start hitches and resource lifetime.
They are MIT-labelled Aurora components, not the game's GPL platform layer.

MeleePad already enables shader caching, asynchronous ubershaders and startup
shader preparation. Our active `VideoCommon/ShaderCache.cpp` already loads and
compiles pipeline UIDs. Adding a second cache or wholesale renderer replacement
is unjustified. Instrument cold and warm paths before changing policy.

The prior [Metal cost screen](NATIVE-PORT-LEARNING-GOAL.md) measured low average
pipeline creation and presentation costs in its selected combat trace; that is
historical evidence against making these our first sustained-FPS target.
Conversely, [issue 46](https://github.com/999sian/melee-pc/issues/46) reports
multi-second first-use freezes in melee-pc. The reporter suspects shaders, but
the cause is not established. Cache presence alone does not prove smooth play.

### 4. Native math — reusable in isolation, little new here

Compiled their actual Aurora `mtx.c` plus `vec.c` with Apple Clang for ARM64 and
ran identity multiplication and both exact-alias cases successfully. This only
proves that those host routines compile and satisfy three small cases; it is
not guest floating-point equivalence or an FPS benchmark.

More significantly, `mtx.c` is byte-identical to the Aurora copy already under
our active dependency's `GXRuntime/graphics/aurora`. It is not a new optimized
matrix implementation. Having that library in the tree also does not mean our
translated game already calls it. Their `vec.c` differs in `PSVECSquareMag`,
including explicit `fmaf`; operation order and PPC semantics require independent
checks before use. Preserve exceptional values, paired-single state, aliasing,
callbacks and rollback behavior. Do not repeat a generic leaf-math sweep.

### 5. File prefetch — loading optimization only, reimplement carefully

Their new `src/pc/file_cache.cpp` provides raw-archive caching, priority prewarm
and LRU eviction. This can inspire prefetch of the selected stage/fighters if
our I/O traces identify a real loading bottleneck. It does not explain or cure
sustained combat execution below game speed.

The current implementation should not be copied unchanged:

- Its >4 GiB system-memory profile defaults to a 512 MiB cache. Device RAM is
  not an appropriate proxy for an iOS app's available memory budget.
- Pinned entries bypass eviction. After attempting eviction, oversized unpinned
  entries are still inserted. A host probe of the actual implementation set a
  1 MiB budget, inserted a synthetic 2 MiB archive and observed 2 MiB usage.
  The advertised budget is therefore not a hard cap.
- `pc_file_cache_get` copies the entire entry without receiving a destination
  capacity. Any adaptation needs an explicit size contract.
- Prefetch uses detached threads; lifecycle/cancellation and memory-pressure
  behavior need deliberate integration with our app.

An Apple implementation should bound both resident bytes and worker activity,
cancel on scene changes/backgrounding, and respond to memory pressure. Test
against the existing extracted-directory/OS-cache path first.

### 6. Audio, controls and visual features — references, not speed fixes

Their software AX mixer implements 64 voices at 32 kHz in 160-sample blocks,
plus effects and native streaming. It belongs to their replacement SDK; it is
not an audio-buffer patch for our Dolphin-derived runtime. Our observed audio
starvation during slow game execution needs the underlying throughput fixed.
A mixer replacement requires independent mixing, scheduling and save/rollback
validation before any CPU advantage can be claimed.

Widescreen/HUD changes, remapping, texture replacements and custom music are
product ideas. They add functionality and sometimes work; they are not evidence
of better iPhone frame times. Some GX functions are stubs in `src/pc/gx.c`,
including draw-sync tracking and fog-table approximation, so copying their
simplifications could trade away correctness we currently preserve.

## Whole-engine migration and Slippi

A direct-source engine could eventually remove more overhead than isolated
translated-function optimizations. That makes it worth tracking, but an
integration requires an Apple-compatible data model, complete native GX/audio
services, app lifecycle, input, persistence, correctness tests and performance
tests. Initially it would support their v1.02 target, not automatically our
retained v1.00 path.

Slippi's injected PowerPC code, guest addresses, EXI integration, snapshots and
restore behavior do not follow native C structures automatically. Native
objects, pointer registries, audio state and host callbacks can live outside
MEM1; copying MEM1 alone is not a complete rollback design. Their roadmap's
rollback aspirations are not an implementation we can inherit.

Our [local Slippi validation](SLIPPI-SIMULATOR-LONG-PASS-2026-09-15.md) records
actual local correction/replay work, with official-client/Internet/physical
acceptance still separate. Preserve that work when evaluating an offline
alternate engine.

For an eventual source-port experiment, compare the existing local
`ref/melee-native-alpha1` research too: it already documents native asset
materialization and Apple layout fixes. This is not a recommendation to restart
that port or assume its older state remains current. It is a reason not to
begin by forcing Linux low-address assumptions into iOS.

## Reuse and attribution

The upstream [LICENSE.md](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/LICENSE.md)
explicitly distinguishes:

| Material | Repository's stated terms | Practical assessment |
|---|---|---|
| `src/melee/`, `src/sysdolphin/` | Decompiled Nintendo/HAL game code; no permission offered | Do not treat the repo's GPL badge as permission to copy these files. |
| `src/pc/`, tools/platform/build infrastructure | GPL-3.0-or-later | A candidate reuse needs exact-file provenance, notices and review of the combined distribution's source/license obligations. Credit alone does not settle them. |
| Vendored Aurora | MIT; retain its copyright/license notice | Prefer applicable standalone components or upstream contributions, while checking individual file provenance. |
| SDL, Dawn, fonts and other dependencies | Separate licenses | Preserve applicable notices when actually redistributed. |

This records upstream's expressed permissions, not a legal-clearance opinion.
Supplying one's own disc does not itself resolve the decompiled-source issue.
MeleePad's active Dolphin files carry GPL-2.0-or-later notices; do not casually
import a GPL-3.0 platform snippet without reviewing the exact combined work.

If only an idea is independently implemented, describe it accurately as
inspired by their approach. If actual code is included, name the component,
files, upstream commit and modifications, retain required notices, and include
the applicable license/source material. Saying that we use parts of melee-pc
would currently be false: this assessment integrates no production code.

## Concrete next experiment and decision gates

1. Establish a repeatable v1.02 combat fixture: identical initial state, RNG,
   frame-indexed input, roster/stage, resolution and settings. Demonstrate
   control-versus-control repeatability. Report results-screen work separately.
2. Profile normal MeleePad on native macOS and physical iOS separately. Measure
   translated game/GX work, vertex decoding, command processing/polling, GPU busy
   time, pipeline stalls and I/O. Use a separate profiled run so its overhead is
   not counted as normal gameplay performance.
3. If software vertex decode is material on iOS, implement one optional,
   precompiled format path with existing-decoder fallback. If command dispatch
   dominates instead, choose one larger byte-preserving native boundary.
   Select one candidate from the measured result, not both simultaneously.
4. Compare decoded outputs and all relevant side effects, then exercise dynamic
   objects, invalidation, transitions and the existing rollback path. Reject
   stale caches, visual regressions or state divergence.
5. Run matched-temperature physical A/B and reverse-order confirmation. Record
   simulation progress, mean/p95/p99 frame time, slow frames, audio underruns,
   memory and thermal state. For the capped Mac case, compare work/headroom and
   tails as well as FPS. A reasonable proposed promotion screen is a repeated
   >=5% reduction in the selected CPU-bound combat workload with no material
   tail/audio/correctness regression; this is a future gate, not a result.

Do not use these observations to promote the previously rejected matrix/GX
candidate, change floating-point flags globally, bypass the Clang check, increase
all cache budgets, or swap out the engine. A separate macOS source-port prototype
becomes justified only after its endian/pointer feasibility is demonstrated and
the integration cost is accepted as a different project.

## Executed checks and limits

| Check | Observed result | What it establishes |
|---|---|---|
| Stock CMake + Apple Clang | Rejected at the explicit GCC requirement | No stock native Apple build through this configuration |
| Actual `DiscU32` header + synthetic bytes | Read `78563412`; expected `12345678` | Ignoring the storage-order attribute breaks this data path |
| Actual Aurora matrix/vector sources | Identity and two exact-alias cases passed on ARM64 | Small standalone native component can compile/run |
| Actual file-cache source + synthetic archive | 1 MiB budget admitted 2 MiB | Budget is not strictly enforced for an oversized entry |

[Aggregate check results](artifacts/melee-pc-assessment-2026-09-16/checks.json)
contain no game data. Probe sources, commands embodied in CMake state, executables
and logs are retained privately under `ref/melee-pc-assessment-20260916/`.
The cache probe links the actual source with dead-code elimination and an
`OSReport` stub; it does not run disc prefetch or emulate the full application.

No full melee-pc build, graphics test suite, gameplay run, Apple FPS comparison
or physical-device acceptance was performed. Runtime claims in their README
remain upstream claims. The open [Home-Run Contest crash report](https://github.com/999sian/melee-pc/issues/48)
and first-use freeze report are additional regression targets, not reproduced
findings here. No percentage improvement for MeleePad is established by this
assessment.
