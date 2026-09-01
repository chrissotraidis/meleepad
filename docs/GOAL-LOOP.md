# ssbmpad goal-based loop

Operating loop for the autonomous build of ssbmpad. The requirements live in `docs/PRD.md`; this document is how you run. Written 24 Aug 2026.

## The goal stack

Work the lowest unmet goal. A goal is met only when its evidence exists in `docs/` per PRD Section 11. Never work a higher goal while a lower one is broken (a regression reopens the lower goal).

- **G0. Environment ready.** Toolchain verified, ROM identified and hashed, `ref/sunpad` docs read, core repos cloned and pinned into `ref/`.
- **G1. SMC pass recorded.** DolRecomp suspicious-instruction output for `main.dol` captured and interpreted; patch list (possibly empty) written down.
- **G2. Module recompiles and links.** ModernGekko-Template pipeline produces a Melee module on macOS.
- **G3. macOS boots to title.** Renders, accepts input.
- **G4. macOS playable.** CSS → 1v1 completes with audio. (PRD D1)
- **G5. macOS 60 fps.** Worst-case ≤ 16.7 ms incl audio on Final Destination and Fountain of Dreams. (PRD D2)
- **G6. Simulator core boots.** iPad Simulator, then iPhone Simulator, boot to gameplay with the no-JIT/interpreter/software-vertex-loader configuration. (PRD D3)
- **G7. Shell ported.** SunPad touch overlay + menu + diagnostics + settings running as ssbmpad in the iPad Simulator, driving gameplay. (PRD D4)
- **G8. Test matrix green.** All 15 rows in PRD Section 10, with evidence. (PRD D5, D6)
- **G9. Netplay working.** The ssbmpad shell exposes Host and Join; two isolated instances complete a synchronized match without desync, with at least one endpoint running iPadOS. Retain connection, gameplay, completion, and diagnostic evidence. A macOS-only connection smoke test does not meet this goal.

G5 is a hard requirement. There is no fallback title, no reduced-fps acceptance. If you are stuck on G5, the loop below still applies: measure, research, change one thing, re-measure.

### Current hard stop: G8 row 7

The installed iPad Simulator product is **not currently playable** on the
controlling route and is **not eligible for physical-iPad promotion**. The
authoritative floor is the user's ordinary first-run, on-screen 21.9 FPS result
in P1 Samus versus level-1 CPU Kirby, Stock/04/05:00, on Fountain of Dreams.
Later automated runs at 45.2, 36.4, or any higher diagnostic value do not
replace that result. Animated opening/menu slowdowns also fail independently.

Until this hard stop is cleared, the loop order is:

1. run the **reality lane** first: terminate the prior process, use the normal
   installed app and product defaults, leave savestates, private pipe input,
   diagnostic environment variables, and profilers off, then retain one
   continuous recording from the first moving frame through the first combat
   minute. A warm relaunch or an already-running match is not a cold result;
2. retain opening/attract, menu, CSS, loading, and exact Samus/level-1-CPU-
   Kirby Stock/04/05:00 Fountain combat as separate phases. For each phase,
   record visible minimum FPS, runtime minimum FPS/VPS and speed, p95/p99 frame
   time when available, the longest continuous sub-59 interval, and the audio
   underrun delta. Use the worse synchronized value;
3. use the **mechanism lane** only to explain that failure: reproduce the exact
   route with guest-state feedback and measure one narrower cause inside the
   slow phase. Automation, private input, counters, profiles, and warm runs can
   reject or rank mechanisms, but cannot qualify the product;
4. make no product build change unless that evidence predicts a falsifiable
   improvement of at least five percent without weakening exception, fallback,
   SMC, input, rendering, lifecycle, audio, diagnostic, or future-netplay
   correctness;
5. reverse control/candidate/control on the same route. A low-risk partial
   candidate may remain for composition only when its tail improvement repeats
   and it introduces no semantic, underrun, visual, input, or lifecycle
   regression. It cannot pass row 7, trigger full acceptance, or supersede the
   ordinary product floor while any phase remains below 59 FPS/VPS;
6. only after two complete fresh-process cold routes and the unchanged-build
   ordinary manual route meet the protocol below may physical-device testing
   begin.

### Row-7 truth and acceptance protocol

Use this evidence order for every performance claim:

1. an ordinary on-screen installed-app run;
2. synchronized runtime FPS, VPS, speed, DMA, and callback evidence from that
   same run;
3. automated exact-route reversals;
4. focused profiles, counters, microbenchmarks, and binary-size preflights.

Lower-ranked evidence may explain or reject a mechanism, but it cannot raise a
failed higher-ranked result. The user's visible **21.9 FPS** first-run frame and
its matching **20.2 FPS / 19.8 VPS** runtime interval therefore form a sticky
regression anchor, not an outlier to average away. This anchor is cleared only
by a newer ordinary manual run of the same installed candidate and exact route
that records the complete moving path—not by a warm scene, attract/demo
playback, idle screen, easier roster, average, best interval, or profiler-only
capture. If the normal first run is slow while a scripted warm run is fast, the
product still fails and the discrepancy itself becomes the next mechanism to
explain.

Judge these phases independently: moving opening/attract content, menu and CSS,
match loading, the first combat minute, continued five-minute combat, results,
and return to menu. Any moving phase below 59.0 FPS, any emulation phase below
59.0 VPS, p95 or p99 frame time above 16.7 ms, sustained speed below real time,
sustained/new audio underruns, lost callbacks, visual corruption, or input
failure fails the whole route. Report the minimum and tail, not just the mean;
do not average a failed phase or visible stutter into a later 60 FPS screen.

A candidate can change row 7 from FAIL only after all of the following pass:

- the measured mechanism and semantic regressions;
- same-build control/candidate/control on the exact route with no failed phase;
- two complete fresh-process cold routes, retaining every interval;
- one unchanged-build ordinary manual five-minute Fountain run with visible
  recording, responsive controls, coherent rendering, music and SFX, and no
  sustained underrun.

Until then, describe the app as an optimization build that boots and runs but
is not currently playable at target speed. Do not call it stable 60 FPS,
nearly ready, physical-iPad-ready, or promoted. G9 netplay remains queued
behind this gate.

The address-translation/discarded-instruction split, guest-PC-store preflight,
and exact-route one-in-4,096 dispatch distribution are complete. TLB/branch
events are too small and distributed to explain the 21.9-to-60 FPS gap alone.
Removing all surviving PC stores looks material in static mini-links but is
semantically unsafe; the safe subset is only 3.77%, below the five-percent
build gate, and the earlier broader live candidate regressed. The corrected
route reaches the exact match but only 49.1 and 41.6 FPS with visible geometry
distortion. A matched long-minus-short combat distribution accounts for 63,775
samples, but no PC exceeds 5.49% and no 16 KiB region exceeds 13.14%; the top
families are the already-rejected interrupt, DVD/timing, and HSD/GX/matrix
paths. That rejects another guest-region specialization before a build.

PERF-256 completes that host-side profile and the first bounded host-loop
candidate. Cold first-combat samples put `StaticRecompCore::Run` self plus the
disabled lockstep check at 8.164% of the CPU-GPU thread, clearing the structural
screen. Patch 0030 caches loop invariants and makes dispatch/freeze diagnostics
default-off while preserving explicit gates. In an A/C/A exact-route reversal,
the candidate repeats a two-second bad tail instead of the control's five and
raises the minimum from 11.7 to 20.2-21.1 FPS, but mean gain is only 3.5-3.7%
and both candidates still collapse to roughly 20 FPS. Retain it only as a
partial building block; row 7 remains a hard fail.

The immediate active step is now a frame-aligned outer-boundary attribution of
that repeatable cold transition spike. Begin with the reality lane, then on a
separate exact diagnostic run correlate total/CPU/present time with native
dispatches, draw/primitive deltas, shader/pipeline creation, and DMA underruns.
Build only when one aligned mechanism predicts at least five percent removable
time. Do not assume shader prewarming is sufficient: compiler workers were
concurrent, but the CPU-GPU thread did not materially block on them. Do not
reopen interrupt-leaf coalescing, fast-disc/DVD shortcuts, direct HSD/GX calls,
matrix-copy specialization, narrow `mtspr`, dual-core FIFO, buffer growth,
vertex-loader work, stale PGO, or footprint-only generated-code variants. See
`docs/artifacts/2026-09-01/g8-r0-cold-host-profile-and-loop-hoist-reversal.md`.

DECISION-215 originally recorded a user-authorized sequencing exception after
PERF-214. On 30 Aug 2026 the user explicitly broadened that direction: assume
the unavailable external-display check passes and repeat it later once the
iPadOS/iOS version is ready. G5 and G8 row 3 are therefore provisionally
accepted for loop progression by user waiver. This is not an empirical
external-display result; a later failed 59.94 Hz/VRR hardware run reopens both
gates. Proceed with exactly one Simulator at a time. See
`docs/artifacts/2026-08-30/g5-external-display-user-acceptance.md`.

MOBILE-216 passes G6. One-at-a-time iPad Pro 13-inch (M5) and iPhone
17 Pro Simulators on iOS 26.5 both booted the same arm64 IOSSIMULATOR app and
ahead-of-time GALE01 module into live Classic-mode combat. Actual on-screen
stick/A/X/Start input drove menu selection, fighter selection, movement,
jump, attack, and match start. This proves the no-JIT Simulator core path, not
real-device performance: static screens often reported 59.9-60.0 FPS while
shader-heavy transitions and combat slowed materially. G7 is now active; G5's
external-display verification is provisionally accepted under the later user
waiver described above. See
`docs/artifacts/2026-08-30/g6-ios-simulator-core-and-gameplay.md`.

SHELL-217 passes G7 on the iPad Simulator. The live three-dot menu changed
render scale and aspect, toggled the FPS label, opened controller mapping and
game-data actions, edited and reset the touch layout, and generated a
diagnostic share file. The first export exposed a dev-only absolute game-root
path; the retained fix now sanitizes boot breadcrumbs, redacts host path tokens
again at export, and has a focused regression. The rebuilt export had zero
path/game-image leak matches. All new shell regressions and the full repository
gate pass. G8 is now active; import, every-control, two-controller, save, and
the remaining matrix rows are not promoted by this decision. See
`docs/artifacts/2026-08-30/g7-shell-parity-and-diagnostics.md`.

MATRIX-218 reconciles G8 without replaying or overclaiming prior evidence.
Rows 1 (boot), 2 (menu navigation), 4 (Fountain 1v1/profile), and 14
(regression suite) pass. Rows 5, 7, 9, 10, 11, and 12 are partial; rows 6, 8,
13, and 15 are open. Row 3 was subsequently provisionally accepted by explicit
user waiver because the required display is unavailable. Close the remaining
one-Simulator iPad cluster first, then the
missing non-display macOS rows and clean-clone build. See
`docs/artifacts/2026-08-30/g8-test-matrix-reconciliation.md`.

IMPORT-219 passes G8 row 13. A real iPad Simulator import first exposed stale
Sunshine SHA/file-layout checks. After replacing them with the pinned GALE01
revision-0 hash, 1,209-file count, and Melee anchors, the app validated,
copied, extracted, atomically activated, and visibly booted the user's image.
Normal sandbox relaunch and same-filename reimport from the Files-visible
SsbmPad folder also passed. Retain the private active import for the remaining
save/control rows; do not commit it. See
`docs/artifacts/2026-08-30/g8-ipad-game-data-import.md`.

AUDIO-220 closes the G8 row-7 attribution question without claiming a pass.
Read-only iPad diagnostics prove that RemoteIO output callbacks survive, but
four-character combat at 37-40 FPS starves the mixer DMA queue: underruns rise
from 99 to 258 in 30 seconds while the CPU-GPU thread remains about 99%. A
larger 160 ms reserve only delays the failure and was reverted. A 10-second
sample places the dominant cost in `StaticRecompCore::Run` and generated
`chassis_dispatch`; vertex loading is below two percent of CPU-GPU samples.
The retained macOS PGO profile fails strict current-source compatibility, and
a disposable partial-profile candidate still falls to 39.9 FPS while
underruns reach 506, so it is rejected. Row 7 is now fail/attributed, not
partial/unmeasured. Next generate a fresh combat-representative profile for
the exact current source or name a new measured generated-dispatch cost; do
not retry buffer growth, stale PGO, or vertex-loader work. See
`docs/artifacts/2026-08-30/g8-ipad-audio-and-combat-attribution.md`.

PERF-221 proves that exact-source iOS frontend PGO is viable and directionally
useful, while rejecting it as a complete row-7 fix. A private instrumented
module captured the built-in four-character combat class through the existing
supported reset/dump hooks. Its 6,537-function profile passes a strict
`profile-instr-out-of-date` build across all 237 generated chunks. The exact
candidate generally improves demanding demo scenes from the 37-40 FPS control
to roughly 42-48 FPS, but CPU-GPU remains 91-100% and mixer underruns still
accumulate. A residual sample keeps 3,758/6,531 CPU-GPU samples in the
inclusive static-core branch and 3,214 under generated `chassis_dispatch`;
vertex loading remains only about 2.6%. Retain the private candidate as the
comparison floor, not as a pass or repository dependency. Next address a new
measured residual shared dispatch/static-core cost and reverse against both
control and fresh PGO on a fixed match path. See
`docs/artifacts/2026-08-30/g8-ipad-audio-and-combat-attribution.md`.

PERF-222 rejects iOS host-core ThinLTO before another live replay. An isolated
exact-toolchain build emitted LLVM bitcode and linked it into a disposable
app, but the resulting `StaticRecompCore::Run` still calls
`FastDispatchableAt`, `SyncIn`, and `SyncOut`. The function instead grew from
692 to 1,327 instructions, direct calls rose from 59 to 61, and the app binary
grew by 94,224 bytes. The measured boundary-removal mechanism did not occur,
so do not promote or repeat this route. Row 7 remains fail/attributed; continue
only from a new measured static-core path that clears a structural/materiality
gate before live play. See
`docs/artifacts/2026-08-30/g8-ios-host-core-thinlto-rejection.md`.

SAVE-223 passes G8 row 8. Live Melee name entry created `CODX` on the iPad
Simulator and `CODM` on macOS; both names were visibly present after normal
termination and fresh-process relaunch. SsbmPad's FPS setting was also read
back after relaunch on both platforms. The iPad preference was restored to its
prior off state after proof. No ROM, module, save, or preference file is
committed, and the sole Simulator is shut down. Continue with the remaining
G8 rows; this does not promote audio continuity, combat performance, or
netplay. See
`docs/artifacts/2026-08-30/g8-save-and-settings-persistence.md`.

CLEAN-224 passes G8 row 15. A fresh checkout first exposed that canonical
Dolphin patch 0017 expected pre-iOS-guard Metal context and therefore failed
after the pinned SunPad patch. The retained context-only repair nests the
existing forced macOS display-sync policy inside SunPad's availability guard.
The corrected clean tree then cloned every pin, extracted the exact private
GALE01 image, regenerated all 237 chunks, linked the module, built and signed
the arm64 macOS app, and passed bootstrap, package-layout, signature, and full
repository gates. Private game and generated output remain untracked. Continue
with the remaining interaction/performance rows; reproducible construction is
not gameplay proof. See
`docs/artifacts/2026-08-30/g8-clean-clone-build.md`.

POLISH-225 retains a ROM-safe public README, a SsbmPad-specific app icon, and
the requested compact R shoulder. The new icon uses an abstract charcoal,
silver-white, crimson, and restrained-blue arena-impact motif with no
controller, text, characters, or copied logo. R now uses the same standard
button class and default width as L and emits matching digital-plus-255/0
trigger semantics. A focused regression, fresh Release build, and live iPad
Simulator visual check pass. This advances G8 row 9 but does not close its
remaining every-control live-play requirement. See
`docs/artifacts/2026-08-30/g8-public-presentation-and-compact-r.md`.

PERF-226 rejects exact-profile iOS `-O3` before live replay. Against the same
current-source combat profile and ThinLTO configuration, O3 grows `__text` by
16,580 bytes, leaves `chassis_dispatch` unchanged, and grows all four sampled
hot generated-function spans by 0.011-0.184%. That does not approach the
predeclared five-percent materiality gate. Keep the exact PGO O2 module as the
private comparison floor and require a newly measured residual mechanism
before another performance replay. See
`docs/artifacts/2026-08-30/g8-ios-exact-pgo-o3-rejection.md`.

DIAG-227 passes G8 row 12. The macOS launcher now exposes a privacy-bounded
Export Diagnostics action and a matching automation route through the same
exporter. The rebuilt binary produced a report from the real runner log with
static-recompiler, audio, controller, and lifecycle breadcrumbs; a scan found
no absolute private paths, game/extraction paths, disc-image names, or save
files. Combined with the retained iPad export, both required platforms pass.
See `docs/artifacts/2026-08-30/g8-macos-diagnostics-export.md`.

BATTLE-228 passes G8 row 5 without hiding its severe performance result. A
MemoryWatcher-gated macOS run explicitly configured P1 Pikachu plus three
level-1 CPUs, selected the literal Battlefield tile, showed an item in live
combat, and reached the natural two-minute Time Battle results screen without
a crash. The retained 11,766-interval bracket spans 198.890 host seconds for a
120-second game timer: presentation remains near 59.94 after two capture-scale
pauses are separated, but effective game progress is only about 36.2 FPS. Row
5 permits an honest target miss, so completion passes while the row-7/static-
core producer deficit remains open. See
`docs/artifacts/2026-08-30/g8-macos-battlefield-four-player-item-match.md`.

KEYBOARD-229 repairs the macOS interactive-launch path. The shipped WASD
profile existed, but prior automation had persisted both controller selectors
as `Pipe/0/ssbmpad`, and the wrapper preserved that internal profile forever.
The wrapper now migrates only SsbmPad's exact pipe transport to the Quartz
keyboard profile in both files, preserves custom keyboard/SDL profiles, and
adds Space as an X/jump binding. Focused migration/package regressions and the
full repository gate pass; the real launcher visibly reports the Quartz
profile. Computer Use taps do not enter Quartz's held-key API, so final
physical-key gameplay confirmation remains pending and is not overclaimed. See
`docs/artifacts/2026-08-30/macos-default-keyboard-controls.md`.

CLASSIC-230 passes G8 row 6. A corrected live player-table address derived
from the generated GALE01 code, plus newly supported MemoryWatcher pointer
chains, exposed fighter object pointers and exact percent values during a
macOS Classic run. The values matched the screen (Samus 60 -> 74 percent and
Pikachu 28 percent). From the retained checkpoint, Pikachu naturally cleared
Brinstar, cleared the following three-opponent team battle after one failed
attempt and retry, completed the target bonus stage by timeout, and advanced
into the Bowser fight. The title remained 59.9-60.0 FPS throughout the retained
screens. This proves no three-stage progression blocker; it does not close the
separately tracked geometry/character-warping defect. See
`docs/artifacts/2026-08-30/g8-macos-classic-three-stage-progression.md`.

