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


## Integrated private math module

The deferred-classification mechanism now also covers the connected sine,
cosine and absolute-value region, retaining the generated arithmetic and
call/cycle boundaries. The private module routes only guarded exact entries
through the candidate and rejoins the original chunk return dispatcher.
Unsupported states retain the original generated path. No production module
or accepted main source has been replaced.

The integrated Mac module passed 100,000 inverse-transpose and 10,000
trigonometric comparisons against the original compiled module through the
same module-dispatch interface. Comparisons cover complete CPUState and RAM,
including edge floats, FP control bits, cycle exits and fallback conditions.
The inverse microbenchmark measured 350–356 ns baseline versus 136–139 ns
candidate across seven alternating pairs. This is local host timing, not an
iPhone or whole-frame improvement. Earlier direct-wrapper timing is not a
comparable integrated benchmark.

Private reproducible integration/build scripts and logs are in
`ref/revision-102/performance-loop/alias-preflight/`: `build-family.py`,
`build-family-ios.py`, `test-family-inverse.log`, and `test-family-trig.log`.
The physical iOS module built successfully. Private build 13 passed strict
code-signature verification, was installed over the regular iPhone app and
launched with profiling enabled. Its v1.00 module is byte-identical to build
12; existing app data was retained. Physical correctness, sustained heavy-scene
performance and whether the gain is worth shipping remain open. Installation
and launch receipts are under `ref/revision-102/performance-loop/math-candidate/`.


### First physical candidate samples: useful local gain, no whole-frame claim

Build 13's fresh runtime log confirms revision 2 and its new module size.
It reached heavy graphics automatically after the light opening scene; the
owner has not confirmed a controlled multi-fighter match. The two 600-frame
windows at emulated frames 7000 and 8800 are complete in both CSV sets.
However, neither window has a single frame with matching draw and primitive
counts across baseline and candidate. Workloads differ substantially.
Candidate CPU-thread means are 20.842 and 15.108 ms versus baseline 20.273
and 23.586 ms. These differences cannot establish a whole-frame speedup.

Across those windows, mean corrected inclusive time per sampled inverse entry
falls from 777.51 ns (262 samples) to 322.85 ns (292 samples). Cosine remains
316.85 versus 319.04 ns; sine remains 342.32 versus 337.59 ns. This supports
an on-device benefit for the inverse mechanism, but not the added trig region
or a substantial application-wide improvement. Different input distributions
and thermal scheduling still limit the per-entry comparison.

The integrated host comparisons also passed all four host rounding modes:
400,000 inverse and 40,000 trig entries. Logs are private. The next source
candidate is deferred classification across the paired-single matrix region;
its helpers repeatedly classify results in `cpu_interpreter_float.c`. This
is distinct from the previously rejected standalone matrix leaf replacement.
Owner-driven heavy-match capture remains requested; build 13's profiler is
currently active. No release or merge of the experiment is justified yet.


### Follow-up screen and bounded capture closure

Inspection rejected the proposed paired-single extension: the generated
PSMTXConcat arithmetic is already inline and does not call the repeated FPRF
classification helpers. Extending that mechanism there would have no basis.
The scalar HSD_MtxScaledAdd region does still use twelve scalar multiply-add
helpers. A guarded private prototype passed 100,000 whole-state/RAM entry
comparisons against the compiled baseline. Its direct-wrapper host timing
cannot yet support an integrated or physical gain; no new device build was
made from this extension.

The build 13 capture was saved under `math-candidate/*-bounded-final.*` with
SHA-256 hashes, then profiling was disabled by normal relaunch. Fresh runtime
session 2026-09-08T10:11:07.899Z confirms build 13 without capture activation.
The earlier statement that its profiler remains active is superseded.

Next gate is a reproducible physical multi-fighter match, requested from the
owner but not yet confirmed. Automatic scene workloads differ, so further
small host optimizations cannot settle acceptance. Hold integration/release
of the candidate until that hardware comparison can establish whether it is
worth retaining. Existing stable main and device game data remain preserved.


### Automated v1.02 comparison route

The owner-driven gate above is not the only available next action. Inspection
found the existing four-player route, whose guest readers/writers explicitly
rejected revision 2. Its v1.02 address selection is now implemented using the
pinned decomp's symbols and struct layouts: state_machine 80479D30, P1 cursor
pointer 804A0BC0, CSSData pointer 804D6CB0, SSSData pointer 804D6C90, and HSD
seed/seed_ptr 804D5F90/804D5F94. Pointer/layout checks and v1.00 addresses remain.
The changes are restricted to the existing developer benchmark launch mode.

