# iPhone performance goal loop

Date: 2026-09-04

Status: **research active; 60 Hz preference cache and secondary scheduler-idle
boundary accepted; fixed Big Blue cadence materially improved but still misses
sustained 60 FPS; texture, FIFO, CP-status, and broad generated-region
candidates rejected or stopped**

## Goal

Make the existing full-fidelity GALE01 revision-1.00 build sustain native game
speed on the attached iPhone 14 without weakening game timing, rendering,
audio, input, saves, lifecycle behavior, or netplay determinism.

The first target is 59 FPS/VPS or better through a repeatable heavy combat
route and a 15-minute thermal soak. A partial optimization may be retained for
composition only when it produces a repeatable, correctly attributed gain.

## Current diagnosis

The iPhone failure is real and is not primarily a render-resolution problem.
At the already-minimum 1x GameCube EFB scale, the retained heavy interval
measured:

| Metric | iPhone 14 result |
| --- | ---: |
| Mean frame time / rate | 30.95 ms / 32.31 FPS |
| CPU wall / thread time | 29.71 / 29.37 ms |
| Video build / present | about 0.04 / 0.02 ms |
| Guest cycles / dispatches per frame | about 8.1 M / 203 k |
| Thermal state | serious |

No new resources appeared during the retained warm interval. The CPU thread
therefore needs a 43.2% reduction merely to reach 16.67 ms, and roughly a 49%
reduction to reach a safer 15 ms sustained budget. Thermal pressure can amplify
the slowdown, but it does not explain away the amount of on-core guest work.

The hardware comparison is directionally consistent with the observation.
Apple specifies two performance CPU cores and a five-core GPU for iPhone 14's
A15, versus four performance CPU cores, a ten-core GPU, and 100 GB/s memory
bandwidth for the M2 iPad Pro. MeleePad currently runs synchronized CPU and
video workers, so the phone has much less sustained headroom for two hot
workers and the rest of the app.

Sources:

