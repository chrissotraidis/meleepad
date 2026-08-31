# ssbmpad status

Last updated: 2026-08-30

## Current goal

**G8 — Test matrix green: IN PROGRESS UNDER USER-AUTHORIZED G5 DEFERRAL**

CLASSIC-230 passes G8 row 6. Generated GALE01 instructions corrected the live
player table from a stale external address to `0x804510C0`; the new pointer-
chain harness then read fighter percentages that matched the screen. The
retained macOS run cleared Brinstar, cleared the next team battle, allowed the
target bonus stage to resolve, and visibly advanced into the Bowser fight at
59.9-60.0 FPS. The known warped geometry/character presentation remains a
separate open defect and is not hidden by this progression pass. See
`docs/artifacts/2026-08-30/g8-macos-classic-three-stage-progression.md`.

KEYBOARD-229 repairs a macOS playability regression. The default WASD profile
was present in the app, but prior automation left both persistent controller
selectors on `Pipe/0/ssbmpad`, so a normal launch had no keyboard controls.
The wrapper now migrates only that exact internal profile to Quartz in both
files, keeps arbitrary custom profiles unchanged, and adds Space as a jump
key. Focused functional/package regressions and the full repository suite pass;
the rebuilt launcher visibly selects `Quartz/0/Keyboard & Mouse`. Physical-key
in-game confirmation remains pending because Computer Use taps do not appear
in Quartz's held-key state. See
`docs/artifacts/2026-08-30/macos-default-keyboard-controls.md`.

CLEAN-224 passes G8 row 15. A fresh checkout exposed a stale context hunk in
Dolphin patch 0017 after the pinned SunPad iOS guard. The retained patch-only
repair applies the existing forced macOS display-sync behavior inside that
guard. The corrected clean tree then fetched every pin, validated/extracted
the exact private image, regenerated 237 chunks, built and ad-hoc signed the
arm64 macOS app, and passed bootstrap, package, signature, and repository
gates. See `docs/artifacts/2026-08-30/g8-clean-clone-build.md`.

SAVE-223 passes G8 row 8 on macOS and the iPad Simulator. Live Melee name
entry created `CODM` and `CODX`; both were visibly recovered after normal
termination and fresh-process relaunch. SsbmPad's FPS setting was also read
back after relaunch on both platforms. Private game data and saves remain
untracked, both app processes are stopped, and the sole Simulator is shut
down. See
`docs/artifacts/2026-08-30/g8-save-and-settings-persistence.md`.

PERF-222 rejects iOS host-core ThinLTO at the pre-live structural gate. The
isolated candidate was genuine LLVM ThinLTO, but linked
`StaticRecompCore::Run` retained the measured `FastDispatchableAt`, `SyncIn`,
and `SyncOut` calls while growing from 692 to 1,327 instructions. The app grew
94,224 bytes and no target hot boundary disappeared. No Simulator or private
game data was used for this rejected candidate. Row 7 remains fail/attributed;
do not add host-core ThinLTO. See
`docs/artifacts/2026-08-30/g8-ios-host-core-thinlto-rejection.md`.

SHELL-217 passes G7. On the live iPad Simulator, the three-dot menu applied 2x
rendering and experimental 16:9 live, exposed the FPS, controller mapping,
touch settings, game-data, and report actions, resized and reset a control,
and generated a diagnostic share file. A live privacy audit caught a dev-only
absolute game-root path in the first export; the retained repair sanitizes the
breadcrumb, scrubs host path tokens again at export, and adds a regression.
The rebuilt report had zero path/game-image leak matches. All focused shell
tests and the repository gate pass. Defaults were restored and the sole
Simulator was shut down. G8 must now execute the full matrix; every-control,
two-controller, saves, and remaining scene/target rows are still open. See
`docs/artifacts/2026-08-30/g7-shell-parity-and-diagnostics.md`.

IMPORT-219 passes G8 row 13. Live testing exposed and removed three inherited
Sunshine import invariants: the SHA-256, 174-file count, and Sunshine-only
required files. The corrected app strictly validated the pinned GALE01
revision-0 image, retained the exact 1,459,978,240-byte ISO, extracted 1,209
Melee files, activated them atomically, booted visible frames, survived a
normal sandbox relaunch, and passed same-filename reimport from the
Files-visible SsbmPad folder. The temporary Files source was removed; private
active data remains for later tests. See
`docs/artifacts/2026-08-30/g8-ipad-game-data-import.md`.

MOBILE-216 passes G6. The same arm64 IOSSIMULATOR SsbmPad app and locally
generated ahead-of-time GALE01 module booted sequentially on an iPad Pro
13-inch (M5) and iPhone 17 Pro Simulator, both on iOS 26.5. Actual touch input
drove title/menu navigation, fighter selection, and live Classic-mode combat.
The mobile product path has no compiled PowerPC JIT; interpreter fallback and
the portable software vertex loader remain selected. Static screens often
reported 59.9-60.0 FPS, but cold transitions and combat were materially slower,
so this is a Simulator core/gameplay pass rather than stable-60 or real-device
performance evidence. G7 subsequently closed the shell boundary; the broader
control, lifecycle, persistence, and import cases belong to G8. See
`docs/artifacts/2026-08-30/g6-ios-simulator-core-and-gameplay.md`.

DECISION-215 defers the unavailable external 59.94 Hz / VRR display
verification until after the iPadOS/iOS version exists and authorizes G6 to
begin. That sequencing exception enabled MOBILE-216, but it is still not a
measured G5 pass: PRD D2 and the final completion requirement remain
unchanged. See
`docs/artifacts/2026-08-30/g5-external-display-verification-deferral.md`.

PERF-214 reconciles the current G5 evidence and closes the remaining local
mechanism inventory. Warm Fountain's rare CPU overruns are distributed across
already-profiled/rejected static-recompiler families; its largest wall tails
are proven `nextDrawable` waits. Warm Final Destination remains wall/vblank-
bound with CPU inside budget. GPU-complete Fountain frames are independently
deferred by the built-in fixed 60.00 Hz panel converting Melee's exact
59.94005994 Hz source. The current Mac exposes neither a 59.94 mode nor a VRR
range, while compiler, renderer, scheduler, audio, input, and macOS vertex-
loader routes all have direct semantic, reversal, API, or materiality
rejections. Further G5 work requires a real 59.94 Hz/suitable-VRR macOS
display (necessary, not sufficient), or genuinely new causal evidence naming
an uncovered public mechanism. Do not weaken D2 or report G5 as passed;
DECISION-215 now permits G6 to proceed while external-display verification is
deferred. See
`docs/artifacts/2026-08-30/g5-remaining-mechanism-and-capability-boundary.md`.

PERF-213 rejects generated-function frame-pointer omission before a full
module build. A hot PGO chunk compiled with and without x29 frame establishment
differs by only 434 instructions across 446 generated functions—essentially
one instruction per native dispatch. PERF-212's direct same-machine result
bounds that at approximately 0.0044 ms/frame, far below the 5% build gate.
Product unchanged. See
`docs/artifacts/2026-08-30/g5-generated-frame-pointer-omission-rejection.md`.

PERF-212 proves the optimized runner emits no per-dispatch caller spills, so a
custom `preserve_most` ABI has nothing to remove. Splitting zero-hit host/alias
paths does remove the dispatcher's x19/x20 save pair and passes 512 randomized
generated-function cases plus host, alias, and miss branches, but saves only
0.190 ns/call (0.385%), projecting 0.022 ms/frame. Product unchanged. See
`docs/artifacts/2026-08-30/g5-dispatch-frame-split-rejection.md`.

PERF-211 reopens sample PGO only against PERF-206's new native-PC ring, then
closes it before a module build. This Xcode has no `llvm-profgen`; the shipped
module has no DWARF line data or pseudo probes; and the ring contains PC
snapshots rather than branch/context trace. A symbol-only profile would merely
approximate function hotness already measured more exactly by the retained
frontend profile's entries, blocks, and branch weights. Do not synthesize a
weaker profile, rebuild with probes, or install another profiling toolchain.
Product unchanged; G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-native-pc-sample-pgo-screen.md`.

PERF-210 closes a possible fixed-scheduler escape route. Apple's pthread
contract says incompatible legacy scheduling permanently opts a thread out of
requested QoS. A disposable readback proves user-interactive QoS applies,
public fixed policy clears it, and reapplying QoS fails with `EPERM` while the
thread remains fixed; timeshare restoration succeeds. Fixed plus user-
interactive is not a supported untested combination, and fixed alone already
failed PERF-191's reversal. Do not add a policy mode or use private APIs.
Product unchanged; G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-fixed-plus-qos-contract-rejection.md`.

PERF-209 audits PERF-207 against Apple's current drawable guidance. Dolphin
already performs independent presenter work before `nextDrawable`, contains
acquisition/presentation in autorelease scopes, and clears its retained
drawable through the existing scheduled handler; direct presentation already
has a live rejection. A real host `CAMetalLayer` reports opaque RGB
`BGRA8Unorm` and framebuffer-only defaults, and the retained product is
fullscreen, satisfying Apple's direct-to-display prerequisites on Apple
silicon. Acquiring materially later would require the already-rejected
offscreen/reserve architecture. Do not add an opacity, retain, framebuffer,
or latency no-op. Product unchanged; G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-apple-drawable-lifecycle-audit.md`.

PERF-208 screens the installed macOS 26.5 Metal/QuartzCore API surface after
PERF-207's exact drawable-wait attribution. `CAMetalLayer` supports only two or
three drawables and already defaults to the maximum three; the actual host
also reports framebuffer-only textures, asynchronous layer updates, display
sync, and finite timeout behavior. The ordinary Metal queue permits 64
incomplete command buffers, so its limit is not the three-drawable bottleneck.
Metal 4 still requires the same acquired `MTLDrawable` and present APIs;
`waitForDrawable`/`signalDrawable` add ordering but no capacity or source
frame. No command-count, timeout, transaction, or backend-migration candidate
is causal enough to build. Product unchanged; G5 stays open and G6 blocked.
See `docs/artifacts/2026-08-30/g5-current-metal-drawable-api-screen.md`.

PERF-207 resolves PERF-206's unexplained warm wall-wait residency without a
product edit. An optional four-frame external unwind passes its signed target
regression and retains 52,906 error-free second-match samples. Offline joining
finds six wall rows above 20 ms but only one CPU-thread overrun; 31/32 timed-
semaphore tail samples share the exact libdispatch -> QuartzCore ->
`-[CAMetalLayer nextDrawable]` chain. The phase logger records current Metal
subphases beside the next start-to-start interval, and the corrected one-row
join maps the three 31.5-34.7 ms tails to prior 16.9-21.8 ms drawable waits.
This strengthens already-known drawable backpressure and does not reopen
rejected pool-depth, Rush, direct/absolute presentation, or reserve-queue
changes. Retain the external diagnostic only; this observer-bearing run makes
no FPS claim. G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-warm-wall-stack-attribution.md`.

PERF-206 replaces the failed CLI-counter path with a bounded external ARM64
PC ring on a disposable `get-task-allow` runner; the canonical product gains
no entitlement. A 120-second same-process warm Fountain capture retains
78,744 samples with zero errors and joins 73,871 body samples plus 48 samples
to four exact active-combat CPU overruns. `StaticRecompCore::Run` rises 2.99x,
but the remaining signal is distributed across state transfer, GPFIFO,
`ppc_psq_load`, and 8033/8035/8036/8038 generated chunks; no leaf owns more
than four samples. Those mechanisms/families already have semantic and live
rejections, so no repeated product rewrite is justified. Retain the tested
sampler/analyzer only; this observer-bearing result makes no FPS claim. G5
stays open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-warm-native-pc-ring-attribution.md`.

PERF-205 repairs a retained diagnostic before it can contaminate another G5
capture. The triggered thread sampler still treated CSV column 3 as
`total_ms`, but the current phase schema places `host_frame_end_unix_ns` there.
An end-to-end regression proves a true 10.0 ms row falsely triggered as
`1.78807e+18` ms. The sampler now resolves `emulated_frame` and `total_ms` by
header name and passes current, legacy, reordered, below-threshold, and
malformed-schema cases; the full repository gate passes. This restores tool
correctness only: it records external run state/CPU time, not native PCs, and
does not justify a new FPS claim or game run by itself. G5 stays open and G6
blocked. See
`docs/artifacts/2026-08-30/g5-triggered-sampler-schema-repair.md`.

PERF-203 reproduces an exact same-process warm Fountain window but rejects the
command-line CPU Counters route before making a metric claim. Corrected
startup and MemoryWatcher gates prove title readiness, first combat and its
natural completion, then second combat; a fresh frame shows coherent Fountain.
The attached trace crashes `xctrace` inside `SystemCounterAggregator` and is
unexportable, while a five-second data-free attach hangs and grows to 4.4 GiB.
The invalid disposable trace was deleted and all owned processes stopped.
The reusable PGO bundle also predates the lightweight recorder, preventing a
clock join. Retain no product edit and do not retry CLI CPU Counters. See
`docs/artifacts/2026-08-30/g5-warm-cpu-counter-cli-rejection.md`.

PERF-204 closes the remaining compiler-splitting escape route without a game
build. AppleClang rejects late machine splitting for arm64 Mach-O. The
format-independent IR hot/cold splitter is already active under the retained
frontend profile: normal and explicitly enabled builds of the two selected
warm-overrun chunks are byte-identical and already contain 311/315 cold
functions. G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-hot-cold-splitting-rejection.md`.

PERF-202 tests whether the rare warm Fountain compute overruns justify a new
PGO collection/build. The active profile was reset only after verified
Fountain combat began and dumped at natural combat completion; it already
covers the proposed scene. Coverage reconstruction gives the five PERF-196
PCs 2,523,933-17,523,395 hits. An independent local-training repeat has the
same function hashes/counter shapes and assigns every selected PC the exact
same count, despite an aggregate-profile difference of 873. Warm-profile
absence or unstable weighting is rejected before a build. Retain the current
module; G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-warm-profile-refresh-rejection.md`.

PERF-201 closes two proposed host-wake escape routes without launching the
game. Apple's temporary pthread QoS override represents a real pending-work
dependency and can only raise a target to the maximum of its requested and
override classes. The rejected user-interactive/priority-zero run already
exercised that maximum; a permanent fake dependency is neither valid nor a new
scheduler tier. Fresh upstream Dolphin and Slippi `CoreTiming.cpp`/Metal
submission files are byte-identical, and their only relevant `Present.cpp`
difference is removed framebuffer metadata—not pacing. This checkout already
uses the same throttle, precision sleep, intended-presentation sleep, and
Metal submission flow. There is no reference patch to transfer. Retain no
product edit; G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-qos-override-and-reference-pacing-audit.md`.

PERF-200 tests the last unpreflighted current Apple display-cadence primitive
before any game integration. A retained, sanitized host-only
`CAMetalDisplayLink` harness drives this M1's panel perfectly at an exact 60 Hz
source: 599/599 actual intervals meet 16.7 ms with 16.667083 ms worst and zero
source repeats. Requesting 59.94005994 Hz for 2,400 intervals is still
quantized to 60 Hz: all 2,399 generated-color presentations meet 16.7 ms, but
the measured target timeline requires two callbacks with no new 59.94 Hz
source frame. Integration would have to duplicate stale content, interpolate,
or change deterministic guest/audio speed; those violate the distinct-frame
boundary or already have direct rejections. Do not integrate the display link.
G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-metal-display-link-rejection.md`.

PERF-199 joins PERF-198's three observer-free warm Final Destination wall
outliers exactly into vblank: 25.267167/26.342000/26.497500 ms producer rows
map to 26.349416/26.652583/28.360792 ms vblank stalls, while thread CPU is only
6.019-6.648 ms. A separate visually verified same-process phase run joins all
5,890 warm combat frames exactly and reproduces one 59.993541 ms wall stall
with 10.339240 ms thread CPU. Guest work is ordinary; `nextDrawable` is
0.032333 ms, presentation 0.266333 ms, audio 2.076958 ms, and EFB/fallback are
zero. The missing interval is host execution/wake loss in the combined CPU/
vblank path, not static recompiler, Metal cost, or M1 throughput. Existing
scheduler, timer, Rush, dual-core, and drawable candidates already have direct
reversals, so no speculative product edit is retained. G5 stays open and G6
blocked. See
`docs/artifacts/2026-08-29/g5-warm-final-destination-wall-attribution.md`.

PERF-197 fixes a measurement defect: lightweight-only recording previously
left every emulated-frame identity at zero because the shared index advanced
only for the heavier phase observer. Canonical patch 0025 activates the
existing store for either recorder while preserving the disabled path; its
2,496-row smoke is nonzero, unique, and monotonic. The fix and regression are
published in `10dcb11`. PERF-198 then compares 5,890 exact Final Destination
combat frames twice in one process. Warm combat averages 59.959490 FPS and has
zero CPU frames over 16.7 ms, but wall p95 is 17.268541 ms and three wall
intervals exceed 20 ms (26.497500 ms worst). This is playable-looking but not
stable 60 or a G5 pass. Next join those exact warm wall rows to render/vblank/
presentation timing; do not repeat a static-recompiler rewrite. G6 remains
blocked. See `docs/artifacts/2026-08-29/g5-lightweight-frame-identity-activation.md`
and `docs/artifacts/2026-08-29/g5-same-process-final-destination-warmup.md`.

PERF-196 joins a visually verified same-process warm Fountain body to the
retained one-in-4,096 dispatch sampler. Five CPU overruns contain 175 samples
versus 146.46 expected; `0x80360000..0x8036FFFF` explains 64.4% of the sample
excess, but no individual PC exceeds 2.557 excess samples. The exact PCs are
the already-tested PERF-075 HSD/GX family: direct-call, guarded, trace,
merged-state, register-cache, LLVM, and structural variants all previously
failed materiality or semantics. No repeated product rewrite is justified.
Observer-free images correct a near-misclassification of Fountain background
art as mesh warp; fighters are coherent, while the known lower-floor
reflection smear remains open. G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-warm-dispatch-region-rejection.md`.

