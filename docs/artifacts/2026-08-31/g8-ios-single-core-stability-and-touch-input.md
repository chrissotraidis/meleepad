# G8 iPad Simulator single-core stability and touch input

Date: 2026-08-31

Status: **row 7 pass retained on single-core; row 9 pass; row 11 still partial**

## Why the prior row-7 acceptance was reopened

The source-integrated cache-direct/profile-guided candidate from PERF-235
enabled Dolphin's CPU/video split. Its retained acceptance run was too short.
The same exact build later failed after 139.4 seconds:

- process launch: `2026-08-31 01:00:14.9399 -0500`;
- crash capture: `2026-08-31 01:02:34.3586 -0500`;
- `EXC_BREAKPOINT` / `SIGTRAP` on faulting thread 13, named `Video thread`;
- top frame: `OpcodeDecoder::RunFifo<false>`, symbol offset 1444;
- the runtime warning immediately before the failure reported malformed FIFO
  command `cmd2 = 0x84000000` and `stream_size_temp < 16`.

This is the known CPU/GPU FIFO-desynchronization failure class. It also violates
the PRD's explicit instruction not to ship the CPU/video split. The earlier
dual-core row-7 acceptance is therefore retracted.

## Smallest causal reversal

The retained product configuration now:

- leaves `Config::MAIN_CPU_THREAD` disabled (single CPU/GPU worker);
- retains three asynchronous shader compiler workers;
- retains the exact cache-direct, profile-guided generated module and host PGO;
- reports `cpuVideoSplit=0 shaderCompilerThreads=3` at runtime.

Canonical ModernGekko patch 0011 now contains only the shader-worker setting.
The focused performance-config regression rejects any reintroduction of the
iOS CPU/video split.

## Single-core runtime result

Target: iPad Pro 13-inch (M5) Simulator, iOS 26.5, Release arm64,
GALE01 revision 0. Source revision before this evidence batch:
`cc53dafc53b11261bd08cbc783b1b883c6b41805`.

The exact single-core candidate ran continuously from its first performance row
at `06:22:30Z` through `06:45:14Z` (22 minutes 44 seconds), including attract
combat, two controlled 1v1 matches, results screens, menu transitions, overlay
settings, and a background/foreground cycle.

- 135 ten-second performance rows;
- last interval: 59.9 FPS, 59.9 VPS, DMA queue 14/15;
- CoreAudio callbacks continued throughout;
- underruns rose 1 -> 71 over the complete cold/transition-heavy run, but 107
  intervals were flat and the longest flat run was 15 consecutive intervals;
- demanding combat repeatedly held 59.9 FPS/VPS with the CPU/GPU worker below
  saturation;
- isolated presentation-only dips remained (minimum reported FPS 3.7 while VPS
  and speed stayed 59.9/1.0); these are not described as stable locked-60;
- zero `cmd2`, unknown-opcode, malformed-FIFO, desync, fatal, panic, or crash
  matches occurred;
- backgrounding logged `runtime paused for system event`; foregrounding retained
  controller slot 1, reactivated the Speaker route, resumed the runtime, and
  returned to 59.9 FPS/VPS.

This satisfies row 7's written no-*sustained*-underrun boundary without the
unsafe CPU/video split. It does not prove physical-iPad performance or eliminate
the separate Simulator presentation hitch.

## Short-tap input loss and retained correction

The overlay could queue `PRESS` and `RELEASE` before the emulated controller
sampled either edge. The pipe backend then exposed only the released state.
`PipeInput` now optionally latches a short digital press until `GetState()`
observes it once; analog axes remain unlatched, and a duplicate press after an
already-observed hold cannot create a phantom second edge.

The regression compiles and exercises Dolphin's actual private `PipeInput`
class. A live 20 ms Start tap interrupted an attract match after the fix, and a
normal overlay Start action immediately returned from attract mode to the title.

## Row 9: every overlay control in a live match

The hands-on lane used the visible overlay itself. Accessibility actions call
the same `buttonDown:`/`buttonUp:` and stick `valueChanged` handlers as direct
touch; no FIFO menu-injection script drove these checks.

