# Learning from other Melee ports

Started September 9, 2026. Active bounded investigation on
`codex/native-port-learning`. The prior session handoff remains historical.
No new device install, release, or performance improvement is claimed here.

## Goal and loop

Understand the two linked projects, verify the meaning of 120 FPS, and use
source plus existing iPhone evidence to select one meaningful experiment.
For each candidate: identify the cost, state the expected effect, check exact
behavior against the existing implementation, then measure the same workload.
Reject non-transferable ideas before building. Keep the stable device builds,
ISOs, saves, and netplay behavior intact.

## Pinned sources

- [jonrosner/melee-native alpha.1](https://github.com/jonrosner/melee-native/releases/tag/v0.1.0-alpha.1),
  `f41fecfc86843e20e3054e00fd56bdb4cbb01e42`.
- [t3dotgg/melee4mac](https://github.com/t3dotgg/melee4mac/tree/a276aeb70f9879204d891d967f1c9442523568e1),
  `a276aeb70f9879204d891d967f1c9442523568e1`.
- MeleePad public baseline: `bbab869` (documentation), stable runtime release
  `83b81ed` / Preview 4 build 18; private build 20 uses unchanged game modules
  plus scene diagnostics. Research branch includes those diagnostics.

Source checkouts are ignored under `ref/melee-native-alpha1/` and
`ref/melee4mac-research/`. They are reference material, not build instructions
or authority to modify their upstream repositories. No upstream messages sent.

## What 120 FPS means

The claim comes from melee4mac's [refresh implementation](https://github.com/t3dotgg/melee4mac/blob/a276aeb70f9879204d891d967f1c9442523568e1/native/macos/refresh/README.md).
It runs game logic, input, animation clocks, and collision at 60 Hz. After each
normal render it predicts joints and camera motion half a frame forward and
renders again. It restores saved transforms before simulation resumes. This
is additional geometry rendering, not just presenting an identical buffer,
but it is not a 120 Hz simulation or a 120 Hz input-response guarantee.
Quaternion/custom-matrix poses, discontinuities, render side effects, and
60 Hz particles/UI remain limitations.

The [recorded benchmark](https://github.com/t3dotgg/melee4mac/blob/a276aeb70f9879204d891d967f1c9442523568e1/docs/native-macos.md#fluidity-checks-on-2026-09-08)
uses an M5 Max, a saved two-fighter match, short 15–20 second samples, and a
60 Hz monitor. It reports 119.97 render FPS at 4x and 119.99 at 6x; simulation
remains approximately 60 updates/s. Its authors explicitly distinguish
presentation callbacks from complete visible refreshes. This is not evidence
of sustained four-fighter A15/iPhone performance or verified 120 Hz scanout.
We have inspected their source and reports, not independently reproduced them.

Melee-native alpha.1 instead targets 60 FPS and does not claim a verified lock.
Its release has incomplete saving and mode/visual coverage. These two projects
must not be treated as equivalent performance evidence.

## Architectural differences

| Project | Execution and rendering | Implication for MeleePad |
|---|---|---|
| MeleePad | Generated PowerPC-to-C compiled to ARM64, original guest layout, Dolphin-derived Metal/audio/system services | Preserves much original behavior, but translation/state and hardware-compatibility costs remain |
| melee4mac | Same broad static-recompilation family, with game-loop visual hooks and runtime patches | Individual runtime ideas are plausible transfers; its desktop measurements are not iPhone acceptance |
| melee-native | Compiles recovered game C directly; native SDK/runtime and Aurora GX bridge | Potentially removes larger classes of compatibility overhead, but requires a different port architecture |

Melee-native's [CMake target](https://github.com/jonrosner/melee-native/blob/f41fecfc86843e20e3054e00fd56bdb4cbb01e42/native/CMakeLists.txt)
compiles game sources with native definitions and links Aurora services.
Its [porting notes](https://github.com/jonrosner/melee-native/blob/f41fecfc86843e20e3054e00fd56bdb4cbb01e42/native/PORTING_NOTES.md)
show why this is not a replacement module we can drop in: LP64 pointer layouts,
endianness, bitfields, fixed offsets, asset relocation, and original memory
aliasing all need repair. Adopting that architecture would also require renewed
iOS rendering, saves, controls, lifecycle, and deterministic netplay validation.

## Ranked transfers and current decisions

1. **Source-informed GX boundary specialization:** strongest next investigation.
   Our existing scene-filtered combat profile attributes 7.10% of sampled guest
   time to `GXLoadPosMtxImm` and 3.83% to `GXLoadNrmMtxImm`. The native-source port
   demonstrates the architectural benefit of working at SDK boundaries. Inspect
   a narrow equivalent within our original guest layout before considering a
   full source-port rewrite. These shares are not whole-app speedup forecasts.
2. **Submit Metal commands before drawable/presentation waits:** real structural
   difference in melee4mac's [fluid-render patch](https://github.com/t3dotgg/melee4mac/blob/a276aeb70f9879204d891d967f1c9442523568e1/native/macos/patches/fluid-render.patch).
   Our renderer still acquires the drawable before its final submission and
   submits after the presentation deadline. Screened against existing iPhone
   evidence below; useful latency/tail lead, weak first choice for sustained
   combat throughput. Do not change drawable count and submission order together.
3. **Separate simulation/render/GPU/display metrics:** useful measurement model
   from their [Metal guide](https://github.com/t3dotgg/melee4mac/blob/a276aeb70f9879204d891d967f1c9442523568e1/native/macos/render/README.md).
   Add missing measurements only when they decide an experiment; reuse our
   existing scene, frame-time, and audio logs first.
4. **Read-time input refresh:** potentially improves input age, not frame rate.
   Their hook excludes deterministic sessions. Do not transplant it into our
   netplay path or assume existing touch input has the same sampling delay.
5. **Faster disc transfer/cache:** targets launch and loading, not sustained
   loaded combat. Their disc override excludes netplay. Keep separate from FPS.
6. **120 FPS prediction:** defer until sustained 60 FPS is solved; extra rendering
   increases work. It is a later optional visual feature for capable hardware.
7. **Wholesale direct-source port:** separate feasibility project, not this
   stable app's next patch. Learn from native boundary design and failure tests.

## First screening experiment — existing iPhone trace

Reused private `scene-followup/scene-profile` phase CSV and runtime log, without
running a new game or altering a device. Select consecutive valid `vs-combat`
reports with unchanged session/transition count and advancing sampled frames;
exclude 250 ms at both ends of each interval. This selects 6,439 phase rows.

| Metric | Mean | Maximum |
|---|---:|---:|
| Recorded CPU-thread work | 19.580 ms | 109.775 ms |
| Drawable acquisition | 0.384 ms | 9.459 ms |
| Present phase | 0.025 ms | 0.324 ms |
| Recorded presentation sleep/spin | 0 ms | 0 ms |
| Texture creation | 0.013 ms | 0.985 ms |
| Metal pipeline creation | 0.004 ms | 2.272 ms |

This is an instrumented run and CPU/GPU phases overlap. These figures neither
measure GPU busy time nor prove an absolute optimization ceiling. They do show
that the proposed presentation-deadline overlap has no recorded sleep to hide
in this capture. Drawable waits have occasional tails, but average CPU work
is the more substantial lead. Do not spend another device-build cycle assuming
Metal queue changes will solve this trace's sustained slowdown.
Private screening output: `ref/native-port-learning/metal-cost-screen.json`.

## Next bounded experiment

Inspect generated position/normal matrix upload routines alongside the exact
v1.02 decompilation. Determine whether redundant guest floating-point/state
marshalling can be removed while preserving the full CPU state and ordered FIFO
writes. Keep MMIO delivery, command ordering, cycle accounting, and original
fallback behavior; do not bypass the GPU FIFO into renderer state.

Before a physical build, require differential tests against the original module:
normal and exceptional floats, RAM boundaries/aliasing, relevant GQR states,
all CPU state, RAM side effects, and FIFO byte/order equivalence. Reject if the
change cannot preserve those contracts or show meaningful host cost reduction.
If viable, use one controlled physical A/B/repeat with matching scene and thermal
start; judge mean/p95 slow frames and audio underruns together. No promotion from
one favorable pair. Keep diagnostic build 20 until evidence justifies replacing
it. Do not repeat the earlier arithmetic matrix experiment or broad sleep sweeps.

## Current completion boundary

Architecture and 120 FPS comparison complete. Metal submission candidate
screened and deprioritized for sustained iPhone throughput. GX boundary
specialization passed the host screen; physical comparison remains pending.
No speed patch has been installed.

## Candidate implementation in progress

The private candidate specializes only the load prefix of `WriteMTXPS4x3`
(`0x80341408`) and `WriteMTXPS3x3from3x4` (`0x8034143C`). It uses the existing
bit-preserving paired-single conversion, retains scalar-load semantics, and
branches back into the original generated code before the first write. Guards
require enabled floating-point/paired loads, GQR0 zero, and a complete ordinary
RAM input span. Other inputs retain the original implementation, including
mid-function entry. Cycle decrement and all stores remain in place.

This is deliberately not raw matrix copying: paired-single conversion and
callback-visible register state are part of the contract. The differential
harness compares final CPU state, RAM, return status, module metadata, and full
CPU snapshots at ordered MMIO callbacks, including callbacks that change CPU
state. Exceptional floats, nonzero GQRs, disabled FP/paired loads, RAM boundaries,
aliases and unaligned input are included. The Mac module comparison passed 3,000 cases per helper (6,000 total).

Private reproduction: `ref/native-port-learning/prepare-gx.py` builds from the
existing exact module object set; `test-gx.py` prepares and runs the comparison.
The link command and source hashes are retained in `gx-build.json` after a
successful link. No module or generated game code is added to Git.

## Host result and hardware availability

The optimized Mac module linked with only the target chunk object replaced.
ABI, code ranges, SMC ranges, and original chunk hashes compare equal. All
6,000 differential cases passed, including complete callback-time CPU snapshots
(normalizing only the RAM allocation pointer), ordered MMIO events, return
status, final CPU state, and the full 5 MiB test RAM image. The test is retained
as `tests/GXUploadDifferentialTests.c`; run with original and candidate module
paths. These synthetic callbacks do not replace real runtime/graphics checks.

Five alternating-order host microbenchmark rounds measured:

| Helper | Control range | Candidate range | Median paired reduction |
|---|---:|---:|---:|
| Position upload | 69.5–73.7 ns | 52.5–53.9 ns | 25.29% |
| Normal upload | 50.3–53.5 ns | 39.2–42.3 ns | 19.60% |

These are isolated helper costs with synthetic MMIO callbacks, not GPU or FPS
measurements. The 11% profile share belongs to containing upload routines;
multiplying it by the helper microbenchmark percentage is not a measured
whole-game gain. This passes the host screen and justifies a single bounded
device comparison, not promotion.

`python3 scripts/prepare-gx-upload-experiment.py --generated <private-generated-dir>
--out <fresh-ignored-dir>` reproduces the tested private generated chunk byte
for byte. It rejects other source hashes and non-private output; it never
enables the candidate. Build with the original flags and module object set.
Exact local compile/link commands and hashes are in the ignored `gx-build.json`;
`test-gx.log` contains the differential and timing results.

CoreDevice currently lists both attached-device records as **disconnected**.
No device was launched, installed, or modified. The iOS module build completed successfully; physical validation remains
pending connection. Do not rebuild the completed candidate without a change. Do not claim device acceptance
from the host test or install automatically if the user is actively playing.

## Completed iOS build and resume gate

The existing linker finished successfully. `ios/gx-load-module.dylib` is an
ARM64 iOS library with minimum OS 16.0 and SDK 26.5. The compile retained
`-mtune=apple-a15`, `-ffp-contract=off`, `-fno-fast-math`, and the original
optimization/LTO settings. Its generated candidate source matches the tested
Mac source byte for byte. The original iOS control module's `__text` hash
matches the retained build-20 game module, eliminating a stale-control concern.
The candidate has a different `__text` hash, as expected. Receipts and hashes
are in `ref/native-port-learning/ios/artifact-audit.json` and `gx-build.json`.

Both CoreDevice device records were checked again and remain disconnected.
No app packaging, signing, installation, or device launch occurred in this pass.
Host validation is complete; physical runtime acceptance is incomplete. The
next step requires reconnecting and unlocking the iPhone, then preserving its
current data and checking whether the owner is actively playing before testing.
Do not replace build 20 permanently unless the controlled comparison supports it.

Once connected, use the existing scene-aware control protocol, same v1.02 image,
1x/4:3, and matching thermal starts. Keep save/config snapshots and original
build-20 package available for an in-place restoration. Compare combat-only
frame timing and audio underruns, exclude results and mixed scene windows, and
repeat only a promising first pair. A disconnected device is not a rejected
optimization result. Do not turn this wait into unrelated research or new tests.
