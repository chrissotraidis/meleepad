# G5 FPS-title Spotlight rejection

Date: 2026-08-29

Status: **SIDE EFFECT CONFIRMED; PERFORMANCE CAUSE REJECTED; G5 OPEN**

## Question

Does the once-per-second FPS window-title update cause the remaining Fountain
of Dreams frame-time tail through AppKit window-tab and CoreSpotlight indexing?

## New mechanism

The default macOS configuration enables `show_fps_in_title`. The runtime title
thread calls `Host_UpdateTitle` about once per second, and the macOS platform
implementation asynchronously calls `setTitle:` on the game window. Unified
logging revealed that each live title change made AppKit index one window-tab
item and submit a CoreSpotlight `index-items` batch. One such batch followed a
previous clean run's severe render interval closely enough to reopen PERF-169,
which had considered updater computation and frame phase but not this AppKit
side effect.

## Matched test

A private, reversible run changed only `show_fps_in_title=true` to `false`.
It used the same signed PGO app, isolated Fountain save, fullscreen Metal,
Cubeb, confirmed Game Mode, quiet 18-cycle input, one game, and no Simulator.
The title-off unified log contains only two startup indexing pairs and no
once-per-second combat indexing. This proves that the updater caused the
recurring AppKit/CoreSpotlight traffic.

That traffic was not the remaining frame-time cause. Exact final 2,001-row
combat windows compare as follows:

| Setting | Mean | FPS | p95 | p99 | Worst | >20 ms |
|---|---:|---:|---:|---:|---:|---:|
| Title on | 16.675121731 ms | 59.969577 | 16.786209 ms | 16.834666 ms | 33.919041 ms | 2 |
| Title off | 16.675156588 ms | 59.969452 | 16.801375 ms | 16.845292 ms | 33.398500 ms | 1 |

The title-off run therefore retains the same mean cadence, a slightly worse
p95/p99, and one doubled frame. The recurrent indexing disappears while the
failure remains. A return A leg is unnecessary because the candidate does not
show the required one-direction improvement even before accounting for normal
run-to-run tail variation.

The title-off run ended with 641,839,149 native dispatches, zero fallback, zero
failed SMC verification, Cubeb active, Game Mode on, and no thermal warning.
Private evidence hashes:

- render log: `a6fbbe52bf520da1d298c8a530ec86874710b40be70d701377ed64f02848494d`
- vblank log: `64ebc65205deee022b4889bed9269799cb2552fa19474986057f80a229676570`
- runtime stderr: `816ed856afebcadb27b3d4ee850cc4c2845af03bdea490417ab4281b7c313cf0`
- unified runner log: `06ff5d1c87fb4bcda9b8f53cafd0cb1af84783bd53294edd61981bfbce20d113`
- Game Policy log: `e35a81d2950e5d4d38950df500e26f6dd684494e436ad88d1313a55ae91c755c`

## Reversal and decision

The private setting was restored byte-for-byte to SHA-256
`b0823b321971720aa71a07f90bc22755f2164a2cbbd1a289af2365709287e2dd`.
No product source changed, and no game or Simulator remains active.

**Keep the useful FPS title option and reject it as the primary G5 cause.**
PERF-169's conclusion survives with a stronger direct mechanism test. Continue
from the PERF-176 combined CPU-GPU/vblank host-execution stall class. Fountain
still fails strict worst-case G5; Final Destination and G6 remain blocked.
