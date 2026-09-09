# MeleePad

**Super Smash Bros. Melee on iPhone, iPad, and Apple Silicon Mac through
ahead-of-time recompilation and Metal.**

MeleePad turns a supported copy of Melee into a native Apple app you build
yourself. It uses touch controls, physical controllers, Metal rendering, and a
Dolphin-derived compatibility runtime—without requiring JIT on iPhone or iPad.

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

**[How it works](#how-meleepad-works) · [Current status](#current-status) ·
[FAQ](#faq) · [Build it](#build-from-source) ·
[Online play](#experimental-multiplayer) · [Get help](#reporting-issues)**

> [!IMPORTANT]
> MeleePad v0.1.0 Preview 4 makes experimental private Internet rooms and Direct
> IP available with temporary peer chat, compatibility checks, and the
> development public-lobby UI. It is not an
> online-play beta: there is no deployed public game browser, relay, automatic
> matchmaking, ranked play, or Slippi rollback. The downloadable IPA is an
> unsigned, module-free app shell and is **not playable as downloaded**. A
> playable build must be generated locally from your own exact supported game
> image. Performance and rendering still vary by scene and device.
>
> Preview 4 is build 18. Both players must use the same build.

### At a glance

| | What to expect |
|---|---|
| **Platforms** | iPhone, iPad, and Apple Silicon Mac |
| **Game input** | Verified USA v1.02 recommended; v1.00 retained, each requiring its matching local module |
| **Distribution** | Source plus an unsigned, non-playable IPA shell; playable builds are generated and signed locally |
| **Controls** | Touch, supported physical controllers, and keyboard on Mac |
| **Online play** | Experimental MeleePad-to-MeleePad private rooms and Direct IP, with temporary peer chat in Preview 4; not yet a public beta |
| **Not included** | Melee, game assets, saves, signing material, or a generated game module |

## What's new in Preview 4

Preview 4 (build 18) rolls up the latest device-tested changes:

- **USA v1.02 recommended, v1.00 retained.** Import or switch versions with
  separate game data and saves. The menu and Online Play show the active version.
- **Floating touch stick.** Your thumb sets the stick center inside its pickup
  zone; the stick hides when released. The D-pad is hidden by default and can
  be restored in Controls.
- **Lower CPU-loop overhead.** Normal gameplay compiles out disabled diagnostic
  bookkeeping. Physical testing supports a modest improvement; heavy iPhone
  scenes still slow down, especially under thermal pressure.
- **Better gameplay logs.** Ten-second summaries include frame-time average,
  p95 upper bound, maximum, slow-frame counts, and new audio underruns, alongside
  FPS, CPU usage, thermal state, resolution, and graphics workload. No manual
  profiler activation is needed. Logs remain local and can be shared through
  **Report a Problem**.
- **Clearer Online Play and macOS fixes.** Refreshed styling, version-compatibility
  guidance, consistent fallback policy, corrected app branding and keyboard bindings.

See [version choices](docs/MELEE-VERSIONS.md) and
[Preview 4 notes](docs/releases/v0.1.0-preview.4.md). The decompilation supports
revision-aware development and debugging; it does not itself guarantee a speedup.

## How MeleePad works

MeleePad does not depend on a completed source-code decompilation of Melee.
Instead, it uses **static recompilation**: translating the original game's
compiled PowerPC instructions into code that can be compiled for a different
processor before the app runs.

The build pipeline works in five stages:

1. You provide your own supported USA `GALE01` disc image locally: v1.02
   (recommended) or v1.00.
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

## FAQ

<details>
<summary>Can I download a playable IPA?</summary>

The public IPA is an unsigned, module-free shell. Importing an ISO alone cannot
make it playable. Build the matching game module locally and sign the app with
your Apple development account using the instructions below.

</details>

<details>
<summary>Does the completed decompilation make MeleePad faster?</summary>

It helps us understand and profile the original game. MeleePad still uses
statically translated PowerPC code and a Dolphin-derived compatibility runtime;
the decompilation does not automatically produce an optimized ARM64/Metal port.
The September 9 investigation retained better scene diagnostics but established
no reliable gameplay speedup. Heavy iPhone 14 scenes remain a known problem.

</details>

<details>
<summary>Where are the other answers?</summary>

The [full FAQ](docs/FAQ.md) covers native execution, JIT, supported images,
controllers, multiplayer, privacy, connection troubleshooting, Slippi, and
physical-device limitations. The [Online Play guide](docs/ONLINE-PLAY.md)
contains setup instructions, verified results, and remaining acceptance gates.

</details>

## Current status

| Area | Working now | Important limitations |
|---|---|---|
| macOS | Native Apple Silicon launcher and runner, Metal rendering, keyboard and controller profiles, matches, saves, and settings | Final display and worst-frame acceptance work remains |
| iPhone and iPad | Native app shell, Metal gameplay, touch controls, controller mapping, More menu, exact-image import, persistent saves and settings, and diagnostic export | Serious water, reflection, and shadow rendering defects remain; the full visual, audio, controller, and lifecycle matrix has not passed |
| Performance | A physical iPad can hold 59.9–60.0 FPS/VPS at 2x resolution during observed solo play | Latest iPhone 14 logs include 37.9–45.6 FPS dips and audio starvation; sustained heavy-scene performance remains unresolved |
| Experimental multiplayer | Preview 4 fixed-delay Private Room and Direct IP transport, eight-character room codes, temporary peer chat, native Host/Join lobby, compatibility fingerprinting, and synchronized Mac/iPad Simulator runs in both host directions | No public matchmaking endpoint, physical-device/outside-network/full-match beta evidence, relay, or Slippi rollback |
| Distribution | Preview 4 source plus an unsigned, module-free IPA shell; locally generated, locally signed playable apps | Public IPA is not playable as downloaded; no App Store or TestFlight build; the locally generated game module is not distributed |

The combat-only right-stick mapping has passed a hands-on physical-iPad retest,
including the required menu/gameplay behavior. The current evidence, remaining
acceptance rows, and known rendering debt are tracked in
[the goal loop](docs/GOAL-LOOP.md), [project status](docs/STATUS.md), and
[technical debt](docs/TECH-DEBT.md).

The accepted Preview 1 performance debt and the retained physical-device
measurements are summarized in
[the physical-iPad thermal slowdown record](docs/artifacts/2026-09-03/preview1-physical-ipad-thermal-slowdown.md).

## Development handoff

The September 9 performance session is stopped. Private build 20 adds scene
logging with the stable game modules; the matrix optimization candidate was not
promoted. **No new release or proven gameplay speedup resulted.**

Start with the [resume handoff](docs/SESSION-HANDOFF-2026-09-09.md) for preserved
builds, findings, and the next bounded investigation. Research code is preserved
on `codex/decomp-connected-performance`; it is separate from the public release.

## Requirements

To build MeleePad, you need:

- an Apple Silicon Mac;
- Xcode 26.x;
- CMake, Ninja, Git, ripgrep, and Python 3; and
- your own supported USA Melee disc image (`GALE01`): v1.02 recommended,
  or v1.00 for existing setups.

Use [the version guide](docs/MELEE-VERSIONS.md) to identify supported input and
build the matching module. Preparation verifies content and executable identity;
it rejects unlisted images. Each revision has separate extraction/module storage.

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

Release maintainers can build the publishable module-free iPhoneOS shell and
package it reproducibly with:

```sh
xcodebuild -project MeleePad.xcodeproj -scheme MeleePad \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData-public \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
./scripts/package-public-ios-ipa.sh \
  build/DerivedData-public/Build/Products/Release-iphoneos/MeleePad.app
```

The packager refuses game modules, game/save files, provisioning profiles,
signatures, and private host paths. Its output remains an app shell; it does not
replace the playable local-build process below.

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

Private Room and Direct IP are available for controlled tests with people you
trust. Both peers need the **same app build, game revision, matching modules and
game data, and compatible gameplay settings**. For the published Preview 4,
that means build 18 on both ends; USA v1.02 is recommended. v1.00 can only play
with a compatible v1.00 peer. Private diagnostic builds are not the release.

| Option | Current boundary |
|---|---|
| Private Room | Eight-character room codes through Dolphin traversal; no relay fallback |
| Direct IP | Advanced testing on a trusted network or private VPN |
| Public Games | Development UI only; no production public browser |
| Room Chat | Temporary plaintext peer chat in Private Room and Direct IP |

Retained tests include synchronized Mac/iPad Simulator runs. A completed
physical iPhone/iPad Internet match has **not** passed acceptance. There is no
Slippi rollback, ranked matchmaking, encrypted gameplay, or verified four-player
online release.

For setup, troubleshooting, privacy, and the full test history, see the
[Online Play guide](docs/ONLINE-PLAY.md). Use the
[Private Room test guide](docs/PRIVATE-ROOM-TESTING.md) for a complete report.

## Reporting issues

Use **More (•••) → Report a Problem…** to review and share a diagnostic package.
Gameplay timing summaries are collected automatically; note the approximate time
and scene when a slowdown happens. No profiler switch is required. Then
[open a MeleePad GitHub issue](https://github.com/chrissotraidis/meleepad/issues/new)
and include:

- the Apple device and OS version;
- whether touch, keyboard, or a named controller was in use;
- the scene and steps needed to reproduce the problem;
- relevant display, audio, and controller settings; and
- the diagnostic export, after checking it for anything you do not want to
  share.

For Online Play, also include whether you hosted or joined, whether the players
used the same or separate networks, whether either side used a VPN, approximate
time to receive the room code, approximate ping if a peer connected, and
whether a full match, results screen, character select, and rematch completed.
The [community test guide](docs/PRIVATE-ROOM-TESTING.md) contains a copyable
report template.

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
