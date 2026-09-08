# Heavy-scene iPhone performance goal loop

Started 2026-09-08. The owner accepts build 11 as the next baseline and authorizes
merging it, then further focused optimization. This supersedes the prior
preferred-revision loop for new work. Acceptance does not erase known slowdown
or establish physical online-match success. No new public IPA is requested.

## Outcome

Prepare one worthwhile optimization for the physical iPhone's heavy scenes,
with preserved gameplay and a repeatable measured benefit. Use the completed
v1.02 decompilation to understand and specialize the existing translation;
matching original code is not itself an optimized Apple-native port.

The older v1.00 investigations remain in [the previous iPhone ledger](IPHONE-PERFORMANCE-GOAL-LOOP.md).

## Current state

- Accepted baseline merged in PR #4, main commit `5661889`.
- Full repository checks passed before merge. Prior device installs and owner's
  testing remain the acceptance evidence; no replacement IPA was published.
- [Latest evidence](artifacts/2026-09-08/iphone-heavy-scene-performance.md):
  verified v1.02 on iPhone build 11, 1×/4:3, samples at 9.9 then 34–43 FPS.
- Current step: heavy-scene capture is complete and the iPhone has been
  relaunched normally with profiling off. The selected optimization lane is
  composed matrix processing; see the measured attribution below.

## Loop

1. Reuse the existing frame-phase and sampled dispatch-time traces. Capture one
   short heavy scene on the physical iPhone. Identify stage/fighters and pause
   timing; use the exact v1.02 symbol map. Logging overhead is unmeasured, so
   this identifies candidates rather than proving final uninstrumented speed.
2. Select one substantial target: connected joint-transform/collision calls if
   game CPU dominates; common precompiled vertex decoders if graphics CPU
   dominates; shader warm-up only if measured compilation/fallback cost warrants
   it. Read and preserve existing caching and validity guards.
3. Implement the smallest useful specialization behind a reversible gate. Check
   memory/state, floating-point edge cases, timing and fallback equivalence.
   Avoid another standalone matrix leaf rewrite: prior projected gains were too
   small. Do not substitute reduced game speed or skipped simulation work.
4. Build a physical-iPhone candidate and compare the same scene at 1×/4:3 with
   comparable temperature, including a warmed repeat and audio/frame tails.
   Verify the benefit without tracing. Keep only a repeatable worthwhile gain.
5. Record the result and stop that candidate if inconclusive. Choose another
   only when evidence identifies a better target; no broad benchmark sweep.

Preserve v1.00. Game-semantic changes require equivalence before online use;
all future netplay acceptance is physical iPad–iPhone. No Simulator netplay or
QuickTime recording. Keep game data, generated modules, captures and device
identifiers private. Preserve the unrelated local images.

## Minimal capture handoff

The next diagnostic build accepts the developer launch environment variable
`MELEEPAD_PERFORMANCE_CAPTURE=1`. It resolves the existing profiler's outputs
inside the app's Logs directory; no product setting or persistent preference
is added. Ordinary launches retain existing logging.

Launch with `devicectl device process launch --device <physical-iPhone>
--terminate-existing --environment-variables '{"MELEEPAD_PERFORMANCE_CAPTURE":"1"}'
<installed-bundle-id>`. Confirm the regular app identity before launch.

Reproduce the heavy scene for approximately 30–60 seconds, then use the app's
normal stop/return flow to flush buffered samples. Retrieve
`Library/Application Support/MeleePad/Logs/performance-phase.csv` and
`performance-dispatch.csv` together with `runtime.log`. Do not force-terminate
before retrieval: the final dispatch buffer flushes on normal runtime shutdown.
Each profiler session overwrites these CSVs, so copy them before another run.
Relaunch normally afterward to disable tracing. Captures are private and not
part of the normal shared problem report.

Use `scripts/analyze-dispatch-time-samples.py` for the selected emulated-frame
window, then `scripts/symbolize-melee.py --dol <verified-v1.02-main.dol>` for
ranked PCs. Dispatch frequency alone is not execution-time attribution.
A timed dispatch can include continuation work after its named entry; its
inclusive time must not be treated as the exclusive cost of a leaf. The prior
iPhone I14 matrix experiment demonstrated this failure directly. Use the
existing burst trace only if call-context ambiguity prevents choosing a
composed path; do not add another generic profiler.

## Iteration ledger

- 2026-09-08: merged the accepted baseline and reused the existing profiler via
  one developer launch flag. The physical-iOS Release build passed; device attribution
  remains pending; no new speedup is claimed.

- Source follow-up: the previous iPhone I14/I15 ledger already rejects GX
  matrix leaf specialization and establishes inclusive-time bias. Preserve
  that result. Decomp joint/collision inspection informs composed paths, not
  a renewed claim that leaf SIMD is a sufficient fix.

- Handoff: private diagnostic build 12 is prepared from the accepted regular
  app with the new host executable. Its existing game modules are unchanged;
  signing with the baseline certificate and strict bundle verification pass.
  It is not installed or published. The device still has accepted build 11.
  Diagnostics/privacy tests and dispatch-time analyzer tests pass. Next step
  is the short physical heavy-scene capture, then one selected optimization.

