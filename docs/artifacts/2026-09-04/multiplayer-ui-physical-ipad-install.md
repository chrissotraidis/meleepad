# Multiplayer UI physical iPad install

Date: 2026-09-04

Target: Chris' iPad Pro, iPad14,5

Bundle: `com.ssbmpad.SsbmPad`, version `0.1.0` build `5`

Result: **PASS for an in-place development install and preserved game boot**

## Candidate

- The complete repository check passed, including the native Online Play source
  contract, diagnostics privacy checks, and all 18 public-lobby service tests.
- Release builds passed for the iPad Simulator and generic ARM64 iPhoneOS.
- The local user-generated `gGALE01_recomp.dylib` was placed only in the signed
  development app and signed with the same development team as the app.
- Strict nested-code verification passed before installation.

## Data-preserving deployment

The app was installed over the existing build with CoreDevice's app-install
command and the unchanged `com.ssbmpad.SsbmPad` bundle identifier. The existing
app was not uninstalled, its container was not reset, and no
`--remove-existing-content` operation was used.

A current preinstall CoreDevice file-copy attempt stalled while enabling the
device file service and was cancelled without writing to the device. The prior
verified backup of the GCI save, Dolphin configuration, and app preferences was
retained locally rather than attempting a riskier workaround.

## Post-install proof

The installed app reported all of the following from the physical iPad:

- the sandbox game root exists and remains selected;
- `GALE01.iso` exists;
- the game root and local recompiled module both exist;
- the static-recomp module loaded from the unchanged app data container;
- the runtime produced gameplay at 59.9 FPS; and
- the signed app remained installed as `com.ssbmpad.SsbmPad`.

This proves the existing ISO, extracted game data, and module remained usable
after the in-place update. Byte-for-byte postinstall save/config comparison was
not available in this run because the CoreDevice file-copy service timed out;
the app did not write a save during this launch.

## Claim boundary

This is physical-device build, launch, and preserved-game-data evidence. It is
not four-device multiplayer evidence. Public Games and room chat also remain
closed in release builds until a production HTTPS lobby service is configured.
