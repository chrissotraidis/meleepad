# G5 outlining and frame-pacing experiments

Date: 2026-08-24

## Scope

These are two falsifiable follow-ups to the retained local PGO result. Neither
experiment is retained. The portable PGO module remains the best-known local
module at SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.

## Blanket loop outlining

The clean generated module exposes 592 `loop_*` symbols while the PGO module
exposes 779. To test whether PGO's gain came primarily from shrinking large
dispatch callers, all 969 generated loop helpers were temporarily marked
`noinline` and rebuilt with the production macOS 14 O2 + ThinLTO settings.

The unsigned candidate was an arm64 macOS 14 dylib, 82,569,640 bytes, SHA-256
`e8cc83ac913a1b30a4ba7dd08efe26b7c60d535b63245da456751e6c1807add4`,
and exported all 969 loop helpers. It was rejected before a controlled stage
trace: a built-in four-player attract battle collapsed to 4.1 FPS. That gross
regression is sufficient to reject blanket outlining. The generated sources
and clean module cache were restored byte-for-byte.

## Apple Silicon precise-spin timer

Dolphin's precision timer sleeps until about 1.02 ms before its target and then
calls `std::this_thread::yield()` repeatedly. A default-off, environment-gated
Apple Silicon experiment replaced the OS scheduler yield with the ARM `yield`
hint during only that final spin and logged its mode identity. Game speed,
emulated clocks, graphics, audio, and the PGO game module were unchanged.

Temporary controller tracing proved FIFO commands became the expected port-1
`GCPadStatus` bits (`A=0x0100`, `Start=0x1000`). An `Always Connected` profile
flag did not alter title behavior and was rejected. All trace code and the
profile change were removed before timing.

Two fresh no-input attract runs used Cubeb, Metal, 1x internal resolution, and
the same PGO module. For each run, the selected interval is the cumulative
60,000-150,000 ms window from the closed buffered trace. There were no visual
or input actions inside either selected window.

| Render metric | Default timer | Precise-spin | Change |
|---|---:|---:|---:|
| Frames | 5,135 | 5,147 | +12 |
| Mean | 17.528468 ms | 17.490305 ms | 0.22% lower |
| Median | 16.682666 ms | 16.682791 ms | effectively unchanged |
| p95 | 17.848100 ms | 17.841458 ms | 0.04% lower |
| p99 | 18.813991 ms | 18.695980 ms | 0.63% lower |
| Worst | 3132.187584 ms | 2940.037500 ms | still multi-second |
| Frames <=16.7 ms | 61.25% | 65.86% | +4.61 points |

The vblank distributions were also effectively unchanged: default measured
16.683777 ms mean / 19.016708 ms p95 / 19.947468 ms p99 / 59.765208 ms worst;
precise-spin measured 16.683131 ms mean / 19.067145 ms p95 / 19.898321 ms p99 /
66.784167 ms worst.

The experiment is rejected. It does not materially improve p95, does not
remove large tail events, and spends about 1 ms per frame spinning. Attract
mode is diagnostic only and does not replace the required-stage traces.

Raw selected-window evidence:

- `g5-default-timer-attract-90s-render-times.txt` — SHA-256
  `b27035c9cfb98f91ffa1a52713568c0d7220fd0eff901ac13584b15baf6dde60`
- `g5-precise-timer-attract-90s-render-times.txt` — SHA-256
  `468ed6bb9578dae05d1433430f7681860b27d78d91ce8a53055156830ecf7350`
- `g5-default-timer-attract-90s-vblank-times.txt` — SHA-256
  `cce9b40caff383a0628ae2b49a5c04a3fc98bff4db969996404947793c862f7b`
- `g5-precise-timer-attract-90s-vblank-times.txt` — SHA-256
  `0dc9017184147e2b773b2f258d63e2f0c674ae2ea1af327b75443a15481a8edf`

## Cleanup

- Default timer source restored exactly.
- Temporary pipe and pad tracing removed.
- Main `GCPadNew.ini` restored byte-for-byte.
- Signed app module restored and verified at the PGO SHA above.
- No runner, writer, frontend, or Simulator remains active.
