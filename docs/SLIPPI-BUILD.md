# Slippi builds

Preview 5 adds the native iOS/iPadOS Slippi host to the public source build.
The public IPA remains an unsigned module-free shell. The owner-tested playable
iPad app also contains private generated game modules and data; those cannot be
recovered by merely importing an ISO into the public shell.

## Rebuild the public shell

On Apple Silicon with Xcode, CMake, Ninja, ripgrep and rustup:

```sh
bash scripts/bootstrap-dependencies.sh
rustup toolchain install 1.88.0 --profile minimal
rustup target add --toolchain 1.88.0 aarch64-apple-ios
bash scripts/check-repository.sh
bash scripts/ios-build-core-device.sh --core-only
python3 scripts/build-slippi-dependencies.py
bash scripts/ios-provision.sh device
xcodebuild -project MeleePad.xcodeproj -scheme MeleePad -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build-release \
  CODE_SIGNING_ALLOWED=NO build
bash scripts/package-public-ios-ipa.sh build-release/Build/Products/Release-iphoneos/MeleePad.app
```

The [Intel build probe](../.github/workflows/intel-ios-shell-build.yml) also
passed on a GitHub-hosted x86_64 Mac: it built the host `dolrecomp` compiler,
cross-built the ARM64 iOS app, and passed the unsigned module-free IPA audit.
That verifies the public shell build on Intel, not generation of the private
game/Slippi modules, signing, or playable iPhone/iPad operation. The complete
Intel-only path remains unvalidated.

The Rust build requires a new output directory. Preserve or relocate an existing
`build-slippi-device/rust` before rebuilding; old archives are never silently reused.
The pinned RecompCore `SlippiAdapter` holds the C++ adapter, upstream externals
and Rust submodule. There is no source-patch replay in bootstrap.

## Playable private builds

Use your own USA v1.02 image and Slippi account. Prepare the base game and native
modules using the repository's game preparation tooling. Slippi also requires a
native module compiled for its matching hook/code set, the Slippi GameSettings,
bootloader and matching game resources. The diagnostic generation scripts under
`scripts/build-slippi-*.py` document the current private pipeline through their
`--help` options. This remains a developer workflow, not a turnkey end-user
on-device compiler. A base offline module is not a substitute for a Slippi module.
Native Slippi currently starts only with USA v1.02. A v1.00 import remains
usable for standalone play; choose or import v1.02 for the Slippi route. The
home card reports this version mismatch before requesting your account.
When the game, module and account are ready, the home card also flags Low Power
Mode, serious heat, or a wireless audio route that can affect timing. Audio
advice refreshes when the output route changes; these are guidance, not blocks
on starting a match.

The supported, owner-tested preparation path uses an Apple Silicon Mac. An
Intel Mac can sign or sideload an already complete ARM64 iPhone/iPad IPA, but
the repository has no validated Intel-only playable-module build path. The
public module-free IPA cannot become playable by sideloading, importing an ISO,
or importing a Slippi account. Do not share a private completed IPA: it can
contain generated game code or game data.

Stage the resulting matching inputs with `scripts/stage-ios-modules.py`, then
sign the complete bundle using your own identity. Do not publish that bundle.
Retain the source pin, executable and module hashes, settings/code-set identity,
compiler and SDK versions for each test build. Verify the app's readiness message
before entering online play. Update existing devices in place with the same
bundle identifier and signing team to preserve user data.

Home **Settings → Slippi Input Delay** selects 1–4 local input-delay frames
(default 2). The choice is captured when the next native Slippi session starts and sent
to Slippi's existing online-delay configuration. It is separate from the older
experimental lobby's buffer setting. Changing it does not alter a running
match or repair packet loss or local performance stalls.
The ready-to-play home card now flags Low Power Mode or serious heat before a
Slippi run. Startup diagnostics record those conditions and the screen refresh
rate to help interpret a later timing report; this is advice, not a network fix.
The card also updates when the device's network path becomes unavailable or
cellular-only. A usable path does not prove Slippi's servers are reachable or
measure latency, so this guidance does not block starting a match.

## Import your Slippi profile

Follow the [README account-import steps](../README.md#import-your-slippi-profile-on-iphone-or-ipad): download your own `user.json`, save it in Files, then choose
**Slippi Multiplayer → SET UP SLIPPI → Import Account**. The account import
is separate from preparing the game and native module.
The account stays in this device's Keychain. A temporary plaintext copy is
needed while the native runtime runs; the next app startup removes any copy
left by a force-quit without deleting run diagnostics or the imported account.
To switch accounts later, use **Home → Settings → Import or Replace Slippi
Account**. A successful replacement returns to Home; it does not start a match.

## Modes and support boundary

Completed Unranked games have been tested on the maintainer's physical iPad.
Ranked uses Slippi's ordinary subscription/free-day eligibility. Direct, Teams
and Party are admitted by the host but are not equivalently hardware-validated.
Poor connection quality and local performance stalls remain under investigation.
Replay and numeric diagnostic files stay local until shared by the user; treat
replays as potentially identifying when submitting reports.
**Settings → Recent Slippi Replays** lists up to eight saved files after a run
and opens the system share sheet for the one you select. An interrupted run can
leave an incomplete replay; this list does not verify game completion or a
winner. Sharing is disabled while Slippi is running so the selected file is no
longer being written. No replay is uploaded automatically.

## Compare completed replays during development

DashDance's replay reader inspired a strict, offline comparison command. Supply
one recorded `.slp` and a separately generated reference for the same game:

```sh
python3 scripts/compare-slippi-replays.py \
  --recorded /private/path/recorded.slp \
  --reference /private/path/reference.slp \
  --output /private/path/comparison.json
```

The command checks matching replay versions, coverage from Slippi's first frame,
required fields and the full game-end payload, then reports the first differing
finalized pre- or post-frame field or unmapped payload byte. Exit codes are
0 equivalent, 1 divergent, 2 incomplete, 3
invalid and 4 unsupported. Repeated rollback records are counted, but equality
of the final records does not prove each rollback step matched. The tool does not
generate the reference replay or authenticate to Slippi. Keep both replays and
the report private unless you have reviewed their contents for player data.
