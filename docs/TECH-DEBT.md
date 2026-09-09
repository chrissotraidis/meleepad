# meleepad technical debt

Last updated: 2026-09-09

This is the short, ranked engineering queue behind the active goal loop. It is
not a substitute for `GOAL-LOOP.md` or evidence in `docs/artifacts/`.

Performance evidence: [v1.02 iPhone performance goal](IPHONE-102-PERFORMANCE-GOAL-LOOP.md).
Preview 4/build 18 rolls up the merged build-17 increment and lightweight
gameplay timing logs.
Sustained performance and physical netplay limitations remain open.

## Active decompilation investigation — after Preview 4

The [bounded decompilation loop](DECOMP-PERFORMANCE-GOAL-LOOP.md) now maps saved
native samples to exact source functions, using a debug rebuild whose machine
code matches the sampled module. Matrix concatenation and inverse-transpose
account for roughly 4.8–4.9% and 3.9–4.1% of CPU-thread samples respectively.
Splitting functions alone passed correctness checks but offered no useful
timing improvement and was rejected.

A guarded local-floating-point-state prototype is faster in isolated host
measurements and passes 79,000 full-module adversarial comparisons plus 300
comparisons sampled during confirmed local Classic combat. Source-defined
input guards admit over 99.99% of observed entries in the final local route.
This uses Null graphics for correctness and coverage, not device speed.
A physical A–B–A–B comparison then found lower candidate tail frame times,
but audio did not consistently improve, the repeated workload differed and
native profiling failed. Build 19 is not promoted; build 18 is restored on the
iPhone. No public release was made. See the linked loop for the complete table.

Next: log source-defined scene transitions independently of menu input steps,
identify the late jump to approximately 111,000 primitives per frame, and
profile an identical scene window. Distinguish combat from results before
claiming a four-fighter speedup. Preserve the reproducible matrix candidate
for that focused comparison; do not repeat broad optimization sweeps.

## Current performance investigation — private build 17

Build 17 adds a modest host-loop optimization:
normal execution compiles out disabled diagnostic branches, while timing,
lockstep, and diagnostic runs use the same fully instrumented loop. A physical
25-second four-fighter comparison reduces loop self samples from 1,683 to
980 ms (41.8%); total CPU-thread samples are 2.38% lower, with unchanged game
modules. This is a targeted improvement, not a precise FPS gain or a fix for
sustained heavy-match slowdowns. Patch 0056 makes the change reproducible.

The owner's latest gameplay logs confirm 41–45 FPS slowdown samples with
serious thermal pressure and CPU-thread utilization of 86–93%. The owner finds
it improved but still imperfect. Build 18 now logs frame-time p95/max, slow-frame counts and audio-underrun
deltas using existing frame timestamps. Next performance work should target a
flagged slow interval; always-on per-dispatch timing remains excluded. See the [owner-run assessment](artifacts/2026-09-08/build17-owner-gameplay.md).

Neither tested math candidate is retained. Deferred floating-point classification
substantially reduces isolated inverse-matrix time, but physical four-fighter
comparisons do not establish a consistent whole-game improvement. Trig changes
regressed; removing them and adding scalar matrix-add still failed the hardware
retention gate. The original module remains unchanged in private build 17.

The physical four-fighter route now supports v1.02 using verified decompilation
symbols and layouts. It reaches a fixed roster on Big Blue. Captures show strong
thermal sensitivity: a cooled baseline begins near 60 FPS and slows as it warms.
One cooled pair favored a candidate by about 4% CPU time, but differing starting
thermal states and subsequent contrary results prevent retaining that claim.

The owner reconnected the iPhone and two 25-second native Time Profiler
captures of the four-fighter route succeeded. With internal capture disabled,
CPU leaf samples split into 46.29% generated game bodies, 24.10% module helpers
and dispatch, and 29.58% core/system. The video worker spends substantial time
in FIFO/status polling; prior sleep-threshold experiments already regressed or
failed to exceed noise and should not be repeated without a different mechanism.

Internal diagnostic clock work accounts for 7.35% of CPU samples when capture
is enabled, versus 0.04% disabled. Keep internal capture off during native
profiling. The capture-disabled run still slowed to 47.5 FPS in one later
interval, so logging is not the whole issue. Next source gate: map matrix/joint
native sample offsets to exact decompilation functions before selecting a
bounded region optimization. See the [full evidence and current device
state](IPHONE-102-PERFORMANCE-GOAL-LOOP.md). That attribution led to the build-17 host-loop specialization above.
No new sustained FPS claim or physical online acceptance is established.

