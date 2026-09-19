# Slippi preview iteration — September 14, 2026

This is a private development checkpoint, not a public preview release. The owner
has not found an online opponent and has not confirmed online play. No new
online match, cross-engine parity, physical gameplay or audio acceptance is
claimed by this iteration. The physical iPad installation was not changed.

## Repairs and evidence

- Device provisioning previously required its linker response file before
  generating it. It now checks prepared sources first and the complete response
  afterward. Empty responses, missing relative/external archives, malformed
  arguments and directories posing as archives fail. Three retained fixtures
  passed the old check incorrectly and fail the repaired check. Nine focused
  tests cover this behavior.
- Device and Simulator provisioning shared one development configuration. The
  Xcode resource now selects `Provisioned/$(PLATFORM_NAME)/dev-config.plist`.
  After both provisioning runs, both app builds copied the matching platform's
  configuration. Simulator configuration contains no device bundle paths.
- Simulator provisioning no longer automatically calls an ordinary v1.02
  module Slippi-capable. `MELEEPAD_SLIPPI_MODULE` is an explicit opt-in and uses
  the staging validator: original disc revision identity, Apple platform and
  required injected native GCT coverage. The retained injected Simulator module
  passes; wrong-platform and ordinary-module controls are rejected.
- The Slippi Rust FFI static-library change is now recorded in
  [the maintained fork](https://github.com/chrissotraidis/slippi-rust-extensions/tree/codex/meleepad-ios-static-20260914),
  commit `4ad5ab440f3d277cfea82accbadfdcdc9510f2f9`, based on upstream
  `2d29e794de8497582675fb70877851f2cdd2f256`. Original source history and GPL
  license text remain in that fork. The only integration change is `cdylib` to
  `staticlib` in `ffi/Cargo.toml`.
- `scripts/build-slippi-rust.py` rejects wrong revisions, dirty sources and a
  copied directory that only inherits a parent repository's Git identity.
  Five actual-Git fixture tests cover those conditions. It selects Cargo,
  rustc and rustdoc explicitly from Rust 1.88.0, uses `--locked`, and writes
  toolchain, SDK, source/lock/header and archive identities. This avoids the
  mixed rustup/Homebrew compiler selection observed on this Mac.
- Both clean Rust library builds passed for iPhoneOS and Simulator, using
  Xcode 26.6 (17F113), SDK 26.5 and deployment target 16.0. Both private app
  targets linked against the new archives. The generated FFI header is
  byte-identical to the previously used header. Retained C++ libraries and
  assembled Slippi overlay inputs still require their separate provenance work.
- A fresh Simulator Slippi launch with no retained disc reproduced an invisible
  startup error: UIKit rejected the alert during `viewDidLoad`. The controller
  now retains that message until `viewDidAppear`, so the missing prerequisite
  can be explained instead of leaving only a generic failure label. The same
  Simulator launch displayed the complete missing-disc explanation after the
  repair. No native gameplay ran in that isolated, unprovisioned test.

The complete development-checkout repository suite passed, including the 14 new
focused tests. The app changes remain in the private development checkout; only
the small Rust dependency fork has been published. No preview IPA was released.

## Rebuild the Rust component

Clone the fork into an ignored local directory and check out the exact commit
above. Install Rust 1.88.0 and its `aarch64-apple-ios` and
`aarch64-apple-ios-sim` targets. Then run, with new output directories:

```sh
python3 scripts/build-slippi-rust.py --source ref/slippi-rust-preview \
  --output ref/slippi-compatibility/preview-rust-device --platform device
python3 scripts/build-slippi-rust.py --source ref/slippi-rust-preview \
  --output ref/slippi-compatibility/preview-rust-simulator --platform simulator
```

Each output contains `build.log` and `provenance.json`. This recipe describes one
source component; it does not establish bit-identical reproduction of an entire
app or retroactive provenance for previously compiled libraries. Preserve
Project Slippi attribution and the fork's original license notices when preparing
a recipient package.

## Remaining preview work

1. Record and reproduce the C++ Slippi overlay and its remaining dependencies;
   integrate the private host with the maintained runtime graph and app credits.
2. Repair/rebuild the ordinary Simulator v1.02 generated-module inputs: the
   existing module fails the original-disc identity check. Full staging is
   correctly blocked; do not weaken this check or relabel it as Slippi.
3. Build and audit the exact complete candidate, preserving module/revision
   identity and bundling corresponding notices and source references.
4. Exercise local paired gameplay, rollback, completed results, rematch and
   disconnect/recovery on that candidate. These tests do not replace official
   desktop interoperability or physical gameplay/audio acceptance.
5. Obtain actual opponent testing before making online-support claims. Retained
   Internet latency problems remain unresolved; no network fix is claimed here.
