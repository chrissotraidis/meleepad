# G5 Metal presentation and drawable-acquisition attribution

Date: 2026-08-27

Status: **DISPLAY SYNC RETAINED; STRICT G5 STILL OPEN**

## Question

The standalone three-drawable Metal harness holds 60 Hz while live Dolphin's
CPU-side phase logger does not. This experiment measured the display itself
with `MTLDrawable.presentedTime`, then timestamped immediately before and after
`CAMetalLayer.nextDrawable` to distinguish a slow M1/GPU, drawable starvation,
late Dolphin submission, and display-side deferral.

All runs used the same arm64 PGO runner module (`bd0893031a28e94b...af26f5a`),
Metal, Cubeb, the same Fountain savestate, and zero interpreter fallbacks.
`MELEEPAD_METAL_FORCE_DISPLAY_SYNC=1` changed only
`CAMetalLayer.displaySyncEnabled`; Dolphin VSync, CPU `SleepUntil`, and the
scheduled-handler presentation path remained unchanged. The actual-time logger
and override were default-off diagnostics in a disposable signed app. No ROM,
extracted game data, profile, savestate, or memory card entered Git.

## Actual-presentation result

Two 15-second no-phase controls with ordinary layer display sync disabled
measured only 53.59% and 53.27% of actual intervals at or below 16.7 ms. Their
p95 values were 18.460/18.661 ms and worst values were 34.006/34.433 ms.

With only layer display sync enabled, two identical 780-interval brackets
measured:

| Run | Mean | p95 | p99 | Worst | <=16.7 ms |
|---|---:|---:|---:|---:|---:|
| A | 16.666564 ms | 16.666625 ms | 16.666667 ms | 16.666667 ms | 100% |
| A2 | 16.666570 ms | 16.666628 ms | 16.666667 ms | 16.666709 ms | 100% |

An exact 440-frame run then matched the established control at
1,501,629,399 guest cycles, 51,369,928 native dispatches, 905,572 bursts,
zero interpreter fallbacks, and 882 hook fallbacks. Its actual presentation
p95/p99/worst were 16.666625/16.666650/16.666667 ms, with 440/440 intervals at
or below 16.7 ms. Display sync therefore did not skip or change guest work.

This falsifies raw M1 throughput as the 12.5 FPS cause. The same M1, runner,
module, renderer, audio path, and guest work can present every measured frame
at one refresh when the layer is synchronized correctly.

## Full-match boundary

The first remaining-match soak naturally transitioned to results after
113.406 seconds. Across 6,666 trimmed intervals it measured 16.666625 ms p95,
16.666667 ms p99, 83.332666 ms worst, and 99.865% at or below 16.7 ms. This is
a large improvement, not a G5 pass: the PRD requires the worst interval to be
at most 16.7 ms.

The five-timestamp repeat retained 6,674 full-match intervals. Its p95/p99/
worst were 16.666667/16.666709/99.999791 ms and 99.925% met 16.7 ms. Both
missed-refresh clusters began before drawable acquisition:

| Frame | Acquire-begin gap | `nextDrawable` | Backbuffer prep | Register gap | Presented gap |
|---:|---:|---:|---:|---:|---:|
| 628 | 130.992500 ms | 0.047792 ms | 0.105333 ms | 126.540958 ms | 99.998458 ms |
| 4378 | 102.810709 ms | 0.052125 ms | 0.062833 ms | 100.321958 ms | 83.332166 ms |

`nextDrawable` and the final backbuffer work are therefore excluded. The
combined CPU-GPU/presenter thread reached Metal late.

## Rejected follow-ups

- A Video-thread QoS candidate never activated because this product runs
  Dolphin's single-core CPU-GPU mode; it was discarded as a no-op.
- Raising the actual combined CPU-GPU thread to
  `QOS_CLASS_USER_INTERACTIVE` returned success but still produced 100.0 and
  33.3 ms presentation gaps. The candidate is rejected and removed.
- `CPUThread=True` split emulation and video work but worsened the result to
  four misses and 133.332 ms worst. Dual-core mode is rejected.
- Raising the exact app window with Computer Use before the match still
  produced four misses and 83.333 ms worst. Foreground state is excluded.
- MemoryWatcher performs a blocking Unix-datagram `sendto` every emulated
  frame. Unbinding its receiver for a 106-second combat window still produced
  an 83.332 ms worst interval, so watcher backpressure is excluded as this
  stall's cause. The blocking send remains diagnostic technical debt.
- A rolling System Trace was bounded to five seconds because disk was low.
  One valid trace caught only profiler-startup perturbation. A later run
  triggered on a genuine 33.333 ms miss, but Instruments aborted while saving
  and the trace bundle failed validation; it is not evidence. The three raw
  ktrace files created by these attempts and the failed bundles were removed.

