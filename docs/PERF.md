# ssbmpad performance ledger

G5 is active. G4 passed with a clean controlled 1v1 on 2026-08-24.

The runner's window-title counter was observed across boot, title, and
attract-mode scenes. It ranged from single digits during a cold transition to
roughly 58-60 FPS in lighter title/intro frames, with complex four-character
attract battles commonly in the low 30s to low 40s. These are diagnostic
spot-values, not a controlled frame-time trace, and they do not satisfy the
PRD's worst-case <=16.7 ms requirement.

The first controlled diagnostic match (Kirby versus CPU Samus on Venom) ran at
about 12.5-13.0 FPS during combat and returned to about 57.5 FPS on the results
screen. The runner, frontend, and generated module are native arm64 binaries;
`sysctl.proc_translated=0`. Both the runtime and module are Release builds, the
generated C chunks use optimization flags, Metal is selected, and internal
resolution is 1x. A one-second process sample found the CPU-GPU/static-recomp
thread saturated in generated `gGALE01_recomp.dylib` functions. Metal draw/EFB
and Cubeb mixing paths were present but secondary.

The first retained optimization fixes a macOS build-system defect: forced Ninja
response files caused CMake's Apple IPO probe to fail, despite the module cache
identity claiming ThinLTO. With platform-default response-file handling, the
official O2 build now compiles and links with `-flto=thin`. On aligned
boot/attract frames 2001-3500, mean frame time improved from 20.247 ms to
17.703 ms and p95 from 26.069 ms to 21.207 ms. A separate O3 + native-tuning
build was no faster, so that added complexity was rejected. See
`docs/artifacts/2026-08-24/g5-thinlto-investigation.md`.

The first required-stage baseline is now recorded. A clean Yoshi-versus-CPU-
Zelda Fountain match measured 19.552 ms mean, 19.326 ms median, 22.862 ms p95,
28.010 ms p99, and 111.083 ms worst over 5,176 active-combat frames. Only 3.73%
of frames met 16.7 ms. A clean process sample placed about 88% of the sampled
CPU thread in generated `chassis_dispatch`, classifying the scene as CPU-bound.

An isolated C-backend PGO experiment confirmed the same hot path. Its first
comparison was measurement-confounded and is superseded. In the corrected
buffered 90-second Yoshi-versus-CPU-Ice-Climbers Fountain pair, PGO lowered
mean 8.3%, median 6.8%, p95 20.4%, p99 22.6%, and worst 17.6%. Frames at or
under 16.7 ms rose from 13.38% to 61.03%. A macOS 14 rebuild reproduced the
candidate in a 30-second confirmation. The portable PGO module is retained
locally as the best-known build and code-generation oracle, but the local
ROM-trained profile cannot be committed or serve as the final reproducible
shipping change. See `docs/artifacts/2026-08-24/g5-fountain-pgo-investigation.md`.

A smaller GameCube-only RAM specialization was also rejected. On an equal
105-second Yoshi-versus-CPU-Ice-Climbers Fountain pair it improved mean 3.5%,
median 4.2%, p95 3.0%, and p99 4.4%, but missed the 5% retention threshold and
regressed the worst frame from 1320.456 ms to 1385.798 ms. Recurring isolated
approximately 1.3-second hitches appeared across clean, PGO, and specialized
runs. See
`docs/artifacts/2026-08-24/g5-noexram-investigation.md`.

That hitch conclusion was measurement-confounded. Dolphin's frame-time logger
forced a file flush on every frame, and the exploratory logs also included
screen captures. The retained logger correction buffers ordinary lines. A
visually bounded, capture-free 90-second Yoshi-versus-CPU-Ice-Climbers
Fountain control then measured 18.187 ms mean, 17.903 ms median, 21.168 ms p95,
21.999 ms p99, and 55.135 ms worst; it did not reproduce the approximately
1.3-second hitch. G5 still fails on sustained frame time. See
`docs/artifacts/2026-08-24/g5-render-logging-control.md`.

The first static reproduction attempt forced the hottest sampled polling helper,
`loop_80349494`, to inline into its generated caller. The symbol disappeared
from the macOS 14 arm64 candidate as intended, but an exact capture-free
Fountain replay regressed to 18.763 ms mean, 18.293 ms median, 22.040 ms p95,
24.031 ms p99, and 1296.873 ms worst. Only 23.56% of frames met 16.7 ms. The
single-helper change was rejected and the portable PGO module restored. The
steady-state regression is sufficient to reject it regardless of the isolated
outlier; PGO's gain is not explained by this call-site decision alone.

