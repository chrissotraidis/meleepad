# G5 title-thread and overloaded-host rejection

Date: 2026-08-29

Status: **TITLE UPDATE NOT CAUSAL; OVERLOADED A/B/A EXCLUDED; G5 OPEN**

## Question

Every retained packaged G5 run enabled `show_fps_in_title`. ModernGekko then
starts a separate thread that wakes once per second, reads performance metrics,
formats the title, and dispatches an AppKit title update to the main queue.
Could that periodic WindowServer work cause the remaining isolated hitches?

## Disposable A/B/A

The first screen used the unchanged signed app, current runner and PGO module,
verified Fountain state, Metal/Cubeb, fullscreen configuration, exactly one
game process, no Simulator, and quiet 45-second balanced FIFO input. The sole
intended variable was `show_fps_in_title=true/false/true` in the private user
configuration. The setting was restored to `true` after the reversal.

The three shutdowns did not execute comparable guest work. Over a common final
1,401-row boundary they degraded monotonically while the option toggled A/B/A:

| Run | Title thread | Mean | FPS | p95 | p99 | Worst |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| A | on | 23.989348 ms | 41.685 | 46.640167 | 57.773041 | 85.125666 |
| B | off | 26.049351 ms | 38.389 | 50.417667 | 57.780791 | 106.806500 |
| A2 | on | 31.143193 ms | 32.110 | 55.417334 | 67.276000 | 97.580250 |

No Game Mode session was confirmed for these launches. Read-only host snapshots
also showed varying substantial work from Jump Desktop, Codex/OpenCodex,
`airportd`, WindowServer, and other normal user processes. None was altered,
and spot CPU values are not used to blame a particular process. The enormous
monotonic A-to-A2 drift, plus different native dispatch/cycle totals in the
same wall-duration input, makes the entire A/B/A invalid as a title-thread or
product-speed comparison. It is not a new regression baseline.

Private render-log SHA-256 values:

- A: `203f51bf5bc5a49fd5becc3e9dbd4777dc7c9c680f49b82504c6879708dc3778`
- B: `f31314991f50cf239e76739f6ba2c717c5cf774571733433bc5e54d601147045`
- A2: `24439f5b60656ecbfce01477baf0510f2072481e91cca7bb6450d57803931406`

## Clean retained periodicity check

The title thread still has a specific falsifiable signature: one update per
second against 59.94 FPS should place affected rows at a nearly fixed frame
phase modulo 60. Over a 2,001-row window the source/display drift moves that
phase by only about two frames, so a causal title hitch should cluster in one
or two adjacent phase bins.

The earlier clean, quiet retained controls do not show that signature:

- PERF-154's three rows above 17 ms occur at phases 26, 21, and 48. The best
  adjacent pair of phase bins contains only one of three.
- PERF-165's seven rows above 17 ms occur at phases 4, 24, 34, 35, 18, 56,
  and 30. The best adjacent pair contains only two of seven.
- Their >20 ms rows are similarly dispersed rather than recurring every
  roughly 60 frames.

This rejects the once-per-second title update as the common cause of the clean
observer-free producer tail. It also explains why disabling it during the
overloaded screen did not produce even a directional improvement.

## Decision

Do not remove the user-visible FPS title or change its update thread for G5.
The clean tail is not phase-locked to it, and the attempted live A/B/A was
dominated by changing external host load. No product source, app, module, ROM,
save, or package changed. The private config is restored, no game or Simulator
is running, G5 remains open, and G6 remains blocked.
