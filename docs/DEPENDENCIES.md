# Dependency provenance and forks

MeleePad is the Apple app repository. It consumes maintained forks of the runtime,
compiler, and transport; each fork retains upstream history and license notices.
The app repository itself is not a GitHub fork of one of these dependencies.

## Maintained source graph

```text
MeleePad
└── ref/ModernGekko
    └── vendor/dolphin (RecompCore)
        ├── DolRecomp
        ├── Externals/enet/enet
        └── SlippiAdapter/rust (slippi-rust-extensions)
```

| Component | MeleePad fork commit | Upstream base |
| --- | --- | --- |
| modernGekko | [`caa300853745b21ef4fa68e4137a0830c8d9b5a8`](https://github.com/chrissotraidis/ModernGekko/commit/caa300853745b21ef4fa68e4137a0830c8d9b5a8) | [`048c426ba3db0369e40826d22ad3adcce7fe7c58`](https://github.com/ExpansionPak/ModernGekko/commit/048c426ba3db0369e40826d22ad3adcce7fe7c58) |
| recompCore | [`a697cb8f5e85aa488c9afb722f14ff37d0d76a0e`](https://github.com/chrissotraidis/RecompCore/commit/a697cb8f5e85aa488c9afb722f14ff37d0d76a0e) | [`e13ab348f13cd67879f6db6e9d7185410f8f62c6`](https://github.com/ExpansionPak/RecompCore/commit/e13ab348f13cd67879f6db6e9d7185410f8f62c6) |
| dolRecomp | [`7a18425130a98596364d6063a49562d0f731230b`](https://github.com/chrissotraidis/DolRecomp/commit/7a18425130a98596364d6063a49562d0f731230b) | [`93b881c8f73df1d64a88491f2aa50c7c9ed2384d`](https://github.com/ExpansionPak/DolRecomp/commit/93b881c8f73df1d64a88491f2aa50c7c9ed2384d) |
| enet | [`c8827b136c5681d0b12d30a0746492527d7cfced`](https://github.com/chrissotraidis/enet/commit/c8827b136c5681d0b12d30a0746492527d7cfced) | [`2662c0de09e36f2a2030ccc2c528a3e4c9e8138a`](https://github.com/lsalzman/enet/commit/2662c0de09e36f2a2030ccc2c528a3e4c9e8138a) |

Slippi Rust is pinned by the RecompCore gitlink to
[`4ad5ab440f3d277cfea82accbadfdcdc9510f2f9`](https://github.com/chrissotraidis/slippi-rust-extensions/commit/4ad5ab440f3d277cfea82accbadfdcdc9510f2f9).
The adapter records its Slippi Dolphin donor commit and retains the original
notices. Rust dependencies are selected by its committed Cargo.lock and built
with Rust 1.88.0. See [Slippi builds](SLIPPI-BUILD.md).

The [dependency lock](../config/dependencies.lock.json), parent gitlinks, nested
`.gitmodules`, and checked-out sources must agree. Run:

```sh
bash scripts/bootstrap-dependencies.sh --sources-only
python3 scripts/dependency-lock.py
```

Normal bootstrap initializes the Apple build dependencies; `--references` also
prepares the pinned SunPad, template, Melee, and m-ex references used by developer
tools. No game data is downloaded. Dirty checkouts are preserved and rejected.
Use a fresh worktree to migrate an older patched dependency installation.

MeleePad-specific branches coexist with GalaxyPad's branches; neither app follows
a floating default branch. Updating one app's pin does not update the other.
Original author names and per-file license notices remain authoritative.

## Updating dependency source

1. Make and review ordinary source commits in the maintained component fork.
   Do not add a bootstrap patch or edit a dependency during the build.
2. Update gitlinks from the changed component outward through its parents,
   then update MeleePad's `ref/ModernGekko` gitlink and
   `config/dependencies.lock.json` to the reviewed commits. Keep URLs, notices
   and provenance documentation consistent with the selected source.
3. In a clean worktree, run `bash scripts/bootstrap-dependencies.sh --sources-only`
   and `bash scripts/check-repository.sh`. The lock checker rejects mismatched
   revisions and tracked or nonignored untracked dependency changes.
4. Require the `source-checks` and `ios-build` CI checks before merging.
   Source/build success does not establish gameplay or performance acceptance.

The historical `patches/` directory is not an update mechanism. Existing patched
local checkouts should be preserved and replaced by a fresh worktree for normal
builds, rather than reset or silently rewritten by bootstrap.

## Migration evidence and limits

The earlier public bootstrap failed replaying `0011-ios-shader-workers.patch` on
its declared inputs. Rather than continue relying on patch-order checks, the
migration recorded the inspected working dependency source as ordinary commits.
The [migration record](../config/dependency-migration.json) hashes each carried
source file. The nested Git URLs/pins changed to the maintained fork graph; source
files were compared byte-for-byte with the captured working tree. ENet's startup
RTT smoothing has a regression exercising its actual ACK handler.

The snapshot includes the existing opt-in runtime diagnostics; it does not prove
every historical optimization or experiment beneficial. Subsequent changes require
separate review and measured evidence. The old [patch archive](../patches/README.md)
remains for provenance and legacy tests, but bootstrap no longer applies it.
Some legacy source-contract tests inspect archived patches; those are distinct
from compiled behavioral tests and the current pinned-source/iOS build checks.

The ARM64 fallback repair from [RecompCore PR #6](https://github.com/ExpansionPak/RecompCore/pull/6)
is present in the captured source: its complete two-file diff passes a reverse
application check, including block-link suppression, the dispatcher yield call,
and PC writeback before returning. The upstream merge is not an ancestor of this
older vendor branch, so ancestry alone would give the wrong answer. This is source
verification, not a benchmark or a claim about every historical Mac binary.

The private Slippi host/overlay and game module are separate release inputs. This
fork migration does not make the private Slippi build reproducible or publicly
available. See [Slippi release readiness](SLIPPI-RELEASE-READINESS.md).