PERF-195 adds exact emulated-frame identity to the default-dormant lightweight
recorder and uses it to join every one of 7,431 warm Fountain combat rows to
the retained phase observer. All eight combined-thread CPU overruns are
static-core compute: their phase CPU-thread median is 16.852 ms versus 11.591
ms in within-budget rows, with elevated native dispatch and guest-cycle counts.
Metal/presentation, audio, EFB traffic, and fallback handling are not elevated.
This is observer-bearing causal evidence, not an acceptance FPS claim. G5
remains open and G6 blocked; next use the bounded dispatch/frame sampler to
name the enriched guest-PC regions. See
`docs/artifacts/2026-08-29/g5-warm-static-core-attribution.md`.

PERF-192 adds a strict test-driven producer/presentation classifier and wires
its nine regressions into repository checks. It reproduces all retained
PERF-187/188/189 display events as 2/1/1 GPU-ready fixed-rate holds with zero
ambiguous or undisplayed rows, while independently retaining
2,583/1,908/2,393 producer misses. Thread CPU exceeds 16.7 ms in only 2/0/1 of
those rows. The tool explicitly never claims G5 and does not promote observer-
bearing diagnostic traces to acceptance evidence. No game or Simulator ran.
Next is a default-dormant observer-light wall/thread producer recorder on the
canonical package. See
`docs/artifacts/2026-08-29/g5-strict-evidence-classifier.md`.

PERF-191 closes the remaining public fixed-priority scheduler screen before a
game build. `THREAD_EXTENDED_POLICY{timeshare=false}` is genuinely distinct
from precedence/QoS/time-constraint policies, but its data-free A/B/A result
does not reverse. In fixed/timeshare/fixed order, fixed misses 5/300 and 3/300
periodic budgets with 29.628/20.546 ms worst, while timeshare misses 2/300 with
17.669 ms worst. XNU also clears requested pthread QoS while applying a legacy
policy and may demote sustained fixed execution. Product remains unchanged;
no game or Simulator remains. G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-fixed-priority-preflight-rejection.md`.

PERF-190 rejects Apple frame generation as the remaining distinct-frame
display route. Color-only MetalFX produces a two-position ghost. VideoToolbox
low-latency optical flow is supported at 640x528 on this M1 and costs only
2.380 ms mean / 2.849 ms worst after session startup, but a 128-pixel synthetic
jump ghosts and three retained Melee combat stress pairs visibly smear fighter
limbs, silhouettes, and effects. Chronological conversion also adds about one
16.683 ms source frame of input/display latency, requires macOS/iOS 26, leaves
the independent producer tail untouched, and cannot guarantee compositor
selection. No product source/config/runtime changed; no game or Simulator
remains. G5 stays open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-frame-interpolation-rejection.md`.

PERF-189 directly rejects exact `1001/1000` host-rate alignment against actual
presentation. Under corrected 1x/fullscreen Fountain, `EmulationSpeed = 1.001`
still produces a GPU-ready 33.333666 ms actual hold after 30.413 seconds; its
producer phase is 16.909166 ms and GPU work finishes 31.017 ms before the
skipped deadline. Candidate actual mean/p95/worst are
16.669889/16.666875/33.333666 ms. The isolated setting is removed and its
config restored byte-for-byte; no game or Simulator remains. See
`docs/artifacts/2026-08-29/g5-rate-alignment-actual-presentation-rejection.md`.

PERF-188 reproduces the corrected same-run join on verified 1x/fullscreen
Final Destination. Across 73.449 seconds and coherent combat/results visual
endpoints, actual presentation averages 59.985932 FPS with one 33.333667 ms
hold; that frame has a nominal 17.058208 ms producer phase and GPU completion
31.500 ms before the skipped deadline. Separately, all fourteen producer rows
above 20 ms map to nominal actual intervals. Fountain and Final Destination
therefore share two independent tails, and both fail the unchanged gate. No
game or Simulator remains. See
`docs/artifacts/2026-08-29/g5-final-destination-combined-join.md`.

PERF-187 invalidates PERF-186's accidentally regenerated 3x/windowed profile
and reruns the combined join at verified 640x528/fullscreen. Across 94.650
seconds of Fountain combat, actual presentation averages 59.978560 FPS with
16.666833/16.666834 ms p95/p99 but retains two 33.333 ms holds. Both frames
were registered and GPU-complete 17-33/15-31 ms before the missed deadline,
with nominal producer phases. Separately, all fourteen producer rows above
20 ms are buffered into nominal actual intervals. The two tails are independent
and both fail the unchanged gate under their respective interpretations. Fresh
combat/results endpoints are coherent. The hook is absent, the canonical
runner remains exact, and 26/26 scoped tests pass. See
`docs/artifacts/2026-08-29/g5-corrected-combined-producer-presentation-join.md`.

PERF-185 completes the first park-and-pivot step after PERF-184: all 26 scoped
native macOS tests pass, including runtime/module loading, CPU/GX behavior,
audio, frontend configuration, and netplay protocol. This proves the restored
baseline is internally coherent; it is not a frame-rate result or G5 pass. No
game, Simulator, or unrelated process change was involved. See
`docs/artifacts/2026-08-29/g5-park-pivot-regression.md`.

PERF-183 retains the unchanged A leg of a proposed Activity Monitor isolation.
With no external process changed, Fountain measures 59.790259 FPS, 16.795167
ms p95, 33.468333 ms worst, and seven doubled render rows with matching vblank
stalls. This is not causal. PERF-184 parks B/A2 as optional follow-up, not a
prerequisite or blocker. Activity Monitor does not need to be paused for work
to continue; do not signal it, `sysmond`, or any other app/service. Continue
with scoped macOS work that does not depend on unrelated process changes. No
game or Simulator remains. See
`docs/artifacts/2026-08-29/g5-activity-monitor-isolation-a-leg.md`.

PERF-182 independently audits the accumulated G5 evidence and current source.
No evidence-qualified public product-local mechanism remains for another
build: guest compute, GPU, Metal/presentation, supported scheduler/timer,
audio, shader, disc, FPS-title, and known Logitech routes are causally closed.
The audit identifies a wording ambiguity between producer and presented
intervals on this fixed-60 panel, but does not edit or weaken D2; genuine
producer intervals still exceed 16.7 ms. Reversible clean-host isolation is an
unresolved optional diagnostic, now parked by PERF-184. It is not the next
required action and does not block other scoped macOS work. No game or
Simulator remains. See
`docs/artifacts/2026-08-29/g5-independent-boundary-audit.md`.

PERF-181 rejects doubling Cubeb's requested buffer from 512 to 1,024 frames.
The CoreAudio device minimum is only 128, so the candidate is effective, but
Fountain regresses from 59.969577 to 59.910028 FPS and retains three doubled
render rows; p95 is unchanged/slightly worse at 16.789792 ms. Vblank retains
five rows above 20 ms and a 34.148375 ms worst. DSP-thread toggling is inert
under Melee's DSP HLE. The source, diagnostic, and private logger setting were
restored exactly; no game or Simulator remains. Keep Cubeb 512. G5 remains
open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-cubeb-buffer-rejection.md`.

PERF-180 refreshes Main Menu performance on the exact current PGO/Game Mode
package. A cold MemoryWatcher-gated route proves the genuine revision-0 menu
class, then a conservative 3,413-row buffered bracket averages 16.683976 ms /
59.937749 FPS. No interval exceeds 20 ms; the worst rolling 60-frame rate is
59.743392 FPS. The old sustained 12.5-30 FPS mode does not reproduce. P95 is
still 18.793042 ms, with distributed delayed/early compensation, and no fresh
visual claim is attached. This is not a smoothness or G5 pass. No source or
config changed, and no game or Simulator remains. See
`docs/artifacts/2026-08-29/g5-current-main-menu-window.md`.

PERF-179 rejects reducing the native Metal layer from its default three-
drawable pool to two. The one-line private candidate catastrophically turns
Fountain's final 2,001 rows into 38.967624 FPS, 33.393333 ms p95, and
33.554417 ms worst, with 1,080 render intervals above 30 ms. The repeated
33-to-16 ms starvation/return pattern persists across shorter suffixes. The
source was restored, the canonical runner returned exactly to SHA-256
`0abc212b...`, and no game or Simulator remains. Keep the default layer pool;
G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-two-drawable-layer-rejection.md`.

PERF-178 directly tests a newly observed side effect of the FPS-title updater.
Each live title change does trigger AppKit window-tab and CoreSpotlight
indexing, but a matched private title-off Fountain run removed recurring combat
indexing while retaining essentially identical mean cadence and a doubled
frame: title-on/title-off were 59.969577/59.969452 FPS with
33.919041/33.398500 ms worst frames. The private setting was restored byte-for-
byte, no product source changed, and no game or Simulator remains. Keep the FPS
title option; continue from PERF-176's combined CPU-GPU/vblank host-execution
stall class. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-fps-title-spotlight-rejection.md`.

PERF-172 proves that the current refreshed PGO topology still activates Game
Mode on macOS 26.5.2. A signed disposable LaunchServices wrapper retained exact
runner `e1f3c1d8...` as its child with known PGO module `bd089303...`.
`gamepolicyd` identified it through Info.plist, granted frontmost/fullscreen/
console policy, activated the fullscreen gaming session, logged `Game mode
enabled`, enabled DPS, and reached `Game mode status is now on`. The probe was
brief and collected no visual, input, audio, or frame-time evidence because
current external host load is not a valid G5 environment. All probe processes
are stopped. Activation readiness is proven; strict G5 remains open and G6 is
blocked. See
`docs/artifacts/2026-08-29/g5-current-gamemode-activation-probe.md`.

PERF-171 restores Game Mode eligibility to the fastest known local package.
The ignored `SsbmPad-PGO.app` still had the correct `bd089303...` PGO module
but stale metadata without the games category or `LSSupportsGameMode`, and it
failed the current package-layout gate. The supported private-profile workflow
refreshed the bundle with current metadata and runner `e1f3c1d8...`, preserved
the stale bundle as a timestamped backup, restored the canonical profile-free
module pointer, and passed layout, native-arm64/macOS-14, and strict deep-sign
verification. No game or Simulator ran. This repairs package readiness only;
Game Mode activation and strict G5 remain unproved, and G6 stays blocked. See
`docs/artifacts/2026-08-29/g5-pgo-package-gamemode-refresh.md`.

PERF-170 rejects lazy-gating the always-on ModernGekko runtime-diagnostics hook.
Its exact work is an 88-byte FNV hash plus relaxed statistic stores. Five
optimized ten-million-call host loops measure 59.410-62.788 ns/call, about
0.00036% of the frame budget; the ASan/UBSan repeat emits no diagnostic. That
is orders of magnitude below materiality and cannot correct millisecond-scale
off-core gaps. Preserve the useful public diagnostics behavior. The disposable
preflight is removed, product remains unchanged, G5 is open, and G6 blocked.
See `docs/artifacts/2026-08-29/g5-runtime-diagnostics-cost-rejection.md`.

PERF-169 rejects the ModernGekko FPS-title thread as the common source of the
clean producer tail. A disposable title-on/off/on run was dominated by changing
host load and degraded monotonically from 41.685 to 38.389 to 32.110 FPS across
A/B/A, so all three legs are excluded rather than promoted as a regression or
option effect. No unrelated process was touched. The causal result comes from
the retained quiet PERF-154/165 windows: rows above 17 ms occupy dispersed
modulo-60 phases, not the one/two adjacent phases predicted for a once-per-
second title update. The private setting is restored and the product remains
unchanged. Do not remove the useful FPS title for G5. G5 stays open and G6
blocked. See
`docs/artifacts/2026-08-29/g5-title-thread-and-overloaded-host-rejection.md`.

PERF-168 rejects a Dolphin-side one-frame presentation reserve before touching
the product. A replay of PERF-152's 1,091 retained Fountain intervals showed
the queue was mathematically plausible, but the required two-thread Metal
control disproved benefit at the real boundary. Capacity one already absorbed
an injected 8 ms producer delay through Metal's existing drawable buffering;
capacity two preserved distinct ordering but increased frame age. Both the
optimized and ASan/UBSan repeats retained a 33.333 ms actual-presentation
worst, and the sanitizer repeat reported no code diagnostic. The disposable
harness is removed. Do not add an offscreen backbuffer/presentation thread or
another application queue. G5 remains on a different causal producer-side
mechanism; G6 stays blocked. See
`docs/artifacts/2026-08-29/g5-one-frame-presentation-reserve-rejection.md`.

PERF-136/137 phase-attribute current Final Destination and reject transient
backup/browser load. Two exact 2,001-frame combat windows have essentially
identical 17.150/17.148 ms total p95. CPU-thread p95 is only 6.729/6.749 ms;
audio p95 is 1.311/1.313 ms. Their worst frames are 27.641/30.737 ms but do
only 4.148/2.590 ms CPU work and lose 19.609/24.645 ms off-core, with just
0.118/0.141 ms video build. The reversal occurred after `fseventsd` and Brave
fell out of the high-load set, so those transient processes are not causal.
Final Destination and Fountain share a host runnable/descheduling tail, not an
M1 compute, static-recompiler, GPU, audio, or timer limit. Do not repeat those
routes. See
`docs/artifacts/2026-08-28/g5-final-destination-off-core-reversal.md`.

PERF-135 refreshes the other required D2 stage on the current build. After
excluding a truncated-log harness run, a windowed control, and a visually
wrong-stage attempt, the verified fullscreen Final Destination match retained
a conservative 2,801-frame interior combat window at 16.683246 ms mean
(59.940 FPS), 17.209583 ms p95, 17.399125 ms p99, and 24.292208 ms worst, with
zero frames above 33 ms. Actual Final Destination, coherent combat, 59.9-60.0
FPS title readings, and match completion were visually verified; Cubeb audio
remained active. This materially improves the old baseline but still fails
strict G5. A private hashed FD state now makes the next phase-attribution run
cheap. Attribute its 24 ms producer class against Fountain's known off-core
tail; do not reopen rejected compiler/pacing routes. See
`docs/artifacts/2026-08-28/g5-current-final-destination-baseline.md`.

PERF-134 rejects a separate runner/runtime PGO build by existing-sample
coverage. `StaticRecompCore::Run` owns 9,279 samples and its already-profiled
module child `chassis_dispatch` owns 9,030; deleting every runner-only sample
would save at most 2.683479%, below the 5% preflight gate. Runner PGO cannot
optimize the module-local generated functions/helpers or remove runnable host
descheduling. Do not instrument/rebuild all of Dolphin for this route. See
`docs/artifacts/2026-08-28/g5-runner-pgo-coverage-bound.md`.

PERF-133 rejects the last simple early-commit Metal API variant before a
Dolphin build. The matched host control delivers 600/600 intervals at
16.666667 ms p95 and zero drops, but `presentDrawable:atTime:` drops all
601 requested drawables with layer display sync both enabled and disabled,
with and without a 25 ms injected producer stall. `CACurrentMediaTime` matches
Mach absolute seconds within 26 microseconds, so this is not a clock-domain
mistake. The disposable harness extension was removed. Do not retry absolute
scheduled presentation, minimum-duration presentation, Rush, fixed wake lead,
or layer-sync variants. G5 remains on the natural no-queue producer/
descheduling tail. See
`docs/artifacts/2026-08-28/g5-absolute-scheduled-presentation-rejection.md`.

PERF-132 corrects a rotated-path diagnosis but does **not** reopen an
optimization. The standalone `llvm-cov` failure was a missing generated-source
path, not missing counters. Checkout reconciliation then found PERF-088 had
already consumed matching coverage and rejected both resulting candidates:
source-weight forms were 59.011-62.751% slower and the semantically correct
single-entry trace was 1.343-3.025% slower. Do not repeat branch probabilities
or FP-trace coalescing. G5 remains on the separate pre-results no-queue
producer/descheduling tail. See
`docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md` and
`docs/artifacts/2026-08-28/g5-profile-edge-coverage-recovery.md`.

PERF-126/127 now separate fixed-panel conversion from genuine late work.
Patch 0021 gives the opt-in phase CSV an absolute host timestamp; the exact
join finds seven pre-results surfaces queued but not displayed in about 110
seconds, closely matching the 6.6 holds predicted when a 59.94 Hz guest feeds
this M1 Air's only 60.0 Hz, non-VRR mode. Their GPU work completed before the
next VSync. Separate no-queue gaps expose real producer stalls, including a
144.530 ms phase with only 19.900 ms CPU-thread work. The logger-free PERF-127
control reproduces 16 ordinary 33.333 ms holds plus one 399.993 ms result
transition; p95/p99 remain excellent at 16.666417/16.666458 ms, but strict
worst-case G5 still fails. Do not change guest speed or duplicate stale frames.
Next isolate only repeated missing-present-command-buffer assignments from
downstream queue drops; Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-host-time-join-and-logger-free-cadence.md`.

PERF-128 independently closes the conversion classification. A host-only
three-drawable Metal control passes 120/120 when unpaced at 60 Hz, then produces
exactly six 33.333 ms holds over 6,600 intervals when fed at 16.683 ms: the
predicted 59.94-to-60 behavior, without Dolphin or guest code. Do not spend the
G5 loop on those fixed-panel holds. Continue only from the separate no-queue
producer stalls and results transition.

