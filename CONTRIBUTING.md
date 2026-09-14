# Contributing to MeleePad

Report app problems in [MeleePad issues](https://github.com/chrissotraidis/meleepad/issues).
Include the build, device and OS, game revision, scene, reproduction steps, and
expected/actual behavior. Review diagnostic exports before sharing. Never attach
game images, extracted assets, generated game code, saves, credentials, signing
material, or another player's private information.

## Source ownership and review

Apple UI, controls, import, diagnostics, and packaging belong in this repository.
Runtime and compiler changes belong with ModernGekko, RecompCore, or DolRecomp;
retain their project names, licenses, author history, and notices. Follow the
receiving project's contribution policy before proposing a change upstream.

MeleePad currently consumes pinned upstream revisions plus a patch series. The
maintainer's GalaxyPad dependency forks exist, but are not yet MeleePad build
inputs. See [dependency provenance](docs/DEPENDENCIES.md). Do not point MeleePad at
another game's fork tip without reviewing compatibility. A migration must retain
all required fixes as reviewable commits and verify the resulting source tree,
nested dependencies, build, and game behavior before replacing the patch pipeline.

Use focused pull requests with the concrete problem, resulting behavior, and
validation. Keep controls and appearance consistent. Preserve existing user data
and local modifications. Tests support review; a successful build or menu capture
does not establish physical gameplay, audio quality, or network interoperability.

Run focused checks for the change and the repository suite:

```sh
./scripts/check-repository.sh
```

Some existing checks need prepared local dependencies or private evidence. Report
missing inputs and failed checks explicitly; do not count unavailable checks as
passing. Never download game data to satisfy a test.

## Release provenance

Record the app and dependency commits, patches, toolchain, build flags, module
identity, and artifact hashes. Retain corresponding source and original license
texts for distributed components. Distinguish redistributable sources from inputs
the user must supply privately. A newly documented license or fork link does not
retroactively validate an existing binary's provenance.

AI assistance is permitted for MeleePad contributions; contributors remain
responsible for understanding and reviewing their work. Upstream projects may
have different policies. See [Credits](CREDITS.md) and [notices](THIRD-PARTY-NOTICES.md).
