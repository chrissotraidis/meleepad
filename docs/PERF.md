# meleepad performance ledger

G5 is active. G4 passed with a clean controlled 1v1 on 2026-08-24.

PERF-287 attributes and reverses a new ordinary 54.2 FPS / 54.3 VPS / 0.917
speed interval. The failing two-draw workload used only 67.4% CPU-thread and
6.6% video-thread time. A Codex Computer Use assertion began 0.849 seconds
before the row, and Core Audio reported a MeleePad overload 21 ms afterward.
A fresh 180-second no-observer control retains 16 reports at 59.7-60.0 FPS/VPS,
0.989 minimum speed, and one underrun; it later holds 59.9 FPS at 171.4%
aggregate app CPU. Keep the product unchanged and exclude Computer Use from
the manual acceptance window. A third fresh process then reproduces the effect
causally: one state read is followed by 56.2/56.5 FPS/VPS and three underruns
on the same light projection, then immediate recovery. That induced window has
no audio overload, so Computer Use is sufficient for sub-59 pacing; the
original overload amplified the first event. See
`docs/artifacts/2026-09-02/g8-computer-use-audio-overload-reversal.md`.

PERF-258 repairs the bounded transition correctness screen before another
throughput candidate. The first exact-combat reports were cache-control false
positives: generated `dcbi`/`dcbf` hooks changed cache state that lockstep could
not replay but did not mark the block unsafe. Patch 0032 adds that diagnostic
guard. The corrected route removes those four entries but retains 21 distinct
reports, beginning at `0x80358ABC -> 0x80358AE8`. Minimize that interval before
classifying it as a journal blind spot or generated semantic mismatch. This is
not an FPS gain; row 7 remains failed. See
`docs/artifacts/2026-09-01/g8-transition-lockstep-cache-filter.md`.

PERF-257 rejects two broad explanations for the iPad row-7 failure. Exact
frame attribution finds sustained 27-35 ms frames with no Metal pipeline or
shader creation, while tail native dispatches and guest cycles rise 2.79x and
2.03x. A strict-compatible current-source host-PGO app then decays to 10.3 FPS
/ 10.6 VPS and 373 underruns in exact Fountain combat; underruns reach 547.
The retained frame also shows stretched/fragmented Samus and reflection smear
without an SMC, FIFO, desync, thermal, or memory warning. Treat the next step
as silent correctness/state-divergence attribution, not another compiler or
late-state throughput experiment. See
`docs/artifacts/2026-09-01/g8-progressive-fountain-collapse-and-menu-cleanup.md`.

PERF-206 retains a signed-development-only external ARM64 PC ring and exact
start-to-start analyzer after `xctrace` CLI counters failed. A 120-second warm
Fountain ring retains 78,744 error-free samples and joins 48 samples to four
active-combat CPU overruns versus 73,871 body samples. The leading broad
symbol is `StaticRecompCore::Run` at 2.99x; state transfer and the
8033/8035/8036/8038 generated families are sparse and distributed, with no
leaf above four overrun samples. All named mechanisms already have focused
and live rejections. Retain no product edit and make no FPS claim. See
`docs/artifacts/2026-08-30/g5-warm-native-pc-ring-attribution.md`.

PERF-203 rejects CLI CPU Counters as an exact warm-frame attribution method on
this host. Corrected gates reproduce first-complete/second-live Fountain, but
the 20-second attached trace crashes `xctrace` during counter aggregation and
cannot export; a five-second data-free attach also hangs and grows to 4.4 GiB.
No counter metric or frame join is claimed. See
`docs/artifacts/2026-08-30/g5-warm-cpu-counter-cli-rejection.md`.

PERF-204 rejects another compiler-splitting build. Late machine-function
splitting is unsupported for arm64 Mach-O. Normal frontend-PGO objects for the
selected `func_8035D940`/`func_80361940` chunks already contain 311/315 cold
functions, and explicit IR hot/cold splitting produces byte-identical objects
at 294,988/286,464 text bytes. See
`docs/artifacts/2026-08-30/g5-hot-cold-splitting-rejection.md`.

PERF-202 rejects another warm-specific PGO collection/build. The active
profile already spans verified Fountain combat, and exact coverage
reconstruction gives PERF-196's five enriched warm PCs 2.524M-17.523M hits.
An independent full local-training repeat assigns all five the exact same
counts and matches their containing function hashes, counter shapes, and
entry counts. The proposed candidate has no new coverage or weighting signal,
so no game build is justified. See
`docs/artifacts/2026-08-29/g5-warm-profile-refresh-rejection.md`.

PERF-200 retains a sanitized host-only `CAMetalDisplayLink` preflight. An
exact-60 source yields 599/599 actual intervals within 16.7 ms and no modeled
source repeats. Requesting 59.94005994 Hz is quantized to the fixed panel's
60 Hz cadence: 2,399/2,399 generated-color intervals meet 16.7 ms, but two of
2,400 callbacks have no new valid 59.94 Hz source frame. Integration would
require stale duplication, interpolation, or changed deterministic guest/
audio timing and is rejected. See
`docs/artifacts/2026-08-29/g5-metal-display-link-rejection.md`.

PERF-199 maps PERF-198's three warm Final Destination 25.267-26.498 ms
producer rows exactly to 26.349-28.361 ms vblank stalls with only 6.019-6.648
ms thread CPU. A separate exact 5,890-frame phase join reproduces one 59.994
ms wall stall with 10.339 ms CPU; guest work, Metal, audio, EFB, and fallback
are nominal. The remaining class is host execution/wake loss. See
`docs/artifacts/2026-08-29/g5-warm-final-destination-wall-attribution.md`.

PERF-198 compares the same 5,890 Final Destination combat frames twice in one
process. Warm combat averages 59.959490 FPS with zero CPU rows over 16.7 ms,
but wall p95 is 17.268541 ms and three rows exceed 20 ms (26.497500 ms worst).
G5 remains open. See
`docs/artifacts/2026-08-29/g5-same-process-final-destination-warmup.md`.

PERF-197 repairs lightweight-only emulated-frame identity. Its 2,496-row smoke
is nonzero, unique, and monotonic; the fix adds no default-path atomic store.
This is measurement integrity, not a speed result. See
`docs/artifacts/2026-08-29/g5-lightweight-frame-identity-activation.md`.

PERF-196 joins 6,650 exact warm Fountain rows to dispatch sampling. Five CPU
overruns contain 175 samples versus 146.46 expected; `0x80360000..8036FFFF`
explains most excess, but no PC dominates and all selected PCs belong to the
already-rejected HSD/GX family. See
`docs/artifacts/2026-08-29/g5-warm-dispatch-region-rejection.md`.