PERF-231 retains iOS host-runtime PGO as a material row-7 direction. The fresh
iPad sample exposes 14.48% host-only opportunity, unlike the already-rejected
2.68% macOS bound. A strict profile-use build materially shrank the measured
runtime helpers and lifted heavy scenes with the unchanged non-PGO module into
the 59.0-59.9 FPS range; a later shader-heavy scene still fell to 54.5 FPS and
DMA underruns accumulated. Row 7 remains open. Next combine this private host
profile with the retained exact-source game-module PGO on a fixed path. See
`docs/artifacts/2026-08-30/g8-ios-host-runtime-pgo-direction.md`.

PERF-232 completes that combined reversal without closing row 7. A fresh dense
exact-source profile was selectively applied to all 237 generated chunks and
observed module helpers while three unobserved interpreter fallback files stayed
normally optimized. The combined host+module-PGO candidate sustained long
59.8-60.0 FPS combat intervals, but cold shader/resource creation still produced
32-54 FPS windows and raised DMA underruns; a warmed repeat still contained a
36.5 presentation-FPS transition and a 59.2 FPS heavy interval. A warmed sample
keeps 69.7% of CPU-GPU samples under `StaticRecompCore::Run` and 60.9% below
`chassis_dispatch`. Next isolate a Metal pipeline/resource persistence or
prewarm mechanism, then return to the residual generated-dispatch ceiling. See
`docs/artifacts/2026-08-30/g8-ios-combined-pgo-reversal.md`.

PERF-214 reconciles every current G5 failure class against the retained
mechanism history. Warm CPU overruns are rare and distributed across already
closed/profiled families; the largest Fountain tails are proven
`nextDrawable` waits; warm Final Destination is wall/vblank-bound with CPU
inside budget; and GPU-complete frames are still deferred by the built-in
fixed 60.00 Hz panel converting Melee's 59.94005994 Hz distinct source. The
current Mac exposes no 59.94 or variable-refresh mode, and every public
product-local compiler, renderer, scheduler, audio, input, and vertex-loader
lever has a direct semantic, API, reversal, or materiality rejection. Further
G5 work now requires a real 59.94 Hz or suitable VRR macOS display (necessary,
not sufficient), or genuinely new causal evidence naming an uncovered public
mechanism. Do not weaken D2, count stale duplicates, use private driver APIs,
or treat G5 as proven. Its earlier G6 prohibition is superseded only by the
explicit DECISION-215 sequencing exception above. See
`docs/artifacts/2026-08-30/g5-remaining-mechanism-and-capability-boundary.md`.

PERF-213 rejects generated-module frame-pointer omission before a full build.
On a retained hot PGO chunk, `-fomit-frame-pointer` keeps the x29/LR save pair
and removes essentially one frame-establishment instruction per generated
function: 434 fewer instructions across 446 `func_` symbols. PERF-212's direct
same-machine result bounds that at about 0.0044 ms/frame for 116,775
dispatches, far below the 5% product-build gate. Do not build or retest this
flag without a source-level mechanism that materially changes register
pressure. The product was unchanged, G5 remains open, and G6 blocked. See
`docs/artifacts/2026-08-30/g5-generated-frame-pointer-omission-rejection.md`.

PERF-212 closes the ARM64 dispatcher calling-convention and cold-frame-split
routes. The optimized runner emits no per-dispatch spills around its indirect
module call, so `preserve_most` has no caller traffic to remove and would push
extra preservation into the callee. Splitting the proven-zero-hit host/alias
paths does remove the dispatcher's x19/x20 save pair while preserving all
tested branch semantics, but a five-million-call reversal saves only 0.190 ns
per call (0.385%), projecting 0.022 ms at 116,775 dispatches/frame. Do not add
a custom ABI or repeat the cold-path split. The product was unchanged, G5
remains open, and G6 blocked. See
`docs/artifacts/2026-08-30/g5-dispatch-frame-split-rejection.md`.

PERF-211 rechecks LLVM sample PGO only because PERF-206 added native-PC data.
The installed Xcode lacks `llvm-profgen`, the shipped module has neither DWARF
line data nor pseudo probes, and the ring contains PC snapshots rather than
branch/context trace. A symbol-only profile would be strictly weaker than the
retained frontend profile's exact entries, blocks, and branch weights. Do not
synthesize it, rebuild with probes, or install a second profiling toolchain.
G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-native-pc-sample-pgo-screen.md`.

PERF-210 proves that fixed scheduling plus requested user-interactive QoS is
not a supported untested combination. Public fixed policy immediately clears
requested QoS; reapplication fails with `EPERM` and readback stays fixed plus
unspecified QoS. Timeshare restoration succeeds. Fixed alone already failed
PERF-191's reversal, so do not rerun it, add a combined mode, or use private
policy interfaces. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-fixed-plus-qos-contract-rejection.md`.

PERF-209 closes the Apple-recommended drawable-lifecycle route. The current
backend performs independent presenter work before acquisition, scopes
drawable references with autorelease pools, and clears its sole retained
drawable through the existing scheduled handler. A real host layer is already
opaque, RGB `BGRA8Unorm`, and framebuffer-only; the retained product is
fullscreen, satisfying Apple's direct-to-display prerequisites. A materially
later acquisition needs the already-rejected offscreen/reserve architecture.
Do not add opacity, retain, framebuffer, or preferred-latency no-ops. G5
remains open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-apple-drawable-lifecycle-audit.md`.

PERF-208 closes the installed macOS 26.5 drawable-API escape route without a
product build. A real host layer already uses framebuffer-only textures, the
maximum supported three drawables, asynchronous updates, display sync, and a
finite timeout. The ordinary Metal queue's 64-command-buffer allowance is not
the three-drawable bottleneck. Metal 4 still consumes the same acquired
`MTLDrawable`; its explicit wait/signal calls add ordering, not capacity or a
new distinct source frame. Do not build command-count, timeout, transaction,
or Metal-4 migration variants from PERF-207. G5 remains open and G6 blocked.
See `docs/artifacts/2026-08-30/g5-current-metal-drawable-api-screen.md`.

PERF-207 adds a bounded four-frame unwind to the development-only external
sampler and resolves the unexplained warm wall wait exactly. A same-process
second Fountain match retains 52,906 error-free samples; 31/32 timed-semaphore
samples inside six wall tails share the libdispatch -> QuartzCore ->
`-[CAMetalLayer nextDrawable]` chain. The phase logger's Metal values describe
the current present while `total_ms` ends at that present's start, so the
correct one-row join maps the three 31.5-34.7 ms tails to prior 16.9-21.8 ms
drawable waits. Do not misclassify this as throttle/FIFO/idle residency or
reopen already-rejected pool-depth, Rush, direct/absolute presentation, or
reserve-frame changes. Retain the external tools only; the diagnostic is
observer-bearing, G5 remains open, and G6 remains blocked. See
`docs/artifacts/2026-08-30/g5-warm-wall-stack-attribution.md`.

PERF-206 extends the repaired sampler behind an explicit development-only
native-PC mode. A complete 120-second same-process warm Fountain ring retains
78,744 error-free samples, and a tested start-to-start analyzer joins 48 of
them to four exact active-combat CPU overruns versus 73,871 body samples.
`StaticRecompCore::Run` rises 2.99x, but the remaining signal is distributed
across already-closed state-transfer/GPFIFO/paired-single and
8033/8035/8036/8038 generated families; no leaf owns more than four samples.
Do not add a product debug entitlement or repeat merged-state, guarded-call,
register-cache, or structural rewrites from this sparse signal. Retain the
external tools only; G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-warm-native-pc-ring-attribution.md`.

PERF-205 repairs the retained triggered thread sampler after a current-schema
regression proves it reads `host_frame_end_unix_ns` as `total_ms` and falsely
triggers a 10.0 ms row as `1.78807e+18` ms. The tool now resolves required
columns by header name and passes five end-to-end current, legacy, reordered,
threshold, and malformed-schema cases in the full repository gate. This is a
diagnostic correctness repair only: it records external run state/CPU time,
not native PCs, so it does not justify a fresh game run or FPS claim by itself.
G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-triggered-sampler-schema-repair.md`.

PERF-203 rejects `xctrace` CLI CPU Counters as an exact warm-frame method on
this Xcode/macOS pair. Corrected title/GameState gates reproduce a complete
first Fountain match and live second match, but attached traces crash or hang
during aggregation and remain unexportable. Do not retry a longer CLI trace or
infer counters from its visual reproduction. PERF-204 then closes LLVM
splitting: late machine splitting is unsupported on arm64 Mach-O, while the IR
hot/cold pass is already active and explicit enablement produces byte-identical
PGO objects for the selected warm chunks. Retain no product edit; G5 remains
open and G6 blocked. See
`docs/artifacts/2026-08-30/g5-warm-cpu-counter-cli-rejection.md` and
`docs/artifacts/2026-08-30/g5-hot-cold-splitting-rejection.md`.

PERF-202 closes stale or scene-incomplete PGO weighting as the explanation for
PERF-196's rare warm Fountain compute overruns. The active profile begins only
after verified Fountain combat entry and ends at natural combat completion.
Its five enriched PCs have 2,523,933-17,523,395 exact coverage hits, and an
independent full local-training repeat assigns every one the identical count
with matching function hashes and counter shapes. Do not collect or build a
third warm Fountain profile without a genuinely different workload or
compiler mechanism. Retain the current PGO module; G5 remains open and G6
blocked. See
`docs/artifacts/2026-08-29/g5-warm-profile-refresh-rejection.md`.

PERF-201 rejects a pthread QoS override and a reference-pacing transfer before
a game build. Apple's override API requires a real pending-work dependency and
cannot exceed the same user-interactive/priority-zero class already rejected
in a matched run. Current upstream Dolphin and Slippi use the same throttle,
precision sleep, presentation sleep, and Metal submission algorithms as this
checkout; their only relevant source delta is non-pacing framebuffer metadata.
Do not add a fake permanent dependency or copy identical reference code. G5
remains open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-qos-override-and-reference-pacing-audit.md`.

PERF-200 preflights `CAMetalDisplayLink` without a game build. An exact 60 Hz
control delivers 599/599 actual intervals within 16.7 ms and no modeled source
repeat. An exact 59.94005994 Hz request is nevertheless quantized to this
fixed panel's 60 Hz cadence; over 2,400 intervals it forces two callbacks where
a valid source has no new distinct frame. The API can appear perfect only by
duplicating/synthesizing content or changing deterministic guest/audio speed,
all of which violate the boundary or have direct rejections. Retain the host
harness, do not integrate it into Dolphin, and keep G5 open/G6 blocked. See
`docs/artifacts/2026-08-29/g5-metal-display-link-rejection.md`.

PERF-199 maps all three PERF-198 warm Final Destination producer stalls to
vblank with ordinary 6.019-6.648 ms thread CPU. A separate exact 5,890-frame
phase join reproduces a 59.993541 ms wall stall with only 10.339240 ms thread
CPU; guest work is ordinary, Metal/presentation is below 0.3 ms, audio is
2.077 ms, and EFB/fallback are zero. The remaining producer tail is host
execution/wake loss, not static-recompiler or GPU cost. Available scheduler,
timer, pacing, dual-core, and drawable mechanisms already have direct
reversals; retain no speculative edit. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-warm-final-destination-wall-attribution.md`.

PERF-197 repairs lightweight-only emulated-frame identity and publishes the
regression/fix in `10dcb11`. PERF-198 uses that identity for a visually verified
same-process Final Destination comparison. The 5,890-frame warm combat body
averages 59.959490 FPS with zero CPU frames above 16.7 ms, but wall p95 is
17.268541 ms and three frames exceed 20 ms (26.497500 ms worst). Final
Destination is not static-core-bound after warm-up in this run, but it is not
stable 60 FPS. Next join those exact wall rows to render/vblank/presentation
timing; do not repeat guest-PC rewrites without a new mechanism. G5 remains
open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-lightweight-frame-identity-activation.md` and
`docs/artifacts/2026-08-29/g5-same-process-final-destination-warmup.md`.

PERF-194 repeats two visually verified Fountain matches in one continuous
single-core process. The cold leg has 105 combined-thread CPU overruns; the
same-process warm leg has eight. In the first ten seconds the count collapses
from 104 to two, proving most of PERF-193's cold compute burst is one-time
warm-up. The warm match improves to 59.984858 FPS mean but still fails at
29.475375 ms worst, with eight CPU overruns and a separate 15.100374 ms wall-
minus-thread tail. Next use the retained phase logger only on a verified warm
match to attribute those eight CPU rows. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-same-process-fountain-warmup.md`.

PERF-193 retains a default-dormant observer-light producer recorder in the
canonical Dolphin patch stack. Its disabled regression proves zero thread-
clock calls and no output; opt-in mode reuses the existing wall timestamp,
reads one thread CPU clock per interval, buffers in memory, and flushes once at
shutdown. A corrected single-core cold Fountain window averages 59.942726 FPS
but fails at 39.496833 ms worst. All 104 combined-thread CPU overruns occur in
the first ten seconds; after that CPU stays within 16.7 ms while separate
33.251625/20.855458 ms wall holds remain. Next run a second Fountain match in
the same process to distinguish one-time warm-up from recurring match-start
work. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-29/g5-lightweight-producer-recorder.md`.

PERF-192 retains a strict repository-native classifier for the independent
producer and actual-presentation timelines. Nine data-free regressions prevent
wrong clock joins, hidden producer misses, silent zero-present removal, and
false fixed-rate labels. Exact replay of PERF-187/188/189 reproduces 2/1/1
GPU-ready conversion holds with zero ambiguous/undisplayed records while
independently retaining 2,583/1,908/2,393 producer misses. Only 2/0/1 of those
misses have thread CPU above 16.7 ms. The tool always emits
`g5_pass_claimed=false`; G5 remains open. Next add a default-dormant
observer-light wall/thread producer recorder rather than another codegen or
display candidate. See
`docs/artifacts/2026-08-29/g5-strict-evidence-classifier.md`.

PERF-191 identifies one genuinely distinct public scheduler policy, then
rejects it before a product build. Apple XNU maps
`THREAD_EXTENDED_POLICY{timeshare=false}` to fixed rather than timeshare
scheduling, but also clears requested pthread QoS while applying legacy policy
and contains a sustained-fixed failsafe. A data-free eight-competitor preflight
initially favored fixed mode, but the required fixed/timeshare/fixed reversal
did not: fixed arms missed 5/300 and 3/300 budgets with 29.628/20.546 ms worst,
versus timeshare's 2/300 and 17.669 ms worst. Do not add the policy to Dolphin.
See
`docs/artifacts/2026-08-29/g5-fixed-priority-preflight-rejection.md`.

PERF-190 rejects both available Apple frame-generation routes before product
integration. Color-only MetalFX is fast but produces a literal two-position
ghost. VideoToolbox low-latency optical flow supports 640x528 NV12 on this M1
at 2.380 ms mean / 2.849 ms worst after startup and reconstructs modest
synthetic motion, but real retained Melee stress pairs smear fighter limbs,
silhouettes, and effects. A chronological 59.94-to-60 converter also requires
about one source frame of display/input latency, is macOS/iOS 26-only, does not
fix the separate producer tail, and cannot force macOS to select a ready
drawable. Do not integrate interpolation or a delayed synthetic presentation
queue. See
`docs/artifacts/2026-08-29/g5-frame-interpolation-rejection.md`.

PERF-189 reopens exact `EmulationSpeed = 1.001` only against the newly
separated actual-presentation class, then rejects it directly. The corrected
1x/fullscreen Fountain candidate retains a GPU-ready 33.333666 ms actual hold
after 30.413 seconds, with a nominal 16.909166 ms producer phase and GPU work
complete 31.017 ms early. The isolated setting is removed and its config
restored byte-for-byte. See
`docs/artifacts/2026-08-29/g5-rate-alignment-actual-presentation-rejection.md`.

PERF-188 reproduces PERF-187's same-run separation on verified 1x/fullscreen
Final Destination. Its 73.449-second combat boundary has one GPU-ready
33.333667 ms actual hold with a nominal 17.058208 ms producer phase. All
fourteen separate producer rows above 20 ms are buffered into nominal actual
intervals. Fountain and Final Destination therefore share two independent
tails; both still fail G5. See
`docs/artifacts/2026-08-29/g5-final-destination-combined-join.md`.

PERF-187 invalidates PERF-186's hidden 3x/windowed profile and reruns the same
join at verified 640x528/fullscreen. The 94.650-second Fountain combat boundary
has two 33.333 ms actual holds whose producer phases are nominal and whose GPU
work finished 31.056/15.119 ms before the skipped refresh. Separately, all
fourteen producer rows above 20 ms are buffered into nominal actual intervals.
The display-conversion and producer tails are independent in the same run;
both fail the unchanged gate under their respective interpretations. See
`docs/artifacts/2026-08-29/g5-corrected-combined-producer-presentation-join.md`.

PERF-183 retains only the unchanged A leg of a proposed Activity Monitor
isolation. With Activity Monitor active, Fountain measures 59.790259 FPS with
seven doubled render rows and matching vblank stalls. This is not causal.
PERF-184 parks the proposed B/A2 isolation as an optional future diagnostic,
not a prerequisite or blocker: Activity Monitor does not need to be paused for
the goal loop to continue. Do not signal Activity Monitor, `sysmond`, or touch
Brave, Claude, OpenCodex, Codex, ChatGPT, Logitech, or system services. Continue
through the unblocking ladder with scoped macOS work that does not depend on
changing unrelated processes. See
`docs/artifacts/2026-08-29/g5-activity-monitor-isolation-a-leg.md`.

PERF-182 is an independent read-only audit of the accumulated G5 evidence and
current source. It finds no evidence-qualified public product-local mechanism
for another build: compute, GPU, presentation, scheduler/timer, audio, shader,
disc, title, and known external-agent routes are causally closed. It also
separates mathematically required 59.94-to-fixed-60 display holds from genuine
producer intervals without weakening D2; the latter still fail. Reversible
clean-host isolation of unrelated runnable load remains an unresolved optional
diagnostic, but PERF-184 parks it. It must not stop other scoped macOS work or
be treated as required. See
`docs/artifacts/2026-08-29/g5-independent-boundary-audit.md`.

PERF-181 rejects larger Cubeb buffering while preserving required audio. The
device minimum is 128 frames, so changing Dolphin's request from 512 to 1,024
is effective, but Fountain falls from 59.969577 to 59.910028 FPS and retains
three doubled render rows; p95 is unchanged/slightly worse at 16.789792 ms.
DSP-thread toggling is inert under Melee's DSP HLE. The candidate and diagnostic
are removed and the canonical runner hash restored exactly. Keep Cubeb 512.
See `docs/artifacts/2026-08-29/g5-cubeb-buffer-rejection.md`.

