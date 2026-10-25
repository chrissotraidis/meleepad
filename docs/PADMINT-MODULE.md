# Portable offline module preparation

MeleePad's offline iPhone build can use the published app and compile only the
game module from the player's reviewed USA v1.00 or v1.02 image. The portable
backend is `scripts/build-padmint-module.py`. It uses the committed standalone
DolRecomp generator and RecompCore module template. It does not build the app,
the runtime, Rust Slippi, or a native player executable.

This unreleased recipe offers experimental Apple Silicon Mac and Windows ARM64/x64
builds. It is not a release or a device acceptance result. The public-release
pause in `AGENTS.md` still applies. Linux is not advertised. The x64 compiler proof ran under Windows ARM emulation;
a native x64 Windows player run remains unverified.

## Shared packaging prerequisite

The recipe requires PadMint's schema 2 module-result support in
[PR 179](https://github.com/chrissotraidis/padmint/pull/179), after the shared
Windows hardening and installed-input changes (PadMint PRs 177 and 178).
Older PadMint versions must reject schema 2 rather than run a partial recipe.
Do not publish the new recipe or change PadMint's catalog until the required
PadMint implementation is released and the normal player checks pass.

PadMint prepares its pinned public-source SDK and provides `{ios_toolchain}`.
The backend writes `module-result.json` inside the current private work folder.
It names one checksummed module and one checksummed DOL-identity sidecar, using
POSIX paths relative to that descriptor. PadMint verifies these files, checks
the module's imported names against the published app and known runtime names,
and packages both files itself. The backend does not import PadMint's Python
package or change the published app.

The v1.00 destinations are `gGALE01_recomp.dylib` and its `.dol-sha256` sidecar.
The v1.02 destinations are `gGALE01r2_recomp.dylib` and its `.dol-sha256` sidecar.
The existing app requires v1.02's adjacent sidecar to match the revision catalog;
renaming the module without its identity is insufficient.

## Source and private-input checks

- The complete original image must match `apple/shared/MeleePadRevisions.json`.
  A reviewed CISO can be normalized privately; existing normalized images are
  validated and never overwritten.
- The extracted DOL must match the same revision's SHA-256 and the extraction
  must contain 1,209 game files. Incompatible or incomplete cached extractions
  are preserved and rejected.
- The backend initializes only the locked ModernGekko, RecompCore, DolRecomp and
  ENet submodules. Modified checkouts are preserved and rejected. There are no
  bootstrap patches, floating source revisions, or game-data downloads.
- An optional `--source-root` uses an already prepared checkout read-only. Its
  lock, gitlinks and clean dependency contents must match the current recipe.
- Generated chunks are separated by DOL, dependency-lock and generator-option
  identity. Inherited `DOLRECOMP_*` tuning variables are cleared so this recipe
  uses reviewed defaults and cannot reuse obsolete chunks after an option
  change. The current generator invocation matches `moderngekko-port`'s C/Gekko/GameCube
  path. It stops if the runtime gains `Data/Sys/GameSettings/GALE01.ini`, because
  new default DOL patches would need a reviewed equivalent preparation step.

Keep images, extractions, generated source, modules and personal IPAs private.
Use a task-owned work folder with enough space for extraction, compilation and
optional CISO normalization. The existing 30 GB catalog estimate is retained
until complete player measurements justify a smaller requirement.

## Validation

Run `python3 tests/test-padmint-module.py` for synthetic tests covering revision
identity, checksums, cache preservation, generator separation, source pin checks
and Windows compiler-environment preparation. The default repository suite is
`bash scripts/check-repository.sh`, with dependencies prepared as documented in
`CONTRIBUTING.md`.

For a private build with PadMint's already prepared toolchain:

```sh
python3 scripts/build-padmint-module.py \
  --rom /path/to/reviewed-image.iso \
  --work /path/to/private-work \
  --toolchain /path/to/iPhoneOS-open-source.sdk/toolchain.cmake
```

Windows needs Visual Studio 2022 C++ Build Tools and a Windows SDK. The backend
selects the native ARM64 tools when available and otherwise uses x64 tools.
macOS needs a native C compiler and the macOS SDK for the small host generator.
PadMint's LLVM and public-source SDK compile the iPhone module on either host.
Use a local Windows work folder: native CMake link commands cannot use a UNC
working directory. Private inputs can remain on a shared volume.

The module uses the maintained template's optimization and floating-point
defaults, including its normal interprocedural optimization, plus the existing
iPhone build's `apple-a15` CPU tuning. It adds no experimental compiler flags.

Recorded private build validation on 2026-10-26:

- Apple Silicon Mac: original v1.00 ISO and v1.02 CISO through the standalone
  generator and LLVM 22.1.8 module build, strict imports, revision-specific
  identity and final IPA checks passed.
- Windows 11 ARM64: the bundled x64 Python 3.13.15 ran PadMint's checkout
  `tools --repo` and `build --repo --revision --app` route successfully for
  v1.00, with native ARM64 MSVC 19.44 host tools and LLVM 21.1.8. This used
  already verified tools and an existing checked extraction, with local build
  files. It was a warm-cache pre-release check, not a clean-machine or published
  `make` check. A complete v1.02 Windows run remains unverified.
- Windows x64 toolchain: a fresh v1.00 extraction, generation, default module
  compile and personal IPA passed with actual x64 MSVC 19.44, DolRecomp and
  LLVM/LLD 21.1.8 executables. The test ran under Windows ARM64 emulation with
  an explicit x64 compiler environment; CMake and Ninja were ARM64 coordinators.
  It establishes x64 compiler compatibility, not a native x64 host or default
  player run. All 241 generated files matched the Windows ARM64 output exactly.
- All three routes preserved all 3,317 members of the v0.2.4 published app, including
  their ZIP metadata, and added only the chosen module and its identity sidecar.
  The final v1.00 generator outputs matched between Mac and Windows after text
  line-ending normalization. No private inputs or outputs were uploaded.

An import or package check does not prove app launch, gameplay, sound, controls,
or performance. Those remain separate physical-device checks.