## Build 9 handoff — v1.02, performance, and hardware netplay

USA v1.02 is now preferred for new development setups; v1.00 remains supported
with its existing data and separate revision storage. Build 9 is not a published
release. See [version details](MELEE-VERSIONS.md) and
[the evidence ledger](REVISION-102-GOAL-LOOP.md).

**No measured performance improvement from this decompilation pass.** The
completed source is pinned and its symbols are checked against the executable.
It helped audit v1.02 idle/controller-wait addresses and gate legacy diagnostic
writes. It has not replaced generated game code with an optimized native source
port. Decompilation completion does not itself change the runtime's GPU, memory,
CPU dispatch, or thermal costs.

The current performance investigation and ranked candidates are recorded in
[the build-11 physical-iPhone report](artifacts/2026-09-08/iphone-heavy-scene-performance.md).
It supersedes the earlier generic hypothesis list: one short scene attribution,
one justified implementation candidate, then stop if inconclusive.

Netplay build 9 aligns desktop fallback execution with iOS and rejects older
protocol peers. Bounded Mac–Simulator timing/state and mixed-revision rejection
tests passed; they do not establish complete hardware or Internet matches.
The owner now requires all further netplay acceptance on the attached physical
iPad and iPhone, not multiple Simulators or Mac–Simulator sessions. The desktop
test was stopped before its results gate.

Remaining demonstration gate: same build 9 and verified v1.02 on both physical
devices; connect, exercise both players' controls, finish one match, compare
results, and start another without desync. Record device audio/input behavior
and whether the connection was LAN or Internet. A LAN result must not be posted
as proof of Internet play, matchmaking, or Slippi support. Until this passes,
describe online play as experimental; announce version support separately.

## Build 10 — visible revision and physical app identity

The owner reported severe iPhone lag and could not tell which Melee revision
was running. Device inventory exposed two apps: the regular MeleePad still had
build 6 on iPad and build 7 on iPhone, while Revision QA had build 9. The QA
containers had verified v1.02 extraction, but no retained ISO. Do not confuse
QA installation with updating the owner's regular app.

Build 10 puts the detected Melee version in the three-dot menu title, removes
recommendation text from the Game Data & Saves row, and shows the current game
and app build above all Online Play connection modes. Its version picker shows
current selection before recommendation guidance. Boot refreshes the menu after
rebasing and validating the game root, avoiding stale container paths.

The regular apps were updated in place under their existing legacy bundle
identity. Both device ISO read-backs match the verified source; both boot logs
confirm revision 2 and Melee-v1.02.iso exists=1. Old Melee GCI files and save
states were removed, and fresh v1.02 saves are used, as explicitly requested.
The stale retained-image filename restored by legacy preference migration was
also fixed: startup searches the selected revision folder when that path is
missing. The physical iPhone reaches the fresh-save prompt. Lag remains unresolved: neither a revision change nor ISO retention
is a measured speed fix. Next physical acceptance must identify the regular
app, build, game version, actual ISO boot, and gameplay scene before comparing
performance or diagnosing network delay.

## Build 11 — touch follow-up and resolution observation

The owner reports substantially better iPhone gameplay with regular build 10
and verified v1.02 ISO boot, with some later slowdowns. This is hands-on
feedback, not a controlled performance comparison. The earlier regular app
was build 7, so the observation cannot isolate revision, retained ISO, or a
single runtime change as its cause.

Resolution changes are taking effect: the physical log at 07:44:07 UTC reports
EFB 2560x2112 and renderScale=4; after return to 1x it reports 640x528. This
disproves a general claim that the setting does nothing internally. Visible
quality and the reported slowdown still need scene-specific interpretation;
textures and 2D artwork do not gain detail merely from higher EFB resolution.

Build 11 adapts KartPad's floating main stick: each touch sets a new center in
the pickup zone, artwork disappears on release, and cancellation/resize resets
input. Fixed C-stick remains unchanged. Layout editing exposes the resting
position. D-pad defaults hidden, with Controls → Show D-Pad to restore it.
Online Play receives a visual refresh without changing connection behavior.
Physical touch feel and multiplayer layout inspection are owner acceptance
items for the installed iPhone build; no Simulator netplay is requested.

