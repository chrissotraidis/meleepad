# Desktop reference test route

This route tests MeleePad against the desktop Slippi engine without requiring a
second production account. It is not a replacement for eventual public-service
Direct acceptance.

## Reference build

Use a fresh ignored checkout of `project-slippi/Ishiiruka` at
`e7711b104b339a99385f2bb12b472d46140a7bc7` (v3.6.4). Initialize only
`Externals/SlippiRustExtensions` and `Externals/corrosion` at their recorded
submodule revisions. Apply `patches/slippi/reference-lab-build.patch` with
`git apply --check` first. The patch names the executable `SlippiReferenceLab`
and fixes missing declarations exposed with precompiled headers disabled.

The tested configuration uses a project-local CMake 3.31.10 installation,
Ninja, the current Xcode SDK, and Rust 1.88.0 with the x86_64-apple-darwin target.
Pass these CMake settings, supplying explicit absolute Rust compiler/Cargo paths:

```text
-G Ninja
-DCMAKE_OSX_ARCHITECTURES=x86_64
-DRust_CARGO_TARGET=x86_64-apple-darwin
-DRust_COMPILER=<Rust 1.88.0 rustc>
-DRust_CARGO=<Rust 1.88.0 cargo>
-DCMAKE_BUILD_TYPE=Release
-DENABLE_LTO=OFF
-DENABLE_PCH=OFF
-DENABLE_AO=OFF
-DAO_FOUND=0
-DSKIP_POSTPROCESS_BUNDLE=ON
-DENABLE_ANALYTICS=OFF
-DFASTLOG=ON
```

Build target `SlippiReferenceLab`. No install target is needed. Do not launch
this initial build with a test matchmaker: it still contains upstream account
paths and public endpoints. Source and compilation are the first gate only.

The x86_64 reference has built and linked successfully. See [build evidence](artifacts/slippi-feasibility-2026-09-10/reference-lab-build.json). That initial artifact was not launched. A subsequently isolated build has now paired and played against the native runtime; see the evidence below.

## Isolation and interoperability gates

1. Give the reference an explicit separate account path. macOS Slippi resolves
   its account independently of `-u`, so that argument alone is insufficient.
2. Restrict the test process to the explicit local fixture and peer addresses;
   route matchmaking to the fixture and verify denied external destinations.
3. Use only the fixture's two synthetic identities. The fixture must reject
   unexpected identities and must never receive a real play key.
4. Keep desktop execution, peer packets, rollback, and game codes intact.
   Record any additional instrumentation separately from build fixes.
5. Play a full reference/native game and rematch. Compare finalized player,
   RNG, and item packets, including delayed-input rollback. First establish a
   desktop/native baseline, then repeat with the physical iPad.
6. Retain mismatches and capture failures. A pass covers the instrumented
   reference and exact configurations; public service acceptance remains open.

The official [matchmaking source](https://github.com/project-slippi/Ishiiruka/blob/e7711b104b339a99385f2bb12b472d46140a7bc7/Source/Core/Core/Slippi/SlippiMatchmaking.cpp)
shows the matchmaking introduction separately from the peer connection.

## Comparing desktop recordings

`python3 scripts/extract-slippi-reference-trace.py <closed.slp> <new-output>`
extracts raw state packets using the pinned desktop writer format. The output
can feed `scripts/analyze-slippi-local-game.py` alongside the native trace.
Use its rollback-aware mode for timelines containing revisions. Review its
scope labels: the existing analyzer was originally written for local peers;
its output alone must not be relabeled public crossplay acceptance.

The extractor excludes metadata and game-start identity fields. It rejects
unclosed/truncated streams, malformed command tables, wrong state-event sizes,
and incomplete game boundaries. Seven synthetic parser tests pass. The automated reference/native run now provides both streams from the same local match. Strict agreement remains blocked by item differences.

## Automated Mac-only baseline

Apply `patches/slippi/reference-lab-isolation.patch` after the build patch and
rebuild the laboratory target. `scripts/run-slippi-reference-lab.py` creates a
fresh private test directory, copies Sys resources, signs the laboratory copy,
and verifies its loopback/account-directory sandbox before launch. Its
libmelee 0.47.3 controller uses pipe input and spectator frame updates. Only the
menu observer is added; the three required gameplay groups match the native
diagnostic configuration. Full recommended-code parity remains a separate gate.

[Automated comparison](artifacts/slippi-feasibility-2026-09-10/reference-automated-match.json)
records 1,462 finalized frames, including 18 desktop rollback events. Every
player and RNG packet matched. The raw comparison failed on item data, including
a one-ULP encoded-float difference in packet lane `0x18`; the exact game-object
meaning of that lane remains unproven. This is a compatibility blocker, not a
passing crossplay result. The bounded native run ended the session before a
full match or rematch. No public service or hardware was used. The multiplicity-
preserving detail is in the [item trace analysis](artifacts/slippi-feasibility-2026-09-10/reference-item-trace.json).

The native guest-context capture then ran two assigned no-JIT peers through the
loopback fixture. At the callback boundary, the saved registers were callback
state (`r28=1`, `r4/r30=0x80bee680`), not the `SendGameInfo` item-object
context. An exact scan of the pinned packet-field tuple across direct MEM1 and
valid D-cache lines found zero candidates for all 420 captured item events on
both clients. This rules out treating the post-DMA callback state as the
packet source; it does not prove that the object is absent. The redacted
[capture artifact](artifacts/slippi-feasibility-2026-09-10/native-guest-item-context.json)
records the result. The next diagnostic must instrument a matching, same-length
native `SendGameInfo` module at the guest instruction boundary before another
cross-engine comparison is attempted.