Final Destination is now measured through a ROM-safe isolated-save setup. The
clean no-mod portable-PGO run measured 16.941 ms mean, 16.678 ms median,
16.946 ms p95, 17.189 ms p99, and 1385.242 ms worst. It is slightly faster in
steady state than Fountain, but still fails p95, p99, and worst. See
`docs/artifacts/2026-08-24/g5-final-destination.md`.

Two broader explanations were then rejected. Marking all 969 generated loop
helpers `noinline` collapsed a four-player attract battle to 4.1 FPS, so PGO's
gain is not reproducible through blanket outlining. Replacing macOS's final
precision-timer scheduler yields with ARM spin hints improved a matched
attract p99 by only 0.63%, left p95 effectively unchanged, and retained
multi-second tail events while spending about 1 ms per frame spinning. See
`docs/artifacts/2026-08-24/g5-outline-and-timer-experiments.md`.

A timestamp-correlated attract diagnostic then separated render delta, CPU
work, requested throttle sleep, and host-clock delta. Frames above 17 ms
averaged 16.757 ms of CPU work and only 2.562 ms of requested sleep; the worst
transition combined 933.964 ms work with 636.776 ms catch-up sleep. The
remaining steady-state tail is primarily generated-module compute rather than
timer overshoot. Combining portable PGO with the earlier GameCube-only
no-EXRAM specialization did not compose: median stayed at 16.683 ms while p95
regressed from 17.848 ms to 19.335 ms and p99 from 18.814 ms to 20.477 ms in a
matched attract window. The candidate was rejected before required-stage
replay. See
`docs/artifacts/2026-08-24/g5-timing-attribution-and-pgo-noexram.md`.

The dominant polling helper's 256-cycle host-return budget was tested directly
with a profile-free 1024-cycle build. It regressed attract median to 16.757 ms,
p95 to 22.926 ms, and p99 to 24.989 ms; vblank regressed in parallel. Reduced
host dispatch frequency does not justify the wider timing-check interval, so
the default budget is retained.

An exact static reproduction of PGO's cold helper symbols was also insufficient.
All 247 PGO-only loop helpers had profile entry counts of zero through nine;
forcing only those helpers `noinline` reproduced all 247 symbols without
touching the hot polling helper. The profile-free candidate nevertheless
regressed attract median/p95/p99 to 16.814/21.459/22.548 ms. PGO's useful
information includes internal branch weights and hot/cold block layout, not
just call boundaries or symbol presence.

A second local PGO corpus added three minutes of no-input attract coverage and
weighted the original Fountain profile 2:1. The portable combined-profile
module slightly improved attract p95 from 17.848 ms to 17.682 ms and improved
vblank tail, but worsened render mean from 17.528 ms to 17.744 ms and p99 from
18.814 ms to 20.654 ms. It was rejected before required-stage replay. Further
PGO training must cover Fountain and Final Destination directly rather than
generic attract scenes.

Direct required-stage training was then tested after repairing the complete
FIFO-to-SI input route and recording controlled 1v1s on both stages. A 2:1
Fountain/Final Destination profile built successfully, but a matched 1,000-frame
attract screen regressed median from 16.684 to 16.778 ms, p95 from 18.077 to
18.383 ms, and worst from 19.088 to 57.091 ms; its <=16.7 ms share fell from
50.80% to 46.60%. The candidate was rejected and the retained Fountain-only
module restored. See
`docs/artifacts/2026-08-25/g5-fountain-fd-pgo-and-input-route.md`.

A new combat-only profile now matches the exact promoted source rather than
reusing a stale corpus. In an exact 440-emulated-frame
candidate/control/candidate Fountain bracket, all three runs execute
1,501,757,755 guest cycles and 51,380,895 dispatches. PGO reduces CPU-thread
mean from 15.941 ms to 11.889/11.606 ms and total p95 from 18.123 ms to
17.608/17.776 ms. The gain is real but insufficient for strict G5. Ordinary
non-precision sleep worsens p95 to 18.227 ms and is rejected. Binary comparison
shows a 723,904-byte larger `__text` plus selective hot helper-call elimination
and branch specialization, not a blanket size/outline effect. The ROM-trained
profile and module stay local as an oracle; the reproducible product remains
unchanged. See
`docs/artifacts/2026-08-27/g5-current-source-combat-pgo-oracle.md`.