- [Apple iPhone 14 technical specifications](https://support.apple.com/en-gb/111850)
- [Apple 11-inch M2 iPad Pro technical specifications](https://support.apple.com/en-euro/111842)
- [Apple thermal-state documentation](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum/serious)

## Research iterations

### I0 — physical-device attribution

The ordinary run and the diagnostic run independently reproduce the same
roughly 32 FPS class. The diagnostic run attributes almost all of the frame to
the emulated CPU thread, not Metal presentation. Samples are distributed, but
nine 16 KiB guest regions account for 72.65% of the retained samples; the top
eight account for 69.91%. No individual guest PC owns enough time to justify
another one-address replacement.

Decision: retain the physical iPhone as a new performance lane. Do not infer
iPhone acceptance from the M2 iPad result.

### I1 — current upstream LLVM backend

An isolated current-upstream DolRecomp build was made compatible with LLVM 22
and Apple ARM64. Twenty-eight of twenty-nine tests passed. The sole failure is
an ELF-symbol spelling expectation in a disassembly regex; the Mach-O object
contains the tested cold escape and budget call, while semantic execution,
native-ABI, paired-single, interception, and pipeline tests pass.

The same private 1,024-instruction slice used by the earlier backend rejection
was regenerated. With the new default backend and 128-instruction partitions,
LLVM is only 2.2-10.4% slower than C rather than the former 4.8-4.9x slower.
`--state-in-memory` reverses that narrow result by 6.2-10.0% against upstream C.
On a shared runtime/harness against MeleePad's pinned generated C, however, the
gross lead is only 3.4%. A 256-instruction partition is 2.2% slower, so 128 is
the only surviving partition size.

The footprint and eligibility screens reject a broad integration:

| Screen | Result |
| --- | ---: |
| Exact 4 KiB slice, LLVM state-memory size / C | 4.24x |
| Five leading physical-iPhone regions | 159/160 compatibility partitions |
| Region object-size ratios | 4.06-4.70x C |

The new native-register ABI is therefore not the mechanism improving the
actual iPhone regions. Almost every partition falls back to the compatibility
ABI, and the remaining local win is far below the 35% preflight gate.

Decision: do not update DolRecomp, do not generate a full LLVM module, and do
not deploy this backend. Reconsider only if compatibility partitions gain a
measured state-boundary compaction that beats C by at least 35% without a
multi-fold footprint increase.

Primary sources:

- [ExpansionPak DolRecomp](https://github.com/ExpansionPak/DolRecomp)
- [RecompCore](https://github.com/aharonahdoot/RecompCore)

### I2 — newer C emitter

An initial cross-build result appeared to make upstream C about 36% faster.
That comparison was invalid because the harness copied different-sized
`CPUState` structures inside every timed iteration. A shared-runtime
comparison removes that apparent lead. The small remaining source difference
also includes the same global inline FP-availability mechanism that previously
passed semantics but regressed real gameplay and grew the full module.

Decision: do not retry global FP-gate inlining, no-EXRAM memory specialization,
FPRF common-case branches, broad PC-store removal, or a compiler-flag sweep.
Their existing live reversals remain controlling.

### I3 — lower-fidelity workload option

Dolphin's own settings describe 1x as native EFB resolution; MeleePad is
already at that minimum. The relevant low-end graphics hacks are already at
their fast defaults. MeleePad deliberately presents same-identity XFB updates
because the old duplicate-XFB heuristic caused multi-second frozen
transitions. Lowering a scale number below 1 is therefore neither a supported
EFB mode nor a likely fix for a 29.37 ms guest CPU frame.

There is one separate game-workload experiment: Slippi's maintained
"Lagless FoD" patch disables Fountain particles and reflections specifically
to improve performance. This changes the game image, targets revision 1.02
rather than MeleePad's required revision 1.00, and would affect deterministic
online compatibility. It is not eligible for the stable default. It may be
ported later as an explicit offline experimental low-power profile if the
correctness-neutral backend lane cannot reach the phone budget.

Primary sources:

- [Dolphin low-end graphics setting descriptions](https://github.com/dolphin-emu/dolphin/blob/master/Source/Android/app/src/main/res/values/strings.xml)
- [Dolphin Melee compatibility settings](https://wiki.dolphin-emu.org/index.php?title=Super_Smash_Bros._Melee)
- [Slippi GALE01 configuration and Lagless FoD](https://github.com/project-slippi/slippi-ssbm-asm/blob/master/Output/Netplay/GALE01r2.ini)

### I4 — live workload and texture-allocation split

A fresh read-only copy of the still-installed build-5 log shows that serious
thermal state is not a universal 32 FPS cap. Light scenes repeatedly recover
to 59.9 FPS while still serious. The failures split into at least two classes:

| Class | Representative behavior |
| --- | --- |
| Graphics-heavy | 31.8-39.0 FPS, CPU thread 98-100%, video thread 70-71%, 204-218 newly created textures per ten seconds |
| CPU-only / movie-like | 45-47 FPS, CPU thread 91-100%, video thread about 3%, one draw and zero primitives, no material texture creation |

One preceding graphics-heavy interval creates 390 textures in ten seconds.
Dolphin keeps unused textures in its reuse pool for only three frames before
destroying them. The counts establish churn, not its cost: creation may be a
cause, a consequence of changing content, or both. It cannot explain the
separate CPU-only slow class.

Decision: add a bounded allocation-cost diagnostic before changing pool
retention. Treat texture reuse and generated CPU work as independent lanes.

### I5 — physical texture cost and THP CPU profile

Dolphin patch `0046-texture-pool-attribution.patch` adds only opt-in phase-log
measurement. It records reuse, miss reason, expiry, recreation of the same
configuration within 30 frames, and the wall time of real texture/framebuffer
creation. A relative log name resolves inside Dolphin's writable `Logs`
directory on sandboxed iOS. With the environment variable absent, the timers,
diagnostic map, and counters remain inactive; pool retention is unchanged.

The signed build-5 candidate compiled, installed over the existing bundle, and
launched on the attached iPhone 14. The pre-/post-install GC save, Dolphin
configuration, and preferences trees were byte-identical. The retained ISO and
extracted game tree remained present.

Two adjacent slow graphics windows measured:

| Ten-second window | Phase FPS | CPU-thread mean | Video-thread CPU | Creates / time | Recent-expiry recreates |
| --- | ---: | ---: | ---: | ---: | ---: |
| first | 52.6 | 18.32 ms | 63.8% | 188 / 6.184 ms | 99 |
| second | 45.6 | 21.15 ms | 65.4% | 234 / 6.728 ms | 129 |

The second window's create calls averaged 28.8 microseconds. Although 55.1% of
them followed expiry of the same configuration, all creation consumed only
about 0.10% of the measured video-thread CPU budget. Even perfect reuse cannot
recover a useful fraction of a frame. The small `video_build_ms` phase field is
not the full asynchronous video-worker cost and must not be used as that
denominator.

Decision: retain the default-off attribution, reject a longer texture-pool
retention experiment, and do not spend the 128 MiB memory allowance. Current
upstream Dolphin still uses the same three-frame pool threshold; it contains no
new retention mechanism that changes this result.

A separate 12-second physical Time Profiler sample caught the one-draw THP
movie slowdown. The CPU thread supplied 10,245 ms of running samples while the
video thread supplied 413 ms. Its CPU leaf distribution was:

| CPU sample family | Share |
| --- | ---: |
| generated guest bodies | 39.86% |
| paired-quantized helpers | 22.79% |
| memory/runtime helpers | 10.50% |
| `ppc_fp_available` | 8.88% |
| dispatch/synchronization | 7.66% |
| diagnostic clocks | 3.42% |

Three generated chunks cover 81.83% of this sample: `0x8032D940` (51.63%),
the loop inside `0x80345940` (17.82%), and `0x80331940` (12.38%). Within the
first chunk, 99.6% of FP-gate samples, 93.2% of paired-store samples, and nearly
all `psq_load_value` samples originate there. The generated source contains
1,429 FP-availability call sites and 432 paired-load/store call sites in that
single 16 KiB guest chunk.

This reproduces the earlier THP diagnosis on real A15 hardware, at larger
relative helper cost. It does not revive the rejected global inline gate,
per-chunk flag, paired-load coalescing, or broad PGO candidates. Those variants
added branches/code across many sites and regressed live routes. The surviving
shape is a manifest-selected region path that checks entry invariants once and
removes repeated state round trips without duplicating a condition at every FP
instruction.

Primary sources:

- [Current Dolphin texture-cache source](https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/VideoCommon/TextureCacheBase.cpp)
- [Current DolRecomp backend scope](https://github.com/ExpansionPak/DolRecomp/blob/main/README.md)

### I6 — de-aliased heavy-route selection and graphics-heavy profile pilot

The THP Time Profiler capture in I5 sampled a real slowdown, but not the fixed
heavy-gameplay route. Two new unattended physical-iPhone runs joined phase rows
to native-dispatch samples at prime intervals/offsets `4093/17` and `4091/211`.
The retained windows exclude loading, the one-draw THP movie, menus, and a later
lifecycle interruption. They cover fair and serious thermal states:

| Window | Phase FPS | CPU-thread mean | Dispatches/frame | Draws/frame | Samples |
| --- | ---: | ---: | ---: | ---: | ---: |
| run 1, fair | 32.20 | 29.73 ms | 205,116 | 1,235 | 24,205 |
| run 1, serious | 31.29 | 30.63 ms | 217,930 | 1,279 | 23,321 |
| run 2, fair | 40.40 | 23.80 ms | 165,289 | 746 | 32,645 |

`scripts/analyze-stable-dispatch-regions.py` resolves wall-time windows through
`host_frame_end_unix_ns`, uses the actual generated-chunk grid, rejects a chunk
when its normalized share varies by more than 25%, and ranks survivors by their
minimum share. Ten chunks conservatively cover 70.50% in every window:

| Rank | Generated chunk | Minimum share | Maximum/minimum |
| --- | --- | ---: | ---: |
| 1 | `0x8035D940` | 14.22% | 1.10x |
| 2 | `0x80369940` | 11.08% | 1.09x |
| 3 | `0x8033D940` | 10.63% | 1.02x |
| 4 | `0x80339940` | 8.16% | 1.09x |
| 5 | `0x80359940` | 6.91% | 1.14x |
| 6 | `0x80375940` | 5.23% | 1.08x |
| 7 | `0x80361940` | 4.71% | 1.11x |
| 8 | `0x8036D940` | 3.35% | 1.18x |
| 9 | `0x80381940` | 2.39% | 1.17x |
| 10 | `0x80321940` | 1.44% | 1.19x |

The I5 THP/movie chunks do not survive this test: `0x8032D940` has no heavy
samples, `0x80331940` has 0.02-0.03%, and `0x80345940` varies from 4.50% to
8.96%. The proposed three-chunk THP tranche is rejected before generator work.
The heavy route also has diffuse exact entries: only `0x803408D4` reaches a
stable 1.70% of the complete dispatch stream among the selected chunks. A
single-function or one-entry wrapper cannot meet the whole-frame gate.

A subsequent ordinary-build Time Profiler pilot crossed from fair to serious
thermal state during a graphics-heavy match. Its five complete serious seconds
show the CPU thread at 4,973 ms and video thread at 3,174 ms. Selected generated
chunks own about 46.8% of CPU samples before assigning dispatcher-only samples;
the largest is `0x8033D940` at 14.6%. On the video thread,
`SetCPStatusFromGPU` is 19.9%, `RunGpuLoop` is 23.6%, vertex flush is 11.2%,
and EFB peek-cache refresh is 9.1%. Texture copy and hashing are only 1.1% and
0.9% in this segment, independently reinforcing the texture-retention rejection.

The pilot is not the required 12-second graphics-heavy profile because its
first 6.56 seconds precede the serious interval. Its distribution is candidate
selection evidence only. Before editing the FIFO path, count CP-status calls,
control-source activity, watermark transitions, interrupt transitions, status
reads, and control writes in a default-off diagnostic. Do not skip status work
until that run proves the inactive-control fast path is both dominant and
semantically isolatable. Current upstream Dolphin retains the same per-gather
status update, so there is no upstream optimization to import blindly.

Private evidence remains outside Git. Run 1 dispatch/phase SHA-256 values are
`2f21b47928ccaf68e59ecb5dac773242a959de7657ff73add07a9de87e612711` and
`a2ff82fa8112e9a536c136e5120f12c6bf4daac318733c418165dcfedc58a039`;
run 2 values are
`d91f9df334ae644aae2aa8cc2d7ab45e95f8b86f68249d1baecef4ead85cc771`
and `20764fcd9e3dd38aa04c1bbe038ea69a74195084f521d571b1e204fc30a8ed26`.
The profile XML/runtime-log values are
`3d39e22f0e510a1cf38f0bd1a88e78046fd5b0e14acd62a78364138f6bc27568`
and `1e342397b612de58e393e1fce314db166bc8360956d86a09fa894eb26644a69d`.
The GC tree is byte-identical before and after all runs.

### I7 — FIFO spin experiment and reproducible physical route

An opt-in CP-status attribution run covered 10,361 rendered frames. In its
graphics-heavy rows, `SetCPStatusFromGPU` was called a median 542,461 times per
frame (mean 519,161; p95 663,935), but the observed control sources were
inactive: no read-disable intervals, interrupt transitions, status reads, or
watermark transitions occurred in the retained heavy interval. The counters
were removed after the attribution run because counting on this hot path is
itself perturbing.

Making the GPU worker sleep immediately when a callback found no FIFO work was
a clear rejection. Mean FPS fell from 49.32 to 46.30 while task context
switches rose from about 50 to 1,997 per frame. The bounded 1,024-callback spin
candidate was also rejected after the controlled repeat below; its source
change was removed.

The iOS input publisher also performed an Objective-C preferences lookup for
`MeleePadModernCStickHorizontal` on every 60 Hz input update. When the key was
unset, CoreFoundation emitted 1,743 identical diagnostics over about 29
seconds. The value is now loaded once into an atomic cache and refreshed by the
existing settings-change path. A physical rerun produced only six clustered
launch-time preference reads and none during steady input. This removes real
60 Hz work but is not, by itself, evidence of an FPS gain.

The private, default-off `classic-v1` route now reads the validated revision-
1.00 Classic cursor state, selects Peach, and starts gameplay without screen
capture or UI automation. Its clock comes from the emulated frame counter, the
menu transitions reset the validated revision-specific RNG seed, and gameplay
starts on emulated frame 1,920. Three physical runs reached that frame with the
same cursor position and seed while the phone reported fair thermal state.

The resulting control/candidate/control sequence covered the same 8,439
emulated frames from 1,920 through 10,358:

| Run | All-row FPS | Heavy-row FPS | Heavy CPU-thread mean | Heavy context switches |
| --- | ---: | ---: | ---: | ---: |
| control A | 54.56 | 49.10 | 19.57 ms | 45.14 |
| 1,024-spin | 54.94 | 49.72 | 19.31 ms | 77.74 |
| control B | 53.83 | 48.19 | 19.92 ms | 45.06 |

The candidate's 1.27% apparent heavy-row gain over control A sits inside the
1.84% control-to-control range. On 938 closely matched workload rows its total
frame-time change was 0.01%, while heavy-row context switches rose about 73%.
Only 13 rows matched all three runs exactly enough for a three-way comparison,
so the aggregate is not evidence of a durable gain.

Decision: reject and remove the 1,024-spin candidate. Retain the benchmark
route, fixed frame/RNG controls, phase logging, and 60 Hz preference-cache fix.
Do not attempt another FIFO sleep threshold without evidence that it can avoid
the context-switch increase and exceed measured control-to-control drift.

### I8 — inactive CP-status fast-path rejection

The current upstream Dolphin implementation still performs full breakpoint,
watermark, and interrupt evaluation in `SetCPStatusFromGPU` for every 32-byte
FIFO gather. The I7 attribution showed all three event sources inactive during
the Melee heavy interval, so an environment-gated early return was tested.

The first version checked the six relevant atomics on each call. On 523 closely
matched heavy frames it increased total frame time 1.13%. A refined version
cached the aggregate "status work required" state so the gather path loaded one
atomic flag. Over 8,144 common emulated frames through frame 10,063, its heavy
result was 49.58 FPS versus 49.65 FPS control. On 575 closely matched heavy
frames it increased total frame time 0.63%; context switches were unchanged.

Decision: reject both shapes and remove their source/patch/bootstrap changes.
The Time Profiler percentage did identify frequently executed bookkeeping, but
removing that work did not improve the end-to-end physical-device frame budget.
Do not pursue additional CP-status specialization without a new profile showing
exclusive instruction cost rather than inclusive sampling in the FIFO loop.

### I9 — three-workload generated-region stop gate

The deterministic Classic route cannot reproduce the graphics density of the
two original severe windows. Its best 12-second interval measured 30.25 FPS,
31.85 ms CPU-thread time, 128,985 native dispatches, 388 draws, and 27,131
primitives per frame. Across the complete run, no frame exceeded 664 draws.
The two retained severe windows measured 1,284 and 738 draws at 30.83 and 40.00
FPS respectively. The predeclared 700-draw native-profile gate therefore was
not weakened, and no new Time Profiler result was accepted. Two headless
Instruments attempts also failed before recording because the installed Xcode
could not boot an Instruments service for the newer device OS; gameplay and
device logging remained live.

An independent prime-offset internal sampler recorded 360,448 dispatch samples
without console or screen capture. Intersecting its slow Classic interval with
the two severe 12-second windows reduced the stable corpus from ten chunks to
eight. Their combined minimum coverage is only 47.21%, so the explicit 70%
selection gate fails. The largest stable chunks start at `0x80360000`,
`0x8035C000`, and `0x8033C000`, but none justifies a broad region backend.

Decision: stop the proposed register-resident generated-C integration before
editing DolRecomp. Its measured stable coverage is too low to project the
required whole-frame gain. Return to physical attribution or the explicitly
separate low-power visual lane; do not redefine the failed coverage threshold.

### I10 — deterministic Fountain route and reflection-only rejection

A new default-off `training-fod-v1` route reaches Training mode with digital
menu edges, selects Peach through Melee's live CSS cursor pointer, and enters
Fountain of Dreams through the stage selector's own `force_stage_id` field.
Every guest-memory access is revision-1.00-specific and range/state checked.
The route also has an opt-in extracted-DOL boot so a deliberately patched
module can be measured against matching guest code without editing the retained
ISO. A mismatched pilot correctly produced two static-recomp chunk-verification
fallbacks and was discarded before measurement.

The first visual experiment ported only the reflection-removal half of
Slippi's maintained Lagless FoD patch by function identity. It did not copy
revision-1.02 addresses, and it excluded the separate particle and dynamic
heap-pointer changes. A signed stable control and signed candidate were run
from matching revision-1.00 DOLs on the same physical iPhone, at 1x, with the
same route and RNG seed. Across 4,801 aligned gameplay frames (emulated frames
2,400 through 7,200):

| Metric | control | reflection-only | candidate minus control |
| --- | ---: | ---: | ---: |
| mean total frame | 16.756 ms | 16.763 ms | +0.007 ms |
| mean CPU-thread | 14.108 ms | 14.032 ms | -0.076 ms |
| mean video-build | 4.902 ms | 5.008 ms | +0.106 ms |
| total-frame p95 | 17.975 ms | 17.984 ms | +0.009 ms |
| frames over 16.667 ms | 52.53% | 53.18% | +0.65 points |
| frames over 20 ms | 0.08% | 0.08% | no change |

The candidate did not reduce draw calls, primitives, static cycles, or total
frame time. Its small CPU-thread decrease was offset by video-build time and
is not an end-to-end improvement.

Decision: reject reflection-only. Do not ship it or describe it as an iPhone
speedup. Preserve the route and matching-DOL guard as measurement
infrastructure. If the low-power visual lane continues, measure the particle
half separately and require a visible whole-frame gain before composing the
two. This Training/FoD route isolates stage effects; it does not replace the
unresolved graphics-heavy route required to claim the full app problem fixed.

### I11 — physical iPhone heavy reproduction and scheduler/clock rejection

An ordinary stable 1x launch with only the existing frame-phase CSV enabled
reproduced the user's severe iPhone behavior without QuickTime, screen capture,
or UI observation. The hands-off attract sequence reached the already-known
Big Blue projection hash `002a81fb84e3f68f`. Runtime telemetry fell through
40.1, 35.0, and 28.4 FPS while draw counts reached 1,176-1,266, both CPU and
video threads saturated, and DMA underruns rose to 321. Thermal state changed
from fair to serious only after sustained overload; it was not the trigger.

Across all 1,257 complete frames with at least 700 draws, the retained CSV
measures:

| Metric | Stable iPhone result |
| --- | ---: |
| effective cadence from mean frame time | 36.41 FPS |
| mean / p95 total frame | 27.466 / 36.076 ms |
| mean CPU-thread time | 26.326 ms |
| mean draws / primitives | 1,119.6 / 74,073.6 |
| mean static cycles / native dispatches | 7.825M / 209,485 |
| mean Metal present / next-drawable wait | 0.024 / 0.014 ms |
| mean texture-create time | 0.016 ms |

The heaviest complete row reached 1,384 draws. This crosses the predeclared
700-draw, sub-55-FPS profile gate and shows why lowering render resolution is
not the primary remedy: the app is already at native 1x, Metal present and
texture allocation are negligible, and the emulation and video worker threads
are the saturated resources.

Two existing hidden launch profiles were then tested without changing source:

- The 90% emulated-clock profile reduced guest cycles about 9.4% and CPU-thread
  time 11.6% across 4,631 identical opening frames. In the 601-frame CPU-only
  dip it reduced total time 8.6%, but later 700-plus-draw scenes still ran only
  about 41-45 FPS and the attract sequence diverged. It changes emulated timing
  and does not make the failing class playable, so keep it hidden and rejected.
- User-initiated QoS at a full 100% emulated clock failed a control/candidate/
  control reversal. Against the two-control midpoint, the identical 601-frame
  CPU dip changed total time by +0.06% and CPU-thread time by -1.77%, while the
  two controls themselves differed by 6.02% and 9.41%. Reject QoS as run drift.

A default-off neutral-input attract route was also prototyped with one-time and
preselection RNG writes. Each fresh process verified the same seed value at the
same emulated frame, but selected different first-demo projection hashes
(`a1269fa93c1b98df` versus `c0546e0402e2344b`). The one-word seed is therefore
not a deterministic route boundary. The prototype was removed before the
stable app was rebuilt and reinstalled.

Decision: the iPhone problem is now directly reproduced and bounded as combined
CPU/video host work, not primarily resolution, Metal presentation, texture
pool churn, or initial thermal throttling. No scheduler, clock, or visual patch
from this iteration earns retention. The remaining route prerequisite is a
guest-state-driven heavy match (or equivalent private replay) that fixes the
roster/stage/demo state itself rather than relying on attract RNG. Profile only
while the same interval simultaneously exceeds 700 draws and 50% video-thread
CPU and remains below 55 FPS.

Private CSV evidence remains outside Git. SHA-256 values for the stable heavy,
90%-clock, QoS-only, and stable-reversal traces are respectively
`a4ef451a836cabf7417c8dcf960687506ea5f979531ae7f9b908aee15bb4b7a3`,
`d66c287708ba5c77ba392f804916c3ace282d9a71e90925b9e9536eaae0d4f79`,
`5af4197f57e4244eaa324518814c4e462b6ed6369401fc97ead05b958f6a8484`,
and `d415192f28ac5372a6e3dc471abce122c855f71ee8ec4317b5c8720e145384b4`.
The installed app was returned to a normal launch with the pre-experiment
preferences and play-time file restored byte-for-byte; controller, graphics,
save, and signed-module files already matched their backups.

## Next correctness-neutral candidates

### Completed graphics-lane diagnostic

Make one default-off diagnostic change; do not alter retention yet:

1. `Common/FramePhaseTiming.h`
   - Add opt-in counters for texture-pool hit, empty-range miss,
     same-frame-ineligible miss, expiry, recreation of the same configuration
     within 30 frames, and texture/framebuffer creation calls and time.
2. `VideoCommon/TextureCacheBase.h` and `.cpp`
   - Increment the miss reason in `FindMatchingTextureFromPool`.
   - Time only the real `CreateTexture` plus optional `CreateFramebuffer` path
     in `AllocateTexture`.
   - Count entries removed by the existing three-frame pool expiry in
     `Cleanup`, and retain only a bounded diagnostic-only record of their
     configuration.
3. `VideoCommon/Present.cpp`
   - Export per-frame deltas in the existing buffered phase CSV. The entire
     path remains disabled unless `MELEEPAD_FRAME_PHASE_LOG` is set; do not add
     a timer, polling thread, or UI surface. With logging disabled, only cached
     false checks remain. Resolve a relative diagnostic filename inside
     Dolphin's writable `Logs` directory so the same opt-in path works inside
     an iOS sandbox.

The device run fails the 10% cost gate by roughly two orders of magnitude.
Pool retention is closed. If graphics-heavy video CPU remains a separate
priority, capture one 12-second profile only while telemetry simultaneously
shows at least 700 draws, at least 50% video-thread CPU, and less than 55 FPS.
Classify texture decode/upload, EFB copies, hashing, vertex work, and Metal
encoding separately. Do not infer that distribution from the THP profile.

### Generated-CPU lane

The next candidate is **profile-selected register-resident generated C**, not
a new whole-module backend. It must operate on a stable multi-region corpus and
cross enough guest calls to matter.

### Completed heavy-route selection gate

The two prime-stride runs above replace the THP/movie selection. The generated
candidate corpus is the ten stable chunks in I6, not `0x8032D940`,
`0x80331940`, and `0x80345940`. Preserve the canonical switch-based chunks for
arbitrary entry. Generate optimized regions only for exact entries and edges
that repeat across the heavy windows, and guard once on the invariants required
by their instructions: `MSR.FP`, paired-load enable state, referenced GQR
values, and the absence of an in-region `mtmsr`, `mtspr`-GQR, `rfi`, fallback,
exception, or self-modifying-code hazard. A failed guard dispatches to the
canonical path before changing state.

The optimized path must not add a flag branch at every FP instruction. It
loads the live GPR/FPR/PS1/control set once, keeps it in typed locals across
the bounded region, uses compact selected-site paired-memory lowering, and
materializes architecturally live state at every helper or exit named below.
This remains structurally different from the rejected 1,429-site FP-gate
rewrite.

Dispatch coverage is not host-time coverage. The profile pilot bounds the ten
chunks at about 46.8% of CPU samples before dispatcher attribution. At that
coverage, a 35% local gain projects only 16.4% whole-frame; at least 53.4%
local gain is required to project 25%. Do not begin the generator integration
until a complete graphics-heavy profile plus dispatcher ownership either
supports that local gate or expands the defensible host-time corpus.

### Selection gate before editing — completed

The route, thermal split, prime-stride de-aliasing, phase join, and scene
exclusions are complete in I6. Ten chunks pass the 70% dispatch-coverage gate,
but the graphics-heavy host-time and exact-entry gates remain stricter and
control whether generator work begins.

### Precise proposed implementation

Keep the feature default-off and data-driven. Add a repeatable C-backend region
manifest rather than hard-coding GALE01 addresses into generic code.

1. `DolRecomp/src/app/cli.c` and `cli.h`
   - Accept `--c-state-regions <manifest>` only with the C backend.
   - Validate sorted, aligned, non-overlapping ranges and fail closed on an
     input/module identity mismatch.
2. `DolRecomp/src/app/pipeline.c`
   - Pass the selected ranges into C chunk generation without changing normal
     chunking outside those ranges.
   - Emit the manifest identity into generated metadata so a stale module
     cannot silently load.
3. `DolRecomp/src/backend/c_cfg.c` and `c_cfg.h`
   - Form a bounded single-entry region across statically known guest calls.
   - Reject recursion, indirect branches, system/RFI/fallback operations,
     cache-control hazards, self-modifying writes, and unclassified helpers.
   - Compute live-in, live-out, and helper clobber masks for GPR, FPR, PS1, CR,
     XER, FPSCR, LR, CTR, and cycle state.
4. `DolRecomp/src/backend/emitter.c`
   - Load only live-in guest values into typed locals at region entry.
   - Keep them local across safe blocks and selected direct callees.
   - Spill only helper inputs before a classified helper; reload only its
     declared outputs afterward.
   - Materialize all architecturally live state before every exception,
     fallback, SMC, host-call, cycle-budget, indirect, or outside-region exit.
   - Preserve the existing canonical C function as the non-selected path.
5. `DolRecomp/tests/test_codegen_emit.c` and `test_c_execute.c`
   - Add adversarial cases for every exit class, FP-disabled entry, exception
     enables, exact cycle boundaries, direct-callee return, and invalidated
     code.
   - Differentially compare complete CPU state and touched RAM against the
     canonical emitter.

Only after a data-free preflight passes should the generic changes be captured
as dependency patches and replayed by `scripts/bootstrap-dependencies.sh`.
Do not hand-edit generated game source or commit game-derived state.

### Candidate gates

The experiment stops before a game build unless all of these pass:

- zero differential mismatches across at least 20,000 randomized cases per
  selected family;
- exact fallback, exception, SMC, helper, and cycle-boundary behavior;
- at least 35% median selected-path host-time gain in alternating tests;
- at least 25% projected whole-frame CPU gain from measured physical coverage;
- bounded native-text growth, with no multi-fold module expansion; and
- a credible composition path to the measured 43.2% total CPU reduction.

If it passes, build one private signed candidate and install it in place. Never
uninstall the app or replace its data container. Run control/candidate/control
on the same heavy route, then a 15-minute candidate soak. Retain only a result
that improves both nominal and serious-thermal intervals without a crash,
FIFO error, visual change, audio underrun trend, input regression, save change,
or netplay fingerprint mismatch.

## Optional low-power visual lane

This lane starts only if the correctness-neutral lane cannot credibly reach
the remaining budget.

1. Port only the maintained Lagless FoD behavior from revision 1.02 to 1.00 by
   function identity, not by guessed address offsets.
2. Assert every original instruction before patching and generate a separate
   module from the patched private DOL; never let runtime code mutation force a
   hot static-recompiled chunk into interpreter fallback.
3. Expose it first through a developer-only launch argument named as a visual
   reduction, not as a general performance mode.
4. Disable it for online play unless every peer advertises the identical
   module/patch fingerprint.
5. Measure its frame, CPU-thread, video-thread, and thermal effect separately.

This option can be useful, but it is a different visual product profile. It
must never be used to claim that the full-fidelity iPhone 14 problem is fixed.

## Stop conditions

- If stable hot-region coverage falls below 70%, do not build the region
  candidate; return to physical attribution.
- If selected C regions cannot reach 35% locally, reject the architecture.
- If a retained composition cannot plausibly remove at least 43.2% of the
  measured CPU time, stop calling it a route to 60 FPS.
- If full-fidelity cannot pass the device soak, document iPhone 14 as below
  the supported full-fidelity tier rather than hiding the deficit with frame
  skipping, emulated underclocking, stale-frame duplication, or altered timing.

### I12 — fixed four-player Big Blue reproduction and attribution

The default-off `versus-four-big-blue-v1` route now reaches a consistent heavy
workload without screen automation: VS Melee, P1 Samus, three CPU players
(Kirby, Bowser, Link), and Big Blue. Menu navigation still uses normal emulated
controller input. After the route has verified the VS CSS mode and the expected
human/CPU slot layout, it writes only the four transient character-kind bytes
in guest RAM to eliminate CPU-token overlap, fixes the benchmark random seed,
and forces Big Blue through the validated stage-selection structure. The route
stops generating input as soon as CSS is left, so Start cannot leak into stage
selection or gameplay. These writes do not touch the disc image, module, save,
or retained configuration.

This replaces several rejected route revisions. The first assumed P1 was open,
an unselected-token position overlapped P3's door, one Link target sat on an
icon edge, and moving overlapping CPU tokens changed the wrong player. Each
failure was visible in guest-state logs and was removed rather than hidden with
longer timing. Two final runs reached the same fixed roster and stage, although
per-frame draw and dispatch counts are not identical; treat this as a
repeatable workload class, not a frame-exact deterministic replay.

The clean run is
`/private/tmp/meleepad-iphone14-versus-four-big-blue-v58.csv` (SHA-256
`dbd4fa8a3bbf28fe9d156f0e0bc1e8f2d901c6223148bd46ee5e826effcdc607`).
The dispatch-sampled run is
`/private/tmp/meleepad-iphone14-versus-four-big-blue-v59.csv` (SHA-256
`fc5e8f39cc4f49b651b8c3e74a4808e2fc0e5503101eaec66be8cfe31d5879ea`),
with entry samples in
`/private/tmp/meleepad-iphone14-versus-four-big-blue-v59-dispatch.csv`
(SHA-256
`934be63a910efef4b58ac6d94cf3abbd4012895cbc9709435dd7aa49c97688bb`).
The sampled run captured 229,377 dispatch entries.

At emulated-frame windows 3000–3600, 3600–4200, 4200–4800, and 4800–5400,
wall time per 600 emulated frames was 10.80, 11.77, 11.86, and 12.56 seconds:
55.57, 50.99, 50.57, and 47.78 FPS. The CPU thread was effectively saturated
and the video thread remained heavily loaded. Thermal pressure stayed fair
through the selected windows and became serious only near the end, so thermal
state amplifies the slowdown but does not explain its onset.

With the actual generated chunk-grid origin `0x80005940`, 27 regions were
stable across all four windows and the leading 12 covered 70.30% of dispatch
samples. The largest stable regions begin at `0x8035D940`, `0x80369940`, and
`0x8033D940`; the hottest single entry is `0x803408D4`. The address range and
generated call patterns point toward guest GX/display-list command generation,
consistent with roughly 630 draws per frame and concurrent video-thread load.
That semantic attribution is still provisional because the available decomp
symbols are revision 1.02 while this module is revision 1.00.

This is meaningful diagnosis and a reliable experiment harness, not a retained
performance improvement. Before changing code, map the hot revision-1.00 entry
and its callers by instruction identity. Only a narrow specialization with a
canonical fallback should proceed to a device A/B test; do not revive the
previously regressive global inline or broad direct-call experiments merely
because dispatch coverage now passes 70% on this one workload.

### I13 — host-time attribution and secondary scheduler-idle retention

The first dispatch-duration implementation timed diagnostic hash-map work as
well as generated execution and overstated CPU coverage by 2.4-3.3x. Those
v60-v63 captures are rejected. The corrected default-off implementation starts
its monotonic timer immediately before `m_module->dispatch`, records the
adjacent clock-call cost, and otherwise keeps the existing prime-stride sample
selection. Two physical iPhone captures at interval 4,093 and offsets 877 and
1,733 estimate 76.6-80.7% of independently measured CPU-thread time. This is
credible inclusive dispatch attribution rather than another frequency proxy.

The two accepted captures agree at corresponding route windows. Eighteen
regions stay within the 1.25x de-aliasing limit; the leading twelve
conservatively cover 70.359% of dispatch host time. Exact instruction identity
also confirms `0x803408D4..0x8034099C` as SDK `PSMTXConcat`, but its earlier
whole-function replacement remains closed: the locally fast implementation's
global replacement probe taxed every dispatch and projected only hundredths of
a millisecond net. No isolated matrix replacement or broad direct-call retry
was made.

The new time profile instead exposed a regression in retained idle policy.
`0x80349494`, previously proved to be the revision-1.00 OS scheduler's
`RunQueueBits == 0` poll, again consumed 10.8-18.5% of dispatch time. The later
netplay work had replaced the sole configured main idle address with
`0x80348814`; it did not preserve the first proven scheduler boundary. Current
generated code still shows the three-instruction poll returning to the runtime
at its exact 256-cycle boundary, and the historical candidate already proved
that `CoreTiming::Idle()` advances to the interrupt/event that ends it.

Patch 0049 therefore adds a second ordinary static-recompiler idle address.
It does not replace the current main or caller-qualified boundaries, and its
environment override remains available only for controlled experiments. The
retained product policy is revision-scoped as
`StaticRecompSecondaryIdlePC = 0x80349494`; executable-only desktop boot loads
the same GameINI key so netplay peers remain symmetric. The iOS host also sets
the same value explicitly, matching its existing idle policy.

A single signed binary was tested control/candidate/control at native timing,
1x EFB scale, with the fixed Samus/Kirby/Bowser/Link Big Blue route. A rebuilt
default-config product then supplied the independent candidate repeat:

| Emulated frames | Control midpoint FPS | Opt-in FPS | Default repeat FPS | Control midpoint CPU | Default repeat CPU |
| --- | ---: | ---: | ---: | ---: | ---: |
| 3000-3600 | 56.996 | 59.902 | 59.913 | 16.097 ms | 14.455 ms |
| 3600-4200 | 52.219 | 59.210 | 59.387 | 18.474 ms | 16.077 ms |
| 4200-4800 | 51.744 | 59.073 | 59.248 | 18.643 ms | 16.026 ms |
| 4800-5400 | 49.344 | 57.703 | 57.724 | 19.555 ms | 16.368 ms |

The default repeat reduces CPU-thread mean by 10.2-16.3% and improves cadence
by 5.1-17.0% against the two-control midpoint. Draw and primitive means remain
closely matched. Across all 2,400 selected rows, control A and the opt-in arm
both report 4,804 hook fallbacks; fallback-step totals differ by only 102 out of
about 1.862 million. Static guest cycles fall from 6.33-8.11 million per frame
in control to 4.06-4.26 million in the retained build, which is the expected
removal of empty scheduler spinning rather than game work. Both candidates
log the first secondary-idle hit, complete the route, and retain the same stage
projection sequence. No screen-control or capture tool was used.

The improvement is retained but does not close the goal. The late fair-thermal
window remains 17.325 ms mean / 57.724 FPS with a 19.118 ms p95, and the video
worker now consumes more of the available second performance core because the
game is producing frames faster. Re-profile the retained build before choosing
another mechanism; `0x80349494` must disappear from the remaining host-time
profile. The next candidate must improve the new CPU/video limit without
changing emulated clock, render fidelity, audio, input, save behavior, or the
canonical netplay boundary.

Private evidence remains outside Git. Corrected host-time phase/sample SHA-256
pairs are `d4f3c0f6...e210b` / `7de2e9cf...d98a6306` and
`1a1c99e4...91bb` / `3e2c09a5...90923b`. Control A, opt-in candidate, control
B, and default candidate phase hashes are respectively
`323d4786...7d7c`, `ad37520e...6ab`, `6ff6a189...1d47`, and
`55583f4a...79e0`.

### I14 — retained-build re-profile and GX matrix-family candidate

Two post-retention profiles confirmed that `0x80349494` no longer appears in
the sampled dispatch set. The retained scheduler policy is therefore doing the
specific work intended by I13. The fixed route remains a workload class rather
than a frame-exact replay: v69 carries about 624-635 draws per frame in the
selected windows and falls to 58.821 FPS late, while v70 carries about 562-593
draws and remains near 59.81 FPS. Both stay thermally nominal. Combining their
host-time profiles produces only 62.6614% conservative stable-region coverage,
below the 70% gate, so the proposed general region generator remains closed.

Exact entry identity is more stable than broad region rank. The adjacent
revision-1.00 entries `0x8033FB64`, `0x8033FBA0`, and `0x8033FC1C` map by
instruction identity and the constant revision delta to `GXLoadPosMtxImm`,
`GXLoadNrmMtxImm`, and `GXLoadTexMtxImm`. Together they account for roughly
11.5-12.2% of dispatch host time in both offsets. With the neighboring
`PSMTXConcat`, the family remains within 17.5-19.6% across every selected
window. This supports one chunk-local entry specialization; it does not reopen
the rejected global `PSMTXConcat`, gather-width, GPFIFO, or GQR0 experiments.

A disposable data-free implementation reproduces the exact prologue, stack,
GPR/LR/CR/downcount, paired/scalar float, FIFO event, and 256-cycle-boundary
semantics for the three GX routines. It fails closed to canonical dispatch when
FP, LSQE, GQR0, matrix-memory, or stack-memory preconditions are not satisfied.
Direct and built-module differential tests each pass 200,000 randomized cases
per routine (1.2 million comparisons total), with matching module ABI,
code-range, SMC-range, chunk-range, and original-text-hash metadata. Alternating
local measurements reduce the selected-path median by 57.0-60.1%, enough to justify a private physical
candidate without adding a common-dispatch branch.

The first valid candidate/reversal pair used native timing and 1x EFB scale:

| Emulated frames | Candidate FPS | Reversal FPS | Candidate CPU | Reversal CPU | CPU reduction |
| --- | ---: | ---: | ---: | ---: | ---: |
| 3000-3600 | 59.896 | 59.907 | 13.504 ms | 14.325 ms | 5.7% |
| 3600-4200 | 59.896 | 59.684 | 15.286 ms | 15.987 ms | 4.4% |
| 4200-4800 | 59.889 | 59.256 | 15.255 ms | 15.996 ms | 4.6% |
| 4800-5400 | 59.249 | 57.427 | 15.321 ms | 16.556 ms | 7.5% |

Draw counts differ by only 0.1-1.0% and primitive counts remain closely
matched. The candidate stays thermally nominal; the back-to-back reversal
reaches fair late, so the reversal delta is an upper bound. Comparison with
the cooler, similarly heavy v69 control instead supports a smaller 2.3-3.2%
CPU-thread reduction and a 0.73% late-FPS improvement. This is a credible
incremental gain, not evidence of sustained 60 FPS. Candidate and reversal
both accumulate audio underruns when the two performance threads saturate.

The known-good module was restored byte-for-byte after the pair. Keep the GX
candidate private and unretained until a cooled independent candidate repeat
reproduces the CPU reduction and a longer soak finds no correctness, audio,
input, save, or netplay-fingerprint regression. If retained, capture the
generic implementation as a dependency patch; never commit the copied
game-derived chunk or private generated module.

Private evidence remains outside Git. Retained profiles v69 and v70 have
SHA-256 `1640d271...a12667b` and `dc0ffa49...91b447`. Candidate v72 and
reversal v73 have SHA-256 `268aff0a...6a76e` and `44695770...5205c2`.

The first cooled independent repeat, v74, remains nominal and records 59.795,
59.909, 59.212, and 59.813 FPS across the same four windows. It has no new
FIFO, assertion, crash, or runtime error and accumulates 23 audio underruns by
the final selected interval. Workload is lighter than v72 in some windows, so
v74 is supporting evidence rather than a standalone percentage claim; it must
be paired with an equally cooled phase-only control.

The phase trace also narrows the graphics question. In v72 and v74, measured
video-build time is almost entirely `CAMetalLayer::nextDrawable` wait. Across
the full 2,400-frame v72 selection, Metal pipeline creation totals 8.119 ms,
texture creation 22.635 ms, framebuffer creation 0.015 ms, and the only EFB
VRAM pipeline miss 0.109 ms. Apple documents that `nextDrawable` waits when no
drawable from the limited pool is available, commonly until a display refresh;
it is not direct evidence that shader execution itself consumed that duration.
This matches the CPU-thread tail crossing the 16.67 ms budget while the video
thread reaches presentation and waits.

Render scale 1 is already Dolphin's native 640x528 EFB and the lowest supported
setting in the current UI and runtime clamp. A sub-native viewport would be a
new reduced-fidelity mode. Apple recommends a temporary viewport reduction to
test a suspected high-resolution fragment bottleneck, but the current internal
trace instead selects CPU execution and frame pacing. Do not add sub-native
rendering as the next full-fidelity experiment.

References:

- <https://developer.apple.com/documentation/quartzcore/cametallayer/1478172-nextdrawable>
- <https://developer.apple.com/documentation/xcode/analyzing-the-performance-of-your-metal-app/>
- <https://developer.apple.com/documentation/metal/improving-your-games-graphics-performance-and-settings>

#### Final GX matrix-family decision

The equally cooled phase-only control v75 rejects the candidate. It stays
nominal and reaches 59.906, 59.901, 59.800, and 59.533 FPS. Against v75, the
closely workload-matched v72 candidate changes CPU-thread mean by -0.40%,
-0.29%, +0.12%, and -0.85% in the four windows, where positive means a saving.
Guest cycles differ by no more than 0.52% and primitives by no more than 0.37%.
The candidate therefore ranges from statistically unpersuasive noise to a
small regression; it does not reproduce the earlier warm-reversal delta.

The v74 repeat cannot rescue the result. Its first three windows execute
2.14-6.85% fewer guest cycles and 3.41-7.33% fewer draws than v75, so their
lower CPU means are not equal-work evidence. Its late window is closer but
still has 2.25% fewer draws and only a 0.47% FPS lead. Do not retain or promote
the GX matrix family, and do not run the planned soak. The control module is
already restored and verified byte-for-byte.

This rejection also explains why inclusive dispatch-time share was too
optimistic for leaf selection. A dispatch sample beginning at a GX entry can
include continuation work after that leaf; multiplying its whole sampled
duration by the isolated leaf speedup overstates removable time. The next
attribution step measured the rejected candidate's guards and exact entry
duration under the existing default-off profilers. The bounded device counter
run records 3,145,728 position calls, 2,097,152 normal calls, and 1,048,576
texture calls. Their specialized guards pass 99.9843%, 99.9943%, and 99.9890%
of calls respectively; all failures are floating-point-mode mismatches, with
zero LSQE, GQR0, stack, or matrix-memory failures. The specialization is
therefore active on the physical device, and guard rejection does not explain
the missing whole-game improvement.

The matching-offset v77 device-time profile instead exposes a device-specific
codegen gap. Against the v69 control, corrected mean duration per sample changes
from 530.8 to 647.8 ns for `GXLoadPosMtxImm` (+22.05%), 375.4 to 315.7 ns for
`GXLoadNrmMtxImm` (-15.91%), and 594.1 to 506.9 ns for `GXLoadTexMtxImm`
(-14.68%). The unchanged neighboring `PSMTXConcat` moves only +1.11%, which is
a useful sampling control. The largest routine regresses and the other two
deliver far less than the 55-60% Apple Silicon host microbenchmark result; in
aggregate this family cannot remove meaningful physical-device CPU time.

Do not select another isolated leaf from inclusive dispatch share. A local
microbenchmark alone must no longer qualify an exact-entry candidate for a
physical performance build without a defensible device-side exclusive-time
estimate. The next candidate must cover a bounded composed path or superblock
with enough measured exclusive CPU time to clear the whole-frame gate. The
known-good module was restored and copied back for byte-for-byte verification;
the app remains stopped and its data remains installed.

Private v74 and v75 phase SHA-256 values are `e73f6fca...5c7a7b7f` and
`528869b1...7a638716`. The v77 phase and dispatch-time sample hashes are
`7eb967be...24c40` and `9317b81f...16e76`.

### I15 — physical-iOS A15 scheduling retention

The first dispatch-burst attempt, v78, is invalid. Its absolute `/tmp` output
path was not writable inside the app sandbox, and the dormant logger retried
the failed open on every full buffer. That produced 1,068,513 error lines,
artificially saturated the CPU, and eventually raised thermal state to fair.
It is excluded from every performance and path-selection claim. The logger now
clears its path and pending samples after the first open failure, matching the
existing dispatch-time logger's fail-closed behavior; the focused source check
passes.

The corrected v79 control used the app container's writable temporary path.
It recorded 901,120 rows through emulated frame 5,656 with zero open failures,
remained thermally nominal, and held about 59.9 FPS through the observed heavy
interval. Exact consecutive sequences confirm that the callful path from
`0x8036C8B0` through `PSMTXConcat`, `GXLoadPosMtxImm`, the matrix-normalization
parent, and `GXLoadNrmMtxImm` is stable in all four selected windows.
Context-weighting the v69 duration profile by v79's observed return edges gives
14.84-17.29% of dispatch CPU time for that composed path. Treat the burst
stream as structural evidence only: retaining 15 usable edges per 16,384
dispatches implies an effective single-edge scale of 16,384/15, so the older
analyzer's configurable raw sample-period multiplier is not an execution-count
claim for multi-entry sequences.

Before implementing a new superblock, an object-only compiler screen found a
broader and lower-risk physical-iOS opportunity. The generated module had no
CPU scheduling target. Adding `-mtune=apple-a15` changes ARM64 output in all
three hottest generated chunks. AppleClang's driver and LLVM IR both confirm
that the minimum target remains `apple-a7` and the six target-feature flags are
unchanged; only `tune-cpu=apple-a15` is added. This is scheduling tuning, not an
A15-only instruction-set requirement.

One signed tuned/control physical pair completed the fixed route at native
timing and 1x EFB scale with nominal thermals and no new crash, assertion, or
FIFO error:

| Emulated frames | Tuned FPS | Control FPS | Tuned CPU | Control CPU | CPU reduction |
| --- | ---: | ---: | ---: | ---: | ---: |
| 3000-3600 | 59.783 | 59.914 | 12.672 ms | 14.058 ms | 9.86% |
| 3600-4200 | 59.910 | 59.809 | 13.254 ms | 15.802 ms | 16.13% |
| 4200-4800 | 59.239 | 59.607 | 14.258 ms | 15.817 ms | 9.86% |
| 4800-5400 | 59.776 | 58.780 | 14.476 ms | 15.842 ms | 8.62% |

The first three windows carry 2.26-6.55% fewer guest cycles and 3.33-7.35%
fewer draws in the tuned run, so their full deltas remain upper bounds. The
late window is the acceptance anchor: guest cycles differ by only +0.09%,
while primitives are +2.64%, CPU time is 8.62% lower, and cadence improves by
1.70% / almost exactly one FPS. This is sufficient to retain the scheduling
tune for the requested experimental physical-iOS build, but not to claim
sustained 60 FPS on every route or device.

`RECOMPCORE_MODULE_TUNE_CPU` is now a generic module-template cache setting,
captured by dependency patch 0050. The physical iOS build selects
`apple-a15`; the Simulator and other platforms do not. This applies the same
compatible tuned module build to iPhones and iPads rather than keeping a
one-off replacement binary. A focused repository test rejects accidentally
using `-mcpu=apple-a15`, which would conflate scheduling with the ISA target.
The known-good control was restored and verified byte-for-byte after v80. The
normal `ios-build-core-device.sh` path then rebuilt successfully after fixing
an older overlapping-patch bootstrap check; its 81,235,476-byte executable
text and SHA-256 are identical to the tested temporary tuned module. That
canonical signed output is now deployed and copied back for byte-for-byte
verification. The app remains stopped and all installed data remains in place.

Private v79 burst, v80 tuned phase, and v81 control phase SHA-256 values are
`1a1510a2...e9acb`, `845a7b12...f1981`, and `c2c3586b...3573f`.
