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

## Testing rhythm

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
