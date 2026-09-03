# Build 5 physical-iPad test installation

Date: 2026-09-03
Candidate: MeleePad `0.1.0` build `5`
Source base: `514f758` plus the unreleased networking/public-lobby working tree
Result: **PASS for signed install, launch, and data preservation; gameplay and
Internet-match acceptance remain open**

## Scope

Put the latest working candidate on the connected iPad Pro without deleting
the installed game's data or overstating what an automated launch proves.
This was an in-place development deployment, not a public release or service
deployment.

## Build and verification

- Replayed the dependency patches and rebuilt the iPhoneOS ModernGekko core;
  the provisioned GALE01 native module remained current.
- Built the Release target for iPhoneOS with the installed app's existing
  bundle identifier, `com.ssbmpad.SsbmPad`.
- Verified the product metadata reports marketing version `0.1.0` and bundle
  version `5`.
- `codesign --verify --deep --strict` passed. The signed executable SHA-256 is
  `603ff764053fb00a2ac0d1114e5c501b6e0c67bd6a0a2305c53dfa694a2f9f13`.
- The complete `scripts/check-repository.sh` gate passed, including ten public
  lobby tests and all netplay contracts.

## Data-preserving install

The previous installation was `0.1.0` build `4` under
`com.ssbmpad.SsbmPad`. Before changing it, GC saves, Dolphin configuration,
and preferences were copied to
`/tmp/meleepad-ipad-prebuild5-backup-20260903-2303`.

Build 5 was installed directly over build 4. No uninstall, app-container
deletion, or remove-existing-content operation was used.

A post-install readback before first launch proved:

- the GALE01 GCI save is byte-identical to the backup;
- the complete configuration and preferences trees are byte-identical;
- `GALE01.iso` remains present at 1,459,978,240 bytes; and
- the extracted `GALE01` tree remains present with 1,214 files.

The full pre-launch readback is retained temporarily at
`/tmp/meleepad-ipad-postinstall5-prelaunch-4hdOz0Dc`.

## Launch verification

The installed-app inventory reports `com.ssbmpad.SsbmPad`, version `0.1.0`,
build `5`. `devicectl` launched it successfully and the MeleePad executable
appeared in the device process list. A second GCI readback after launch was
byte-identical to the pre-install backup.

## Claim boundary and next test

This run proves that build 5 can be signed, installed, and started on the
physical iPad while preserving the user's game data and save. It does not
prove rendered gameplay, control/audio quality, lifecycle recovery, thermal
behavior, or a completed physical-device Internet match.

The build intentionally contains no production public-lobby endpoint. Public
Games should therefore present the unavailable-service path. Private Room and
Direct IP remain available, and Private Room uses the already proven Dolphin
traversal room-code transport. The next retained acceptance run should pair
this iPad with a second endpoint on an independent network, complete a
five-minute match through results/rematch/leave, and capture the failure paths
listed in `docs/PUBLIC-LOBBY-GOAL-LOOP.md`.