PERF-195 joins all 7,431 warm Fountain rows to phase evidence. All eight CPU
overruns are static-core compute, with 16.852 ms median CPU-thread time versus
11.591 ms in within-budget rows; Metal, audio, EFB, and fallback do not rise.
See `docs/artifacts/2026-08-29/g5-warm-static-core-attribution.md`.

PERF-194 repeats Fountain twice in one process. Cold combat has 105 CPU
overruns; warm combat has eight, proving most cold cost is one-time warm-up.
Warm mean is 59.984858 FPS but worst is 29.475375 ms, so G5 still fails. See
`docs/artifacts/2026-08-29/g5-same-process-fountain-warmup.md`.

PERF-193 introduces the low-overhead wall/thread recorder. Corrected cold
Fountain averages 59.942726 FPS with 39.496833 ms worst; all 104 CPU overruns
occur in the first ten seconds, while later wall holds remain. See
`docs/artifacts/2026-08-29/g5-lightweight-producer-recorder.md`.

PERF-192 retains `scripts/classify-g5-intervals.py` plus nine data-free
regressions. Exact PERF-187/188/189 replay reproduces 2/1/1 GPU-ready fixed-
rate holds, zero ambiguous/undisplayed records, and independent
2,583/1,908/2,393 producer misses. Only 2/0/1 misses exceed 16.7 ms of thread
CPU. Repository checks pass, the tool never claims G5, and no runtime ran. See
`docs/artifacts/2026-08-29/g5-strict-evidence-classifier.md`.

PERF-191 screens public macOS fixed-priority scheduling without building the
game. The policy is distinct, but the required fixed/timeshare/fixed reversal
rejects it: fixed arms miss 5/300 and 3/300 periodic budgets at 29.628/20.546
ms worst versus timeshare's 2/300 at 17.669 ms. QoS clearing and XNU's fixed-
execution failsafe add product risks without a repeatable tail win. See
`docs/artifacts/2026-08-29/g5-fixed-priority-preflight-rejection.md`.

PERF-190 rejects host frame generation before Dolphin integration. MetalFX
color-only interpolation ghosts. VideoToolbox's macOS 26 low-latency optical
flow supports 640x528 NV12 and measures 2.380 ms mean / 2.849 ms worst after
startup, but extreme synthetic motion and retained Melee combat stress pairs
smear or duplicate fighters and effects. Correct chronological 59.94-to-60
conversion also adds about one frame of presentation/input latency, leaves the
independent producer tail untouched, and cannot force compositor selection.
Product remains unchanged; G5 stays open. See
`docs/artifacts/2026-08-29/g5-frame-interpolation-rejection.md`.

PERF-189 retests exact `EmulationSpeed = 1.001` against direct actual
presentation after PERF-187 separated the tails. The corrected 1x/fullscreen
Fountain candidate retains a GPU-ready 33.333666 ms hold after 30.413 seconds,
despite a nominal 16.909166 ms producer phase and GPU completion 31.017 ms
early. Rate alignment is rejected again and reversed byte-for-byte. See
`docs/artifacts/2026-08-29/g5-rate-alignment-actual-presentation-rejection.md`.

PERF-188 repeats the corrected same-run join on verified 1x/fullscreen Final
Destination. The 73.449-second combat boundary has one GPU-ready 33.333667 ms
actual hold with a nominal producer phase, while all fourteen producer rows
above 20 ms are displayed at nominal intervals. Actual/producer worst are
33.333667/34.064583 ms. Both required stages now prove the same independent
tails; G5 remains open. See
`docs/artifacts/2026-08-29/g5-final-destination-combined-join.md`.

PERF-187 invalidates PERF-186's hidden 3x/windowed profile, then repeats the
same join at verified 640x528/fullscreen. The 94.650-second Fountain boundary
has two GPU-ready 33.333 ms actual holds with nominal producer phases, while
all fourteen producer rows above 20 ms map to nominal actual intervals. This
proves the fixed-display and producer tails are independent in the same run.
Actual and producer worst are 33.333500/35.904291 ms, so G5 remains open. See
`docs/artifacts/2026-08-29/g5-corrected-combined-producer-presentation-join.md`.

PERF-172 proves current Game Mode activation without collecting performance.
A signed LaunchServices wrapper retained current runner `e1f3c1d8...` as its
child with known PGO module `bd089303...`. macOS 26.5.2 Game Policy recorded
identified-game/frontmost/fullscreen/console grants, an active fullscreen
gaming session, `Game mode enabled`, DPS, and `Game mode status is now on`.
The brief probe used no combat state, input, screenshot, or frame-time logger
because current external host load is unsuitable for G5 evidence. Require the
same on-state before the next valid Fountain/Final Destination run. See
`docs/artifacts/2026-08-29/g5-current-gamemode-activation-probe.md`.

PERF-171 refreshes the ignored reusable PGO bundle before another live test.
Its known `bd089303...` module was intact, but stale bundle metadata omitted
the games category and `LSSupportsGameMode`, failing the current package-layout
gate. The supported pointer-safe profile workflow repackaged it with current
runner `e1f3c1d8...`, current canonical metadata, and the unchanged known PGO
module; layout, arm64/macOS-14 identity, deep signing, and active-pointer
restoration pass. This restores test-package readiness only and supplies no
new frame-time result. See
`docs/artifacts/2026-08-29/g5-pgo-package-gamemode-refresh.md`.

PERF-085 implements the exact `0x803408A0..0x803408D0` matrix-copy preflight
selected by PERF-084. It passes 20,000 full-state/24-MiB-RAM cases and improves
77.795167 to 23.738208 ns/call, but exact copy coverage is only 0.059158%/0%
in two Fountain profiles. Combining it with the adjacent proven concat kernel
at zero wrapper cost projects only about 2.55%/3.53%. Retain
`scripts/g5_psmtxcopy_preflight.c`; reject the two-address chunk wrapper before
a module build. See
`docs/artifacts/2026-08-28/g5-matrix-copy-family-preflight.md`.

PERF-084 extends the guest-cost mapper with complete function-span and guest-
call classification, then rejects leaf-only state caching. Two independent
line-symbol Fountain profiles bound unclosed no-call work at 14.293349% and
17.302565% of mapped generated samples. Clearing 5% would require a
34.981%/28.897% local gain before synchronization overhead, versus the
9.70-10.92% real complete-function gain in PERF-081. State retention therefore
must cross selected guest calls; next preflight the exact
`0x80377B6C..0x80377CE4` parent and its mutually exclusive `0x803408A0`
callee boundary. See
`docs/artifacts/2026-08-28/g5-function-family-coverage.md`.

