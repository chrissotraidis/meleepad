# Preview 2 public package audit

Date: 2026-09-03
Candidate: MeleePad `0.1.0` build `5`
Artifact: `MeleePad-v0.1.0-preview.2-module-free-unsigned.ipa`
Result: **PASS for a public module-free app shell; not a playable IPA**

## Build

The current iPhoneOS Release target was built for generic ARM64 iOS with code
signing disabled in a fresh DerivedData directory. The public packager removed
the local development configuration and rejected any app containing a GALE01
module, game/save file, provisioning profile, signature, key material, or
private host path.

## Retained checks

- packaging the same app twice produced byte-identical IPA files;
- ZIP integrity passed;
- bundle identifier: `com.meleepad.MeleePad`;
- marketing version: `0.1.0`;
- bundle version: `5`;
- architecture: ARM64;
- platform/minimum: iPhoneOS 16.0;
- code-signing inspection: unsigned;
- no `gGALE01_recomp.dylib`, ISO/GCM/RVZ, GCI/save, mobileprovision,
  certificate/key, development config, or private host path is present; and
- SHA-256:
  `797a4d9c218650bd6f7377f07d798d5f06ff46abcfee33c8cdbe44248a552519`.

## Claim boundary

This artifact is safe from the project-specific game-data and signing leaks
checked above. It is not playable as downloaded because static recompilation
happens on the build Mac and the generated game module is deliberately absent.
The playable build remains local-only and requires the exact supported
user-supplied GALE01 revision-0 disc image.
