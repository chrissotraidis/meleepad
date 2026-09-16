# melee-pc research and Apple performance assessment

September 16, 2026. Consolidated findings after three audit passes.

**No evaluated import has demonstrated a MeleePad performance improvement.**
Keep the current Apple runtime. Do not replace its renderer, copy the file cache,
or enable a math substitution on the strength of this repository alone. An early
vertex-decoding priority recommendation is withdrawn: the deeper audit did not
establish that it addresses the limiting workload or improves frame time.
No melee-pc implementation is imported by this research change.

## Inputs and evidence boundaries

The downloaded repository, including vendored Aurora, was inspected at
[`a64b6ad96c48f72eb26a41ef172581a7b1c2d262`](https://github.com/999sian/melee-pc/tree/a64b6ad96c48f72eb26a41ef172581a7b1c2d262).
The final remote-HEAD check still returned this commit. Aurora records upstream
base `d0c931da2ed3f41d0e42736c2ab52a78c7cf1a9d`; the enclosing commit identifies
the actual modified source assessed. This was targeted inspection of build,
representation, graphics, math, audio, caching and licensing, not every line.

The first two passes inspected MeleePad `5d498004c71923af9f989a751448ed302cf777e2`
with existing local work. The final pass checked main
`c3f3a113d3f2cd45923b66053894985813efa76b` and its clean maintained dependencies.
The four vertex loader/manager files and two Aurora math files recorded in
[final-pass.json](artifacts/melee-pc-assessment-2026-09-16/final-pass.json) are
byte-identical between those inspected trees. That carries those source findings
forward; it does not turn historical performance into current-main measurements.

[Host probe results](artifacts/melee-pc-assessment-2026-09-16/checks.json) and
[second-pass aggregate evidence](artifacts/melee-pc-assessment-2026-09-16/second-pass.json)
retain inputs, results and limitations. Raw game data, modules, saves and device
traces are excluded. There was no whole-game melee-pc run, candidate gameplay
benchmark, or new physical-device comparison. These aggregates document local
research; they are not a standalone reproducible benchmark suite.

## Architecture and Apple portability

melee-pc compiles adapted decompiled C into native game functions. MeleePad
compiles translated PowerPC code and retains guest state and console services.
Direct source can avoid translation-related dispatch and register work, but
that is an architectural hypothesis, not measured Apple superiority. Moving the
game to that model would be a separate engine effort, not a small optimization.

The stock [CMake build](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/CMakeLists.txt#L9)
requires GCC. Apple Clang 21 configuration actually failed at this guard.
A synthetic probe using its real `DiscU32` definition read bytes `12 34 56 78`
as `0x78563412`: Clang ignored `scalar_storage_order`. Removing the guard does
not fix the data model. Android GCC/NDK support does not establish Apple support.

An external-pointer handle table supports some high addresses, but
[archive relocation](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/src/sysdolphin/baselib/archive.c#L13)
still requires a low-address archive and writes 32-bit relocated addresses.
The Apple allocation fallback and platform link rules need separate work.
Aurora does contain a Metal backend; renderer support alone does not supply
Apple-compatible game data, lifecycle, input and audio integration.

[macOS issue 37](https://github.com/999sian/melee-pc/issues/37) describes a
contributor's fork working and a request for a PR. It is a useful lead, not
verification of the stock commit. Feature and roadmap claims in the
[pinned README](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/README.md)
were not independently gameplay-tested here.

## Reuse candidates and reasons not to promote them

| Area | What the audit established | Decision |
| --- | --- | --- |
| Indexed vertex fetch | Aurora uploads source arrays and fetches attributes in shaders. MeleePad's ordinary iOS path uses a portable C++ decoder. | No demonstrated gain; retain current path. |
| Native GX boundary | Native SDK calls can avoid some guest marshalling, but Aurora still processes commands and queues work. | Requires a measured, behavior-preserving experiment. |
| Matrix/vector math | Matrix implementation matches existing vendored code; vector arithmetic can produce different bits. | No new matrix benefit; no blind vector substitution. |
| File cache/prewarming | Real implementation exists, but capacity and callback semantics need work. | Do not import it as an iOS performance fix. |
| Pipeline caching | MeleePad already has caching; first-use stalls in the other project remain unproven in cause. | No evidence for a renderer replacement. |
| Audio | Different software AX processing is not an audio or throughput benchmark. | Profile actual starvation before changing the mixer. |
| Native game execution | Could remove translated execution overhead, at substantial integration cost. | Separate feasibility project, not an accepted speed improvement. |

### Vertex work is not a justified first priority

The iOS software loader already uses compiled typed routines with selected
function-pointer stages; it is not a wholly uncompiled interpreter. A static
specialization proposal must show what additional dispatch or conversion it
removes. Enabling the desktop ARM64 runtime-generated decoder is not an ordinary
iOS solution.

Aurora's [frame-end code](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/extern/aurora/lib/gfx/recording.cpp#L577)
clears cached upload ranges each frame. It does not demonstrate durable
cross-frame vertex residency, and shader fetch moves work onto the GPU.
MeleePad also retains decoded CPU positions for z-freeze, serialized
normal/tangent state, optional CPU culling and skip-index output accounting.
Preserving these semantics requires more than swapping the attribute reader.

Two retained physical iPhone profiles attribute 931/11,774 and 1,257/18,682
sampled video-thread milliseconds to decoding, about **7.91% and 6.73%**.
Generated game stacks dominate the CPU-thread samples. These historical
Time Profiler weights are inclusive, may overlap, and are not end-to-end frame
percentages. They do not establish present device performance or an attainable
FPS increase. See the existing [performance ledger](IPHONE-102-PERFORMANCE-GOAL-LOOP.md).

Fresh Mac attribution used a retained September 10 runner, the same module and
state hashes, and separate copied user directories. Software-decoder samples
appeared only when that path was selected. However, runs covered different
emulated frame windows and had sharply different throttle samples; diagnostic
logging added overhead. **The runs were rejected as performance A/B evidence.**
The aggregate CPU times must not be presented as a speedup. Setup failures and
an observer-triggered wrapper launch were excluded; that later launch replaced
some mutable research scratch logs, not the aggregate evidence or game fixtures.

### Math needs equivalence, not just a successful host compile

The compared Aurora matrix file is byte-identical to MeleePad's existing copy.
Three ARM64 host cases passed identity and exact-alias checks, not PowerPC
accuracy or gameplay checks. In 100,000 deterministic finite-vector cases,
`PSVECSquareMag` differed bitwise 10,636 times. One result was `0x431724f6`
versus `0x431724f7`; explicit fused arithmetic changes rounding. No PowerPC
oracle was used, so neither implementation is declared correct from this test.
There was no speed measurement or proof that replacing this host helper changes
the active translated-game path. Netplay and replay behavior raise the acceptance
bar for any change in floating-point results.

### Cache and transition claims need qualification

A probe of the actual file-cache implementation configured a 1 MiB budget and
inserted a 2 MiB object; reported usage became 2 MiB. Pinned entries bypass
eviction, the default can be 512 MiB on machines reporting over 4 GiB RAM, and
background prefetch and copies need memory-pressure/lifetime scrutiny on iOS.
The copy interface also has no destination-capacity argument. This is not an
accepted mobile memory policy.

The final pass checked two more concrete details. In
[lbfile.c](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/src/melee/lb/lbfile.c#L140),
a cache hit copies into the destination and invokes completion immediately,
instead of the normal device-request route. It is not universally zero-copy;
callback timing and reentrancy must remain correct. In
[lbbgflash.c](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/src/melee/lb/lbbgflash.c#L419),
optional `MELEE_FAST_LOAD`/`MELEE_FAST_FADES` settings shorten long fades to six
frames. That changes transition duration, not execution throughput, and is not
the default. Commit descriptions claiming instant loads are not measurements.
[Issue 46](https://github.com/999sian/melee-pc/issues/46) reports first-use freezes;
the suspected shader cause is not established by that report.

## Source reuse and compatibility

The repository's [license statement](https://github.com/999sian/melee-pc/blob/a64b6ad96c48f72eb26a41ef172581a7b1c2d262/LICENSE.md)
distinguishes unlicensed game/decompilation portions from GPL-3.0-or-later PC
code and MIT Aurora portions. Attribution alone is not permission to reuse
unlicensed code. Before any import, identify the exact files, applicable license
and downstream obligations; this assessment is not legal clearance.

Slippi work depends on guest addresses, injected PowerPC behavior and snapshots.
Native objects cannot automatically substitute for that memory layout. Replacing
the game engine would require separate compatibility work and acceptance.

## MeleePad updates use committed sources, not patch replay

Main already merged the migration in
[PR #10](https://github.com/chrissotraidis/meleepad/pull/10). The final audit
verified clean pinned sources and the dependency checker's 11 mutation tests.
The selected revisions are ModernGekko `052e56e2`, RecompCore `2d352bed`,
DolRecomp `7a184251` and ENet `7471be40`; full hashes and URLs are in the
[dependency lock](../config/dependencies.lock.json).

Normal bootstrap initializes those gitlinks and checks source integrity. The
bootstrap, build, preparation, packaging and CI entry points inspected do not
replay the historical patch archive. Some legacy tests still inspect archived
patch text; those are provenance/source-contract checks, not build-time source
updates. See [dependency maintenance](DEPENDENCIES.md) for the update procedure.

The original local research branch predates this migration and still contains
patch-based tooling and unrelated uncommitted work. It was preserved. This
publication was prepared from a clean main-based worktree so it cannot restore
that older bootstrap. No dependency pin or production runtime code changes are
part of this document.

## Acceptance before any future optimization

First profile the current linked build on the affected platform and identify
its limiting work. Use a bounded candidate behind a switch, with the same
compiler, module, scene, inputs, resolution and settings as its control. Compare
repeated matched frame windows, including tail frame time, audio starvation,
memory and thermal behavior. Run relevant rendering/state/rollback equivalence
checks. A Mac result alone cannot accept an iPhone change, and a helper
microbenchmark cannot establish a gameplay improvement. Until those gates pass,
these ideas remain research hypotheses rather than recommended imports.