PERF-130/131 close the approximately 400 ms match/results hold as a
deterministic guest transition, not a slow rendered field. Three natural runs
reach emulated frame 54872 with exactly 211,892,535 guest cycles and 14,356,543
native dispatches in one output row: the preceding output is frame 54845, so
Melee intentionally advances 27 VI fields without a new XFB. CPU-thread work
is about 10.5-11.7 ms per internal field and the remainder is throttle sleep;
video, drawable acquisition, and presentation are negligible. A targeted Time
Profiler trace confirms generated guest execution rather than Metal, while the
cache-control chain remains below one percent of sampled CPU time. Do not
synthesize stale frames or optimize this transition. G5 remains open for the
separate pre-results no-queue producer stalls, especially host descheduling.
See
`docs/artifacts/2026-08-28/g5-results-transition-classification.md`.

PERF-129 rejects Dolphin's existing Rush Frame Presentation path on exact
emulated work. In the comparable 45-second window, actual 33.333 ms holds rise
from four to ten, CPU-thread rows above 16.7 ms double from 13 to 26, and
`nextDrawable` stalls above 10 ms rise from two to four. The existing
post-render presentation sleep is only about 0.000043 ms/frame, so moving it
cannot recover the measured wait. Earlier no-Instruments Game Mode controls
have no acquisition stall above 10 ms, proving the Display observer adds some
tail cost; do not redesign drawable lifecycle from it. Product remains
unchanged. PERF-130/131 supersede its proposed transition follow-up. See
`docs/artifacts/2026-08-28/g5-rush-frame-presentation-rejection.md`.

PERF-117 through PERF-124 close the actual-display observer ambiguity and the
supplied PERF-106 crash. A minimal Display-only Instruments template records
the WindowServer surface cadence without the rejected in-process drawable
callback. The full Game Mode Fountain trace retains 6,862 consecutive
process-attributed intervals: p95/p99 are both 16.666417 ms, but 15 intervals
are 33.333 ms and one match/results transition is 366.660 ms. Sixteen intervals
exceed 16.7 ms, including misses well before results, so G5 still fails even
though ordinary gameplay is genuinely on a 60 Hz cadence. Exact combat frames
48123..54845 have zero EFB misses. Separately, PERF-122 reproduced the supplied
SIGTRAP when the opt-in state-load signal was consumed during Core Starting;
patch 0013 now defers state requests until Running/Paused, and PERF-123 passes
the same signal-at-frame-zero regression. Next separate 59.94-to-60 phase slips
from genuinely late frames with a shared observer timestamp; do not change
guest speed, duplicate stale content, or retry rejected timer/scheduler/
drawable/compiler routes. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-external-display-cadence-and-savestate-startup.md`.

PERF-114 through PERF-116 now retain a clean prewarmed Game Mode A/B/A
reversal. All three full Fountain spans execute exactly matched guest work with
zero EFB or interpreter misses. Confirmed Game Mode on/off/on measures total
p95 at 17.288/17.725/17.462 ms and worst at 24.337/179.211/24.381 ms; both on
runs have zero >33 ms frames while the off reversal has six. Game Policy logs
prove fullscreen Game Mode was on before combat in both candidates. A signed
wrapper-parent/runner-child topology harness proves the real product launch
path also activates Game Mode, so fresh installs now default to fullscreen and
retain the existing opt-out toggle. This materially mitigates runnable-
descheduling tails but does not pass G5: p95 and worst remain above 16.7 ms.
Next measure actual synchronized display cadence under Game Mode using a
non-perturbing observer; do not equate CPU-side drawable backpressure with a
missed refresh. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-prewarmed-gamemode-reversal.md`.

PERF-104 through PERF-113 separate the remaining natural tail from a newly
closed deterministic hitch. A 74.579 ms natural frame accumulated only 21.186
ms CPU-thread time while the kernel reported the emulation thread runnable;
the 52.940 ms gap is host descheduling, not a Dolphin wait or statically
recompiled on-core work. A marker-aligned System Trace reproduced fragmented
higher-priority host contention, but its per-process attribution is observer-
caveated. Separately, fresh bundle identities exposed R4, RGBA8, and XFB cold
EFB-to-VRAM Metal compiles of 108-134 ms. Prewarming those exact existing
pipelines removed the observed severe combat compiles and reduced frame 48436
from 133.447 to 17.234 ms. PERF-112's full 6,723-frame run found one additional
half-scale XFB variant (1.036 ms), so PERF-113 extends the bounded set to four
and proves zero combat EFB misses through frame 51604. The full prewarmed match
still fails G5 at 17.584 ms p95 / 18.540 ms p99 / 48.962 ms worst. Its first
captured 41.385 ms stall has a 25.619 ms wall/thread gap, 14.809 ms inside
`PresentBackbuffer`, and a runnable thread; the tail remains host scheduling/
GPU-queue timing, not static-recompiler execution. A Game Mode A/B/A screen was
inconclusive. Next run a prewarmed Game Mode on/off reversal through
LaunchServices, now without cold-compile confounding. G5 remains open; G6 and
Final Destination remain blocked. See
`docs/artifacts/2026-08-28/g5-runnable-descheduling-and-efb-prewarm.md`.

PERF-096 through PERF-098 correct the authoritative resolution input and
extend the tail attribution to a natural full match. `moderngekko-run` reads
top-level `config.ini`, not only `Config/GFX.ini`; PERF-091 through PERF-093
were therefore still 3x and their native label/reversal are invalid. A fresh
true-native clone retained `resolution=640x528` and `InternalResolution = 1`.
Against a 3x/native/3x identical-work reversal, native improves total mean to
16.571 from 16.683/16.677 ms and pass count to 250 from 243/241, but total p95
remains 17.055 ms. Keep native as the gate baseline, not as a tail fix. The
phase-only full Fountain combat span has 6,723 rows, total p95/p99/worst
17.001/17.336/54.523 ms, and one >33 ms stall. Its worst row has ordinary
guest work, 17.223 ms CPU-thread time, 36.874 ms off-core wall time, only
0.031 ms `nextDrawable`, and no EFB miss. The remaining severe stall is
pre-Metal/off-core. Next identify its concrete kernel wait or scheduling edge
without retrying rejected scheduler or presentation variants. G5 remains open;
G6 and Final Destination remain blocked. See
`docs/artifacts/2026-08-28/g5-true-native-and-full-stall-attribution.md`.

PERF-090 through PERF-093 directly close the unexplained PGO wall/thread gap.
Precision-timer work is only 0.000372 ms/frame mean and is excluded. The gate
baseline in those runs remained at 3x because the initial correction edited
the non-authoritative GFX file; PERF-097 supersedes that resolution claim. Presenter
subphases then put 99.7% of ordinary video-build time in `BindBackbuffer`; the
direct Metal split puts 4.784 ms/frame mean and 5.737 ms p95 in
`CAMetalLayer.nextDrawable`, 99.600% of bind time. On that exact 3x
440-frame Fountain window, CPU-thread mean/p95/worst are
11.544/12.654/15.782 ms and all rows meet 16.7 ms, while total p95 is
17.756 ms and only 243/440 rows meet 16.7 ms. The current static-recompiled
on-core path is not the source of this CPU-side gap; synchronous drawable-pool
backpressure is. This is not automatically an onscreen miss: prior synchronized
actual-presentation windows passed. PERF-094/095 then rejected
`addPresentedHandler` as an observer because three joined runs changed exact
work from 1.502 to 3.567 billion cycles and collapsed acquisition wait to
0.018-0.023 ms. The logger is removed. Next retain stripped actual-presentation
evidence and target rare pre-acquisition full-match stalls; do not mutate the
drawable lifecycle from these CPU-side counters alone. G5 remains open; G6
and Final Destination remain blocked. See
`docs/artifacts/2026-08-28/g5-frame-wait-and-metal-bind-attribution.md`.

PERF-089 repeats PERF-088's exact 440-frame Fountain window on the retained
frontend-PGO oracle with identical guest work. CPU-thread mean/p95/worst are
11.676/12.984/16.284 ms, and all 440 frames are at or below 16.7 ms. The
statically recompiled on-core path therefore meets this exact budget. Total
p95/p99/worst still fail at 18.256/19.823/25.517 ms because CPU wall exceeds
CPU-thread time by 4.609 ms mean, 6.180 ms p95, and 12.630 ms worst. The one
1.445 ms EFB compile changes neither p95 nor any of the 215 failing frames.
Requested throttle sleep is zero on all 440 frames and measured throttle sleep
is only 0.000511 ms mean, excluding the known timer path. Next classify
CPU-thread wait states versus OS descheduling on the same PGO
oracle; do not perform another static-recompiler flag or source-hint sweep.
G5 remains open; G6 and Final Destination remain blocked. See
`docs/artifacts/2026-08-28/g5-pgo-wall-tail-attribution.md`.

PERF-088 closes the bounded profile-edge route. A coverage-mapped module
decoded exact retained Fountain counts; 113 executed branches were weighted
and 992 arbitrary-entry/full-RAM cases passed. Source weights compacted the hot
interval 7.69x but triggered contradictory `cold hot minsize` IR and regressed
59-63%. A 12,872-byte single-entry GPR-cached trace passed 4,096 cases but its
long ThinLTO screen was 2.492% slower. Both routes are rejected before a module
build. New default-dormant EFB phase counters then found one real 1.198 ms VRAM
pipeline compile in the exact 440-frame Fountain window, but removing it changes
neither p95 nor the 184 frames above 16.7 ms. The 73.470 ms worst frame had no
shader miss and about 48.6 ms of off-core wall time. Next run the same counters
on the retained frontend-PGO oracle; do not prewarm EFB pipelines or broaden
source hints. G5 remains open; G6 and Final Destination remain blocked. See
`docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md`.

PERF-087 identifies profile-weighted basic-block layout inside giant generated
functions as the strongest remaining static-recompilation route. For one exact
hot callful interval, frontend PGO compresses the host-address spread from
148,788 to 11,780 bytes (about 12.6x). Entry-only computed-label and biased-hot
forms remain semantic-equivalent but improve the exact hot slice by only
1.785% and 2.904% median, below the 5% gate. The next bounded experiment must
export the current profile's internal edge weights into one generated chunk and
test profile-free source-level branch probabilities before attempting a broad
generator change. The retained profile has 11,548 counters for the selected
function but its training binary lacks coverage mapping, so the next disposable
instrumented build must add that mapping; raw counter indices must not be
guessed. Synchronous Metal shader compilation remains a separate tail candidate.
See `docs/artifacts/2026-08-28/g5-profile-weighted-block-layout.md`.

PERF-086 rejects AppleClang flag tuning on the exact retained 1,024-instruction
generated-C hot slice. O3, Os, disabled vectorization/unrolling, and Apple-M1/
native CPU tuning all remain within a roughly 1.5-2% paired noise band and none
reaches the 5% preflight gate. Oz cuts text from 64,756 to 40,280 bytes but
slows the exact entry 26.040%. Every candidate matches full relevant CPU state
and RAM. The next experiment is not another compiler flag or isolated leaf: it
must promote live guest state across a profile-qualified callful region and
synchronize only at helpers/observable exits. See
`docs/artifacts/2026-08-28/g5-c-flag-matrix-rejection.md`.

PERF-085 proves an exact `0x803408A0..0x803408D0` paired-single matrix-copy
fast path but rejects the two-address chunk-local matrix family. All 20,000
full CPU/24-MiB-RAM differential cases pass; nine alternating million-call
repeats improve 77.795167 to 23.738208 ns/call (69.486268%). Exact Fountain
coverage is only 0.059158%/0% for copy and 3.632276%/5.110603% for the adjacent
concatenation kernel. Their zero-wrapper-cost combined projection is only
about 2.55%/3.53%, below 5%. Retain the harness; do not build a module or add
another isolated SDK leaf. See
`docs/artifacts/2026-08-28/g5-matrix-copy-family-preflight.md`.

PERF-084 rejects the simpler leaf-only implementation of PERF-083's state-
retention route. Complete function/call attribution over two retained
line-symbol Fountain profiles puts unclosed no-call work at only 14.293349%
and 17.302565% of mapped generated samples. It would require a 34.981% or
28.897% local gain before entry/exit overhead; PERF-081's real complete
function delivered 9.70-10.92%. The analyzer now resolves exact guest PCs to
diagnostic function spans and classifies all `bl`/`blrl` boundaries in about
five seconds. Next preflight one actual guarded parent/callee region; do not
modify DolRecomp or build a module for leaf-only caching. See
`docs/artifacts/2026-08-28/g5-function-family-coverage.md`.

PERF-083 refreshes the current signed product and narrows the researched static-
translation route. A coherent Fountain frame reads 60.0 FPS, but the exact
440-emulated-frame trace measures 16.814891 ms mean / 18.761260 ms p95 /
21.389482 ms p99 / 29.560250 ms worst, with only 56.3636% at or below 16.7 ms.
CPU-thread mean/p95 are 15.735743/17.683831 ms; rendering, present, and audio
remain secondary. The next bounded experiment is a profile-guided generated-C
extended basic block that keeps live guest state in locals and synchronizes at
real exits. No module build follows unless a full-state/RAM semantic preflight
projects above 5% CPU-thread improvement. See
`docs/artifacts/2026-08-28/g5-static-recomp-structural-followup.md`.

PERF-082 rejects DolRecomp's LLVM backend on exact Apple ARM64 hot-slice
evidence. Focused backend/semantic tests pass 3/3, but the exact 1,024-
instruction slice emits 396,548 text bytes / 99,136 host instructions versus
C's 64,756 / 16,183. More importantly, byte-identical-state execution repeats
at 464.884-487.871 ns for LLVM versus 95.992-100.103 ns for C: LLVM is
4.84-4.93 times slower. Common-exit and stock O2/Oz variants are also worse.
The private full compile was stopped at 130/947 objects; no module, app, or
product input changed. See
`docs/artifacts/2026-08-28/g5-llvm22-arm64-preflight.md`.

PERF-081 proves a complete generated guest function can benefit from explicit
state caching but rejects a one-function game build. A narrowed entry alone is
neutral; caching six live GPRs and eight FPR/PS1 pairs plus retaining the exact
first FP gate passes 4,096 randomized cases, including FP-disabled and every
0..-255 initial cycle budget, and repeats a 9.70-10.92% local gain. Its actual
sample share projects only 0.33-0.37% overall. See
`docs/artifacts/2026-08-28/g5-single-entry-register-cache-preflight.md`.

PERF-080 maps retained line-table host samples to guest PCs. The top two
clusters independently reproduce already-closed matrix FIFO and PSMTXConcat
work; the largest unclosed region owns only 3.40% of chassis samples. No single
new region can pass 5%, so retain the mapper and require a broad state-retention
mechanism without a common-dispatch tax. See
`docs/artifacts/2026-08-28/g5-guest-cost-attribution.md`.

PERF-079 proves generator-level guest-state retention but rejects the selected
small region before a game build. A data-free model of the actual
`0x8036C91C..0x8036C934` generated slice passes 4,096 randomized full-state/RAM
comparisons. Its single-entry form removes 31 arm64 instructions, five loads,
and 13 branches and repeats a 21.29-21.79% local speedup. The absolute saving is
only 1.216-1.264 ns/execution: about 0.001 ms/frame at the sampled site and less
than 0.148 ms/frame even under the impossible assumption that every native
dispatch receives the saving. No module, ABI, app, game, or Simulator changed.
Next attribute inclusive host samples to guest PCs and merge one genuinely
expensive region rather than another frequent tiny edge. See
`docs/artifacts/2026-08-28/g5-merged-state-preflight-rejection.md`.

PERF-076 rejects an out-of-line validity callback on every statically linked
cross-chunk call. Focused tests cover denied/accepted targets, exact cycle
budget, post-callee continuation invalidation, and terminal return; the full
module emitted 67,012 guarded sites and real arm64 direct calls. A load-time
CPU-state size check caught and prevented a missing public ABI mirror before
boot. After correcting both disposable mirrors, exact Fountain dispatches fell
69.05% from 51,369,928 to 15,897,417. The clean profile-free pair improved
CPU-thread mean only 1.66% from 15.700 to 15.439 ms, CPU p95 only 0.64%, grew
text 12.79%, reduced compliance to 60.000%, and left p95 at 18.677 ms with a
128.024 ms worst. The callback design and all ABI edits are removed; the
canonical module pointer is restored. A separate stale-generator fix remains:
`prepare-game.sh` now refreshes the top-level `dolrecomp` executable before
generation. Next preflight an inline data-only validity representation; if it
cannot project a >5% gain, move to profile-derived superblocks with boundary
guards. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-guarded-direct-call-rejection.md`.

The follow-up static-recompiler survey ranks an inline eligibility table first,
then a bounded profile-derived superblock if per-edge guards cannot project a
material gain. It also separates CPU translation work from the remaining
Metal/display/off-core frame tail and excludes BOLT's ELF-only path. See
`docs/artifacts/2026-08-28/g5-static-recomp-optimization-research.md`.

PERF-077 now rejects that broad inline-table path before a game build. An
arm64 host preflight matching the preserved callback and full target/callee/
continuation sequence saves only 5.875–5.967 ns per edge. The measured dynamic
edge bounds project 0.237–0.481 ms/frame additional improvement; even the
largest projection plus PERF-076 reaches only 4.72%, below the 5% threshold.
No product ABI or generated module changed. Next preflight one bounded
`8036C8D8..8036C91C` profile-derived superblock with a single boundary guard.
See
`docs/artifacts/2026-08-28/g5-inline-validity-preflight-rejection.md`.

PERF-078 passes a six-path boundary-trace semantics regression but rejects a
dispatcher-only trace forest. The seven-node Fountain candidate covers only
5.16% of dispatches and projects about 0.076 ms/frame. All 278 dominant sampled
edges reach only a zero-overhead 5.37% projection, with 204 required merely to
cross 5% before guards, misses, footprint, and sample error. No game build or
ABI change is justified. Next compare a genuinely merged generated region
against separate chunk calls and prove material CPUState spill elimination.
See
`docs/artifacts/2026-08-28/g5-dispatch-trace-coverage-rejection.md`.

PERF-075 rejects an address-specific ten-edge direct-call candidate while
confirming dispatcher cost. Sampled predecessor/destination data reconstructed
the hot `0x8036C87C..0x8036C944` linked-call sequence. The focused regression
failed before direct continuation and passed both normal and 256-cycle-budget
paths after it; arm64 disassembly proves ThinLTO emitted real direct calls. In
the exact 440-frame Fountain interval, dispatches fell 9.17% from 51,380,895
to 46,668,247, but CPU-thread mean improved only 1.17% from 11.621 to
11.485 ms. Total mean remained 16.667 ms, only 55.000% met 16.7 ms, and worst
remained 22.057 ms. A safety audit also found that nested cross-chunk calls
bypass the runtime's forced-fallback and SMC target-verification boundary. The
candidate is removed and canonical focused tests pass. Next add a cheap target
validity guard with an invalidated-callee regression before screening broader
static calls. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-hot-direct-call-rejection.md`.

