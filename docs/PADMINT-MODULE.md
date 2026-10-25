# Portable offline module preparation

MeleePad's offline iPhone build can use the published app and compile only the
game module from the player's reviewed USA v1.00 or v1.02 image. The portable
backend is `scripts/build-padmint-module.py`. It uses the committed standalone
DolRecomp generator and RecompCore module template. It does not build the app,
the runtime, Rust Slippi, or a native player executable.

This is source preparation for a future PadMint recipe. It is not a release or
a device acceptance result. The public-release pause in `AGENTS.md` still
applies. Windows remains unadvertised until a complete Windows build has been
recorded. Neither Windows x64 nor Linux is implied by a Windows ARM64 test.

## Shared packaging prerequisite

The recipe requires PadMint's schema 2 module-result support, after the shared
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
  uses reviewed defaults and cannot reuse obsolete chunks after an option change. The
  current generator invocation matches `moderngekko-port`'s C/Gekko/GameCube
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
An import or package check does not prove app launch, gameplay, sound, controls,
or performance. Those remain separate physical-device checks.
