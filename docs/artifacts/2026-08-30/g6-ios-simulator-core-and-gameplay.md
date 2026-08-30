# G6 iOS Simulator core and gameplay

Date: 2026-08-30

## Decision

G6 passes. The same SsbmPad application and ahead-of-time GALE01 module booted
through the no-JIT iOS Simulator runtime on an iPad Simulator and then an
iPhone Simulator. Both reached live Classic-mode combat using the on-screen
controller. G7 is now the active goal.

This does not turn the deferred G5 external-display verification into a pass,
does not prove real-device performance, and does not complete the broader G7
shell/control/settings/diagnostics matrix.

## Product path

- The app target is `com.ssbmpad.SsbmPad`, arm64 `IOSSIMULATOR`, minimum iOS
  16.0.
- The locally generated `gGALE01_recomp.dylib` is also arm64
  `IOSSIMULATOR`, minimum iOS 16.0. The tested module was 82,821,272 bytes.
- Guest code runs through the ahead-of-time statically recompiled module. The
  compiled PowerPC JIT is not enabled; interpreter fallback and the portable
  software vertex loader remain the mobile configuration.
- Retail media, extracted game data, generated code, module, provisioning
  paths, and build products remain ignored and untracked.
- The iOS build keeps the core's component archives intact and passes them to
  the linker with `-force_load`. This avoids the invalid table produced when
  Apple `libtool` flattened the approximately 37 MiB archive set.
- Metal display-sync properties unavailable on iOS are now macOS-only. The
  Simulator also disables framebuffer fetch because its reported Apple GPU
  family advertises the capability while its shader compiler rejects
  render-target reads. After that capability correction, real frames render.

The final source labels GALE01 as `native-60-fps`; an inherited Sunshine-only
experimental 60 FPS switch was removed. The earlier iPad diagnostic log says
`original-30-fps`; that label was wrong, not a different emulation mode. The
corrected final build was rebuilt and exercised on iPhone.

## iPad Simulator result

Target: iPad Pro 13-inch (M5), iOS 26.5,
`68016FEA-1887-4E05-A7F4-B26EC8572B8A`.

The app rendered the memory-card prompt, navigated the title and menus,
selected Classic mode and a fighter, and entered a live Fox-versus-Yoshi match
on Yoshi's Story. On-screen stick, A, X, and Start input visibly drove the
game, including movement, jump, attack, menu selection, and match start.

Retained evidence:

- `docs/evidence/g6/ipad-framebuffer-fetch-disabled.png`
- `docs/evidence/g6/ipad-title-navigation.png`
- `docs/evidence/g6/ipad-repeated-start-gate.png`
- `docs/evidence/g6/ipad-classic-combat-touch-input.png`
- `docs/evidence/g6/ipad-classic-combat-performance.log`

## iPhone Simulator result

Target: iPhone 17 Pro, iOS 26.5,
`7B639924-AD8F-4D5C-AD29-71F47C768A0D`.

After shutting down the iPad Simulator, the same built app rendered the
memory-card prompt, reached the Classic character-select screen, selected
Yoshi through touch input, and entered live combat. The screenshot files are
stored in the Simulator's raw pixel orientation; the live app window was
correctly landscape.

Retained evidence:

- `docs/evidence/g6/iphone-first-render.png`
- `docs/evidence/g6/iphone-repeated-start-gate.png`
- `docs/evidence/g6/iphone-classic-cursor-target.png`
- `docs/evidence/g6/iphone-classic-combat.png`
- `docs/evidence/g6/iphone-runtime.log`

## Performance boundary

Simulator performance is diagnostic only. Static title/menu intervals often
reported 59.9-60.0 FPS. Shader-heavy transitions and combat were not stable at
60: the retained iPad window contains approximately 47-55 FPS combat samples
and lower transition samples, while the iPhone run contains approximately
40-44 FPS combat samples after lower cold-transition samples. These numbers
must not be used as real-device acceptance evidence or as a stable-60 claim.
Audio was active through RemoteIO at 48 kHz with 512-frame callbacks.

## Verification boundary

- The two Simulator runs were sequential; only one Simulator was booted at a
  time.
- Both app processes were terminated and both Simulators were shut down after
  capture.
- G5 remains deferred under DECISION-215.
- G7 must now verify the complete touch overlay, menu, settings, diagnostics,
  lifecycle, layout, controller, and import behavior before shell parity can
  pass.
