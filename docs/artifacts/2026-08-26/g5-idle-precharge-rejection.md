# G5 external sample and idle-precharge rejection

## Question

Is the previously measured 50.605 FPS Pikachu-versus-CPU-DK Fountain interval
a deterministic roster slow path, and can the configured scheduler-idle loop
be shortened at static-recompiler burst entry without adding a branch to every
native dispatch?

## Fresh normal-runner correction

The normal signed runner (`c26625db...`) and corrected module (`2dce1352...`)
were cold-booted with MemoryWatcher active before the runner. Computer Use
visibly verified P1 Pikachu, level-1 CPU Donkey Kong, the explicit `Fountain of
Dreams` label, coherent live combat, Cubeb audio, and results. The window title
held 59.8-59.9 FPS during active combat and read 59.9 FPS at results.

This run did not set `MELEEPAD_FRAME_PHASE_LOG`, so the title is not promoted to
a strict G5 bracket. It is nevertheless direct falsifying evidence against the
previous claim that the DK roster deterministically causes 50 FPS. The prior
600-row 50.605 FPS interval remains valid evidence of a real slowdown, but its
cause is intermittent or host/path-state dependent rather than proven to be
the roster alone.

A concurrent ten-second external `sample` is retained as
`g5-normal-pikachu-dk-fountain.sample.txt` (SHA-256
`613398c2432bca41fd08c0547dacb3811343c323edcaadaa7fcade83c8f3f93e`).
Of 886 CPU-thread samples, 776 were in `StaticRecompCore::Run`, 756 descended
through `chassis_dispatch`, and 156 had `loop_80349494` at the top. Thus the
known three-instruction scheduler poll still consumed 17.6% of CPU-thread
samples even in a visibly full-speed match. The retained active-combat and
results PNGs prove the sampled roster and completed match.

## Candidate

DolRecomp's generated C normally executes about 86 three-cycle iterations
before its 256-cycle backward-loop budget returns `0x80349494` to the host,
where the existing `StaticRecompIdlePC` path calls `CoreTiming::Idle()`.

A focused candidate precharged the generated downcount to `-255` when a native
burst began at the configured idle PC. This preserves the existing charge
boundary and should make the first poll return immediately. A production-
header regression failed before the helper existed and passed after it was
implemented. The candidate runner built, was signed, and had SHA-256
`bc36dd002c34f41098a0eca89063c9ac314d74330a799dd9b257cd33e090da04`.

The watcher-first route visibly established the same Pikachu/CPU-DK/Fountain
scene. A capture-free 4,090-row combat interval (`24838..28927`) measured:

| Metric | Candidate |
|---|---:|
| Mean / median | 16.742 / 16.672 ms |
| p95 / p99 / worst | 17.577 / 19.527 / 152.055 ms |
| Average FPS | 59.731 |
| Frames <=16.7 ms | 55.110% |
| CPU-thread mean / p95 / p99 | 16.019 / 17.370 / 18.952 ms |
| Throttle sleep mean | 1.026 ms |
| Native dispatches / guest cycles mean | 128,311 / 8,107,177 |
| Interpreter and cache fallbacks | 0 |

The strict p95, p99, and worst-frame requirements all fail. More importantly,
an external sample of the candidate still placed 183 of 890 CPU-thread samples
at `loop_80349494` (20.6%), versus 156 of 886 (17.6%) in the normal run.
Melee reaches this loop later inside an already-running native burst, so a
burst-entry precharge normally never sees it. The apparent CPU-headroom change
cannot be attributed without a matched system-state control.

## Decision

**CANDIDATE REJECTED AND REMOVED; G5 OPEN; FINAL DESTINATION NOT RUN; G6
BLOCKED.** The source helper, regression, and candidate runner were removed.
The app is restored and signed with normal runner SHA `c26625db...` and module
SHA `2dce1352...`. No runtime or Simulator remains.

The next smallest experiment must act at the generated branch itself, not only
at burst entry and not with a new check on every native dispatch: locally emit
an immediate host return after one taken poll at the exact configured idle PC,
then run a focused semantic test and a matched phase-logged Fountain pair.
Retain it only if the external sample loses `loop_80349494` and the complete
strict frame distribution improves.
