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

The next falsifiable step is a matched repeat/control to separate rare host
preemption from systematic per-dispatch cost before another behavior change.
Retain a behavior change only if the complete strict Fountain distribution
improves, then repeat on Final Destination. G5 and the ban on starting G6
remain in force. See
`docs/artifacts/2026-08-25/g5-static-work-and-qos-rejection.md`.

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
