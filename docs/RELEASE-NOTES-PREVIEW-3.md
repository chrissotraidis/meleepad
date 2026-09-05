# MeleePad v0.1.0 Preview 3

Preview 3 is build 7. It makes the current experimental multiplayer work
available in a release, carries the accepted C-stick repair, and retains the
first measured iPhone performance improvement.

## Highlights

- Experimental Private Room and Direct IP play are available from **More (•••)
  → Experimental Multiplayer…**. Private Room creates an eight-character code
  through Dolphin's public traversal service.
- Connected Private Room and Direct IP sessions include temporary peer chat.
  Chat and gameplay are peer-to-peer, unencrypted, and intended for people you
  trust.
- The touch C-stick and a physical controller's right stick now share the same
  combat-only attack conversion. Menu navigation remains raw C-stick input.
  The current physical-device behavior was accepted after the regression fix.
- Physical iOS game modules use Apple A15 scheduling tuning without requiring
  an A15-only instruction set. A matched iPhone 14 late-window comparison
  reduced emulation CPU time by 8.62% and improved cadence by almost one FPS.
  This is a measured improvement, not a promise of sustained 60 FPS.
- **Report a Problem…** now creates a redacted diagnostic, presents it for
  review or saving, and then offers the prefilled GitHub issue with clear manual
  attachment instructions. MeleePad does not upload the log automatically.
- **Offline Cheats → Unlock All Characters & Stages** toggles Dolphin's bundled
  offline Action Replay entry in app-owned settings. It is disabled before
  netplay; unlocks already written to a game save may persist after it is
  turned off.

## Multiplayer boundary

Private Room and Direct IP are live as experimental Preview features, not as a
general multiplayer beta. Retained tests cover synchronized Mac/iPad Simulator
gameplay in both host directions, repeated two-way peer chat, a complete
two-Mac match, and physical-iPad room creation. Complete physical-device
Internet matches, independent-network NAT coverage, lifecycle recovery, and
rematches remain open.

Public Games is not live. Its native UI and local service have development
coverage, but Preview 3 contains no production MeleePad HTTPS discovery
endpoint. There is no public browser, automatic matchmaking, relay fallback,
ranked play, or Slippi rollback.

## iPhone performance boundary

The iPhone 14 improvement is real but incomplete. Heavy scenes can still miss
native cadence at the minimum 1x render scale, especially under thermal
pressure. Lowering render scale cannot go below 1x; the retained change instead
tunes scheduling for the generated ARM64 module while leaving game timing,
rendering fidelity, and the minimum CPU instruction set intact.

## IPA and game-data boundary

`MeleePad-v0.1.0-preview.3-module-free-unsigned.ipa` is an unsigned ARM64 app
shell for iOS/iPadOS 16 or later. It is **not playable as downloaded**. It does
not contain Super Smash Bros. Melee, extracted Nintendo data, saves, signing
material, or the locally generated `gGALE01_recomp.dylib` game module.

A playable app must be built locally on an Apple Silicon Mac from the user's
own legally obtained exact supported USA `GALE01` revision-0 disc image and
signed with the user's own Apple development identity.
