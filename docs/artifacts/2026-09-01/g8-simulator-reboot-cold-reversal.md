# PERF-270 — Simulator-reboot cold reversal

Date: 2026-09-01

Status: **exact route holds target after reboot; intermittent ordinary gate remains**

## Question

Does rebooting the one retained Simulator, while preserving the installed app,
game data, and saves, recreate the exact route's earlier 53.5 FPS cold failure?

## Method

Stop and reboot the same iPad Pro 13-inch (M5) Simulator, then run the unchanged
published candidate through the state-verified Samus/level-1-CPU-Kirby
Stock/04/05:00 Fountain route. Enable phase timing for attribution but omit the
dispatch sampler. Preserve the app container and all user data.

Private hashes:

- phase CSV:
  `1313b4246af9be84e3253a49f6b9e9ab99af855a509134a9875f54fca5853bf1`;
- route log:
  `dc6ff4d5f651769031fa08bcdae6a4695230705f095d86cf471f4f9d82942a3b`;
- runtime log:
  `73d438fc1cc1a5ac88192e98c03240bfeac512cae2cdd85a409aa1e5ea8c4ec2`.

## Result

The complete runtime reports 59.7-60.0 FPS and 59.8-60.0 VPS. The route reaches
verified combat in 49.21 seconds and continues without a crash, FIFO,
malformed-command, panic, fatal, unknown-command, or desync report.

Ten-second phase bins after startup average 16.672-16.694 ms through the exact
load and early-combat transition. The previously expensive numeric region now
resembles the warm repeat: about 11.37 ms CPU-thread time, 4.16 million static
cycles, and 181,000 native dispatches per row, not the failed run's 16.224 ms,
8.11 million cycles, and 523,000 dispatches. Rebooting Simulator services is
therefore insufficient to recreate the failed state.

One runtime interval reaches 59.7 FPS / 59.8 VPS and speed 0.982. DMA underruns
begin at one and end at three. The run is strong feasibility and stability
evidence, but it does not satisfy the written ordinary-route and audio gates.

## Decision

Do not make another performance-code change. Two independent exact repeats,
including this Simulator-reboot run, fail to reproduce the 53.5 FPS collapse
and sustain approximately 60 FPS. The remaining controlling evidence is the
ordinary installed-app path, which previously reached 55.6 FPS / 55.3 VPS and
accumulated transition underruns.

Proceed to repeated ordinary cold installed-app routes on the unchanged build.
If the failure recurs, capture its host-time/state boundary and compare it to
these recovered runs. If it does not recur twice, perform the required
unchanged-build manual five-minute Fountain acceptance route. Keep row 7,
physical-iPad promotion, and G9 closed until that product evidence passes.