| Control | Live result |
|---|---|
| Move stick | Moved the Stage Select cursor onto Onett and moved P1 in combat. |
| Start | Advanced CSS -> Stage Select, paused/resumed combat, and exited results. |
| A | Selected Onett and was exercised in the retained combat sequence. |
| B | Exercised in-match through the real overlay handler; the retained sequence shows attack/damage progression. |
| X | Produced a separately observed airborne P1 jump. |
| Y | Produced a separately observed airborne P1 jump. |
| Z | Exercised in-match through the real grab-button handler. |
| L | Exercised in-match through the digital-plus-255 trigger path. |
| R | Exercised in-match through the equal-size digital-plus-255 trigger path. |
| C-stick | Right and up were exercised in-match. A temporary trace, removed before the retained build, separately measured C-right as Dolphin pad `(128,128,220,128)` while the main stick stayed neutral. |
| D-pad | Up, left, right, and down were each exercised in-match. Directions without a Melee action correctly produced no invented gameplay behavior. |

The retained 15-second recording spans the one-at-a-time A, B, L, R, Z,
C-right, C-up, and four-direction D-pad sequence through damage changes, launches,
stock reset, Time-out, and results. Prior G7 evidence already proves layout edit
and per-device reset. Row 9 therefore passes.

## Controller visibility and lifecycle

Live testing found a real row-11 source defect: `applyControllerVisibility`
compiled out controller detection on Simulator, even though the active MFi
`Gamepad` was assigned to P1. A regression first failed on that exemption. The
retained source now applies identical visibility and touch-clearing semantics to
Simulator-forwarded controllers.

After rebuilding the exact single-core candidate:

- with `Hide on controller` enabled, the connected `Gamepad` hid every touch
  control except Menu while gameplay continued;
- disabling the setting immediately restored the complete overlay;
- the focused slot/disconnect suite still proves slot retention, P1 reclaim,
  held-input clearing, and visibility refresh on removal;
- a live background/foreground round trip retained slot 1 with no stuck input.

An actual live controller disconnect/reconnect was not available from this
Simulator session, so row 11 remains partial rather than converting the focused
disconnect regression into a physical acceptance claim.

## Retained evidence

- `screenshots/2026-08-31/g8-controller-overlay-hidden.png` — SHA-256
  `2c0c2b39b8c607d6ea80b82588bb8dda4f447da65ae41bbd15c7886a38e1f6c1`;
- `screenshots/2026-08-31/g8-controller-overlay-shown.png` — SHA-256
  `2c351571c01ec029da00d4f44c1542d5449911c598063191b7def8063ba06bea`;
- `screenshots/2026-08-31/g8-touch-controls-live-evidence.mp4` — SHA-256
  `21b08a955f8849ee02fa2a7ddb0d42a55e2d7be3e0f0cfe9e0a5999f2509ce8e`;
- crash report inspected locally as
  `SsbmPad-2026-08-31-010309.ips`; it is not committed;
- exact rebuilt app executable SHA-256:
  `1e37399dd8852c9ef9487e279878ff0eda1f2ebb5d67407da2fb882457d018de`.

The original 235 MiB Simulator capture and a 58 MiB intermediate transcode were
moved out of the repository to `/private/tmp`; only the 888 KiB evidence encode
is retained in Git.

## Verification

- exact Release Simulator rebuild: pass;
- `tests/test-controller-slots.sh`: pass after fail-first Simulator visibility
  regression;
- `tests/test-pipe-short-tap-latching.sh`: pass;
- `tests/test-touch-stick-accessibility.sh`: pass;
- `tests/test-experimental-performance-config.sh`: pass;
- `scripts/check-repository.sh`: pass.

## Next lowest unmet gates

G8 remains active. Row 10 still needs the destructive remove/reimport menu
boundary consolidated with the already-passed import evidence. Row 11 still
needs a directly observed controller disconnect/reconnect and overlay-show/P1
reclaim result. G9 netplay does not begin before those G8 gaps are closed.
