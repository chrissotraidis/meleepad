# G8 public presentation and compact R control

Date: 2026-08-30

Status: **retained product polish; G8 remains in progress**

## Scope

This checkpoint addresses three product-quality gaps without promoting mobile
performance or input rows beyond their evidence:

- add a public, ROM-safe repository landing page;
- replace the inherited sun icon with an original SsbmPad identity;
- make the touch R shoulder a compact digital control matching L instead of
  inheriting SunPad's long analog-pressure slider.

## Retained changes

- Root `README.md` now explains the architecture, supported Apple targets,
  private game-data preparation, build/import paths, controls, testing policy,
  and current acceptance boundaries. It reports demanding iPad Simulator
  combat at roughly 42-48 FPS and explicitly does not call that playable.
- The 1024x1024 opaque app-icon master is an original abstract arena-impact
  emblem in charcoal, silver-white, crimson, and restrained blue. It contains
  no controller, text, characters, or copied brand mark. Its generation prompt
  and SHA-256 are retained beside the asset in `PROVENANCE.md`.
- R is now the same standard touch-button class and default width as L. Both
  shoulders emit the GameCube digital button and a 255/0 trigger value on
  press/release. The legacy wide-R width path is absent.

## Verification

- `tests/test-iphone-touch-layout-defaults.sh`: pass. The focused contract
  requires a standard button and compact shoulder width and rejects the old
  `rightShoulderWidth` path.
- Fresh Release iOS Simulator build: pass.
- Live iPad Pro 13-inch (M5) Simulator inspection: L and R render at matching
  compact sizes; R no longer exposes the pressure-slider accessibility hint.
- Retained screenshot:
  `docs/evidence/g8/ipad-compact-shoulders.png` (2064x2752), SHA-256
  `48b7d7e0afd8fa366bad09348e3794e9760168c003561fd0e08a8c4aa99f3074`.
- App icon: 1024x1024, opaque, SHA-256
  `addae9f61cdd77af1167c20d2ac58819aa11d88cd3e10ede379d5d59ecec9b4a`.
- README local links: pass.

The app was terminated and the sole Simulator shut down after the visual
check. This proves the requested R geometry and semantics, not every touch
control in live gameplay; G8 row 9 therefore remains partial.