PERF-074 rejects a profile-derived Mach-O order file. The linker honored a
tight sequence containing `chassis_dispatch`, common runtime helpers, and four
hot generated regions without changing the 81,959,380-byte text image. The
exact 440-frame Fountain workload matched PERF-072 at 1,501,757,755 cycles and
51,380,895 dispatches. CPU-thread mean improved only 0.083 ms, while total
mean regressed to 16.852 ms, only 55.682% of frames met 16.7 ms, and worst was
133.107 ms. The candidate is not promoted and all product inputs are restored.
Next measure and eliminate one specific high-frequency dispatch edge with a
focused semantic regression before another live build. Final Destination and
G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-order-file-rejection.md`.

PERF-073 rejects whole-module IR-level PGO after a clean end-to-end screen. A
fresh arm64 ThinLTO training module produced a genuine IR profile with 866
post-optimization functions and 3,947,902 blocks, and a fresh profile-use app
built without mismatch warnings. Its exact 440-frame Fountain interval matched
1,501,757,755 cycles and 51,380,895 dispatches, but CPU-thread mean regressed
from 11.621 to 12.085 ms, total p95 remained above budget at 18.048 ms, and a
steady-combat frame reached 69.163 ms. The temporary compiler/cache-identity
edit is restored; the canonical pointer remains profile-free. Next use the
retained profiles to select one bounded hot-region or dispatch-edge change.
Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-ir-pgo-rejection.md`.

PERF-072 retains a data-free local PGO generation/training/merge/package
workflow. `--pgo-generate` has a distinct hash-only cache identity; the new
scripts preserve the canonical module pointer and keep the disc, extracted
game, profile, module, app, savestate, and private paths outside Git. A real
combat-only run produced a 6,556-function/2,727,666-block profile, then a fresh
247-step profile-use build and signed arm64 app. The clean equal-work Fountain
smoke matched 1,501,757,755 cycles and 51,380,895 dispatches at 16.664 ms mean
/ 60.011 FPS and 11.621 ms CPU-thread mean, but failed G5 at 18.065 ms p95 and
22.509 ms worst. The locally trained binary is not code-identical to the prior
oracle and does not replace it. The reusable PGO oracle app has been refreshed
to the current product runner while retaining its known module. IR-level PGO
was subsequently rejected by PERF-073; CS-PGO+LTO and BOLT remain excluded by
host preflights/platform support. See
`docs/artifacts/2026-08-28/g5-local-pgo-training-workflow.md`.

PERF-071 retains a ROM-safe private-profile packaging bridge. The supported
prepare script now accepts validated private LLVM profile data, and
`scripts/package-local-pgo-app.sh` preserves/restores the canonical module
pointer while building, manifest-checking, packaging, and signing the local
PGO app. A full current-source rebuild reproduced the known signed module
`bd089303...af26f5a`; a repeat logged a cache hit in 24 seconds; and a forced
post-selection packaging failure still restored the canonical pointer. The
manifest contains only profile SHA-256 `3f9d2aa4...f572ac12`, not its private
path. This closes the profile-consuming bridge, not clean-clone profile
training or G5. Next build a repository-native local training/merge recipe or
another causal compute change. See
`docs/artifacts/2026-08-27/g5-local-pgo-package-workflow.md`.

PERF-070 joins actual canonical presentation gaps to phase counters. After the
established two-second warm-up, 6,670 intervals measured 16.666667 ms p95,
33.332875 ms p99, 133.332917 ms worst, and 98.306% compliance. The best phase
alignment is `frame - 1` at 0.674781 correlation. Misses average 19.623 ms
CPU-thread time versus 16.080 ms for compliant rows and execute about 5% more
cycles/dispatches; the 133 ms worst is distinct, with 131.944 ms CPU wall but
only 31.829 ms CPU-thread time. A soft real-time time-constraint screen on the
otherwise-perfect PGO short path returned success but introduced a
116.664750 ms stall, so it is rejected and removed. The runner is rebuilt with
only the retained display-sync policy. Next select a reproducible PGO-informed
compute path; do not retry scheduler/priority/time-constraint variants. G5,
Final Destination, and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-phase-join-and-time-constraint-rejection.md`.

PERF-069 identifies a real Metal presentation improvement without passing G5.
Two ordinary no-phase actual-`presentedTime` controls put only 53.3-53.6% of
intervals at <=16.7 ms. Changing only `CAMetalLayer.displaySyncEnabled` made
two 780-interval brackets 100% compliant with 16.666709 ms worst, and an exact
440-frame run preserved 1,501,629,399 cycles and 51,369,928 dispatches while
holding 16.666667 ms worst. This disproves an M1 throughput ceiling. Full
matches still miss rare refreshes: the five-timestamp repeat measured
16.666667/16.666709/99.999791 ms p95/p99/worst and 99.925% compliance.
Both long gaps began 103-131 ms before Metal while `nextDrawable` took only
0.05 ms. Combined-thread QoS, dual-core mode, foreground activation, and an
unbound MemoryWatcher receiver all failed to remove the stalls. The stripped,
product-scoped policy now passes a canonical A/B/reverse-A: no-sync p95 was
18.147/18.561 ms, while synchronized p95/worst were
16.666667/16.666750 ms with 779/779 intervals compliant. The signed canonical
full match reached results with 16.666625/16.666667 ms p95/p99 but ten misses
and 66.666334 ms worst. Retain the improvement; join actual gaps to canonical
phase counters next. G5, Final Destination, and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-metal-presentation-attribution.md`.

PERF-068 rejects CFG-local FP-gate elision. The candidate kept exact-CIA
checks for every direct entry, restarted body checks at leaders and after
`mtmsr`, and moved 72.517% of gates out of sequential bodies. Focused tests,
the known lockstep screen, candidate-specific Fountain PGO, arm64/signature,
and package checks passed; linked `__text` grew only 1.506%. Exact 440-frame
candidate/control/candidate windows matched 1,501,629,399 cycles and
51,369,928 dispatches. CPU-thread mean improved by 0.236-0.490 ms, but total
p95 worsened from 17.677 ms to 17.775/17.980 ms and the <=16.7 ms share stayed
52.5%. All candidate source is removed. Next perform read-only attribution of
the serialization difference between the passing three-drawable host Metal
queue and the live Dolphin path; do not retry FP gates, presentation settings,
or timer variants without one new falsifiable edge. Final Destination and G6
remain blocked. See
`docs/artifacts/2026-08-27/g5-fp-cfg-gate-rejection.md`.

PERF-067 rejects a semantics-preserving per-generated-chunk FP-availability
cache. Focused direct-entry/`mtmsr` tests and the canonical 1,401-PC lockstep
screen passed, and the retained Fountain profile bounded successful helper
calls down by at least 81.0%. But linked `__text` grew 16.45%, and exact
385-frame candidate/control/candidate windows matched all guest work while
candidate CPU-thread mean regressed from 16.114 ms to 23.750/23.650 ms. Total
p95 regressed from 18.113 ms to 26.925/26.622 ms and zero candidate frames met
16.7 ms. All candidate source is removed; do not retry per-chunk flags or a
branch at every FP instruction. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-fp-availability-cache-rejection.md`.

PERF-066 rejects audio removal and a misleading profiler-teardown trigger.
The prior 129-132 ms rows all align to emulated frame 48436, identical guest
work, and a unique 7.0-8.4 ms Cubeb mix burst, but the event did not recur in
two fresh Cubeb reversals or a corrected 90-second trigger. Exact
Cubeb/no-output/Cubeb work matched at 1,501,629,399 cycles; disabling audio
worsened p95 from 17.599/17.631 ms to 17.668 ms and p99 from
18.158/18.395 ms to 19.277 ms. Audio remains enabled and required. G5 remains
open on the ordinary tail. Current official Dolphin adds no relevant
Metal/Cubeb/timer scheduling mechanism, and an exact-work
`SmoothEarlyPresentation=True` run worsened p95 to 17.700 ms and worst to
31.300 ms. Reject audio and presentation-setting changes; return to the
generated-code evidence. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-tail-trigger-and-audio-rejection.md`.

PERF-065 closes the fresh current-PGO line-symbol attribution without a
retained product change. A byte-identical `__text` rebuild maps the remaining
generated samples across diffuse render/resource work rather than one guest
kernel. The only coherent new host cost was JIT-only exception discovery
below static gather writes. Replacing it with Dolphin's fast gather checks
preserved widths/order/check cadence and repeated a small 0.022-0.107 ms
CPU-mean gain, but exact candidate/control/candidate Fountain p95 was
17.883/17.726/17.843 ms: both candidates regressed the control and missed the
5% threshold. The edit and candidate-specific test are removed; the canonical
runner is restored. Separate ordinary 17-19 ms tail attribution from the rare
129-132 ms stall next. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-static-gather-fast-check-rejection.md`.

PERF-064 closes the current-PGO pacing controls without passing G5. A
MemoryWatcher-gated, low-overhead buffered render run still measures
17.956 ms p95 / 22.767 ms p99 / 113.255 ms worst. VSync and
PresentDrawable-only introduce 130.294/79.016 ms stalls and change nominal
boundary work. A host-only strict GCD timer reaches 16.691 ms p95 but misses
p99/worst at 16.712/18.358 ms, so it is rejected before a Dolphin build. The
next step is an actual-`presentedTime` host Metal scheduled-presentation
harness. That harness now passes two 600/600 scheduled runs at <=16.667 ms
with zero drops, proving the M1 display path is capable. The corresponding
live Dolphin candidate instead blocks in Metal and fails at 18.022 ms p95 /
132.188 ms worst; fullscreen also fails at 17.493 ms p95. The product edit is
removed. Continue from a fresh no-phase current-PGO compute sample. Final
Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-pgo-pacing-controls-rejection.md`.

PERF-063 establishes a fresh, current-source PGO oracle. Exact
candidate/control/candidate Fountain windows match 1,501,757,755 guest cycles
and 51,380,895 dispatches. The candidate cuts CPU-thread mean from 15.941 ms
to 11.889/11.606 ms and improves p95 from 18.123 ms to 17.608/17.776 ms, but
does not meet the strict 16.7 ms tail gate. Ordinary `sleep_until` is rejected:
it worsens wake-lateness p95 to 2.124 ms and total p95 to 18.227 ms. A retained
live frame shows coherent Pikachu/CPU-Fox Fountain at a 59.9 FPS title. The
local ROM-trained profile/module remain outside Git and do not replace the
reproducible product module. G6 remains blocked. See
`docs/artifacts/2026-08-27/g5-current-source-combat-pgo-oracle.md`.

ThinLTO remarks now explain that gain as 44,741 selective inlines led by
41,671 FP-availability sites; hot thresholds are 3,000 while cold sites remain
325/45. The hottest isolated short long-load is only a roughly 1 ns/call
opportunity and was rejected before a module build. The validated candidate is
installed locally as `build-macos/SsbmPad-PGO.app`; the reproducible canonical
app remains unchanged.

PERF-062 fixes a real signed-package workload defect. The app now builds with
an explicit bundle mode, keeps Dolphin `Sys` under `Contents/Resources`,
retains the revision byte from validated `boot.bin`, and seeds the GALE01r0
idle PC into the current-run config before CPU initialization. Two identical
440-field Fountain package runs executed 1,501,629,399 cycles and averaged
16.514/16.575 ms (60.55/60.33 FPS), versus the contaminated package's
3,567,157,782 cycles and 18.627 ms. Retain the roughly 2.1 ms product gain,
but do not pass G5: p95 remains 18.281/18.259 ms and only 65.7%/57.5% of rows
meet 16.7 ms. G6 remains blocked. See
`docs/artifacts/2026-08-27/g5-packaged-idle-config-retained.md`.

PERF-060 rejected a finite-normal FPRF branch at host preflight: complete
semantics passed, but 54/54 paired five-million-operation runs lost and the
candidate was 31.1% slower. PERF-061 then rejected the private stale-profile
oracle after its nominal shared window measured 24.379 ms mean / 53.859 ms
p95 with incomplete profile coverage. Neither changed the product. See
`docs/artifacts/2026-08-27/g5-fprf-hotpath-preflight-rejection.md` and
`docs/artifacts/2026-08-27/g5-stale-pgo-oracle-rejection.md`.

