# iPhone heavy-scene performance: evidence and next optimization

2026-09-08 · MeleePad engineering decision · regular physical iPhone build 11

## Decision

The latest iPhone run confirms severe slowdown with Melee v1.02 at native resolution. The decompilation provides useful function boundaries and semantics for targeted optimization, but the installed app still executes generated PowerPC translations. This research delivered no new runtime speedup. Consistently smooth iPhone gameplay is not an established product claim.

Prioritize a **connected animation-transform specialization**, conditional on one short attribution capture of the failing scene. Keep intermediate emulated register values in native locals across selected calls instead of repeatedly materializing full guest context. Collision helpers are an alternate target if attribution favors them. Do not repeat standalone matrix microbenchmarks or start a whole-game native rewrite.

Scope: explain the latest retained physical-iPhone log, inspect the current runtime and pinned decompilation, and select bounded implementation candidates. No new gameplay session, Simulator, recording, device installation, or netplay acceptance test was performed. Stage and fighter identities are not recorded; the connection to multiple characters is the owner's observation.

## What the phone actually recorded

The retained session identifies build 11 and the physical A15 iPhone. Its selected game is verified USA v1.02. The following are logged samples, not a continuous frame-time trace. Times are UTC on September 8 (add nine hours for Japan).

| Time | Reported FPS | Emulation speed | CPU thread | Video thread | Audio underruns, cumulative |
| --- | ---: | ---: | ---: | ---: | ---: |
| 08:01:16 | 59.9 | 1.004× | 60.8% | 13.2% | 43 |
| 08:01:26 | 9.9 | 0.191× | 91.6% | 62.2% | 114 |
| 08:01:36 | 34.2 | 0.567× | 97.7% | 70.6% | 199 |
| 08:01:46 | 37.8 | 0.635× | 99.2% | 71.5% | 295 |
| 08:01:56 | 43.2 | 0.727× | 99.2% | 73.7% | 368 |
| 08:02:06 | 59.9 | 0.993× | 76.2% | 52.6% | 389 |

Source: privately retained `ref/revision-102/build11-latest-iphone-runtime.log`; parsed companion `build11-latest-performance.json`. Raw logs remain excluded from the repository.

