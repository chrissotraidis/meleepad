# G5 current Main Menu window

Date: 2026-08-29

Status: **SUSTAINED MENU COLLAPSE NOT REPRODUCED; PACING TAIL RETAINED; G5 OPEN**

## Question

Does the current PGO/Game Mode package still reproduce the previously observed
sustained 12.5-30 FPS slowdown in Melee's animated Main Menu?

## Current cold route

The exact current signed PGO app, module, isolated user tree, fullscreen Metal,
Cubeb, one game, and no Simulator were used without a savestate. MemoryWatcher
was armed before launch and proved the genuine revision-0 title lockout:

- `0x804D4594` became nonzero at 131.60 seconds;
- it returned to zero at 132.13 seconds;
- the script then pressed Start; and
- `0x80477D68 & 0xFF0000FF` reached `0x01000000`, the verified menu class,
  at 133.13 seconds.

The route waited another five seconds before recording the buffered-log
boundary, then held the controller FIFO open and left the process untouched
for 60 wall-clock seconds. Game Mode was on before the title route completed.
No UI observer, phase logger, screenshot, or Simulator ran.

Because Dolphin's lightweight render logger is buffered, line counts taken
during the process do not describe every wall-clock endpoint exactly. The
selected rows are therefore a conservative interior buffered bracket, not a
claim that exactly 60.000 seconds are represented. It contains 3,413 intervals
and 56.942412 seconds of accumulated render time wholly after the five-second
menu settle.

## Result

| Metric | Current Main Menu |
|---|---:|
| Intervals | 3,413 |
| Mean / implied FPS | 16.683976 ms / 59.937749 FPS |
| Median | 16.688791 ms |
| p95 | 18.793042 ms |
| p99 | 19.062209 ms |
| Worst | 19.611250 ms |
| At or below 16.7 ms | 1,785 / 3,413 (52.300%) |
| Above 20 ms | 0 |
| Worst rolling 60-frame rate | 59.743392 FPS |
| Worst rolling 600-frame rate | 59.917396 FPS |

The 329 rows above 18.5 ms are distributed through the bracket, not confined
to a later state. Their previous-plus-current two-frame total averages
33.470121 ms, and the window also contains 392 compensating rows below
15.5 ms. This is delayed/early pacing around full-speed mean cadence, not a
sustained throughput collapse.

No fresh visual claim is attached because the run intentionally avoided UI
automation. The memory gate establishes menu state and the timing result
falsifies a current sustained 12.5-30 FPS numeric mode, but it does not prove
that every animation looks smooth. The p95 and worst also remain above the
strict 16.7 ms G5 boundary.

The run ended with 886,213,384 native dispatches, zero interpreter fallback,
zero failed SMC verification, Cubeb active, and no thermal or performance
warning. Private evidence hashes:

- render log: `af4d16d5de9557babbc7f5f17d9f373e0eef60e5684dcc7e5b341e8b9e5abf9d`
- vblank log: `e211418c587ac22b97a79ec71995687b82f10a310ee9416721b14a8fa6bb9699`
- route log: `0092c82baeca80e3540f207b47763379fa239ba0a5c79d27b11afa359920867d`
- runtime stderr: `a839bfdc4851ddcf26e32c8dd8e5eb12d8f895c379d9b50a01d7f6b5476b01f6`
- Game Policy log: `7e918c341ad15c5f603a507efe66ccd460961bc38b0193fede3e5aba07f92bf7`

## Decision

**Do not describe the current Main Menu as running at 12.5 FPS.** The present
package sustains approximately 59.94 FPS mean cadence in the verified menu
class, but its delayed/early tail prevents a smoothness or strict-G5 claim.
No product source or configuration changed, and no game or Simulator remains.
Continue G5 from the shared pacing/descheduling boundary rather than a menu-
specific renderer or static-recompiler rewrite. G6 remains blocked.
