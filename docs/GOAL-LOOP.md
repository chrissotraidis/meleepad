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
