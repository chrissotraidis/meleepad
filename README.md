# MeleePad

<p align="center">
  <strong>Super Smash Bros. Melee on iPhone, iPad, and Apple Silicon Mac through ahead-of-time recompilation and Metal.</strong><br>
  Native Apple app shells, mobile touch controls, controller support, and local user-supplied game-data import.
</p>

<p align="center">
  <img src="apple/ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="180" alt="MeleePad navy, ivory, and coral analog-gate app icon">
</p>

<p align="center">
  <img alt="iOS and iPadOS 16+ target" src="https://img.shields.io/badge/iOS%20%2F%20iPadOS-16%2B-0A84FF?logo=apple">
  <img alt="macOS 14+ target" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple">
  <img alt="Metal renderer" src="https://img.shields.io/badge/renderer-Metal-5E5CE6">
  <img alt="Ahead-of-time PowerPC recompilation" src="https://img.shields.io/badge/PowerPC-ahead--of--time-FF9F0A">
  <img alt="Game data not included" src="https://img.shields.io/badge/game%20data-not%20included-FF453A">
</p>

![MeleePad running Melee Classic mode with touch controls on iPad](docs/evidence/g6/ipad-classic-combat-touch-input.png)

MeleePad wraps a [DolRecomp](https://github.com/encounter/dolrecomp)-generated
GALE01 game module in a ModernGekko/Dolphin-derived compatibility runtime.
Covered PowerPC code runs as ahead-of-time-compiled Apple ARM64 code; Dolphin's
Metal backend renders into native Apple app surfaces. The mobile app imports a
user-provided supported disc image through Files and provides a customizable
touch controller alongside Apple GameController support. The macOS app provides
a native launcher, Metal rendering, keyboard/controller input, local settings,
and netplay-facing configuration.

This repository contains the Apple integration, source patches, tests, and
reproducible build tooling. It does **not** contain Melee, a disc image,
extracted Nintendo assets, saves, signing material, or a generated game module.

## Current status

MeleePad is an engineering preview, not a finished release. The native macOS app
boots and plays coherent matches at approximately the original 59.94 Hz cadence
in established warm scenes, though strict worst-frame and remaining acceptance
work is still tracked. The same ahead-of-time game module boots on iPad and
iPhone Simulators with Metal, touch input, imported game data, persistent saves,
and diagnostics.

An exploratory physical-iPad build now boots the imported game, preserves saves
and settings across in-place updates, and has repeatedly sustained 59.9–60.0
FPS/VPS at 2x resolution during observed solo play. This is encouraging device
evidence, not final acceptance: serious water/reflection/shadow corruption is
open, while the combat-only right-stick convenience has passed its physical
menu-and-Classic hands-on retest. The complete visual/audio/controller/lifecycle
matrix has not passed. The evidence-first loop and exact open rows live in
[`docs/GOAL-LOOP.md`](docs/GOAL-LOOP.md) and [`docs/STATUS.md`](docs/STATUS.md).

| Area | Verified now | Still open |
|---|---|---|
| macOS | Native arm64 launcher/runner, Metal, keyboard/controller profiles, coherent live matches, saves/settings | Strict final acceptance rows and suitable-display replay |
| iPad/iPhone | Native app shell, Metal gameplay, touch overlay, menu, exact-image import, persistent saves/settings, diagnostics, accepted physical-iPad right-stick/menu behavior, and a locally signed in-place build holding near 60 FPS at 2x in observed solo play | Water/reflection/shadow repair, remaining control-matrix coverage, long-session audio/lifecycle checks, and formal physical-device acceptance |
| Recompiler | 237-chunk GALE01 module, exact-source PGO workflow, clean-clone regeneration | Remaining mobile producer deficit |
| Experimental multiplayer | Direct-IP fixed-delay transport, native Host/Join lobby, compatibility fingerprint, and one completed two-Mac direct match | Mac/iPad currently fails the canonical-state synchronization gate; room codes, traversal service, matchmaking, reliable physical-device matches, and the consumer beta UI remain unimplemented. Work is [paused at B1](docs/NETPLAY-BETA-GOAL-LOOP.md). |
| Distribution | ROM-safe source repository, ad-hoc local builds, and verified Apple Development-signed device installation | Public signing, TestFlight, and App Store release |

## Build from source

You need an Apple Silicon Mac with Xcode 26.x, CMake, Ninja, Git, ripgrep,
Python 3, and your own legally obtained USA revision 0 Melee image (`GALE01`).

Prepare the pinned public dependencies and private game inputs:

```sh
./scripts/bootstrap-dependencies.sh
./scripts/prepare-game.sh /path/to/GALE01.iso
```

These commands validate the supported image, build the public tools, extract
game data locally, and generate private build inputs under ignored paths. They
never download or redistribute game data.

Build the local Apple Silicon macOS app:

```sh
./scripts/package-macos-app.sh
open build-macos/MeleePad.app
```

Build the iOS Simulator core and app:

```sh
./scripts/ios-build-core.sh
./scripts/ios-provision.sh
xcodebuild -project MeleePad.xcodeproj -scheme MeleePad \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  CODE_SIGNING_ALLOWED=NO build
```

Generated source trees, extracted game data, app packages, profiles, saves,
and locally recompiled modules are ignored and must not be committed.

## First launch on iPhone or iPad

MeleePad never downloads or bundles game data.

1. Launch MeleePad and open the **•••** menu.
2. Choose **Game Data & Saves → Import or Reimport Game Data**.
3. Select your supported raw ISO/GCM image in Files.
4. Leave the app open while it validates, extracts, and atomically activates
   the private game data.
5. Start playing after the first rendered frame appears.

A failed reimport leaves the prior working data active. Removing stored game
data keeps saves and control settings separate.

## Controls and settings

The landscape touch layout provides move and C sticks, compact L/R shoulder
buttons, A/B/X/Y/Z, Start, and a grouped editable D-pad. **•••** opens render
scale, aspect ratio, FPS diagnostics, touch-layout editing/reset, controller
mapping, game-data, and privacy-bounded diagnostic export. A physical controller
can automatically hide the touch overlay; controller input and touch input use
the same thread-safe GameCube state.

On macOS, the launcher can select a generated GameCube profile or an existing
controller profile. The built-in keyboard controls are:

| Action | Keys |
|---|---|
| Move | W / A / S / D |
| Attack / confirm | J |
| Special / back | K |
| Jump | Space or U; I is the second jump button |
| C-stick / smash | Arrow keys |
| Shield | Q or E |
| Grab | O |
| Start / pause | Return |

Launching the macOS app automatically replaces MeleePad's internal automation
pipe profile with this interactive keyboard profile. Existing custom keyboard
and physical-controller profiles are preserved.

## Experimental multiplayer

Experimental Multiplayer is currently a developer-facing **Direct Connection
Preview**, not usable online multiplayer, a public beta, or game streaming.
Both players need the same MeleePad build and supported game revision. Each
device runs the match locally while the fixed-delay transport exchanges
synchronized controller input; the joining player is assigned another
GameCube controller port.

The underlying direct connection has completed a two-Mac match. The current
Mac/iPad path does not: it fails closed at the canonical-state synchronization
gate, so it cannot yet complete a reliable cross-platform match. The next task
is to isolate that deterministic state difference before adding the planned
room-code experience. Exact evidence and the restart point are recorded in the
[paused B1 goal loop](docs/NETPLAY-BETA-GOAL-LOOP.md).

Developers can exercise the current lobby as follows, but should expect the
cross-platform match to stop when synchronization fails:

1. Start on the same Wi-Fi network or a low-latency private VPN.
2. The host chooses **Host**, leaves UDP port **2626**, and creates the lobby.
3. The host shares an IP address or hostname that the joining device can
   reach. The joining player chooses **Join**, enters it, and uses the same
   port.
4. Both players mark themselves **Ready**; the host starts the synchronized
   match.

Port 2626 is [Dolphin's standard direct-NetPlay listen port](https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/Config/NetplaySettings.cpp),
not a matchmaking server. Same-network play normally needs no router changes.
Across the public internet, direct hosting can require UDP port forwarding;
Dolphin's [Netplay guide](https://dolphin-emu.org/docs/guides/netplay-guide/)
explains the same direct-versus-traversal distinction. MeleePad does not yet
expose Dolphin traversal room codes, a public lobby, relay fallback, or
matchmaking. No physical-device online match has passed the acceptance matrix.

The closest architectural next step is Dolphin's existing traversal protocol:
it supplies short room codes and helps peers connect without carrying gameplay
traffic, and its client/server code is already present in the pinned runtime.
[Slippi](https://github.com/project-slippi/project-slippi) is the established
Melee-specific alternative with rollback and matchmaking, but it is not a
drop-in server for this build. Slippi combines a modified Dolphin runtime,
Melee ASM/EXI integration, and a private matchmaking service, so compatibility
would require a separate rollback and game-integration project. A private VPN
can make the current direct-IP path reachable for testing, but it does not fix
determinism, latency, or the remaining match-completion gates.

## Testing and project policy

The repository follows a proof-gated goal loop: small falsifiable changes,
focused regressions, live visual evidence for playability claims, ROM-safe Git
history, and explicit separation between verified, partial, and blocked work.
Run the repository safety suite before publishing:

```sh
./scripts/check-repository.sh
```

The final iPad Simulator performance gate must be played by a person; automated
touch input cannot substitute for it. With exactly one Simulator booted, run:

```sh
./scripts/run-g8-human-acceptance.sh
```

The harness starts a fresh ordinary Release, records the complete screen
without UI polling, and retains the same-session runtime rows and hashes outside
Git. Follow its exact Samus/Kirby/Fountain instructions, play for five
uninterrupted combat minutes, reach results, return to the menu, and then finish
the capture from the terminal. The script reports numeric thresholds but never
declares acceptance; the video and every phase still require review.

See [`docs/PRD.md`](docs/PRD.md) for the acceptance contract and
[`docs/JOURNAL.md`](docs/JOURNAL.md) for the chronological engineering record.

MeleePad is an independent compatibility project and is not affiliated with or
endorsed by Nintendo, HAL Laboratory, or the Dolphin project.
