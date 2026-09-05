# Preview 3 release evidence

Date: 2026-09-05

Candidate: MeleePad `0.1.0` build `7`

Source merge: `f43bb3f`

Artifact: `MeleePad-v0.1.0-preview.3-module-free-unsigned.ipa`

Result: **PASS for the in-place iPhone installation and public module-free app
shell; physical multiplayer and sustained-60 iPhone acceptance remain open**

## Physical iPhone installation

- The canonical physical-device core and generated module rebuilt through
  `scripts/ios-build-core-device.sh`; the generated module used the retained
  `apple-a15` scheduling tune without changing the minimum instruction set.
- The Release iPhoneOS app and generated module were signed locally, verified
  as ARM64, and passed strict nested signature verification.
- The app was installed directly over the existing iPhone 14 installation with
  the unchanged `com.ssbmpad.SsbmPad` identity. No uninstall, container reset,
  or remove-existing-content operation was used.
- The installed-app record reports version `0.1.0`, build `7`, and the app
  launched successfully.

This proves build, in-place installation, installed metadata, and launch. The
user separately accepted the corrected current-build C-stick behavior before
the release cut. This run does not claim a new byte-for-byte device-container
comparison, a completed physical-device Internet match, or sustained 60 FPS on
iPhone 14.

## Public package

The unsigned generic iPhoneOS Release shell was built from merged `main` with
code signing disabled. Packaging the same app twice produced byte-identical IPA
files. ZIP integrity passed.

The extracted package reports:

- bundle identifier `com.meleepad.MeleePad`;
- version `0.1.0`, build `7`;
- ARM64 iPhoneOS executable;
- unsigned code;
- no generated `gGALE01_recomp.dylib` module;
- no ISO/GCM/RVZ, extracted game data, GCI/save, provisioning profile,
  certificate/key, or development configuration; and
- no private host path found by the package audit.

The 12,107,666-byte IPA SHA-256 is
`2eb4d2ca00213bbf2abbbb0c320eecbd6a3418cc691c8d17056971be2869726e`.

The public IPA is not playable as downloaded. A playable build remains local
and requires the user's own exact supported game image, locally generated game
module, and Apple development signing.

## Multiplayer claim boundary

Preview 3 makes Private Room and Direct IP live as experimental features and
adds temporary peer chat. Public Games is not live because no production
MeleePad HTTPS discovery endpoint is configured. Physical-device full-match,
independent-network NAT, lifecycle, rematch, relay, and multiplayer-beta gates
remain open.