Route tests and the physical-iOS Release build passed. Private build 14 is
installed and running `versus-four-big-blue-v1` with capture enabled, using
build 13's optimized modules. A control build 15 is prepared with the same
executable bytes before the code-signature blob and the baseline v1.02 module.
Signature differences reflect the different build-number seal. The route's
actual fixed-roster/stage acceptance is not yet established; opening menu
input is confirmed by a fresh runtime log. This route is a fixed workload
setup, not a claim of frame-exact deterministic replay.


Build 14 route progression is now verified in `route-candidate/runtime-second.log`:
normal input enabled the three CPU doors; at emulated frame 2042 the checked
roster write set 10040506, frame 2043 confirmed slot types 00/01/01/01, and
the stage selector accepted forced stage 0x13 (Big Blue). Both seed boundary
writes succeeded. This removes the immediate need for owner-operated setup;
the physical comparison can proceed autonomously. Whole-frame improvement
remains unverified until both runs are captured and compared.


### First fixed four-player pair: inconclusive under thermal pressure

Both builds reached the checked 10040506 roster and Big Blue. Build 14 uses
the candidate module; build 15 uses the original module. Both use the same
app executable before its signature blob, original 4:3, 1x rendering, and
identical profiling flags. Complete phase and dispatch windows were saved
privately with hashes. Both runs report serious thermal state.

| Emulated frames | Candidate CPU ms | Control CPU ms | Candidate FPS | Control FPS |
| --- | ---: | ---: | ---: | ---: |
| 3000–3599 | 17.048 | 15.671 | 54.49 | 58.05 |
| 4200–4799 | 19.786 | 16.970 | 48.39 | 55.74 |
| 5400–5999 | 20.919 | 26.618 | 45.83 | 36.05 |

FPS here is 1000 divided by mean recorded frame time. Candidate draw counts
are +5.64%, +2.67%, and -1.37%; primitives are +1.93%, +1.59%, and -3.83%.
This is not equal-work evidence or a consistent improvement. Thermal pressure
also changes within the broad serious category. Do not retain the candidate
from this pair or claim the heavy-scene slowdown is fixed.

The original module is currently installed in private build 15. The benchmark
process was terminated after capture, leaving the phone idle to cool. A cooled
comparison is warranted by the unresolved thermal/workload confounds; repeated
warm runs are not. Private analysis: `route-comparison1.json`, `compare-route.py`,
and both route directories' `capture1-sha256.json` files.


### Cooled control captured

The baseline was confirmed stopped, then left idle for just over five minutes
before relaunch. Its route again fixed the same roster at frame 2042 and opened
stage selection at 2043. Initial telemetry reported serious, then fair, then
serious again later in the run; idle duration alone is not a thermal-state
measurement. CPU means for the three windows are 15.561, 16.844 and 18.985 ms;
FPS from mean frame time is 58.53, 56.88 and 50.54. This shows the substantial
thermal sensitivity of the baseline, not an optimization gain.

Complete capture files and hashes are `route-control/*-cooled2.*` and
`cooled2-sha256.json`. The baseline process was stopped at 10:33:47 UTC and
candidate build 14 was reinstalled without launching it. The matching candidate
cooldown is in progress. The goal remains incomplete and the experimental
module remains outside main and any public release.


### Cooled candidate: promising aggregate, reject the trig component

After the same five-minute idle interval, candidate build 14 reports nominal
at startup, unlike the control's initially serious then fair state. Candidate
CPU means are 14.935, 16.245 and 18.102 ms, respectively 4.02%, 3.56% and 4.65%
below the cooled control; FPS is 59.88, 58.69 and 52.80. In the latter two
windows, draws/primitives/cycles/dispatches differ by at most 0.16%. This is
encouraging aggregate evidence but the starting thermal-state difference
prevents attributing the full gain to the optimization.

Corrected inclusive entry timing in those latter windows isolates a problem:
inverse is 648.02 ns control versus 318.23 candidate, but cosine increases
294.64 to 425.40 ns and sine 270.33 to 313.23 ns. Unchanged reference routines
move in both directions. Reject the trig component. A revised private module
is building with inverse plus the correctness-tested scalar matrix-add region,
restoring the original trig chunk. No further phone build is installed yet;
build 14 was stopped after saving its capture. Retention remains unproven.
