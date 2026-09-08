# Melee versions

Development build 8 adds USA v1.02 as the preferred target while retaining
v1.00. The published Preview 3 remains a v1.00-only, module-free shell.
See [the active acceptance ledger](REVISION-102-GOAL-LOOP.md) before making
claims about the development build.

| Version | Why choose it? | Limits |
| --- | --- | --- |
| USA v1.02, disc revision 2 | Recommended for new setups; matches the completed decompilation and widely used Melee tools | Requires its own locally built module; no automatic Slippi compatibility or performance guarantee |
| USA v1.00, disc revision 0 | Keeps existing copies and that revision's behavior usable | Does not directly match the completed v1.02 source; some future work may arrive on v1.02 first |

Import identifies the file by its contents, not its name. The app shows the
detected version after extraction. Choose **Menu → Game Data & Saves → Choose
Version or Import Game Data** to import or switch between installed versions.
On iOS each version keeps separate game data and saves. Importing or removing
one version leaves the other intact. Existing v1.00 data stays in its original
location; a new v1.02 save starts fresh rather than modifying the old save.

Online peers must have matching game versions, compatible builds, game assets,
modules and gameplay modifications. A room label is not the final check: the
peer transport also verifies game/module/asset fingerprints. Development build
8 uses a new transport compatibility prefix and rejects older peers.

## Supported images

The shared catalog is `apple/shared/MeleePadRevisions.json`. It includes the
existing exact raw v1.00 ISO, the conventional v1.02 ISO identified by the
[UnclePunch project's documented MD5](https://github.com/UnclePunch/Training-Mode),
and the owner's supplied v1.02 CISO plus its normalized raw representation.
The executable is additionally verified with SHA-256 after extraction.

The supplied CISO has a different whole-disc hash from the conventional raw
dump. All 1,209 filesystem files occupy stored blocks; none overlaps an omitted
CISO block. Its executable matches doldecomp's exact v1.02 target. This proves
the code target and retained file extents, not an independent byte-for-byte
comparison of every asset against another retail dump. Arbitrary modified
images, v1.01, other regions, and unlisted CISO encodings are rejected.

## Local builds

1. Run `python3 scripts/identify-game.py /path/to/your/image` to identify it.
2. Run `scripts/prepare-game.sh /path/to/your/image`. A supported CISO is
   normalized privately under `ref/normalized/`; the original is preserved.
   Revision 2 uses its own extraction and `modules-macos14-r2` module store.
3. For Simulator modules, use `MELEEPAD_GAME_REVISION=2 scripts/ios-build-core.sh`.
   For device modules, use
   `MELEEPAD_GAME_REVISION=2 scripts/ios-build-core-device.sh`.
   Repeat with `MELEEPAD_GAME_REVISION=0` to build v1.00 as well.
4. Build the Xcode app for the intended platform. Provisioning includes every
   already-built revision, and Simulator launches select the corresponding
   local module.
5. For a local device app, run
   `python3 scripts/stage-ios-modules.py /path/to/MeleePad.app --platform device`,
   then sign the staged modules and the app with the matching development
   identity before installation. Preserve both `.dol-sha256` identity files.

Importing a disc cannot create native executable code on an iPhone or iPad.
If its matching module is absent, the app retains the import and explains what
is missing. The public packager rejects playable apps, all recompiled module
names, and CISO as well as raw game images.

## Using the completed source

Bootstrap pins the completed decompilation separately at
`ae5898ee0dfda41b34fdf846f7d680a33e14779d` under `ref/melee-complete`; it preserves
the older reference checkout. `scripts/symbolize-melee.py --dol /path/to/main.dol
8034B164 801A4DAC` labels guest addresses using that exact committed symbol map.
It refuses a v1.00 executable. This is a debugging aid, not a source-code port.

The first concrete application is the revision-specific controller-wait audit:
v1.02's verified secondary scheduler wait and caller-qualified pad queue wait
are mapped separately. The old primary shortcut maps to `SITransfer`, so it
is disabled for v1.02 pending independent timing evidence. Existing v1.00
benchmark memory writes are disabled for v1.02 rather than applied to unrelated
addresses. Performance and rendering changes still require measured evidence.

For local peer acceptance, set `MELEEPAD_NETPLAY_TRACE_CANONICAL=1` on the
host runner to record every received canonical report and successful paired
comparison. A zero sequence means there is no new snapshot to compare, not a
successful comparison. Use a known initialized QA save to reach the normal
main-loop boundary, and keep modal startup coverage separate from gameplay.


For a macOS runner launched with `--controller 'Quartz/0/Keyboard & Mouse'`,
keyboard bindings now follow Dolphin's macOS defaults: arrow keys move,
X/Z/C/S map to A/B/X/Y, D to Z, Return to Start, Q/W to L/R, I/K/J/L to
the C-stick, and T/G/F/H to the D-pad. Previously this explicit keyboard device
received SDL gamepad bindings, which could not resolve its keys. This fixes the
runner configuration path; the launcher's controller picker still lists SDL
gamepads.