ThinLTO's private inline records attribute that candidate to 44,741 successful
selective inlines, led by 41,671 FP-availability sites. Hot call sites use a
3,000 inline threshold while cold sites remain at 325 or 45. Coverage resolved
the hottest isolated short long-load to revision-0 PC `0x8036E8B4`, but the
retained host preflight leaves only about 1 ns/call for that one site, so no
single-site module was built. The validated candidate is retained locally as
`build-macos/SsbmPad-PGO.app`; it is not the reproducible product module and
does not satisfy G5.

A subsequent current-PGO pacing screen rules out three more routes. The
existing buffered render logger, gated by 1,001 advancing MemoryWatcher fields
before state load, still measures 17.956 ms p95 / 22.767 ms p99 /
113.255 ms worst without phase counters. VSync and PresentDrawable-only add
large stalls and change nominal boundary work. A public macOS strict dispatch
timer reaches 16.691 ms host p95 without spinning but fails p99/worst at
16.712/18.358 ms, so no Dolphin build was made. Continue with a host-only Metal
scheduled-presentation/actual-`presentedTime` feasibility test; do not retry
these controls or move product pacing until the host gate passes. The
pipelined host harness subsequently passes two 600/600 scheduled runs with
zero drops and <=16.667 ms worst, but the live Dolphin form blocks in Metal and
fails at 18.022 ms p95 / 132.188 ms worst. Fullscreen also remains above the
gate at 17.493 ms p95. The product edit is removed; continue with a fresh
no-phase current-PGO compute sample. See
`docs/artifacts/2026-08-27/g5-pgo-pacing-controls-rejection.md`.

A byte-identical line-symbol build then mapped a fresh current-PGO Fountain
sample. The giant generated function and opcode counts are diffuse; the only
coherent new host cost was JIT-only `CompileExceptionCheck` work beneath
static gather writes. A regression-first candidate used Dolphin's
`FastWrite*`/`FastCheckGatherPipe` sequence while preserving widths, ordering,
and the generic arm's per-byte check cadence. Exact 440-field
candidate/control/candidate windows matched 1,501,757,755 cycles and
51,380,895 dispatches. CPU mean improved by just 0.022-0.107 ms, while p95
regressed from the 17.726 ms control to 17.883/17.843 ms. The candidate misses
the 5% threshold and is removed. Next separate ordinary 17-19 ms frames from
the rare 129-132 ms stall and trigger attribution at the stall rather than
selecting another edit from the diffuse sample. See
`docs/artifacts/2026-08-27/g5-static-gather-fast-check-rejection.md`.

The 129-132 ms rows from that rejection are all emulated frame `48436` with
identical guest work and the only 7.0-8.4 ms Cubeb mix burst. A corrected
90-second rolling System Trace trigger did not reproduce the event; an
earlier marker occurred only during profiler teardown and is rejected. Exact
Cubeb/no-output/Cubeb reversal brackets then matched 1,501,629,399 cycles and
51,369,928 dispatches. Removing audio worsened p95 from 17.599/17.631 ms to
17.668 ms, p99 from 18.158/18.395 ms to 19.277 ms, and worst from about
20.34 ms to 27.01 ms. Reject no-output: audio is required and is not the
ordinary p95 cause. Current official Dolphin has no newer relevant
Metal/Cubeb/timer scheduling mechanism, while the exact-work hidden
`SmoothEarlyPresentation=True` control worsens p95 to 17.700 ms and worst to
31.300 ms. Reject that setting as well and return to generated-code evidence.
See
`docs/artifacts/2026-08-27/g5-tail-trigger-and-audio-rejection.md`.

A semantics-preserving per-generated-chunk FP-availability cache then passed
focused direct-entry/`mtmsr` tests and the canonical 1,401-PC lockstep screen.
The retained Fountain profile bounded helper-call removal at at least 81.0%,
but linked `__text` grew 16.45%. Exact 385-frame candidate/control/candidate
windows matched 1,330,434,029 cycles and 45,572,090 dispatches; candidate
CPU-thread mean regressed from 16.114 ms to 23.750/23.650 ms, while total p95
regressed from 18.113 ms to 26.925/26.622 ms. PERF-067 is rejected and all
candidate source is removed. Do not retry per-chunk flags or another branch
at every FP instruction. See
`docs/artifacts/2026-08-27/g5-fp-availability-cache-rejection.md`.