Every performance sample reports **640×528 EFB, 1× render scale, original 4:3, Low Power Mode off, serious thermal state**. Higher resolution or experimental widescreen therefore cannot explain this particular failure. CPU-thread utilization approaches one core, while substantial CPU work also occurs on the video thread. This supports a CPU-side throughput concern but does not identify individual hot functions or exclude a GPU bottleneck. Video-thread CPU usage is not GPU utilization: Dolphin moves graphics preparation work onto that thread. [Dolphin's dual-core explanation](https://dolphin-emu.org/blog/2022/07/07/dolphin-progress-report-may-and-june-2022/).

Thermal state was already serious during earlier 60 FPS samples. Heat may reduce available headroom; this log cannot quantify throttling or attribute the entire collapse to temperature. Apple defines serious as high thermal state, not a measured clock-frequency reduction. Later 60 FPS samples are **not proof of active-gameplay recovery**: the owner mentioned pausing, and the host pause flag does not detect the game's own pause screen. [Apple thermal-state definitions](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum).

Last-frame primitive snapshots rise from 32,968 to about 55,000–57,000 around the severe interval. Cumulative created shaders rise from 60 vertex / 144 pixel to 65 / 176 at the first bad sample. These are workload and shader-activity clues, not measured costs. The runtime captures graphics counters from the last completed frame, whereas shader creation is cumulative; neither is an interval-average profile. Source: `ref/ModernGekko/src/runtime/dolphin_runtime.cpp:656–684`.

## Ranked implementation candidates

### 1. Reduce translation overhead across animation or collision calls

The pinned decomp's `HSD_JObjMakeMatrix` prepares parent transforms, builds scale/rotation/translation matrices and invokes matrix concatenation. The current generated equivalent still contains instruction-shaped PC updates, floating-point checks and guest-register writes. The practical opportunity is retaining live values across a **selected function family**, using the decomp to understand safe boundaries. Existing clean-matrix checks mean blindly adding another matrix cache is not a novel fix. [Pinned joint-transform source](https://github.com/doldecomp/melee/blob/ae5898ee0dfda41b34fdf846f7d680a33e14779d/src/sysdolphin/baselib/jobj.c#L138), [existing clean-matrix check](https://github.com/doldecomp/melee/blob/ae5898ee0dfda41b34fdf846f7d680a33e14779d/src/sysdolphin/baselib/jobj.h#L250).

A second family is `lbColl_80007ECC` and selected capsule/intersection helpers. As a concrete example, the grab-collision caller loops through potential victim fighters, active grab hit capsules and grabbable hurt capsules. More participants can increase that work, but this does **not** prove grab collision caused the recorded slowdown. Preserve lazy position updates and traversal/first-hit order. [Pinned grab-collision loop](https://github.com/doldecomp/melee/blob/ae5898ee0dfda41b34fdf846f7d680a33e14779d/src/melee/ft/ftcoll.c#L1566), [capsule helper](https://github.com/doldecomp/melee/blob/ae5898ee0dfda41b34fdf846f7d680a33e14779d/src/melee/lb/lbcollision.c#L1650).

Integration must retain guest-memory semantics, aliasing, paired-single rounding, exception behavior, cycle/timebase accounting and code-validity/fallback guards. Ordinary host float/FMA substitutions are not automatically equivalent. Changed boundary collisions could desynchronize online matches. Start behind a revision-102 feature gate; keep the existing path for unsupported conditions and v1.00. Local implementation references: `StaticRecompCore_Run.cpp:165–194`, `StaticRecompCore_SMC.cpp:222`, and generated `chunk_0208_text1_80341940.c:8760` under the private revision-102 module output.

**Expected gain: unknown.** Earlier leaf work is an explicit negative result: standalone copy/concat work projected only 2.55–3.53% overall; another local live-state optimization projected 0.33–0.37%. Those older scenes/revisions do not establish current coverage. This candidate must cross useful call boundaries, not repeat those experiments. [Prior results](../../PERF.md) (see entries PERF-080 through PERF-085 and the direct-call experiments in the same document).

### 2. Precompile common vertex-decoding paths for iOS

Our iOS configuration forces Dolphin's software vertex loader because the alternative ARM64 loader generates executable code. The software path invokes a sequence of function pointers for every vertex. A small set of ahead-of-time compiled decoders for frequently used vertex formats could remove that overhead while retaining the portable fallback. This is a renderer optimization; the decomp can help identify asset formats, but completing the decomp does not supply this implementation.

Source: `ref/ModernGekko/src/runtime/dolphin_runtime.cpp:547`; `vendor/dolphin/Source/Core/VideoCommon/VertexLoaderBase.cpp:235–274` and `VertexLoader.cpp:256–276` within ModernGekko. Preserve format conversion, endianness, indexing, skipped vertices and output bytes. Choose formats from actual workload attribution; do not generate every possible format. **Gain and relevant coverage are unknown.** Reducing video-thread CPU may help throughput/thermal headroom, but cannot guarantee resolution of a separate game-CPU bottleneck.

### 3. Diagnose shader fallback and warm-up for the initial collapse

The first severe sample coincides with 37 additional created shaders. The runtime already enables shader caching, asynchronous ubershaders, waiting for startup shaders, and three iOS compiler workers. Simply enabling those options again is not a fix. Uncached uber-pipeline creation still has a synchronous path, and cumulative shader counters cannot tell us its duration or how long fallback shaders were used.

A useful candidate is ensuring observed pipeline variants are cached/warmed before gameplay **if** compilation/fallback timing accounts for the bad interval. Do not claim shader creation explains the sustained 34–43 FPS segment. Source: `dolphin_runtime.cpp:534–541`; `VideoCommon/ShaderCache.cpp:141–170`; `VideoBackends/Metal/MTLObjectCache.mm:374–436` within the pinned local runtime.

## Bounded next step and stopping rule

1. Capture one short reproduction of the actual heavy scene on the physical iPhone, with guest-function attribution and shader/vertex-loader timing sufficient to choose one candidate. Record stage, fighters, thermal state and in-game pause explicitly. No broad benchmark sweep or Simulator substitute.
2. Implement only the selected high-coverage family or renderer path behind a reversible gate. For game-code work, check state, memory, floating-point edge cases, timing and fallback behavior against the existing implementation before deployment.
3. Compare the same physical scene at 1×/4:3 under comparable thermal conditions, including a warmed repeat to separate shader first-use effects. Retain the change only for a meaningful repeatable improvement without gameplay/audio regressions. Keep online equivalence acceptance on the physical iPad–iPhone pair.
4. Stop after that candidate if results are inconclusive; document the reason. Do not spend another session on low-coverage leaf tuning.

At a steady 34.2–43.2 FPS, reaching 60 would require approximately **43–28% less frame time**, respectively (`1 − FPS/60`). This is an illustrative budget calculation, not an optimization forecast; sampled FPS does not provide frame-time percentiles. It explains why a few-percent micro-optimization would be insufficient.

Missing evidence: hot guest PCs/functions in this run, GPU timings, actual shader compilation/fallback duration, active vertex formats, fighter/stage identity, and pause timing. Research stops here because further source browsing cannot establish these runtime facts. No new performance build or reliable online-play claim results from this report.