PERF-180 refreshes the user-visible Main Menu on the exact current PGO/Game
Mode package. A cold MemoryWatcher-gated route reaches the genuine menu class,
then a conservative 3,413-row buffered bracket averages 59.937749 FPS with no
interval above 20 ms and a 59.743392 FPS worst rolling 60-frame rate. The old
sustained 12.5-30 FPS mode does not reproduce. P95 is still 18.793042 ms and
the slow rows have compensating early rows, so do not claim perfect menu
smoothness or G5. See
`docs/artifacts/2026-08-29/g5-current-main-menu-window.md`.

PERF-179 rejects the last untested native Metal queue-depth lever. Reducing
`CAMetalLayer.maximumDrawableCount` from its three-drawable default to two
collapses Fountain's final 2,001 rows to 38.967624 FPS, 33.393333 ms p95, and
33.554417 ms worst, with 1,080 render intervals above 30 ms. The one-line
candidate is removed and the canonical runner hash restored exactly. The
default pool is necessary queue headroom; do not retry layer-pool reduction.
See `docs/artifacts/2026-08-29/g5-two-drawable-layer-rejection.md`.

PERF-178 reopens PERF-169 for a newly observed mechanism, then rejects it with
a clean direct test. Live FPS title changes do trigger recurring AppKit window-
tab and CoreSpotlight indexing, but disabling the title updates removes that
traffic without removing the frame tail: matched final 2,001-row Fountain
windows remain 59.9696 vs 59.9695 FPS with 33.919 vs 33.399 ms worst frames.
The private setting is restored byte-for-byte. Keep the FPS-title option; it is
not the primary G5 cause. Continue from PERF-176's combined CPU-GPU/vblank host-
execution stall class. See
`docs/artifacts/2026-08-29/g5-fps-title-spotlight-rejection.md`.

PERF-177 closes four false transfers after PERF-176. Current Slippi uses the
same ordinary pthread/affinity and async-shader structure; it adds no hidden
macOS scheduler policy. The clean run discovered no pipeline UIDs after its
already-warm 11:03 cache, while a retained 12,067-sample profile gives runtime
shader compilation only 15 samples. `LoadGameIntoMemory` does not wrap the
extracted `DirectoryBlobReader`, and FastDisc already failed. Do not change
shader mode, add an inert disc-memory setting, or port a cache-affinity hint.
See `docs/artifacts/2026-08-29/g5-reference-shader-and-streaming-rejection.md`.

PERF-176 joins the clean current render/vblank logs without a live observer.
All six pre-results render gaps above 20 ms map to vblank stalls at an exact
fixed +172-row offset, including four 33 ms pairs. The residual hold therefore
begins in the combined CPU-GPU/vblank host-execution path, not only in the
compositor. Supported QoS, priority, time-constraint, Game Mode, timer,
workgroup, and dual-core routes are already rejected; Apple's affinity tag is
cache-locality guidance rather than P-core pinning and is not a new fix. Do
not add an affinity no-op. See
`docs/artifacts/2026-08-29/g5-current-render-vblank-stall-join.md`.

PERF-174/175 extend the confirmed-Game-Mode Fountain result without changing
product source. A hands-off 36-cycle repeat reaches the same deterministic
match/results boundary at absolute render row 6,784; its final 2,001 combat
rows before that boundary average 59.999592 FPS with 16.785125 ms p95 and
16.946375 ms worst, still above 16.7 ms. A private reversible 1001/1000 host-
rate alignment candidate retains 16.791291 ms p95 and one 33.281208 ms hold;
it is rejected and the config is restored byte-for-byte. Do not retry a larger
speed scale, count post-match transitions as combat, run Final Destination, or
start G6. See `docs/artifacts/2026-08-29/g5-sustained-pre-results-and-rate-alignment-rejection.md`.

PERF-173 is the first full Fountain combat window gated on confirmed current
Game Mode. The exact PGO runner/module, quiet 18-cycle input, Metal, Cubeb, and
no Simulator restore a 60.000651 FPS mean with no rows above 20 ms, but the
strict final 2,001 rows still fail at 16.807334 ms p95 and 17.477083 ms worst;
only 69.165417% meet 16.7 ms. The worst rows have short catch-up successors.
No fresh visual claim is attached because this run intentionally avoided UI
automation. Retain the measurement-only result, do not run Final Destination
or G6, and continue from the residual producer-cadence tail. See
`docs/artifacts/2026-08-29/g5-confirmed-gamemode-fountain-window.md`.

PERF-172 proves current Game Mode activation for the refreshed PGO topology
without making a speed claim. A signed LaunchServices wrapper remained parent
of exact runner `e1f3c1d8...` and known PGO module `bd089303...`. Unified Game
Policy logs then recorded the identified-game, frontmost, fullscreen, and
console grants, an active fullscreen gaming session, `Game mode enabled`, DPS,
and `Game mode status is now on`. The brief boot used no replay or frame-time
measurement because current external host load is unsuitable for G5 evidence.
Require the same activation line before the next combat state load. See
`docs/artifacts/2026-08-29/g5-current-gamemode-activation-probe.md`.

PERF-171 repairs a stale ignored local PGO bundle before another live run. The
known PGO module was intact, but `SsbmPad-PGO.app` lacked the games category and
`LSSupportsGameMode`, so it failed the current package-layout test. The
pointer-safe private-profile packaging workflow refreshed it with the current
runner and canonical metadata while preserving the old bundle and restoring
the profile-free active-module pointer. Layout, arm64/macOS-14 identity, and
deep signing now pass; the known module remains `bd089303...`. This is package
readiness, not a G5 pass. See
`docs/artifacts/2026-08-29/g5-pgo-package-gamemode-refresh.md`.

PERF-170 rejects lazy-gating ModernGekko's always-on runtime diagnostics hook.
The exact-shaped host preflight hashes the same 88 bytes and performs the same
relaxed atomic operations in 59.410-62.788 ns/call across five ten-million-call
optimized repeats, only about 0.00036% of a frame. ASan/UBSan also passes. Keep
the useful public diagnostics behavior; deleting sixty nanoseconds cannot fix
off-core millisecond gaps. The disposable preflight is removed. See
`docs/artifacts/2026-08-29/g5-runtime-diagnostics-cost-rejection.md`.

PERF-169 rejects the once-per-second FPS title updater as the common clean-tail
cause. A disposable title-on/off/on run was invalidated by severe changing host
load and monotonically degraded 41.685 -> 38.389 -> 32.110 FPS across A/B/A;
no external process was altered and those numbers are not product baselines.
The earlier quiet PERF-154/165 controls provide the valid causal screen: their
>17 ms rows are scattered across unrelated modulo-60 phases rather than
clustering around a one-second update. The private setting is restored. Do not
remove the useful FPS title for G5. See
`docs/artifacts/2026-08-29/g5-title-thread-and-overloaded-host-rejection.md`.

PERF-168 rejects a second Dolphin-side presentation reserve before a product
build. Replaying the retained lightweight Fountain completion trace showed a
one-frame lead could absorb its sampled producer jitter, but the required
two-thread Metal control did not improve actual presentation: both queue
depths retained a 33.333 ms worst interval, while the extra frame increased
ready-to-submit latency. Metal's existing drawable pipeline already absorbed
the injected 8 ms producer delay. The disposable harness is removed. Do not
add an offscreen backbuffer/presentation thread or duplicate buffering already
provided below Dolphin. Continue G5 from a different causal producer-side
mechanism. See
`docs/artifacts/2026-08-29/g5-one-frame-presentation-reserve-rejection.md`.

PERF-134 rejects runner/runtime PGO before a build. The retained current-PGO
sample has 9,279 `StaticRecompCore::Run` samples and 9,030 in its already-PGO'd
module child `chassis_dispatch`; even deleting all runner-only work projects
only 2.683479%, below the 5% screen. Do not instrument or rebuild all of
Dolphin for this route. See
`docs/artifacts/2026-08-28/g5-runner-pgo-coverage-bound.md`.

PERF-133 rejects absolute Metal scheduled presentation before a Dolphin build:
the matched host control passes 600/600, while `presentDrawable:atTime:` drops
601/601 drawables with layer sync on or off and with or without an injected
25 ms producer stall. The host clock matches Mach absolute seconds, and the
disposable harness change is removed. Do not retry scheduled presentation,
Rush, fixed wake lead, or layer-sync variants. Continue from the natural
no-queue producer/descheduling tail. See
`docs/artifacts/2026-08-28/g5-absolute-scheduled-presentation-rejection.md`.

PERF-132 corrects only a rotated generated-source path diagnosis. PERF-088 had
already decoded matching coverage and rejected the resulting source-weight
and single-entry FP-trace candidates: the former were about 59-63% slower and
the latter 1.3-3.0% slower after a full semantic pass. Do not repeat either
route. Continue G5 from the separate pre-results no-queue producer/descheduling
tail. See `docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md`
and `docs/artifacts/2026-08-28/g5-profile-edge-coverage-recovery.md`.

## The loop

Repeat until G9 is met:

1. **Pick** the lowest unmet goal. Choose the smallest concrete step that could advance it.
2. **Check state before acting.** What is already built? What does `docs/STATUS.md` say? Never rebuild what a cache already holds (modules are cached by DOL hash + toolchain identity).
3. **Execute** the step.
4. **Test immediately.** Run the relevant check the moment the step completes. Compilation success is not gameplay success; a PID is not a booted game; a booted game is not a playable one.
5. **Capture evidence.** Screenshot, log excerpt, or profile into `docs/artifacts/<date>/`; one dated line in `docs/JOURNAL.md`: goal, step, command, result, evidence path, next step.
6. **Update** `docs/STATUS.md` if the goal state changed.
7. Continue. If the step failed, enter the unblocking ladder below before retrying anything.

## Process hygiene (hard rules)

- **One Simulator at a time.** Before booting any Simulator: `xcrun simctl list devices booted`, and `xcrun simctl shutdown` everything already running. This machine rule comes from sunpad's TESTING.md and is not optional.
- **One game instance at a time.** Before launching the game on any target, kill every previous instance (the macOS binary, the Simulator app, stray moderngekko processes). Two instances fighting over config, saves, or the GPU produce garbage data and false bugs. The sole exception is the G9 netplay acceptance run: use exactly two intentional endpoints with separate user/config/save directories and record both identities.
- **Kill before relaunch, always.** Never layer a new run on a hung one.
- **One variable at a time** during perf work and debugging. Change one thing, re-measure, journal it.
- **Clean up after crashes.** A crashed run can leave a booted Simulator or an orphan process; step 2 of the loop exists to catch this.
- **Never touch the inputs.** The ROM and `ref/sunpad` are read-only. Nothing containing game data ever leaves the machine or enters a git commit (enforce with the audit-script pattern from sunpad).
- **Timebox repetition.** The same command failing the same way twice is a blocker; stop retrying and enter the unblocking ladder. Never loop a failing action a third time unchanged.
- **Keep performance input quiet.** Redirect `gcpipe.py` progress output away
  from the live terminal during measured windows. PERF-153/154 proved streamed
  UI/terminal output creates severe false tail rows even though the FIFO input
  itself is unchanged.

## Unblocking ladder

When blocked, escalate through these in order. Journal each rung you use.

1. **Read the actual error.** Full log, not the last line. ssbmpad's own runtime.log breadcrumbs (once the shell exists) and the unified log are first sources.
2. **Check the reference implementation.** How does `ref/sunpad` handle this exact thing? The patches directory, the scripts, and docs/KNOWN_ISSUES.md + TECH-DEBT.md + AUDIO_ISSUE.md are a catalog of already-solved problems on this exact stack. Most blockers you hit, sunpad hit first.
3. **Check the toolchain source.** DolRecomp, ModernGekko, RecompCore, and the vendored Dolphin sources are all in `ref/`. Read the code that produced the error. The doldecomp/melee + m-ex symbol map turns anonymous crash addresses into named Melee functions; use it every time a fault lands in generated code.
4. **Research.** Web search: Dolphin issue tracker and source history, Slippi's dolphin fork (their GALE01 memory map and determinism work), decomp community material, DolRecomp/ModernGekko issues, StrikersRecomp as a second worked example. Time-limited: research to answer a specific question, then come back and act.
5. **Reduce the problem.** Smaller repro: interpreter-only run (skip the module) to isolate recomp bugs; software vs Metal comparisons for render bugs; a different stage/character to isolate content-specific faults; C backend vs LLVM backend to isolate codegen bugs.
6. **Route around.** If a specific function miscompiles, patch or replace that function (DolRecomp replacement mechanism) and keep moving; the interpreter fallback means one bad function never has to stop the port ("slower, never broken").
7. **Park and pivot.** If a blocker on the current goal survives all of the above in a working day, journal it as an open defect with a full repro, and take the largest step available that does not depend on it (e.g. shell-porting work while a perf question stews). Return next session with fresh state.

8. **Stop conditions.** Stop and write a clear handoff (JOURNAL + STATUS + the specific decision needed) only if: the ROM appears to be an unusable dump; a required upstream repo is gone and no mirror exists; or continuing would require violating a hard rule in the PRD (uploading game data, pushing to a remote, physical-device deployment). Everything else has an unblocking path.

## Active G5 scalar-single sub-loop (2026-08-25)

The independent stale-`ps1` review and its implemented correction are recorded
in `docs/artifacts/2026-08-25/g5-independent-scalar-single-review.md` and
`docs/artifacts/2026-08-25/g5-scalar-single-frsp-correction.md`. Exact helpers
now cover scalar-single arithmetic and `frsp`; focused semantic/generated-C
tests pass; 200 consecutive corrected frames are coherent; and an exact-source
PGO screen improves rather than collapses the matched no-input tail. This
closes the report's source-level action items, not the gates.

The corrected module survived a 402.7-second, 2,110-frame extended matched
visual corpus with Brinstar, multiple four-player scenes, and dense Peach
combat. `VISUAL-001B` is closed under its documented boundary and reopens on
any recurrence. A clean corrected-module Fountain interval still fails G5 at
17.000 ms render p95, 17.301 ms p99, and 79.167 ms worst.

That replay is now complete. In a clean 3,683-frame Fountain bracket, total
p95/p99/worst are 17.016/17.227/18.986 ms. Video build, present, and audio are
small; most frames retain deliberate throttle sleep, while one frame has an
18.010 ms derived-compute overrun. The current sleep counter cannot distinguish
requested sleep from wake-up lateness.

That diagnostic is also complete. Wake lateness is 0.199 ms p95 / 0.214 ms p99
and correlates only 0.024 with total time. The five worst frames requested no
sleep and have 19.470-24.159 ms of derived compute. Stop timer work.

Per-frame work attribution is complete. Tail frames execute essentially the
same bursts and charged guest cycles; host nanoseconds per native dispatch
correlate 0.783 with total time. A user-interactive CPU-thread QoS candidate
removed the 51.412 ms outlier but regressed p95 from 16.975 to 17.031 ms, so it
was removed.

The unchanged repeat reproduced p95 at 16.975 ms and a smaller 21.604 ms
ordinary-work cluster. Thread CPU timing then showed the tail is mainly on-core
execution cost: residual off-core time is only 0.018 ms p95 / 0.148 ms p99,
while tail thread CPU rises by 0.207 ms.

Runtime fallback classification is complete, but its original no-op semantic
interpretation was wrong. Dolphin invalidates the JIT cache line for `dcbf`,
`dcbst`, and supervisor-mode `dcbi` when D-cache emulation is disabled. The
generated C backend now matches the existing LLVM/runtime cache-control path,
continues the native block, and preserves privilege, cycle, D-cache-enabled,
and invalidation behavior. The stale specialized fallback was removed.

The exact profile-free matched Fountain comparison improved mean frame time
from 20.329 to 17.858 ms (-12.153%), p95 from 22.581 to 20.054 ms, p99 from
23.825 to 21.319 ms, and worst from 33.066 to 27.860 ms. Cache fallbacks fell
from 6,066.022/frame to zero while 6,064.453 direct cache-helper calls/frame
remained exactly accounted. Retain the correction, but do not pass G5: only
19.285% of candidate frames are <=16.7 ms.

That exact-source PGO cycle is complete and rejected. One visually verified
Fountain profile was merged; the PGO-use module passed native-runtime smoke,
but its 6,428-frame strict Fountain bracket measured 16.894 ms mean,
17.860 ms p95, 18.080 ms p99, and 1,367.699 ms worst. Only 55.009% of frames
were <=16.7 ms. Final Destination was therefore not run.

Visual re-audit classified the acceptance screen correctly: its two real
Bowsers match the accepted Bowser/Bowser roster and remain coherent; only the
known reference-parity Fountain reflection is distorted. The profile-free
Bowser/Ice Climbers screen agrees. `VISUAL-001B` remains closed under its prior
extended-corpus boundary. Cold-boot testing did prove the current title-
lockout predicate cannot distinguish the opening movie from the title and
attract path reliably; invalid demo routes were excluded by visual gates.

Throttle-deadline attribution and its focused host regression are complete.
A 3.02 ms macOS wake lead plus true busy spin passed 900/900 host samples at
<=16.7 ms, but the real corrected-module Fountain bracket regressed to
19.667 ms mean, 22.357 ms p95, 24.690 ms p99, and only 2.895% <=16.7 ms.
CPU-thread work rose to 19.437 ms mean and the emulator no longer reached its
throttle point. The candidate is rejected and removed; no other timer variant
may be tried without new evidence.

The same work caught and excluded a stale generated-module package, restored
the canonical corrected `06852d9f...` source/module path, and proved the cold
route is deterministic when MemoryWatcher starts before the runner: opening-
movie state precedes the genuine 0x14-to-zero title lockout, then the exact
one-second START hold reaches menu/CSS.

The matched restored-runner control is complete. Its 3,673-frame Fountain
bracket restored 59.932 FPS average and measured 16.686 ms mean / 17.656 ms
p95 / 18.984 ms p99 / 36.424 ms worst, with zero fallbacks and 6,057.624
direct cache controls/frame. This confirms the busy-spin regression was timer
contention, but G5 still fails its tail gate. Relative to the <=16.7 ms body,
the p95 tail has nearly unchanged bursts and guest cycles but 13,634 more
native dispatches/frame (+10.5%) and 5.8% more CPU-thread nanoseconds per
dispatch.

Dispatch-return attribution was then screened at exact, one-in-256, and
piggybacked one-in-4096 rates. Exact classification visibly reduced Stage
Select to about 44.5 FPS; the sampled variants also could not rule out observer
cost, so all attribution code was removed. One restored normal-runner
Pikachu/CPU-DK Fountain interval did average 19.761 ms / 50.605 FPS with a
19.575 ms CPU-thread mean. A fresh cold replay of the same roster then visibly
held 59.8-59.9 FPS through combat and results, falsifying deterministic roster
attribution. The slowdown is real but intermittent or host/path-state
dependent. Animated-menu slowdown remains in the regression scope, though it
does not yet have a clean numeric bracket.

