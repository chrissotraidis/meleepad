# G5 PGO package Game Mode refresh

Date: 2026-08-29

Status: **FASTEST LOCAL PACKAGE REFRESHED; GAME MODE ELIGIBILITY RESTORED; G5 OPEN**

## Question

Is the reusable `build-macos/MeleePad-PGO.app` still a valid current product
package for the next G5 acceptance run, or has its ignored local bundle drifted
behind the repository's retained Game Mode/package requirements?

## Audit result

The ordinary canonical `MeleePad.app` passed the current package-layout test and
contained both:

- `LSApplicationCategoryType=public.app-category.games`; and
- `LSSupportsGameMode=true`.

The reusable PGO app was correctly signed and still contained the retained
known-profile module, but its older `Info.plist` contained neither key. It
therefore failed `scripts/test-macos-package-layout.sh`. This was a stale local
bundle, not a source, generated-module, or gameplay regression. Launching it
could not establish the Game Mode eligibility required by the retained
PERF-114/116 product topology.

## Pointer-safe refresh

The supported local workflow was run with the validated, read-only revision-0
ISO and the existing private profile whose SHA-256 is
`3f9d2aa4dbd5aa34465c8b975e5c6c369518e0db23137b2e424295a0f572ac12`:

```text
scripts/package-local-pgo-app.sh <validated-revision-0-ISO>
  <private-current-idle-fountain.profdata> build-macos/MeleePad-PGO.app
```

The script validated the ISO and profile, selected the hash-keyed PGO module,
built the current launcher/runner, packaged from the current canonical
`apple/macos/Info.plist`, ran package-layout verification, deep ad-hoc signed
the bundle, and restored the canonical `active-module.txt` on exit.

The previous stale bundle is retained locally as
`build-macos/MeleePad-PGO.app.previous.20260829-104114`. It is recoverable and
was not deleted.

## Verified refreshed package

- bundle metadata: games category and `LSSupportsGameMode=true`;
- runner SHA-256:
  `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`;
- known PGO module SHA-256:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- runner/module architecture: native arm64;
- runner/module minimum OS: macOS 14.0;
- package-layout test: pass;
- strict deep signature verification: pass; and
- canonical active-module SHA-256 after restoration:
  `03e7936e6eb031f8ed62af7dbc31c17dd9abab98937b6fc7be806b30e87b6461`.

No game or Simulator was launched. No ROM, extracted file, profile, generated
module, app, save, log, or private path is added to Git.

## Decision

The fastest known local PGO package is again eligible for a confirmed
fullscreen Game Mode acceptance run. This closes a local package-readiness
defect; it does not prove Game Mode activation, gameplay, frame cadence, or G5.
Before the next live run, require this package-layout pass and a naturally
clean host window. G5 remains open and G6 remains blocked.