PERF-083 refreshes the canonical signed product and the structural
static-recompilation decision. The exact 440-emulated-frame Fountain interval
measures 16.814891 ms total mean / 18.761260 ms p95 and 15.735743 ms CPU-thread
mean while executing 51,369,928 native dispatches. Research and the retained
PERF-079/081 mechanisms select profile-guided generated-C extended basic
blocks with live guest state as the next bounded route. Helper-effect
classification belongs inside that experiment; RAM specialization and
chunk-scoped replacements remain secondary and require new exact attribution.
See `docs/artifacts/2026-08-28/g5-static-recomp-structural-followup.md`.

PERF-080 adds deterministic line-sample to guest-PC cost attribution. The
largest two clusters reproduce already-closed `WriteMTXPS4x3` and
`PSMTXConcat`; the largest unclosed region is only 52/1,531 chassis samples /
3.40%. PERF-081 then compiles that complete function in canonical and
single-entry forms. Entry narrowing alone is neutral, while explicit live
GPR/FPR/PS1 caching with one exact FP gate passes 4,096 cases and improves the
function 9.70-10.92%. Its measured coverage projects only 0.33-0.37% overall,
so no game build follows. See
`docs/artifacts/2026-08-28/g5-guest-cost-attribution.md` and
`docs/artifacts/2026-08-28/g5-single-entry-register-cache-preflight.md`.

PERF-082 rejects DolRecomp's broad LLVM backend after a small LLVM 22/Apple
ARM64 port proved semantics but failed the exact hot-slice performance gate.
The 1,024-instruction slice is 6.12 times larger than C and, with identical
resulting CPU/RAM state, repeats 4.84-4.93 times slower. Common-exit and stock
O2/Oz variants are worse. The full private generation was stopped at 130/947
objects before module link. Do not retry this architecture without first
beating the retained C slice on both size and time. No product input changed.
See
`docs/artifacts/2026-08-28/g5-llvm22-arm64-preflight.md`.

PERF-079 tests the generator-level state-retention mechanism requested by
PERF-078. A faithful data-free model of guest `0x8036C91C..0x8036C934` passes
4,096 randomized full-state/RAM comparisons. The single-entry form reduces
arm64 instructions from 159 to 128, loads from 32 to 27, and branches from 36
to 23, repeating a 21.29-21.79% local speedup. It saves only 1.216-1.264 ns per
execution, however: about 0.001 ms/frame at the exact sampled site and under
0.148 ms/frame even if unrealistically applied to every dispatch. The slice is
rejected before a game build. Next select a larger merged region from inclusive
host cost mapped to guest PCs, not edge frequency. See
`docs/artifacts/2026-08-28/g5-merged-state-preflight-rejection.md`.

The runner's window-title counter was observed across boot, title, and
attract-mode scenes. It ranged from single digits during a cold transition to
roughly 58-60 FPS in lighter title/intro frames, with complex four-character
attract battles commonly in the low 30s to low 40s. These are diagnostic
spot-values, not a controlled frame-time trace, and they do not satisfy the
PRD's worst-case <=16.7 ms requirement.

The first controlled diagnostic match (Kirby versus CPU Samus on Venom) ran at
about 12.5-13.0 FPS during combat and returned to about 57.5 FPS on the results
screen. The runner, frontend, and generated module are native arm64 binaries;
`sysctl.proc_translated=0`. Both the runtime and module are Release builds, the
generated C chunks use optimization flags, Metal is selected, and internal
resolution is 1x. A one-second process sample found the CPU-GPU/static-recomp
thread saturated in generated `gGALE01_recomp.dylib` functions. Metal draw/EFB
and Cubeb mixing paths were present but secondary.

The first retained optimization fixes a macOS build-system defect: forced Ninja
response files caused CMake's Apple IPO probe to fail, despite the module cache
identity claiming ThinLTO. With platform-default response-file handling, the
official O2 build now compiles and links with `-flto=thin`. On aligned
boot/attract frames 2001-3500, mean frame time improved from 20.247 ms to
17.703 ms and p95 from 26.069 ms to 21.207 ms. A separate O3 + native-tuning
build was no faster, so that added complexity was rejected. See
`docs/artifacts/2026-08-24/g5-thinlto-investigation.md`.

The first required-stage baseline is now recorded. A clean Yoshi-versus-CPU-
Zelda Fountain match measured 19.552 ms mean, 19.326 ms median, 22.862 ms p95,
28.010 ms p99, and 111.083 ms worst over 5,176 active-combat frames. Only 3.73%
of frames met 16.7 ms. A clean process sample placed about 88% of the sampled
CPU thread in generated `chassis_dispatch`, classifying the scene as CPU-bound.

An isolated C-backend PGO experiment confirmed the same hot path. Its first
comparison was measurement-confounded and is superseded. In the corrected
buffered 90-second Yoshi-versus-CPU-Ice-Climbers Fountain pair, PGO lowered
mean 8.3%, median 6.8%, p95 20.4%, p99 22.6%, and worst 17.6%. Frames at or
under 16.7 ms rose from 13.38% to 61.03%. A macOS 14 rebuild reproduced the
candidate in a 30-second confirmation. The portable PGO module is retained
locally as the best-known build and code-generation oracle, but the local
ROM-trained profile cannot be committed or serve as the final reproducible
shipping change. See `docs/artifacts/2026-08-24/g5-fountain-pgo-investigation.md`.

A smaller GameCube-only RAM specialization was also rejected. On an equal
105-second Yoshi-versus-CPU-Ice-Climbers Fountain pair it improved mean 3.5%,
median 4.2%, p95 3.0%, and p99 4.4%, but missed the 5% retention threshold and
regressed the worst frame from 1320.456 ms to 1385.798 ms. Recurring isolated
approximately 1.3-second hitches appeared across clean, PGO, and specialized
runs. See
`docs/artifacts/2026-08-24/g5-noexram-investigation.md`.

That hitch conclusion was measurement-confounded. Dolphin's frame-time logger
forced a file flush on every frame, and the exploratory logs also included
screen captures. The retained logger correction buffers ordinary lines. A
visually bounded, capture-free 90-second Yoshi-versus-CPU-Ice-Climbers
Fountain control then measured 18.187 ms mean, 17.903 ms median, 21.168 ms p95,
21.999 ms p99, and 55.135 ms worst; it did not reproduce the approximately
1.3-second hitch. G5 still fails on sustained frame time. See
`docs/artifacts/2026-08-24/g5-render-logging-control.md`.

