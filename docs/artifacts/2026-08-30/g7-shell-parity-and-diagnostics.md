# G7 shell parity and diagnostics

Date: 2026-08-30

## Decision

G7 passes. On the iPad Pro 13-inch (M5) Simulator running iOS 26.5, the
SsbmPad touch overlay and three-dot menu remained responsive over live Melee,
changed render resolution and aspect ratio live, edited and reset the touch
layout, exposed the controller/game-data/report actions, toggled the FPS
overlay, and generated a privacy-bounded diagnostic file. G6 already proved
that the overlay's controls drive menus and live combat.

G8 is now active. This decision does not pass the full 15-row matrix: every
individual touch control, two-controller connect/disconnect, complete ISO
import/reimport/rollback/removal behavior, save persistence, and the remaining
target/scene rows still require their own evidence.

## Live shell result

- `Render Resolution` exposed Native/1x through 4x. Selecting 2x changed the
  runtime EFB from 640x528 to 1280x1056 and logged
  `runtime render scale=2 source=live`.
- `Aspect Ratio` exposed Original 4:3, experimental 16:9, and experimental
  Fill. Selecting 16:9 changed the projection and logged
  `runtime aspect mode=widescreen-16:9 source=live`.
- `Show FPS Counter` produced a live accessible `59.9 FPS` label and was then
  returned to off.
- `Touch Control Settings` exposed render scale, opacity, global size,
  hide-on-controller, modern C-stick behavior, move mode, and per-device
  layout reset. The A control was selected and resized from 1.0 to 1.2; the
  reset confirmation restored the device layout.
- `Controller Button Mapping` opened against the Simulator's connected
  `Gamepad` and showed GameCube A/B/X/Y/Z mappings.
- `Game Data & Saves` exposed import/reimport, import from the Files-visible
  SsbmPad folder, and removal. The destructive removal was not invoked; the
  full import/removal matrix belongs to G8.
- `Report a Problem` produced `Latest-SsbmPad-Diagnostic.log` and presented
  the system share sheet without transmitting the file.

Retained visual evidence:

- `docs/evidence/g7/ipad-menu-parity.png`
- `docs/evidence/g7/ipad-touch-layout-settings.png`
- `docs/evidence/g7/ipad-live-menu-diagnostics.png`

## Diagnostic privacy repair

The first live export revealed that a dev-provisioned Simulator breadcrumb
could include the host's absolute extracted-game path. This violated the
export boundary even though the game data itself was never embedded.

The retained fix:

- records only game-data availability and source class in the boot breadcrumb;
- redacts complete host-user, volume, private, and temporary path tokens;
- applies redaction again while exporting current and previous logs, protecting
  reports from stale pre-fix sessions; and
- adds a regression with an external `/Users/.../PrivateGame/main.dol` path.

The rebuilt app generated a 34,609-byte report with SHA-256
`4a2ed56279707f58b89a22a5186a5ad2de9247db31a63eb62bc84c165b3a24f7`.
A scan returned zero matches for `/Users/`, `/Volumes/`, `/private/`,
`/var/folders`, `Super-Smash`, `main.dol`, or supported disc-image extensions.
The report retained the required app/build, platform, settings, controller,
graphics, performance, lifecycle, runtime, and `native-60-fps` context.

## Regression gate

The repository gate now compiles and runs SsbmPad-native focused tests for:

- input-pipe encoding and zero-initialized controller snapshots;
- physical-controller mapping and corrupt-setting fallback;
- two-slot retention/reclaim and held-input clearing on disconnect;
- diagnostic session rollover, event bounding, path redaction, and issue-form
  contract;
- experimental performance configuration;
- GALE01 native-60 semantics with no Sunshine-only 60 FPS control;
- iPhone touch-layout defaults; and
- game-data first-run guards and import actions.

`scripts/check-repository.sh` passed with all existing G5 diagnostic tests and
all new shell regressions. The rebuilt arm64 iOS Simulator app also passed
Xcode compilation/link/validation.

## Cleanup and boundary

Resolution was restored to Native/1x, aspect to Original 4:3, FPS overlay to
off, and the touch layout to its device default. The app was terminated and
the sole Simulator was shut down. G5 external-display verification remains
deferred and unpassed under DECISION-215.