PERF-059 rejected a dominant scalar-FMA mode split at host preflight. The
fixed single/add/non-negative path passed 160,000 complete-state comparisons,
but 56 paired five-million-operation timing runs averaged 19.362982 ns versus
19.347089 ns for the generic helper, with a near-even 29/27 win split. Flag
dispatch is not the material `ppc_fmadd_op` cost, so no module/game build was
wasted and no product source changed. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-27/g5-fma-mode-split-preflight-rejection.md`.

The retained savestate harness now has a causal emulated-frame clock. A
Pikachu/CPU-Fox Fountain state visibly restored active combat, and two equal
440-field control windows matched exactly in guest cycles, native dispatches,
and static bursts. Patch 0014 logs Dolphin's savestated VI/Movie frame beside
the presentation index. A shared-state A/B/reverse-A rerun found no
reproducible benefit from the 64-bit gather-write arm: warm candidate and
reverse-control ranges overlapped, and the fastest reverse control was faster.
The arm is removed; the diagnostic remains. The exact window still measured
roughly 21.5-23.3 ms mean and 24.1-26.3 ms warm p95, so G5 clearly fails and
G6/iPadOS remains blocked. See
`docs/artifacts/2026-08-27/g5-emulated-frame-shared-state-verdict.md`.

The native arm64 package now reproducibly completes Character Select ->
controlled 1v1 -> results using the reference FIFO controller path. A clean
Kirby-versus-CPU-Samus time battle on Venom accepted movement, attacks, and
jumps through the match and reached the results screen. A live process sample
captured Cubeb/CoreAudio mixing while game streaming samples were being
pushed. G4 is therefore met.

The lowest unmet gate is sustained 60 fps. Fountain of Dreams is now measured:
a clean Yoshi-versus-CPU-Zelda trace produced 19.552 ms mean / 22.862 ms p95
and 111.083 ms worst. A process sample placed about 88% of the CPU thread in
generated `chassis_dispatch`, so the required scene is CPU-bound. An isolated
PGO candidate improved an exact Yoshi-versus-CPU-Ice-Climbers pair by 8.5% at
median, 10.0% at p95, and 15.4% at p99, but was rejected for an unbounded
129.740 ms worst frame. A smaller no-EXRAM specialization improved an equal
105-second pair by only 3.0-4.4% across sustained percentiles and regressed the
worst frame from 1320.456 ms to 1385.798 ms, so it was also rejected. That
worst-frame comparison was later found to be measurement-confounded: the
logger flushed every frame and visual evidence capture introduced large
pauses. With buffered logging, a capture-free 90-second clean control had a
55.135 ms worst frame and missed the sustained target at 17.903 ms median /
21.168 ms p95. The corrected PGO replay improved every metric to 16.682 ms
median / 16.846 ms p95 / 17.031 ms p99 / 45.425 ms worst; a macOS 14 rebuild
reproduced the result. That portable module is retained locally as the
best-known build, but its ROM-trained profile is not a committable shipping
input. Final Destination is now unlocked through an isolated ROM-safe save and
measured at 16.678 ms median / 16.946 ms p95 / 17.189 ms p99 / 1385.242 ms
worst. Single-loop inlining, blanket loop outlining, and an Apple Silicon
precision-timer spin experiment are rejected. Timestamp correlation attributes
the remaining steady-state tail primarily to generated-module compute. A
combined portable-PGO/no-EXRAM candidate left median unchanged and regressed a
matched attract p95 from 17.848 ms to 19.335 ms, so it was also rejected. A
smaller static reproduction and causal compute-tail reduction are still
required. A profile-free 1024-cycle generated-loop budget also regressed
matched attract p95 to 22.926 ms and is rejected; the default 256 is retained.
Exact `noinline` reproduction of all 247 PGO-cold helper symbols regressed
matched attract p95 to 21.459 ms, proving symbol outlining alone is also
insufficient.
A 2:1 Fountain/attract combined PGO profile improved attract p95 slightly to
17.682 ms but worsened mean and p99 to 17.744/20.654 ms, so it was rejected.
The controlled FIFO route was then re-established end to end and used for
visible Fountain and Final Destination 1v1s. A direct 2:1 Fountain/Final
Destination PGO profile also failed its matched attract screen: median/p95
regressed from 16.684/18.077 ms to 16.778/18.383 ms and worst rose from 19.088
ms to 57.091 ms. That candidate is rejected and the retained Fountain-only
module is restored. Revision-0 source attribution then identified
`loop_80349494` as the scheduler idle loop. Configuring Dolphin's existing
`StaticRecompIdlePC` facility removes it from the hot-dispatch histogram and
roughly halves host dispatch/cycle work in comparable attract runs. The
optimization is retained, but it is not a G5 pass: profile-free active scenes
still ran around 40-55 FPS and reached 16.9 FPS on Jungle Japes. Further work
must train and measure visually verified required-stage combat with idle
skipping active, rather than profile idle polling.

The next C-emitter experiment inlined the common `MSR.FP` enabled check while
preserving the existing FP-unavailable exception fallback. A clean matched
1,000-frame screen improved p95/p99 by 3.1%/3.4%, but regressed worst frame
from 27.987 to 34.777 ms and the <=16.7 ms share from 49.80% to 49.20%.
Four-player scenes still ran around 45-48 FPS. The candidate is rejected under
the strict retention rule and dependency source is restored.

The revision-0 cold route now self-verifies VS CSS. `gcpipe.py` pumps watched
memory during animation delays so Dolphin's empty per-frame datagrams cannot
starve the terminal update; a clean retry exited on `GameState=0x02020100`.
The same run reached a visually verified, audio-enabled Fountain match. Its
capture-free combat interval still fails G5 at 17.115 ms p95, 17.318 ms p99,
59.024 ms worst, and 54.714% of render frames at or below 16.7 ms.

A subsequent locked-cache pointer experiment proved that paired-single traffic
could bypass the full MMU and moved the CPU thread from almost continuous
generated compute to predominantly pacing sleep. It was nevertheless rejected:
a clean 5,803-frame screening bracket regressed render p95/p99 to
18.899/20.513 ms and the <=16.7 ms share to 46.631%. The temporary source,
test, and app-bundle changes were restored. See
`docs/artifacts/2026-08-25/g5-locked-cache-pointer-rejection.md`.

Re-testing the Apple-silicon final-spin hint in that new compute-headroom state
also failed retention. Median returned to 16.678 ms, but render p95/p99/worst
regressed to 19.658/21.009/70.455 ms. The composed timer/hook experiment was
removed and Final Destination was not run.

The older 03:30:57 sample that motivated the pointer experiment is now
withdrawn as combat attribution: its dominant address maps inside Melee's
640x480 THP video decoder, proving it sampled boot/opening/menu work. A
subsequent `mach_wait_until` pacing idea was rejected without a game build
because a 1,000-frame host preflight was worse than the current timer in p95,
p99, worst, and <=16.7 share.

The stage-attribution gap is now closed for a fresh diagnostic. Visible native
window evidence shows Pikachu, level-1 CPU Kirby, the Stage Select screen, an
explicit `Fountain of Dreams` highlight, live Fountain combat, and results.
The concurrent 12-second combat sample placed 5,367 of 8,396 CPU-thread samples
in `StaticRecompCore::Run`; its diagnostic render bracket measured 17.565 ms
p95, 22.530 ms p99, and 30.615 ms worst. This is valid Fountain attribution,
but not a clean acceptance interval because sampling ran concurrently. It also
shows that the retained PGO module was trained before the idle-PC optimization,
making a fresh visually verified idle-skipping corpus the next focused test.

That fresh reduced-idle corpus did not improve Fountain. Its PGO-use candidate
regressed clean render p95/p99/worst to 17.216/17.459/88.407 ms and reduced the
<=16.7 ms share to 54.212%, so it was rejected without a Final Destination
run. The same visibly verified match reproduced impossible scale/displacement
at a 59.9 FPS title, providing independent positive evidence for
`VISUAL-001B`.

The counter-control prerequisite for a truly combat-only corpus is now
verified. Instrumented modules optionally export LLVM reset/dump hooks; the
host resolves them without changing the module ABI and invokes them on the
emulated CPU thread from an explicit one-shot memory predicate. The real-module
fixture excluded seven pre-reset calls and retained exactly three post-reset
calls. A live main-menu-to-VS transition then logged reset followed by a
successful dump. Release/PGO-use modules export neither hook. The next G5
experiment was therefore paused for a release-only attribution audit rather
than another blind training run.

That audit corrected the current bottleneck model. In 4,094 visually verified
Fountain combat frames, the release spent 8.574 ms mean / 9.875 ms p95 in
guest compute and 8.088 ms mean in deliberate throttle sleep. Total frame time
was 16.683 ms mean / 17.237 ms p95 / 19.112 ms worst; compute correlation with
the total was only 0.0794. The 12.5-22 FPS window was an LLVM-instrumented
trainer, not the release. A bounded Apple 2.02 ms precision-spin experiment
regressed active-scene p95 to 19.314 ms and was removed. G5 remains open under
its strict tail rule, but the normal release has substantial compute headroom;
the active source investigation moves to the independent visual-state
corruption rather than more timer or PGO guessing.

An independent source/disassembly review confirms the stale-`ps1` mechanism,
corrects `0x80374174` from a claimed cause site to a later comparison point,
and identifies the same lane-1 defect at 1,237 `frsp` sites. It also falsifies
the claim that PGO prevented helper call-site inlining and shows that the
12-15 versus 45-48 FPS observations used unmatched scenes. The large inline
candidate is not retained. The report-driven follow-up is now complete:
DolRecomp routes scalar-single arithmetic and all 1,237 `frsp` sites through
exact GXRuntime
helpers, writes both lanes, and preserves Rc/FPSCR behavior. Focused DolRecomp
and GXRuntime suites pass. A 200-frame corrected corpus containing Peach stayed
coherent but did not reproduce the exact known Battlefield composition, so it
is strong negative evidence rather than visual closure. Exact-source PGO
improved a matched no-input render p95 from 20.616 to 18.232 ms, falsifying the
feared helper-PGO collapse, but still fails 16.7 ms and is not required-stage
acceptance. See
`docs/artifacts/2026-08-25/g5-scalar-single-frsp-correction.md`.

No Simulator is booted. G6 remains gated on G5.

The Fountain visual report is split as `VISUAL-001A/B`. Both parts are now
closed. The blurred/blocky
lower reflection is closed as reference parity: it appears in profile-use,
profile-free, no-module, and signed official Dolphin 2606a native-scale Metal
runs. EFB-to-RAM and non-deferred-copy experiments were unnecessary and were
reverted. The separate fighter-body report was not reproduced in an initial
9.8-second interaction clip, but a later uncontaminated adjacent sequence
confirms impossible multi-frame Peach hair/arm deformation at a 59.9 FPS title,
recovering by frame 186. The exact scalar-single/`frsp` correction subsequently
survived a 402.7-second, 2,110-frame extended matched corpus with Brinstar,
multiple four-player scenes, and dense Peach combat. `VISUAL-001B` is closed
under that documented boundary and reopens on any recurrence.

The corrected module has now been replayed on the phase-CSV runner through a
visibly verified, capture-free Fountain bracket. Across 3,683 conservatively
trimmed frames, total p95/p99/worst are 17.016/17.227/18.986 ms and only
53.136% are at or below 16.7 ms. Video build, present, and audio have p99 costs
of only 0.101/0.106/1.318 ms. Derived compute is 10.459 ms mean / 12.540 ms p99,
with one 18.010 ms compute-only overrun; most other frames still include about
6.2 ms deliberate throttle sleep. G5 remains open. The next diagnostic adds
requested sleep and wake-lateness fields to distinguish pacing overshoot from
compute before another behavior change. That follow-up excludes pacing
overshoot: wake lateness is only 0.199 ms p95 / 0.214 ms p99 with 0.024 total-
time correlation, while the five worst frames requested no sleep and spent
19.470-24.159 ms in derived compute. Timer work stops. The next diagnostic adds
per-frame static-recompiler work deltas to distinguish guest workload from host
cost. See
`docs/artifacts/2026-08-25/g5-corrected-fountain-deadline-attribution.md`.

That attribution now shows tail guest work is flat: bursts are 0.25% lower and
charged cycles 0.04% lower than the <=16.7 ms body, while host nanoseconds per
native dispatch correlate 0.783 with total time. A default-off user-interactive
CPU-thread QoS candidate cut worst from 51.412 to 18.002 ms and slightly
improved p99, but regressed p95 from 16.975 to 17.031 ms. It is rejected and
removed. The diagnostic counters remain; a matched repeat/control is next.

The unchanged repeat reproduced p95 at 16.975 ms and a 21.604 ms host-cost
cluster. A valid thread-CPU Fountain bracket then measured total p95/p99/worst
16.970/17.184/19.088 ms. After subtracting known idle/throttle time, residual
off-core time is only 0.018 ms p95 / 0.148 ms p99; tail thread CPU rises by
0.207 ms versus only 0.067 ms residual. The tail is mainly on-core execution
cost.

Runtime fallback-class attribution is complete, and its original no-op semantic
conclusion is corrected. Dolphin invalidates JIT cache lines for `dcbf`,
`dcbst`, and supervisor-mode `dcbi` with D-cache emulation off. Generated C now
uses the same exact cache-control helper as LLVM and continues the native block;
the stale specialized fallback was removed. In the matched profile-free
Fountain comparison, mean/p95/p99/worst improved from
20.329/22.581/23.825/33.066 ms to 17.858/20.054/21.319/27.860 ms. Cache
fallbacks fell from 6,066.022/frame to zero while 6,064.453 direct helper calls
per frame remained exactly accounted. This correction is retained, but only
19.285% of frames meet 16.7 ms, so G5 stays open. See
`docs/artifacts/2026-08-25/g5-cache-control-parity.md`.

Dispatch-return attribution was rejected after its exact form visibly reduced
Stage Select to about 44.5 FPS and sampled forms could not exclude observer
cost. All of that instrumentation was removed and the normal signed runner was
restored. A clean normal-runner Pikachu-versus-level-1-CPU-Donkey-Kong Fountain
interval still averaged 19.761 ms / 50.605 FPS, with 21.551 ms p95 and only
2.000% of frames at or below 16.7 ms. Its CPU thread averaged 19.575 ms despite
fewer native dispatches than the earlier 59.932 FPS Pikachu/Kirby control.
This proves a real slowdown interval, but a fresh cold replay of the same
Pikachu/CPU-DK/Fountain roster then visibly held 59.8-59.9 FPS through active
combat and results. DK is therefore not a deterministic trigger; the slowdown
is intermittent or host/path-state dependent. Animated menus also visibly
slow, so menu behavior remains in the regression scope; only the exact
classifier's menu reading is numeric and therefore cannot be used as a clean
baseline.

The fresh normal external sample found the known scheduler idle poll
`loop_80349494` atop 156/886 CPU-thread samples even in the full-speed replay.
A burst-entry idle precharge candidate did not remove it (183/890 candidate
samples), and its clean 4,090-frame phase bracket still failed at 17.577 ms p95
/ 19.527 ms p99. The candidate and test helper were removed; the normal signed
runner is restored. The next experiment must return from the exact generated
idle branch after one poll and then pass a matched semantic/sample/phase test,
not add work to every dispatch. See
`docs/artifacts/2026-08-26/g5-idle-precharge-rejection.md`.

## Goal ledger

| Goal | State | Evidence / blocker |
|---|---|---|
| G0 Environment ready | Pass | `docs/artifacts/2026-08-24/g0-environment.md`; pinned revisions below |
| G1 SMC pass recorded | Pass | `docs/artifacts/2026-08-24/g1-smc-report.md`; no generator proven, runtime guard retained, `smc_failed=0` |
| G2 Module recompiles and links | Pass | `docs/artifacts/2026-08-24/g2-module-and-package.md` |
| G3 macOS boots to title | Pass | `docs/artifacts/2026-08-24/g3-macos-title-and-input.md`; retained title and A-transition screenshots |
| G4 macOS playable | Pass | `docs/artifacts/2026-08-24/g4-controlled-match.md`; clean CSS -> 1v1 -> results plus live Cubeb/CoreAudio mixing evidence |
| G5 macOS 60 fps | Deferred, not passed | DECISION-215 permits mobile sequencing while unavailable external 59.94 Hz/VRR verification is deferred; D2 remains unchanged |
| G6 Simulator core boots | Pass | `docs/artifacts/2026-08-30/g6-ios-simulator-core-and-gameplay.md` |
| G7 Shell ported | Pass | `docs/artifacts/2026-08-30/g7-shell-parity-and-diagnostics.md` |
| G8 Test matrix green | In progress | `docs/artifacts/2026-08-30/g8-test-matrix-reconciliation.md`; rows 1, 2, 4, 5, 6, 8, 12, 13, 14, and 15 pass; row 3 is provisionally accepted; others partial/failed |
| G9 Netplay working | Not started | G8 first; requires a synchronized completed match with an iPadOS endpoint |

## Pinned inputs and dependencies

- Retail image: GALE01 disc 0 revision 0, SHA-256
  `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`.
- Extracted DOL: SHA-256
  `0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448`.
- SunPad: `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- ModernGekko: `048c426ba3db0369e40826d22ad3adcce7fe7c58`.
- Dolphin/RecompCore submodule: `e13ab348f13cd67879f6db6e9d7185410f8f62c6`.
- DolRecomp: `93b881c8f73df1d64a88491f2aa50c7c9ed2384d`.
- RecompCore: `af7a1a4854ee243b92926875e5a6b66663b0fda0`.
- ModernGekko Template: `1ee85bb5e09c38f493a09f5fa6e9dc8228b23e42`.
- melee: `8b5e380f412dc6bad8cc0557fa8fd95fee6815ed`.
- m-ex: `c9f25da0e59e8c387895371934e98eb5046796b3`.

## Test matrix

The authoritative row-by-row reconciliation is
`docs/artifacts/2026-08-30/g8-test-matrix-reconciliation.md`. Rows 1, 2, 4, 5,
6, 8, 12, 13, 14, and 15 pass. Rows 9, 10, and 11 are partial; row 7 is failed
and attributed. Row 3 is provisionally accepted by the user's
explicit external-display waiver and must be replayed later on suitable
hardware.

POLISH-225 adds a first-class ROM-safe root README and replaces the inherited
sun icon with an original controller-free charcoal/silver/crimson SsbmPad
arena-impact emblem. The touch R shoulder now uses the same compact standard
button and width as L, with matching digital-plus-255/0 trigger semantics. The
focused layout regression, a fresh Release build, and a live iPad Simulator
visual check pass. G8 row 9 remains partial until every control is exercised in
live gameplay. See
`docs/artifacts/2026-08-30/g8-public-presentation-and-compact-r.md`.

PERF-226 rejects exact-profile iOS `-O3` at the structural gate. Relative to
the same-source exact PGO O2 module, O3 grows `__text` by 16,580 bytes, leaves
`chassis_dispatch` unchanged, and grows each sampled hot generated-function
span. No result approaches the required five-percent materiality threshold, so
there is no live replay and no product promotion. G8 row 7 remains
fail/attributed. See
`docs/artifacts/2026-08-30/g8-ios-exact-pgo-o3-rejection.md`.

DIAG-227 closes G8 row 12. The macOS launcher now provides a visible Export
Diagnostics action and an automation route through the same privacy-bounded
exporter. The rebuilt binary exported the real runner log with lifecycle,
static-recompiler, audio, and controller breadcrumbs; zero private-path,
game-data, disc-image, memory-card, or save matches remained. Together with
the prior iPad export, both row platforms pass. See
`docs/artifacts/2026-08-30/g8-macos-diagnostics-export.md`.

BATTLE-228 closes G8 row 5. A controlled macOS run visibly proved four
fighters, the literal Battlefield selection, an item in live combat, and a
natural Time Battle results screen. The full bracket completes without a
crash but takes 198.890 host seconds for a two-minute game timer, approximately
36.2 effective game FPS despite near-59.94 presentation. This is an honest row
5 target miss, not a 60 FPS claim, and strengthens the existing static-core
producer attribution. See
`docs/artifacts/2026-08-30/g8-macos-battlefield-four-player-item-match.md`.

CLASSIC-230 closes G8 row 6. A macOS Classic run visibly cleared Brinstar and
the following team battle, completed the target bonus stage without a
progression block, and advanced into the Bowser fight. Generated-code-derived
MemoryWatcher chains matched live fighter percentages and removed the blind-
macro ambiguity. Retained screens report 59.9-60.0 FPS; visible geometry warp
remains separately open. See
`docs/artifacts/2026-08-30/g8-macos-classic-three-stage-progression.md`.

## Open defects and decisions

- **INPUT-001:** Supplied disc is GALE01 revision 0 rather than the PRD's
  preferred revision 2. Proceed per PRD Section 5.1 and keep module identity
  tied to the actual SHA-256.
- **INPUT-002 (superseded):** Native Quartz was not reliable enough for replay;
  the shipped reference FIFO path now provides reproducible controlled input.
- **INPUT-003 (fixed):** The FIFO parser/controller binding was corrected and
  replayed successfully through a complete clean 1v1.
- **LAUNCHER-001 (fixed):** Removed the unsolicited recursive Documents scan at
  startup; Browse remains explicit.
- **LAUNCHER-002 (fixed):** Replaced the frontend's blocking child wait with a
  nonblocking event-pumping wait so macOS no longer marks it unresponsive while
  the runner is active.
- **PERF-001 (historical attribution superseded):** The early exact trace was
  genuinely slow, but later release-only phase timing disproves the blanket
  conclusion that the current retained release is steady-state CPU-bound.
- **PERF-002 (fixed):** Forced Ninja response files broke CMake's Apple IPO
  probe while the cache identity still claimed ThinLTO. The macOS configure path
  now uses platform-default response files and a distinct cache identity.
- **PERF-003:** Corrected buffered C-backend PGO improves Fountain mean 8.3%,
  median 6.8%, p95 20.4%, p99 22.6%, and worst 17.6%. The portable macOS 14
  module is retained locally as the best-known build, but the ROM-trained
  profile remains local and cannot be the reproducible shipping solution.
  PGO still fails the 16.7 ms p95/p99/worst gate.
- **PERF-004:** A GameCube-only RAM specialization improved an equal Fountain
  pair by 3.0-4.4% across mean/median/p95/p99 but was rejected below the 5%
  retention threshold. Its reported 1385.798 ms worst-frame comparison is
  invalidated by the measurement correction below and is not a product claim.
