# Corrected Fountain deadline attribution

Date: 2026-08-25

Status: **PACING OVERSHOOT EXCLUDED; G5 COMPUTE TAIL REMAINS**

## Diagnostic change

The default-off phase logger now records:

- requested CPU throttle duration; and
- positive wake lateness, only when `SleepUntil` was entered before its target.

No timer, renderer, audio, PGO, or generated-code behavior changed. The
incremental runner built successfully. A 111-row smoke test populated both new
fields on 61 rows and found no row whose requested duration exceeded actual
time inside `SleepUntil`.

The canonical dependency patch was also repaired to include its previously
omitted new `FramePhaseTiming.h`. The complete phase patch applies cleanly to
pinned Dolphin `e13ab348f13cd67879f6db6e9d7185410f8f62c6` after the documented
prerequisite patches.

## Verified route and bracket

The run used the same corrected module as the preceding phase attribution:

- module SHA-256:
  `524dd2df5a65ce36b16692350faac5f44ee42858e2771a92327711b5f3c06639`;
- packaged diagnostic runner SHA-256:
  `fd84cb468aa93fa649920283ea7c56919c8d4f0d71af0f8616830cf7dbec3cba`;
- isolated user directory:
  `/private/tmp/ssbmpad-lateness-fountain.yO5Yiy`;
- full local phase log SHA-256:
  `fddd2d1d047127186947232543839e6b0ce7c2b1c5bec2ddaacec9c4489d3cf3`.

The automated route's final Stage Select memory predicate timed out, but a
fresh native-window inspection at that exact point visibly showed `Fountain of
Dreams` highlighted at 59.9 FPS. Launching from that state visibly produced
live Fountain combat at 59.9 FPS. The stale predicate was not treated as a
stage failure.

The capture-free combat bracket ran from Unix time `1787703925` through
`1787703990`. The log grew from 11,832 to 15,790 lines. Trimming 120 rows from
both edges retains frames 11,951 through 15,668 in
`g5-corrected-fountain-lateness.csv`, SHA-256
`c210e12042a8383ce2ee5eb7eb7ffdcbbde3a003b9aee4b57ee79331deb7a52f`.
No Simulator was booted.

## Results

| Phase | Mean | Median | p95 | p99 | Worst |
|---|---:|---:|---:|---:|---:|
| Total | 16.683353 | 16.686583 | 17.011436 | 17.233304 | 24.185167 |
| Derived compute | 11.311844 | 11.300683 | 12.477118 | 13.635830 | 24.158668 |
| Actual throttle sleep | 5.357522 | 5.351728 | 6.558198 | 7.036495 | 7.523458 |
| Requested throttle | 5.288771 | 5.304555 | 6.390840 | 6.870080 | 7.323236 |
| Wake lateness | 0.068460 | 0.030299 | 0.198742 | 0.214000 | 0.248265 |
| Video build | 0.053832 | 0.051750 | 0.076595 | 0.102111 | 0.259292 |
| Present | 0.028744 | 0.018834 | 0.071471 | 0.205540 | 0.312625 |
| Audio mix | 0.784225 | 0.750354 | 1.266340 | 1.317359 | 1.442125 |

Only 2,031 of 3,718 frames (54.626%) meet 16.7 ms. Wake lateness correlates
only `0.024467` with total frame time. Derived compute correlates `0.370500`.
The >16.7 ms rows average 11.462 ms compute versus 11.187 ms in the body.

The five worst frames are decisive: each entered throttle after its deadline,
so requested sleep and wake lateness are both zero. Their total/compute times
are 24.185/24.159, 22.904/22.897, 22.117/22.085, 20.067/19.995, and
19.406/19.470 ms.

## Decision

macOS deadline wake-up overshoot is not the cause of the strict Fountain tail.
No timer/spin-window experiment is justified by this evidence. G5 remains
open because the corrected module still produces intermittent compute-only
overruns and a 17.011 ms p95.

The next smallest diagnostic is per-frame generated-work attribution: add
default-off static-recompiler burst/cycle/native/fallback deltas to the same
CSV, replay Fountain, and determine whether the compute overruns reflect more
guest work or higher host cost for comparable guest work. Only then select one
generated-code behavior experiment.