The first static reproduction attempt forced the hottest sampled polling helper,
`loop_80349494`, to inline into its generated caller. The symbol disappeared
from the macOS 14 arm64 candidate as intended, but an exact capture-free
Fountain replay regressed to 18.763 ms mean, 18.293 ms median, 22.040 ms p95,
24.031 ms p99, and 1296.873 ms worst. Only 23.56% of frames met 16.7 ms. The
single-helper change was rejected and the portable PGO module restored. The
steady-state regression is sufficient to reject it regardless of the isolated
outlier; PGO's gain is not explained by this call-site decision alone.

Final Destination is now measured through a ROM-safe isolated-save setup. The
clean no-mod portable-PGO run measured 16.941 ms mean, 16.678 ms median,
16.946 ms p95, 17.189 ms p99, and 1385.242 ms worst. It is slightly faster in
steady state than Fountain, but still fails p95, p99, and worst. See
`docs/artifacts/2026-08-24/g5-final-destination.md`.

Two broader explanations were then rejected. Marking all 969 generated loop
helpers `noinline` collapsed a four-player attract battle to 4.1 FPS, so PGO's
gain is not reproducible through blanket outlining. Replacing macOS's final
precision-timer scheduler yields with ARM spin hints improved a matched
attract p99 by only 0.63%, left p95 effectively unchanged, and retained
multi-second tail events while spending about 1 ms per frame spinning. See
`docs/artifacts/2026-08-24/g5-outline-and-timer-experiments.md`.

A timestamp-correlated attract diagnostic then separated render delta, CPU
work, requested throttle sleep, and host-clock delta. Frames above 17 ms
averaged 16.757 ms of CPU work and only 2.562 ms of requested sleep; the worst
transition combined 933.964 ms work with 636.776 ms catch-up sleep. The
remaining steady-state tail is primarily generated-module compute rather than
timer overshoot. Combining portable PGO with the earlier GameCube-only
no-EXRAM specialization did not compose: median stayed at 16.683 ms while p95
regressed from 17.848 ms to 19.335 ms and p99 from 18.814 ms to 20.477 ms in a
matched attract window. The candidate was rejected before required-stage
replay. See
`docs/artifacts/2026-08-24/g5-timing-attribution-and-pgo-noexram.md`.

The dominant polling helper's 256-cycle host-return budget was tested directly
with a profile-free 1024-cycle build. It regressed attract median to 16.757 ms,
p95 to 22.926 ms, and p99 to 24.989 ms; vblank regressed in parallel. Reduced
host dispatch frequency does not justify the wider timing-check interval, so
the default budget is retained.

An exact static reproduction of PGO's cold helper symbols was also insufficient.
All 247 PGO-only loop helpers had profile entry counts of zero through nine;
forcing only those helpers `noinline` reproduced all 247 symbols without
touching the hot polling helper. The profile-free candidate nevertheless
regressed attract median/p95/p99 to 16.814/21.459/22.548 ms. PGO's useful
information includes internal branch weights and hot/cold block layout, not
just call boundaries or symbol presence.

A second local PGO corpus added three minutes of no-input attract coverage and
weighted the original Fountain profile 2:1. The portable combined-profile
module slightly improved attract p95 from 17.848 ms to 17.682 ms and improved
vblank tail, but worsened render mean from 17.528 ms to 17.744 ms and p99 from
18.814 ms to 20.654 ms. It was rejected before required-stage replay. Further
PGO training must cover Fountain and Final Destination directly rather than
generic attract scenes.

Direct required-stage training was then tested after repairing the complete
FIFO-to-SI input route and recording controlled 1v1s on both stages. A 2:1
Fountain/Final Destination profile built successfully, but a matched 1,000-frame
attract screen regressed median from 16.684 to 16.778 ms, p95 from 18.077 to
18.383 ms, and worst from 19.088 to 57.091 ms; its <=16.7 ms share fell from
50.80% to 46.60%. The candidate was rejected and the retained Fountain-only
module restored. See
`docs/artifacts/2026-08-25/g5-fountain-fd-pgo-and-input-route.md`.

A new combat-only profile now matches the exact promoted source rather than
reusing a stale corpus. In an exact 440-emulated-frame
candidate/control/candidate Fountain bracket, all three runs execute
1,501,757,755 guest cycles and 51,380,895 dispatches. PGO reduces CPU-thread
mean from 15.941 ms to 11.889/11.606 ms and total p95 from 18.123 ms to
17.608/17.776 ms. The gain is real but insufficient for strict G5. Ordinary
non-precision sleep worsens p95 to 18.227 ms and is rejected. Binary comparison
shows a 723,904-byte larger `__text` plus selective hot helper-call elimination
and branch specialization, not a blanket size/outline effect. The ROM-trained
profile and module stay local as an oracle; the reproducible product remains
unchanged. See
`docs/artifacts/2026-08-27/g5-current-source-combat-pgo-oracle.md`.

ThinLTO's private inline records attribute that candidate to 44,741 successful
selective inlines, led by 41,671 FP-availability sites. Hot call sites use a
3,000 inline threshold while cold sites remain at 325 or 45. Coverage resolved
the hottest isolated short long-load to revision-0 PC `0x8036E8B4`, but the
retained host preflight leaves only about 1 ns/call for that one site, so no
single-site module was built. The validated candidate is retained locally as
`build-macos/MeleePad-PGO.app`; it is not the reproducible product module and
does not satisfy G5.

A subsequent current-PGO pacing screen rules out three more routes. The
existing buffered render logger, gated by 1,001 advancing MemoryWatcher fields
before state load, still measures 17.956 ms p95 / 22.767 ms p99 /
113.255 ms worst without phase counters. VSync and PresentDrawable-only add
large stalls and change nominal boundary work. A public macOS strict dispatch
timer reaches 16.691 ms host p95 without spinning but fails p99/worst at
16.712/18.358 ms, so no Dolphin build was made. Continue with a host-only Metal
scheduled-presentation/actual-`presentedTime` feasibility test; do not retry
these controls or move product pacing until the host gate passes. The
pipelined host harness subsequently passes two 600/600 scheduled runs with
zero drops and <=16.667 ms worst, but the live Dolphin form blocks in Metal and
fails at 18.022 ms p95 / 132.188 ms worst. Fullscreen also remains above the
gate at 17.493 ms p95. The product edit is removed; continue with a fresh
no-phase current-PGO compute sample. See
`docs/artifacts/2026-08-27/g5-pgo-pacing-controls-rejection.md`.

