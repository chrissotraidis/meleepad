# G5 local PGO package workflow

Date: 2026-08-27

Status: **PRIVATE-PROFILE PACKAGE PATH RETAINED; TRAINING PATH STILL OPEN**

## Question

The current-source PGO oracle repeatedly saves about 4.2 ms of CPU-thread work,
but the supported product scripts could only build the profile-free module.
Could the existing profile-hashed ModernGekko support be exposed through one
ROM-safe local workflow without committing the profile, generated module, app,
or a private filesystem path?

This step does not claim that a clean clone can train the profile. It closes
only the profile-consuming build/package bridge.

## Workflow

`scripts/prepare-game.sh` now accepts an optional second argument (or
`SSBMPAD_PGO_PROFILE`) containing private LLVM profile data. It validates the
profile before dependency work, then passes it to the already-retained
`moderngekko-port --pgo-profile` path. The default one-argument behavior is
unchanged.

`scripts/package-local-pgo-app.sh` composes the supported steps:

1. validate the user-owned revision-0 ISO and private profile;
2. preserve the canonical `active-module.txt` pointer;
3. build or select the hash-keyed PGO module;
4. require the manifest to contain the profile SHA-256 and no private path;
5. package, layout-test, and strictly ad-hoc sign a local app; and
6. restore the original active-module pointer on success or failure.

Only the profile SHA-256 is printed. The script, profile, module cache, and app
remain within the existing ignored/local boundaries.

Usage:

```text
scripts/package-local-pgo-app.sh \
  /path/to/GALE01-revision-0.iso \
  /private/path/current-idle-fountain.profdata \
  /private/output/SsbmPad-PGO.app
```

## End-to-end proof

The first current-source invocation performed a genuine 247-step generated
module build and ThinLTO link. Apple Clang consumed the profile without stale,
missing, or hash-mismatch warnings. The output then passed package layout,
arm64 identity, macOS 14 minimum, and strict deep ad-hoc signing.

- profile SHA-256:
  `3f9d2aa4dbd5aa34465c8b975e5c6c369518e0db23137b2e424295a0f572ac12`;
- cache key suffix: `5d9d1b7aea44e9f0`;
- unsigned cache module SHA-256:
  `abb435806d2f123981686b097661f89fa6d41513709be4b61f8252b2785bd3ab`;
- packaged signed module SHA-256:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

The packaged hash exactly reproduces the retained PGO oracle. The manifest
records `pgo_profile_sha256` in the cache identity and contains no
`/private/tmp` or full profile path.

A second invocation completed in 24 seconds, explicitly logged `cache hit`,
reproduced the same signed module hash, and restored the canonical pointer. A
negative test then selected the cached PGO module and deliberately attempted
to package under `/dev/null`; packaging failed with status 1 as intended, and
the trap still restored the canonical pointer.

The two disposable proof apps were removed afterward. The reusable ignored
module cache remains. The ROM, private profile, generated module, app, and
private-path logs are absent from tracked files.

## Decision

**PERF-071 retains the local private-profile packaging bridge. G5 remains
open; Final Destination and G6 remain blocked.** This is infrastructure for
the measured compute improvement, not a performance acceptance result. The
next missing piece is a repository-native, data-free local training/merge
recipe driven by user-owned ROM/runtime inputs; until that exists, the private
profile cannot define the canonical clean-clone product.
