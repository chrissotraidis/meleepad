# G8 SunPad menu-state fix

Date: 2026-09-01

Status: source regression, Release Simulator build, and live interaction pass

## Upstream source

The separate SunPad checkout was clean and fast-forwarded from `e43f0ea` to
Preview 7 at `2608265`. The relevant upstream change is `792f0e7`,
`Stabilize and reorganize the iOS settings menu`.

The specific three-dot-button defect is documented in that change: iPadOS can
synthesize a rectangular selected state while a primary-action menu is being
dismissed. SunPad prevents it by assigning one explicit circular
`UIButtonConfiguration` and disabling automatic configuration updates.

The pinned `ref/sunpad` dependency remains unchanged. This is a narrow source
transfer, not an unreviewed dependency upgrade.

## SsbmPad change

- use the same immutable circular configuration for the ellipsis button;
- retain the white glyph and existing dark translucent appearance;
- group render/aspect actions under `Display`;
- group controller/touch actions under `Controls`;
- add the upstream-style icon to `Game Data & Saves`;
- retain SsbmPad's `Share Diagnostic Log…` and `Report a Problem…` actions;
- keep Experimental Performance Mode absent.

`tests/test-experimental-performance-config.sh` now rejects loss of the fixed
configuration or the Display/Controls hierarchy.

## Verification

- focused menu/config regression: pass;
- Release build for iPad Pro 13-inch (M5), iOS 26.5 Simulator: pass;
- installed-app menu opened: `Display`, `Controls`, `Game Data & Saves`, FPS,
  diagnostic sharing, and problem reporting all present;
- menu dismissed: the accessibility tree returned to one `Menu` button and
  the live button retained the circular white-ellipsis appearance;
- app stopped after verification; one Simulator remains booted.

Evidence:

- `docs/evidence/g8/ipad-sunpad-menu-state-fix.png`
- `docs/evidence/g8/ipad-sunpad-menu-dismissed.png`

This changes no runtime, input, emulation, or netplay behavior. G8 row 7 still
requires the ordinary human-controlled uninterrupted five-minute match. G9
netplay remains not started.