- Execution correction: the previous handoff ended without running the next
  step. Build 12 has now actually been installed in the regular iPhone app
  container and launched with capture enabled. Runtime log confirms build 12,
  verified revision 2, and profiler activation. Both CSVs were retrieved and
  parsed successfully. Installation preserves game data. Heavy-scene
  reproduction is pending; initial menu samples are not optimization evidence.

## First completed v1.02 physical capture

The previous execution turn made concrete progress by installing and running
build 12. This continuation retrieved heavy-frame data, checked complete
window coverage, and symbolized PCs against the hash-verified v1.02 DOL.

| Emulated frames | Rows | Mean frame | CPU-thread mean | Metal pipeline creation/frame | Timed dispatch samples |
| --- | ---: | ---: | ---: | ---: | ---: |
| 7000–7599 | 600 | 21.333 ms | 20.273 ms | 0.0035 ms | 24,991 |
| 8800–9399 | 600 | 24.548 ms | 23.586 ms | 0.021 ms | 21,227 |

Both windows are inside the flushed dispatch trace. An initial live copy
ended at frame 9023 and therefore could not support the entire second window;
that incomplete analysis was replaced with the final capture. Raw logs and
hashes remain private under `ref/revision-102/performance-loop/`.

The logged settings are 1× / original 4:3, with serious thermal state during
the slowdown. These are instrumented observations, not an uninstrumented
performance baseline. Stage/fighter identity has not been independently
confirmed; heavy graphics and CPU slowdown are observed directly.

Across these two windows, the leading named entries by mean sampled dispatch
time are PSMTXConcat (6.09%), GXLoadPosMtxImm (5.83%),
HSD_MtxInverseTranspose (4.30%), GXLoadNrmMtxImm (3.41%), sinf (3.25%) and
cosf (3.00%). HSD_MtxScaledAdd contributes 1.79%. These are percentages of
corrected sampled dispatch time, not exclusive leaf time or whole-frame
savings. Estimated dispatch coverage is only 79.2% / 68.9% of CPU-thread time.

Decision: postpone shader warm-up and vertex-loader changes as the first
experiment. CPU-thread cost nearly fills the observed frame budget, and
recorded pipeline-creation cost is small in these sustained intervals. This
does not measure all GPU work or explain every first-use hitch.

The next code experiment should cover a connected matrix path, not repeat the
rejected standalone GX leaf. The pinned `SetupEnvelopeModelMtx` implementation
(`src/sysdolphin/baselib/pobj.c:1125`) provides one concrete composition of
joint preparation, concat, weighted accumulation, inverse-transpose and GX
upload. Source structure makes this a candidate, not proof that all sampled
matrix calls originate there. Any private preflight must preserve intermediate
guest state/memory, cycle exits, FP rounding and code-validity guards; local
math timing alone cannot qualify it for a claimed device improvement.

The final CSVs were copied before restarting the regular app without capture
environment variables. The unflushed trailing dispatch buffer is deliberately
not part of the evidence. No new optimization has been installed.

## Matrix-code preflight: deferred result classification

The first code experiment now exists privately and has been executed. It is
not installed on the iPhone or enabled in the accepted main build.

- Adding a restricted context pointer produced identical ARM64 instruction
  text in all three screened hot chunks. Rejected without a device build.
- A guarded direct-RAM version of the inverse-transpose region preserved
  20,000 CPU-state/RAM comparisons, but improved local time only about 1–3%.
- Inlining the unchanged FP helpers and hoisting FP-availability checks under
  a validated no-callback entry improved that local result to roughly 7–11%.
  This remained too small for a device candidate.
- Deferring the overwritten FPSCR result-classification field (FPRF) until
  each exit improved the same local region by **34–38%** in the initial run.
  An expanded run passed **100,000 adversarial entry comparisons** and
  measured 37.3–38.6% across seven alternating local timing pairs.

The final expanded run compares complete CPUState (normalizing only the RAM
pointer) and 64 KiB of RAM after each tested entry. Inputs include matrix
aliases, signed zero, NaNs, infinities, subnormals, raw float bit patterns,
FP-disabled entry, reservation state, and boundary/MMIO addresses that must
fall back. These are Mac-host comparisons against the extracted existing
generated region, not an iPhone test or proof of a whole connected path.

The mechanism preserves arithmetic and exception-helper code. Within the
validated RAM-only region, no memory callback or journal can observe an
intermediate FPRF value; arithmetic helpers read other FPSCR fields, not that
classification field. Record the most recent successful FP result, then
compute/commit its classification before every region exit. Keep exception
flags, rounding, registers, memory writes and cycle charges unchanged. The
fast entry rejects FP-disabled state, reservations, an active write journal
and memory ranges outside the checked matrices/stack/constants.

This is a **mechanism preflight**, not a decision to ship another isolated
leaf. The inverse-transpose entry represented only about 4.3% of sampled
dispatch time, and that share is inclusive. Its local gain cannot establish a
substantial whole-game improvement. The next step is to extend and measure
the mechanism across the connected joint-transform math path, including its
trigonometric work, while preserving observation and exit boundaries.

Private source snapshots, executable, exact logs and SHA-256 manifest are in
`ref/revision-102/performance-loop/alias-preflight/`. The successful artifact
is `inverse-deferred.c` with `deferred-float.c`; the expanded test result is
`test-inverse-deferred-edge.log`. The goal remains incomplete until a useful
connected-path implementation passes physical-iPhone validation.
