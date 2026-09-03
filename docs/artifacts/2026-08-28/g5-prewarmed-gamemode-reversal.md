# G5 prewarmed Game Mode reversal

Date: 2026-08-28

Status: **GAME MODE SEVERE-TAIL MITIGATION RETAINED; G5 OPEN**

## Question

PERF-112 proved the remaining long Fountain frames were runnable-thread
descheduling rather than static-recompiler execution. The earlier Game Mode
screen was confounded by 108-134 ms cold Metal shader compilation and did not
prove that Game Mode was active. PERF-114 through PERF-116 repeat the full
6,723-frame combat span after the four exact EFB pipelines are prewarmed.

All runs use the same M1, signed runner, frontend-PGO module, native 640x528
configuration, fullscreen window, Metal, Cubeb, and slot-1 state. Each executes
exactly 23,506,257,223 guest cycles, 805,358,717 native dispatches, 14,058,507
bursts, and 13,460 hook fallbacks, with zero interpreter or EFB pipeline
misses. The only intended A/B/A variable is `LSSupportsGameMode`.

## Result

| Run | Game Mode | mean | p95 | p99 | worst | >33 ms | <=16.7 ms |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| PERF-114 A | on | 16.680769 | 17.288042 | 18.112750 | 24.336541 | 0 | 3,625 |
| PERF-115 B | off | 16.722169 | 17.725125 | 18.938167 | 179.210791 | 6 | 3,831 |
| PERF-116 A2 | on | 16.673662 | 17.461625 | 18.196334 | 24.380917 | 0 | 3,787 |

Game Policy logs prove both eligible runs entered a fullscreen gaming session,
then logged `Game mode enabled` and `Game mode status is now on` before the
combat state was loaded. The ineligible reversal received no Game Mode session.
Both eligible runs eliminate every severe frame; the reversal contains six,
including adjacent 179.211/132.774 ms runnable-descheduling stalls.

This is a material, repeated host-tail mitigation, not a G5 pass. Both eligible
p95 values and 24.3 ms worst frames still exceed 16.7 ms. The phase logger also
includes CPU-side drawable backpressure that prior `presentedTime` evidence
proved can coexist with exact 60 Hz display cadence.

## Product-path transfer

A signed topology harness preserved the real product relationship:
LaunchServices owned the bundle wrapper, the wrapper remained as PID 47523,
and fullscreen `MeleePadRunner` PID 47528 ran as its child. Game Policy logged
the wrapper app, then a fullscreen gaming session and Game Mode on while the
child runner advanced gameplay. The existing frontend/runner architecture
therefore transfers Game Mode correctly; no helper bundle or launcher rewrite
is required.

Fresh installs now default to fullscreen, while the existing menu toggle and
saved user choice remain intact. The package regression requires
`fullscreen=true`, the games category, `LSSupportsGameMode=true`, and the
four-pipeline prewarm marker. A fresh signed package passes.

## Decision and next experiment

Retain fullscreen as the fresh-install default and keep the opt-out toggle.
Do not claim M1 insufficiency or G5. Do not retry QoS, time constraints, timer,
drawable-lifecycle, dual-core, or static compiler-flag variants.

The next measurement must use the retained synchronized display path and an
observer that does not add a drawable-presented handler. The concrete question
is whether Game Mode removes the rare missed-refresh clusters in actual display
cadence, not whether CPU-side phase p95 falls below the display period. Final
Destination and G6 remain blocked until Fountain worst actual interval is
proved at or below 16.7 ms.
