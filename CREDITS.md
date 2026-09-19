# Credits and provenance

MeleePad is an Apple integration project built on the work below. It does not
claim authorship of the recompilation tools, compatibility runtime, or game.

| Project | Contribution |
| --- | --- |
| [ModernGekko — Hyperway, ExpansionPak and contributors](https://github.com/ExpansionPak/ModernGekko) | Runtime integration, game-port tooling, and native execution framework |
| [DolRecomp — ExpansionPak and contributors](https://github.com/ExpansionPak/DolRecomp) | Ahead-of-time PowerPC code generation |
| [RecompCore — ExpansionPak and contributors](https://github.com/ExpansionPak/RecompCore) | Dolphin-derived static-recompilation runtime, including GXRuntime |
| [Dolphin Emulator contributors](https://github.com/dolphin-emu/dolphin) | GameCube hardware, graphics, audio, memory, timing, and input implementation |
| [ModernGekko-Template](https://github.com/ExpansionPak/ModernGekko-Template) | Recompilation pipeline and game-port reference |
| [SunPad](https://github.com/chrissotraidis/sunpad) | Apple integration and touch-control foundation |
| [Melee decompilation community](https://github.com/doldecomp/melee) | Revision-aware source, symbols, and research references |
| [m-ex / Akaneia contributors](https://github.com/akaneia/m-ex) | Melee modding and expansion reference |
| [ENet — Lee Salzman and contributors](https://github.com/lsalzman/enet) | Peer transport; MeleePad retains a reviewed startup RTT adjustment |
| [Project Slippi and contributors](https://github.com/project-slippi) | Slippi protocol, matchmaking, rollback, replay support and Rust FFI adapted for native iOS/iPadOS play |

ModernGekko's [upstream credits](https://github.com/ExpansionPak/ModernGekko#credits)
recognize SpecialK / aharonahdoot for RecompCore, the Dolphin team for its
foundation, and Literally God / MrPoloGit for the recompilation template and
macOS support. Its Hall of Fame also credits Literally God / MrPoloGit for Melee.
Original contributor histories and per-file notices remain authoritative.

MeleePad's own work includes UIKit and macOS integration, touch and controller
handling, import/version selection, diagnostics, packaging, and game-specific
runtime integration. A MeleePad bug or modification is not an upstream endorsement.
Slippi support is maintained by MeleePad; it is not an endorsement by Project Slippi.

The retained ARM64 static-recompilation fallback repair was authored by Douglas
Whittingham; see [RecompCore PR #6](https://github.com/ExpansionPak/RecompCore/pull/6).

Dependency verification and migration tooling also reuse work from
[GalaxyPad](https://github.com/chrissotraidis/galaxypad), under its original license.

See [dependency provenance](docs/DEPENDENCIES.md) for upstream bases, local patch
locations, and the distinction between the app repository and dependency forks.
[Third-party notices](THIRD-PARTY-NOTICES.md) supplement, rather than replace,
original license texts and attribution.

## AI assistance

Development has used AI assistance. The maintainer remains responsible for
understanding, reviewing, and validating accepted changes. AI assistance does not
transfer credit from upstream authors or imply their involvement in this port.
Nintendo's game, characters, and trademarks belong to their respective owners.