- **PERF-005 (fixed):** The frame-time logger forced a file flush every frame,
  while screenshots inside exploratory runs introduced multi-second pauses.
  Logging is now buffered through a reproducible dependency patch. A 90-second
  capture-free Fountain control had a 55.135 ms worst frame, disproving the
  previously inferred recurring approximately 1.3-second product hitch for
  that run; sustained timing still fails G5.
- **PERF-006:** Forcing the hottest sampled generated polling helper,
  `loop_80349494`, to inline removed its symbol but regressed the matched
  Fountain replay to 18.293 ms median / 22.040 ms p95 / 24.031 ms p99. The
  experiment was rejected, generated/cache state was restored, and the local
  portable PGO module remains the best-known build.
- **PERF-007:** Final Destination is unlocked in an isolated local GCI and was
  verified after a clean no-mod restart. Its matched portable-PGO run measured
  16.678 ms median / 16.946 ms p95 / 17.189 ms p99 / 1385.242 ms worst. The
  stage blocker is closed, but G5 still fails on shared tail behavior.
- **PERF-008:** Blanket `noinline` on all 969 generated loop helpers collapsed
  an active attract battle to 4.1 FPS and was rejected. A default-off Apple
  Silicon precise-spin timer improved a matched attract p99 by only 0.63%,
  left p95 effectively unchanged, retained multi-second tails, and was also
  rejected. Default source, profile, cache, and app state were restored.
- **PERF-009:** Timestamp correlation attributes frames above 17 ms primarily
  to generated-module work rather than timer overshoot. Combining PGO with the
  no-EXRAM specialization left median unchanged and regressed a matched attract
  p95/p99 to 19.335/20.477 ms, so the combination was rejected before
  required-stage replay. The portable-PGO app was restored.
- **PERF-010:** Raising the generated loop return budget from 256 to 1024
  cycles reduced potential dispatcher boundaries but regressed matched attract
  median/p95/p99 to 16.757/22.926/24.989 ms and vblank in parallel. The
  profile-free experiment was rejected and default 256 restored.
- **PERF-011:** All 247 PGO-only loop helpers had profile entry counts zero
  through nine. A profile-free candidate outlined exactly those helpers and
  retained the hot polling helper, but regressed attract median/p95/p99 to
  16.814/21.459/22.548 ms. PGO branch weights and internal block layout, not
  helper symbol presence alone, are material.
- **PERF-012:** A separate three-minute attract profile merged at 1:2 weight
  with the original Fountain corpus improved attract p95 and vblank tail but
  regressed render mean/p99 to 17.744/20.654 ms. It was rejected before real
  stages; useful broader PGO must train Fountain and Final Destination.
- **PERF-013 (fixed):** Revision-0 generated source proves `loop_80349494` is
  the OS scheduler idle loop, not an active-gameplay helper. The retained
  GALE01r0 game-settings patch routes that PC through ModernGekko's existing
  `CoreTiming().Idle()` path. It disappears from the top dispatch sites and
  sharply reduces idle dispatch/cycle counts without changing guest behavior.
  Profile-free active combat still fails G5, so this closes wasted idle work,
  not the performance gate.
- **PERF-014:** Inlining the common `MSR.FP` enabled check preserved the
  exception fallback and passed generated-C plus PowerPC reference tests. A
  clean matched screen improved p95/p99 from 20.622/21.597 to
  19.979/20.854 ms, but worst regressed from 27.987 to 34.777 ms and the
  <=16.7 ms share slipped. It is rejected; see
  `docs/artifacts/2026-08-25/g5-fp-fast-path-and-watcher-audit.md`.
- **INPUT-004 (fixed):** Static-recomp watched memory is fixed and reproducibly
  packaged. Direct bounded MEM1/MEM2 reads are used only for an active static
  module; ordinary cores retain the MMU path, and initial zero is now
  published. Generated revision-0 instructions corrected the mixed-revision
  predicates to `GameState=0x80477D68` and title lockout `0x804D4594`. A cold
  replay observed the complete 20-to-zero lockout transition, sent one START,
  reached Main Menu, and reached four-slot VS CSS after bounded menu readiness
  windows. The earlier terminal timeout was empty-datagram socket starvation:
  the client did not read during menu sleeps. Watched delays are now pumped,
  the timing-dependent initial-zero prerequisite is removed, and a cold retry
  exited zero on `GameState=0x02020100` (`GM_VS`, CSS index zero). Evidence:
  `docs/artifacts/2026-08-25/g5-static-recomp-memory-watcher-route.md` and
  `docs/artifacts/2026-08-25/g5-watcher-pump-fountain-replay.md`.
- **PERF-015:** The repaired route reached a visually verified Fountain match
  with Cubeb audio, then ran a capture-free 5,463-frame combat interval. The
  59.9 FPS title concealed a failing tail: render p95/p99/worst were
  17.115/17.318/59.024 ms and only 54.714% of frames were <=16.7 ms. G5 remains
  open; see `docs/artifacts/2026-08-25/g5-watcher-pump-fountain-replay.md`.
- **PERF-016 (rejected):** GXRuntime's unused external-pointer callback was
  wired to Dolphin's locked-cache pointer under a failing regression and an
  explicit lockstep-journaling guard. The callback was live and created large
  CPU headroom, but a clean 5,803-frame screening interval regressed render
  p95/p99 to 18.899/20.513 ms and the <=16.7 ms share to 46.631%. It was
  rejected before Final Destination; all temporary code and staged build
  artifacts were restored. Evidence:
  `docs/artifacts/2026-08-25/g5-locked-cache-pointer-rejection.md`.
- **PERF-017 (rejected):** Replacing the final macOS scheduler yield with the
  ARM `yield` hint was re-tested specifically on top of the locked-cache
  compute-headroom state. It recovered a 16.678 ms median but regressed render
  p95/p99/worst to 19.658/21.009/70.455 ms, so the composition was removed
  before Final Destination. Evidence:
  `docs/artifacts/2026-08-25/g5-locked-cache-pointer-rejection.md`.
- **PERF-018 (preflight rejected):** A 1,000-frame host benchmark rejected
  `mach_wait_until` before a game build: p95/p99/worst were
  23.431/24.530/24.951 ms versus 22.852/23.525/23.543 ms for the current loop,
  and the <=16.7 share also fell. The same audit withdrew the 03:30:57 sample
  as combat evidence because its dominant PC is the THP video decoder.
  Evidence: `docs/artifacts/2026-08-25/g5-locked-cache-pointer-rejection.md`.
- **PERF-019 (attribution restored):** A visually gated native route proved
  Pikachu versus level-1 CPU Kirby on Fountain from CSS through results. The
  12-second combat-only process sample placed 5,367/8,396 CPU-thread samples in
  `StaticRecompCore::Run`; its concurrent diagnostic bracket measured render
  p95/p99/worst 17.565/22.530/30.615 ms. Sampling overhead excludes it from G5
  acceptance, but it is the first valid post-correction combat hotspot sample.
  Evidence: `docs/artifacts/2026-08-25/g5-visually-verified-fountain-sample.md`.
- **PERF-020 (phase attribution corrected):** Buffered present-aligned timing
  on 4,094 verified Fountain combat frames measured 8.574 ms mean / 9.875 ms
  p95 guest compute, 8.088 ms mean throttle sleep, and 16.683/17.237/19.112 ms
  total mean/p95/worst. Compute correlation with total was 0.0794. A 2.02 ms
  Apple precision-spin candidate regressed active-scene p95 to 19.314 ms and
  was removed. G5 remains open, but the current release is not steady-state
  compute-bound. Evidence:
  `docs/artifacts/2026-08-25/g5-release-frame-phase-attribution.md`.
- **PERF-021 (retained correctness/performance fix):** Source parity audit
  withdrew the incorrect claim that `dcbf`/`dcbi` are no-ops with D-cache
  emulation disabled. Generated C now uses the exact runtime cache helper and
  continues its block, matching LLVM and Dolphin semantics. A matched
  profile-free Fountain comparison improved mean frame time 12.153% to
  17.858 ms and p95 to 20.054 ms while eliminating 6,066.022 cache
  fallbacks/frame. Only 19.285% of frames are <=16.7 ms, so G5 remains open.
  The next experiment retrains exact-source PGO on this changed control flow.
  Evidence: `docs/artifacts/2026-08-25/g5-cache-control-parity.md`.
- **PERF-022 (PGO rejected):** Exact-source cache-control PGO used exactly one
  eligible, visually verified Fountain training profile. The signed arm64
  PGO-use module exported no profiling hooks and ran with Cubeb, zero fallback
  steps, and zero SMC failures. Its 6,428-frame trimmed Fountain bracket
  measured 16.894/17.860/18.080/1,367.699 ms mean/p95/p99/worst; only 55.009%
  of frames were <=16.7 ms. The candidate fails even without the single large
  stall, so it was rejected before Final Destination. Invalid attract/demo
  routes and a roster-unmatched profile-free run were explicitly excluded from
  A/B claims. Evidence:
  `docs/artifacts/2026-08-26/g5-cache-control-pgo-rejection.md`.
- **PERF-023 (macOS pacing rejected):** A 3.02 ms early wake plus true busy
  spin passed 900/900 host-preflight samples at <=16.7 ms, but a corrected-
  module Fountain bracket measured 19.667/22.357/24.690/141.484 ms
  mean/p95/p99/worst and only 2.895% <=16.7 ms. CPU-thread work rose to
  19.437 ms mean, requested throttle time vanished, cache fallbacks stayed
  zero, and 6,062.409 direct cache helpers/frame remained accounted. The
  timer candidate is removed. A stale generated-module bracket was separately
  excluded; canonical regeneration restored exact source suffix `06852d9f...`
  and module SHA `2dce1352...`. Evidence:
  `docs/artifacts/2026-08-26/g5-macos-pacing-contention-rejection.md`.
- **PERF-024 (menu idle shortcuts rejected):** A watcher-gated normal CSS
  control averaged 59.939 FPS but missed strict p95 at 16.896 ms; its native
  sample put Melee's scheduler idle poll in 1,839 samples. An immediate return
  changed guest timing and visibly fell to 28-31 FPS. A cycle-preserving poll
  collapse reduced CPU-thread mean from 8.463 to 5.48-5.60 ms and the loop to
  34 samples with matched guest cycles, but repeated CSS p95 regressed to
  18.479/18.468 ms as mean precision-timer wake lateness rose from 0.070 ms to
  0.375-0.407 ms. Both candidates are removed; G5 remains open. Evidence:
  `docs/artifacts/2026-08-26/g5-menu-idle-loop-rejections.md`.
- **PERF-025 (menu pacing follow-ups rejected):** A retained host harness
  proved 500 us sleep chunks eliminate the newly exposed long-sleep miss, and
  chunked true spin achieved 16.683 ms p95 synthetically. In coherent watched
  CSS, chunked yield plus the idle collapse repeated at 16.933/16.902 ms p95;
  chunked true spin repeated at 16.928/16.890 ms despite <0.001 ms wake-
  lateness p95. Neither passes 16.7 ms or consistently beats the 16.896 ms
  normal control. All product changes are removed; the diagnostic harness is
  retained. Evidence:
  `docs/artifacts/2026-08-26/g5-menu-pacing-followup-rejections.md`.
- **PERF-026 (CSS boundary attribution retained):** Three watched normal CSS
  brackets proved intended-present and CPU target cadence are exact. Tail rows
  do not add CPU slices/throttle calls; `SyncGPU` is about 0.0001 ms and video
  queue/service about 0.03 ms. The variable 2.452 ms/body versus 3.176 ms/tail
  interval is CPU work after throttle and before VI output. A CSS-only,
  post-throttle piggyback sample ranked scheduler poll `0x80349494` first and
  `OSDisableInterrupts`/`OSRestoreInterrupts` leaves `0x80345738`/`0x80345760`
  second/third. Diagnostic code is removed; G5 remains open. Evidence:
  `docs/artifacts/2026-08-26/g5-css-boundary-attribution.md`.
- **PERF-027 (interrupt-leaf coalescing rejected):** Exact, event-boundary-
  guarded module execution of revision-0 `OSDisableInterrupts` and
  `OSRestoreInterrupts` passed focused register/MSR/CR/cycle semantics and
  removed about 51 native dispatches/frame. A watched 3,600-frame CSS bracket
  measured 16.908 ms p95 versus the 16.896 ms normal control, with unchanged
  CPU work. Candidate source is removed and the normal signed package is
  restored. Evidence:
  `docs/artifacts/2026-08-26/g5-interrupt-leaf-coalesce-rejection.md`.
- **PERF-028 (empty forced-fallback preflight rejected):** A corrected
  out-of-line host benchmark measured the empty-vector guard at only 0.314 ns
  saved/dispatch, projected as 0.021 ms across a CSS frame. No game build or
  product change was justified. The major intermittent menu slowdown is now
  tracked separately from the approximately 0.2 ms strict-tail miss. Evidence:
  `docs/artifacts/2026-08-26/g5-empty-fallback-preflight.md`.
- **PERF-029 (menu background pacing attributed; activity hints rejected):** A
  five-minute normal background CSS soak averaged 59.940 FPS with no sustained
  sub-55 rolling window, but measured 17.838 ms p95, three 52-85 ms hitches,
  and 0.925 ms mean wake lateness. An explicitly raised normal control measured
  16.927 ms p95 and 0.070 ms wake lateness with unchanged CPU work. Apple
  user-initiated and user-interactive latency-critical activity variants did
  not change the background result and were removed. Evidence:
  `docs/artifacts/2026-08-26/g5-menu-background-pacing.md`.
- **PERF-030 (focus attribution withdrawn):** A single verified normal CSS
  process ran foreground, background, then foreground again. The final 3,600
  complete rows of each stable segment all averaged 59.940 FPS, with
  16.912/16.928/16.934 ms p95 and 0.077/0.072/0.074 ms mean wake lateness.
  Focus did not reproduce the earlier cross-process pacing difference, so no
  focus policy is justified. The normal product is unchanged; G5 remains open.
  Evidence: `docs/artifacts/2026-08-26/g5-active-transition-pacing.md`.
- **PERF-031 (CSS-armed hitch captured):** A default-off rolling trigger was
  armed only after MemoryWatcher proved VS CSS. After four minutes it captured
  a 54.918 FPS one-second window containing 70.344/37.102/33.618 ms hitches.
  CPU-thread work stayed at 11.281-12.975 ms, guest work was flat, and
  video/present/audio stayed tiny, attributing the loss to off-core host delay.
  Two/five/ten-second windows remained 57.316/58.866/59.399 FPS, so a sustained
  12-15 FPS menu collapse is not reproduced. Evidence:
  `docs/artifacts/2026-08-26/g5-css-slow-window-capture.md`.
- **PERF-032 (dispatch branch attribution retained; lookup order rejected):**
  A watcher-gated Main Menu interval counted 373,345,803 generic dispatches;
  every call hit generated original code, with zero replacement, host, alias,
  or miss branches. Packaged-control and candidate cold routes both reproduced
  approximately 2.9-second and 3.15-second scene-load present gaps containing
  about 174/188 normally paced guest frames and negligible Metal present work.
  Stable menu presentation remained 59.936/59.928 FPS. The lookup candidate's
  visually verified 3,078-frame Pikachu/CPU-Captain-Falcon Fountain bracket
  measured 16.833/18.588/20.262/101.926 ms mean/p95/p99/worst, or 59.407 FPS,
  and was rejected before Final Destination. The exact-order counter remains
  default-off as patch 0010; normal packages export no hooks. G5 remains open.
  Evidence:
  `docs/artifacts/2026-08-26/g5-dispatch-branch-attribution-and-lookup-rejection.md`.
- **PERF-033 (Fountain frame-address attribution retained):** A visually
  verified Pikachu/CPU-Donkey-Kong Fountain bracket measured 16.664 ms p50 and
  17.881 ms p95. Tail frames executed about 8,008 extra native dispatches, but
  the delta was spread across many PCs; the largest individual site accounted
  for only about 525/frame. Separately, the cold route captured four 1.87-3.17
  second CPU-bound transition gaps with 55-99 million dispatches, dominated by
  `lbDvd`/`DVDCancel` wait paths while Metal present stayed near 0.02-0.05 ms.
  The major menu transition stalls and combat tail are therefore separate.
  Next: isolated fast-disc control; no isolated-leaf retry. Evidence:
  `docs/artifacts/2026-08-26/g5-fountain-frame-address-attribution.md`.
- **PERF-034 (fast-disc rejected):** An isolated GALE01r0 game-settings layer
  with `FastDiscSpeed = True` preserved coherent CSS and Pikachu/CPU-DK
  Fountain behavior, but still produced 1.85-3.23 second scene-change rows
  with 54-93 million dispatches. Those rows aggregate 111-193 ordinary
  frames' worth of guest cycles and are not sustained animated-menu FPS.
  A visually gated 2,500-row Fountain interval measured 16.671 ms p50 and
  17.827 ms p95, so G5 still fails. Fast-disc is removed. The combat tail maps
  broadly to HSD/GX rendering work; next is a coherent dispatch-boundary
  preflight, not DVD or isolated leaves. Evidence:
  `docs/artifacts/2026-08-26/g5-fast-disc-rejection.md`.
- **PERF-035 (live Main Menu reproduction):** The restored canonical runner
  was driven through the genuine title lockout to CSS and deliberately backed
  out to the animated Main Menu. A 5,042-frame untouched Main Menu bracket
  averaged 59.936 FPS with 16.946 ms p95, but included a visible 102.552 ms
  hitch. The same route reproduced four 1.90-3.72 second CPU-bound transition
  freezes with 58-92 million native dispatches and only 0.019-0.031 ms Metal
  present time. A sustained 12.5-30 FPS Main Menu state did not recur, but the
  transition freezes and pacing hitch keep menu behavior in G5's failure
  scope. Do not use the 59.9 title alone as acceptance evidence or retry
  fast-disc. Evidence:
  `docs/artifacts/2026-08-26/g5-live-main-menu-reproduction.md`.