The fresh normal external sample put the known scheduler poll
`loop_80349494` atop 156/886 CPU-thread samples even at full speed. A burst-
entry idle precharge candidate failed mechanistically: its sample still had
the loop atop 183/890 samples and its 4,090-frame phase bracket failed G5 at
17.577 ms p95 / 19.527 ms p99. It was removed. The next single experiment is a
local generated-branch early return after one taken poll at the exact idle PC,
followed by a focused semantic test and a matched phase-logged Fountain pair.
Do not add a check to every dispatch, retry timer variants, or retry the
rejected global loop budgets; do not run Final Destination or start G6. See
`docs/artifacts/2026-08-26/g5-idle-precharge-rejection.md`.

The exact generated idle branch has now been tested. Returning after one poll
without preserving cycle charge visibly halved opening-movie speed and was
rejected. A cycle-preserving collapse kept about 8.107M guest cycles/frame,
reduced CSS CPU-thread mean from 8.463 to 5.48-5.60 ms, and reduced the idle
loop from 1,839 to 34 samples. However, two matched CSS brackets regressed p95
from 16.896 ms to 18.479 and 18.468 ms as mean wake lateness rose from 0.070 ms
to 0.375-0.407 ms. Both shortcuts are removed. The next single experiment is
a host-only preflight for chunked long Apple precision sleeps before the
unchanged 1.02 ms final-yield window; combine it locally with the
cycle-preserving shortcut only if the preflight improves long-sleep lateness
without busy-spin contention. G5 remains open; do not run Final Destination or
start G6. See `docs/artifacts/2026-08-26/g5-menu-idle-loop-rejections.md`.

The long-sleep preflight passed for 500 us chunks: chunked yield measured
16.692 ms p95 and chunked true spin 16.683 ms p95. Both were then combined
locally with the cycle-preserving idle collapse on watcher-gated CSS. Chunked
yield fixed wake-lateness p95 to 0.013-0.016 ms but repeated at 16.933/16.902 ms
frame p95. Chunked true spin reduced wake-lateness p95 below 0.001 ms but
repeated at 16.928/16.890 ms. Neither passes 16.7 ms or consistently beats the
16.896 ms normal control, so all product changes are removed. Retain the
extended host preflight only. The next single experiment is diagnostic phase-
log attribution of CPU-slice, throttle-target, and present-frame boundaries;
do not retry timer or generated-loop variants. See
`docs/artifacts/2026-08-26/g5-menu-pacing-followup-rejections.md`.

Phase-boundary attribution is complete. Across three watcher-gated normal CSS
brackets, intended-present and CPU throttle targets advanced at exact
16.683333/16.683334 ms cadence. Tail rows did not add CPU slices or throttle
calls. `SyncGPU` cost about 0.0001 ms, video queue/service about 0.03 ms, and
presentation work remained tiny. The CPU reached VI output 1.092 ms after the
intended target on average and 1.313 ms at p95; the last-throttle-end to VI-
output wall interval rose from 2.452 ms/body to 3.176 ms/tail. A CSS-only,
post-throttle piggyback sample ranked scheduler poll `0x80349494` first and the
tiny interrupt leaves `0x80345738`/`0x80345760` second/third at 3,121/3,118
samples. Diagnostic code is removed. The next single experiment is exact
module-level coalescing of only those two interrupt leaves, with a focused
semantic regression first. Do not combine it with the rejected idle collapse
or change timer/SyncGPU/queue/Metal. See
`docs/artifacts/2026-08-26/g5-css-boundary-attribution.md`.

Exact module-boundary coalescing of the two interrupt leaves is complete and
rejected. A focused semantic regression covered both EE states, CR0/SO,
registers, PC/LR, and exact 5/7/8-cycle charges. The native candidate removed
about 51 of roughly 67,052 CSS dispatches/frame, but CPU-thread mean remained
8.48 ms and the 3,600-frame p95 was 16.908 ms versus the 16.896 ms control.
All candidate source is removed and the normal module restored. Do not retry
another isolated low-frequency guest leaf. The next host-only preflight must
measure the common per-dispatch chassis path, starting with the empty forced-
fallback-range check, before another cold game build. See
`docs/artifacts/2026-08-26/g5-interrupt-leaf-coalesce-rejection.md`.

The common-path empty-forced-fallback preflight is also complete without a
game rebuild. A corrected out-of-line host benchmark measured only 0.314 ns
saved per dispatch, or 0.021 ms at 67,000 CSS dispatches/frame. That cannot
explain or repair the strict tail, so no product change was made. Stop shaving
isolated chassis branches. The next diagnostic is a longer watcher-gated
normal CSS soak with rolling-window detection for the user's distinct,
intermittent major menu slowdown. See
`docs/artifacts/2026-08-26/g5-empty-fallback-preflight.md`.

Exact late-Fountain CPU counters then measured 48.674% instruction delivery
and motivated a regression-first C-backend PC-materialization candidate. The
narrowed form passed 14/14 DolRecomp tests and live lockstep, removed 28.5% of
generated `ctx->pc` stores, and shrank `__text` by 1.41 MiB. The equal
440-emulated-frame reversal nevertheless lost: candidate 20.150 ms mean /
21.983 ms p95 versus fresh canonical control 19.017 / 20.576 ms, with only a
three-cycle and one-dispatch work difference. It is removed. Do not retry
global transparent-instruction PC elision; select the next candidate from a
new dynamic exact-window cost. G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-27/g5-transparent-pc-elision-rejection.md`.

The next dynamic helper screen is also complete. Inlining only the common
enabled-FP availability test passed focused semantics and a 1,367-PC lockstep
screen, but its equal-frame A/B/A repeat tied or lost to canonical: 19.036 ms
mean / 20.831 ms p95 versus 19.002 / 20.675 ms. It is removed. A load attempted
at emulated frame zero trapped while Dolphin's emulation thread was still
starting; all future signal loads must wait for advancing emulated frames.
G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-27/g5-fp-availability-inline-rejection.md`.

The longer menu diagnostic separated sustained FPS from pacing. A five-minute
normal background CSS soak averaged 59.940 FPS and never fell below 55 FPS in
any rolling 1/2/5/10-second window, but p95 rose to 17.838 ms with three
52-85 ms hitches and 0.925 ms mean timer wake lateness. A matched explicitly
raised normal control returned to 16.927 ms p95 and 0.070 ms wake lateness with
unchanged CPU work. Two lifecycle-balanced `NSProcessInfo` activity variants
did not improve background pacing and are removed. The next diagnostic must
record actual application-active transitions and run a longer raised control;
do not retry activity flags. See
`docs/artifacts/2026-08-26/g5-menu-background-pacing.md`.

The required same-process transition control withdrew that attribution. One
unchanged verified CSS process ran foreground, background, then foreground;
the final 3,600 rows of each stable segment all averaged 59.940 FPS, measured
16.912/16.928/16.934 ms p95, and had 0.072-0.077 ms mean wake lateness. Focus
did not cause the earlier cross-process difference, and no focus or activity
policy is retained. The normal menu did not reproduce a sustained major
slowdown in this run. The next diagnostic is a normal-product trigger that
captures phase rows plus a low-overhead native sample on the first one-second
window below 55 FPS. The separate strict G5 tail remains open; do not run Final
Destination or begin G6. See
`docs/artifacts/2026-08-26/g5-active-transition-pacing.md`.

The menu trigger is now stage-safe and retained default-off. It can ignore a
startup prefix and remain unarmed until MemoryWatcher proves CSS; on the first
60-frame interval below 55 FPS it flushes phase evidence before a native
sample begins. This excluded a cold-start 14.3 FPS title average and a 50.3 FPS
opening-movie window. After four armed CSS minutes it captured a real 54.918
FPS one-second hitch cluster: three 33-70 ms frames had flat guest work, only
11-13 ms CPU-thread time, and tiny renderer/present/audio cost. The loss is
off-core host delay. Two/five/ten-second rates still held
57.316/58.866/59.399 FPS, so no sustained 12-15 FPS menu collapse is proven.
Do not retry focus/activity, timer, or idle-loop changes. Return to the normal
required-stage strict tail and reopen this branch only for a multi-second
sub-55 recurrence. See
`docs/artifacts/2026-08-26/g5-css-slow-window-capture.md`.

Frame-correlated native sampling now separates the two open symptoms. A
visually verified Pikachu/CPU-DK Fountain bracket measured 16.664 ms p50 and
17.881 ms p95; about 8,008 extra dispatches in tail frames were distributed
across many addresses, so do not retry isolated leaves. The same cold route
captured four 1.87-3.17 second CPU-bound scene transitions dominated by Melee
`lbDvd`/`DVDCancel` synchronous wait paths, with negligible Metal present
time. The next single experiment is an isolated control using Dolphin's
existing fast-disc setting. It must retain correct visible behavior and
deterministic/netplay configuration as well as reduce the measured transition
gaps. See
`docs/artifacts/2026-08-26/g5-fountain-frame-address-attribution.md`.

The isolated fast-disc control is complete and rejected. It preserved visible
Pikachu/CPU-DK Fountain behavior but did not remove four 1.85-3.23 second
scene-change rows, and Fountain still measured 17.827 ms p95. The long rows
aggregate roughly 111-193 normal frames' worth of guest cycles; do not treat
them as sustained animated-menu FPS or optimize DVD code from them. Tail PCs
instead map broadly across HSD matrix/material/animation work and GX state
setters. The next single experiment is a host preflight for coherent
cross-segment dispatch reduction that preserves SMC verification, exception
and host-call boundaries, guest cycle accounting, and bounded event delivery.
See `docs/artifacts/2026-08-26/g5-fast-disc-rejection.md`.

A renewed canonical live check now distinguishes the user's menu report more
sharply. The untouched animated Main Menu held 59.936 FPS over 5,042 frames
with 16.946 ms p95, so a sustained 12.5-30 FPS state did not recur. It still
produced a visible 102.552 ms hitch, and the complete route reproduced four
1.90-3.72 second CPU-bound transition freezes with 58-92 million dispatches
and negligible Metal present time. Keep all three performance scopes
separate: steady menu pacing, transition freezes, and the required Fountain
strict tail. G5 remains open for all visible failures; the 59.9 title is not
acceptance proof. See
`docs/artifacts/2026-08-26/g5-live-main-menu-reproduction.md`.

The 1,024-instruction generated C chunk candidate is also complete and
rejected. Although its bounded lockstep screen introduced no new divergence
class and visible Pikachu/CPU-Yoshi Fountain remained coherent, the bracket
measured 17.867 ms p95 / 59.740 FPS and native dispatches increased to about
161,478/frame. Smaller host functions therefore lose to more cross-chunk
returns. LLVM is not a bounded alternative because the backend rejects Apple
arm64 production targets. Do not retry either route. Patch 0011 now
canonicalizes the default-off frame/PC sampler after a verified clean patch
chain; it does not change the normal product path. See
`docs/artifacts/2026-08-26/g5-generated-chunk-size-rejection.md`.

The opposite 8,192-instruction C control is also rejected, at the semantic
gate. It reduced hashed chunks from 237 to 119 and linked successfully, but a
matched headless lockstep screen produced 91 reports versus the canonical
control's 88, adding memory-writing mismatch entries at `0x80339460`,
`0x803394C4`, and `0x80339510`. It was never installed or performance-tested.
The generator limit is restored to 4,096. Do not retry larger monolithic
chunks; preserve canonical segment boundaries or strengthen the equivalence
proof before transforming them. See
`docs/artifacts/2026-08-26/g5-c8192-semantic-rejection.md`.

A preserved-boundary direct-chunk table also fails G5 and is removed. ABI 4
temporarily exposed a generated function pointer parallel to each of the
canonical 237 verified chunks, letting the chassis skip the module's duplicate
address-to-function search without changing segment, SMC, host-call, exception,
cycle, or event boundaries. Its matched lockstep result exactly preserved the
canonical 88 reports / seven fallback skips / three zero skips / zero
undercharges. Computer Use then verified Pikachu versus CPU Yoshi, literal
Fountain, coherent combat, and the result screen. The clean 4,743-frame combat
bracket nevertheless measured 16.934 ms mean / 18.753 ms p95 / 59.054 FPS.
Restore ABI 3 and generic dispatch; do not retry module-function lookup/layout
changes without a new mechanism explaining the repeat Fountain regression. An
exact canonical Pikachu/CPU-Yoshi Fountain control subsequently measured
16.763 ms mean / 17.554 ms p95 / 59.657 FPS over the same 4,743-frame count,
confirming the candidate's +0.171 ms mean and +1.199 ms p95 regression.
Disassembly, rather than the guest-path-dependent dispatch-count difference,
confirms duplicate chunk-index resolution in that candidate loop. A simpler
DOL last-chunk cache then failed to establish the exact route and sustained
only 49.134 FPS / 24.563 ms p95 over 1,479 active How-to frames, so it too is
removed. Do not retry chunk-lookup micro-optimizations. Keep the independently
reproduced 1.90-3.72 second menu
transition freezes in G5 scope. See
`docs/artifacts/2026-08-26/g5-direct-chunk-table-rejection.md` and
`docs/artifacts/2026-08-26/g5-direct-chunk-matched-yoshi-control.md` and
`docs/artifacts/2026-08-26/g5-last-chunk-cache-rejection.md`.

The next zoomed-out preflight splits the remaining slow paths instead of
forcing one common cause. Visually gated Apple CPU Counters measured the
four-player combat CPU thread at 53.6% instruction-delivery loss / 33.1%
useful, but the slow How-to CPU thread at only 20.2% delivery loss / 74.7%
useful. Broad generated-code outlining is therefore rejected. Two combat-hot
chunks shrink 36-38% under standalone native `-Oz`, but the attempted full
links reproduced the exact canonical dylib and did not create a testable
candidate. Do not retry dispatcher, timer, chunk-size, or broad-outlining
variants. The next single experiment is a clean native CPU sample over the
visually gated How-to fight, joined to its frame-PC log, followed by at most
one named routine/helper optimization with material attribution. G5 remains
open and G6 remains blocked. See
`docs/artifacts/2026-08-26/g5-front-end-pressure-preflight.md`.

How-to is now attributed specifically to Nintendo THP video decompression.
The hot generated chunks cover `THPVideoDecode` and the 640x480/NxN MCU-row
decompressors; paired-single helpers and generic writes dominate their native
stacks. A semantic-clean inline `MSR.FP` gate nevertheless grew generated text
by 855,404 bytes and reduced coherent four-player combat to 38.380 FPS over a
clean 201-frame bracket, so it is removed. Do not retry global FP gates or
inline PSQ expansion. The next single experiment is a default-off address
histogram in the THP-time external-write path. Only a proven stable RAM range
may justify a focused MMU-validated contiguous-buffer fast path. G5 remains
open; G6 remains blocked. See
`docs/artifacts/2026-08-26/g5-thp-fp-gate-rejection.md`.

The follow-up external-write histogram confirms that THP's hot output is
almost entirely one-byte stores into the 16 KiB locked-cache window. A direct
locked-cache write path passed the bounded canonical lockstep screen and
improved the same How-to movie from 21.252 to 16.565 ms mean, but a fresh exact
Pikachu mirror on literal Fountain regressed from 59.519 to 55.764 FPS and
from 18.391 to 20.200 ms p95. Reject and remove the global shortcut; retain
the THP/MMU attribution. The next single experiment is a host-only,
THP-scoped preflight that separates byte-store, address-translation, and
journaling cost before any new game build. Do not use guest-PC special cases
or another broad locked-cache path. G5 remains open and G6 remains blocked.
See
`docs/artifacts/2026-08-26/g5-locked-cache-fast-path-rejection.md`.

The required host-only chassis preflight is complete. Across five fresh
processes using Dolphin's real MMU and L1 buffer, the median one-byte path cost
was 6.765 ns canonical, 5.446 ns after `Memcheck`, 1.356 ns for journal plus
direct store, and 2.289 ns when stable MSR propagation was restored. Generic
`WriteToHardware`, not `Memcheck` or MSR alone, owns most removable inner cost.
This does not reopen either rejected global locked-cache path. The next single
experiment is offline analysis of contiguous store runs in the exact hot THP
chunks `0x8032D940` and `0x80331940`; require an exact bulk-operation semantic
regression before another game build. G5 remains open and G6 remains blocked.
See
`docs/artifacts/2026-08-26/g5-locked-cache-write-chassis-preflight.md`.

The exact contiguous-store follow-up is retained. Dolphin's interpreter and
arm64 JIT perform non-`W` paired-single stores as one wide transaction;
GXRuntime performed two lane transactions. Exact float/U8/U16/S8/S16 and
single-lane regressions now pass. A stale cache-hit package was detected and
excluded before acceptance; `moderngekko-port` now fingerprints the GXRuntime
and module-template sources, built new key `1e1debc9fb83a31a`, and repeated as
a hit. The genuine candidate improved the visually verified Mario/Bowser THP
movie from 21.252 to 16.678 ms mean and CPU-thread work from 20.493 to
11.095 ms. Coherent Pikachu/CPU-Mario Fountain measured 16.710 ms / 59.845
FPS, but its 18.217 ms p95 and How-to's 17.876 ms p95 still fail strict G5.
Retain both semantic and cache fixes. Next, split the retained Fountain p95
rows from the <=16.7 ms body and sample that exact live-rendered tail; change
one newly attributed hotspot only. Do not retry global locked-cache, timer,
dispatcher, broad FP, or guest-PC shortcuts. G5 remains open and G6 remains
blocked. See
`docs/artifacts/2026-08-26/g5-paired-store-transactions-retained.md`.

The symmetric paired-load follow-up is rejected. Exact float/U8/U16/S8/S16
external-read regressions passed, but the distinct candidate fell from
59.9-60.0 FPS in menus to 52.141 FPS mean in visually verified
Pikachu/CPU-Yoshi Fountain combat. Its 4,578-frame bracket measured
19.178837 ms mean, 21.220959 ms p95, 18.779152 ms CPU-thread mean, flat guest
cycles, and zero fallbacks. Candidate source and bootstrap state are removed;
the paired-store build is active and the product was never changed. Do not
retry a global paired-load/MMU shortcut. Next, add source line tables to a
diagnostic-equivalent retained module and take a normal native Fountain sample
without per-frame PC logging, reducing `0x8035D940`/`0x8033D940` to one named
guest routine/helper. G5 remains open and G6 remains blocked. See
`docs/artifacts/2026-08-26/g5-paired-load-transaction-rejection.md`.

The line-symbolized, text-identical diagnostic reduced the live Fountain hot
chunk to `WriteMTXPS4x3`: six GQR0 loads followed by six GX FIFO paired stores,
with the store PCs accounting for 283/8,892 chassis samples. A guarded general
GQR0 helper passed GXRuntime 1/1 and DolRecomp 14/14, but the distinct candidate
fell to 20.823964 ms / 48.022 FPS / 23.354708 ms p95 over 5,486 visually
verified Bowser/CPU-Ness Fountain frames. Candidate code is removed, retained
key `1e1debc9fb83a31a` is active, and the product was never changed. Do not
retry the helper split. Next, host-preflight a general ordered GX FIFO matrix
batch with exact byte/order/callback semantics before another module build.
G5 remains open and G6 remains blocked. See
`docs/artifacts/2026-08-26/g5-line-symbolized-fountain-attribution.md` and
`docs/artifacts/2026-08-26/g5-gqr0-store-fast-path-rejection.md`.