## Reproducible canonical product

The diagnostic logger and environment override were then stripped. Two
reproducible patches add an opt-in ModernGekko macOS policy and force only the
Metal layer's `displaySyncEnabled` property; `package-macos-app.sh` enables the
policy for MeleePad. The package regression failed against the old canonical
runner, then passed after rebuilding. The rebuilt arm64 app is strictly
ad-hoc signed, its runner SHA-256 is
`93ebc4626307486602ed4525276ea9ed2c309b13c9a7805257981d3616563cd5`,
and its non-PGO module SHA-256 is
`44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`.
A product smoke loaded exact Fountain state and logged the compile-time product
policy with Metal, Cubeb, and the existing controller profile; no diagnostic
display-sync variable was present.

Checkpoint validation passed dependency bootstrap and both new patch
reverse-checks, 40/40 applicable CTest entries, 16/16 `gcpipe` tests, profile
hook separation, repository safety, shell syntax, diff whitespace, package
layout, arm64 identity, and strict ad-hoc signing. The first package-regression
implementation used `grep -q` under `pipefail`, which made a successful marker
match return 141 when `strings` received SIGPIPE; the test now consumes the
full stream and the reproducible package path completes.

The same canonical module was then measured in the disposable actual-time
runner. Two display-sync-off controls bracketed the synchronized candidate:

| Run | Intervals | p95 | p99 | Worst | <=16.7 ms |
|---|---:|---:|---:|---:|---:|
| no-sync A | 778 | 18.146675 ms | 23.061259 ms | 31.779291 ms | 55.141% |
| display-sync candidate | 779 | 16.666667 ms | 16.666708 ms | 16.666750 ms | 100% |
| no-sync A2 | 780 | 18.561353 ms | 26.956394 ms | 31.684208 ms | 57.564% |

This closes the canonical A/B/reverse-A requirement and does not depend on the
private PGO profile. A full canonical match naturally reached results after
113.369 seconds. Its actual p95/p99 were 16.666625/16.666667 ms and 99.850%
of 6,667 intervals met 16.7 ms, but ten missed refreshes produced a 66.666334
ms worst. The product change is retained for its large repeated improvement;
the full-match worst keeps G5 open.

## Decision

Actual Metal presentation is the correct G5 acceptance signal. The
product-scoped layer-display-sync behavior is retained because both PGO and
canonical comparisons show a large repeated improvement, the canonical
package path is reproducible, and short/exact brackets reach the target
without changing guest work. It is not a gate pass: multiple full matches
retain pre-acquisition stalls, and the canonical full match also exposes more
33 ms misses near its tighter compute margin. QoS, dual-core, focus, drawable
blocking, backbuffer work, and MemoryWatcher backpressure are rejected. Final
Destination and G6 remain blocked.

Next validate and publish this scoped improvement, then join actual
presentation gaps to the existing emulated-frame/CPU-thread phase counters on
the canonical module. The first question is whether canonical misses are
off-core stalls or on-core compute overruns before choosing another codegen
change. Do not retry the rejected scheduling variants.

## Evidence

Raw CSVs, bounds, and runtime identity excerpts are retained under
`docs/evidence/g5-metal-presentation-attribution/`. Key SHA-256 values:

- five-timestamp full-match control:
  `0f05e5f4eb856cffcc869e40d3ccbcaa066d3b9f1382de0e77b2f47d84ccb4b6`
- exact actual-presentation CSV:
  `82277e5c8b53c7a82a43e0d4b4422c2fa2b2750839a303d91a243670023e05c1`
- exact phase CSV:
  `dd8568024853cf2b85391acbc2a2023b8898c33180d75c2aaa25035712c59e8b`
- combined-QoS rejection:
  `8905884ca4d717e509ac48337dcca618615c65e0c25068d99f76711dd5fd5686`
- dual-core rejection:
  `bb77957b6451e0fea63350c8e51009f5d4739fa654b7f737749959df18c77d9a`
- foreground rejection:
  `5e4aaeabd27409f4774f96aad580f99d9cbe896e8a494b435e78cc85ffbf5f39`
- watcher-unbound rejection:
  `073a93efc78fe1f19d35df18064ec6663a82bda2273f2f166dbb5dccff2dc6de`
- canonical synchronized short run:
  `0406b0f39d3565f0756f3ed433e4c3da4a516d5f0ab9f2eedb6ead59f47fec66`
- canonical synchronized full match:
  `360ba7060a0521dea750a03b9764949e36a2af04871b642d948210e08581cd5c`
- canonical no-sync controls:
  `a800a52bc6231cc29c056f5e3a36e9683972fff849039beddd6d56837a4f5948`
  and
  `fa6c1d49185374c25b82ae67494eb808d19e30fec15e69c4afd5384c89680676`
