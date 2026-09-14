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

MeleePad consumes exact maintained ModernGekko, RecompCore, DolRecomp and ENet
fork commits through nested submodules. See [dependency provenance](docs/DEPENDENCIES.md).
Commit runtime/compiler changes in the relevant fork, then update the app's lock
and gitlink together. Do not add automatic bootstrap patches or follow a floating
branch. Preserve GalaxyPad's separate selected commits.

`main` requires a pull request and current passing `source-checks` and `ios-build`
checks, including for administrators. Source checks and iOS compilation do not
substitute for code review or physical gameplay/audio acceptance.

Use focused pull requests with the concrete problem, resulting behavior, and
validation. Keep controls and appearance consistent. Preserve existing user data
and local modifications. Tests support review; a successful build or menu capture
does not establish physical gameplay, audio quality, or network interoperability.

Run focused checks for the change and the repository suite:

```sh
./scripts/check-repository.sh
```

Prepare sources with `bash scripts/bootstrap-dependencies.sh --sources-only`.
Keep private game-derived experiments outside the default suite and report
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