The ordered 64-bit gather-write follow-up is also rejected. Although a
real-GPFifo host preflight showed an approximately 8x isolated win and the
one-arm candidate passed matched bounded lockstep, its first exact-length
Fountain bracket regressed from 53.537 to 51.076 FPS and from 20.975 to
22.605 ms p95. A no-P1-input follow-up was not causally matched because CPU AI
diverged by roughly 34,785 native dispatches/frame; candidate p95 still
worsened from 21.425 to 23.151 ms. The branded runner could not produce a
shared save state through the standalone signals or native shortcuts, so no
stronger claim is manufactured. Candidate and temporary code are removed,
the promoted product is unchanged, G5 remains open, and G6 remains blocked.
Next, establish a verified save/load-state or emulated-frame-gated comparison
harness before another performance candidate. See
`docs/artifacts/2026-08-27/g5-gpfifo64-rejection.md`.

The deterministic comparison prerequisite is now retained as patch 0013.
Failing-before evidence showed `SIGUSR1` killed the branded runner; a first
handler build survived but could not write because the custom runtime omitted
Dolphin's standard user-directory creation. The retained default-off path
creates that directory tree and maps `SIGUSR1`/`SIGUSR2` to Dolphin's existing
platform requests only when `MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1`. A signed
live run wrote a real 9.2 MB state, visibly advanced, loaded it, rewound, and
continued emulation. The RAM-bearing state remains local. This is tooling, not
a performance pass: G5 remains open and G6 remains blocked. Next, make one
late-Fountain state and require aligned work counts across canonical control
and a distinct candidate before judging the next optimization. See
`docs/artifacts/2026-08-27/g5-deterministic-savestate-harness.md`.

The late-Fountain comparison prerequisite is now complete. A local state
visibly restored Pikachu/CPU-Fox combat from a later divergent scene, and
patch 0014 adds Dolphin's savestated emulated VI frame to the diagnostic phase
CSV. Two `48123..48562` control replays matched exactly at 3,567,157,803 guest
cycles, 59,374,686 native dispatches, and 905,158 bursts. Equal presentation
row counts had not matched because missed deadlines change how many emulated
fields land in each present bucket. A shared-state A/B/reverse-A rerun of the
64-bit gather-write arm found overlapping control/candidate timing; the
fastest reverse control beat the fastest candidate. The arm is removed again.
Retain the emulated-frame diagnostic, require it for future causal A/Bs, and
attribute one new compute hotspot inside this exact window. Do not retry
gather width, global MMU/locked-cache, timers, dispatcher budgets, broad FP,
or guest-PC shortcuts. G5 remains open and G6 remains blocked. See
`docs/artifacts/2026-08-27/g5-emulated-frame-shared-state-verdict.md`.

The next exact-window lead, SDK `PSMTXConcat` at guest
`0x803408D4..0x8034099C`, is rejected at preflight. A hash-gated disposable
whole-function replacement matched full CPU and memory state across 20,000
randomized trials and was 3.23-3.29x faster per hit, but enabling the supported
replacement path added 2.04-2.40 ns to every non-hit dispatch. At Fountain's
roughly 130,000 dispatches/frame, that global 0.27-0.31 ms tax consumes the
sample-bounded local gain. Candidate source was removed before live testing;
the active module and product remain canonical. Do not retry this replacement
shape or a common-path guest-PC shortcut. Continue G5 by finding a larger
coherent exact-window kernel or a general optimization with no per-dispatch
tax. G6 remains blocked. See
`docs/artifacts/2026-08-27/g5-psmtxconcat-replacement-preflight-rejection.md`.

The subsequent line-zero attribution found compiler-generated intra-chunk
entry decoding, but a computed-label rewrite is rejected at linked preflight.
Canonical Clang already lowers the dense switch to a constant-time 32-bit
relative jump table. The candidate used 64-bit label pointers, grew total VM
by 2.70 MB, doubled the hot chunk's stack frame, and produced only mixed
standalone timing. It was removed before lockstep/live testing; the active
module and package were untouched. Do not retry pointer-width computed labels
or treat static text shrinkage as a performance result. Continue G5 from a
newly measured dynamic cost; G6 remains blocked. See
`docs/artifacts/2026-08-27/g5-computed-label-entry-decoder-rejection.md`.

The next exact-window helper investigation retained a correctness repair.
All 3,677 scalar FMA sites previously used a value-return helper that missed
normal `fmadds` FI/FR and NI-mode single-subnormal flushing. DolRecomp now
emits the existing instruction-shaped exact helper for all eight scalar FMA
forms, with generated-C and GXRuntime regressions. Clean patch reproduction,
fresh suites, bounded lockstep, exact shared-state work, official rebuild,
signed packaging, and coherent live Fountain all pass. The warmed candidate
did not improve performance: 19.127040 ms / 52.282 FPS / 21.457875 ms p95
versus canonical 18.967010 / 52.723 / 20.397875. Retain the semantic fix, do
not count it as a speed win, and keep G5 open/G6 blocked. Next, re-sample the
promoted exact window and rank the next dynamic cost after excluding the known
scheduler and corrected FMA helper. See
`docs/artifacts/2026-08-27/g5-scalar-fma-semantics-retained.md`.

The promoted no-logger audit then proved observer overhead is real but not the
G5 root cause. Full phase logging costs roughly 1-2 FPS, while the normal
signed product still measured only 53.3-55.3 FPS on the retained Fountain
state and a live four-player Brinstar attract scene reached 22.9 FPS. A
regression-first default-off diagnostic gate removed `ShouldCheck` and reduced
`StaticRecompCore::Run` self samples, but its equal-frame mean lost at
18.997244 ms versus the promoted control's 18.926719 ms; p95 tied at
20.771917/20.781917 ms. The candidate is removed. Do not retry observer gates
or treat phase-logged FPS as product FPS. Continue G5 by line-symbolizing the
large no-logger `func_8035D940`/`func_8033D940` generated costs and selecting a
coherent guest kernel before another source change. G6 remains blocked. See
`docs/artifacts/2026-08-27/g5-diagnostic-overhead-gate-rejection.md`.

The following promoted exact-window sample selected generated `lmw`/`stmw`
transfers as a cross-routine cost. Retained shared helpers classify one safe
ordinary-RAM range for long transfers and fall back per word everywhere else;
short forms stay canonical. Regression coverage preserves mirrors, EXRAM,
journaling, reservation invalidation, and base-register overwrite semantics.
Exact A/B/A2 reproduces a 0.21-0.24 ms CPU-thread gain, while `__text` shrinks
331,796 bytes. The official key `b2d4b69da942f7c2`, signed package, and a
coherent live 54.7 FPS Fountain combat frame pass. This is useful progress but
not the strict 16.7 ms/60 FPS gate: G5 remains open and G6 remains blocked.
Continue from a fresh no-logger sample of this promoted module. Do not retry
the rejected inline helper form or route short stores through the helper. See
`docs/artifacts/2026-08-27/g5-multiword-range-helpers-retained.md`.

Fresh no-logger and byte-identical line-table samples after PERF-057 confirmed
that the six `WriteMTXPS4x3` FIFO stores remain hot. The deterministic harness
now supplies the shared-state comparison missing from the old `Write64`
experiment. Candidate A/A2 and a same-build reversal executed identical work,
but the candidate did not reproduce a CPU-mean gain and both candidate means
were slower; p95 remained above 16.7 ms. The 8-byte arm is removed. A packaged
runner row executed different work and is explicitly contaminated, not a
control. G5 remains open and G6 blocked. Continue by aggregating non-entry
source lines inside `func_8035D940`; do not retry gather width or the same
matrix-writer shortcut. See
`docs/artifacts/2026-08-27/g5-gpfifo64-deterministic-rejection.md`.

The subsequent cross-routine FMA attribution selected the dominant
single/add/non-negative constant mode for a cheap host gate. A fixed-mode clone
passed 160,000 complete-state semantic comparisons, but 56 paired
five-million-operation timings averaged 19.362982 ns specialized versus
19.347089 ns generic, with an effectively even win split. The outer flag split
is rejected before a module/game build and product source is unchanged. Do not
retry constant-mode routing; any further FMA work must first identify a
specific inner classification or rounding cost with exact semantic coverage.
G5 remains open and G6 blocked. See
`docs/artifacts/2026-08-27/g5-fma-mode-split-preflight-rejection.md`.

PERF-087 now separates entry dispatch from internal profile-guided layout. In
one exact callful interval, frontend PGO reduces the host-address spread from
148,788 to 11,780 bytes, while computed-label and biased-hot entry rewrites
improve an exact semantic-equivalent slice by only 1.785% and 2.904% median.
Reject entry-only rewrites. The next static-recompiler experiment is a bounded
single-chunk export of profile edge counts into source-level branch
probabilities; require full state/RAM equivalence, layout convergence, <=5%
text growth, and >5% local timing gain before a module build. Treat synchronous
Metal shader compilation and rare off-core presentation stalls as a separate
tail branch. G5 remains open; do not run Final Destination or start G6. See
`docs/artifacts/2026-08-28/g5-profile-weighted-block-layout.md`.

PERF-088 executes and rejects that next experiment. A coverage-mapped module
decoded the retained profile exactly; C-level weights compact the selected hot
interval but cause cold/minsize treatment and a 59-63% slowdown. A narrowed,
GPR-cached, FP-gate-reduced hot trace passes 4,096 full-state/RAM cases but is
2.492% slower in the long ThinLTO confirmation. Do not broaden either route.
Frame-correlated EFB counters find one real 1.198 ms synchronous VRAM pipeline
compile in exact Fountain frames `48123..48562`, but subtracting it changes
neither p95 nor the 184/440 frames over 16.7 ms. The 73.470 ms worst frame has
zero shader misses and about 48.6 ms of off-core wall time. Retain the counters,
reject prewarming as the tail solution, and repeat the same exact window on the
best frontend-PGO oracle. G5 remains open; G6 and Final Destination remain
blocked. See
`docs/artifacts/2026-08-28/g5-profile-edge-and-efb-attribution.md`.

PERF-089 completes that exact PGO-oracle comparison. On the same 440 Fountain
frames and identical guest work, frontend-PGO CPU-thread mean/p95/worst are
11.676/12.984/16.284 ms and every CPU-thread row meets 16.7 ms. Total
p95/p99/worst remain 18.256/19.823/25.517 ms. CPU wall exceeds CPU-thread time
by 4.609 ms mean, 6.180 ms p95, and 12.630 ms worst. The only EFB compile is
1.445 ms and changes neither p95 nor any of 215 failing frames. This proves
the current static-recompiled on-core path is no longer the strict Fountain
bottleneck in this window. Requested throttle sleep is zero on every selected
frame and actual throttle sleep is only 0.000511 ms mean, so do not retry the
timer path. Next directly classify CPU-thread wait states or
OS descheduling on the same PGO oracle; do not retry compiler flags, source
weights, trace narrowing, EFB prewarming, scheduler priority, or display
pacing. G5 remains open; do not run Final Destination or start G6. See
`docs/artifacts/2026-08-28/g5-pgo-wall-tail-attribution.md`.

PERF-090 through PERF-093 directly resolve that wall-tail branch. Observer-
heavy stack sampling is excluded; direct counters show precision-timer work at
only 0.000372 ms/frame mean. Their attempted resolution correction edited only
`Config/GFX.ini`, but the runner's authoritative top-level `config.ini` still
selected 1920x1080/3x. PERF-091's nominal 1x/3x reversal is invalid. Presenter
and Metal
subphases then prove that `CAMetalLayer.nextDrawable` averages 4.784 ms and
owns 99.600% of `BindBackbuffer`. On those exact 3x Fountain frames
`48123..48562`, all CPU-thread rows meet 16.7 ms (11.544/12.654/15.782 ms
mean/p95/worst), while total p95 is 17.756 ms and only 243/440 rows pass. Next
recognize this as the CPU-side Core Animation backpressure point, not proof of
an onscreen missed refresh: earlier synchronized actual-presentation windows
passed. PERF-094/095 reject `addPresentedHandler` as a joined observer because
it changes selected work from 1.502 to 3.567 billion cycles and collapses
acquisition wait to 0.018-0.023 ms. The logger is removed. Retain stripped
actual-presentation evidence and target rare pre-acquisition full-match stalls;
do not mutate drawable lifecycle, return to compiler flags, source weights,
timer variants, EFB prewarming, or resolution changes. G5 remains open; Final
Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-frame-wait-and-metal-bind-attribution.md`.

PERF-096 through PERF-098 correct that configuration boundary and extend the
measurement to a natural full match. A fresh private clone retains both
`resolution=640x528` and `InternalResolution = 1`; its save and PGO module are
unchanged. In an effectively identical-work 3x/native/3x reversal, true native
improves total mean to 16.571 from 16.683/16.677 ms and pass count to 250 from
243/241, but p95 remains 17.055 ms. Native is required and retained, not a G5
fix. The phase-only full combat interval contains 6,723 rows and one 54.523 ms
stall. That row has 17.223 ms CPU-thread work, 36.874 ms off-core wall time,
0.031 ms drawable acquisition, ordinary guest work, and no EFB miss. The
severe remaining stall is pre-Metal/off-core. Next identify the exact kernel
wait or scheduling edge without retrying QoS, time-constraint, dual-core,
timer, VSync, or presentation variants. G5 remains open; Final Destination and
G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-true-native-and-full-stall-attribution.md`.

Inner FPRF attribution is also complete. A finite-normal branch passed full
classification and scalar-FMA state semantics but lost all 54 corrected host
timing pairs by 31.1%, so it was rejected before a game build. A current-source
build with the excluded stale profile was then used only as an oracle; missing
and mismatched profile coverage plus a 24.379 ms mean / 53.859 ms p95 rejects
that stale direction. Do not retry either experiment. See
`docs/artifacts/2026-08-27/g5-fprf-hotpath-preflight-rejection.md` and
`docs/artifacts/2026-08-27/g5-stale-pgo-oracle-rejection.md`.

The packaged/local workload discrepancy is now closed. The app had bundled
`GALE01r0.ini` where neither its local-dev resolver nor a valid signed bundle
could consume it, and extracted-DOL boot did not install the disc's revision
layer. Explicit app-bundle mode, `Contents/Resources/Sys`, boot revision
retention, and pre-CPU current-run idle seeding are retained. Two clean signed
package repeats now execute the deterministic 1.502B-cycle workload and
average 16.514/16.575 ms (60.55/60.33 FPS). This materially advances G5 but
does not pass it: p95 is still 18.281/18.259 ms. The next single experiment is
fresh tail attribution on this exact idle-enabled package. Do not retry
scheduler-loop, timer, stale-PGO, package-layout, FPRF-branch, or gather-width
variants. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-packaged-idle-config-retained.md`.

Fresh current-source combat PGO is now causally screened. Candidate A, the
current control, and candidate A2 execute exactly 1,501,757,755 cycles and
51,380,895 dispatches over emulated frames `48123..48562`. PGO cuts
CPU-thread mean by about 4.2 ms and improves total p95 from 18.123 ms to
17.608/17.776 ms, but does not pass 16.7 ms. Disabling precision timing
worsens p95 to 18.227 ms and is rejected. The local profile/module are an
oracle, not a committable product input. Their disassembly proves selective
hot call elimination and internal specialization while `__text` grows; it
does not justify retrying blanket FP inlining, global PSQ loads, cold-symbol
outlining, outer FMA splits, or timer variants. The next single diagnostic is
an optimization-remark/call-site diff to select one previously untested,
semantics-complete common case. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-current-source-combat-pgo-oracle.md`.

That inline diff is complete: 44,741 successful PGO inlines are dominated by
41,671 selectively hot FP-availability sites, with hot threshold 3,000 versus
cold 325/45. Coverage resolved the hottest isolated short long-load to
revision-0 `0x8036E8B4`, but host preflight leaves only about 1 ns/call and
rejects a one-site module build. Do not replace PGO with blanket inlining or a
large derived address list. The validated faster local app is retained as
`build-macos/SsbmPad-PGO.app`; canonical packaging remains reproducible and
unchanged. G5 remains open and G6 blocked.

Fresh pacing controls on that exact PGO app are also complete. A low-overhead
buffered render log independently fails at 17.956 ms p95 / 22.767 ms p99 /
113.255 ms worst, so full phase logging is not creating the gate failure.
VSync moves pacing into Metal but fails at 17.922 ms p95 / 130.294 ms worst;
PresentDrawable-only fails at 17.737 ms p95 / 79.016 ms worst; both also alter
nominal boundary work. A new strict GCD timer passes host p95 at 16.691 ms but
fails p99/worst at 16.712/18.358 ms and is rejected before a game build. Do not
retry VSync, PresentDrawable-only, observer gates, dispatch timer parameters,
or prior sleep/spin variants. A pipelined host Metal harness then passed
600/600 actual `presentedTime` intervals twice at <=16.667 ms with zero drops,
but the live scheduled-present candidate blocked in the drawable path and
failed at 18.022 ms p95 / 132.188 ms worst; fullscreen also failed at
17.493 ms p95. The product edit is removed. Do not retry Metal/display pacing
variants. Next take a fresh no-phase current-PGO CPU sample and select one
coherent remaining compute outlier. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-pgo-pacing-controls-rejection.md`.

The required fresh current-PGO sample is now line-attributed with a disposable
module whose 81,959,380-byte `__text` is byte-identical to the retained PGO
module. Generated samples remain diffuse; the only coherent untried host cost
was JIT-only exception discovery below static gather writes. A
regression-first `FastWrite*`/`FastCheckGatherPipe` candidate preserved write
widths, order, and check cadence, but exact Fountain candidate/control/
candidate p95 was 17.883/17.726/17.843 ms. Its repeated 0.022-0.107 ms CPU-mean
gain is below the 5% threshold and both candidate p95 values regress control.
The product edit and candidate-specific test are removed, and the canonical
runner rebuild matches the reversal control. Do not retry JIT FIFO discovery,
gather-width, or paired-store variants. Next split the ordinary 17-19 ms tail
from the rare 129-132 ms stall and trigger attribution on the latter. Final
Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-static-gather-fast-check-rejection.md`.

