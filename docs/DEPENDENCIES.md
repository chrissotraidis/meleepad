# Dependency provenance and forks

MeleePad is the Apple app repository. It was created as a separate integration
repository, not a GitHub fork of a single compiler or runtime. Its dependency
history still belongs to the upstream projects listed in [Credits](../CREDITS.md).

## Current build inputs

The [bootstrap script](../scripts/bootstrap-dependencies.sh) is authoritative for
these upstream base revisions and the ordered patch application. `ref/` is ignored;
local generated code, game data, and build outputs are not public source inputs.
A base commit alone is not the complete source identity of a patched dependency.

| Component | Upstream base commit | Local checkout |
| --- | --- | --- |
| [ModernGekko](https://github.com/ExpansionPak/ModernGekko) | [`048c426ba3db0369e40826d22ad3adcce7fe7c58`](https://github.com/ExpansionPak/ModernGekko/commit/048c426ba3db0369e40826d22ad3adcce7fe7c58) | `ref/ModernGekko` |
| [RecompCore runtime](https://github.com/ExpansionPak/RecompCore) | [`e13ab348f13cd67879f6db6e9d7185410f8f62c6`](https://github.com/ExpansionPak/RecompCore/commit/e13ab348f13cd67879f6db6e9d7185410f8f62c6) | `ref/ModernGekko/vendor/dolphin` |
| [DolRecomp compiler](https://github.com/ExpansionPak/DolRecomp) | [`93b881c8f73df1d64a88491f2aa50c7c9ed2384d`](https://github.com/ExpansionPak/DolRecomp/commit/93b881c8f73df1d64a88491f2aa50c7c9ed2384d) | `ref/ModernGekko/vendor/dolphin/DolRecomp` |
| [ModernGekko-Template](https://github.com/ExpansionPak/ModernGekko-Template) | [`1ee85bb5e09c38f493a09f5fa6e9dc8228b23e42`](https://github.com/ExpansionPak/ModernGekko-Template/commit/1ee85bb5e09c38f493a09f5fa6e9dc8228b23e42) | `ref/ModernGekko-Template` |
| [RecompCore reference](https://github.com/ExpansionPak/RecompCore) | [`af7a1a4854ee243b92926875e5a6b66663b0fda0`](https://github.com/ExpansionPak/RecompCore/commit/af7a1a4854ee243b92926875e5a6b66663b0fda0) | `ref/RecompCore` |
| [SunPad](https://github.com/chrissotraidis/sunpad) | [`e43f0ea6b797e5110787171957c9dc3c6213269c`](https://github.com/chrissotraidis/sunpad/commit/e43f0ea6b797e5110787171957c9dc3c6213269c) | `ref/sunpad` |
| [Melee reference](https://github.com/doldecomp/melee) | [`8b5e380f412dc6bad8cc0557fa8fd95fee6815ed`](https://github.com/doldecomp/melee/commit/8b5e380f412dc6bad8cc0557fa8fd95fee6815ed) | `ref/melee` |
| [Completed Melee reference](https://github.com/doldecomp/melee) | [`ae5898ee0dfda41b34fdf846f7d680a33e14779d`](https://github.com/doldecomp/melee/commit/ae5898ee0dfda41b34fdf846f7d680a33e14779d) | `ref/melee-complete` |
| [m-ex reference](https://github.com/akaneia/m-ex) | [`c9f25da0e59e8c387895371934e98eb5046796b3`](https://github.com/akaneia/m-ex/commit/c9f25da0e59e8c387895371934e98eb5046796b3) | `ref/m-ex` |

MeleePad integration patches live in [patches](../patches/), including
`moderngekko/`, `moderngekko-dolphin/`, and `dolrecomp/`. Additional Apple foundation
patches are selected by bootstrap from the pinned SunPad checkout. Follow the
script's order; do not infer a complete build from a directory listing or apply
all research patches indiscriminately. Original upstream license files, git
histories, and author notices must be preserved.

## Maintained forks and migration boundary

The maintainer maintains these actual GitHub forks for GalaxyPad:

| Maintained fork | Upstream parent |
| --- | --- |
| [chrissotraidis/ModernGekko](https://github.com/chrissotraidis/ModernGekko) | [ExpansionPak/ModernGekko](https://github.com/ExpansionPak/ModernGekko) |
| [chrissotraidis/RecompCore](https://github.com/chrissotraidis/RecompCore) | [ExpansionPak/RecompCore](https://github.com/ExpansionPak/RecompCore) |
| [chrissotraidis/DolRecomp](https://github.com/chrissotraidis/DolRecomp) | [ExpansionPak/DolRecomp](https://github.com/ExpansionPak/DolRecomp) |

[GalaxyPad's source guide](https://github.com/chrissotraidis/galaxypad/blob/main/docs/DEPENDENCIES.md)
records its pinned nested fork graph. **Those commits are not MeleePad's selected
build inputs.** Linking these forks does not migrate MeleePad, validate their
Melee compatibility, or replace its existing patch series.

A MeleePad migration needs separate reviewed commits preserving its runtime,
compiler, revision, netplay, and platform changes. Compare the final source tree
against the retained working inputs, pin nested dependencies, and validate builds
and gameplay before switching bootstrap. Do not rewrite upstream history or move
existing GalaxyPad pins to accommodate MeleePad.

## Release records

For a new release, record the app commit, all dependency bases plus patches or
fork commits, nested dependency commits, toolchain and flags, private module
identity, and final artifact hashes. Retain original license texts and the source
corresponding to the distributed components. Research checkouts and local private
Slippi builds may contain additional inputs absent from the public bootstrap;
they must be inventoried separately before claiming reproducibility or shipping.

This document clarifies attribution and source ownership. It does not certify
historical packages, Slippi interoperability, or compliance of an unreviewed
binary. See [third-party notices](../THIRD-PARTY-NOTICES.md) and
[contribution guidelines](../CONTRIBUTING.md).
