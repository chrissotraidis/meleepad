# G8 clean-clone build

Date: 2026-08-30

Status: **G8 row 15 pass**

## Question

Can a fresh checkout fetch only the pinned public dependencies, validate the
user's private GALE01 revision-0 image, regenerate the static module, package
the macOS product, and pass the repository and package gates without borrowing
the working checkout's ignored dependency or build trees?

## Initial failure

A single-branch clone of published `main` started at
`291f05f20794b6e66e4ea1e0352a5555b04704ef`. The first ordered dependency
bootstrap failed at
`patches/moderngekko-dolphin/0017-macos-layer-display-sync.patch`.

The canonical patch still expected Dolphin's original unguarded
`setDisplaySyncEnabled:` calls. The earlier pinned SunPad iOS patch had already
wrapped those calls in `#if TARGET_OS_OSX`, so patch 0017 could not apply to a
genuinely fresh composed tree. The long-lived working dependency checkout
masked the defect because the final product-policy marker was already present.

The retained repair changes only patch 0017's context and nesting: it applies
inside the existing macOS availability guard and retains the forced product
display-sync policy plus diagnostic breadcrumb. No product behavior changes
relative to the previously built working tree.

## Clean reproduction

The same disposable clone copied in only the corrected canonical patch, then
ran this ordered pipeline:

```text
scripts/bootstrap-dependencies.sh
scripts/check-repository.sh
SSBMPAD_JOBS=8 scripts/prepare-game.sh <private GALE01 revision-0 ISO>
SSBMPAD_JOBS=8 scripts/package-macos-app.sh
scripts/test-macos-package-layout.sh build-macos/SsbmPad.app
codesign --verify --deep --strict build-macos/SsbmPad.app
scripts/bootstrap-dependencies.sh
scripts/check-repository.sh
```

Observed results:

- all pinned public repositories and required nested submodules cloned at the
  documented revisions;
- all canonical patches through Dolphin 0028 applied and the scope audit
  passed;
- the exact 1,459,978,240-byte GALE01 revision-0 image validated and extracted
  1,209 files;
- DolRecomp generated 237 chunks and the clean ThinLTO module linked;
- the macOS runner and launcher each rebuilt in a separate clean product build
  directory;
- package layout passed, and strict deep code-sign verification passed with an
  ad-hoc `com.ssbmpad.SsbmPad.macos` signature;
- the final repository suite passed after packaging.

## Output identity

All three packaged binaries are arm64 Mach-O files:

| File | Bytes |
|---|---:|
| `SsbmPadFrontend` | 21,900,480 |
| `SsbmPadRunner` | 22,005,984 |
| `gGALE01_recomp.dylib` | 81,865,632 |

The generated module targets macOS 14.0 with SDK 26.5 and has SHA-256
`935349ac88488ca0623d2302cae31653ab1a08d2c9b7643706ad6cf8e4d4fc08`.
The private image, extraction, generated sources, module, and app bundle remain
outside version control.

## Decision

G8 row 15 passes for the corrected candidate tree. This proves reproducible
construction and packaging, not gameplay, combat performance, mobile-device
readiness, or netplay.
