# MeleePad

**Super Smash Bros. Melee on iPhone, iPad, and Apple Silicon Mac through
ahead-of-time recompilation and Metal.**

<p align="center">
  <img alt="Requires iOS or iPadOS 16 or later" src="https://img.shields.io/badge/iOS%20%2F%20iPadOS-16%2B-0A84FF?logo=apple">
  <img alt="Requires macOS 14 or later" src="https://img.shields.io/badge/macOS-14%2B-0A84FF?logo=apple">
  <img alt="Uses the Metal renderer" src="https://img.shields.io/badge/renderer-Metal-5E5CE6">
  <img alt="Uses ahead-of-time PowerPC recompilation" src="https://img.shields.io/badge/PowerPC-ahead--of--time-FF9F0A">
  <img alt="Game data is not included" src="https://img.shields.io/badge/game%20data-not%20included-FF453A">
</p>

![MeleePad running a four-player match on an iPad at 59.9 frames per second, with translucent touch controls and the More menu button visible](docs/images/meleepad-ipad-gameplay.png)

*A physical-iPad development build running at 2x resolution. Performance varies
by scene and device; this image is evidence from one observed match, not a
universal performance guarantee.*

> [!IMPORTANT]
> MeleePad is an engineering preview. It is not available through the App Store
> or TestFlight, and online play is not yet reliable between Apple platforms.
> You must build the app from source and supply your own supported game image.

## How MeleePad works

MeleePad does not depend on a completed source-code decompilation of Melee.
Instead, it uses **static recompilation**: translating the original game's
compiled PowerPC instructions into code that can be compiled for a different
processor before the app runs.

The build pipeline works in five stages:

1. You provide your own supported `GALE01` revision 0 disc image locally.
2. The tooling verifies that exact image and extracts its executable and game
   data. Nothing is downloaded from Nintendo or committed to this repository.