- **PERF-036 (generated chunk-size candidate rejected):** LLVM generation is
  not a bounded Apple-arm64 option: the installed LLVM is 22.1.8 versus
  DolRecomp's 19/20 check, and the backend rejects production targets other
  than x86-64 Linux/Windows. An isolated C backend candidate reduced generated
  chunks from 4,096 to 1,024 instructions and passed a bounded lockstep screen,
  but visibly verified Pikachu/CPU-Yoshi Fountain measured 17.867 ms p95 and
  only 59.740 FPS. Mean native dispatches rose to 161,478/frame because more
  chunk crossings outweighed smaller host functions. The candidate is removed;
  product module `2dce1352...` is restored. Evidence:
  `docs/artifacts/2026-08-26/g5-generated-chunk-size-rejection.md`.
- **PERF-037 (larger C chunks rejected semantically):** An isolated
  8,192-instruction C candidate reduced hashed chunks from 237 to 119 and
  linked an 83 MB module, but a matched headless lockstep screen recorded 91
  reports versus the canonical control's 88. Both had seven fallback skips,
  three zero skips, and zero undercharges; the candidate alone added
  memory-writing report PCs `0x80339460`, `0x803394C4`, and `0x80339510`.
  It was rejected before visual/performance testing and never installed. The
  generator limit is restored to 4,096 and the candidate is in Trash. Next
  work must preserve canonical segment boundaries or strengthen proof before
  transforming them. Evidence:
  `docs/artifacts/2026-08-26/g5-c8192-semantic-rejection.md`.
- **PERF-038 (direct verified-chunk table rejected):** A temporary ABI 4
  exposed 237 generated function pointers parallel to the unchanged verified
  chunks, removing the module's duplicate address-to-function lookup while
  preserving every canonical segment/timing/SMC boundary. The matched
  lockstep screen exactly preserved 88 reports, seven fallback skips, three
  zero skips, and zero undercharges. Visually verified Pikachu/CPU-Yoshi
  Fountain then measured 16.934 ms mean, 18.753 ms p95, and only 59.054 FPS
  over 4,743 clean combat frames. The candidate is removed, ABI 3/generic
  dispatch are restored, and the product app was never modified. Evidence:
  `docs/artifacts/2026-08-26/g5-direct-chunk-table-rejection.md`.
- **PERF-039 (matched canonical Yoshi control):** The untouched ABI 3 product
  visibly repeated P1 Pikachu/CPU Yoshi on literal Fountain. Exact 4,743-frame
  combat measured 16.762538 ms mean, 17.553780 ms p95, and 59.656839 FPS.
  Against the same roster/stage/sample count, the rejected direct table added
  0.171120 ms mean, 1.198945 ms p95, and about 3,537 native dispatches/frame.
  The regression is confirmed, both paths still fail strict G5, and the next
  preflight is to carry the chunk index already verified by the loop condition
  rather than resolve it again. This does not close the separate multi-second
  menu-transition freezes. Evidence:
  `docs/artifacts/2026-08-26/g5-direct-chunk-matched-yoshi-control.md`.
- **PERF-040 (last-chunk cache rejected):** A temporary DOL-only reuse of the
  existing `m_last_chunk_index` field returned a cached index only when the
  next PC remained inside the same exact chunk; all misses and REL modules kept
  the canonical lookup. It reached the canonical 88-report lockstep set, but
  the live route entered the opening/demo path and timed out before CSS. A
  visibly bounded active How-to interval then sustained only 49.134 FPS with
  24.563 ms p95 over 1,479 frames; attract screens also read 37.5-39.2 FPS.
  These are absolute failures, not matched regressions. The candidate is
  removed and both local runners/product hashes are canonical. Evidence:
  `docs/artifacts/2026-08-26/g5-last-chunk-cache-rejection.md`.
- **PERF-041 (front-end hypothesis split):** Visually gated Apple CPU Counters
  show four-player Pokemon Stadium combat is strongly instruction-delivery
  limited on the CPU thread (53.6% delivery / 33.1% useful), while the slow
  How-to fight is not (20.2% delivery / 74.7% useful). How-to frames
  19,250-19,450 still averaged 21.252 ms with 20.493 ms CPU-thread work and
  only about 41,372 dispatches/frame. Broad outlining is rejected. Native
  `-Oz` preflight shrank two combat-hot chunks by 36-38%, but both ThinLTO and
  mixed native link attempts reproduced the exact canonical dylib, so no
  candidate entered semantic/runtime testing. Build cache and product are
  canonical. Next: clean visually gated How-to native sample plus frame-PC
  attribution, then one named routine/helper only. Evidence:
  `docs/artifacts/2026-08-26/g5-front-end-pressure-preflight.md`.
- **PERF-042 (THP inline FP gate rejected):** The How-to counter trace maps
  68.09% of CPU samples to generated chunk `0x8032D940` and 11.54% to
  `0x80331940`; GALE01 symbols identify THP video decompression. A focused
  inline `MSR.FP` gate removed the sampled 4.40% helper call when FP was
  enabled and passed generated-C plus exact disabled-exception tests. Its
  1,401-check lockstep screen preserved the canonical 88 reports, but the
  candidate grew `__text` by 855,404 bytes and visibly fell to 39.1 FPS in
  coherent four-player combat. Clean frames 8,050-8,250 averaged 26.055 ms /
  38.380 FPS with 25.037 ms CPU-thread work and 0% <=16.7 ms. It is removed;
  product and active source module are canonical. Next: default-off THP-time
  external-write address histogram before any MMU-validated buffer fast path.
  Evidence: `docs/artifacts/2026-08-26/g5-thp-fp-gate-rejection.md`.
- **PERF-043 (locked-cache write path split and rejected):** A default-off
  external-write histogram sampled 8,389,081 writes and found 99.588560% in
  the 16 KiB locked-cache window, almost entirely one-byte THP output. An exact
  in-bounds direct-store candidate passed the 1,401-check canonical lockstep
  screen and improved the visually verified How-to movie from 21.252 to
  16.565 ms mean, but a fresh matched Pikachu mirror on literal Fountain
  regressed from 16.801 ms / 59.519 FPS / 18.391 ms p95 to 17.933 ms /
  55.764 FPS / 20.200 ms p95. It is removed; source and packaged product are
  canonical. The THP/MMU attribution remains, but the next experiment must be
  a THP-scoped host preflight rather than another global memory fast path.
  Evidence:
  `docs/artifacts/2026-08-26/g5-locked-cache-fast-path-rejection.md`.
- **PERF-044 (locked-cache write chassis attributed):** A temporary
  Release-mode arm64 benchmark used Dolphin's real `System`, `MMU`, and L1
  buffer for five processes of 11 x 2,000,000 writes/path. Median
  nanoseconds/write were 6.765 canonical, 5.446 after `Memcheck`, 1.356 for
  journal-check plus direct store, 2.289 with stable MSR propagation restored,
  and 1.018 for the raw store. The generic hardware dispatcher, not
  `Memcheck` alone, owns most removable inner cost; preserving MSR still
  leaves 4.476 ns/write theoretical headroom. This is attribution only: both
  prior global locked-cache integrations regressed gameplay. Temporary code
  is removed and the source runner is canonical. Next: offline contiguous
  store-run analysis in the exact two hot THP chunks before any new build.
  Evidence:
  `docs/artifacts/2026-08-26/g5-locked-cache-write-chassis-preflight.md`.
- **PERF-045 (paired PSQ transactions retained):** Dolphin's interpreter and
  arm64 JIT perform non-`W` paired-single stores as one wide memory
  transaction; GXRuntime issued two. The corrected float/U8/U16/S8/S16 paths
  pass exact external address/value/size/count regressions and the full
  GXRuntime suite. A first runtime package was correctly excluded after its
  module hash proved it was a stale cache hit. The cache identity now includes
  the GXRuntime and module-template sources; clean build key
  `1e1debc9fb83a31a` records `module_sources=7dcfd35e31be989b` and repeats as a
  hit. The genuine candidate improved the visually verified Mario/Bowser THP
  movie from 21.252 ms / 47.055 FPS to 16.678 ms / 59.959 FPS and CPU-thread
  mean from 20.493 to 11.095 ms. Coherent Pikachu/CPU-Mario Fountain combat
  measured 16.710 ms / 59.845 FPS with 18.217 ms p95 and zero fallbacks. The
  fix and reproducibility guard are retained, but G5 remains open because both
  p95 tails exceed 16.7 ms and live four-player rendering remains slow.
  Evidence:
  `docs/artifacts/2026-08-26/g5-paired-store-transactions-retained.md`.
- **PERF-046 (paired PSQ loads rejected):** Exact external-read transaction
  regressions passed, but the distinct candidate failed live
  Pikachu/CPU-Yoshi Fountain at 19.178837 ms mean / 52.141 FPS / 21.220959 ms
  p95 over 4,578 frames. CPU-thread mean was 18.779152 ms while guest cycles
  stayed near 8.107M and fallbacks stayed zero. Candidate code, tests,
  bootstrap entry, and patch are removed; active key `1e1debc9fb83a31a` and
  the unchanged signed product are restored. Next: line-symbolized native
  sampling of the retained build, not another global load/MMU shortcut.
  Evidence:
  `docs/artifacts/2026-08-26/g5-paired-load-transaction-rejection.md`.
- **PERF-047 (line-symbol attribution; GQR0 split rejected):** A
  line-symbolized module with byte-identical `__text` mapped 283/8,892 chassis
  samples to the six GX FIFO stores in `WriteMTXPS4x3`. A regression-first,
  runtime-guarded GQR0 helper passed GXRuntime 1/1 and DolRecomp 14/14, then
  failed live Bowser/CPU-Ness Fountain at 20.823964 ms / 48.022 FPS /
  23.354708 ms p95 across 5,486 frames. CPU-thread mean was 20.331661 ms,
  native dispatches rose to 149,650.631/frame, guest cycles stayed flat, and
  fallbacks stayed zero. Candidate source is removed; retained key
  `1e1debc9fb83a31a` is active and the product was never modified. Next:
  host-only exact ordered GX FIFO matrix-batch preflight, not another helper
  split. Evidence:
  `docs/artifacts/2026-08-26/g5-line-symbolized-fountain-attribution.md` and
  `docs/artifacts/2026-08-26/g5-gqr0-store-fast-path-rejection.md`.
- **PERF-048 (64-bit gather write rejected):** A real-GPFifo host benchmark
  found stable 7.976-8.111x isolated speedup for one `Write64` versus eight
  `Write8` calls, and the one-arm candidate passed a matched 1,398-check
  lockstep screen. Live Fountain did not retain that promise. A 7,430-row
  Pikachu/CPU-Peach bracket regressed from 18.679 ms / 53.537 FPS / 20.975 ms
  p95 to 19.579 ms / 51.076 FPS / 22.605 ms p95. A no-P1-input 7,431-row
  bracket moved mean by only 0.255 ms in the candidate's favor while p95
  worsened from 21.425 to 23.151 ms and CPU AI diverged by about 34,785 native
  dispatches/frame. A shared-state causal replay was unavailable: the
  standalone signal handler is not installed by the branded entrypoint and
  native shortcuts produced no state file. The candidate and temporary
  benchmark/guard are removed; product hashes remain canonical. Next: build a
  verified frame-deterministic comparison harness before another performance
  candidate. Evidence:
  `docs/artifacts/2026-08-27/g5-gpfifo64-rejection.md`.
- **PERF-049 (deterministic savestate harness retained):** The branded runtime
  did not install Dolphin no-GUI's save/load signal handlers; `SIGUSR1` killed
  the first verified Fountain seed. A handler-only candidate survived but
  could not write because the custom runtime also skipped
  `UICommon::CreateDirectories()`. Patch 0013 now creates Dolphin's standard
  user tree and, only under `MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1`, scopes
  `SIGUSR1`/`SIGUSR2` to existing platform save/load requests. A signed live
  run wrote a real 9.2 MB `GALE01.s01`, visibly advanced, loaded it, rewound,
  survived, and continued phase rows. The RAM-bearing state stays local.
  Bootstrap, patch reverse/forward, focused CTest 4/4, and `gcpipe` 16/16
  pass. G5 remains open; next is one shared-state control/candidate Fountain
  comparison with aligned work counts. Evidence:
  `docs/artifacts/2026-08-27/g5-deterministic-savestate-harness.md`.
- **PERF-050 (emulated-frame A/B harness retained; gather width rejected):**
  A fresh Pikachu/CPU-Fox Fountain state visibly restored saved combat after a
  divergent interval. Equal presentation-row windows did not match guest work,
  so patch 0014 now logs Dolphin's savestated VI/Movie frame. Two equal
  440-field controls then matched exactly at 3,567,157,803 cycles, 59,374,686
  dispatches, and 905,158 bursts. In a shared-state A/B/reverse-A bracket,
  warm gather candidates ranged 22.391-23.311 ms mean while reverse controls
  ranged 21.459-22.360 ms; the ranges overlap and the fastest control won.
  The `Write64` arm is removed, patch 0014 is retained, G5 remains open, and
  G6 remains blocked. Future candidates require equal emulated-frame windows.
  Evidence:
  `docs/artifacts/2026-08-27/g5-emulated-frame-shared-state-verdict.md`.
- **PERF-051 (transparent PC elision rejected):** Exact late-Fountain Apple
  counters attributed 48.674% of CPU-thread time to instruction delivery. A
  regression-first C-backend candidate passed DolRecomp 14/14 and matched the
  current 1,398-check lockstep report set while removing 279,793 generated
  `ctx->pc` stores and 1.41 MiB of text. In equal emulated frames, however, it
  ran at 20.149624 ms / 49.629 FPS / 21.983167 ms p95 versus a fresh canonical
  control at 19.016881 ms / 52.585 FPS / 20.575625 ms p95. Work differed by
  only three guest cycles and one native dispatch. The candidate is removed,
  active key `1e1debc9fb83a31a` is restored, G5 remains open, and G6 remains
  blocked. Next: identify a newly measured dynamic exact-window cost rather
  than optimize static code size. Evidence:
  `docs/artifacts/2026-08-27/g5-transparent-pc-elision-rejection.md`.
- **PERF-052 (FP-availability inline rejected):** A 0.413-0.463 ns host
  preflight and exact sample justified inlining the enabled-FP MSR test while
  retaining the slow exception path. Focused semantics, bootstrap, and a
  1,367-PC/91-report lockstep screen passed. Equal-frame A/B/A did not repeat
  the first CPU-thread gain: candidate repeat measured 19.035697 ms mean /
  20.830500 ms p95 / 18.579110 ms CPU-thread mean versus canonical
  19.001550 / 20.675166 / 18.595254 ms. The candidate is removed and key
  `1e1debc9fb83a31a` restored. A too-early savestate load also established a
  new harness rule: require advancing emulated frames before `SIGUSR2`.
  Evidence: `docs/artifacts/2026-08-27/g5-fp-availability-inline-rejection.md`.
- **PERF-053 (`PSMTXConcat` replacement preflight rejected):** Exact-window
  line evidence identified guest `0x803408D4..0x8034099C` as the SDK matrix
  concatenation kernel. A revision-hash-gated disposable replacement matched
  full CPU state, output, and scratch-stack memory across 20,000 randomized
  trials and ran 3.23-3.29x faster per hit. The supported replacement probe,
  however, added 2.04-2.40 ns to every non-hit dispatch, or about 0.27-0.31 ms
  at Fountain's dispatch rate. More than 2,200 hits/frame would be needed to
  break even; sampling bounds the plausible net gain to only hundredths of a
  millisecond. The candidate was removed before a live run, the active module
  and product are unchanged, G5 remains open, and G6 remains blocked.
  Evidence:
  `docs/artifacts/2026-08-27/g5-psmtxconcat-replacement-preflight-rejection.md`.
- **PERF-054 (computed-label entry decoder rejected):** Exact line-zero native
  samples were attributed to generated chunk-entry decoding. A regression-first
  computed-label candidate preserved 4,096-instruction chunks and passed
  focused generated-code tests 3/3. Its full ThinLTO module proved canonical
  Clang already uses a constant-time 32-bit relative jump table: the candidate
  merely substituted 64-bit pointers. `__TEXT` shrank 5,095,424 bytes, but
  `__DATA_CONST` grew 7,749,632 bytes, total VM size grew 2,703,360 bytes, and
  the hot chunk's stack frame doubled. Standalone hit timings were mixed with
  no repeatable win. The candidate was removed before lockstep/live testing;
  active module and product are unchanged, G5 remains open, and G6 remains
  blocked. Evidence:
  `docs/artifacts/2026-08-27/g5-computed-label-entry-decoder-rejection.md`.
- **PERF-055 / CORRECTNESS-006 (scalar FMA exactness retained):** Exact-window
  attribution found 118 top samples in `ppc_fma`, then a failing-before
  regression showed the larger issue: all 3,677 generated scalar FMA sites
  missed normal `fmadds` FI/FR behavior and NI-mode single-subnormal flushing.
  DolRecomp now emits all eight scalar FMA variants through exact
  `ppc_fmadd_op`; focused semantics, DolRecomp 14/14, GXRuntime 1/1, a
  1,367-PC lockstep screen, clean patch reproduction, and packaged live
  Fountain all pass. The warmed live candidate measured 19.127040 ms / 52.282
  FPS / 21.457875 ms p95 versus canonical 18.967010 / 52.723 / 20.397875, so
  this is retained for correctness and determinism, not speed. The packaged
  capture shows coherent Pikachu/Fox geometry at 52.5 FPS. Active key
  `d852344fce9334dc` is promoted; G5 remains open and G6 remains blocked.
  Next: re-sample the exact promoted window and attribute the next distinct
  dynamic cost, excluding known scheduler and corrected FMA work. Evidence:
  `docs/artifacts/2026-08-27/g5-scalar-fma-semantics-retained.md`.