A byte-identical line-symbol build then mapped a fresh current-PGO Fountain
sample. The giant generated function and opcode counts are diffuse; the only
coherent new host cost was JIT-only `CompileExceptionCheck` work beneath
static gather writes. A regression-first candidate used Dolphin's
`FastWrite*`/`FastCheckGatherPipe` sequence while preserving widths, ordering,
and the generic arm's per-byte check cadence. Exact 440-field
candidate/control/candidate windows matched 1,501,757,755 cycles and
51,380,895 dispatches. CPU mean improved by just 0.022-0.107 ms, while p95
regressed from the 17.726 ms control to 17.883/17.843 ms. The candidate misses
the 5% threshold and is removed. Next separate ordinary 17-19 ms frames from
the rare 129-132 ms stall and trigger attribution at the stall rather than
selecting another edit from the diffuse sample. See
`docs/artifacts/2026-08-27/g5-static-gather-fast-check-rejection.md`.

The 129-132 ms rows from that rejection are all emulated frame `48436` with
identical guest work and the only 7.0-8.4 ms Cubeb mix burst. A corrected
90-second rolling System Trace trigger did not reproduce the event; an
earlier marker occurred only during profiler teardown and is rejected. Exact
Cubeb/no-output/Cubeb reversal brackets then matched 1,501,629,399 cycles and
51,369,928 dispatches. Removing audio worsened p95 from 17.599/17.631 ms to
17.668 ms, p99 from 18.158/18.395 ms to 19.277 ms, and worst from about
20.34 ms to 27.01 ms. Reject no-output: audio is required and is not the
ordinary p95 cause. Current official Dolphin has no newer relevant
Metal/Cubeb/timer scheduling mechanism, while the exact-work hidden
`SmoothEarlyPresentation=True` control worsens p95 to 17.700 ms and worst to
31.300 ms. Reject that setting as well and return to generated-code evidence.
See
`docs/artifacts/2026-08-27/g5-tail-trigger-and-audio-rejection.md`.

A semantics-preserving per-generated-chunk FP-availability cache then passed
focused direct-entry/`mtmsr` tests and the canonical 1,401-PC lockstep screen.
The retained Fountain profile bounded helper-call removal at at least 81.0%,
but linked `__text` grew 16.45%. Exact 385-frame candidate/control/candidate
windows matched 1,330,434,029 cycles and 45,572,090 dispatches; candidate
CPU-thread mean regressed from 16.114 ms to 23.750/23.650 ms, while total p95
regressed from 18.113 ms to 26.925/26.622 ms. PERF-067 is rejected and all
candidate source is removed. Do not retry per-chunk flags or another branch
at every FP instruction. See
`docs/artifacts/2026-08-27/g5-fp-availability-cache-rejection.md`.

A distinct CFG-local FP-gate candidate then moved 94,146 of 129,826 exact FP
checks out of sequential bodies while keeping exact-CIA direct-entry gates and
restarting checks at every control-flow leader and after `mtmsr`. Its own
Fountain profile matched the expected 6,556-function/2,727,666-block source
shape, Apple Clang accepted it cleanly, and linked PGO `__text` grew only
1.506%. Exact 440-frame candidate/control/candidate runs matched
1,501,629,399 cycles, 51,369,928 dispatches, 905,572 bursts, and 882 hook
fallbacks. CPU-thread mean improved by 0.236-0.490 ms, but candidate p95
worsened to 17.775/17.980 ms from the 17.677 ms control and the <=16.7 ms
share stayed 52.5%. PERF-068 is rejected and removed. The next diagnostic is
read-only attribution of the serialization edge present in live Dolphin but
absent from the already-passing three-drawable host Metal queue, not another
FP, timer, or presentation-setting edit. See
`docs/artifacts/2026-08-27/g5-fp-cfg-gate-rejection.md`.

The shared-state comparison gap is now closed. Patch 0014 records Dolphin's
savestated emulated VI/Movie frame beside each presentation row. Two equal
440-field Fountain control windows matched exactly at 3,567,157,803 guest
cycles, 59,374,686 native dispatches, and 905,158 bursts. A causal
A/B/reverse-A replay of the 64-bit gather candidate found warm candidate means
of 22.391-23.311 ms versus reverse-control means of 21.459-22.360 ms; the
ranges overlap and the fastest control won. The gather arm is removed. These
21.5-23.3 ms means and 24.1-26.3 ms warm p95 values remain a clear G5 failure.
See
`docs/artifacts/2026-08-27/g5-emulated-frame-shared-state-verdict.md`.

Actual Metal presentation attribution now supersedes CPU-side pacing as the
immediate G5 edge. With ordinary layer display sync, two no-phase controls put
only 53.3-53.6% of actual `MTLDrawable.presentedTime` intervals at or below
16.7 ms. Enabling only `CAMetalLayer.displaySyncEnabled` produced two
780-interval 100% brackets with 16.666709 ms worst. An exact 440-frame run
preserved 1,501,629,399 cycles, 51,369,928 dispatches, 905,572 bursts, and zero
fallbacks while measuring 16.666667 ms worst. The M1/Metal path therefore has
the required throughput.

Full-match worst still fails. A five-timestamp 6,674-interval run measured
16.666667/16.666709/99.999791 ms p95/p99/worst and 99.925% at <=16.7 ms. Both
misses began 103-131 ms before Metal; `nextDrawable` took 0.048/0.052 ms and
backbuffer preparation stayed below 0.106 ms. Combined CPU-GPU QoS still
missed at 100 ms, dual-core mode worsened worst to 133.332 ms, foreground
activation missed at 83.333 ms, and unbinding the per-frame MemoryWatcher
socket still missed at 83.332 ms. Reject those variants. Strip diagnostics and
screen only layer display sync on the reproducible canonical module next;
retain it only after canonical A/B/reverse-A plus visual/audio checks. That
screen now passes: display-sync-off canonical controls measured
18.147/18.561 ms p95 and only 55.141%/57.564% compliance, while the synchronized
candidate measured 16.666667 ms p95 / 16.666750 ms worst with 779/779
intervals compliant. The stripped product policy is retained and the signed
canonical product smoke passes. Its full match naturally reached results with
16.666625/16.666667 ms p95/p99, but ten missed refreshes left 66.666334 ms
worst. Join those actual gaps to canonical phase counters next; G5 stays open.
See
`docs/artifacts/2026-08-27/g5-metal-presentation-attribution.md`.

