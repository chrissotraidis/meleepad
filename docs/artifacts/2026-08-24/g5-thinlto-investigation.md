# G5 ThinLTO investigation

Date: 2026-08-24

Scope: diagnostic aligned boot/attract comparison on native arm64 macOS. This
is not the required Final Destination or Fountain of Dreams acceptance trace.

## Root cause

`moderngekko-port` described the Clang module as ThinLTO in its cache identity,
but configured CMake under `CMAKE_NINJA_FORCE_RESPONSE_FILE=1`. CMake's Apple
IPO probe then failed while invoking `/usr/bin/ar @response-file`, so the
generated module's actual compile and link commands contained no `-flto`.

Allowing platform-default Ninja response-file behavior on Apple makes the same
CMake module template pass its IPO probe and emit `-flto=thin` for compile and
link. The cache identity now includes `cmake:platform-response-files`, ensuring
the old non-LTO artifact cannot be reused as the fixed build.

## Comparison

All values are milliseconds from Dolphin's `LogRenderTimeToFile` output. The
same clean application state and generated GALE01 revision-0 program were used.
Rows compare identical presented-frame indices from boot. Startup/transition
outliers are retained. These aligned sequences are diagnostic because attract
mode is not a G5 acceptance scene.

| Build | Frames | Mean | Median | p95 | p99 | Worst | Mean FPS |
|---|---:|---:|---:|---:|---:|---:|---:|
| Baseline O2, no actual LTO | 1-2000 | 17.822 | 17.064 | 24.920 | 28.928 | 1653.705 | 56.11 |
| Hand O3 + ThinLTO + native | 1-2000 | 17.503 | 16.750 | 21.699 | 22.724 | 1652.006 | 57.13 |
| Official O2 + ThinLTO | 1-2000 | 17.502 | 16.660 | 21.456 | 22.638 | 1652.311 | 57.14 |
| Baseline O2, no actual LTO | 2001-3500 | 20.247 | 17.562 | 26.069 | 29.790 | 1227.385 | 49.39 |
| Hand O3 + ThinLTO + native | 2001-3500 | 17.778 | 20.472 | 21.582 | 22.884 | 36.329 | 56.25 |
| Official O2 + ThinLTO | 2001-3500 | 17.703 | 20.285 | 21.207 | 22.444 | 56.788 | 56.49 |
| Baseline O2, no actual LTO | 2501-3000 | 23.604 | 24.211 | 26.691 | 29.289 | 141.378 | 42.36 |
| Hand O3 + ThinLTO + native | 2501-3000 | 19.950 | 20.970 | 21.921 | 23.166 | 36.329 | 50.12 |
| Official O2 + ThinLTO | 2501-3000 | 19.728 | 20.758 | 21.412 | 22.260 | 26.904 | 50.69 |

For frames 2001-3500, official O2 + ThinLTO improves mean frame time by
12.6% and p95 by 18.6%. O3 plus native CPU tuning did not improve on official
O2 + ThinLTO and is rejected as unnecessary complexity.

## Result

**PARTIAL.** The build-system defect is fixed and the reproducible O2 + ThinLTO
module is the retained candidate. The scene remains above the 16.7 ms G5
ceiling, and controlled Final Destination plus Fountain of Dreams traces are
still required. `smc_failed=0` at clean shutdown.

Retained raw traces:

- `g5-c-backend-packaged-title-render-times.txt`
- `g5-o3-thinlto-native-boot-attract-render-times.txt`
- `g5-o2-thinlto-official-boot-attract-render-times.txt`