3. [DolRecomp](https://github.com/ExpansionPak/DolRecomp) reads the GameCube
   executable, decodes its PowerPC instructions, and emits portable C in
   manageable generated chunks.
4. Apple Clang compiles those generated chunks ahead of time into an ARM64 game
   module. The iPhone or iPad does not translate that code while you play.
5. [ModernGekko](https://github.com/ExpansionPak/ModernGekko), built on a
   Dolphin-derived runtime, supplies the console environment around that code:
   memory, timing, disc access, graphics, audio, and controller interfaces.
   MeleePad connects that runtime to UIKit, Metal, Apple audio, touch controls,
   and GameController.

The result is a native ARM64 Apple app running ahead-of-time-compiled game code.
Static recompilation replaces the runtime CPU translation layer; the
Dolphin-derived compatibility layer still models the GameCube hardware and
services the game expects. This is therefore most accurately described as a
**native static-recompilation compatibility port**, not a traditional
source-code port and not a stock Dolphin frontend.

The iPhone and iPad app imports a user-supplied game image from Files. The macOS
app provides a native launcher, Metal rendering, keyboard and controller input,
local settings, and developer-facing netplay controls. This repository contains
the Apple integration, source patches, tests, and reproducible build tooling.
It does **not** contain Melee, a disc image, extracted Nintendo assets, saves,
signing material, or a generated game module.

## Frequently asked questions

### Is this possible without a completed Melee decompilation?

Yes. A traditional decompilation project reconstructs human-readable source
code and data structures from a compiled game. Static recompilation solves a
different problem: DolRecomp converts the existing PowerPC machine instructions
into generated code that a modern compiler can turn into ARM64 instructions.
That makes execution on a new CPU possible without claiming to have recovered
the game's original source code.

### Is MeleePad truly native on iPhone and iPad?

Yes, in the platform and execution sense. The installed app and generated game
module are ARM64 binaries, rendering uses Metal, and the app uses native Apple
interfaces for its window, touch controls, controllers, audio lifecycle, file
import, and settings. It does not require a just-in-time compiler or a browser.

“Native” does not mean that every part of the GameCube was rewritten by hand.
MeleePad still needs a compatibility runtime to provide the hardware behavior
the recompiled game expects. Calling it a native static-recompilation port makes
both parts of the architecture clear.

### Is this an emulator?

It shares substantial runtime technology with Dolphin, particularly for the
GameCube memory model, graphics, audio, input, and operating-system services.
The major difference is CPU execution: covered Melee PowerPC code is translated
and compiled ahead of time instead of being handled by Dolphin's normal runtime
CPU emulation or JIT path. It is best understood as a game-specific static
recompilation joined to a Dolphin-derived compatibility runtime.

### Does MeleePad need JIT or special runtime permissions?

No. The game module is compiled to ARM64 before installation, so normal gameplay
does not generate executable code on the device. A locally signed build still
needs ordinary Apple development provisioning, just like other apps installed
from Xcode.

### Why does MeleePad require an exact disc revision?

Static recompilation depends on the executable's exact instruction layout,
addresses, and data. Even another legitimate regional or revision build can
differ at those locations. MeleePad currently validates and supports only the
USA `GALE01` revision 0 image used to generate and test this module.

### Does the repository or app include Melee?

No. The repository contains no game image, extracted game assets, saves, or
generated game module. On first launch, you select your own supported image.
MeleePad validates it, retains a private local copy in the app container, and
extracts the data required by the runtime. The game data stays on your device.

### How do I install it?

There is no public App Store, TestFlight, or downloadable binary release yet.
Developers can build it from source on an Apple Silicon Mac with Xcode and sign
the iPhone or iPad build using their own Apple development account. Start with
the [requirements](#requirements), follow the
[physical-device build steps](#build-for-a-physical-iphone-or-ipad), and then
complete [first-launch game-data import](#first-launch-on-iphone-or-ipad).

### Does multiplayer work?

Not reliably across Apple platforms yet. One direct two-Mac match has completed,
but Mac/iPad sessions currently stop at a synchronization safety check. Room
codes, traversal, relay, public matchmaking, and a consumer-ready online flow
are not implemented. The [Experimental multiplayer](#experimental-multiplayer)
section explains exactly what exists and what remains.

### What works on physical hardware today?

The game launches and plays on a physical iPad with Metal rendering, touch
controls, supported physical controllers, persistent game data and saves, and
the native settings menu. Observed solo play has repeatedly held close to 60
FPS at 2x resolution. Serious water, reflection, and shadow rendering defects
remain, and the complete device acceptance matrix is still in progress.

## Current status

| Area | Working now | Important limitations |
|---|---|---|
| macOS | Native Apple Silicon launcher and runner, Metal rendering, keyboard and controller profiles, matches, saves, and settings | Final display and worst-frame acceptance work remains |
| iPhone and iPad | Native app shell, Metal gameplay, touch controls, controller mapping, More menu, exact-image import, persistent saves and settings, and diagnostic export | Serious water, reflection, and shadow rendering defects remain; the full visual, audio, controller, and lifecycle matrix has not passed |
| Performance | A physical iPad has repeatedly held 59.9–60.0 FPS/VPS at 2x resolution during observed solo play | Results are scene- and device-specific and are not final hardware acceptance |
| Experimental multiplayer | Direct-IP fixed-delay transport, Host and Join lobby, compatibility fingerprinting, and one completed two-Mac direct match | Mac/iPad synchronization currently fails closed; reliable cross-platform matches, room codes, traversal, relay, and matchmaking are unavailable |
| Distribution | ROM-safe source repository and locally signed development builds | No public binary, TestFlight build, or App Store release |

The combat-only right-stick mapping has passed a hands-on physical-iPad retest,
including the required menu/gameplay behavior. The current evidence, remaining
acceptance rows, and known rendering debt are tracked in
[the goal loop](docs/GOAL-LOOP.md), [project status](docs/STATUS.md), and
[technical debt](docs/TECH-DEBT.md).

## Requirements

To build MeleePad, you need:

- an Apple Silicon Mac;
- Xcode 26.x;
- CMake, Ninja, Git, ripgrep, and Python 3; and
- your own legally obtained USA revision 0 Melee disc image (`GALE01`) in raw
  ISO or GCM form.

MeleePad supports that exact game revision. The preparation scripts validate
the selected image and reject unsupported input.

## Build from source

Prepare the pinned public dependencies and your private game input:

```sh
./scripts/bootstrap-dependencies.sh
./scripts/prepare-game.sh /path/to/GALE01.iso
```

These commands build the public tools, validate and extract the supplied game
locally, and generate private build inputs under ignored paths. They never
download or redistribute game data.

Build and open the Apple Silicon macOS app:

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

### Build for a physical iPhone or iPad

First build the device core and locally generated game module:

```sh
./scripts/ios-build-core-device.sh
open MeleePad.xcodeproj
```

Then, in Xcode:

1. Select the **MeleePad** target and open **Signing & Capabilities**.
2. Select your Apple development team. If Xcode reports that the bundle
   identifier is unavailable, change it to a unique reverse-DNS identifier
   owned by your team.
3. Connect and unlock the iPhone or iPad, enable Developer Mode if required,
   and select that device as the run destination.
4. Choose **Product → Run** to build, sign, install, and launch MeleePad.

Keep the same bundle identifier for later updates if you want iOS to preserve
the app's private game data, saves, controller settings, and preferences.
Changing the identifier creates a separate app container.

Generated sources, extracted game data, app packages, profiles, saves, and
locally recompiled modules are ignored and must not be committed.

## First launch on iPhone or iPad

MeleePad never downloads or bundles game data.

1. Launch MeleePad and open the **More (•••)** menu.
2. Choose **Game Data & Saves**, then **Import or Reimport Game Data**.
3. Select your supported raw ISO or GCM image in Files.
4. Leave the app open while it validates, extracts, and atomically activates
   the private game data.
5. Start playing after the first rendered frame appears.

A failed reimport leaves the prior working data active. Removing stored game
data keeps saves and control settings separate.

## Controls and settings

The landscape touch layout provides move and C sticks, compact L and R
shoulder buttons, A/B/X/Y/Z, Start, and a grouped editable directional pad.
The **More (•••)** menu contains render scale, aspect ratio, FPS diagnostics,
touch-layout editing and reset, controller mapping, game-data controls, and
diagnostic export. Connecting a physical controller can automatically hide the
touch overlay.

The built-in macOS keyboard controls are:

| Action | Key |
|---|---|
| Move | W, A, S, and D |
| Attack or confirm | J |
| Special or back | K |
| Jump | Space or U; I is the second jump button |
| C-stick or smash attack | Arrow keys |
| Shield | Q or E |
| Grab | O |
| Start or pause | Return |

Launching the macOS app replaces only MeleePad's internal automation pipe
profile with this interactive keyboard profile. Existing custom keyboard and
physical-controller profiles are preserved.

## Experimental multiplayer

**Online play is not ready for general use.** The current UI is a developer
preview for direct connections, not a public multiplayer beta.

### How the current preview works

- Both players run the match locally; MeleePad exchanges synchronized
  controller input rather than streaming video.
- Both devices need the same MeleePad build, supported game revision, module,
  and compatible settings.
- The transport uses fixed delay. It is not Slippi rollback netcode.
- The joining player is assigned another GameCube controller port.
- A synchronization mismatch stops the session instead of allowing the two
  games to continue in different states.

### What has been verified

| Test | Result |
|---|---|
| Two Macs using direct connection | One full match completed through results and lobby return, with saves unchanged |
| Mac and iPad connection and synchronized start | The peers connect and begin together, then the session stops at the canonical-state synchronization gate |
| iPhone multiplayer interaction | Compile coverage only; no completed device match |
| Room-code or public-internet play | Not implemented or accepted |

The current Mac/iPad failure is being investigated as a deterministic state
difference. Until that is resolved, a private network, VPN, or forwarded port
can improve reachability but **cannot** make cross-platform gameplay reliable.
The exact evidence and restart point are recorded in the
[paused B1 multiplayer goal loop](docs/NETPLAY-BETA-GOAL-LOOP.md).

### Direct connection details for developers

Developers can inspect the current lobby on the same local network:

1. The host chooses **Host**, keeps UDP port **2626**, and creates the lobby.
2. The host shares an IP address or hostname reachable by the joining device.
3. The second player chooses **Join**, enters that address and the same port,
   then connects.
4. Both players mark themselves **Ready**; the host starts the synchronized
   session.

UDP port 2626 is Dolphin's standard direct-netplay listening port. It is not a
MeleePad server. Same-network testing normally requires no router change;
testing across the public internet may require UDP port forwarding or a private
VPN. The current gameplay channel is plaintext, so use it only with trusted
people on a private test network. Do not expose it as a public service.

MeleePad does not currently operate a traversal service and does not provide
room codes, a public lobby, accounts, relay fallback, matchmaking, spectating,
or ranked play. Dolphin's traversal protocol is the planned basis for private
room codes after cross-platform determinism is proven. Slippi is an established
Melee-specific rollback and matchmaking system, but it is not a drop-in server
for this build and would require a separate integration project.

### What is required before a beta claim

Before the UI can be called **Online Play with Friends (Beta)**, one unchanged
build must complete full Mac/iPad, Mac/iPhone, and iPad/iPhone matches; pass
disconnect, backgrounding, save, input, performance, and privacy checks; and
connect across separate networks through a working short room-code flow. The
[multiplayer beta plan](docs/NETPLAY-BETA-GOAL-LOOP.md) defines the complete
acceptance matrix.

## Reporting issues

Use **More (•••) → Share Diagnostic Logs** to export a diagnostic package. Then
[open a MeleePad GitHub issue](https://github.com/chrissotraidis/meleepad/issues/new)
and include:

- the Apple device and OS version;
- whether touch, keyboard, or a named controller was in use;
- the scene and steps needed to reproduce the problem;
- relevant display, audio, and controller settings; and
- the diagnostic export, after checking it for anything you do not want to
  share.

Never upload a game image, extracted game data, save files, signing material,
IP addresses, or room codes.

## Testing and project policy

The repository uses a proof-gated workflow: small falsifiable changes, focused
regressions, live visual evidence for playability claims, ROM-safe Git history,
and explicit separation between verified, partial, and blocked work.

Run the repository safety suite before publishing:

```sh
./scripts/check-repository.sh
```

The final iPad Simulator performance gate must be played by a person; automated
touch input cannot replace it. With exactly one Simulator booted, run:

```sh
./scripts/run-g8-human-acceptance.sh
```

The harness starts a fresh Release build, records the complete screen without
UI polling, and retains same-session runtime rows and hashes outside Git. Follow
its displayed match instructions, play for five uninterrupted combat minutes,
reach results, return to the menu, and finish the capture from the terminal.
The script reports numeric thresholds but never declares acceptance; a person
must still review the recording and every phase.

See the [product requirements](docs/PRD.md), [engineering journal](docs/JOURNAL.md),
and [current status](docs/STATUS.md) for the acceptance contract, chronology,
and detailed evidence.

## Legal

MeleePad is an independent compatibility project and is not affiliated with or
endorsed by Nintendo, HAL Laboratory, or the Dolphin project. MeleePad does not
provide copyrighted game data; users are responsible for supplying and using
their own legally obtained game image in accordance with applicable law.