That canonical join is complete. After the standard two-second warm-up, 6,670
actual intervals measured 16.666667/33.332875/133.332917 ms p95/p99/worst and
98.306% compliance. Presentation interval to phase-total correlation peaks at
0.674781 for phase row `frame - 1`. Misses average 19.623207 ms CPU-thread
time versus 16.079824 ms in compliant rows and carry roughly 5% more guest
cycles and native dispatches. The worst row instead measures 131.944005 ms CPU
wall and 31.829401 ms CPU thread, exposing about 100 ms off-core. A default-off
Mach time-constraint policy was screened only on the faster PGO oracle. The
call succeeded, but a 773-interval bracket regressed from the prior 100%
control to 99.871% and introduced a 116.664750 ms stall. Reject and remove the
scheduler candidate; no full match is justified. Source and the incremental
runner are restored to the product display-sync policy with diagnostic markers
absent. See
`docs/artifacts/2026-08-27/g5-phase-join-and-time-constraint-rejection.md`.

The measured PGO compute path now has a supported private-profile package
bridge. `prepare-game.sh` accepts validated private LLVM profile data, while
`package-local-pgo-app.sh` preserves the canonical module pointer, requires a
hash-only cache manifest, builds/packages/signs the local app, and restores the
pointer on success or failure. A full current-source build reproduced the
known signed PGO module `bd089303...af26f5a`; a repeat logged a cache hit in
24 seconds; and a forced packaging failure still restored the canonical
pointer. The manifest contains profile SHA-256 `3f9d2aa4...f572ac12` and no
private path. PERF-071 closes profile consumption only: local profile training
and G5 remain open. See
`docs/artifacts/2026-08-27/g5-local-pgo-package-workflow.md`.

The private profile can now also be reproduced end to end from user-owned
inputs. PERF-072 adds a distinct C/Clang `--pgo-generate` cache identity plus
scripts to package an instrumented app, run a combat-gated isolated training
session, merge its raw profiles, and feed the result through PERF-071 while
restoring the canonical pointer on every exit. A real Fountain-only profile
has the same 6,556-function/2,727,666-block shape as the earlier oracle and
differs by only 873 aggregate counts. That difference nevertheless changes
127,816 `__text` bytes inside `func_80345940`, so the local product is not
promoted as byte-equivalent. Its clean 440-frame Fountain window exactly
matches 1,501,757,755 cycles and 51,380,895 dispatches and measures 16.664 ms
mean / 11.621 ms CPU-thread mean, reproducing the expected PGO compute class.
It still fails G5 at 18.065 ms p95 / 19.130 ms p99 / 22.509 ms worst. Retain
the workflow, not the binary as canonical. See
`docs/artifacts/2026-08-28/g5-local-pgo-training-workflow.md`.

IR-level PGO is technically functional but rejected for the product. A fresh
`-fprofile-generate` ThinLTO training module produced a real IR profile with
866 post-optimization functions, 3,947,902 blocks, and 52,990,495,633 counts.
The profile-use build emitted no mismatch warnings, but grew `__text` from
81,959,380 to 84,388,556 bytes. Its exact 440-frame Fountain interval matched
the frontend-PGO guest work while worsening CPU-thread mean from 11.620875 to
12.084786 ms. Total p95 was effectively flat at 18.047575 ms and worst rose to
69.163166 ms at steady emulated frame 48,394. PERF-073 restores the published
frontend training mode and rejects whole-module IR PGO. See
`docs/artifacts/2026-08-28/g5-ir-pgo-rejection.md`.

A profile-derived Mach-O order file is also technically functional but
rejected. Apple `ld` placed the requested dispatcher, helper, and generated
symbols contiguously while retaining the frontend-PGO module's 81,959,380-byte
`__text`. Exact emulated frames `48123..48562` matched PERF-072 at
1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, and 882 hook
fallbacks. Ordered CPU-thread mean improved from 11.620875 to 11.537926 ms,
only 0.714%, while total mean regressed from 16.663618 to 16.852325 ms and
worst rose from 22.509416 to 133.106958 ms. PERF-074 restores all temporary
linker/cache-identity inputs and rejects global code placement. See
`docs/artifacts/2026-08-28/g5-order-file-rejection.md`.

Profiled cross-chunk direct calls have now been measured rather than inferred.
PERF-075 sampled 12,539 predecessor/destination edges over the exact Fountain
interval and selected ten linked calls in one hot guest sequence. Focused
generated execution tests prove correct normal return and the existing
256-cycle budget exit, and the isolated PGO-use module contains direct arm64
`bl _func_...` calls. Exact-window native dispatches fell by 4,712,648 / 9.17%,
but CPU-thread mean fell only 0.135849 ms / 1.17%, from 11.620875 to
11.485026 ms. Total mean was flat at 16.666753 ms, compliance slipped to
55.000%, and worst remained 22.057 ms. The candidate also bypasses
`FastDispatchableAt` for nested target chunks, so it does not preserve forced
fallback or post-invalidation SMC verification. PERF-075 rejects and removes
the address-specific transform. The next screen must add a cheap target-valid
guard, fail first on an invalidated callee, and only then test broader static
call chaining. See
`docs/artifacts/2026-08-28/g5-hot-direct-call-rejection.md`.

PERF-076 adds the missing safety contract and rejects its first broad
implementation. A target callback delegates to `FastDispatchableAt`; a second
callback rechecks a local continuation after the callee, preserving forced
fallback and post-invalidation SMC behavior. Five focused paths and 67,012
full-game sites compile and pass; arm64 contains real direct calls. The module
loader correctly caught a missing public `CPUState` mirror before boot. With
both disposable mirrors aligned, a PGO positive screen cut dispatches 69.1%
but worsened CPU mean; because its old profile mismatched, a second clean
profile-free module established the verdict. Against the closest exact-work
canonical no-profile control, CPU-thread mean improves only 0.260529 ms /
1.66% and CPU p95 0.64%, while `__text` grows 12.79%, compliance falls, and
worst reaches 128.024 ms. Two out-of-line validity callbacks per linked call
consume most of the dispatcher saving. The callback candidate is removed. See
`docs/artifacts/2026-08-28/g5-guarded-direct-call-rejection.md`.

A primary-source optimization survey now ranks the remaining static-recompiler
options. The next useful representation is an inline runtime-owned eligibility
table matching mature direct-block-chaining designs, followed—only if per-edge
guards remain too costly—by one profile-derived superblock with guards at trace
boundaries. Keeping guest state live inside that region and optimizing specific
helpers require Instruments evidence first. BOLT is excluded because it
accepts ELF rather than this Mach-O product; generic PGO/LTO repetition is also
excluded by the existing measurements. See
`docs/artifacts/2026-08-28/g5-static-recomp-optimization-research.md`.