A distinct CFG-local FP-gate candidate then moved 94,146 of 129,826 exact FP
checks out of sequential bodies while keeping exact-CIA direct-entry gates and
restarting checks at every control-flow leader and after `mtmsr`. Its own
Fountain profile matched the expected 6,556-function/2,727,666-block source
shape, Apple Clang accepted it cleanly, and linked PGO `__text` grew only
1.506%. Exact 440-frame candidate/control/candidate runs matched
1,501,629,399 cycles, 51,369,928 dispatches, 905,572 bursts, and 882 hook
fallbacks. CPU-thread mean improved by 0.236-0.490 ms, but candidate p95
worsened to 17.775/17.980 ms from the 17.677 ms control and the <=16.7 ms
share stayed 52.5%. PERF-068 is rejected and removed. The next diagnostic is
read-only attribution of the serialization edge present in live Dolphin but
absent from the already-passing three-drawable host Metal queue, not another
FP, timer, or presentation-setting edit. See
`docs/artifacts/2026-08-27/g5-fp-cfg-gate-rejection.md`.

The shared-state comparison gap is now closed. Patch 0014 records Dolphin's
savestated emulated VI/Movie frame beside each presentation row. Two equal
440-field Fountain control windows matched exactly at 3,567,157,803 guest
cycles, 59,374,686 native dispatches, and 905,158 bursts. A causal
A/B/reverse-A replay of the 64-bit gather candidate found warm candidate means
of 22.391-23.311 ms versus reverse-control means of 21.459-22.360 ms; the
ranges overlap and the fastest control won. The gather arm is removed. These
21.5-23.3 ms means and 24.1-26.3 ms warm p95 values remain a clear G5 failure.
See
`docs/artifacts/2026-08-27/g5-emulated-frame-shared-state-verdict.md`.

Actual Metal presentation attribution now supersedes CPU-side pacing as the
immediate G5 edge. With ordinary layer display sync, two no-phase controls put
only 53.3-53.6% of actual `MTLDrawable.presentedTime` intervals at or below
16.7 ms. Enabling only `CAMetalLayer.displaySyncEnabled` produced two
780-interval 100% brackets with 16.666709 ms worst. An exact 440-frame run
preserved 1,501,629,399 cycles, 51,369,928 dispatches, 905,572 bursts, and zero
fallbacks while measuring 16.666667 ms worst. The M1/Metal path therefore has
the required throughput.

Full-match worst still fails. A five-timestamp 6,674-interval run measured
16.666667/16.666709/99.999791 ms p95/p99/worst and 99.925% at <=16.7 ms. Both
misses began 103-131 ms before Metal; `nextDrawable` took 0.048/0.052 ms and
backbuffer preparation stayed below 0.106 ms. Combined CPU-GPU QoS still
missed at 100 ms, dual-core mode worsened worst to 133.332 ms, foreground
activation missed at 83.333 ms, and unbinding the per-frame MemoryWatcher
socket still missed at 83.332 ms. Reject those variants. Strip diagnostics and
screen only layer display sync on the reproducible canonical module next;
retain it only after canonical A/B/reverse-A plus visual/audio checks. That
screen now passes: display-sync-off canonical controls measured
18.147/18.561 ms p95 and only 55.141%/57.564% compliance, while the synchronized
candidate measured 16.666667 ms p95 / 16.666750 ms worst with 779/779
intervals compliant. The stripped product policy is retained and the signed
canonical product smoke passes. Its full match naturally reached results with
16.666625/16.666667 ms p95/p99, but ten missed refreshes left 66.666334 ms
worst. Join those actual gaps to canonical phase counters next; G5 stays open.
See
`docs/artifacts/2026-08-27/g5-metal-presentation-attribution.md`.

That canonical join is complete. After the standard two-second warm-up, 6,670
actual intervals measured 16.666667/33.332875/133.332917 ms p95/p99/worst and
98.306% compliance. Presentation interval to phase-total correlation peaks at
0.674781 for phase row `frame - 1`. Misses average 19.623207 ms CPU-thread
time versus 16.079824 ms in compliant rows and carry roughly 5% more guest
cycles and native dispatches. The worst row instead measures 131.944005 ms CPU
wall and 31.829401 ms CPU thread, exposing about 100 ms off-core. A default-off
Mach time-constraint policy was screened only on the faster PGO oracle. The
call succeeded, but a 773-interval bracket regressed from the prior 100%
control to 99.871% and introduced a 116.664750 ms stall. Reject and remove the
scheduler candidate; no full match is justified. Source and the incremental
runner are restored to the product display-sync policy with diagnostic markers
absent. See
`docs/artifacts/2026-08-27/g5-phase-join-and-time-constraint-rejection.md`.

