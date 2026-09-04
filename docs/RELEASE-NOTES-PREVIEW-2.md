# MeleePad v0.1.0 Preview 2

Preview 2 makes MeleePad's first working Internet-room path available as an
experimental developer preview.

## Highlights

- Private Room can create and join eight-character codes through Dolphin's
  public traversal rendezvous.
- Direct IP remains available for local-network and advanced testing.
- The native Online Play screen now includes compatibility-aware Public Games,
  Private Room, and Direct IP modes.
- The development public-lobby service implements bounded rooms, version gates,
  bounded room chat, heartbeats, hide/report controls, and secret-safe logging.
- Cross-platform Mac/iPad Simulator sessions connected through public traversal
  in both host directions and sustained roughly 4,700 rendered frames without a
  canonical mismatch or disconnect.
- The signed build-5 candidate was installed over build 4 on a physical iPad,
  launched successfully, and preserved the existing game data, configuration,
  preferences, and GCI save.

## What online play does and does not provide

Private Room is usable only after players find one another elsewhere and share
the generated code. The match runs peer-to-peer with fixed input delay; this is
not Slippi rollback, a streamed game, or a MeleePad-hosted gameplay server.
Room codes are locators, not passwords or an end-to-end-encryption guarantee.
There is no relay fallback, so some NAT/firewall combinations may fail.

Public Games is a development vertical slice, not a live matchmaking service.
No production MeleePad discovery endpoint is configured or deployed in this
release, so the app fails closed and keeps Private Room and Direct IP available.

Physical-device Internet matches, independent-network NAT coverage, complete
cross-platform matches/rematches, lifecycle recovery, and the public-service
operations/moderation gates remain open.

## IPA and game-data boundary

The attached
`MeleePad-v0.1.0-preview.2-module-free-unsigned.ipa` is an unsigned ARM64 app
shell for iOS/iPadOS 16 or later. It is **not playable as downloaded**. It does
not contain Super Smash Bros. Melee, extracted Nintendo data, saves, signing
material, or the locally generated `gGALE01_recomp.dylib` game module.

A playable app must be built locally on an Apple Silicon Mac from the user's
own legally obtained exact supported disc image and signed with the user's own
Apple development identity.

Supported image:

- Super Smash Bros. Melee (USA), original v1.00;
- game ID `GALE01`, disc 0, revision byte 0;
- raw ISO/GCM, exactly 1,459,978,240 bytes; and
- SHA-256
  `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`.

Revision 1/v1.01, revision 2/v1.02, PAL, Japanese, compressed, and modified
images are unsupported.

Public IPA SHA-256:
`797a4d9c218650bd6f7377f07d798d5f06ff46abcfee33c8cdbe44248a552519`