PERF-077 rejects the broad inline-table representation before a game build. A
retained arm64 host preflight reproduces the preserved callback's target guard,
direct callee, continuation-PC check, second guard, host-call query, cold REL
branch, and address-to-chunk lookup. Two 15-repetition runs, each using 32
million edges per representation per repetition, measure only 5.875–5.967 ns
saved per complete edge. PERF-076 bounds dynamic direct
edges at 40,310–80,619/frame, projecting only 0.237–0.481 ms additional gain.
Even adding the largest projection to PERF-076 reaches only 4.72%, below the
5% build threshold. Do not change the product ABI or regenerate the broad
module. Next preflight one profile-derived superblock with one boundary guard.
See
`docs/artifacts/2026-08-28/g5-inline-validity-preflight-rejection.md`.

PERF-078 validates boundary-trace semantics but rejects dispatcher-only trace
chaining on coverage. A deterministic analyzer identifies the dominant
Fountain chains, while a focused signed-budget regression passes invalidated
entry, canonical fallback, completion, successor miss, exception, and exact
`-256` exit paths. The seven-node candidate covers only 5.16% of dispatches
and projects about 0.076 ms/frame. Even all 278 dominant edges reach only a
zero-overhead 5.37% CPU projection; 204 edges are needed merely to cross 5%,
before guards, misses, footprint, and low-sample selection error. Do not build
a dispatcher-only trace forest. Next preflight a genuinely merged generated
region and require evidence that keeping guest state live removes material
arm64 loads/stores beyond dispatch savings. See
`docs/artifacts/2026-08-28/g5-dispatch-trace-coverage-rejection.md`.

PERF-149/150 close the remaining GPU-readiness question. A short current-PGO
Fountain screen passes all 2,001 actual display intervals with a 16.666749 ms
worst, but the sustained 95.884-second combat window measures 16.692862 ms
mean / 16.666833 ms p95 / 16.666834 ms p99 / 33.333542 ms worst. Nine of
5,744 intervals miss one refresh. Every associated present record was
registered 12.397-32.797 ms before the skipped refresh, and its Metal GPU work
ended 10.408-30.918 ms before that deadline. GPU work itself is 1.565649 ms
mean and 2.522875 ms worst. The M1 GPU and Fountain render path are therefore
not the cause of this current strict tail; macOS deferred already-ready frames,
consistent with the retained approximately 59.94 Hz source to fixed 60.0 Hz
panel conversion proof. The private observer was removed and the canonical
runner rebuilt without its marker. See
`docs/artifacts/2026-08-29/g5-gpu-readiness-and-display-deferral.md`.

PERF-151/152 separate the fixed-panel boundary from the genuine producer tail.
GALE01's VI cadence derives exactly to `60000/1001`, or 16.683333 ms, while
every current M1 built-in mode is 60.000000 Hz. PERF-127's observer-free stable
20-100 second window queued 4,794 surfaces and displayed 4,788; six holds are
only one above the five-hold conversion expectation. Proven ready-frame
conversion holds therefore cannot alone classify D2 compute misses. A
disposable one-wall/one-thread-clock-per-present split then retained 1,091
complete combat intervals before a disk-full shutdown truncation. Thread CPU
measured 11.757568 ms mean / 12.758312 ms p95 / 13.852158 ms p99 /
14.735375 ms worst, with zero rows above 16.7 ms; all three >20 ms wall rows
were off-core. Its wall distribution is diagnostic-only because disk pressure
may aggravate scheduling. The observer is removed. See
`docs/artifacts/2026-08-29/g5-ntsc-display-boundary-and-light-producer-tail.md`.

PERF-153/154 identify and remove a severe harness contaminant. The same
observer-free packaged Fountain run with streamed `gcpipe.py` progress measured
16.708388 ms mean / 16.793208 ms p95 / 33.330875 ms worst and contained five
33 ms plus one 30 ms gap. Redirecting only progress output to `/dev/null`
removed every 30-33 ms gap and restored 16.666653 ms mean / 60.000049 FPS.
Quiet p95 remains 16.796250 ms and strict worst still fails at 22.544875 ms;
the two >20 ms events are delayed/catch-up pairs. Retain quiet input as a
measurement rule, not a product optimization. See
`docs/artifacts/2026-08-29/g5-quiet-input-harness-reversal.md`.

PERF-179 rejects reducing the native Metal layer pool from three drawables to
two. The candidate collapses Fountain's final 2,001 render rows to 38.967624
FPS, 33.393333 ms p95, and 33.554417 ms worst, with 1,080 rows above 30 ms.
The source and canonical runner were restored. See
`docs/artifacts/2026-08-29/g5-two-drawable-layer-rejection.md`.

PERF-180 refreshes Main Menu timing on the exact current PGO/Game Mode package.
A genuine cold MemoryWatcher-gated menu bracket averages 59.937749 FPS with no
row above 20 ms and a 59.743392 FPS worst rolling 60-frame rate. Its p95 is
still 18.793042 ms, with delayed/early compensation, so this rejects the old
sustained 12.5-30 FPS diagnosis without claiming perfect smoothness. See
`docs/artifacts/2026-08-29/g5-current-main-menu-window.md`.

PERF-181 rejects a larger Cubeb buffer. CoreAudio's minimum is 128 frames, so
the 512-to-1,024 request change is effective, but the candidate falls from the
matched control's 59.969577 to 59.910028 FPS, keeps 16.789792 ms p95, and
increases >20 ms render rows from two to three. Vblank retains the same hold
class. The candidate is removed and Cubeb 512 restored. See
`docs/artifacts/2026-08-29/g5-cubeb-buffer-rejection.md`.

PERF-182 independently audits all remaining public product-local G5 levers
against current source and causal evidence. It finds no build candidate:
compute, GPU, presentation, supported scheduler/timer, audio, shader, disc,
title, and known Logitech routes are closed. It preserves the distinction
between mathematically required fixed-panel conversion holds and genuine
producer intervals without weakening D2; the producer class still fails.
Reversible clean-host isolation remains an unresolved optional diagnostic, not
a required next action. PERF-184 parks it so the loop can continue without
changing unrelated processes. See
`docs/artifacts/2026-08-29/g5-independent-boundary-audit.md`.

