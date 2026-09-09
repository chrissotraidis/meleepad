# Native macOS comparison: September 9–10, 2026

Completed the bounded comparison requested by the owner. Native MeleePad ran
v1.02 combat at 59.94 FPS in two short trials on this M3 Max. melee4mac sustained
60 Hz at its 60 FPS setting; its experimental 120 FPS setting slowed simulation
in this scene. No performance patch is promoted from these results.

## Measured results

Apple M3 Max, 128 GiB, macOS 26.6.2; built-in Retina display reports nominal
120 Hz and maximum 120 FPS through CoreGraphics/AppKit. Both games used Metal,
1x internal resolution (640 × 528), and the same owner-created v1.02 save state:
Mario human versus Kirby CPU level 1 on Onett. One game ran at a time, without
compilation. Measurements lasted 30 seconds after startup/load work.

| Build / setting | Rate measured | Simulation estimate | Other evidence |
| --- | --- | --- | --- |
| MeleePad control | 59.944 host frames/s | Not independently counted | Median 16.683 ms; p95 17.459 ms; 0/1,798 intervals >20 ms |
| MeleePad repeat | 59.942 host frames/s | Not independently counted | Median 16.696 ms; p95 17.398 ms; 1/1,798 intervals >20 ms |
| melee4mac 60, VSync, new queues | 60.000 callbacks/s | 60.017 Hz | Median GPU busy 0.693 ms |
| melee4mac 60, VSync, original queues | 60.000 callbacks/s | 59.933 Hz | Median GPU busy 0.599 ms |
| melee4mac 120, VSync | 97.517 callbacks/s | 48.788 Hz | Median GPU busy 0.682 ms |
| melee4mac 120, no VSync | 95.701 callbacks/s | 47.916 Hz | Median GPU busy 0.641 ms |

[Machine-readable measurements](artifacts/native-macos-comparison-2026-09-10/results.json)
retain the full summaries and fixture hash. Host frame completion is **not**
the same metric as a CoreAnimation presentation callback. Do not compare their
long-frame counts as if they used identical instrumentation. Callbacks do not
prove every complete frame physically appeared on the panel.

The other runtime admitted the state as active Versus and screenshots confirmed
the same fighters/stage. This is not a deterministic cross-runtime input replay:
controller configurations and runtime hooks differ, and subsequent game outcomes
can diverge. The control captures were manually started after restoring the
fixture, rather than at an identical simulation frame. These short samples
establish native Mac functionality and reject a universal 120 FPS assumption;
they do not establish four-player, sustained thermal, netplay or iPhone acceptance.

## What we learned and the next experiment

melee4mac implements an additional geometry render using predicted joint/camera
poses, then restores original transforms before simulation. Its target is
60 simulation updates plus 120 visual updates, not 120 Hz physics. See its
[refresh implementation](https://github.com/t3dotgg/melee4mac/tree/a276aeb70f9879204d891d967f1c9442523568e1/native/macos/refresh).
Our Mac results do not reproduce a steady 120 in Onett. Different hardware,
scenes and settings can explain other reported results.

A separate five-second `sample` capture of the 120 FPS path found 2,695 of
3,856 CPU-GPU-thread samples beneath generated `chassis_dispatch` (~70%). The
largest direct generated chunks were `func_80361940` (299), `func_8033D940`
(294), and `func_8035D940` (226). These are large generated chunks, not exact
original game-function attribution. The directly visible refresh helper subtree
was only 23 samples; this does not include the additional game's entire draw
traversal. The profile is excluded from the timing table.

The most defensible next experiment is to map those sampled native offsets back
to exact guest PCs and decompiled HSD/GX functions, then profile the matching
60 Hz MeleePad combat path. Replace or simplify only a shared, measured hot
routine, with CPU-state/memory equivalence checks and the same-state whole-app
A/B. Do not infer a speedup from the decompilation percentage or chunk name.

Two smaller upstream ideas remain candidates: precise presentation/GPU telemetry
and earlier Metal command submission. The original/new queue comparison did not
show a benefit here (median submit-to-callback 22.82 versus 23.14 ms), so there
is no justification to change our default queue settings yet. Our v1.02 runtime
already configures the SelectThread idle address `0x8034B164` through its guarded
secondary-idle path; rediscovering the same address is not a new optimization.
120 FPS adds work and should remain a separate optional Mac feature experiment,
not a proposed fix for iPhone 14 slowdowns.

## Reproduction and retained local evidence

- MeleePad source: `2557822`, clean runner rebuilt after temporary input diagnostics
  were removed. Runner SHA-256:
  `d2626855b8b09761460215e97d587d769e60f246296b6d5533a6a54dff88352e`.
- Explicit v1.02 module SHA-256:
  `6eda112765d2726701d3439c0f5dfb289cc48c2d3af8c316aebff7c2ff8ee09a`.
  The package's legacy fallback module pointer is older; the comparison launcher
  explicitly supplies the v1.02 module and extracted data.
- melee4mac source: `a276aeb70f9879204d891d967f1c9442523568e1`, built through its
  official `native/macos/build.py --iso <owner revision-2 CISO> --jobs 6`.
  Matching decompilation verification passed; no verification bypass.
- Other runtime SHA-256:
  `14b8ca89e3a15528bc734e372f7c842d7839c15475774595b228b40d11457da2`;
  module SHA-256:
  `e477427cbb2f3fde926f433a30f4d7c76bc047b4e193e0058ed8fc9c204afb03`.

Ignored local work directory: `ref/native-port-learning/macos-comparison/`.
It retains the private `MeleePad.app`, clean/setup build logs, controller fixture,
`meleepad-user/StateSaves/GALE01.s02`, both control CSV/windows/summaries,
`other-*/summary.json`, frame CSVs, match PNGs, runtime logs and
`other-120.sample.txt`. `setup-phase.csv` contains setup/concurrent build activity
and is not benchmark evidence. Temporary input diagnostics were removed and the
clean runner rebuilt before the first control. Both test games were stopped.

Repeat the other project's benchmark from the repository root with:

```sh
python3 ref/melee4mac-research/native/macos/benchmark.py \
  --app 'ref/melee4mac-research/build/native/Melee for Mac.app' \
  --state ref/native-port-learning/macos-comparison/meleepad-user/StateSaves/GALE01.s02 \
  --output ref/native-port-learning/macos-comparison/NEW-RUN \
  --fps 120 --scale 1 --seconds 30 --vsync
```

For MeleePad, launch the private comparison app, restore State 2 from its States
menu, and select a 30-second timestamp window in `MELEEPAD_FRAME_PHASE_LOG` after
loading. Use a frame-indexed replay before attributing small changes to code.

No physical device, original app data, game image, release or production module
pointer was changed. Private bundles include owner-derived game material and
must not be uploaded. Only documentation and aggregate measurements are public.
