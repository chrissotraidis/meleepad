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

Required next work:

1. Use the retained PGO binary/profile as an oracle for a smaller static
   compute-path decision; blind size thresholds, single-helper inlining,
   blanket outlining, timer spinning, and combined no-EXRAM are rejected.
2. Continue reducing the real p95/p99/worst tail to at most 16.7 ms.
3. Turn the proven isolated-save unlock procedure into a repository-native,
   data-free setup without distributing the generated GCI.
4. Retain an optimization only after both required stages improve and the G5
   worst-frame requirement is actually met.