## Build 11 — confirmed heavy-scene iPhone slowdown

The latest regular-iPhone log confirms verified v1.02, build 11. At 1× / 4:3,
the 08:01:26 UTC sample reports 9.9 FPS; the next three report 34.2, 37.8 and
43.2 FPS. Audio underruns rise from 43 to 368. CPU-thread utilization reaches
97.7–99.2% while video-thread CPU reaches 70.6–73.7%. Serious thermal state
persists throughout the run, including earlier 60 FPS samples. Later 60 FPS
samples may be in-game pause, so do not call them proven gameplay recovery.

No new speedup was implemented in this research pass. The ranked candidates
are connected animation/collision specialization with live native state,
precompiled common iOS vertex decoders, and shader warm-up/fallback work.
Individual matrix kernels were already investigated and their projected gain
was too small; do not repeat that work. New shader creation overlaps the worst
sample, but its time cost is unknown. Existing async shader/cache settings are
already enabled. See the [evidence and bounded implementation gate](artifacts/2026-09-08/iphone-heavy-scene-performance.md).

Do not advertise consistently smooth iPhone gameplay. Preserve experimental
online status until a physical iPad–iPhone match passes separately.

## Preview 1 accepted debt — physical-iPad thermal slowdown

Preview 1 is complete with this issue explicitly accepted as technical debt,
not closed. A 2026-09-03 physical-iPad run captured a sustained slowdown after
an approximately three-minute in-game pause and return to a heavy Classic-mode
battle. The ten-second reports fell through 51.0, 47.7, 46.2, 47.0, and 56.7
FPS while VPS matched the loss and emulation speed reached 0.776. Audio DMA
underruns increased from 5 to 138 during the same 50-second interval.

The device entered `serious` thermal state as the slowdown began. Aggregate app
CPU remained about 182–186%, led by the CPU and video threads, while resident
memory stayed near 503–507 MiB, Low Power Mode remained off, and no memory
warning, audio interruption, crash, or multi-minute iPadOS background event was
recorded. The evidence is consistent with a heavy scene exhausting CPU/video
headroom after sustained load and thermal pressure; it does not prove a single
stage-specific code defect.

Do not block Preview 1 on this issue. Future work should reproduce from a fresh
process and add bounded hitch telemetry: frame-time p95/p99/max, thresholded
hitch counts, in-game pause and scene-transition markers, and GPU/pipeline or
resource-upload timing. Keep diagnostics export enabled and request the same-run
log plus scene, settings, and device information from reporters. See
[`docs/artifacts/2026-09-03/preview1-physical-ipad-thermal-slowdown.md`](artifacts/2026-09-03/preview1-physical-ipad-thermal-slowdown.md).

## P0 — G8 row 7: prove the complete iPad route honestly at 60 FPS

### Current feasibility decision

Sixty-FPS gameplay is now demonstrably possible in the iPad Simulator on this
machine; it is no longer only a projection. The ordinary observer-free product
held every reported moving opening/attract interval above the written 59.0
FPS/VPS floor for about eight minutes, and the exact five-minute Fountain route
held 59.9-60.0 FPS/VPS after the caller-qualified controller-wait correction.
Those results also rule out the M1, Metal throughput, static recompilation as a
whole, and the 59.94 Hz guest cadence as unavoidable explanations for the old
20-36 FPS behavior.

The ordinary visible route has now directly retested the sticky 21.9 FPS
anchor. Its sustained 20-36 FPS behavior does not reproduce, but the anchor is
not cleared under the written acceptance protocol: three isolated recorded
reports fall below 59 FPS/VPS, and none of the automated matches lasts five
uninterrupted minutes before Samus loses four stocks. This is a residual
acceptance/tail gap, not evidence of a known remaining 40 FPS performance gap.

Use this decision boundary next:

1. run one human-controlled uninterrupted five-minute Samus versus level-1 CPU
   Kirby, Stock/04, 05:00, Fountain match with a short retained recording and
   same-run runtime log;
2. pass only if every moving phase remains at or above 59.0 FPS/VPS with no
   sustained underrun growth, corruption, or input failure; and
3. if a dip repeats visibly, profile only that exact interval. Reopen
   static-core architecture work only if the failure is on-core, CPU-heavy,
   sustained, and does not contain the already-corrected
   `80019550/801A4064` controller-wait motif.

