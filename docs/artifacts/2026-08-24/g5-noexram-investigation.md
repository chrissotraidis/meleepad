# G5 GameCube-only RAM specialization investigation

Date: 2026-08-24

## Question

Would removing the Wii MEM2 check from every inlined GameCube memory access
materially improve the CPU-bound generated module without regressing tail or
worst-frame behavior?

The experiment was default-off and isolated. `get_ram_ptr` skipped the EXRAM
branch only under `GXRUNTIME_ASSUME_NO_EXRAM`; a second runtime-test target
verified MEM1 access and rejection of a MEM2 address in that mode. Both the
normal and specialized tests passed before the module comparison.

## Controlled pair

Both runs used the native arm64 packaged runner, Metal, 640x528 internal
resolution, Cubeb audio, the FIFO controller, Yoshi versus level-1 CPU Ice
Climbers, Fountain of Dreams, and the same movement/attack/jump workload. The
screen, matchup, stage, active combat, and completed clean results were
visually verified. Temporary input tracing proved FIFO command parsing and the
corresponding GameCube pad bits (`START=0x1000`, `A=0x0100`, `B=0x0200`); all
trace code was removed before measurement.

The active screenshot boundary was slightly later in the candidate match, so
both distributions are bounded to an equal cumulative 105 seconds that end in
active combat.

| Metric | Clean | No-EXRAM candidate | Change |
|---|---:|---:|---:|
| Frames | 5,921 | 6,135 | +214 |
| Mean | 17.735650 ms | 17.116890 ms | 3.5% lower |
| Median | 17.445250 ms | 16.717917 ms | 4.2% lower |
| p95 | 19.410959 ms | 18.831875 ms | 3.0% lower |
| p99 | 21.230458 ms | 20.288292 ms | 4.4% lower |
| Worst | 1320.456208 ms | 1385.798458 ms | regression |
| Frames <=16.7 ms | 1,314 (22.19%) | 2,862 (46.65%) | +24.46 points |
| Frames >40 ms | 4 | 3 | one fewer |

Evidence:

- `g5-clean-noexram-pair-yoshi-ice-fountain-105s-render-times.txt` — SHA-256
  `666daa552431f516d199414840809c0ce6356abe6d7234f7676415c364404097`
- `g5-noexram-yoshi-ice-fountain-105s-render-times.txt` — SHA-256
  `db2832808a3a07b1407c2a02d9fe1eafa19652d55bc880ff05fb5f33cff76f9e`

## Decision

**Rejected.** The sustained improvement is below the 5% retention threshold,
and the critical worst frame regressed by 65.342 ms. The candidate's 1.386 s
hitch occurred 82.309 seconds into active combat; the clean run had a 1.320 s
hitch at 98.440 seconds. These isolated hitches recur across clean, PGO, and
specialized runs and dominate the G5 worst-frame gate.

The specialization, its extra tests, and temporary input traces were removed.
The normal GXRuntime suite passes, the app verifies, and the production module
was restored to SHA-256
`5bbd12e0704d6ce2221603d3fc016eb9aba88756b88d2139809c8b6ee1b09b82`.

The next falsifiable experiment is to attribute the recurring approximately
1.3-second hitch using a time-correlated process/system sample before making
another steady-state optimization.