PERF-183 retains an unchanged Activity-Monitor-on A leg without altering any
external process. Read-only snapshots identify Activity Monitor plus its
natural `sysmond` sampling as the only material current observer load. The
final 2,001 Fountain rows measure 59.790259 FPS, 16.795167 ms p95, and seven
doubled render frames; vblank retains matching stalls. This is not causal.
PERF-184 parks the B/A2 idea as optional and explicitly non-blocking. Activity
Monitor does not need to be paused; continue without touching unrelated
processes.
See `docs/artifacts/2026-08-29/g5-activity-monitor-isolation-a-leg.md`.

PERF-185 takes the first non-blocking park-and-pivot step: the restored macOS
baseline passes all 26 scoped `moderngekko.*` tests, covering runtime and
module loading, CPU/GX, audio, frontend configuration, and netplay protocol.
This is baseline-integrity evidence, not a timing measurement or G5 pass. See
`docs/artifacts/2026-08-29/g5-park-pivot-regression.md`.

Required next work:

1. Keep G5 open. Before another product build, require a falsifiable mechanism
   that can produce a new distinct frame each fixed-panel refresh while
   preserving deterministic guest, audio, and netplay timing. Duplicating a
   stale surface is not a pass.
2. Do not reopen GPU, renderer, drawable acquisition, VSync, display-sync,
   direct/scheduled presentation, timer, QoS, or already-rejected guest-code
   candidates without new contradictory evidence.
3. Continue reducing any observer-free producer interval above 16.7 ms, but do
   not conflate fixed-panel conversion holds with M1 compute saturation.
   Recover disk headroom before the next measurement and choose a new causal
   host-descheduling mechanism rather than repeating the same timing observer.
4. Retain an optimization only after both required stages improve and the G5
   worst-frame requirement is actually met.

## 2026-08-30 — PERF-212 dispatcher frame-split rejection

- Active runner disassembly emits no spill/reload around the indirect module
  dispatch call; its x19-x28 saves occur once at `StaticRecompCore::Run`
  entry. A `preserve_most` ABI therefore has no caller traffic to remove.
- A semantics-preserving disposable split moved the proven-zero-hit host and
  alias branches out of the common dispatcher. ThinLTO removed the x19/x20
  save pair and reduced the common frame sequence while growing module text by
  only 296 bytes.
- Canonical/candidate comparison passed 512 randomized generated-function
  cases plus host hit, host miss, physical alias, and complete miss branches.
- Nine alternating five-million-call repeats measured 49.475708 ns/call
  control versus 49.285442 ns/call split: 0.190267 ns or 0.384566% saved.
  At 116,775 dispatches/frame, projection is only 0.022216 ms/frame.
- Decision: reject custom calling convention and cold-frame split below the
  5% build gate. No candidate reached the app or game.
- Evidence:
  `docs/artifacts/2026-08-30/g5-dispatch-frame-split-rejection.md`.

## 2026-08-30 — PERF-213 generated frame-pointer omission rejection

- One retained hot frontend-PGO chunk compiled with identical strict flags
  and explicit frame-pointer on/off modes.
- Control: 365,656 text bytes / 88,056 instructions. Omit candidate: 363,920
  text bytes / 87,622 instructions.
- The 434-instruction reduction across 446 generated functions is almost
  entirely one removed x29 frame-establishment `add` per function; x29/LR is
  still saved/restored.
- PERF-212's direct same-machine result bounds this at approximately
  0.0044 ms/frame, far below materiality.
- Decision: reject before ThinLTO module/game build; temporary objects deleted.
- Evidence:
  `docs/artifacts/2026-08-30/g5-generated-frame-pointer-omission-rejection.md`.

## 2026-08-30 — PERF-214 remaining mechanism and capability boundary

- Warm Fountain: 6,731 PERF-207 frames, 12.273 ms mean combined-thread CPU,
  one CPU overrun, but six wall intervals above 20 ms. The three largest map
  to prior 16.9-21.8 ms `nextDrawable` waits.
- Warm Final Destination: zero CPU rows above 16.7 ms in 5,890 frames, but
  three wall intervals above 20 ms; later join maps them to vblank/host
  execution loss.
- Actual Fountain presentation: all nine 33.333 ms PERF-150 misses were
  GPU-complete 10.3-30.7 ms before the skipped refresh. GPU work is 1.566 ms
  mean / 2.523 ms worst.
- Current host: only the built-in `1440 x 900 @ 60.00Hz` mode; retained
  Quartz/IOKit audit has no 59.94 or VRR range. The 59.94005994-to-60
  conversion class cannot be falsified on this display without stale
  duplication, interpolation, or guest-speed changes, all invalid/rejected.
- PRD AOT vertex specialization is below threshold on macOS: nine samples in
  the strongest older Fountain profile and only two incidental PERF-207 tail
  stacks while CPU remained inside budget.
- Decision: the next necessary capability is a real 59.94 Hz or suitable-VRR
  macOS display, followed by the unchanged audio-on FD/Fountain gates. This is
  necessary, not sufficient. G5 remains unpassed and G6 blocked.
- Evidence:
  `docs/artifacts/2026-08-30/g5-remaining-mechanism-and-capability-boundary.md`.

## 2026-08-31 — PERF-236 dual-core crash and single-core reversal

- The previously accepted iOS CPU/video split launched at 01:00:14.9399 and
  crashed at 01:02:34.3586: 139.4 seconds. The report records
  `EXC_BREAKPOINT` / `SIGTRAP`, faulting Video thread 13, and top frame
  `OpcodeDecoder::RunFifo<false>` +1444. The preceding runtime warning reported
  malformed FIFO command `0x84000000` with fewer than 16 bytes available.
- Retained configuration: cache-direct exact-PGO module, host PGO, single
  CPU/GPU worker, three shader compiler workers. Runtime identity:
  `cpuVideoSplit=0 shaderCompilerThreads=3`.
- Reversal window: 06:22:30Z..06:45:14Z, 135 ten-second rows over 22:44.
  Final interval 59.9 FPS / 59.9 VPS, DMA 14/15. Underruns 1 -> 71 across cold
  creation, multiple transitions/matches, UI work, and lifecycle; 107 intervals
  were flat and the longest consecutive flat run was 15 intervals.
- The minimum reported presentation FPS was 3.7 while VPS remained 59.9 and
  speed 1.0; keep the presentation hitch separate from emulation/audio
  continuity. Zero FIFO/desync/fatal/crash matches occurred.
- Decision: reject and forbid iOS Dolphin dual-core. Row 7 passes its
  no-sustained-underrun boundary on the single-core product path, not as a
  locked-60 or physical-device claim.
- Evidence:
  `docs/artifacts/2026-08-31/g8-ios-single-core-stability-and-touch-input.md`.