Do not add another optimization merely to make progress. A passing ordinary
route closes the performance investigation; a failing route must identify the
next measured mechanism.

### Latest ordinary manual result

The first fully visible no-pipe setup now works end to end: the shipped overlay
sets Stock/04/05:00, P1 Samus, level-1 CPU Kirby, and Fountain, drives combat,
reaches results, returns to CSS, and survives background/resume with speaker
audio restored. Five exact Fountain attempts total more than eleven minutes of
visible combat and overwhelmingly report 59.8-60.0 FPS/VPS. This confirms that
the old sustained 20-36 FPS failure is reversed in the ordinary product.

Do not close row 7 yet. The long HEVC-observed window contains three isolated
sub-59 reports (49.4/51.0, 46.7/46.7, and 52.1/52.2 FPS/VPS), each recovering
on the next report, and UI automation lost all four Samus stocks before five
minutes in every attempt. The strict remaining gate is therefore one
human-controlled uninterrupted five-minute match plus classification of any
visible repeated dip. This is not justification for another broad static-core
rewrite: reopen architecture work only for a sustained, on-core, CPU-heavy
failure distinct from the corrected controller wait. See
`docs/artifacts/2026-09-01/g8-ordinary-manual-fountain-reality-route.md`.

Two follow-up exact-Fountain reversals isolate that tail from product
performance. With HEVC retained but Computer Use state/screenshot polling
absent, 69 combined reports and 29 full-work combat reports all remain at or
above 59.9 FPS/VPS. The longer held-shoulder run retains 3:19 of combat with
59.9 minimum FPS/VPS and only two additional underruns. HEVC alone and the
exact workload are therefore insufficient causes of PERF-283's three dips.
Treat them as observer-contingent unless a short-recorded human route repeats
one visibly; do not optimize the core for them. The remaining P0 is one
ordinary human-controlled uninterrupted five-minute exact match without
Computer Use polling during combat. See
`docs/artifacts/2026-09-01/g8-hevc-no-ui-observer-tail-reversal.md`.

### 1. Close acceptance after the controller-wait reversal

The primary iPad Simulator CPU collapse now has a measured cause and retained
product fix. A live 27.807 ms / 26.609 ms total/CPU interval spends about
434,000 native dispatches per frame in a deterministic raw-controller queue
wait. Melee repeatedly services callbacks while waiting for its periodic pad
alarm. This is host-busy waiting for emulated time, not Metal, fighter AI, DVD
throughput, generic M1 weakness, or a need to lower resolution.

Patch 0038 uses Dolphin's existing `CoreTiming::Idle()` only at the exact
caller-qualified boundary PC/LR `80019550/801A4064`. The LR guard matters
because the service routine is shared. The iOS GALE01 host enables the pair as
ordinary runtime configuration; there is no player-facing performance mode.

The same-sequence candidate/control reversal at emulated frames 7,500-9,500
reduces CPU-thread time 13.600 -> 9.529 ms (29.9%), native dispatches
380,751 -> 107,535 (71.8%), and charged busy-loop cycles 6.346M -> 3.116M
(50.9%) while maintaining target cadence and progressing visuals. The rebuilt
default product, with no diagnostic environment, measures 16.714 ms mean over
15,021 active rows, reports 59.6-60.2 FPS/VPS, and has no strict-slow cluster
longer than two frames. See
`docs/artifacts/2026-09-01/g8-caller-qualified-controller-wait-yield.md`.

The architecture question is therefore no longer the immediate P0. Do not
return to the phase-aliased five-region corpus, a broad resident-C rewrite,
compiler-flag sweeps, or host blame unless a fresh accepted product route
reproduces a different sustained CPU-heavy failure.

The remaining P0 is honest acceptance: run two complete fresh-process routes
and the unchanged-build manual five-minute Samus/CPU-Kirby Fountain route.
Retain moving opening, menus/CSS, load, active input, combat, results, return,
audio, lifecycle, coherent geometry, and 59.9-60.0 FPS/VPS. The current attract
soak proves the mechanism and target cadence, but does not substitute for the
manual control/results/lifecycle row.

The first post-yield exact route now clears the hardest parts: state-verified
Samus/level-1-Kirby Fountain, over five minutes of input, results, CSS return,
and background/resume all remain coherent at 59.9-60.0 FPS. Its final six
minutes contain zero CPU-heavy slow rows. One earlier ten-second interval still
reports 56.7 VPS because of isolated 136/391 ms off-core wall stalls with only
13/18 ms CPU time. Next repeat the ordinary product route without phase,
MemoryWatcher, or external-pipe observers. Do not tune the static core for this
single host-wait event unless it reproduces visibly. See
`docs/artifacts/2026-09-01/g8-first-post-yield-fountain-acceptance.md`.