- **PERF-056 (diagnostic-overhead gate rejected):** A promoted no-phase-log
  control proved full frame telemetry costs roughly 1-2 FPS, but the normal
  product still measured only 53.3-55.3 FPS on the retained Fountain state.
  A regression-first gate removed default lockstep, freeze-trace, profile, and
  dispatch-map work from the common loop; `ShouldCheck` disappeared and
  `StaticRecompCore::Run` self samples fell 309 to 274. The equal emulated-frame
  verdict nevertheless lost: candidate 18.997244 ms / 52.639 FPS / 20.771917
  ms p95 versus promoted control 18.926719 / 52.835 / 20.781917, with work
  within 14 cycles and three dispatches. Candidate and regression are removed;
  the signed product was untouched. G5 remains open and G6 blocked. Next:
  line-symbol attribution of the large generated `func_8035D940` and
  `func_8033D940` costs, not another runtime-observer shortcut. Evidence:
  `docs/artifacts/2026-08-27/g5-diagnostic-overhead-gate-rejection.md`.
- **PERF-057 (multiword range helpers retained/promoted):** A fresh
  line-symbolized Fountain sample attributed 251/11,849 CPU-thread samples to
  generated `lmw`/`stmw` transfers. Regression-first shared helpers classify
  a complete ordinary-RAM range once while preserving per-word fallback,
  mirrors, EXRAM, journaling, reservation invalidation, and `lmw` base-register
  overwrite behavior. Candidate A/A2 measured 18.719603/18.681924 ms mean and
  18.241015/18.269532 ms CPU-thread mean versus control 18.848329/18.484106,
  with equal or near-equal work. `__text` shrank 331,796 bytes. The official
  key `b2d4b69da942f7c2`, full suites, clean patch reproduction, signed package,
  and coherent live Pikachu/Fox Fountain frame at 54.7 FPS pass. This is a
  small retained improvement, not 60 FPS: G5 remains open and G6 blocked.
  Next: sample the newly promoted no-logger module and select a new coherent
  dynamic cost; do not inline the helpers or include short stores. Evidence:
  `docs/artifacts/2026-08-27/g5-multiword-range-helpers-retained.md`.
- **PERF-058 (deterministic GPFIFO64 retry rejected):** Fresh no-logger and
  byte-identical line-table samples reconfirmed the six hot `WriteMTXPS4x3`
  FIFO stores. The retained shared-state harness supplied the causal gate the
  earlier retry lacked. Candidate A/A2 and a same-build reversal executed
  exactly 1,501,629,399 cycles and 51,369,928 dispatches. Candidate means were
  16.680304/16.884788 ms versus reversal 16.516704 ms; its small A CPU-mean
  gain did not repeat, and p95 remained above 16.7 ms. The arm is removed. A
  packaged row had different work and is excluded as contaminated. G5 remains
  open; G6 remains blocked. Next: aggregate non-entry lines in the remaining
  `func_8035D940` cost, excluding gather width. Evidence:
  `docs/artifacts/2026-08-27/g5-gpfifo64-deterministic-rejection.md`.
- **PERF-059 (outer scalar-FMA mode split rejected):** The dominant constant
  mode passed complete semantics but tied/lost the generic helper at host
  preflight. Evidence:
  `docs/artifacts/2026-08-27/g5-fma-mode-split-preflight-rejection.md`.
- **PERF-060 (finite-normal FPRF branch rejected):** Six semantic batches
  passed; the corrected 54-pair preflight measured 9.364704 ns candidate versus
  7.144759 ns control, with zero candidate wins. Evidence:
  `docs/artifacts/2026-08-27/g5-fprf-hotpath-preflight-rejection.md`.
- **PERF-061 (stale current-source PGO oracle rejected):** The excluded
  private profile had widespread missing/mismatched coverage and its packaged
  440-field interval measured 24.378538 ms mean / 53.859334 ms p95. No profile
  or candidate module is promoted. Evidence:
  `docs/artifacts/2026-08-27/g5-stale-pgo-oracle-rejection.md`.
- **PERF-062 (packaged revision-idle config retained):** The signed app's Sys
  layout and executable-only configuration path prevented GALE01r0's retained
  scheduler idle PC from reaching the static core. Explicit app-bundle mode,
  revision retention, and current-run GameINI seeding reduce identical package
  work from 3.567B to 1.502B cycles. Two repeats average 60.55/60.33 FPS, but
  p95 remains 18.281/18.259 ms, so G5 stays open and G6 blocked. Evidence:
  `docs/artifacts/2026-08-27/g5-packaged-idle-config-retained.md`.
- **VISUAL-001A (closed as reference parity):** The blurred/blocky Fountain
  floor reflection appears in PGO, profile-free, no-module, and signed official
  Dolphin 2606a JIT64 SC + Metal native-scale runs. It is not an ssbmpad visual
  regression. EFB-to-RAM and non-deferred-copy controls were reverted.
- **VISUAL-001B (closed; recurrence rule remains):** Adjacent `.png` frames 176-184 showed
  Peach's hair and arms deforming into impossible spike/blade shapes over
  multiple frames before recovery at frame 186. Exact GXRuntime helpers now
  cover scalar-single arithmetic and all 1,237 `frsp` sites. The corrected
  exact-source PGO module then survived 402.7 seconds and 2,110 retained frames
  spanning Brinstar, several four-player scenes, and dense Peach combat without
  deformation. This satisfies the documented extended-matched-equivalent
  closure boundary. Evidence:
  `docs/artifacts/2026-08-25/g5-fountain-visual-warping.md` and
  `docs/artifacts/2026-08-25/g5-corrected-visual-closure-and-fountain-baseline.md`.
  A 2026-08-26 re-audit withdrew an incorrect reopening: the PGO acceptance
  roster intentionally contained two Bowsers and both real meshes were
  coherent; only Fountain's known reference-parity reflection was distorted.
  The profile-free Bowser/Ice Climbers screen agrees. This does not satisfy the
  real-mesh recurrence rule. Evidence:
  `docs/artifacts/2026-08-26/g5-cache-control-pgo-rejection.md`.
- **PERF-138/139/140 (task-event attribution):** The first per-CPU-slice
  task-event observer generated hundreds to thousands of Mach queries per
  frame and is excluded. Default-dormant patch 0022 now samples supported
  task event counts once per presented frame; standalone p95 query cost is
  about 0.71 microseconds. Fresh start/end images bound a continuous Final
  Destination combat interval, and its exact 2,001 rows measure 18.717375 ms
  p95 / 21.867375 ms worst. Misses average more wall-minus-thread time but
  fewer task context switches and fewer Mach/Unix syscalls, rejecting hidden
  whole-process blocking activity and strengthening host execution loss.
  This is diagnostic, not a G5 pass; G6 remains blocked. Evidence:
  `docs/artifacts/2026-08-28/g5-task-event-attribution.md`.
- **PERF-141 (Logitech updater isolation):** The explicitly authorized exact
  updater pause reduced the retained Final Destination window from 18.717 to
  17.195 ms p95, 19.466 to 17.365 ms p99, and 21.867 to 17.975 ms worst; all
  ten frames above 20 ms disappeared. Mean remained 16.683 ms and only 57.571%
  met 16.7 ms, so external load can aggravate severe stutter but is not the
  fundamental G5 limiter. The user directed that Logitech remain stopped, so
  no reversal or exclusive-causality claim is made. No product code changed;
  G5 remains open and G6 blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-logitech-updater-isolation.md`.
- **PERF-142/143/144 (stopped-updater Fountain and source attribution):**
  Fountain still averages 16.677958 ms but reaches only 52.424% compliance,
  17.542125 ms p95, and 34.499292 ms worst with Logitech stopped. Fresh visual
  endpoints show coherent Pikachu/Fox combat and no fighter-morph recurrence.
  A byte-identical line-table sample bounds the first unclosed generated family,
  `func_80339940`, at 106/2,031 active recompiler top-of-stack samples; its
  hottest resolved line has only three samples. Reject a focused local rewrite
  and require a shared operation with at least 5% projected coverage. No
  product code changed; G5 remains open and G6 blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-fountain-stopped-updater-and-symbolized-sample.md`.
- **PERF-145/146 (low-overhead Fountain pacing reversal):** Two current-PGO
  repeats with the detailed phase observer absent average 59.999944/59.999746
  FPS and improve to 16.780083/16.784000 ms p95 and 19.897333/19.996833 ms
  worst. The prior 34.499 ms phase-logged tail is not observer-free, but both
  runs still fail the strict 16.7 ms worst-frame gate. Each residual miss is
  followed by a compensating 13.4-13.5 ms interval, identifying delayed/catch-
  up presentation pacing rather than sustained guest under-speed. Coherent
  Pikachu/Fox endpoints show no mesh-warp recurrence. Fresh guest-cost
  attribution finds no unclosed local candidate above 5%. G5 remains open and
  G6 blocked; next observe actual drawable presentation cadence without
  changing scheduling. Evidence:
  `docs/artifacts/2026-08-29/g5-low-overhead-fountain-pacing-reversal.md`.
- **PERF-147/148 (current actual-presentation deferral):** Actual drawable
  callbacks without phase logging measure 16.666750/16.666792 ms p95 and
  16.666792/16.666833 ms p99, but repeat 33.333375/33.333500 ms worst intervals
  (three/two missed refreshes). All five requests were registered on time after
  normal 16.596-16.792 ms producer gaps and 3.955-5.745 ms drawable acquisition;
  no callback was dropped. Metal/macOS deferred an on-time present request by
  one refresh. The callback may perturb the run and was removed; historical
  actual-display evidence independently retains misses. Coherent Fountain
  endpoints show no mesh-warp recurrence. G5 remains open and G6 blocked;
  next distinguish GPU readiness from compositor deferral without changing
  scheduling. Evidence:
  `docs/artifacts/2026-08-29/g5-current-actual-presentation-deferral.md`.
- **PERF-149/150 (GPU readiness and display deferral):** A short 2,001-
  interval actual-display window passes at 16.666749 ms worst, but the sustained
  95.884-second Fountain combat boundary has nine 33.333 ms intervals and a
  33.333542 ms worst. Every missed frame was registered 12.397-32.797 ms early
  and GPU-complete 10.408-30.918 ms before the skipped refresh; GPU duration is
  only 1.565649 ms mean / 2.522875 ms worst. This rejects M1 GPU saturation and
  late rendering for the observed class and confirms compositor deferral of
  ready frames, consistent with the existing 59.94-to-fixed-60 conversion
  proof. The private observer was removed and canonical source rebuilt without
  its marker. No fighter-mesh recurrence was seen. G5 remains open and G6
  blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-gpu-readiness-and-display-deferral.md`.
- **PERF-151/152 (NTSC/display boundary and light producer split):** GALE01's
  exact VI rate is `60000/1001` or 16.683333 ms, while all current M1 panel
  modes are fixed 60.000000 Hz. PERF-127's observer-free 20-100 second window
  has six unselected surfaces against a five-hold conversion expectation, so
  unique-surface callbacks alone cannot classify D2 compute misses. A separate
  one-wall/one-thread-clock-per-present diagnostic retained 1,091 complete
  combat intervals before disk-full shutdown truncation. Thread CPU remained
  12.758 ms p95 / 14.735 ms worst with zero rows above 16.7 ms; its three
  >20 ms wall rows lost 5.686-12.657 ms off-core. This is mechanism-only,
  because disk pressure can aggravate scheduling. The observer is removed and
  canonical runner restored. G5 remains open on genuine producer-tail rows;
  G6 remains blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-ntsc-display-boundary-and-light-producer-tail.md`.
- **PERF-153/154 (quiet input-harness reversal):** An observer-free canonical
  Fountain control that streamed every controller step into Codex contained
  five 33 ms and one 30 ms gaps. Redirecting only `gcpipe.py` stdout to
  `/dev/null` removed every 30-33 ms gap and restored 16.666653 ms mean /
  60.000049 FPS. This is a measurement correction, not a product speedup:
  quiet p95 is 16.796250 ms and worst remains 22.544875 ms, with two isolated
  delayed/catch-up rows above 20 ms. Future perf input must be quiet. No
  unrelated application was stopped. G5 remains open and G6 blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-quiet-input-harness-reversal.md`.
- **PERF-165/167 (latency-QoS audit and complete Logitech isolation):** XNU
  labels `THREAD_LATENCY_QOS_POLICY` timer latency QoS and uses it to select
  timer-coalescing leeway; user-interactive QoS already selected tier 0 in the
  rejected prior reversal, so this is not a new runnable-CPU mechanism. With
  both the updater and Options+ agent stopped at 0% CPU, the valid quiet
  one-process Fountain window measures 16.675053 ms mean / 16.794959 ms p95 /
  16.838917 ms p99 / 33.249209 ms worst. Only 70.215% meet 16.7 ms. A separate
  framebuffer replay shows coherent Pikachu/Fox combat advancing from 1:48.24
  to 1:33.83 with no real-mesh warp; the known reflection distortion remains.
  No product change was made. G5 remains open, G6 blocked, and any unrelated
  background-load reversal still requires explicit reversible authorization.
  Evidence:
  `docs/artifacts/2026-08-29/g5-latency-qos-and-logitech-agent-isolation.md`.
- **PERF-173 (confirmed-Game-Mode Fountain window):** The exact refreshed PGO
  runner/module, fullscreen Metal/Cubeb, quiet 18-cycle input, one game, and no
  Simulator were gated on `Game mode status is now on` before Fountain state
  load. The exact final 2,001 rows average 16.666486 ms / 60.000651 FPS with no
  row above 20 ms, but p95 is 16.807334 ms and worst is 17.477083 ms; only
  69.165% meet 16.7 ms. Runtime shutdown recorded zero fallback and zero failed
  SMC verification. No fresh visual claim is attached, no product setting or
  source changed, G5 remains open, Final Destination and G6 remain blocked.
  Evidence:
  `docs/artifacts/2026-08-29/g5-confirmed-gamemode-fountain-window.md`.
- **PERF-174/175 (sustained pre-results window and rate-alignment rejection):**
  A hands-off confirmed-Game-Mode repeat places the deterministic match/results
  transition at absolute render row 6,784 in two runs. The clean final 2,001
  pre-transition combat rows average 59.999592 FPS with 16.785125 ms p95 and
  16.946375 ms worst; the wider 4,001-row combat window still contains four
  33 ms holds. A private exact 1001/1000 host-rate candidate retained 16.791291
  ms p95 and one 33.281208 ms hold. It was rejected and `Dolphin.ini` restored
  byte-for-byte. No product source changed; G5 remains open, Final Destination
  and G6 blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-sustained-pre-results-and-rate-alignment-rejection.md`.
- **PERF-176 (current render/vblank stall join):** A read-only join of the
  clean PERF-174 logs maps every post-boot pre-results render gap above 20 ms
  to a vblank stall at the exact same +172-row offset. Four 33 ms render rows
  pair with 33.969-34.979 ms vblank rows. The current residual class begins in
  the combined CPU-GPU/vblank host-execution path, not only the compositor.
  Existing supported scheduler routes are already causally rejected, and
  Apple's affinity tag is cache-locality guidance rather than P-core pinning;
  no no-op product patch was added. G5 remains open, Final Destination and G6
  blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-current-render-vblank-stall-join.md`.
- **PERF-177 (reference/shader/streaming rejection):** SunPad and current
  Slippi expose no distinct supported scheduler route beyond already-rejected
  QoS/dual-core/affinity mechanisms. The clean run changed no pipeline UID
  cache after its pre-run mtime; retained sampling gives shader compilation
  only 15/12,067 samples. SsbmPad boots a directory blob, so Dolphin's
  file-disc `LoadGameIntoMemory` wrapper is inert, and FastDisc already failed.
  No shader/DVD/affinity product experiment was justified or launched. G5
  remains open, Final Destination and G6 blocked. Evidence:
  `docs/artifacts/2026-08-29/g5-reference-shader-and-streaming-rejection.md`.
- **PERF-193 (default-dormant lightweight producer recorder):** Canonical
  patch 0023 reuses the existing render wall timestamp, reads one thread CPU
  clock only when explicitly enabled, buffers records in memory, and flushes
  once at shutdown. Its regression proves zero disabled clock calls/output.
  A corrected single-core cold Fountain match retains 7,431 combat intervals
  at 16.682591 ms mean / 59.942726 FPS, 16.840625 ms p95, and 39.496833 ms
  worst. All 104 combined-thread CPU overruns occur in the first ten seconds;
  after that CPU remains within 16.7 ms while separate 33.251625/20.855458 ms
  wall holds remain. All 22,240 wall records match the independent render log
  exactly. Release links, 26/26 scoped tests, nine classifier tests, and repo
  checks pass. G5 remains open, Final Destination and G6 remain blocked; next
  run a second Fountain match in the same process. Evidence:
  `docs/artifacts/2026-08-29/g5-lightweight-producer-recorder.md`.
- **PERF-194 (same-process Fountain warm-up reversal):** Two visually verified
  Fountain matches ran in one continuous single-core process. Cold match one
  has 105 combined-thread CPU overruns, 104 in its first ten seconds; warm
  match two has eight total, two in its first ten seconds. The same-process
  leg improves to 16.670874 ms mean / 59.984858 FPS, but still fails at
  16.863511 ms p95 and 29.475375 ms worst, with a separate 15.100374 ms wall-
  minus-thread tail. All 30,258 common recorder/render rows match exactly at
  the expected offset. Most cold compute work is one-time warm-up, but warm
  Fountain is not stable at strict 60 FPS. G5 remains open, Final Destination
  and G6 blocked; next join the eight warm CPU overruns to retained phase
  timing. Evidence:
  `docs/artifacts/2026-08-29/g5-same-process-fountain-warmup.md`.