The rare-stall split is complete without a product edit. All three prior
129-132 ms rows align to emulated frame `48436`, identical guest work, and a
unique 7.0-8.4 ms Cubeb mix burst. A corrected 90-second rolling System Trace
did not reproduce it; the first trace marker occurred only during profiler
teardown and is excluded. A fresh exact Cubeb/no-output/Cubeb reversal matched
1,501,629,399 cycles and 51,369,928 dispatches. No-output removed mixer work
but worsened p95 from 17.599/17.631 ms to 17.668 ms, p99 to 19.277 ms, and
worst to 27.013 ms. Reject audio removal: G5 requires audio and Cubeb is not
the ordinary tail cause. Current official Dolphin adds no relevant scheduling
fix, and an exact-work `SmoothEarlyPresentation=True` run worsened p95 to
17.700 ms and worst to 31.300 ms. Reject presentation-setting changes and
return to generated-code evidence. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-27/g5-tail-trigger-and-audio-rejection.md`.

The block-level FP screen is also complete and rejected. A per-generated-
chunk successful-check cache retained a CIA-specific gate at every possible
entry and cleared after `mtmsr`; focused semantics and the canonical 1,401-PC
lockstep screen passed. The actual Fountain profile predicted at least 81.0%
fewer helper calls, but linked `__text` grew 16.45%. Exact 385-frame
candidate/control/candidate work matched, while candidate CPU-thread mean
regressed from 16.114 ms to 23.750/23.650 ms and p95 from 18.113 ms to
26.925/26.622 ms. All candidate source is removed. Do not retry per-chunk FP
flags or another branch at every FP instruction. Final Destination and G6
remain blocked. See
`docs/artifacts/2026-08-27/g5-fp-availability-cache-rejection.md`.

PERF-068 is complete and rejected. A CFG-local FP candidate retained exact-CIA
direct-entry gates while moving 72.517% of checks out of sequential bodies.
Its own clean Fountain PGO profile and exact-work candidate/control/candidate
run repeated a 0.236-0.490 ms CPU-mean gain, but total p95 regressed from
17.677 ms to 17.775/17.980 ms and the strict pass share stayed 52.5%. All
candidate source/tests are removed. Do not retry FP gate elision. The next
single step is read-only attribution of the serialization edge that exists in
live Dolphin but not in the already-passing three-drawable host Metal harness;
do not build another presentation setting or timer variant until that edge is
specific and falsifiable. See
`docs/artifacts/2026-08-27/g5-fp-cfg-gate-rejection.md`.

PERF-069 replaces the assumed CPU-side presentation proxy with actual
`MTLDrawable.presentedTime`. On the same M1, PGO module, Metal renderer, Cubeb
audio path, and exact guest work, changing only
`CAMetalLayer.displaySyncEnabled` moved two short brackets from about 53% to
100% at <=16.7 ms and held an exact 440-frame run to 16.666667 ms worst. Raw
M1 throughput is excluded. Full-match worst still fails at 99.999791 ms even
though p95/p99 are 16.666667/16.666709 ms and 99.925% of intervals comply.
Five-timestamp attribution places the rare stalls before Metal; drawable
acquisition itself is about 0.05 ms on the missed frames. Combined-thread QoS,
dual-core mode, foreground activation, and MemoryWatcher backpressure are
rejected. The stripped product policy passes canonical A/B/reverse-A: no-sync
p95 is 18.147/18.561 ms, while synchronized p95/worst are
16.666667/16.666750 ms with 779/779 intervals compliant. Retain it. The
canonical full match still has ten misses and 66.666334 ms worst, so next join
actual gaps to canonical phase counters. Do not retry the rejected scheduling
variants, run Final Destination, or start G6 until Fountain's strict worst
passes. See
`docs/artifacts/2026-08-27/g5-metal-presentation-attribution.md`.

PERF-070 completes that join. After the established two-second warm-up, 6,670
actual canonical intervals align most strongly to phase row `frame - 1`
(correlation 0.674781). The 113 misses average 19.623 ms CPU-thread work versus
16.080 ms for compliant rows and execute about 5% more cycles/dispatches, so
ordinary misses are compute overruns. The 133.333 ms worst is different:
131.944 ms CPU wall versus 31.829 ms CPU-thread exposes about 100 ms off-core.
A default-off `THREAD_TIME_CONSTRAINT_POLICY` screen on the faster PGO oracle
returned success but introduced a 116.665 ms stall into its otherwise-perfect
short bracket; it is rejected and removed without a full match. Do not retry
QoS, priority, dual-core, real-time/time-constraint, timer, or presentation
variants. Next use the PGO oracle for a reproducible data-free compute path or
another causal generated-code change. Final Destination and G6 remain
blocked. See
`docs/artifacts/2026-08-27/g5-phase-join-and-time-constraint-rejection.md`.

PERF-071 closes the private-profile consumption bridge without weakening the
data boundary. `prepare-game.sh` accepts validated private LLVM profile data,
and `package-local-pgo-app.sh` preserves/restores the canonical module pointer,
requires a hash-only manifest, packages, layout-tests, and signs a local app.
A full 247-step current-source build reproduced the retained signed PGO module
hash; a 24-second repeat logged a cache hit; and a deliberate post-selection
packaging failure still restored the canonical pointer. This does not make the
private profile a clean-clone input or pass G5. Next add a repository-native,
data-free local training/merge recipe driven by user-owned inputs, or select
another causal generated-code change. Final Destination and G6 remain blocked.
See `docs/artifacts/2026-08-27/g5-local-pgo-package-workflow.md`.

PERF-072 closes the clean local training/merge gap. A distinct
`--pgo-generate` cache identity and three repository-native scripts build a
signed training app, gate counter reset/dump to revision-0 combat, merge the
private raw output, and feed it through PERF-071 without committing the disc,
extracted game, profile, module, app, state, or private path. The first genuine
local profile matches the prior 6,556-function/2,727,666-block shape. Its
873-count boundary difference changes 127,816 bytes within one generated
function, so the resulting binary remains diagnostic rather than canonical.
A clean equal-work Fountain run reproduces the expected PGO compute class at
16.664 ms mean / 11.621 ms CPU-thread mean, but fails G5 at 18.065 ms p95 and
22.509 ms worst. Next screen IR-level PGO on this exact workload. Do not use
CS-PGO with the installed LTO path (host preflight emits no profile sections),
do not attempt BOLT on Mach-O, run Final Destination, or start G6. See
`docs/artifacts/2026-08-28/g5-local-pgo-training-workflow.md`.

PERF-073 screens and rejects IR-level PGO on the exact PERF-072 workload. A
fresh `-fprofile-generate` ThinLTO module produced a genuine IR profile with
866 post-optimization functions and 3,947,902 blocks; its indexed data drove a
clean profile-use build without mismatch warnings. Exact emulated frames
`48123..48562` matched 1,501,757,755 cycles, 51,380,895 dispatches, 905,756
bursts, and 882 hook fallbacks. IR PGO nevertheless worsened CPU-thread mean
from 11.621 to 12.085 ms, grew `__text` by 2.43 MB, and recorded 18.048 ms p95
and 69.163 ms worst. The temporary compiler/cache-identity edit is restored.
Do not retry whole-module IR PGO. Next use retained profile evidence to select
one bounded hot-region or dispatch-edge transformation. Final Destination and
G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-ir-pgo-rejection.md`.

PERF-074 screens and rejects a profile-derived Mach-O order file on the same
exact workload. Apple `ld` placed `chassis_dispatch`, the common runtime
helpers, and four hot generated regions contiguously without changing the
81,959,380-byte `__text`. Emulated frames `48123..48562` again matched
1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, and 882 hook
fallbacks. CPU-thread mean improved only 0.083 ms / 0.714%, while total mean
regressed to 16.852 ms, compliance remained 55.682%, and worst rose to
133.107 ms. The temporary linker/cache-identity inputs are restored. Do not
retry global layout. Next measure and eliminate one specific frequent
dispatcher edge with focused semantics first; preserve every fallback and SMC
boundary. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-order-file-rejection.md`.

PERF-075 attributes and screens ten frequent cross-chunk linked calls from the
exact Fountain workload. A sampled predecessor/destination stream reconstructs
the hot `0x8036C87C..0x8036C944` sequence. Focused tests failed before direct
continuation, then passed normal and 256-cycle-budget exits. ThinLTO emitted
real direct arm64 calls, reducing exact-window dispatches from 51,380,895 to
46,668,247 (9.17%), but CPU-thread mean improved only 0.136 ms / 1.17%; total
mean and compliance did not improve, and G5 tails still fail. The safety audit
also proves nested cross-chunk calls bypass the runtime's forced-fallback and
SMC target-verification check. The address-specific candidate is removed. Next
prototype a cheap target-validity guard and require a failing invalidated-callee
regression before screening broader statically known calls. Final Destination
and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-hot-direct-call-rejection.md`.

PERF-076 safely generalizes the cross-chunk experiment and rejects an
out-of-line callback guard on every linked edge. Focused tests cover denied
target, accepted target, exact 256-cycle exit, post-callee continuation
invalidation, and terminal return. The full module emitted 67,012 guarded call
sites across all 237 chunks; arm64 contains real direct calls. A load-time CPU
state size check caught a missing public ABI mirror before boot, and the
corrected isolated app preserved that check. In exact Fountain combat,
dispatches fell 69.05% from 51,369,928 to 15,897,417. A clean profile-free
pair nevertheless improved CPU-thread mean only 0.260529 ms / 1.66%, grew
`__text` 12.79%, reduced compliance, and retained an 18.677 ms p95 / 128.024
ms worst. The callback design is removed; the canonical pointer is restored.
Next preflight a data-only inline validity representation with no per-edge
callback, and build it only if the focused projected gain can exceed 5%. If
that fails, form profile-derived superblocks with guards only at trace
boundaries. Do not retrain or retry the callback design. Final Destination and
G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-guarded-direct-call-rejection.md`.

PERF-077 also rejects the broad inline-table alternative without spending a
game build. A retained host model matches the callback's arm64 control shape
and the full target/callee/continuation sequence. Repeated runs with 32 million
edges per representation project at most 0.481 ms additional saving; combined
with PERF-076, that is
only 4.72% versus the required 5%. Do not retry per-edge guards or change the
product ABI. Next form one profile-derived `8036C8D8..8036C91C` superblock,
guard only its boundary, and require static safety exclusions plus a focused
generated regression before a live build. Final Destination and G6 remain
blocked. See
`docs/artifacts/2026-08-28/g5-inline-validity-preflight-rejection.md`.

PERF-078 proves the boundary-trace control contract but rejects dispatch-only
trace chaining. The focused regression passes invalidated entry, fallback,
completion, successor miss, exception, and exact cycle-budget paths; the
selected generated ranges contain no cache-control or indirect-system hazard.
The seven-node trace nevertheless covers only 5.16% of dispatches and projects
about 0.076 ms/frame. A 278-edge forest reaches only a zero-overhead 5.37%,
with 204 edges needed merely to cross 5%. Do not build it. Next preflight one
genuinely merged generated region and require material arm64 load/store and
host-cost evidence from keeping guest state live. Final Destination and G6
remain blocked. See
`docs/artifacts/2026-08-28/g5-dispatch-trace-coverage-rejection.md`.

PERF-079 proves that a genuinely single-entry generated region lets AppleClang
retain guest state, but rejects the selected small slice. The exact
`0x8036C91C..0x8036C934` model passes 4,096 randomized full-state/RAM cases,
removes 31 arm64 instructions and 13 branches, and repeats a 21.29-21.79% local
speedup. Its absolute saving is only 1.216-1.264 ns: about 0.001 ms/frame at the
sampled site and less than 0.148 ms/frame even if every native dispatch received
the same saving. Do not build or broadly clone tiny regions from relative
microbenchmark percentages. Next map inclusive current-PGO host samples back to
guest PCs and form one larger, genuinely expensive single-entry region with
exact exception, cycle-budget, SMC, and fallback exits. Final Destination and
G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-merged-state-preflight-rejection.md`.

PERF-080 maps the retained byte-identical line sample to guest PCs and closes
the single-hot-region hypothesis: after two independently rediscovered but
already-closed clusters, the largest new region owns only 3.40% of chassis
samples. PERF-081 narrows and executes that complete function. Entry narrowing
alone is neutral; explicit live GPR/FPR/PS1 state plus one exact FP gate passes
4,096 randomized FP-disabled/cycle-boundary cases and repeats a 9.70-10.92%
local gain, but projects only 0.33-0.37% overall. Do not build one-function
address lists. See `docs/artifacts/2026-08-28/g5-guest-cost-attribution.md` and
`docs/artifacts/2026-08-28/g5-single-entry-register-cache-preflight.md`.

PERF-082 rejects the existing broad LLVM backend after enabling LLVM 22/Apple
ARM64 and passing focused semantics. The exact `0x80323940` hot slice measures
396,548 LLVM text bytes versus 64,756 for C and repeats 4.84-4.93 times slower
with identical CPU/RAM results. Common-exit and stock-O2/Oz screens are worse.
The private full run stopped at 130/947 objects before module link; the C
product remains canonical. A future LLVM design must first compact duplicated
runtime-boundary materialization and beat this retained slice before another
game build. See
`docs/artifacts/2026-08-28/g5-llvm22-arm64-preflight.md`.

PERF-083 refreshes the signed canonical Fountain state and confirms the strict
tail still fails despite a coherent 60.0-FPS title reading: the exact 440-field
interval is 16.814891 ms mean / 18.761260 ms p95 with only 56.3636% at or below
16.7 ms. The researched next route is a bounded generated-C extended basic
block with explicit live guest-state locals and exact synchronization at
helper, exception, SMC, forced-fallback, host-call, and normal exits. First run
a data-free full-state/RAM preflight and require a greater-than-5% projected
CPU-thread gain; do not build a game module from a relative microbenchmark
alone. See
`docs/artifacts/2026-08-28/g5-static-recomp-structural-followup.md`.

PERF-084 rejects leaf-only state caching before a generator or game build.
Complete call classification over two retained Fountain line profiles leaves
only 14.293349-17.302565% of mapped generated cost in unclosed no-call spans.
That requires a 28.897-34.981% local gain before synchronization overhead,
well above PERF-081's 9.70-10.92% real-function result. Keep the broader state-
retention objective, but the next preflight must cross a real guest-call
boundary: start with parent `0x80377B6C..0x80377CE4` and its mutually exclusive
calls to `0x803408A0`. Do not modify DolRecomp or build a leaf-only module. See
`docs/artifacts/2026-08-28/g5-function-family-coverage.md`.

PERF-085 follows the exact parent/callee boundary and proves
`0x803408A0..0x803408D0` is an optimizable paired-single matrix copy. A 20,000-
case full-state/24-MiB-RAM differential passes and local time improves 67.70%,
but copy owns only 0.059158%/0% of two retained Fountain profiles. Combining it
with the adjacent proven concat kernel at zero wrapper cost projects only
2.55%/3.53%. Reject the two-address chunk wrapper before a module build. The
next state-retention representation must aggregate several high-cost callful
families; do not retry another isolated SDK leaf. See
`docs/artifacts/2026-08-28/g5-matrix-copy-family-preflight.md`.

## Active G5 runnable-descheduling/prewarm sub-loop (2026-08-28)

PERF-104 proves a natural 74.579 ms Fountain frame is a runnable-thread
descheduling event: CPU-thread work is 21.186 ms and the wall/thread gap is
52.940 ms. PERF-105's marker-aligned System Trace finds fragmented higher-
priority host contention, but profiler-specific attribution remains caveated.
Stop treating the remaining severe natural tail as static-recompiler work.

PERF-106 through PERF-113 identify and close a separate deterministic cold-
bundle hitch. The exact EFB-to-VRAM UIDs are R4, RGBA8, XFB, and half-scale
XFB. The first three cost about 108-118 ms cold; the fourth costs 1.036 ms.
Patch 0020 prewarms all four existing pipelines. PERF-113 proves zero combat
EFB misses through frame 51604. Retain the patch and packaged opt-in.

PERF-112's complete prewarmed match still measures 17.584 ms p95, 18.540 ms
p99, and 48.962 ms worst. The first captured 41.385 ms stall loses 25.619 ms
off-core while remaining runnable and spends 14.809 ms around
`PresentBackbuffer`; it is not static-recompiler work. The next single
experiment is a prewarmed Game Mode on/off reversal launched through
LaunchServices, now that cold pipeline compilation cannot confound the worst
frames. Do not retry compiler flags, QoS, time-constraint, timer, drawable-
lifecycle, or isolated generated-leaf variants. Do not run Final Destination
or start G6 until Fountain's strict p95 and worst pass. See
`docs/artifacts/2026-08-28/g5-runnable-descheduling-and-efb-prewarm.md`.

PERF-114 through PERF-116 complete the prewarmed Game Mode on/off/on reversal.
All three 6,723-frame Fountain spans have exactly matched guest work and zero
EFB misses. Confirmed Game Mode measures 17.288/17.462 ms p95 and
24.337/24.381 ms worst with zero >33 ms frames; the off reversal measures
17.725 ms p95 / 179.211 ms worst with six >33 ms frames. The real signed
wrapper-parent/runner-child product topology also activates Game Mode when the
runner enters fullscreen. Retain fullscreen as the fresh-install default and
the user opt-out toggle. This is a severe-tail mitigation, not a G5 pass.

The next single experiment must measure synchronized actual display cadence
under Game Mode without adding `MTLDrawable.addPresentedHandler`, which is a
known queue-changing observer. Do not retry QoS, time constraints, timers,
dual-core, drawable lifecycle, or static compiler flags. Final Destination and
G6 remain blocked until Fountain worst actual interval is at most 16.7 ms. See
`docs/artifacts/2026-08-28/g5-prewarmed-gamemode-reversal.md`.

