# G5 menu foreground/background pacing attribution

Date: 2026-08-26

## Question

The user reports clearly major slowdowns in animated menus, while short CSS
controls often average 59.94 FPS with only a roughly 0.2 ms strict-tail miss.
Does a longer normal soak enter a sustained low-FPS state, and does macOS
window/process activity affect the pacing distribution?

## Normal background CSS soak

MemoryWatcher started before the restored signed normal runner and verified the
genuine title lockout, main menu, and `GameState=0x02020100` CSS route. The
window was then left backgrounded behind Codex for five untouched minutes.
Across the final 18,000 CSS frames:

| Metric | Result |
|---|---:|
| Mean / FPS | 16.683385 ms / 59.940 FPS |
| p95 / p99 / worst | 17.837625 / 18.017583 / 84.991792 ms |
| Frames <=16.7 ms | 52.994% |
| CPU-thread mean | 8.325521 ms |
| Throttle wake lateness mean / p95 | 0.924872 / 1.319556 ms |
| Frames >25 / >50 ms | 8 / 3 |

There was no sustained half-rate state. No rolling window fell below 55 FPS:

| Rolling window | Worst FPS |
|---|---:|
| 1 second | 55.523 |
| 2 seconds | 57.685 |
| 5 seconds | 59.016 |
| 10 seconds | 59.473 |

The three largest hitches were 84.992, 70.701, and 52.621 ms. This explains
how the menu can look visibly choppy while the long-term title counter remains
59.9: the observed problem is pacing jitter and isolated hitches, not a stable
12.5/30-FPS mode in this run.

## Raised normal control

A second cold normal run used the same watcher route, Metal, Cubeb, runner,
module, and phase logger. Computer Use visibly confirmed coherent CSS and
explicitly raised the window. The final 3,600 frames measured:

| Metric | Background normal | Raised normal |
|---|---:|---:|
| Mean | 16.683385 ms | 16.683371 ms |
| p95 | 17.837625 ms | 16.926792 ms |
| p99 | 18.017583 ms | 17.247541 ms |
| CPU-thread mean | 8.325521 ms | 8.526518 ms |
| Wake lateness mean | 0.924872 ms | 0.070476 ms |
| Wake lateness p95 | 1.319556 ms | 0.129847 ms |

Foreground state reduced mean wake lateness by about 13 times even though CPU
work did not fall. The renderer, guest work, and nominal cadence are not the
source of this difference.

## NSProcessInfo activity candidates

Apple documents `NSProcessInfo` activities as hints that disable some system
heuristics, and `NSActivityLatencyCritical` as requesting the highest timer and
I/O precision available. Two temporary, lifecycle-balanced platform variants
began an activity after successful macOS window initialization and ended it in
the platform destructor:

| Background candidate | p95 | Wake lateness mean / p95 |
|---|---:|---:|
| user-initiated-allowing-idle-sleep + latency-critical | 17.834000 ms | 0.925667 / 1.317346 ms |
| user-interactive + latency-critical | 17.820708 ms | 0.963424 / 1.314861 ms |

Neither changed the background distribution. Both candidates were removed.
The activity API requires explicit completion and warns against unnecessarily
long high-priority activities, so an ineffective permanent hint is not
retained.

Apple references:

- https://developer.apple.com/documentation/foundation/processinfo
- https://developer.apple.com/documentation/foundation/processinfo/activityoptions/latencycritical
- https://developer.apple.com/documentation/foundation/processinfo/beginactivity(options:reason:)

## Superseding same-process result

A subsequent foreground -> background -> foreground transition inside one
unchanged process measured statistically identical 59.940 FPS tails and
0.072-0.077 ms mean wake lateness in all three states. The cross-process
foreground/background attribution below is therefore withdrawn; it was an
association between separate runs, not causal focus evidence. The activity
candidates remain rejected. See `g5-active-transition-pacing.md`.

## Original decision and next step

**SUPERSEDED BY THE SAME-PROCESS TRANSITION RESULT.** At the time, the normal
signed runner
`c26625db7fd1eb504f418ad8ab52a3accc61bb222fd08b369c7804a5465d5598`
and corrected module
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`
are restored. No runtime or Simulator remains.

Do not retry process-activity flags. The next diagnostic must record actual
application-active transitions alongside phase rows and run a longer raised
normal CSS control. Retain a focus-policy change only if foreground state is
proven causal across matched transitions and the change improves visible
foreground play rather than merely spending power on an obscured window.

## Retained artifacts

- `g5-normal-css-long-soak-phase.csv` — SHA-256
  `63777181fd5420351330f5a9a7a93320451330247e135f918864df4d5fb49446`
- `g5-normal-css-raised-phase.csv` — SHA-256
  `eef0cea2e9ef482746d03a956491bc0186eb7877836cdd26193a224b2f36f1a2`
- `g5-latency-activity-background-css-phase.csv` — SHA-256
  `3ea0bb47e60040bdec48762e6a838d4669ed3de7061edd5388a0a6176afc15ce`
- `g5-interactive-activity-background-css-phase.csv` — SHA-256
  `943294610f7f745b067b1d2b73fa6a120485d74e17b9ff129cf6217d68f53de8`