The observer-free reality lane then runs about eight minutes through moving
opening/menu/attract content. All 49 reports remain above the written 59.0
floor: FPS/VPS minima are 59.4/59.5, minimum speed is 0.984, and five underruns
occur only in isolated transitions. The old sustained attract collapse and the
diagnostic route's 56.7-VPS stall do not reproduce. Opening/attract architecture
work is closed; the remaining P0 is the unchanged-build manual exact Fountain
route. See
`docs/artifacts/2026-09-01/g8-observer-free-opening-attract-reality-lane.md`.

After NET-293, PERF-285 repeats the ordinary single-app lane from a fresh
process with no UI observation until after termination. All 17 ten-second
reports hold 59.9-60.0 FPS/VPS, including the 146.7% aggregate-CPU high-work
interval; four isolated transition underruns do not grow afterward. The paired
netplay run's 39-41 FPS therefore does not justify reopening solo static-core
work. Preserve the unchanged Release and run the human five-minute acceptance
route. See
`docs/artifacts/2026-09-02/g8-post-netplay-ordinary-attract-reversal.md`.

PERF-287 closes the only post-PERF-285 sub-55 recurrence as an observer event.
The 54.2/54.3 row occurred on a two-draw workload immediately after a live
Computer Use assertion and alongside a Core Audio overload. A fresh
180-second no-observer control has no report below 59.7 FPS/VPS and holds
cadence at much higher CPU/video load. Do not modify the product or treat
generic host idle-service jetsam as causal; the matched control also contains
idle exits without slowdown. Keep Computer Use absent during the human route.
An induced third process confirms causality: one state read is followed by a
56.2/56.5 light-work report and three underruns, then immediate recovery. No
audio overload occurs in that induced window, separating the base observer
effect from the original overload amplification.
See `docs/artifacts/2026-09-02/g8-computer-use-audio-overload-reversal.md`.

### 2. Cold-transition and resume audio

Sustained visible Classic combat holds the DMA-underrun counter flat while
running 59.9-60.0 FPS/VPS. Load adds one isolated underrun; background/resume
adds five before another flat twenty-second interval. Preserve the current
120 ms buffer and adaptive 15-granule target. Attribute the cold-transition
producer loss before changing permanent latency; do not repeat the rejected
larger-reserve experiment.

### 3. Residual frame tails

The minute-long combat mean is the 59.94 Hz cadence, but p95/p99 remain
17.437/18.697 ms and one 71.070 ms wall outlier occurs. That outlier contains
only 11.870 ms of CPU-thread execution, no pipeline work, and no visible FPS
collapse. Repeat recorder-free and on hardware before changing the emulator.
Optimize only repeatable CPU-heavy clusters that produce visible/VPS loss; do
not chase compensated host-scheduler jitter while rendered cadence remains
59.9-60.0 FPS.

### 4. Bound and regression-test CPU/video separation

iOS now uses synchronized CPU/video threads with a 1,000,000-tick maximum
distance, about 2.06 ms of guest time. Preserve that explicit bound, its source
contract, and the runtime log token. Reject any increase that fails the same
cold control/candidate/control, changes deterministic results, increases
underruns, or revives the old FIFO/crash behavior. Unconstrained dual-core
remains closed.

### 5. Visual and duplicate-XFB regression coverage

The product correction is iOS-only
`GFX_HACK_SKIP_DUPLICATE_XFBS=false`. Default-off boundary counters proved the
control discarded 100 of 101 stable-identity XFB updates, while the candidate
presented advancing pixels. Preserve a focused source/config regression and
repeat one transition video after future Dolphin updates so upstream duplicate
detection changes cannot silently restore the freeze.

The blurred/blocky lower Fountain reflection is closed as official-Dolphin
reference parity. The separate real-mesh issue is closed by the retained
scalar-single/`frsp` correction and its 402.7-second, 2,110-frame corpus. Reopen
only on adjacent-frame evidence of actual fighter deformation; do not retry
EFB-to-RAM or non-deferred-copy controls for the reference reflection.

### 6. Physical-iPad water, reflection, and shadow corruption