The measured PGO compute path now has a supported private-profile package
bridge. `prepare-game.sh` accepts validated private LLVM profile data, while
`package-local-pgo-app.sh` preserves the canonical module pointer, requires a
hash-only cache manifest, builds/packages/signs the local app, and restores the
pointer on success or failure. A full current-source build reproduced the
known signed PGO module `bd089303...af26f5a`; a repeat logged a cache hit in
24 seconds; and a forced packaging failure still restored the canonical
pointer. The manifest contains profile SHA-256 `3f9d2aa4...f572ac12` and no
private path. PERF-071 closes profile consumption only: local profile training
and G5 remain open. See
`docs/artifacts/2026-08-27/g5-local-pgo-package-workflow.md`.

The private profile can now also be reproduced end to end from user-owned
inputs. PERF-072 adds a distinct C/Clang `--pgo-generate` cache identity plus
scripts to package an instrumented app, run a combat-gated isolated training
session, merge its raw profiles, and feed the result through PERF-071 while
restoring the canonical pointer on every exit. A real Fountain-only profile
has the same 6,556-function/2,727,666-block shape as the earlier oracle and
differs by only 873 aggregate counts. That difference nevertheless changes
127,816 `__text` bytes inside `func_80345940`, so the local product is not
promoted as byte-equivalent. Its clean 440-frame Fountain window exactly
matches 1,501,757,755 cycles and 51,380,895 dispatches and measures 16.664 ms
mean / 11.621 ms CPU-thread mean, reproducing the expected PGO compute class.
It still fails G5 at 18.065 ms p95 / 19.130 ms p99 / 22.509 ms worst. Retain
the workflow, not the binary as canonical. See
`docs/artifacts/2026-08-28/g5-local-pgo-training-workflow.md`.

IR-level PGO is technically functional but rejected for the product. A fresh
`-fprofile-generate` ThinLTO training module produced a real IR profile with
866 post-optimization functions, 3,947,902 blocks, and 52,990,495,633 counts.
The profile-use build emitted no mismatch warnings, but grew `__text` from
81,959,380 to 84,388,556 bytes. Its exact 440-frame Fountain interval matched
the frontend-PGO guest work while worsening CPU-thread mean from 11.620875 to
12.084786 ms. Total p95 was effectively flat at 18.047575 ms and worst rose to
69.163166 ms at steady emulated frame 48,394. PERF-073 restores the published
frontend training mode and rejects whole-module IR PGO. See
`docs/artifacts/2026-08-28/g5-ir-pgo-rejection.md`.

A profile-derived Mach-O order file is also technically functional but
rejected. Apple `ld` placed the requested dispatcher, helper, and generated
symbols contiguously while retaining the frontend-PGO module's 81,959,380-byte
`__text`. Exact emulated frames `48123..48562` matched PERF-072 at
1,501,757,755 cycles, 51,380,895 dispatches, 905,756 bursts, and 882 hook
fallbacks. Ordered CPU-thread mean improved from 11.620875 to 11.537926 ms,
only 0.714%, while total mean regressed from 16.663618 to 16.852325 ms and
worst rose from 22.509416 to 133.106958 ms. PERF-074 restores all temporary
linker/cache-identity inputs and rejects global code placement. See
`docs/artifacts/2026-08-28/g5-order-file-rejection.md`.

Required next work:

1. Use the retained PGO profiles as an oracle for one bounded dispatch-edge
   transformation; whole-module IR PGO and global order-file layout are
   rejected. Blind size
   thresholds, single-helper inlining,
   blanket outlining, timer spinning, combined no-EXRAM, and simply diluting
   its Fountain weighting with another stage are rejected.
2. Continue reducing the real p95/p99/worst tail to at most 16.7 ms.
3. Turn the proven isolated-save unlock procedure into a repository-native,
   data-free setup without distributing the generated GCI.
4. Retain an optimization only after both required stages improve and the G5
   worst-frame requirement is actually met.