PERF-117 through PERF-124 complete that actual-display measurement and ingest
the supplied PERF-106 crash report. A custom Display-only Instruments template
observes the WindowServer surface stream without the rejected in-process
drawable callback. PERF-124 retains 6,862 consecutive SsbmPad display
intervals over 114.964458 seconds: p95/p99 are both 16.666417 ms, but 15
intervals are 33.333 ms and one match/results transition is 366.660 ms. Sixteen
intervals exceed 16.7 ms, including misses during combat, so ordinary output is
genuinely near 60 Hz but strict G5 still fails. Exact combat frames
48123..54845 have zero EFB misses. PERF-122 separately reproduced the report's
SIGTRAP by consuming an opt-in state-load request while Core was Starting.
Patch 0013 now leaves state requests pending until Running or Paused, and
PERF-123 passes the same signal-at-emulated-frame-zero regression. Retain the
guard. Next separate the guest's approximately 59.94 Hz phase slips from true
late work with a shared observer timestamp. Do not alter guest speed, present
duplicate stale content as new frames, or retry timer, scheduler, drawable, or
broad compiler variants. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-external-display-cadence-and-savestate-startup.md`.

PERF-126/127 finish the shared-clock and logger-free controls. Default-dormant
patch 0021 timestamps phase frame ends in the same absolute host clock as the
Display trace. Seven pre-results queued surfaces were not displayed over about
110 seconds, closely matching the 6.6 conversion holds predicted by 59.94 Hz
guest output on this Mac's fixed 60.0 Hz, non-VRR panel; representative GPU
work completed before the next VSync. Separate no-queue gaps are genuine
producer stalls and include a 144.530 ms phase with only 19.900 ms CPU-thread
work. PERF-127 removes phase logging entirely and reproduces 16 ordinary
33.333 ms holds plus one 399.993 ms results transition, while p95/p99 remain
16.666417/16.666458 ms. Strict G5 remains open. Do not speed the guest,
duplicate stale content, or retry rejected pacing/drawable/timer/scheduler/
compiler variants. Next isolate repeated missing present-command-buffer
assignments from downstream queue drops and change only a proven producer-side
cause. Final Destination and G6 remain blocked. See
`docs/artifacts/2026-08-28/g5-host-time-join-and-logger-free-cadence.md`.

PERF-128 closes the fixed-rate classification independently. The host-only
three-drawable Metal harness passes 120/120 unpaced 60 Hz intervals, then
produces exactly six 33.333 ms holds over 6,600 intervals when paced at
16.683 ms, with 16.666667 ms p99 and no callback loss. This is the predicted
59.94-to-60 conversion without Dolphin or guest code. Do not optimize or hide
these holds. Continue G5 only from no-queue producer stalls and the results
transition.

PERF-130/131 classify the approximately 400 ms match/results hold as 27
intentional guest VI fields without a new XFB. Three natural runs converge on
emulated frame 54872 with exactly 211,892,535 cycles, 14,356,543 dispatches,
and 17,393 bursts in one output row; the preceding output is frame 54845.
CPU-thread cost stays below the per-field budget and the remainder is throttle
sleep, while video/Metal work is negligible. A targeted Time Profiler trace
confirms generated guest execution. Do not synthesize stale output or optimize
the renderer/cache-control path for this guest transition. Continue G5 only
from the separate pre-results no-queue producer stalls. See
`docs/artifacts/2026-08-28/g5-results-transition-classification.md`.

PERF-129 rejects Rush Frame Presentation. Candidate/control frames
48123..52195 execute identical guest work, but the 45-second actual Display
window worsens from four to ten 33.333 ms holds, doubles CPU-thread rows above
16.7 ms from 13 to 26, and increases `nextDrawable` stalls above 10 ms from two
to four. The existing post-render sleep averages only about 0.000043 ms, so
moving it has no budget to recover. No-Instruments Game Mode controls contain
no acquisition stall above 10 ms, establishing that the Display observer adds
tail cost. Remove/reject the private candidate; do not retry Rush or redesign
drawable lifecycle from observer-specific waits. PERF-130/131 supersede the
proposed transition follow-up. See
`docs/artifacts/2026-08-28/g5-rush-frame-presentation-rejection.md`.

PERF-135 removes the stale sequencing block on the second required stage. A
visually verified, fullscreen current-PGO Final Destination match completes
coherently with Cubeb audio. Its conservative 2,801-frame interior combat
window measures 16.683246 ms mean / 17.209583 ms p95 / 17.399125 ms p99 /
24.292208 ms worst, with no frame above 33 ms. This is materially better than
the old portable-PGO baseline but still fails strict G5; Fountain is not the
only remaining producer-tail scene. A private hashed Final Destination state
is retained. Next phase-attribute the 24 ms class from that state and compare
it to Fountain's proven runnable/off-core tail. Do not repeat rejected
compiler, QoS, timer, dual-core, drawable, or presentation variants, and do
not start G6. See
`docs/artifacts/2026-08-28/g5-current-final-destination-baseline.md`.

PERF-136/137 then phase-attribute that current Final Destination class. Two
exact 2,001-frame combat windows retain essentially identical 17.150/17.148 ms
p95. CPU-thread p95 is only 6.729/6.749 ms and audio p95 is 1.311/1.313 ms.
Their 27.641/30.737 ms worst frames execute just 4.148/2.590 ms on-core and
lose 19.609/24.645 ms off-core, with negligible video build. Repeating after
the transient `fseventsd`/Brave load cleared leaves the mechanism and
distribution intact, so that activity is rejected as the cause. Final
Destination and Fountain share a runnable/descheduling tail, not an M1
compute, static-recompiler, GPU, audio, or timer ceiling. Do not repeat those
routes. Continue only with a genuinely new host-scheduling mechanism, an
authorized reversible background-load isolation, or actual-display evidence.
G5 remains open and G6 remains blocked. See
`docs/artifacts/2026-08-28/g5-final-destination-off-core-reversal.md`.

PERF-138 through PERF-140 test whether hidden blocking/system activity inside
SsbmPad explains that wall-minus-thread loss. macOS has no supported
per-thread context-switch counter, so default-dormant patch 0022 records one
supported task-event snapshot per presented frame. The first per-CPU-slice
placement generated hundreds to thousands of Mach queries per frame and is
explicitly excluded. The corrected one-per-frame query costs about 0.66
microseconds mean / 0.71 microseconds p95 in 100,000-call preflights. In a
visually bounded Final Destination combat interval, the exact 2,001 rows
measure 18.717 ms p95 / 21.867 ms worst. Misses have more off-core time but
fewer task context switches and fewer Mach/Unix syscalls; whole-process
blocking activity is rejected, while host execution loss is strengthened.
Do not retry compiler, timer, priority, workgroup, display-link, or renderer
routes. The next causal test is an explicitly authorized, reversible Logitech
updater isolation. G5 remains open and G6 remains blocked. See
`docs/artifacts/2026-08-28/g5-task-event-attribution.md`.

PERF-141 completes the explicitly authorized Logitech updater isolation. With
the exact root-owned updater stopped at 0% CPU, the same retained Final
Destination state improves from 18.717 to 17.195 ms p95, from 19.466 to 17.365
ms p99, and from 21.867 to 17.975 ms worst; frames above 20 ms fall from ten to
zero. Mean remains 16.683 ms and only 57.571% of frames meet 16.7 ms. Logitech
can aggravate intermittent severe stutter but is not the fundamental G5
limiter. The user directed that it remain stopped, so no A/B/A reversal or
exclusive-causality claim is made. Retain no product change and continue from
the residual required-stage pacing failure; G6 remains blocked. See
`docs/artifacts/2026-08-29/g5-logitech-updater-isolation.md`.

PERF-142 then measures the other required stage with that updater still
stopped. Fountain's exact 2,001-frame combat window averages 16.677958 ms but
only 52.424% of rows meet 16.7 ms; p95 is 17.542125 ms and one off-core stall
reaches 34.499292 ms. Fresh endpoints show coherent Pikachu/Fox combat and no
fighter-morph recurrence. PERF-143/144 use byte-identical symbolized code to
test the first unclosed sampled function family. `func_80339940` accounts for
only 106/2,031 active recompiler top-of-stack samples, and those samples are
diffuse: the hottest individual source line has three samples. Reject a local
rewrite before build. Continue only from a shared operation with at least 5%
fresh projected coverage; G5 remains open and G6 remains blocked. See
`docs/artifacts/2026-08-29/g5-fountain-stopped-updater-and-symbolized-sample.md`.

PERF-145/146 remove the detailed phase observer from two current-PGO Fountain
repeats and use only Dolphin's buffered presented-frame logger. Their exact
final 2,001-row windows repeat 59.999944/59.999746 FPS mean, 16.780083/16.784000
ms p95, and 19.897333/19.996833 ms worst. The earlier 34.499 ms severe tail is
not observer-free, but strict G5 still fails. Each residual worst is followed
by a compensating 13.4-13.5 ms interval, so the remaining mechanism is
delayed/catch-up presentation pacing rather than sustained guest compute.
Fresh guest-cost attribution also finds no unclosed local implementation above
the 5% gate. Do not use detailed phase traces as product-speed claims or reopen
closed codegen/pacing routes. Next obtain actual drawable-presentation cadence
without changing scheduling; G6 remains blocked. See
`docs/artifacts/2026-08-29/g5-low-overhead-fountain-pacing-reversal.md`.

PERF-147/148 then observe current actual drawable presentation without phase
logging. Their final 2,001 intervals measure 16.666750/16.666792 ms p95 and
16.666792/16.666833 ms p99, so Metal absorbs almost all app-side jitter. The
strict worst still fails at 33.333375/33.333500 ms, with three/two exact missed
refreshes and zero dropped callbacks. Every miss was registered on time
(16.596-16.792 ms registration gaps) after a 3.955-5.745 ms drawable acquire;
the producer did not arrive one refresh late. The callback may perturb the run
and was removed, but historical actual-display evidence independently retains
misses. Next distinguish GPU readiness from compositor-only deferral using
command-buffer timestamps without changing scheduling. G6 remains blocked.
See `docs/artifacts/2026-08-29/g5-current-actual-presentation-deferral.md`.

PERF-149/150 add in-memory command-buffer and GPU timestamps without changing
presentation scheduling. A short 2,001-interval screen passes with a
16.666749 ms worst, but a 95.884-second Fountain combat window contains nine
33.333 ms actual intervals. At every miss the present record was registered
12.397-32.797 ms early and GPU work completed 10.408-30.918 ms before the
skipped refresh deadline; combat GPU duration is only 1.565649 ms mean and
2.522875 ms worst. GPU/render lateness is rejected: macOS deferred already-
ready frames, consistent with the independently proven approximately 59.94 Hz
guest to fixed 60.0 Hz panel conversion. The observer is not used to claim a
miss rate, only ordering. It was removed and the canonical runner rebuilt
without its marker. G5 remains open; do not reopen renderer or presentation
variants. The next candidate must preserve deterministic guest/audio/netplay
timing and produce a distinct frame each refresh rather than duplicating stale
content. G6 remains blocked. See
`docs/artifacts/2026-08-29/g5-gpu-readiness-and-display-deferral.md`.

PERF-151/152 then audit the acceptance boundary instead of treating every
unique-surface hold as a compute miss. GALE01's VI cadence derives exactly to
`60000/1001` (16.683333 ms), while every current built-in display mode is
60.000000 Hz. The observer-free PERF-127 stable window queued 4,794 surfaces,
displayed 4,788, and held six versus a five-hold conversion expectation.
Actual display evidence remains necessary, but a proven ready-frame conversion
hold cannot alone replace D2's guest-work test. A lightweight in-memory
presenter-entry split retained 1,091 complete combat intervals before a disk-
full shutdown truncation. Thread CPU stayed below budget at 12.758 ms p95 /
14.735 ms worst and all three >20 ms wall rows were off-core. Use this only for
mechanism attribution; disk pressure excludes its wall distribution. The
observer is removed and canonical runner rebuilt. G5 remains open on genuine
producer intervals above 16.7 ms; recover disk headroom before a new causal
host-descheduling experiment. Do not change VI/audio/netplay timing or count
stale duplicates as new frames. G6 remains blocked. See
`docs/artifacts/2026-08-29/g5-ntsc-display-boundary-and-light-producer-tail.md`.

PERF-153/154 then correct a host-side measurement contaminant. With identical
canonical app/module/state/input, streaming every `gcpipe.py` step through the
live Codex session produced five 33 ms and one 30 ms gaps in the final 2,001
rows. Redirecting only that output to `/dev/null` removed all 30-33 ms gaps and
restored a 16.666653 ms mean / 60.000049 FPS. This is a harness correction, not
a product optimization: quiet p95 remains 16.796250 ms and strict worst still
fails at 22.544875 ms. The two >20 ms rows are delayed/catch-up pairs. Future
performance input must be quiet. No unrelated user process was stopped; any
host-contention reversal needs explicit authority. G5 remains open and G6
blocked. See
`docs/artifacts/2026-08-29/g5-quiet-input-harness-reversal.md`.

PERF-165/167 then close two remaining product-local questions. Apple's XNU
source identifies `THREAD_LATENCY_QOS_POLICY` as timer-coalescing QoS, and
user-interactive QoS already selected tier 0 in the rejected prior reversal;
do not relabel it as a new CPU scheduler mechanism or retry timer policy.
With both the updater and the Options+ agent stopped at 0% CPU, a valid quiet
one-process Fountain window measures 16.675053 ms mean / 16.794959 ms p95 /
33.249209 ms worst. Its body is unchanged and its tail is worse than PERF-154,
so the remaining Logitech agent is not the fundamental limiter. A separate
framebuffer replay proves coherent Pikachu/Fox combat from 1:48.24 to 1:33.83
with no real-mesh recurrence. No product edit remains. Further unrelated
background-load isolation requires explicit reversible authorization; do not
infer causality from process-name CPU spots. G5 remains open and G6 blocked.
See
`docs/artifacts/2026-08-29/g5-latency-qos-and-logitech-agent-isolation.md`.

## Testing rhythm

PERF-196 completes exact guest-PC attribution for the warm static-core class.
Five warm CPU overruns contain 175 one-in-4,096 samples versus 146.46 expected;
`0x80360000..0x8036FFFF` explains 64.4% of their excess, but no single PC
dominates. Those PCs are the already-closed PERF-075 HSD/GX family, so another
direct-call, trace, merged-state, register-cache, LLVM, or structural rewrite
would repeat a rejected mechanism. Observer-free images also correct an
initial near-misclassification of Fountain background art: fighter meshes are
coherent, while the separate lower-floor reflection smear remains open. Keep
G5 open and continue from a genuinely new observer-light compute/wall-tail
mechanism; do not start G6. See
`docs/artifacts/2026-08-29/g5-warm-dispatch-region-rejection.md`.

PERF-195 closes the warm-overrun subsystem attribution without weakening G5.
Exact emulated-frame identity joins all 7,431 warm Fountain combat records to
phase timing and places all eight combined-thread CPU overruns in static-core
compute, with elevated native-dispatch and guest-cycle counts. Metal, audio,
EFB traffic, and fallback handling are rejected for this class. The trace is
observer-bearing and therefore cannot satisfy acceptance. Continue G5 by
using the retained one-in-4,096 dispatch/frame sampler to name guest-PC regions
enriched in those exact overrun frames, then verify any causal change with the
observer-light recorder. See
`docs/artifacts/2026-08-29/g5-warm-static-core-attribution.md`.

PERF-233/234 close the next iOS row-7 attribution branch. Persisted shader
cache state improves startup but does not prevent 42-55 and 47-52 FPS resource
windows. Live E1 counters then confirm 132.1 million hook fallbacks versus
12.6 million native bursts, but refute the audit's narrow `mtspr` priority:
130.9 million are cache operations and only 1.19 million are `mtspr`.
Regenerating the exact source with the retained cache-control backend moves all
cache work to direct helpers and cuts hook fallbacks 98.98%. The profile-free
candidate still falls to 33-50 FPS and is rejected as a product build because
it lacks the legacy module's fresh combat PGO. Next train and strict-use a
fresh profile on the regenerated cache-direct source, combine it with retained
host PGO, and judge per-interval FPS/underruns. Do not apply the stale legacy
profile or specialize `mtspr` first. Row 7 remains open. See
`docs/artifacts/2026-08-30/g8-ios-cache-prewarm-rejection.md` and
`docs/artifacts/2026-08-30/g8-ios-fallback-counter-cache-source-reversal.md`.

PERF-235 closes row 7 without weakening its written boundary. A fresh
cache-direct corpus profiles 6,556 functions and 239.7 million dispatches;
strict-use compilation passes all 237 generated chunks. The resulting module
paired with retained host PGO still fails when CPU and video share one worker,
so cache-direct PGO alone is rejected. An iOS-only CPU/video split plus three
shader compiler workers changes the live mechanism: after a bounded cold
creation burst, callbacks continue, the DMA queue recovers, and underruns stay
flat through sustained heavy work. A clean rebuilt app with both private INI
overrides removed proves the settings are source-integrated; warm 686-705-draw
combat holds 59.9 FPS/VPS with only three isolated transition underruns. This
satisfies PRD row 7's no-*sustained*-underrun requirement, not a zero lifetime
counter or an iPad locked-60 claim. Keep the remaining Simulator presentation
hitch open; next use the new comparison floor for a bounded Metal binary-
archive/pipeline-persistence reversal, while G8 execution moves to partial
rows 9-11. See
`docs/artifacts/2026-08-30/g8-ios-cache-direct-dual-core-audio.md`.

STABILITY-236 retracts PERF-235's unsafe dual-core acceptance and re-closes
row 7 on the single-core product path. The dual-core app crashed after 139.4
seconds with a malformed FIFO command and `SIGTRAP` in the Video thread's
`OpcodeDecoder::RunFifo<false>`. Removing only `MAIN_CPU_THREAD` while retaining
three shader workers produced a 22-minute-44-second run across combat, menus,
results, and lifecycle: 135 performance rows, continuing audio callbacks,
59.9 FPS/VPS at the final interval, long flat-underrun runs, and zero FIFO,
desync, fatal, or crash matches. Short digital presses are now latched until
the emulated pad samples them. The visible overlay drove every Melee control in
a live Onett match, so row 9 passes. Simulator-forwarded controllers now hide
the overlay instead of being compiled out, but row 11 remains partial until an
actual live disconnect/reconnect is observed. Continue G8 with rows 10 and 11;
do not re-enable Dolphin dual-core. See
`docs/artifacts/2026-08-31/g8-ios-single-core-stability-and-touch-input.md`.

MENU-237 passes G8 row 10. A verified private backup made the destructive
boundary recoverable; the live `Remove Stored Game Data` confirmation stopped
the runtime, removed only `GameData`, preserved the separate memory-card path,
and exposed the legal first-run chooser. `Import from SsbmPad Folder` then
validated, copied, extracted exactly 1,209 files, atomically activated the
pinned image, and visibly rebooted with zero staging leftovers. The temporary
Files source was removed, the private backup remains outside Git, and the
restart-required performance toggle was exercised on/off and restored to off.
Together with G7, import, and diagnostics evidence, every menu entry now
functions. Row 11 is the sole non-waived partial row. See
`docs/artifacts/2026-08-31/g8-menu-system-remove-reimport.md`.

PERF-238 reopens G8 row 7 and retracts the physical-iPad-candidate
interpretation of STABILITY-236. The user's first manual Simulator run visibly
showed Fountain gameplay at 21.9 FPS. The matching runtime intervals fell from
42.2/42.3 FPS/VPS through 34.0/33.7 to 20.2/19.8, then the sampled interval
held only 21.5-24.1 FPS/VPS while DMA underruns rose from 913 to 1,240. This is
a sustained emulation-speed failure, not an isolated presentation hitch. The
eight-second sample places 1,756/2,604 CPU-GPU-thread samples in
`StaticRecompCore::Run` and 1,648 below `chassis_dispatch`; a final 59.9
interval from a long mixed-scene run cannot override this exact failure.
Simulator gameplay is not currently playable and the build is not ready for
physical-iPad promotion. See
`docs/artifacts/2026-08-31/g8-ios-fountain-20fps-retraction.md`.

PERF-239 makes the row-7 loop phase-specific and rejects unverified PGO
training. In one unchanged process and with the same product/module hashes,
Fountain and Stage Clear exhausted the CPU-GPU thread at roughly 20-48 FPS,
while the next Classic stage held 60.0 FPS/VPS with 232/2,604 sampled ticks in
`PrecisionTimer::SleepUntil`. The deficit is therefore workload-specific, not
a blanket M1 or Simulator ceiling. The existing module profile gives zero
function-entry counts to three chunks observed in the slow sample, which makes
representative coverage a falsifiable next mechanism, not a conclusion. A
fresh instrumented attempt was rejected before merging: it reproduced severe
opening/attract slowdown, but the automation never entered the requested
Fountain trigger and all inspected target counts were zero. Restore the exact
normal module and do not build from that capture. See
`docs/artifacts/2026-08-31/g8-ios-phase-specific-profile-gate.md`.

PERF-242 rejects the corrected Fountain-composite PGO candidate before a full
acceptance route. The exact Fox/CPU-DK Fountain control itself averages only
41.772 FPS with a 17.0 minimum and +790 DMA underruns. On a same-publisher
normal-route screen, the candidate then regresses the first ten intervals from
47.820 to 35.210 mean FPS, lowers mean speed ratio from 0.810 to 0.609, and
adds more underruns. The exact candidate route did not complete, so no exact
Fountain improvement is claimed; the independent route regression is enough
to fail candidate integrity. Restore control `af1364e6...` and do not spend a
full route on this candidate.

PERF-243 narrows that failure to an instruction-front-end direction without
promoting a flag. Candidate ThinLTO grows module text 2.091% and expands the
three newly trained generated functions 4.35-27.15% while sharply reducing
calls, consistent with aggressive helper inlining. Unroll suppression is an
exact no-op and a blanket inline clamp grows bounded mini-links, so both are
rejected. A valid four-second Instruments UI trace of separate visible 31.1
FPS four-character Brinstar gameplay reports 42.22% instruction-delivery,
21.22% processing, 6.66% discarded, and 30.03% useful cycles for SsbmPad PID
75863. This proves crowded-combat front-end pressure on the M1 host, not the
literal Fountain ratio or iPad-device performance. Next test strict PGO
generated chunks as native non-ThinLTO objects while retaining ThinLTO only
for small runtime helpers; require structural shrinkage before a fixed
Fountain reversal. See
`docs/artifacts/2026-08-31/g8-ios-fountain-profile-rejection-and-front-end-attribution.md`.

PERF-244 rejects the mixed-LTO follow-up despite a decisive structural pass.
Compiling all 237 strict-profile generated chunks as native non-LTO objects
shrinks module text 25.967% and the three named function spans 2.28-24.35%,
while preserving ABI, minimum OS, signing, and bounded runtime integrity. The
first ten live intervals nevertheless collapse to 20.570 mean / 10.4 minimum
FPS, 0.340 mean speed ratio, and +425 underruns; visible four-character
Fountain reports 23.3 FPS. The candidate is about 57% worse than the bounded
control mean and does not earn a full route. Restore control `af1364e6...`.
Instruction-delivery pressure remains measured, but footprint reduction alone
is refuted. Before another module build, split the control's delivery class
with available cache/fetch and branch/discard counters on visually confirmed
four-character Fountain. See
`docs/artifacts/2026-08-31/g8-ios-mixed-lto-rejection.md`.

PERF-245 provides a literal-Fountain process-filtered split without promoting
a new binary. A guarded private-pipe route visibly reaches P1 Yoshi versus
level-1 CPU Zelda on Fountain at 47.7 FPS. A rolling 4-second Instruments Run
2 filtered to SsbmPad PID 88916 reports 41.74% instruction-delivery latency
versus 7.35% delivery bandwidth across 5,881,669,124 cycles. This confirms
latency-dominated instruction delivery on a lighter stage-matched workload,
not four-character acceptance. The unguarded automation attempt is discarded
because the normal 60 Hz publisher overwrote its pipe commands; private pipe
routes must set `SSBMPAD_EXTERNAL_PIPE_INPUT=1` before launch and restore it
afterward. Before another module build, repeat matched Fountain windows with
instruction-address-translation and discarded-sampling modes. See
`docs/artifacts/2026-08-31/g8-ios-fountain-instruction-delivery-latency.md`.

PERF-246 adds a second normal-product failure that the loop must not hide. A
cold launch driven through the visible touch overlay reached the title, menus,
and character select without a savestate or private input mode. During normal
front-end transitions the runtime fell through 51.0 and 49.1 FPS while DMA
underruns rose 10 -> 41, then a later transition presented 52.6 FPS and raised
underruns to 54 before the stable screen recovered. This run did not reach a
valid matched Fountain setup, so it does not replace the user's 21.9 FPS combat
control. It proves that moving opening/menu content must be judged separately
from combat and that warmed CSS/idle recovery cannot pass the route. See
`docs/artifacts/2026-08-31/g8-ios-normal-launch-menu-failure.md`.

PERF-247 repairs the state-gated Simulator harness without changing product
performance. The iOS core already compiled MemoryWatcher, but its 232-byte
socket path exceeded Darwin's 104-byte `sockaddr_un.sun_path` and was silently
truncated to a directory. A Simulator-only explicit user-directory override
now accepts only a short symlink resolving to the exact normal app directory
and only when the resulting socket fits. A live client received
`80477D68=00000000` and cleared its first predicate in 0.57 seconds. Normal
launches do not set the override. This enables exact route calibration but is
diagnostic evidence only; it changes neither row 7 nor the FPS baseline. See
`docs/artifacts/2026-08-31/g8-ios-memorywatcher-short-path.md`.

PERF-248 makes the controlling route exact and rejects elapsed-time cursor
automation. The user's workload is **P1 Samus versus level-1 CPU Kirby in a
four-stock, 5:00 match on Fountain of Dreams**; four-stock means four stocks,
not four fighters. A warm calibration reached the correct roster and literal
stage, but still used the default two-minute time rules, while two cold timed
cursor attempts either remained on blank CSS or selected Link. Simulator
reboot also reset the manually corrected Stock/04/05:00 rules. Historical
revision-1.02 libmelee cursor/player addresses did not yet correlate with the
pinned revision-1.00 visible state, so they are candidates rather than route
facts. Before another module build, derive and test the revision-1.00 fields,
make `gcpipe.py` steer and verify from observed guest state, and prove two cold
exact-route traversals. Only then collect address-translation and discarded-
sampling counters on the visible slow phase. See
`docs/artifacts/2026-08-31/g8-exact-route-state-calibration.md`.

PERF-249 satisfies that calibration prerequisite but does not improve row 7.
Revision-1.00 guest-state feedback verifies Samus, level-1 CPU Kirby,
Stock/04/05:00, literal Fountain slot 8, and combat entry. Two fresh processes
rendered the exact match at only 45.2 and 36.4 visible FPS. Preserve both as
fresh failures and retain the user's lower ordinary-route 21.9 FPS as the
control floor. The next loop step is matched instruction-address-translation
and discarded-sampling evidence from this exact combat interval; do not build
another module or promote the app first. See
`docs/artifacts/2026-08-31/g8-r0-exact-route-reproduction.md`.

PERF-251 completes the requested counter split and refines the loop around the
visible failure. On the exact state-verified Samus/level-1-CPU-Kirby,
Stock/04/05:00 Fountain route, a process-filtered instruction-address-
translation sample reports 1.603 billion cycles, 13.789 million L1I demand
misses, 6.314 million L1I TLB misses, 3.172 million L2 TLB misses, and 3.225
million instruction-fetch walks. A separate valid discarded-sampling run
reports 1.674 billion cycles, 7.755 million incorrectly predicted branches,
and 253,939 unpredicted memory dependencies. The branch samples are spread
across generated functions, `chassis_dispatch`, `RunFifo`, and framework code;
there is no dominant branch patch. These diagnostic windows do not replace the
ordinary 21.9 FPS baseline, and profiler-attached FPS is observer-contaminated.
The next bounded preflight is to count post-optimization guest-PC stores in
the named hot chunks and prove an exception-safe elimination opportunity before
building. See
`docs/artifacts/2026-08-31/g8-r0-instruction-front-end-counter-split.md`.

PERF-254 repairs the exact rules route and rejects the guest-PC-store direction
before a product build. Each editable rules field now receives a forced visible
change before state-gated convergence, and final active rules remain a veto.
Two fresh processes prove the exact Samus/CPU-Kirby, Stock/04/05:00 Fountain
route, but visible combat is only 49.1 and 41.6 FPS with geometry distortion.
Strict-PGO all-drop mini-links shrink 13.34% but are unsafe; a semantics-safe
representative subset shrinks only 3.77%, below the five-percent gate. The
older broad live PC-elision candidate also regressed 52.585 to 49.629 FPS. Do
not build this candidate. Next retain the exact-route one-in-4,096 dispatch
distribution and require a new bounded concentration. See
`docs/artifacts/2026-08-31/g8-r0-rules-normalization-and-pc-store-preflight.md`.

## G8 row-7 and iPad promotion acceptance protocol

This protocol prevents a fast idle/menu tail or final interval from hiding a
slow first-run gameplay path. Row 7 is **failed** at the start of every
performance iteration until the complete protocol below passes; an improving
experiment changes the diagnosis, not the gate state.

There are three evidence lanes, and they are not interchangeable:

- **Diagnostic lane:** profiles, samples, counters, savestates, attract mode,
  and focused phase reversals identify mechanisms and reject candidates. They
  cannot pass row 7 or establish playability.
- **Automated acceptance lane:** two complete fresh-process product routes
  prove repeatability and catch cold-path failures. Automation must use the
  same product input/runtime path as the shipped app unless an explicitly
  logged harness change is itself under test.
- **Manual product lane:** a person launches the installed app normally,
  navigates through the menus, starts a match, and plays it while the visible
  FPS label, responsiveness, audio, and rendering are observed. This lane is
  mandatory twice: first as the reality-check baseline that selects the slow
  workload for the iteration, and again after the automated routes as the
  final veto before physical-device promotion.

The lanes combine pessimistically. A manual visible failure vetoes promotion
even when diagnostic or automated evidence is faster. Resolve a disagreement
by preserving both observations, confirming build/module/config identities,
and reproducing the failed visible phase; never discard the lower result as
"an outlier" without a demonstrated cause and a successful same-path
reversal.

The ordinary manual baseline is sticky across iterations. Automation or a
profiler run may add a lower failure, but it may not raise the baseline. The
21.9 FPS result remains authoritative until the same installed product path,
started normally by a person, is visibly reversed on an unchanged candidate.
Profiler-attached FPS, private-pipe FPS, and post-results/static-screen 60 FPS
must be labelled diagnostic and cannot be cited as evidence that the ordinary
route improved.

0. Begin every row-7 optimization cycle with a cold, ordinary product launch
   and a visible manual sanity route. Do not preload a savestate, preserve a
   warmed shader cache specifically for the run, enable a private input mode,
   or skip the opening/menu path. Record cold boot/opening video, title/menu,
   CSS/stage selection, match loading, and the first active combat minute.
   The lowest repeatable visible phase becomes the iteration's control
   workload. If a tester reports a slower normal route than the retained
   automation, reproduce and explain that route before optimizing an easier
   roster or phase. Diagnostic collection may follow, but no diagnostic result
   can upgrade the visible baseline.

   The controlling acceptance route is P1 Samus versus level-1 CPU Kirby,
   Stock with 04 stocks and a 05:00 time limit, on Fountain of Dreams. Preserve
   visible proof of all four settings. `Four-stock` never means four fighters;
   crowded four-character traces are diagnostic-only unless the tester reports
   that as a separate slower normal route.

1. Test the exact product build and default product settings from a fresh app
   process. Record the complete visible route from boot/title through normal
   menu navigation into a full 1v1 Fountain of Dreams match with music and
   SFX. Do not substitute attract mode, a savestate-only interior window, or a
   warmed scene for this route.
2. Retain scene markers, a visible screenshot or video, and every 10-second
   runtime performance row for the route. Report the minimum and the complete
   interval distribution; never use only the mean, best, final, or selected
   flat-underrun windows.
   Divide the route into cold boot/moving opening or attract content,
   title/menu transitions, CSS/stage selection,
   match loading, Fountain combat, results, and return-to-menu phases. Each
   phase is independently pass/fail; a later fast phase cannot repair an
   earlier failed one.
   When the on-screen FPS label and runtime diagnostics differ, retain both
   and judge the lower value. The user's visible 21.9 FPS Fountain frame is
   therefore a failure even if a nearby diagnostic interval is faster.
3. After the product begins presenting moving game content (including the
   opening/attract sequence and animated menus), every non-paused interval must report
   both FPS and VPS at least 59.0, `speedRatio` at least 0.98, continuing audio
   callbacks, and no sustained DMA-underrun growth. Any interval below 59.0,
   or any two consecutive intervals that add underruns, fails the run and
   reopens row 7. A single interval below 55.0 is an immediate performance
   failure regardless of later recovery.

   A front-end interval with full-speed VPS but sub-threshold visible FPS is a
   presentation failure; a combat interval with FPS and VPS both slow is an
   emulation-speed failure. Diagnose and reverse them independently. Neither
   may be averaged with the other or with a warmed idle/static screen.
4. Work each candidate through three gates before spending another complete
   route on it:
   - **Mechanism:** connect the exact slow phase to measured code or resource
     work and state the predicted effect. Do not optimize a broad suspect just
     because it is present in a profile.
     A counter family must also clear a materiality bound. A measured event is
     not automatically causal: translation and branch events that can explain
     only a small fraction of the 21.9-to-60 gap are recorded as secondary and
     may not justify a broad product rewrite.
   - **Integrity:** pass focused semantics, build, crash, and ROM-boundary
     checks. A faster corrupt, unstable, or timing-inaccurate build is rejected.
   - **Matched phase reversal:** replay the same roster, stage, process state,
     settings, and input path against control/candidate/control (or an equally
     strong fresh-process reversal). Retain the candidate for composition only
     if the failing Fountain phase improves materially (normally at least 5%)
     without moving the cost, underruns, or visual corruption elsewhere. This
     is progress evidence, never a row-7 pass by itself.

   The matched phase must be the slowest retained manual workload unless a
   measured experiment is explicitly diagnosing one of its sub-phases. A
   one-opponent Fountain trace at 47.7 FPS may classify a mechanism, but it
   cannot reverse or replace the retained normal-route 21.9 FPS control.

   A candidate that fails any gate is reverted and entered in the do-not-repeat
   record with its measured rejection. A candidate that passes all three earns
   the full-route test in step 5.

   Before using any PGO candidate, first prove the control build can traverse
   the scripted route. The instrumented run must retain visible trigger-entry
   and trigger-exit evidence, and `llvm-profdata show` must report nonzero
   counts for the target workload. A created `.profraw` file alone is not
   training evidence. If input automation does not visibly advance the guest,
   stop and repair/calibrate the harness; never merge the resulting profile.

   A fixed-duration character/stage cursor script is not acceptable route
   proof. It must verify the revision-1.00 cursor/player/rules state and correct
   deviations before starting the measured phase. If those state fields are
   not validated, repair the harness before profiling or compiling a candidate.
5. Repeat the complete route in two fresh processes. Both runs must pass every
   phase and threshold in steps 1-3. Stop a run as a pass attempt immediately
   after an interval below 55.0, but retain enough surrounding diagnostics to
   attribute it; do not spend minutes collecting a misleading recovery tail.
6. Freeze the exact app, module, settings, save-state policy, and input-path
   identities from the automated pass. On that unchanged installed build, run
   one fresh **manual product route** from launch through menus and at least
   five minutes of active Fountain combat. Retain a visible recording with the
   FPS label plus the matching complete runtime log. Any visible slowdown,
   input lag, audio breakup, character/stage corruption, crash, or threshold
   miss fails row 7 and returns the loop to mechanism attribution. A tester's
   direct observation is acceptance evidence, not anecdotal evidence.
7. Only after both automated Simulator runs and the manual product route pass
   may the same build be called a
   physical-iPad test candidate. Physical-device readiness then requires its
   own signed-device replay covering the same match, touch latency, audio,
   lifecycle, controller reconnect, and a 15-minute thermal soak. Simulator
   or generic-device compilation is never device acceptance.

Current anchor: the user's first ordinary Simulator run reached 21.9 FPS on
screen in active Samus-versus-level-1-CPU-Kirby, four-stock, 5:00 Fountain
combat, with 20.2 FPS / 19.8 VPS in matching diagnostics and growing DMA
underruns. This exact roster/rules/stage route is the control workload for the
next performance reversal; the later lighter one-CPU 47.7 FPS diagnostic does
not supersede it.
The latest cold normal touch-driven route also fell to 49.1-51.0 FPS with
underruns rising 10 -> 41 during front-end transitions, and later presented
52.6 FPS while VPS remained 60.0. That is an additional phase failure, not a
new lower combat control; both classes must pass independently.
Until a matched candidate directly reverses that phase and then passes two
complete cold routes plus the manual product route, describe the Simulator
build as **unplayable in the failing workload**, never as playable, stable-60,
nearly ready, or device-ready.

- **Per change:** the check relevant to what you touched (build, boot, or the affected test row).
- **Per goal claim:** full evidence per PRD Section 11 before marking a goal met in STATUS.md.
- **Per session:** before ending, run the ported regression scripts (sunpad `tests/` equivalents) plus a boot check on the highest working target, so the journal's last entry states a known-good state.
- **Input injection:** use the gcpipe.py pattern (pipe-input bridge) to script menu navigation and match starts; use `xcrun simctl io ... screenshot` for evidence. Hands-on rows in the matrix stay hands-on.
- **Honesty rule** (from sunpad, adopted verbatim): do not convert configured or source-inspected behavior into an acceptance claim. If it wasn't run and observed, it isn't done. Frame-time numbers only ever come from recorded profiles.

## Using the SunPad machinery (not just its code)

- **Logging:** wire the runtime.log breadcrumb system in early (G6/G7), then rely on it: boot, display, controller, lifecycle, input-pipe, runtime-error, screenshot-marker breadcrumbs are your primary debugging instrument on Simulator targets, and Share Diagnostic Log is how test evidence gets exported.
- **Experimental-mode framework:** every risky performance experiment (underclock, scheduling, codegen flags) ships as a default-off experimental toggle with a logged mode identity, sunpad-style, never as a silent change to the stable path.
- **Scripts as templates:** bootstrap-dependencies.sh (pin + patch), prepare-game.sh (validate + extract + module), ios-build-core.sh (Simulator module build), package-macos-app.sh, stage1-run.sh / sunpad-capture.py (automated run + capture). Port them to ssbmpad names rather than inventing new mechanisms; the build must reproduce from a clean clone via scripts alone (matrix row 15).

## Session start checklist

1. Read `docs/STATUS.md` and the last JOURNAL entry.
2. `xcrun simctl list devices booted`; shut down strays. Kill stray game processes.
3. Confirm ref/ inputs unchanged (ROM hash spot-check).
4. State the session goal in JOURNAL.
5. Enter the loop.
