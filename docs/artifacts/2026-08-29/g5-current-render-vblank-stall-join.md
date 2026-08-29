# G5 current render/vblank stall join

Date: 2026-08-29

Status: **CURRENT PRE-RESULTS HOLDS BEGIN IN THE VBLANK/CPU PATH; G5 OPEN**

## Question

Are the remaining 23-33 ms pre-results gaps in the clean confirmed-Game-Mode
Fountain run downstream compositor holds, or does the guest vblank/combined
CPU-GPU path lose the same wall interval before a frame is submitted?

## Read-only join

PERF-176 uses only the private render and vblank logs retained from PERF-174.
No game, profiler, observer, source edit, setting change, or Simulator ran.
Both trackers use the same steady host clock, but they begin at different
points during boot. Matching the rare pre-results spikes establishes a stable
offset of exactly 172 rows between render and vblank logs:

| Render row | Render interval | Vblank row | Vblank interval | Row offset |
| ---: | ---: | ---: | ---: | ---: |
| 2,481 | 26.488416 ms | 2,653 | 25.768667 ms | 172 |
| 3,081 | 23.653459 ms | 3,253 | 23.446458 ms | 172 |
| 3,790 | 33.217583 ms | 3,962 | 34.698125 ms | 172 |
| 3,807 | 33.272458 ms | 3,979 | 34.979375 ms | 172 |
| 4,140 | 33.284417 ms | 4,312 | 34.413042 ms | 172 |
| 4,730 | 33.291500 ms | 4,902 | 33.969416 ms | 172 |

Every render interval above 20 ms after early boot and before the row-6,784
results transition has a corresponding vblank stall at the same fixed offset.
The durations agree closely enough to reject a compositor-only explanation
for this class. The guest/vblank path itself advances late because the combined
CPU-GPU thread loses host execution; presentation then inherits that gap.

The separate row-6,784 transition remains a different class. A clock-phase
join places about 39 vblank callbacks inside its 621.296875 ms presentation
drought, consistent with the already stronger PERF-130/131 proof that Melee
intentionally advances many internal fields without a new XFB at results. This
approximate count is not used to replace PERF-130/131's exact 27-field phase
evidence.

Private source hashes:

- clean render log:
  `72152e5dfaa912f737c841d44c49727ed6d1c51c5854de9e9440fe78ae1d2d02`;
- clean vblank log:
  `b6b4f57a8e7824f1d1a2c0094c8250d8aa1b3a15794d571053b1a78b5663f06c`.

## Scheduler audit and decision

The current evidence does not justify another product-local scheduling edit:

- combined-thread user-interactive QoS, priority, time constraint, Game Mode,
  timer variants, process-activity hints, and dual-core mode already have
  causal reversals;
- generic workgroups do not grant scheduling policy, while interval workgroups
  are audio-specific; and
- Dolphin's `THREAD_AFFINITY_POLICY` helper is an Apple cache-locality hint for
  grouping related threads, not supported processor or P-core pinning. Tagging
  this single combined critical thread cannot protect it from descheduling.

**Retain the upstream host-execution-loss attribution.** Do not relabel these
rows as M1 compute, static-recompiler, GPU, Cubeb, or compositor saturation,
and do not build an affinity no-op. A next causal test needs a genuinely new
supported scheduling mechanism or an explicitly authorized reversible
external-load isolation. G5 remains open; Final Destination and G6 remain
blocked.
