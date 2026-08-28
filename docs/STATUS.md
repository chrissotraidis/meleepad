# ssbmpad status

Last updated: 2026-08-28

## Current goal

**G5 — macOS 60 fps: IN PROGRESS**

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
to the current product runner while retaining its known module. Next screen
IR-level PGO on the same workload;
CS-PGO+LTO and BOLT are excluded by host preflights/platform support. Final
Destination and G6 remain blocked. See
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
| G5 macOS 60 fps | In progress | Cache-control parity retained; PGO, busy-spin, idle shortcuts, activity hints, and focus causality rejected. A CSS-gated trigger captured a one-second 54.918 FPS hitch cluster as off-core host delay, while 2/5/10-second windows held 57.316/58.866/59.399 FPS. Return to the normal required-stage strict tail; reopen the major-menu branch only for a multi-second sub-55 recurrence |
| G6 Simulator core boots | Not started | G5 first; no Simulator booted |
| G7 Shell ported | Not started | G6 first |
| G8 Test matrix green | Not started | G7 first |
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

The macOS build/package/title, controlled-gameplay, and live-audio-stack rows
are proven. Lifecycle and performance rows remain open. All iPadOS and iOS
rows are not run because the loop forbids moving to G6 before G5 passes.

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