The first 2026-09-03 physical iPad session adds a separate, serious rendering
report: water and reflected or shadowed areas can render incorrectly even while
solo play remains near 60 FPS and resolution scaling itself appears to work.
This is direct user observation, but the exact stage, camera, render scale, and
adjacent frames have not yet been captured together. It therefore reopens the
hardware water/reflection path without reclassifying the already-compared
blocky lower Fountain reflection as a new defect.

Handle this as its own rendering goal. Capture the exact scene at 1× and the
user's selected higher scale with a short local recording, screenshot marker,
and same-run diagnostic log. Compare physical iPad against official Dolphin
before changing EFB copies, framebuffer sampling, depth handling, projection,
or Metal shaders. Keep this defect separate from the confirmed 60 FPS result
and from fighter-geometry regressions.

## P1 — cold pipeline behavior

A structurally valid 446-entry pipeline UID cache reduced matched runtime
pipeline creation from 10 / 16.96 ms to 3 / 2.43 ms, but did not improve total
pacing, added a 99.7 ms CPU-heavy hitch, and did not remove the visible
transition freeze. Do not bundle a game-derived seed. Forced termination also
leaves partial UID files whose sizes fail Dolphin's 8 + N*579 validation; keep
cache-integrity/lifecycle cleanup on the queue after row 7.

## P1 — acceptance and physical-device promotion

After the mechanisms above pass, row 7 still requires two complete fresh-process
cold routes and one unchanged-build ordinary manual five-minute Fountain run,
with moving opening, menus, CSS, loading, combat, results, return, controls,
audio, lifecycle, and coherent rendering retained. Only then test a physical
iPad. Simulator success is not device or release proof.

## P2 — G9: turn dormant netplay infrastructure into Online Play

The 2026-09-01 re-audit concludes that friend-code online play is feasible in
about 25-44 focused engineer-days, with real-world NAT/determinism as the main
uncertainty. The iPhone/iPad app already links ENet/SFML and already publishes
touch/controller state through the GameCube pipe that netplay polls. Dolphin's
CC0 traversal server and eight-character room-code protocol are also present.

The unreleased iOS candidate now offers a real Internet Room path backed by
Dolphin's live public traversal service, with Direct IP retained for advanced
use. Both Mac/iPad Simulator host directions create/resolve codes and sustain
synchronized execution. This proves feasibility, not a finished beta: public
service support is not controlled by MeleePad, complete physical-device matches
and real outside-network NAT behavior remain unmeasured, and strict NAT may
still require relay or a narrower scope. Do not market the current form as
finished online multiplayer.

The first defect is now closed by canonical outer patches: the pre-fix
GameCube assertion failed with exit `19`, while the candidate passes explicit
GameCube capacity/assignment/count/disconnect/reconnect and every
`GCPadStatus` field without regressing the Wii path. NL0/NL1 are focused-test
passes, not gameplay proof.

The headless `NetplaySession` extraction passes repeated lifecycle tests and
compiles for macOS and the iPhone Simulator. NL3 now passes: isolated macOS
host/join endpoints completed a full Pikachu/Peach match with two-sided input,
matching results, coordinated return to both lobbies, clean exit, and unchanged
ordinary-save hashes and mtimes. The runner's missing GameCube build option,
Pipe connection lifetime, stale runtime finish, and memory-card destructor
write-through are closed in the durable patch stack.

NL4 is partially implemented. The three-dot menu opens a native UIKit Online
Play form and the iOS core links the headless session library. Visible iPad
evidence passes direct-IP Host, live player/ping/GC-slot/compatibility state,
Ready, Cancel, input neutralization, clean teardown, and fresh solo restart.
An isolated Mac also joins as GC 2, both endpoints become ready, and native
Start enables. Timebase telemetry identified an ISO-versus-extracted-DOL boot
mismatch; aligning every netplay peer on the selected DOL moves the failure
from frame 60 to frame 6,240. Single-core execution reproduces frame 6,240 and
is rejected. Rebuilding the Mac module from the same generated chunks as iPad
moves the failure to frame 7,440 but does not eliminate it. The first host setup
also takes roughly 14.5 seconds while solo runtime and UICommon ownership turn
over.

