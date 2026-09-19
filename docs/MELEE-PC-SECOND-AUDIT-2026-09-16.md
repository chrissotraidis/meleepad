# melee-pc second audit: does any proposed reuse actually help MeleePad?

September 16, 2026. Same pinned melee-pc source as the first assessment:
`a64b6ad96c48f72eb26a41ef172581a7b1c2d262`.

**Result: no production performance change is justified by this audit.**
The first pass correctly identified architectural differences, but it ranked
vertex decoding too confidently without measuring its share of our workload.
This pass withdraws that ranking. It adds source checks, reanalysis of physical
iPhone profiles, two fresh native Mac attribution runs and a floating-point
differential test. No melee-pc implementation has been incorporated into the app.

## 1. Actual iPhone evidence makes the vertex proposal less compelling

Reprocessed the original Time Profiler XML from two retained v1.02 four-fighter
Big Blue investigations. These are historical physical iPhone captures, not
new measurements on the currently installed build. Their original provenance
and limitations are in [the iPhone performance ledger](IPHONE-102-PERFORMANCE-GOAL-LOOP.md).
Both selected captures had internal phase/dispatch timing disabled.

| Running-sample attribution | Loop experiment control | Earlier clean capture |
|---|---:|---:|
| CPU-thread sampled time | 18,515 ms | 25,079 ms |
| Video-thread sampled time | 11,774 ms | 18,682 ms |
| Identifiable software decoder work, video thread | 931 ms | 1,257 ms |
| Decoder / video-thread samples | 7.91% | 6.73% |
| `SetCPStatusFromGPU`, video thread | 2,409 ms | 3,992 ms |
| Samples with generated game/dispatcher on CPU stack | 15,427 ms | 21,050 ms |

The analyzer resolves XML references and charges each sample at most once to
each category. Categories can overlap; they must not be summed. Compiler
inlining, tail calls and unwind visibility limit symbol classification.
Generated-code stack presence includes callees and is not generated-code self
time. Sampled milliseconds are statistical weights, not stopwatch timings.

Vertex decoding is real work, but these captures do not identify it as the
dominant cost. Nor does eliminating 7–8% of video-thread samples imply a 7–8%
FPS gain: CPU/video work overlaps, synchronization matters, and an alternate
path adds work elsewhere. These observations also do not prove that decoder
optimization would never help another scene.

The larger FIFO/status sample share does not authorize deleting status updates
or adding sleeps. The original ledger already distinguishes useful processing
from polling and records rejected sleep experiments. Reclassifying the whole
GPU loop as removable overhead would repeat a known diagnosis error.

## 2. Fresh Mac runs confirm a mechanism, not a speed gain

Ran the retained, previously documented native MeleePad Mac baseline with its
explicit v1.02 module. Used independent copies of Config, GC and StateSaves,
loaded the same Onett Mario/Kirby fixture via the supported state-load signal,
and selected native versus software vertex loading in the copied configuration.
Both valid runs acknowledged the load and advanced emulated frames.

Exact inputs:

- Runner SHA-256: `d2626855b8b09761460215e97d587d769e60f246296b6d5533a6a54dff88352e`.
- Module SHA-256: `6eda112765d2726701d3439c0f5dfb289cc48c2d3af8c316aebff7c2ff8ee09a`.
- Initial state SHA-256: `ee1648dd39eb25c51c91ebec98d7822d484d5ac1b43c12db713bb0ded8f86e3e`.

This is the retained September 10 comparison binary, not a rebuild of today's
dirty Slippi checkout. It uses the Mac combined CPU-GPU thread; it does not
reproduce physical iOS scheduling or thermal behavior.

| Native Mac sampling | Native decoder | Software decoder |
|---|---:|---:|
| CPU-GPU thread samples | 6,074 | 6,361 |
| Identifiable software-decoder samples | 0 | 221 |
| Identifiable software decoder / thread samples | 0% | 3.47% |
| Generated game/dispatcher stack samples | 73.74% | 57.87% |
| Throttle-sleep stack samples | 0.02% | 18.22% |

These percentages include waiting and are not running-only percentages. The
native result's zero software-decoder samples does not mean native decoding is
free; generated decoder code can be symbolically opaque.

**Rejected as a performance A/B.** The sampled frame windows differ
(`41406–42052` versus `41509–42027`), startup/cache conditions differ, and waiting
time differs substantially. Phase logging also selects the diagnostic CPU loop.
The primitive count ranges include zero, so the full windows must not be called
uninterrupted matched combat. Lower CPU time in the software run is not evidence
that software decoding is faster. No FPS delta from this pair is admissible.

The narrower supported finding is that changing the configuration activates
the identifiable software path, and that path does not dominate this profiled
Mac interval. It does not demonstrate an Aurora speed advantage.

## 3. GPU vertex fetching carries costs and compatibility work

Three details materially weaken the original suggestion to borrow Aurora's
vertex path:

1. **Our decoder is already ahead-of-time compiled.**
   `VertexLoader_Position.cpp` and related files instantiate typed C++ loaders.
   `VertexLoader::CompileVertexTranslator` selects function pointers once for a
   format; `RunVertices` invokes those stages per vertex. A newly fused decoder
   might remove calls, but simply proposing a precompiled decoder does not
   introduce a capability we lack. It needs a demonstrated improvement over
   this implementation.
2. **Aurora's array reuse is per frame.**
   `extern/aurora/lib/gfx/recording.cpp:577–579` clears every array's
   `cachedRange` at frame end. `command_processor.cpp:397–398` uploads an array
   again when its range is empty. This avoids repeated uploads within a frame;
   it is not permanent GPU residency of immutable model arrays. Full-array
   uploads, shader indexed fetches and endian conversion must be included in
   the cost comparison. No upload volume/GPU-cost comparison exists here.
3. **Our CPU consumes decoded vertex state.**
   `VertexManagerBase::CalculateZSlope` uses the last triangle's decoded
   positions and matrix indices for z-freeze; cached normal/tangent/binormal
   values feed later shader state and are serialized. `VertexLoaderManager`
   also has an optional CPU-culling path, off by default. Skip-index behavior
   changes output vertex counts. Moving all decoding into a shader would need
   to preserve these contracts, retain a CPU subset or change the renderer.

Sources are in the active
`ref/ModernGekko/vendor/dolphin/Source/Core/VideoCommon/` tree and the pinned
melee-pc checkout. These are concrete integration costs, not evidence that GPU
fetching is inherently slower. They prevent claiming that importing the code
automatically removes the measured CPU cost.

## 4. Native math: an actual bitwise difference, not an interchangeable snippet

The main Aurora `mtx.c` remains byte-identical to our dependency copy. For the
changed `PSVECSquareMag` routine, compiled each repository's actual `vec.c`
separately with Apple Clang, `-O2 -ffp-contract=off -fno-fast-math`, and called
the exported function through the same harness.

Of 100,000 deterministic finite vectors drawn from [-10, 10], **10,636 produced
different result bits**. The first input was approximately
`(7.9234467, -0.4171441, -9.3909197)`; the output bit patterns were `0x431724f6`
and `0x431724f7`. The source difference introduces explicit `fmaf` operations,
which remain fused despite disabling implicit contraction.

This is not proof that melee-pc is wrong: there was no original PPC oracle in
this test, and one implementation might be more faithful for this operation.
It does prove that the change cannot be assumed numerically interchangeable.
The probe measures neither execution speed nor gameplay divergence. There is
also no claim that this vendored routine is the active implementation of our
translated game's math. A rollback-sensitive optimization needs that mapping
and semantic validation first.

## 5. Re-audited disposition of the original proposals

| Proposed import | Evidence after the second pass | Disposition |
|---|---|---|
| Aurora vertex upload/fetch | Smaller measured CPU share; per-frame uploads; CPU-side semantic dependencies | Withdraw top-priority recommendation. No implementation justified yet. |
| Native GX boundary | Large translated workload exists, but prior helper experiments did not earn promotion; Aurora retains FIFO/command processing | Architectural hypothesis only. No newly qualified replacement. |
| Matrix/vector routines | Main matrix code already present; changed vector function differs on finite inputs | No automatic import or speed claim. |
| Pipeline preparation | Existing MeleePad facilities already provide it; no new matched hitch evidence | No cache/renderer replacement. |
| File prewarm/LRU | No measured MeleePad loading bottleneck tied to it; first-pass probe found a soft budget | No cache integration. |
| Software AX mixer | Different engine boundary; no measured advantage against our audio path | No replacement. |
| Whole native-source engine | Can remove classes of guest execution work but still faces build, data-model, correctness and Slippi migration costs | No migration recommendation on speed grounds. |

The first assessment remains a useful architectural inventory. It is not an
optimization backlog whose entries should be implemented on the assumption
that a newer native port must be faster.

## Evidence and preservation

- [Aggregate second-pass evidence](artifacts/melee-pc-assessment-2026-09-16/second-pass.json)
  contains sample counts, hashes and synthetic math results, with no game data
  or device identifiers.
- Private scripts, original-source compilation commands, traces and receipts:
  `ref/melee-pc-assessment-20260916/pass2/`.
- The first Mac launch was excluded: its load signal arrived before startup
  installed the handler. The retry waited for the module-ready log first.
- A UI inspection subsequently auto-reopened the historical benchmark wrapper
  after the managed run ended. It was stopped and excluded. That wrapper reused
  its old scratch runtime/phase log paths and `/tmp` benchmark user directory;
  those mutable historical logs were overwritten. The new per-run evidence,
  retained aggregate results and source fixture were not used through that
  wrapper. Do not use the old scratch logs as the original September 10 capture.
- All audit-launched runners exited; no production source, dependency pin,
  module, installed app, physical device or original fixture was changed.
  Existing dirty work remains in place. No release, commit or external message
  was made.

**Acceptance:** second audit complete; no demonstrated MeleePad speedup and no
performance patch promoted. The evidence is insufficient to suggest importing
any particular melee-pc component as a speed improvement today.