Execution fingerprints close the frame-120 lockstep theory: the sampling hook
runs at unlike native-dispatch boundaries, and `0x803210A4` clears under full
charged-interval replay. Symmetric main/caller idle policy reduces the first
periodic gap to 9 ticks. A same-PC-only 2,048-tick bound filters that measured
boundary jitter but still rejects the real different-PC divergence at frames
6,180/6,240. The first remaining NL4 debt is therefore the full-load iPad CPU
slowdown around that transition, followed by a complete cross-platform match.
The match-ended callback visibly reopens the native lobby with the exact error,
and retained telemetry is capped to the two mismatch records relevant to
Dolphin's stop decision. Remaining product debt is Mac-host/mobile-join, every
exact failure family, host/client loss, background teardown, repeated
open/cancel, iPhone interaction/layout, and a decision on whether the
initialization delay needs a warmer boundary.
The product staging above is superseded by
`docs/NETPLAY-BETA-GOAL-LOOP.md`. The direct-address form is a Preview, not the
beta. B1 first requires a canonical same-boundary CPU/RAM comparison and two
complete Mac/iPad direct matches. B2 closes lifecycle/error resilience. B3
then integrates the pinned traversal client/server as a local room-code
vertical slice, and B4 replaces the engineering form with the complete native
Host a Game / Join a Game / room lobby flow. Operated service, physical-device,
NAT, security/privacy, and release gates follow without deferring their product
contracts.

Do not select a static semantic fix from the current different-live-PC record
alone. `SendTimeBase()` runs from the CPU-thread Pixel Engine finish event, not
the Video Interface field callback, and the fingerprint reads the live static
guest at a native dispatch boundary. First create a
canonical boundary record and prove whether CPU state or selected RAM actually
diverges. The comparator must still reject deliberately injected mismatch
families; no tolerance may hide a real error.

The canonical-boundary candidate in patches 0044/0018 now matches exact CPU,
FPR, paired-single, timebase, and sampled-MEM1 state in live two-Mac Fountain
combat. The initial absence of records was a stale test-package GameSettings
copy, not a comparator failure; the package-layout test now requires the
current main idle PC and caller-qualified PC/LR. Do not promote the diagnostic
candidate yet: two consecutive five-minute Mac/iPad matches, results, rematch,
and both host directions remain open. If cross-platform records differ, use
the named component rather than restoring live-PC tolerance.

The current iPad-host/Mac-join candidate does differ at canonical sequence
6780/frame 120, but only in emulated timebase and the sparse MEM1 digest; PC,
integer, FPR, paired-single/FPSCR, and combined CPU hashes match. Patches
0019/0045 preserve that classification in the native error instead of losing
it behind the generic desync message. The RAM hash is still aggregate and
cannot distinguish gameplay state from presentation/audio or nondeterministic
scratch memory. Add bounded hierarchical MEM1 hashes and a signed timebase
delta next; exclude a range only after the hierarchy proves it is irrelevant.

The same-M1 two-process NL3 run was commonly 12-21 FPS during final combat;
zero network wait separates that host-emulation contention from network delay.
The latest cross-platform fingerprint run showed roughly 39–41 FPS on the iPad
overlay around the real frame-6,180 divergence, so it does not clear the 60 FPS
gate either.
NL3 correctness does not clear G8 row 7 or prove 60 FPS netplay. Room-code
friend play remains the first release; public matchmaking and Slippi rollback
remain separate multi-month projects. See `docs/NETPLAY-FEASIBILITY.md` and
`docs/artifacts/2026-09-02/g9-two-mac-melee-match-pass.md`.

## Closed in Preview 3 — unified problem reporting

**Report a Problem…** now creates the privacy-bounded diagnostic first, lets the
player review or save it, and then offers the prefilled GitHub issue. The UI
makes the required manual attachment step explicit because an issue URL cannot
attach a local file. Nothing is uploaded automatically, and the existing
exclusions for game images, extracted data, saves, signing material, controller
input, room codes, chat, and addresses remain enforced.

## Closed directions — do not repeat without new evidence

- lowering emulated CPU clock or exposing a performance mode;
- generic M1/thermal/resource exhaustion;
- FastDisc or file preload;
- shader/pipeline seeding as the general freeze fix;
- QoS, affinity, Game Mode, activity hints, or timer variants;
- broad ThinLTO/PGO/code-size changes without an exact binary preflight;
- interrupt-leaf/direct-call/guest-PC-store rewrites already below the five
  percent gate or live-regressed; and
- hiding failures by averaging phases, lowering resolution, or changing the
  FPS counter.
