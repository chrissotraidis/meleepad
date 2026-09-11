# Slippi compatibility implementation loop

Started: 2026-09-10. Current phase: native main-app online acceptance. S1 passed; the required native offline subset passes; the iPhoneOS app target now links and has launched on the physical iPad. Native v1.02 boot/render, Slippi module selection, and the private account-to-runtime handoff are proven on the iPad; service matchmaking, full-code parity, rollback gameplay, rematch/disconnect, and crossplay remain open. The active goal tool objective owns this loop; this log records the evidence checkpoint.

## Objective and priority

Make MeleePad launch into the intended two-pane product: the original Melee
experience on the left and a native Slippi multiplayer experience on the right.
The right pane must drive the same no-JIT iOS runtime as the shipped app and
must reach a real Slippi online match, not the existing fixed-delay netplay
fixture. The left pane must remain a working standalone Melee path.

Prioritize this compatibility and product-integration work over deploying Pad
Lobby or adding other extensions. Other agents' extension and performance work
remains independently owned; do not overwrite their changes or reuse a
mutating build directory.

The owner authorized an implementation and testing loop. Work autonomously on
offline integration before account or opponent availability. A compile pass,
synthetic component test, service login or room connection cannot close the
gameplay gate.

The intended launch surface has two explicit panes/cards: **Play Melee** on the
left and **Play Slippi** on the right. Each player must supply their own
account. The [network/identity audit](SLIPPI-NETWORK-IDENTITY-AUDIT.md) tracks
this release gate, including packaging checks, iOS login, credential transport
and session ownership. Target Direct, then Unranked; a live player browser is
not an established upstream capability.

The product surface cannot be accepted if its Online Play control still routes
to the old fixed-delay `NetplaySession`, if the Slippi runtime exists only in a
separate probe executable, or if either pane is decorative. The two-pane UI and
the native Slippi host are one integration gate.

## Current priority: native runtime plus main-app integration

Earlier validation in this checkpoint was Mac/Simulator-only; the latest
iteration also installed the final private QA bundle on the physical iPad. The
isolated, source-built desktop Ishiiruka reference
now pairs with the native no-JIT runtime through a synthetic loopback fixture.
An automated frame-driven controller reaches gameplay without manual menu
input.

The required three-group native Slippi subset now passes a fresh no-JIT boot
(`boot-native-required-017`: 118 frames, zero memory/graphics errors, native
EXI commands observed). The remaining offline code-set failure is narrower:
adding **Normal Lag Reduction** still exits after two frames with 84 invalid
memory reads. A private native module rebuilt with the two exact lag-reduction
branch replacements baked into its DOL produced the same failure, so the
problem is not just runtime replacement of those two instructions. The
shipping app therefore remains explicitly constrained to the three proven
required groups while full-code compatibility stays open. The earlier
`rfi`/context-save trace is not the current root cause of this subset failure.

The first app-integration pass is now in the main target: the home screen has
separate Original Melee and Slippi Multiplayer cards; device builds link the
native Slippi sources; the device-only host imports a normalized account into
Keychain, starts Slippi on the app's existing Metal layer, and forwards the
merged controller state. Simulator retains the old fixed-delay route only as a
regression stub. A signed Release build has now launched on the physical iPad,
visibly rendered both cards, selected the separate Slippi module, and completed
the private account-to-runtime handoff with the temporary plaintext copies
removed. Standard desktop Direct, complete match/rematch and public service
acceptance remain required.

## Pinned starting point

- Modern Slippi: `41a7a3a110ed52999486ae1901c8fbb9a63d4f13`.
- Desktop release reference: Ishiiruka v3.6.4,
  `e7711b104b339a99385f2bb12b472d46140a7bc7`.
- Rust extensions: `2d29e794de8497582675fb70877851f2cdd2f256`.
- Melee target: owner-supplied NTSC v1.02.
- Retain experimental sources/builds under ignored `ref/slippi-compatibility/`.
  Keep reproducible adapters, test harnesses and redacted evidence in tracked
  source. Never commit game resources, generated game code or credentials.

See the [assessment](SLIPPI-PRIORITY-ASSESSMENT-2026-09-10.md) for sources and
the exact limits of existing compiler and snapshot evidence.

## Ordered acceptance gates

| Gate | Required evidence | Current result |
|---|---|---|
| S1: host components | Reproducible build of required Slippi components against the current runtime; execute snapshot and local peer-input transport tests | Passed at component scope: full C++ Slippi EXI device and dependencies compile for macOS/iOS, link and execute on macOS; snapshot, peer input and resource probes pass |
| S2: game integration | Actual Slippi boot, resources and EXI commands; full required injected-code dispatch with no JIT; account-free local game setup | Required groups run an offline match through Metal, including movement, attacks and Slippi frame/item events. Compiled patched text and GCT execute with strict fallback. Full default codes still fail; not all code paths or a complete match/rematch are accepted. Actual game restoration and controlled delayed-input resimulation now pass |
| S3: rollback correctness | Same initial match and authoritative inputs, injected 1/3/7-frame input delays; finalized state agrees with on-time baseline at canonical game boundaries; no suppressed mismatch | Partial pass: offline game, 1/3/7-frame wrong predictions corrected from one captured state; 717 exact player/RNG/item packet comparisons on macOS and 786 on iPad, zero mismatches. Actual local online rollback now corrects changed predictions with up to 3- and 7-frame rewinds under 120/200 ms PAD delays; 4,985/4,994 finalized player/RNG/item packets agree between clients. The physical LAN pair also agrees on 4,875 packets with changed predictions and up to six-frame iPad rewinds. Same-input online on-time baseline and desktop agreement remain open |
| S4: desktop compatibility | Arranged Direct game against a standard pinned desktop Slippi build, full match/results/rematches, clean disconnect/reconnect | Partial diagnostic: source-built, isolated Ishiiruka reference pairs and plays against native no-JIT runtime. Player/RNG packets match through observed desktop rollback; item packet state diverges. Main iOS target now links the native host and has passed signed physical boot/account handoff, but no standard service Direct match is accepted |
| S5: iPad acceptance | Repeat S3/S4 on physical iPad with sustained simulation/frame timing, rollback cost, audio and thermal measurements | Separate Slippi probe evidence covers physical offline/local online corrections and a longer CoreAudio run matching 11,217 packets at 59.74 game frames/s with zero measured-window DMA underruns. The main MeleePad app now passes signed install, physical module selection, account handoff, and clean bounded native shutdown; no menu-driven match has run. Audible quality, pause/rule behavior, sustained full matches/rematches and standard desktop crossplay remain open |
| S6: existing player discovery | Normal account integration and an actual Unranked game after Direct is stable | Not tested |

S1 and S2 may advance by independently testable components. S3 must exercise
actual game simulation: restoring arbitrary RAM is not a substitute. S4 needs
normal user account access and a willing arranged opponent; do not impersonate
official support, bypass service checks or send unsolicited outreach. S5 may
start with offline measurements before an Internet opponent is available.

## Loop procedure

1. Read this checkpoint and inspect current source/build state.
2. Select the earliest unresolved gate and one executable hypothesis.
3. Implement the smallest adapter that preserves upstream semantics. Keep
   existing Private Room behavior and normal app builds working.
4. Run the bounded test and capture exact revisions, adaptations, result and
   limitations. Failure should identify the next change, not restart research.
5. Update this checkpoint and continue with the next concrete blocker. Avoid
   repeating passed checks without a relevant source or environment change.

Do not bypass static-code verification, silently switch to JIT, ignore real
desyncs, fake account acceptance or claim desktop compilation as iPad proof.
Use a separate test user directory; preserve installed app data during any
eventual device upgrade.

## Completion and negative outcomes

A positive feasibility determination requires correct actual rollback plus a
physical-iPad match against standard desktop Slippi at acceptable sustained
speed. Broad Unranked claims additionally require S6. Document tested hardware
and network limits rather than generalizing to every iPhone/iPad.

A negative determination must identify a reproduced incompatibility or measured
performance failure and the attempted practical remedies. A missing adapter,
unfinished implementation or unavailable opponent is an open gate, not proof of
impossibility. Keep the active goal open while independent progress remains.

## Current checkpoint

Initial component proof: four representative PPC hooks compile to iOS ARM64; adapted
Slippi snapshot and input-packet components compile for macOS and iOS; snapshot
capture/restore executes against actual MeleePad Dolphin memory in 100 synthetic
cycles with 500 checks and no failures. No Slippi game had executed at that
checkpoint. Iteration 4 below now executes the bootloader and required game
codes, with a reproduced failure in the full default code set.

Iteration 1 adds a reproducible peer-input adapter and executable test. Three
fresh two-process macOS connections each exchange 300 frames per endpoint:
1,800 received input frames total, zero input/checksum/player-index mismatches,
and all six endpoint runs pass disconnect handling. Each run includes three
50 ms send stalls. These are synthetic input transport checks, not delayed-input
game resimulation. The receiving endpoint also verifies the transmitted
intentional-disconnect reason. Processes exit normally and a subsequent fresh
connection succeeds; in-game rematching is not tested.

SlippiNetplay, SlippiPad and SlippiGame compile for both macOS and iPhoneOS. Only
macOS code executes. The probe links existing MeleePad libraries and records the
core archive hash; it does not rebuild or mutate the shared runtime. The adapter
uses the seven pinned Slippi packet IDs in a separate namespace, removes the
obsolete shared ENet-host ownership cleanup, adapts UTF conversion through the
current API and binds only loopback. Log-category aliases are confined to the
probe compilation; no logger/account data is initialized. This patch is test
infrastructure, not a production network adapter.

Reproduce with existing tools/iPhoneOS build dependencies and the pinned modern
Slippi source tree:

```sh
python3 scripts/probe-slippi-peer.py \
  --upstream ref/slippi-compatibility/upstream \
  --build ref/ModernGekko/build-desktop-tools-meleepad-netplay \
  --ios-build ref/ModernGekko/build-ios-iphoneos-meleepad-static \
  --output ref/slippi-compatibility/peer-probe-new
```

The runner checks pinned input hashes, applies the isolated patch, compiles,
links, runs three bounded connection cycles and writes `results.json`. Its
output must be a new directory. [Retained result](artifacts/slippi-feasibility-2026-09-10/peer-transport.json).

## Iteration 2: resource loading and Rust FFI

The resource loader now compiles and executes against the current Dolphin disc
implementation. The isolated adapter rebuilds DVDThread with the required
CPU-thread file-read method and links that object ahead of the existing core
archive. It does not replace the shared build's archive. The resource root is
an optional constructor argument, so tests need no global bundle-path override;
the default remains Dolphin's system directory.

The loader requires a valid base disc file and successful VCDIFF decode before
returning patched content. Missing discs/files and malformed deltas return an
empty failure without caching delta bytes as valid resources. The adapter
permits reads whenever a disc is inserted, including paused states. Failed
base reads can be retried after inserting the disc.

A synthetic directory-backed GameCube volume exercised the actual disc reader,
standalone resources, cache behavior, delta reconstruction, stadium-resource
preload and failure paths: **11 checks, zero failures**. The malformed-delta
case intentionally emits the VCDIFF decoder's error. Both the loader/disc
objects and the VCDIFF libraries build for macOS and iOS; execution is macOS
only. No retail game data or Slippi game-resource binary was loaded.

```sh
python3 scripts/probe-slippi-resources.py \
  --upstream ref/slippi-compatibility/upstream \
  --build ref/ModernGekko/build-desktop-tools-meleepad-netplay \
  --ios-build ref/ModernGekko/build-ios-iphoneos-meleepad-static \
  --output ref/slippi-compatibility/resource-probe-new
```

[Resource results](artifacts/slippi-feasibility-2026-09-10/resource-loader.json).
The input lock verifies current core sources as well as upstream loader and
dependency sources. An initial exploratory compilation accidentally found the
donor DVD header through a broad include path; that was not accepted as current
core integration evidence. The reproducible test uses only the explicit
current-core overlay and upstream external dependency include path.

The pinned Rust FFI crate builds with `mainline` enabled, default `ishiiruka`
disabled, and its library type changed from `cdylib` to `staticlib`. Both macOS
and iOS archives were produced and sampled platform load commands inspected.
Sampling did not establish archive-wide deployment compatibility: later full
links exposed newer-target native objects in both initial archives. See
Iterations 3 and 9 for the corrected builds.
The only Rust source-tree edit is the
[crate-type patch](../patches/slippi/0003-rust-static-library.patch).

The macOS archive was linked into the
[C++ lifecycle harness](../scripts/slippi-rust-lifecycle-probe.cpp). Under an OS
sandbox denying all network access, three fresh Rust device instances created,
returned anonymous user state, transferred/freed user-info ownership across
FFI, and destroyed successfully. Each used a new empty test directory and a
nonexistent test ISO path. This proves linkage/lifecycle only; it does not test
authentication, a real ISO, audio playback, reporting or gameplay. Rust's DMA
methods are placeholders; the actual Slippi game command handling remains in
the C++ EXI device. Iteration 3 below integrates and tests that device.

[Rust build and lifecycle results](artifacts/slippi-feasibility-2026-09-10/rust-bridge.json).
Build commands, from the repository root after applying the patch to the pinned
Rust checkout (the target directories must remain ignored):

```sh
CARGO_PROFILE_RELEASE_DEBUG=0 CARGO_TARGET_DIR="$PWD/ref/slippi-compatibility/rust-build" \
  cargo build --manifest-path ref/slippi-compatibility/rust/Cargo.toml \
  --locked --release --no-default-features --features mainline -j 4

RUSTC="$(rustup which rustc)" CARGO_PROFILE_RELEASE_DEBUG=0 \
  CARGO_TARGET_DIR="$PWD/ref/slippi-compatibility/rust-build-ios" \
  rustup run stable cargo build --manifest-path ref/slippi-compatibility/rust/Cargo.toml \
  --locked --release --no-default-features --features mainline \
  --target aarch64-apple-ios -j 4
```

The first iOS attempt selected Homebrew's rustc rather than the rustup compiler
with the installed iOS standard library. Explicitly selecting that compiler
resolved it. This was a toolchain-selection failure, not a Slippi incompatibility.
The actual compiler versions and archive hashes are recorded in the evidence.

The executed lifecycle harness was built and run with:

```sh
xcrun clang++ -std=c++20 -arch arm64 -mmacosx-version-min=14.0 \
  -Iref/slippi-compatibility/rust/ffi/includes scripts/slippi-rust-lifecycle-probe.cpp \
  ref/slippi-compatibility/rust-build/release/libslippi_rust_extensions.a \
  -framework CoreFoundation -framework Security -framework AudioToolbox \
  -framework CoreAudio -framework Foundation -framework AudioUnit \
  -framework SystemConfiguration -lresolv -liconv \
  -o ref/slippi-compatibility/rust-lifecycle-probe
sandbox-exec -p '(version 1) (allow default) (deny network*)' \
  ref/slippi-compatibility/rust-lifecycle-probe \
  ref/slippi-compatibility/rust-lifecycle-fixture-new
```

The fixture path must not already exist. These commands must not be substituted
with a real user's Slippi configuration directory.

## Iteration 3: full C++ EXI dispatch

The isolated full device now links with the current MeleePad core and pinned
Rust library. The macOS executable passes **10 checks, zero failures** under an
OS sandbox denying network access: device presence, delay marker/value,
anonymous user status, synthetic resource size/content, Gecko code length/data,
and the disconnected-input response. Construction and shutdown complete.
No instruction from the synthetic Gecko code or a game is executed.

The reproducible runner compiles 17 runtime translation units plus the three
semver units for each of macOS and iOS, and a macOS harness (41 units total).
VCDIFF libraries also build for both platforms. iOS linking, execution, device
factory registration and game boot are not covered. Existing Dolphin library
hashes remain unchanged. [Results](artifacts/slippi-feasibility-2026-09-10/exi-dispatch.json).

The [full adapter](../patches/slippi/0004-isolated-full-exi.patch) includes the
earlier peer/resource changes and adapts config, memory access, replay-state
interfaces, text conversion, typed OSD messages and Gecko serialization.
Its [source lock](../patches/slippi/exi-source-lock.json) checks inputs and the
resulting overlay. It retains the test-only loopback transport restriction and
uses an explicit development version, with no service-compatibility claim.

Two harness failures were resolved: writing a nonexistent Base settings layer
caused a pre-construction crash; using CurrentRun settings fixed it. The first
delay assertion read the response marker as the value; checking both bytes
separately fixed the assertion. The runtime handler was correct.

The earlier Homebrew Rust archive contained native/standard-library objects
requiring macOS 26 or 26.5. Inspecting its first object had missed this. It is
superseded for macOS 14 compatibility by this build, whose full EXI link has no
newer-target warnings:

```sh
RUSTC="$(rustup which --toolchain stable rustc)" MACOSX_DEPLOYMENT_TARGET=14.0 \
  CARGO_PROFILE_RELEASE_DEBUG=0 \
  CARGO_TARGET_DIR="$PWD/ref/slippi-compatibility/rust-build-macos-stable" \
  rustup run stable cargo build --manifest-path ref/slippi-compatibility/rust/Cargo.toml \
  --locked --release --no-default-features --features mainline -j 4

python3 scripts/probe-slippi-exi.py \
  --upstream ref/slippi-compatibility/upstream \
  --rust ref/slippi-compatibility/rust \
  --rust-macos-archive ref/slippi-compatibility/rust-build-macos-stable/release/libslippi_rust_extensions.a \
  --build ref/ModernGekko/build-desktop-tools-meleepad-netplay \
  --ios-build ref/ModernGekko/build-ios-iphoneos-meleepad-static \
  --output ref/slippi-compatibility/exi-probe-new
```

The compiler used was Rust 1.96.0. The runner records the supplied archive's
hash; it does not rebuild Rust or establish the archive's provenance by itself.
The earlier iOS Rust archive is not yet validated by a complete iOS link.

## Iteration 4: actual game boot and failure isolation

The [boot adapter](../patches/slippi/0005-isolated-game-boot.patch) registers the
real Slippi device in slot B in an isolated executable and installs the pinned
Gecko heap bootloader. It uses an experimental, nonpersisted EXI device value
without changing existing enum values or factory signatures. The boot context
and command counters are test-only globals; this is not the final app API.

The probe loads the owner's GALE01 revision 2 ISO and native module, with
`STATICRECOMP_NO_FALLBACK_JIT=1`. The ISO's DOL matches the extracted DOL and
module input hash. It uses a fresh user directory, a separate resource bundle,
no memory cards, no account, and an OS sandbox denying network access. Rust
jukebox, spectator service and replay saving are disabled. The pinned game
resources and game-code bytes remain ignored local artifacts, not repository
content.

The game executes the bootloader, requests GCT size/data over actual emulated
EXI, and loads `MxScn.dat`. The required three-group configuration now reaches
118 frames with no memory or graphics errors under the rebuilt native module.
The full six-group/default configuration, and the narrower required-plus-Normal
Lag Reduction configuration, still stop after two frames because the selected
Normal Lag Reduction code is not represented in the captured native GCT
snapshot. Clean process shutdown did not mean successful game startup; the
harness checks memory errors and continued frame advancement during the last
five seconds of its 20-second window.

The controls narrow the failure:

| Configuration | Observed result |
|---|---|
| Vanilla, native module | 1,195 frames, no memory errors |
| Vanilla, interpreter | 106 frames; slow but continuously advancing |
| General codes only | 1,007 frames, no memory errors |
| General + Recording | 1,012 frames, no memory errors |
| All three required groups | 118 frames in the fresh native run, no memory/graphics errors; Slippi EXI commands execute |
| Required + Normal Lag Reduction | Two frames, invalid memory accesses, halt |
| Required + Apply Delay to all In-Game Scenes | 107 frames, continued progress, no memory errors |
| Required + Lagless FoD | 107 frames, continued progress, no memory errors |

These are headless controls. Several independent cases ran concurrently, so the
counts are **not a device or gameplay performance benchmark**. Diagnostic
subsets do not establish compatibility with standard Slippi. They show that
the current boot failure can be reproduced by adding Normal Lag Reduction.
They do not prove that the original upstream patch is defective.
[Exploratory evidence](artifacts/slippi-feasibility-2026-09-10/boot-isolation.json).

The reproducible runner then built a new executable and ran scheduling controls
sequentially. Required groups advanced with no memory errors, including the
fresh `boot-native-required-017` result. Both single-core operation and
disabling GPU fake completion still failed at two frames with all six groups
enabled. The probe confirmed the selected settings while running. Core-library
and game-input hashes remained unchanged.
[Reproducible results](artifacts/slippi-feasibility-2026-09-10/boot-scheduling-controls.json).

The working required-group run still recorded 611,462,708 interpreter steps and
25 code chunks rejected because Slippi modified their instructions. Rejection
and fallback are expected safeguards; they were not disabled. Native dispatch
counts and interpreter instruction counts are different units and should not
be converted into a percentage. This identifies the next performance task:
compile and verify the injected code and modified game blocks before judging
whether rollback can run fast enough on iPad.

Reproduce with the passing EXI probe and the owner's existing game/module paths:

```sh
python3 scripts/probe-slippi-boot.py \
  --component-probe ref/slippi-compatibility/exi-probe-001 \
  --upstream ref/slippi-compatibility/upstream \
  --rust ref/slippi-compatibility/rust \
  --rust-macos-archive ref/slippi-compatibility/rust-build-macos-stable/release/libslippi_rust_extensions.a \
  --build ref/ModernGekko/build-desktop-tools-meleepad-netplay \
  --game /path/to/owner-extracted-v1.02 \
  --iso /path/to/owner-v1.02.iso \
  --module /path/to/owner-v1.02-native-module.dylib \
  --output ref/slippi-compatibility/boot-probe-new \
  --modes required full-single-core full-gpu-sync-off
```

Expected current runner exit is nonzero because the full-code controls still
fail; the required-group case is the accepted native baseline.
`results.json` records all completed cases and exact input/library hashes.
The current runtime wrapper and StaticRecomp settings definitions are compiled
ahead of the existing libraries because the shared build predates the newly
added secondary-idle setting. This candidate does not establish acceptance of
the latest complete application build.

Next: keep the required groups as the offline execution baseline while making a
deliberate decision about Normal Lag Reduction: compile/capture its native
region if it is required for parity, or keep it out of the shipping subset and
record that compatibility boundary. In parallel, integrate the separate Direct
host into the main iOS target and replace the fixed-delay Online Play route.
The fresh private Direct candidate is linked but unsigned, uninstalled and
untested against the service. No desktop opponent has connected.

## Iteration 5: compile the live modifications

An offline required-code boot captured the owner's 24 MiB emulated RAM while
the CPU was paused, together with 1,997 sampled program counters. The capture
advanced 152 frames without memory errors, but frequent sampling perturbs
timing. Comparing original text with live memory found 239 changed instruction
words across 67 existing 16 KiB chunks. Only visited chunks contribute to the
runtime's failed-chunk counter. [Capture metadata](artifacts/slippi-feasibility-2026-09-10/native-capture.json).

The new [diagnostic module builder](../scripts/build-slippi-snapshot-module.py)
substitutes those captured text bytes into a private code-generation fixture.
It leaves original data sections intact. The game still boots the original
ISO; the generated module must pass normal live instruction verification.
Neither the original DOL nor the normal application module is overwritten.
Generated game code, memory captures and modules remain ignored local files.

The resulting macOS ARM64 module executes successfully with the three required
code groups. A sequential comparison using the exact same probe executable,
Null graphics, software vertex loading, a fresh user directory per run and
network access denied produced:

| Module | Final startup frames | Memory errors | Failed chunks at shutdown |
|---|---:|---:|---:|
| Original v1.02 native module | 131 | 0 | 25 |
| Native module compiled from captured patched text | 1,044 | 0 | 0 |

Both ran for 20 nominal observer intervals and continued advancing late in the
run. Seven early mismatches in the patched module were reverified before
shutdown; verification was not bypassed. The patched run still performed
281,225,409 interpreter steps, including heap-injected code outside its compiled
text regions. These counts establish improved native startup execution, **not
an eightfold gameplay speedup, 60 FPS gameplay or rollback acceptance**.
[Exact build and execution evidence](artifacts/slippi-feasibility-2026-09-10/native-text-execution.json).

The same patched-text module also completes required-code startup with Metal
selected, 1,043 final frames and no memory errors. A subsequent reproducible
run with a renderer screenshot verifies the actual in-game Slippi **Online
Play → Log-in** menu, including the prompt “Access instructions to log-in.”
That run advances 513 frames with zero memory errors and no failed chunks at
shutdown. It ran concurrently with a module LTO build and is not a performance
measurement. Menu input, login and gameplay remain untested. The screenshot
stays in the ignored local test directory.
[Rendered-menu evidence](artifacts/slippi-feasibility-2026-09-10/boot-metal-menu.json).

The full six-group configuration still fails with Metal: guest
instruction exception at `0x01fe01fe`, then an unknown instruction at PC
`0x00000400` and host SIGTRAP. This rules out a failure confined to Null
rendering; it does not establish the cause of the lag-reduction incompatibility.
[Full-code Metal failure](artifacts/slippi-feasibility-2026-09-10/boot-metal-full.json).

These newer execution probes explicitly disable both CPU fallback JIT and the
vertex-loader JIT. Earlier probes explicitly disabled CPU JIT only; their
headless scope should not be described as a fully verified iOS execution path.

The next build additionally compiled the captured 56,720-byte GCT region at
`0x8065cc80`. It includes relocated C2 hooks and mutable metadata. Execution
still completes 1,044 frames with zero memory errors, but all four added GCT
chunks fail strict verification and use interpreter fallback. The fallback
count remains essentially unchanged at 281,288,322 steps. This first test has
not improved performance. A second RAM capture, however, finds **zero changed
GCT words** versus the original capture, and all four final RAM hashes match
the generated module. This points to cached failures from an earlier loading
or relocation phase rather than proving ongoing mutations.
[Build and execution evidence](artifacts/slippi-feasibility-2026-09-10/native-gct-execution.json).

The `--reverify-gct` diagnostic then requested normal instruction-cache
invalidation at second five. This run advances 1,160 frames with zero memory
errors, reduces interpreter fallback to 66,246,154 steps and ends with no failed
chunks. After the invalidation it advances approximately 60 menu frames per
nominal observer second on this Mac. This is not match or iPad performance.
Invalidation resets cached verdicts; it does not set expected hashes or mark
code valid. Cold chunks may remain unverified until next visited, so a zero
failed counter alone does not prove every GCT chunk executed.
[Reverification evidence](artifacts/slippi-feasibility-2026-09-10/gct-reverification.json).

Source inspection identifies a concrete integration lead: the existing Gecko
HLE workaround calls `InstructionCache::Reset`, which calls
`JitInterface::ClearSafe`, which calls the block cache's `Clear`. StaticRecomp's
`EmptyBlockCache` forwards range invalidation to the chunk verifier but inherits
`Clear` without resetting that verifier. `StaticRecompCore::ClearCache` does
reset it, but this path does not call that method. Next: test an isolated fix
that propagates this existing cache-clear event into the verifier. Retest
without the timer before considering it an integration fix.

The captured
address is a diagnostic fixture, not a portable relocation solution. Other
loaded resource code is not yet compiled by this experiment. Actual rollback,
physical iPad execution and desktop Slippi interoperability remain open gates.

```sh
python3 scripts/build-slippi-snapshot-module.py \
  --capture-run ref/slippi-compatibility/boot-capture-001 \
  --dol /path/to/owner-extracted-v1.02/sys/main.dol \
  --compiler ref/ModernGekko/build-desktop-tools-meleepad-netplay/dolrecomp \
  --core ref/ModernGekko \
  --output ref/slippi-compatibility/native-module-new \
  --include-gct \
  --ini ref/slippi-compatibility/upstream/Data/Sys/GameSettings/GALE01r2.ini
```

The capture must originate from a successful `--capture --modes required` boot
probe using the audited original DOL. Omit `--include-gct` and `--ini` to build
only the modified original text. Build results deliberately report execution
as untested; a separate boot test is required for every new module.

## Iteration 6: automatic invalidation and controller navigation

The [cache-clear adapter](../patches/slippi/0006-isolated-cache-clear.patch)
forwards StaticRecomp's existing block-cache `Clear` event through its virtual
range invalidation method. It changes no class layout or expected instruction
hash. This partial fix resets stale verdicts, but three GCT chunks still fail
after later code-handler writes. Required-code startup advances 1,023 frames;
the full six-group configuration still fails at two frames with memory errors.
[Results](artifacts/slippi-feasibility-2026-09-10/cache-clear.json).

The [loader adapter](../patches/slippi/0007-isolated-gct-loader-invalidation.patch)
records the actual GCT heap address supplied by the game and validates its size
against GameCube RAM. On return from the Gecko code handler, it invalidates
cached instruction verdicts for that region. This addresses C2 relocation
writes after the earlier global cache flushes. It runs on the actual loader
event, with no fixed heap address or wall-clock trigger. Every native chunk
must still match its compiled byte hash after invalidation.

With both adapters enabled and the diagnostic timer disabled, the compiled
GCT module completes **1,218 frames, zero memory errors**, with **1,989,263
interpreter steps** and no failed chunks remaining at shutdown. The actual
Slippi login menu renders through Metal. Repeated verification is intentional;
the run records 3,885 checks, so its cost remains part of future device timing.
Cold chunks may remain unverified until visited. This is startup/menu evidence,
not actual rollback or gameplay acceptance.
[Loader results](artifacts/slippi-feasibility-2026-09-10/gct-loader-invalidation.json).

A follow-up with all six code groups and both automatic fixes still fails at
two frames with 74 reported memory errors. The loader fix resolves stale native
verification; it does not resolve the Normal Lag Reduction startup failure.

A negative control uses the same executable with the original vanilla module.
It still rejects **25 mismatched chunks** and uses interpreter fallback,
advancing 130 frames without memory errors. Thus the adapters do not make
incorrectly compiled code pass verification. The three changed runtime units
also compile for iPhoneOS ARM64; a full iOS link and physical execution remain
untested. [iOS compile evidence](artifacts/slippi-feasibility-2026-09-10/gct-loader-ios-compile.json).

An ordinary emulated controller B press then leaves Slippi's login screen and
returns to the normal 1-P Mode submenu. A renderer screenshot verifies that
transition. No scene variables, account data or service responses were changed.
The next navigation test uses B, B, stick down, A, A to reach the offline
Versus character-select screen. Its renderer screenshot shows the UCF 0.84
indicator, character roster and P1 cursor. It advances 1,203 frames with no
memory errors and no failed chunks at shutdown. Fighters have not been selected
and a match has not started. This leaves a concrete next step: ordinary
controller selection of fighters and a stage, then actual simulation and
state-restoration testing.
[Input evidence](artifacts/slippi-feasibility-2026-09-10/menu-navigation.json).
[Versus character-select evidence](artifacts/slippi-feasibility-2026-09-10/offline-versus-menu.json).

Use the boot runner with `--cache-clear-fix --gct-loader-invalidation` and the
captured-GCT module for this candidate. Add `--graphics Metal --screenshot`
for visual evidence, and `--menu-back` for the verified B-button test.
`--offline-versus` reproduces the verified path to character select. The runner
refuses to combine either automatic fix with `--reverify-gct`, keeping timer
experiments separate from automatic behavior. Normal app builds, installed
devices and shared core libraries have not been changed.

## Iteration 7: actual offline gameplay

The harness now accepts a bounded controller input file and 20/40/60-second
observer windows. Each row specifies `second port button x y duration_ms`.
It uses ordinary emulated controller input and explicitly attaches only the
ports used by the script. No scene variables, account status or game state are
written to skip menus. Input files are hashed into the evidence. The extended
log checks now count graphics FIFO errors as failures in addition to invalid
memory accesses.

Two initial cursor movements overshot the character roster. One of those runs
continued at character select through the observation window but failed during
shutdown with an auxiliary-FIFO mismatch, invalid GPU commands and SIGTRAP.
It is retained as a failed run, not a successful gameplay test. A shorter stick
movement selected fighters and reached stage select cleanly.
[Selection evidence and failure](artifacts/slippi-feasibility-2026-09-10/fighter-selection.json).

Moving the stage cursor onto a valid tile then started **Luigi versus Pikachu
on Battlefield**. The run completed 1,185 Slippi frame-bookend events and
2,370 post-frame updates, remained alive, and exited cleanly with no reported
memory errors. The screenshot verifies the in-game stage, fighters and timer.
The captured menu-native module still needed interpreter fallback for one GCT
chunk whose bytes changed during gameplay; verification remained active.

The next run added movement and attacks. Its screenshot shows **Mewtwo versus
Pikachu on Battlefield**, with Pikachu at 2% damage. It completes **1,232
frame-bookend events, 2,464 post-frame updates and 480 item events**, with zero
reported memory or graphics errors and a clean exit. The final failed-chunk
counter is zero, but 232,274,737 interpreter steps remain across the run. That
counter is not proof that all chunks stayed valid throughout execution.
[Actual offline match evidence](artifacts/slippi-feasibility-2026-09-10/offline-active-match.json).

The [controller fixture](../scripts/fixtures/slippi-offline-match-input.txt)
contains input events only. Use it with `--input-script`, `--seconds 40`,
`--graphics Metal --screenshot`, and both automatic invalidation adapters.
It currently moves the first token through a random-selection area, explaining
the different first fighters across fresh runs. It establishes access to
gameplay but **does not define an identical starting match across runs**.
Rollback testing must capture and reuse one exact initial state rather than
compare fresh randomly seeded matches.

Next: use actual game-frame boundaries to capture and restore Slippi state,
then compare on-time inputs with 1/3/7-frame delayed-input resimulation from
the same initial match. Neither a full match/results/rematch cycle, actual
rollback, standard desktop interoperation nor physical iPad performance has
passed. The full six-group startup failure and the observed shutdown FIFO
failure remain open. No normal app or installed device has been modified.

## Iteration 8: actual-game restoration and delayed-input correction

The isolated macOS prototype captures Slippi state at game frame 120, runs an
authoritative input sequence, restores the state, deliberately predicts neutral
input for 1, 3 or 7 frames, then restores and resimulates with the authoritative
inputs. The wrong predictions produce different player packets in every trial,
so the test verifies a real correction rather than replaying an unchanged scene.

Progressive tests passed: 14 player packets for a seven-frame exact replay;
42 for seven-frame delayed-input trials; 180 for 30-frame movement/attack trials;
and finally **717 complete packet comparisons across three 60-frame trials**,
including player state, frame-start RNG and ordered item/projectile events.
There are no ignored fields, packet mismatches or timeline errors. The final run
has zero captured memory/graphics errors and exits cleanly. Each trial shares
one exact captured initial state; random character selection between fresh
boots is not treated as a deterministic baseline.

The synchronous test observer runs at real EXI packet/bookend boundaries. A
separate adapter invalidates native instruction-verification caches for RAM
ranges written during restoration; it never alters expected instruction hashes.
Both changes are isolated patches. The updated savestate, EXI device and game
test harness compile for iPhoneOS ARM64.

These are controlled offline delayed-authoritative-input tests. They do not
exercise network packet arrival, the production online rollback scheduler,
fast resimulation with rendering/audio suppression, desktop interoperability
or physical iPad performance. The full default code-set failure also remains
open. Next: link the complete iOS runtime and prepare an isolated device probe.

Evidence: [complete-event correction](artifacts/slippi-feasibility-2026-09-10/game-input-delay-complete-events.json),
[earlier restore](artifacts/slippi-feasibility-2026-09-10/game-state-restore.json),
[updated iOS compilation](artifacts/slippi-feasibility-2026-09-10/game-restore-ios-compile.json).

## Iteration 9: complete iOS runtime link

All 23 integration/test translation units now compile and link with the existing
iPhoneOS core archives, Slippi Rust extensions, Semver and VCDIFF dependencies.
The result is an ARM64 iPhoneOS executable with minimum iOS 16.0. The shared
core archives remain unchanged. This is the full offline runtime with its
command-line test entry point; it is not yet a UIKit application or an executed
device build. No game module is embedded in this executable.

The first full link exposed 21 deployment-target warnings: native objects from
Rust's ring dependency targeted iOS 26.5. That candidate failed acceptance even
though the linker produced an executable. Rebuilding with an explicitly chosen
rustup compiler, `IPHONEOS_DEPLOYMENT_TARGET=16.0`, and
`CFLAGS_aarch64_apple_ios=-miphoneos-version-min=16.0` resolved the mismatch.
The replacement link has no newer-target warnings. Inspecting one Rust archive
member, as the initial component audit did, was insufficient.

```sh
RUSTC="$(rustup which --toolchain stable rustc)" \
  IPHONEOS_DEPLOYMENT_TARGET=16.0 \
  CFLAGS_aarch64_apple_ios=-miphoneos-version-min=16.0 \
  CXXFLAGS_aarch64_apple_ios=-miphoneos-version-min=16.0 \
  CARGO_PROFILE_RELEASE_DEBUG=0 \
  CARGO_TARGET_DIR="$PWD/ref/slippi-compatibility/rust-build-ios16" \
  rustup run stable cargo build \
  --manifest-path ref/slippi-compatibility/rust/Cargo.toml \
  --package slippi_rust_extensions --release --locked --offline \
  --no-default-features --features mainline --target aarch64-apple-ios -j4

python3 scripts/probe-slippi-ios-link.py \
  --boot-probe ref/slippi-compatibility/game-delay-003 \
  --component-probe ref/slippi-compatibility/exi-probe-001 \
  --upstream ref/slippi-compatibility/upstream \
  --rust ref/slippi-compatibility/rust \
  --rust-ios-archive ref/slippi-compatibility/rust-build-ios16/aarch64-apple-ios/release/libslippi_rust_extensions.a \
  --ios-build ref/ModernGekko/build-ios-iphoneos-meleepad-static \
  --output ref/slippi-compatibility/ios-link-new
```

Evidence: [accepted full link](artifacts/slippi-feasibility-2026-09-10/ios-full-runtime-link.json),
[rejected earlier dependency target](artifacts/slippi-feasibility-2026-09-10/ios-link-target-failure.json).
Next: complete the iOS native game module, package a separate UIKit probe, and
run on the physical iPad when connected and unlocked. Preserve the installed
MeleePad application and its container.

## Iteration 10: separate signed iPad diagnostic candidate

The same captured patched-text/GCT source now builds as an iPhoneOS ARM64
native game module (minimum iOS 16). A small UIKit host links the passing
offline runtime, supplies a CAMetalLayer, drives the existing controller fixture
and stores logs/results in its own Documents directory. The only game-harness
adaptations are its callable entry point and host render-surface argument.

The private bundle uses `com.meleepad.SlippiProbe`, includes owner-supplied game
data, and must never be distributed. Socket and DNS entry points in the
statically linked test code return errors; this is a diagnostic guard, not an
iOS-wide sandbox or production network implementation. Jukebox/audio, spectator
service and replay saving remain disabled as in the host proof.

The candidate is signed using an existing valid development profile that
already includes the iPad, with strict bundle/module signature verification.
The existing MeleePad identifier and container are separate. Neither packaging
nor signing counts as device execution; physical results follow independently.

Evidence: [iOS native game module](artifacts/slippi-feasibility-2026-09-10/ios-native-game-module.json),
[private UIKit build](artifacts/slippi-feasibility-2026-09-10/ios-private-probe-build.json),
[signing audit](artifacts/slippi-feasibility-2026-09-10/ios-private-probe-signing.json).

The first physical launch installed and displayed the separate diagnostic UI,
then returned code 3 before creating the runtime. Wired House Arrest retrieved
the precise error: `missing files directory`. The packager had included `sys`
and the ISO but omitted the extracted `files` directory required by
`InspectGame`. The corrected package includes the original full extracted
files tree, preserving the host test's asset identity. The failed run is
[retained](artifacts/slippi-feasibility-2026-09-10/ipad-startup-packaging-failure.json);
it provides no game-execution or performance evidence. CoreDevice's recursive
container copy timed out; House Arrest succeeded without altering device data.

The corrected package boots and visibly renders Slippi's login menu on the
physical iPad Pro (12.9-inch, sixth generation), with CPU/vertex-loader JIT still
disabled. The core starts around observer second 10; the macOS fixture's Back
presses at seconds 5/6 occur too early. It therefore never starts a match and
correctly returns restoration-test failure code 14. The run renders 3,100
frames, with approximately 60 menu frames per second once running, zero
captured memory/graphics errors, and nominal start/end thermal state. These
are menu measurements, not gameplay or rollback headroom.

[Physical menu evidence](artifacts/slippi-feasibility-2026-09-10/ipad-menu-boot.json).
The next candidate delays the controller fixture by ten seconds; it retains
the same guest simulation and native module.

## Iteration 11: physical iPad offline game and correction pass

The delayed controller fixture reaches an actual Samus/Pikachu match on the
physical iPad. The same snapshot test deliberately predicts wrong inputs for
1, 3 and 7 frames, restores the captured game state, and compares authoritative
resimulation against its local baseline. **All 786 complete packet comparisons
pass**: 360 player-state packets and 426 ordered RNG/item packets. Wrong
predictions differ in all three trials. There are zero packet mismatches,
timeline errors, captured memory errors or captured graphics errors. The probe
returns code 0, and QuickTime visibly shows the match and success status.

This runs the three required Slippi code groups with CPU and vertex-loader JIT
disabled. It is an offline test in a separate diagnostic app, not a Slippi
network match or an available feature in the normal MeleePad build. The iPad
and Mac tests each compare against their own captured baseline; they do not
establish cross-platform state agreement.

Performance is **not accepted yet**. In-game samples show roughly 50-56 rendered
frames per nominal one-second observer interval, which also includes
guard/logging overhead. The run takes 87.37 seconds including initialization
and teardown; that whole-run duration is not a gameplay FPS measurement.
Start/end thermal state is nominal, but this short run does not establish
sustained thermal behavior. Audio is disabled, and the test renders ordinary
resimulation frames rather than benchmarking several corrected frames within
one presentation interval. A full completed match, results and rematch are
also untested.

[Physical game/correction evidence](artifacts/slippi-feasibility-2026-09-10/ipad-game-correction.json).

Next hypotheses: measure precise physical game/rollback costs and reduce
interpreter fallback from mutable GCT chunks; exercise the production online
rollback scheduler; resolve the full default code-set failure; then validate
standard desktop Direct interoperability through normal accounts and an
arranged opponent. Continue to keep public Slippi support disabled.

## Iteration 12: precise device timing and account identity

The separate physical iPad profiling run returns code 0 and records 1,654 game
boundaries. Filtering consecutive frames within each test phase, after-trial
gameplay averages **18.11 ms per frame (55.22 game frames/s)** across 1,038
intervals; median 18.49 ms and p95 19.93 ms. CPU-thread time closely tracks wall
time. This workload exceeds the 16.67 ms budget before production fast rollback
or audio is enabled. It is not an acceptable sustained-performance result.
The [analysis](artifacts/slippi-feasibility-2026-09-10/ipad-frame-profile.json)
is reproducible with `scripts/analyze-slippi-frame-profile.py` from private
captures; no game bytes are published.

Two words change between GCT captures at frames 60/180 and 180/300, both in the
first 16 KiB native-verification chunk. Runtime diagnostics record one failed
chunk and substantial fallback. This identifies a segmentation hypothesis,
not a measured explanation of all overhead. Another concrete lead is that the
normal frontend enables audited v1.02 caller/secondary idle shortcuts, while
this Slippi-INI probe records both idle counters as zero. Test those settings
in isolation, verify their instruction semantics against injected code, and
rerun correction and timing before accepting a performance change.

The owner's distribution concern now has an executable check against real
Slippi UserManager code: **1,000 independent managers preserve separate account
state** under OS-level network denial. Negative controls demonstrate that a
copied credential file duplicates the account, and local file-login success
does not prove service authentication. Logout and account-state replacement
remain isolated from the other manager. This is a local identity test, not
1,000 live connections. [Result](artifacts/slippi-feasibility-2026-09-10/account-identity-isolation.json).

Both probe and public IPA packaging now call the account-file/credential
metadata guard. The current private probe passes 62 metadata-file inspections;
seven rejection fixtures and two accepted fixtures pass. No new public IPA was
built or released. [Audit](artifacts/slippi-feasibility-2026-09-10/bundle-identity-audit.json).
The [network audit](SLIPPI-NETWORK-IDENTITY-AUDIT.md) records the upstream ENet
credential-transport issue, iOS sign-in gap, log redaction, account/report
ownership, same-NAT and IPv6 acceptance requirements. None is resolved by
generating more UUIDs. No production account traffic was sent.

## Iteration 13: physical idle-control experiment

The isolated packager now has `--idle-control`, requiring `--profile`. It applies
the normal frontend's v1.02 secondary scheduler and guarded raw-controller wait
settings. It leaves the unsafe primary shortcut disabled. The captured patched
DOL's service routine, scheduler routine and guarded caller sequence match the
original v1.02 bytes. Nearby Slippi force-engine/start-loop/rollback-loop hooks
do differ; this experiment does not accept their online timing behavior.

The separate probe builds, signs, installs and executes on the iPad, preserving
the normal MeleePad app. QuickTime shows Jigglypuff/Pikachu gameplay and the
completed-test banner. The probe returns 0 with zero captured memory/graphics
errors and JIT disabled. All **699 exact packets** match after 1/3/7-frame wrong
predictions: 360 player packets plus 339 ordered RNG/item packets. Each trial
contains an actual prediction difference and replays from frame 121.

After-trial gameplay averages **59.94 game frames/s** across 1,226 intervals:
16.683 ms mean wall time, 16.691 ms median and 16.968 ms p95. CPU-thread time
averages **7.823 ms**. Runtime counters verify that both configured idle paths
were exercised. Start/end thermal state is nominal. This is the first precise
physical result near the 60 FPS target for this Slippi diagnostic workload.

The previous profiling run selected Captain Falcon, while this one selected
Jigglypuff. Therefore this is not a matched A/B speedup measurement or proof of
all-character performance. The short run still disables audio, does not complete
a match/rematch, and renders ordinary correction frames. Neither the measured
CPU time nor the idle optimization establishes that the production online
scheduler can resimulate several frames inside one presentation interval.

[Physical idle-control evidence](artifacts/slippi-feasibility-2026-09-10/ipad-idle-control.json).
Keep the option diagnostic. Next: validate the actual Slippi online engine loop
and account-free local peer setup, while retaining the full-default-code failure
and desktop interoperability as open gates. If profiling that loop shows the
mutable GCT region is material, split verification chunks without weakening
instruction checks.

## Iteration 14: local online menu and packed-float compatibility

Added a two-client actual-game harness with a small ENet matchmaking fixture.
Each process gets its own synthetic account and user directory. The fixture and
peer clients bind loopback. macOS sandbox rules deny other networking; a sanity
test verifies loopback delivery and rejects non-loopback connection before the
runtimes start. This is a local protocol fixture, not a substitute for Slippi
service acceptance. No real account data enters these runs.

Entering online character select initially reproduced a guest alignment
exception in both native-with-fallback and interpreter-only controls. The guest
console records DAR `0x810E8D2E`. The saved exception PCs differ and must not be
represented as the exact offending instruction. Investigation located packed
float stores in Slippi's injected `Online/Static/UserDisplayFunctions.asm`, at
`0x806685F8` and `0x80668600`. The pinned
[Ishiiruka scalar load/store implementation](https://github.com/project-slippi/Ishiiruka/blob/e7711b104b339a99385f2bb12b472d46140a7bc7/Source/Core/Core/PowerPC/Interpreter/Interpreter_LoadStore.cpp)
accepts these accesses without an alignment exception. Our newer interpreter
checks alignment; modified native chunks correctly fall back to that interpreter.

The diagnostic `--packed-float-control` compiles an isolated load/store object,
leaving the shared core sources/build untouched. Only ordinary `lfs`/`stfs`
executed from the active loaded Slippi GCT region and addressing a complete
four-byte value within cached MEM1 get the donor-compatible behavior. Other
alignment checks, MMU access handling and native instruction hashes remain.
Eleven checks execute the actual interpreter accessors: packed byte order and
round-trip, aligned access, disabled Slippi mode, code-region boundaries and
out-of-RAM rejection. All pass.

With this control, both local processes render the Unranked character-select
screen with the synthetic account name, advance for the full observation and
exit cleanly: 3,455 and 3,462 frames, zero captured memory/graphics errors, JIT
disabled. Each records 16 scoped packed accesses. Without the control, both
processes stop progressing in the guest exception console. This is evidence of
a resolved menu compatibility seam in the diagnostic runtime. The input script
in this run does not select a character, so no ticket, opponent assignment or
online frame exchange occurs; the fixture times out as expected.

[Redacted local-menu evidence](artifacts/slippi-feasibility-2026-09-10/local-online-menu.json).
Next: drive character selection and queue entry against the local fixture,
then validate real online frame scheduling and finalized cross-client state.
Retain the full-default-code failure, physical online performance, supported
account handoff and standard desktop Direct as open gates. The owner has
provided a signed-in browser session for eventual acceptance testing; that is
not native authentication or a reason to enter a public queue prematurely.


## Iteration 15: local online match and finalized packet agreement

The corrected selection script reaches a match through the real Slippi online
client code. The local fixture accepts two independent synthetic tickets,
assigns the opponents, and both game clients establish their peer connection.
Both emit online input requests and game frame events. Server and both clients
exit 0 with zero captured memory/graphics errors and JIT disabled. This uses the
isolated packed-float control above, required three code groups and audio off.
No public service request or user credential is involved.

Both clients record 1,382 consecutive frame bookends, from -123 through 1,258,
and finalize their complete captured timelines. The new analyzer compares all
**4,146 full emitted state packets**: 2,764 player packets and 1,382 RNG packets,
with **zero mismatching frames**. There are no item packets in this run. Five
bookends differ only in when the peer's input becomes finalized; finalization
metadata is checked independently rather than treated as gameplay state.
This is emitted-packet agreement, not a full-RAM comparison. No repeated or
rolled-back game-frame timeline was observed. The current analyzer explicitly
rejects such timelines until rollback-aware analysis is implemented.

Seven analyzer controls pass, including detection of a corrupted player byte,
overflow, missing player data, truncated bookend, repeated timeline and wrong
packet count. Trace files remain private. The public evidence contains counts,
hashes, commands and bounded results, with no credentials or game data.

[Local online match evidence](artifacts/slippi-feasibility-2026-09-10/local-online-match.json).

Reproduce with the previously accepted local boot/components and owner-supplied
game data:

```sh
python3 scripts/probe-slippi-local-game.py \
  --boot-probe ref/slippi-compatibility/game-delay-003 \
  --component-probe ref/slippi-compatibility/exi-probe-001 \
  --build ref/ModernGekko/build-desktop-tools-meleepad-netplay \
  --game ref/revision-102/extracted --iso ref/revision-102/GALE01-r2.iso \
  --module ref/slippi-compatibility/native-gct-001/module-build/gGALE01_recomp.dylib \
  --output ref/slippi-compatibility/local-online-new \
  --input-script scripts/fixtures/slippi-local-online-select-input.txt \
  --packed-float-control
python3 scripts/analyze-slippi-local-game.py \
  ref/slippi-compatibility/local-online-new \
  --output ref/slippi-compatibility/local-online-new/state-comparison.json
```

Next: give the clients distinct gameplay inputs, inject bounded peer-input
latency, and compare finalized state across actual online rollback. The current
short, mostly neutral-input match does not establish complete match/results,
rematch, Internet/NAT reliability, desktop interoperability or iPad speed. It
advances the actual online engine gate beyond offline restoration tests; it
does not close S3, S4 or S5. Preserve the normal installed app while validating
this compatibility change in the separate device probe.


## Iteration 16: actual online rollback under delayed input delivery

The local harness now supports separate input scripts for the two players and
an isolated `--input-delay-ms` option. Starting at input frame 120, it queues
outgoing Slippi PAD packets on the existing network thread and releases them
at their due time. It leaves receive processing, acknowledgements, selections
and disconnect handling active. The bounded queue copies packet contents and
reports enqueued/released counts, overflow and maximum hold duration. This is
controlled input-delivery latency, not an OS network emulator, NAT test or
production networking change. All networking remains loopback-only.

Both active-input runs enter a match, move in different directions, attack and
produce projectile/item events. The actual online EXI path captures and loads
Slippi states; no manual offline correction callback runs in these tests.

| Configured PAD delay | Rewinds per client | Maximum observed rewind | Changed prediction frame events | Common finalized frames | Exact compared packets | Mismatching frames |
|---|---|---|---|---|---|---|
| 120 ms | 20 / 20 | 3 / 3 frames | 30 / 31 | 1,565 (-123 through 1,441) | 4,985: 3,130 player + 1,565 RNG + 290 item | 0 |
| 200 ms | 20 / 20 | 7 / 7 frames | 65 / 65 | 1,568 (-123 through 1,444) | 4,994: 3,136 player + 1,568 RNG + 290 item | 0 |

Both servers and all four client processes exit 0. All clients report JIT
disabled and zero captured memory/graphics errors. Actual maximum packet holds
are approximately 125.7 and 205.9 ms, with no queue overflow. Some packets
remain queued at the bounded observation end; this is not a drained-session
or complete-match acceptance test. One client emits a game-end event around
shutdown; that alone does not establish a normally completed match/results.

The analyzer now has explicit rollback mode. Following the upstream
[frame-bookend contract](https://github.com/project-slippi/slippi-wiki/blob/master/SPEC.md#frame-bookend),
it replaces predictions only before their frames become finalized. It rejects
revisions to finalized frames, skipped frames, malformed packet lengths,
missing player/RNG events, overflow and excessive unfinished tails. It checks
the exact event lengths used by the pinned game-code version. Only the common
finalized prefix is compared. The 120 ms run excludes three unfinalized tail
frames per client and one additional finalized frame on one side; the 200 ms
run excludes six unfinalized tail frames per client and one extra finalized
frame. Those exclusions are explicit in the artifact and are not mismatches
removed from the comparison.

Eleven delay-queue checks pass, including byte-preserving packet copies,
release-time boundaries, acknowledgement passage, zero-delay control and queue
capacity. Eleven synthetic analyzer tests pass, including a changed prediction
that must be replaced, an illegal finalized-frame revision, corrupted state,
truncated packets and incomplete timelines. The prior no-rollback match still
compares cleanly with the strengthened parser.

[Actual online rollback evidence](artifacts/slippi-feasibility-2026-09-10/local-online-rollback.json).
Reproduce using iteration 15's command, replacing its input options with:

```sh
--input-script scripts/fixtures/slippi-local-online-active-0.txt \
--player-one-input-script scripts/fixtures/slippi-local-online-active-1.txt \
--input-delay-ms 120
```

Use a fresh ignored output directory; repeat with `--input-delay-ms 200` for the
longer control. Add `--rollback` to the analyzer command. Run parser checks with
`python3 scripts/test-slippi-local-game-analysis.py`.

This advances S3 from manually driven offline corrections to actual peer-input
rollback and finalized cross-client packet agreement. It is not full RAM
agreement or comparison against a separately replayed, on-time online baseline
with the same authoritative inputs. Both clients use the same experimental
runtime, so shared errors remain possible. The wall-time input scripts also do
not establish identical frame-indexed inputs across separate runs.

Next: carry this scoped compatibility and online engine path into the separate
physical probe, retaining the normal app and data; measure actual online frame
and resimulation timing with audio. The existing offline iOS probe blocks all
socket/DNS creation, so its online successor needs explicit local-fixture
networking and independent synthetic identity rather than simply reusing that
binary. Then test standard desktop Direct with normal account access and an
arranged opponent. Full default code groups, sustained speed, complete matches,
results/rematches, account handoff and real Internet/NAT acceptance stay open.

## Iteration 17: physical online candidate and Local Network permission

Added an explicit LAN variant of the local harness and a private iOS online
packaging path. The fixture assigns each peer's observed address instead of
loopback. The iPad client contacts the configured fixture host but binds its own
interface. The iOS packager compiles the adapted matchmaking, peer transport
and packed-float interpreter object against the accepted iPhoneOS archives.
It retains the native module and no-JIT configuration, adds online frame/CPU
profiling and the diagnostic idle settings, and uses a separate synthetic
account at runtime. The normal MeleePad target is unchanged.

The original offline probe denies socket/DNS creation. This candidate instead
links a diagnostic guard allowing IPv4 UDP to loopback and one explicit private
fixture host. The Mac peer additionally permits the configured host's /24 LAN
subnet so it can reply to the iPad's address. TCP, IPv6 and other destinations
are rejected by the static runtime's wrappers; external DNS names are rejected.
This is not an OS sandbox or a production networking implementation. Thirteen
guard checks pass for each policy. Initial nonblocking receive assertions were
too early for asynchronous UDP delivery; bounded polling corrected those test
assertions without changing packet permissions.

Before device packaging, two Mac processes using the LAN-address path entered
a match and matched **5,013 finalized state packets** (3,112 player, 1,556 RNG,
345 item), with zero mismatching frames. This remains a same-machine control,
not a physical network test. It uses no added packet delay.

The separate **ios-app-009** candidate builds, passes bundle identity inspection,
is signed, installs in place as `com.meleepad.SlippiProbe`, and launches on the
attached iPad Pro. QuickTime verifies the online character-select screen and
synthetic account display. The normal MeleePad app and its private game/save container are
not accessed or replaced. Intermediate candidate 007 installed but was not run;
009 corrects the device bind address and is the candidate tested here.

Apple then displays **Allow Slippi Local Probe to find devices on local
networks?** The first matchmaking attempt fails while that prompt is pending.
The Mac sends one accepted fixture ticket; the iPad sends none, so no opponent
is assigned. The owner subsequently confirmed the permission was allowed; QuickTime verified
the prompt was gone before preparing a fresh attempt.
QuickTime displays the prompt but does not provide iOS touch input. A VPN
indicator is also visible; its effect has not been tested or established.

The collected iPad log reports 3,704 observed runtime frames, zero captured
memory/graphics errors, JIT disabled and nominal start/end thermal states.
There are no online-input or game-frame events and no timing samples from a
match. These observations prove menu execution, not match speed or peer play.
The old diagnostic return code is 0 because its observation stayed healthy;
it must not be interpreted as online success. The next candidate now returns
15 when online input/game-frame coverage is absent or the trace overflows.

[Physical first-attempt evidence](artifacts/slippi-feasibility-2026-09-10/ipad-online-first-attempt.json).
Device diagnostics were copied through House Arrest from the separate probe's
new run directory; originals remain on the device. The fixture and Mac process
ended normally after the bounded attempt, leaving no service running.

Next at that checkpoint: after OS permission, start a fresh synchronized iPad/Mac
attempt, compare their finalized state and measure actual online frame/CPU
intervals. Do not infer performance from the character-select frame counter.
The prepared probes still disable audio; audio, sustained sessions, full
matches/results/rematches, supported account handoff and standard desktop
Direct remain acceptance gates. No real account credentials or public queues
were used in this pass.

## Iteration 18: physical online state agreement and short match timing

After the owner allowed Local Network access, both synthetic clients reached
match assignment. Attempts 002/003 then exposed an asymmetric handshake:
the iPad connected while the Mac rejected the incoming peer. The cause was in
our diagnostic guard. UDP sending allowed the peer's LAN subnet, but numeric
address resolution allowed only the fixture host. ENet's `getaddrinfo` path
returned failure and the upstream peer setup did not check that result.
The Mac therefore compared incoming events against an invalid target address.

The guard now applies its destination predicate to numeric IPv4 resolution as
well as sending, with `AI_NUMERICHOST`; external DNS remains rejected. Fifteen
checks pass under each diagnostic policy, including numeric peer resolution.
No Slippi wire protocol change was needed. The installed iPad policy already
allowed its single Mac destination and was retained. These wrappers constrain
the linked runtime; they are not an OS sandbox or a production transport policy.

The next physical run, **ipad-online-004**, succeeds with **ios-app-010** and the
corrected Mac buddy. Both peers enter a match. All **4,742 finalized state
packets** match across **1,472 frames**, from -123 through 1348: 2,944 player,
1,472 RNG and 326 item packets. There are zero mismatching frames. The iPad has
one extra finalized trailing frame, explicitly outside the comparison. Neither
peer rewinds in this run, which adds no artificial packet delay.

After frame 120, the physical iPad advances at **59.96 game frames/s** over
**20.50 seconds** (1,229 intervals). Wall time averages 16.677 ms, p95 17.218 ms;
thread CPU averages 8.529 ms, p95 9.097 ms. Both thermal bookends are nominal,
JIT is disabled and captured memory/graphics error counts are zero. This is
actual online game progression, not a character-select FPS measurement, but
it remains a short, audio-disabled diagnostic with the three required game-code
groups and scoped idle/packed-float controls. It does not establish sustained
speed, full RAM agreement, a complete match, results, rematches or standard
Slippi desktop interoperability.

[Physical online evidence](artifacts/slippi-feasibility-2026-09-10/ipad-local-online.json).
The state analyzer was unchanged for this acceptance and its eleven adversarial
checks pass. The separate online timing analyzer includes intervening rollback
work in intervals between new highest frames; this run contains no rollback.
The original app and its data remain untouched. No real credentials or public
queues were used. Next: repeat the physical pair with delayed peer input, then
address audio and sustained sessions before standard desktop Direct acceptance.

## Iteration 19: physical online delayed-input correction

Kept the same signed iPad candidate and built a separate Mac buddy from the
accepted objects, changing only its existing PAD-delay queue from 0 to 120 ms.
This delays outgoing Mac PAD packets from frame 120; receive, handshake, ACK
and disconnect processing continue normally. It is a one-way injected delay,
not a measured Internet ping. The prior Mac binary and evidence are retained.

Run **ipad-online-005** matches all **4,875 finalized player/RNG/item packets**
across **1,504 common frames** (-123 through 1380), with zero mismatching frames.
The Mac records 20 rewinds with a maximum depth of four and 46 changed prediction
frame events. The physical iPad records four rewinds with a maximum depth of
six and eight changed prediction events. The analyzer validates those revisions
before finalization and rejects rewrites of already finalized state. Explicitly
excluded tails are four/one unfinalized frames (Mac/iPad) and one additional
finalized Mac frame. No mismatch or intermediate window was discarded.

The delay queue enqueues 1,391 packets, releases 1,384, has no overflow and
measures a maximum hold of 122.210 ms; seven remain queued at bounded shutdown.
The physical iPad's measured frame-120-and-later interval averages **59.72 game
frames/s over 21.12 seconds**. Wall intervals average 16.745 ms, p95 17.506 ms,
maximum 26.836 ms; CPU intervals average 8.724 ms, p95 9.413 ms, maximum 16.245 ms.
Those intervals include intervening resimulation work. Some rewind events are
outside this timing window; the complete state trace supplies the total above.
The device exits 0, has no captured memory/graphics errors, uses no JIT and
reports nominal thermal states at both ends.

[Physical rollback evidence](artifacts/slippi-feasibility-2026-09-10/ipad-local-online-rollback.json).
An initial file copy began before device finalization and lacked the trace
manifest/result. It was retained privately as incomplete; a second copy after
the device's completion supplied the accepted evidence. The run was not repeated
or substituted. Mac process completion alone does not establish device completion.

This is a physical online correction and emitted-state agreement pass between
two experimental clients. It does not close S3's independent on-time online
baseline, S4's standard desktop interoperability, or S5's audio and sustained
full-match requirements. Continue with audio/sustained timing, unresolved default
game-code behavior and then standard desktop Direct using normal account access.
No public service, real account credentials or ranked/unranked queue was used.

## Iteration 20: physical CoreAudio path and controller-fixture correction

Added `--audio` to the isolated iOS packager. It enables the existing CoreAudio
backend, activates a playback AVAudioSession, and samples the existing mixer
callback/output-frame/DMA-underrun counters at online game boundaries. It fails
when session activation fails or the measured match has no output callbacks.
The normal app, core archives and signed game module are unchanged. Jukebox
music remains disabled in this diagnostic; enabling sound output is not proof
of complete Slippi audio behavior.

Candidate **ios-app-011**, run **ipad-online-006**, activates RemoteIO at 48 kHz
and measures 916 output callbacks / 937,984 output frames, with no DMA underruns
inside its frame-120-and-later window (three occurred before it). Its peers
agree on 4,492 emitted state packets. However, QuickTime shows **P2 Paused**
during the run. The fixture's second wall-clock Start input can land after the
match has begun. The measured interval has not been independently established
as entirely unpaused, so its timing is preliminary and is not active-match
performance acceptance.

[First audio-attempt evidence](artifacts/slippi-feasibility-2026-09-10/ipad-audio-first-attempt.json).
The short QuickTime recording remains in its unsaved local composition.
Inspector verifies H.264 video and a 48 kHz AAC mono audio track; source/quality
are not accepted. Direct file inspection stalled and was stopped without
altering the recording. A mirrored audio track also cannot replace a physical
speaker listening check.

Prior traces still show exact finalized packet agreement and varying player
state; that finding is retained. Their FPS values describe recorded event
progression, and are not proof of a fully active workload throughout each run.
The next test explicitly suppresses diagnostic Start input after the first
Slippi game-start event on both peers, continues movement/attacks for a longer
window and retains the 120 ms one-way PAD delay. This changes test controls,
not gameplay pause rules or the Slippi protocol. The packager now supports a
bounded 60–120-second online observer; the new run uses 90 seconds. Device
collection now waits for the run's terminal JSON before copying its trace,
independently of Mac process completion.

### Longer audio-enabled result

Candidate **ios-app-012**, run **ipad-online-007**, and the separate guarded Mac
buddy complete the 90-second observer test (121.98 seconds including device
initialization and scripted-input holds). With the retained 120 ms one-way PAD
delay, **11,217 finalized packets match across 3,518 common frames** (-123 through
3394), with zero mismatches: 7,036 player, 3,518 RNG and 663 item packets.
Mac/iPad record 49/46 rewind events, maximum depths five/three and changed
prediction counts 104/36. The explicit excluded tails are three/one unfinalized
frames and one extra finalized Mac frame.

The iPad advances at **59.74 game frames/s over 54.82 seconds** after frame 120,
including 47 replayed bookends in that timing window. Wall intervals average
16.738 ms, p95 17.709 ms, maximum 21.328 ms. CPU intervals average 9.005 ms,
p95 9.907 ms, maximum 13.221 ms. Both players have 13 distinct action states;
their finalized positions have 330/376 distinct encodings, providing stronger
activity evidence than a menu/idle frame count. This is a longer short test,
not full-match or sustained thermal acceptance.

CoreAudio produces **2,570 callbacks / 2,631,680 output frames** in the measured
window, with **zero new DMA underruns**. Five underruns precede the window and
are retained in the report. Session activation succeeds, device exit is 0,
thermal bookends are nominal, JIT is disabled and captured memory/graphics
errors are zero. Actual audible quality, music and rollback sound behavior are
not accepted by these counters.

[Longer physical audio evidence](artifacts/slippi-feasibility-2026-09-10/ipad-online-audio.json).
The preceding pause observation remains an integration issue to investigate:
upstream `EXI_DeviceSlippi.cpp` disables pause for Unranked, and the fixture
reports mode 1 (Unranked). Suppressing diagnostic Start makes this workload
more controlled; it does not prove the intended match rules or pause rendering
are correct. Continue by checking guest match settings/render state, default
code groups, complete match/results/rematch behavior and an arranged standard
Slippi Direct test. No public service was contacted and the original app/data
remain unchanged.

## Iteration 21: official desktop reference prepared

Moved from additional local simulation tests to the official reference client.
Downloaded official ARM64 Slippi Launcher 2.15.1 and verified its GitHub-published
SHA-256 and application signature. Its normal UI opened and subsequently showed
the owner's signed-in main screen. No account file or secret was copied into
our probe. Launcher interaction overlapped owner navigation, so further account
setting changes were deferred rather than fighting the user's UI actions.

Downloaded the official Slippi netplay v3.6.4 DMG, verified its published digest,
mounted it read-only, copied the unmodified app into the ignored test directory,
and detached the image. The x86_64 client opens through existing Rosetta as
**Faster Melee - Slippi (3.6.4)**. Its stale Info.plist version differs from its
release/runtime version; record both rather than treating the plist as decisive.
Both bundled `GALE01r2.ini` copies hash to
`b30b294df5c0d92deb3129afdfbc894a48aabeb1bce0cf92cce8c4e5408a2587`,
exactly the configuration already pinned in the prototype.

[Official desktop preparation evidence](artifacts/slippi-feasibility-2026-09-10/official-desktop-readiness.json).
This establishes the reference binary/version and available signed-in Launcher,
not game boot, account handoff into either test runtime, or a crossplay match.
The file-open flow did not complete and no matchmaking action was performed.
The original generic Dolphin app and MeleePad app/data were not replaced.

Next: complete the normal official-client game setup and implement the isolated
iPad probe's per-user account/production Direct path. The current probe still
writes synthetic credentials, uses a development version marker and contacts
a private assignment fixture; it cannot simply be pointed at the public service.
Keep synthetic accounts off the real service, retain truthful compatibility
versioning and normal server rejection behavior, and never distribute account
credentials. An async request for an arranged opponent with a distinct account
is pending. Do not replace this crossplay milestone with more same-runtime
performance tests while these concrete setup tasks remain available.

## Iteration 22: separate Direct candidate with account handoff

Created `scripts/build-slippi-direct-probe.py`, a separate build path from the
accepted offline adapter and physical-test assets. Candidate `ios-direct-002`
recompiles all **24 C++ integration units** and the UIKit host for iPhoneOS,
links successfully, preserves the shared archives, and passes the existing
bundle identity audit. It does not modify the normal MeleePad app or the
accepted LAN harness.

The candidate removes synthetic accounts, automatic controller scripts, the
private matchmaking fixture, artificial packet delay and loopback-only peer
binding. It retains upstream matchmaking host selection, port, account handling
and server rejection logic. Its version is **`3.6.4+meleepad.probe`**, identifying
the compatibility baseline and experimental fork; this is not a claim that
Slippi's service accepts that version. Every integration unit is rebuilt with
the same version header.

An EXI-boundary guard rejects all modes except Direct with a nonempty bounded
connect code before code-history persistence or a matchmaking request. It does
not change the requested mode, invent an opponent, bypass authentication or
suppress server errors. An extended controller supplies normal in-game input;
there is no automatic queue entry. The host stops the test on backgrounding,
on explicit Stop, on detected memory/graphics errors, or after 15 minutes.

The new account UI uses an explicit document-picker import and stores the
normalized account in non-synchronizing, device-only Keychain storage. Starting
a test copies it to the isolated runtime's expected `Slippi/user.json` with
mode 0600. Normal teardown removes that plaintext copy after runtime shutdown;
the next launch cleans copies left in this target's UUID run directories by an
interrupted process. The original export is untouched. This is an implementation
of the handoff, not evidence of a successful import or service authentication.
The host does not persist arbitrary runtime logs, which may contain identities
or network payloads. Structured counters and bounded game traces remain private.

**21 account-validation/lifecycle checks and 13 Direct-mode checks pass**, using
synthetic inputs and no network. The first compile exposed a missing local
variable after extracting the in-memory credential handoff; it was fixed before
the passing build and checks. Pinned third-party JSON deprecation warnings remain.

The signed candidate was installed in place as `com.meleepad.SlippiProbe`,
launched successfully, and its **Experimental Slippi Direct** account-import
screen was visually confirmed through QuickTime on the physical iPad. Start
is disabled without an extended controller. No account was imported and no
game runtime or matchmaking request was started. The normal MeleePad bundle
and its game/save container were not targeted.

[Candidate evidence](artifacts/slippi-feasibility-2026-09-10/direct-candidate.json).
The required three-code subset, packed-float and idle diagnostic controls remain
explicit. This candidate cannot establish full default-code compatibility.
Bounded trace/profiler capacity must be checked before treating a long match or
multiple rematches as fully compared; counter totals alone do not prove sync.

Next acceptance: exercise account import and manual navigation on the device,
complete normal official desktop game setup, and attempt Direct using an
arranged opponent's distinct account. No public queue or real credential has
been used by this iteration. Do not report the new build as authenticated or
crossplay-ready merely because it links or its setup screen opens.

## Iteration 23: official desktop boot and real account on physical iPad

The unmodified official Slippi 3.6.4 executable now visibly boots to the Online
Play menu, both with a new isolated user directory and through the owner's
normal signed-in Launcher. The Launcher-managed executable hashes identically
to the pinned official download. Existing Xbox controller mappings were
inspected and left unchanged; keyboard navigation did not move that configured
controller. The reference game was stopped after inspection. No matchmaking
queue was entered. This resolves the earlier file-open/reference-boot blocker.

After the owner resumed work and explicitly authorized credential injection,
the official Launcher's pinned `findPlayKey()` implementation identified its
normal macOS account file. A read-only check confirmed the required fields and
matching owner profile without emitting any values. No credential was generated,
changed or copied into source, a bundle, or a public artifact.

Candidate **ios-direct-003** adds an explicit wired import argument for this
private diagnostic target and a 45-second account-boot observer. It uses the
same normalization and Keychain code as the document picker. CoreDevice's file
transfer timed out; a targeted wired House Arrest listing verified that the
destination file was absent, and AFC then transferred it successfully. The
host imported the account, verified matching Keychain readback, and removed
the inbound temporary copy.

The physical iPad then ran the actual Slippi game runtime with the real account:

- `account_file_loaded=1`, JIT disabled, and the Online Play menu visually shown.
- Exit code 0 after **70.10 seconds**, including initialization and the bounded
  observer; CoreAudio session active.
- Zero captured memory/graphics errors and zero Direct or denied searches.
- No game bookend events; the visible screen remained a menu. The start/end
  counters were subsequently found unwired in this candidate and their zero
  values must not be used as evidence of game absence (see iteration 24).
- Runtime plaintext `Slippi/user.json` was confirmed absent after teardown.
  The account remains in device-only Keychain; the owner's desktop source is
  untouched. The normal MeleePad app/container was not targeted.

[Physical account evidence](artifacts/slippi-feasibility-2026-09-10/ipad-real-account-boot.json).
Upstream's `IsLoggedIn()` means the local account file loaded. It does **not**
prove that matchmaking accepted its play key. Do not rename this result to a
successful service login or crossplay pass. The document-picker gesture and
physical controller input are also not covered by this wired-import run.

The owner has been asked for an arranged opponent's connect code or a separate
account they control for the desktop peer. Do not duplicate the same account
across the two peers, invent an opponent, enter Unranked to find a test subject,
or replace the outstanding desktop match/rematch with repeated menu benchmarks.
The next live acceptance action is Direct with distinct normal accounts.

## Iteration 24: full-match and rematch capture readiness

Auditing the Direct recorder found two limitations before crossplay: its short
LAN trace was capped at 60,000 packets, and the new Direct start/end counters
were attached to an observer that received neither event. This affects those
counters, not the verified Keychain/account loading or observed menu in the
prior run. The prior artifact now explicitly records this limitation.

The separate Direct build now forwards the existing game-info/game-end EXI
events to the observer without changing game execution or the upstream network
path. `scripts/slippi-direct-trace.hpp` stores each game's complete player,
RNG, item and bookend packets separately. The session is bounded by 64 MiB of
payload, 400,000 rows and 16 games; vector bookkeeping adds memory overhead.
Overflow and missing/out-of-order game boundaries are explicit errors in the
metadata. No rollback frame or mismatching state is filtered to make it pass.
Files are written after runtime stop and write failures produce a nonzero
probe exit. The accepted short LAN recorder remains unchanged.

Nine focused synthetic checks pass, including 140,000 retained packets across
two games, frame-number reset separation, overflow, missing game-end and
packets outside a game. [Capture checks](artifacts/slippi-feasibility-2026-09-10/direct-trace-checks.json).
Candidate `ios-direct-004` recompiles/links for iPhoneOS with the new event
forwarding. It is not installed or exercised against a real game. The physical
iPad retains `ios-direct-003` and the owner's Keychain account.

This is evidence-capture preparation, not another networking or performance
acceptance result. The short profiler/audio sampling windows remain bounded;
full-session performance must not be inferred from those windows. A real
desktop match and rematch with separate accounts remain the next acceptance
test; no opponent or second account has been supplied yet.


## Iteration 25: continue without a second production account

The missing arranged opponent blocks public-service acceptance, but need not
block cross-engine testing. Build an isolated desktop reference from Ishiiruka
3.6.4 (`e7711b104b339a99385f2bb12b472d46140a7bc7`), with its pinned Rust
submodule (`2d29e794de8497582675fb70877851f2cdd2f256`), and introduce both
it and the iPad through the private synthetic matchmaker. This is a different
engine from the two experimental peers used in previous LAN tests.

The reference must retain desktop game execution, Slippi game codes, peer
protocol, and rollback behavior. Test-only changes may isolate account storage,
redirect matchmaking to the fixture, restrict network destinations, automate
controller input, and capture state. Record every change. A successful result
would establish compatibility with this instrumented reference, not acceptance
by Slippi's public service or an untouched released binary.

Source inspection found that macOS `GetSlippiUserConfigFolder()` resolves to the
shared application-support Slippi directory, independently of `-u`. Therefore,
previous official boots with a separate user folder did not prove account-file
isolation. No credentials were deliberately copied into those folders, but that
is a narrower statement than saying the official process could not read them.
Do not launch the new reference with synthetic matchmaking until account-path
isolation and network restrictions are implemented and verified. The existing
signed desktop installation and real iPad Keychain account remain untouched.

Build preparation uses a separate ignored checkout and build directory. CMake
4.4 rejected the legacy target/policy rules; a local CMake 3.31.10 installation
successfully configured the project. The target is named `SlippiReferenceLab`
to distinguish it from the installed client. The first compile reached the
Rust extension and exposed an architecture mismatch: Homebrew Rust lacked the
x86_64 target. Configuration now explicitly selects Rust 1.88.0 and its
x86_64-apple-darwin target, matching the pinned project's toolchain. No shared
MeleePad library or source has been rebuilt or modified for this experiment.

Next acceptance sequence: reference build; fixture/account isolation checks;
reference-versus-native match with finalized state comparison; delayed-input
rollback; full match and rematch; repeat on the physical iPad. Preserve mismatch
and failure evidence. Do not replace these gates with repeated menu benchmarks.

The independent desktop replay reader
`scripts/extract-slippi-reference-trace.py` converts the pinned writer's raw
SLP events into the native comparator's CSV format. It requires a closed raw
stream, a complete start/end, known event sizes, and valid packet boundaries;
it excludes metadata, game-start identity fields, and pre-frame input events.
Seven synthetic parser checks pass (`scripts/test-slippi-reference-trace.py`).
This validates extraction guards only; no real desktop/native replay pair has
been compared yet. The source format was checked against the pinned desktop
`CEXISlippi::writeToFile` implementation.

Build-only reference changes are recorded in
`patches/slippi/reference-lab-build.patch`: a distinct CMake target name and
removal of an unused `using namespace Common` directive that fails with the
current SDK when that namespace is not declared. Neither changes game logic.

Reproducible setup and acceptance gates: [Desktop reference lab](SLIPPI-REFERENCE-LAB.md).

The desktop reference subsequently **built and linked successfully** as x86_64,
including the pinned Rust extension. Besides the recorded missing-include
fixes, the optional libao backend was disabled; its stale `AO_FOUND` CMake cache
entry also had to be cleared. CoreAudio remains available. The executable has
not been launched: account/network fixture isolation is the next gate.
[Reference build evidence](artifacts/slippi-feasibility-2026-09-10/reference-lab-build.json).
This advances reference-peer readiness and does not establish cross-engine
compatibility. No iPad install, normal-app change, or account transfer occurred
in this iteration.


## Iteration 26: Mac-only reference/native match start

The user requested a new virtual-only goal loop. The goal tool rejected a new
objective because the older goal remains unfinished/blocked. Work continued
under that objective without falsely marking it complete. This phase uses no
attached hardware, real accounts, or public matchmaking.

The source-built Ishiiruka reference now requires an explicit laboratory account
path and binds matchmaking, peer traffic, and the diagnostic spectator stream
to loopback. `reference-lab-isolation.patch` records these changes. Each test
runs under a macOS sandbox that permits loopback networking and denies the
normal Slippi application-support directory. Both allowed local delivery and
denied external access/account-directory reads were checked before launch.
The fixture accepts only its two synthetic identities and their respective
pinned version strings. Missing app resources initially caused a failed boot;
the driver now copies the reference Sys resources and fixes the laboratory
bundle executable metadata before ad-hoc signing its private copy.

Run `reference-pair-004` obtained both tickets and visibly started a match on
the reference, with the native no-JIT runtime as the other player. The reference
replay was closed when the native peer's bounded session ended; this is **not**
a completed competitive match or rematch. Across the common finalized prefix,
**726 frames / 2,248 packets** were compared. All **1,452 player packets** and
**726 RNG packets** matched exactly. The strict raw comparison failed on 35
frames: differences were confined to item offsets 0x28 and 0x29.
[First cross-engine match evidence](artifacts/slippi-feasibility-2026-09-10/reference-first-match.json).

The Slippi spec identifies those offsets as charge-shot launch/power fields.
The recorder unconditionally reads item offsets 0xDEB/0xDEF for those fields;
the corresponding instruction sequence also exists in the pinned game-code
INI. This suggests type-specific incidental data, but does not justify hiding
the differences. Raw mismatch evidence and the failing result are retained.
No rollback was observed in this baseline; forced-delay validation remains open.

Wall-clock pipe input proved unreliable as cursor movement varied with runtime
speed. The driver now uses libmelee 0.47.3 for frame-driven input through the
reference's existing pipe/spectator interfaces. It does not let libmelee replace
gameplay codes or read the owner's settings. The only additional Gecko block
is its `Optional: Extract Menu Info` observer, which skips in-game scenes; no
infinite-time or instant-match code is enabled. Its network worker is explicitly
bound to loopback. A NumPy frame-number serialization issue was corrected after
an automated two-ticket setup; that interrupted run is not an acceptance pass.
`run-slippi-reference-lab.py` and `slippi-reference-controller.py` retain bounded
execution and stop the process groups for their own test instances.


### Automated longer capture and arithmetic hypothesis

`reference-pair-014` automatically reached gameplay and compared **1,462
finalized frames / 4,683 packets**. The desktop timeline contained 18 rewinds
(up to seven frames) and 84 changed prediction events. All 2,924 player packets
and 1,462 RNG packets matched. The strict result remains **failed**: 126 frames
had item differences, with 231 mismatching item packets. In addition to the
charge-specific bytes, byte `0x1b` differs beginning at frame 229 inside the
32-bit lane beginning at packet offset `0x18`: native `41021f33`, reference
`41021f32`. This is a real one-ULP encoded-float difference and must not be
normalized away. Earlier notes called this lane “item Y”; packet evidence alone
does not establish that object-level meaning.

The native run captured no memory/graphics errors and kept JIT disabled. It
ended at its 60-second bound; no full-match/rematch completion or deliberately
delayed-input acceptance is claimed. [Evidence](artifacts/slippi-feasibility-2026-09-10/reference-automated-match.json).

Source inspection found modern fused multiply-add in the native generated
module runtime, while the pinned desktop JIT disables host FMA in deterministic
mode. This is a hypothesis for the encoded-float difference, not a proven cause.
`scripts/build-slippi-unfused-module.py` builds an isolated finite scalar
multiply-add diagnostic by reusing existing module objects. It changes neither
the shared build nor the normal application. Paired arithmetic and the host
interpreter remain unchanged, so this control is deliberately incomplete.

The scalar-only candidate (`scalar-unfused-002`, run `reference-pair-015`)
completed 1,464 compared frames with 18 desktop rewinds. All player/RNG packets
again matched, but the same `0x18` encoded-float bit patterns remained different.
There were 125 mismatching frames; this is **not a fix**. The control suggests
scalar multiply-add alone is insufficient; it does not exclude paired
arithmetic or interpreted instructions. [Control evidence](artifacts/slippi-feasibility-2026-09-10/reference-scalar-control.json).

The expanded scalar-plus-paired candidate (`paired-unfused-001`, run
`reference-pair-016`) also retained the same `0x18` item bit patterns: **1,469
finalized frames / 4,703 packets**, 125 mismatching frames, 18 desktop rewinds.
All player and RNG packets still match. Neither candidate is promoted into
MeleePad. These experiments do not establish that arithmetic is the cause;
the host interpreter was unchanged and only finite module operations were
controlled. [Paired control evidence](artifacts/slippi-feasibility-2026-09-10/reference-paired-control.json).

**Next bounded experiment:** capture the first relevant item's initial state,
including the candidate position/velocity lanes on each engine; identify the
earliest differing guest instruction; and test that instruction with the
observed operands. Do not repeat menu setup or normalize packet bytes. Revisit
interpreted arithmetic, matrix transforms and item creation only from that
evidence. Full-match/rematch and forced-delay desktop acceptance follow exact
state convergence.

Validation for this pass: seven reference-extractor tests and eleven
rollback-comparator tests pass; modified Python scripts compile, local
documentation links resolve, and whitespace checks pass. No attached hardware,
owner account, public queue, normal app or shared archive was modified.


## Iteration 27: item packet diagnosis and interpreter control

The exact item comparison was tightened before changing runtime code. The new
`analyze-slippi-item-trace.py` comparator retains every `0x3b` event in its
per-frame order instead of converting events to a single frame-keyed value. On
`reference-pair-014`, it confirms **297 item packets per client**, no item-count
disagreement in the common finalized prefix, and **231 payload mismatches**.
The first payload mismatch is frame 229, ordinal 0, item type `0x004b`, raw
packet offset `0x28`; the second item at that frame, type `0x0037`, differs at
offset `0x1b` and raw byte `0x29`. The `0x18` float lane differs by one encoded
ULP in 126 packets. This is a more precise diagnosis than the earlier
single-item-per-frame summary and does not claim the `0x18` lane is a specific
game-object coordinate. [Item trace evidence](artifacts/slippi-feasibility-2026-09-10/reference-item-trace.json).

The analyzer's two focused controls pass. It rejects an extra item event
instead of hiding it and checks more than one item event in a frame. The
existing extractor and rollback controls remain passing. No production module,
normal app, public service or account was changed.

A full PowerPC-interpreter native control was also attempted in the isolated
reference lab (`reference-pair-017`). It is **inconclusive**, not a
compatibility result: the native process reached only 371 game frames in its
60-second bound, the frame-driven controller reported no gameplay frames, and
the fixture saw one unpaired ticket before exiting. The wall-clock menu input
schedule is not valid evidence at interpreter speed. [Interpreter-control
status](artifacts/slippi-feasibility-2026-09-10/reference-interpreter-control.json).

The next loop action remains source-level guest-state capture at item emission:
record the relevant object words and packet bytes on both engines at the first
divergence, then test one observed instruction/operand pair. Only after the
item state converges will the loop spend another bounded run on full match,
rematch and deliberate rollback delay. Hardware and public-service acceptance
remain separate later gates.


## Iteration 28: native callback context ruled out

The first native-only guest-context capture completed a real two-client local
match with the accepted native module and the existing packed-float control.
Both synthetic clients were assigned by the loopback fixture, exited 0, kept
JIT disabled, and recorded zero memory/graphics errors. Each emitted **420
item events** across item types `0x004b` and `0x0037`.

The capture ran at the existing `CEXISlippi::DMAWrite` observer boundary and
also checked the exact field offsets used by the pinned `SendGameInfo` block.
At the first event, the callback had `PC=0x80345e60`, `r28=1`, `r29=0x1a0`,
and `r4/r30=0x80bee680`. That pointer did not reproduce the packet fields at
the `0x40`, `0xc9c`, or `0xdef` offsets. A strict aligned MEM1 scan including
modified D-cache lines found **zero candidate objects for all 420 events on
both clients**. This rules out using the observer's post-DMA registers or a
simple callback-time RAM scan as the guest source context; it does not prove
that the packet construction is wrong or identify the one-ULP cause.

The private run also confirms why the previous full GCT mutation was
inconclusive: changing the resource code without rebuilding the matching
native module triggers static-recomp verification failures, and the
interpreter-only fallback cannot reach the online match within the bounded
wall-clock run. [Redacted capture evidence](artifacts/slippi-feasibility-2026-09-10/native-guest-item-context.json).

The next bounded action is now narrower: create a matching diagnostic native
module for a same-length `SendGameInfo` instrumentation that exports the guest
`r28` and relevant object fields, then run one reference/native comparison at
the first divergent item. Do not promote the instrumented module or alter the
normal app. Full match/rematch, deliberate rollback delay, physical sustained
audio/performance and public-service acceptance remain downstream gates.


## Iteration 29: matching GCT capture and mutable-data drift

The matching diagnostic module was built after correcting a subtle GCT parser
failure: the final instrumentation line must be a complete two-word Gecko pair.
The builder now rejects a generated instruction count that differs from the
expected INI payload and can compile the live, post-handler GCT capture from a
separate successful run. The resulting private ARM64 module contains the
`0x8065cc80` GCT region, 56,864 bytes, and matches the run-010 live RAM capture
byte-for-byte. This confirms the address and the captured relocation; it does
not make the heap data portable or stable.

The instrumented module was then run with the GCT range forced through the
interpreter using the private runner's `--gct-interpreter-fallback` switch.
This removes GCT verification noise: both clients remained no-JIT, recorded
zero memory/graphics errors, and progressed 301–302 frames. However, the
instrumented guest path still produced no accepted ticket, opponent
assignment, or item callback. The run is therefore **inconclusive for the
guest boundary**, not a compatibility pass. Its bounded result is recorded in
the [GCT drift artifact](artifacts/slippi-feasibility-2026-09-10/native-gct-capture-drift.json).

Comparing the run-010 capture used for the module with the later run-011
capture found exactly 18 changed bytes at offsets `0x5eb1–0x5ec2`: embedded
status-string data was present in one run and zero in the other. The native
GCT verifier hashes whole chunks, so compiling this mutable region as a
strictly static native text section is not a reliable integration boundary.
The current evidence supports keeping mutable GCT data on the interpreter
side, or splitting its data from native verification, while preserving native
coverage for stable original text. It does not justify a production fallback
policy change yet.

The known `local-online-guest-008` native baseline remains the closest accepted
local online result: both synthetic clients were assigned, exited 0, stayed
no-JIT with zero memory/graphics errors, and emitted item callbacks. No
physical device, live Slippi service, desktop interoperability, complete
match/rematch, or public playable artifact has been accepted. The next loop
action is to restore that baseline and isolate the `SendGameInfo` instruction
boundary without changing its control flow; only then should the first
cross-engine item divergence be compared again.

## Iteration 30: length-preserving native item hook

The earlier resource instrumentation path remains rejected. Expanding the
pinned `SendGameInfo` GCT block changed the relocated layout and prevented
matchmaking; changing its scratch page and preserving `r12` did not repair that
control-flow boundary. The accepted native baseline therefore stays on the
normal resource layout with the mutable GCT range forced through the
interpreter.

The replacement diagnostic uses a private ModernGekko entry hook at
`0x8065EBD0`, immediately after the native `SendItemInfo` loop loads
`itemData`. The hook reads the item fields through `CPUState::external_read`
and returns without modifying the CPU state or guest memory. It is
length-preserving and does not replace the native module.

The active-input run reached the same local online fixture with both synthetic
tickets accepted and opponents assigned. All three processes exited 0; both
clients remained no-JIT with zero memory/graphics errors. The hook logged 64
calls per client. Comparing those calls with the first 64 emitted `0x3B`
packets found zero mismatches across the 12 captured fields: ID, state,
direction, velocity and position lanes, damage, expiration, spawn, metadata
and instance. The owner-pointer path was not included in this first hook and
remains a small capture gap. [Redacted evidence](artifacts/slippi-feasibility-2026-09-10/native-item-host-hook.json).

This proves the host hook is a viable observation boundary, not that native
Slippi now matches the desktop reference. The next gate is a reference-side
capture at the same item frame and ordinal. Only an identified field or
instruction divergence justifies a native serializer or arithmetic change; no
public native-complete, physical gameplay or live-service claim follows from
this run.

## Iteration 31: reference EXI boundary closed

The first reference-side attempt used a callback-time MEM1 scan. Across 64
reference item packets, it found many stale ID/velocity matches but no object
whose positions also matched, so the broad scan was not a source-state
capture. The EXI callback also runs at `EXISync` with caller registers rather
than the `SendItemInfo` loop's item register. [The scan result is retained in
the private run output](../ref/slippi-compatibility/reference-item-capture-005)
for audit only; raw output is not part of the evidence artifact.

The diagnostic was then made length-preserving. In an isolated copy of the
reference bundle, the existing `SendGameInfo` spawn-ID load was replaced by a
single `mr r3,r28`, allowing the existing spawn-ID store to carry the live
guest pointer to the host. The C2 block remained `0x119` lines, and the
reference still reached matchmaking and opponent selections. The native
control exited 0 with 2,441 no-JIT frames and zero memory/graphics errors.

All 64 reference packets carried a guest pointer, but **0/64** had later RAM
contents matching the serialized item fields. The object changes or becomes
unreliable between item serialization and `EXISync`; this closes the
post-DMA/host-register route without identifying a serializer or arithmetic
cause. [Redacted evidence](artifacts/slippi-feasibility-2026-09-10/reference-item-boundary.json).

## Iteration 32: source-state divergence identified

The next private run paired the reference JIT callback at guest PC
`0x8065EBD0` with the validated native ModernGekko host hook in the same
loopback fixture. The reference and native processes both reached matchmaking;
the fixture assigned both synthetic clients; the native process exited 0 with
1,677 no-JIT frames, zero memory/graphics errors, and GCT fallback enabled.

The two engines each captured 64 instruction-boundary item events. Every
reference boundary object matched its own emitted packet (`64/64`), and every
native host-hook object matched its own emitted packet (`64/64`). Comparing the
paired source states found **0/64 full-field matches**: the first event already
differed in item ID and metadata, while direction, X velocity, spawn ID, and
instance agreed across the window. Y motion, X/Y position, and expiration
first diverged at event 50 as the reference began reporting a second item
trajectory. [Redacted paired evidence](artifacts/slippi-feasibility-2026-09-10/reference-item-instruction-boundary.json).

At face value this moved the likely defect upstream of EXI packet construction:
each serializer faithfully reflected its live `itemData`. The pairing was not,
however, a same-state proof: the first reference/native events already had
different item identity and metadata, and the two processes were driven by
separate timed runs and roles. The run therefore does not identify an earlier
object-creation or object-list instruction, and no production serialization,
packed-float, or arithmetic change is justified. The next loop action is to
establish a same-state, role-controlled pairing (or a reliable interpreter
trace) before tracing item creation/list insertion. Full match/rematch,
deliberate rollback delay, desktop interoperability, physical gameplay, and
live-service acceptance remain separate downstream gates.

## Iteration 33: spawn-boundary diagnostic rejected as a parity gate

To test whether the identity difference could be located at item creation, the
private reference build captured the entry to `Item_8026862C` at guest PC
`0x8026862C`, before the spawn record was initialized and linked. The bounded
run reached the local fixture: both synthetic tickets were assigned, the
native process exited 0 after 1,636 no-JIT frames with zero memory/graphics
errors, and it emitted 234 item packets with the mutable GCT range in the
interpreter. The reference process reached opponent selections and the
controller observed 1,163 game frames. [Redacted run evidence](artifacts/slippi-feasibility-2026-09-10/reference-item-spawn-boundary.json).

The capture is not a cross-engine spawn comparison. The reference JIT callback
became active only after translation and recorded nine later spawn calls, so it
missed the earlier creations relevant to the item window. The native
ModernGekko hook recorded zero dispatches at this function, indicating that
this path was not reached through a host-dispatchable native block; it is not
evidence that native item creation is absent or incorrect. No native behavior
change is justified by this run.

The active goal loop is therefore: first make the fixture state-equivalent by
controlling local roles, inputs, timing, and item identity (or obtain a
reliable interpreter-level creation trace); then capture a common creation or
list-insertion boundary; then compare the same bounded `SendItemInfo` window.
Only a reproducible first divergence may authorize a production patch. The
native local-online baseline is still accepted locally, while full gameplay,
rollback quality, desktop interoperability, physical acceptance, and live
service remain unverified.

## Iteration 34: full-interpreter trace is not a practical runtime path

The reference lab gained an opt-in callback in the actual interpreter
`SingleStepInner` boundary, eliminating the earlier JIT-translation timing
gap. A bounded full-interpreter run reached the synthetic Slippi matchmaking
flow, but the reference advanced only 180 observed frames in 95 seconds and
the controller observed **zero gameplay frames**. No item-spawn or item-packet
capture was produced. This is a runtime-speed limitation of the diagnostic
configuration, not evidence that native item creation or the reference game
is incorrect. [Redacted control evidence](artifacts/slippi-feasibility-2026-09-10/reference-interpreter-spawn-control.json).

The native side independently reached the fixture and produced its bounded
diagnostic output, but it stopped advancing at frame 8 after the synthetic
peer's incomplete session; that run is not a native gameplay acceptance pass.
The interpreter callback remains private and opt-in for a future targeted
trace, but repeating a 95-second full-interpreter lab without a state-control
mechanism is not the next action. The next gate is a deterministic,
same-role/same-input state handoff or a faster interpreter/fallback trace
limited to the item creation/list boundary. No production code change is
authorized by this control.

## Iteration 35: native host integrated into the main app target

The main Xcode target now contains the reusable native Slippi host and its
device-only account handoff. The home screen presents **Original Melee** and
**Slippi Multiplayer** as separate responsive cards. Original Melee keeps the
existing standalone runtime. On iPhoneOS, Slippi stops that singleton runtime,
uses the same `CAMetalLayer`, copies only normalized account fields into an
isolated per-run `Slippi/user.json`, and forwards the existing merged controller
snapshot into Slippi's pad bridge. Exit-to-Home stops either runtime before a
new one starts. The Simulator builds a harmless host stub and retains the old
fixed-delay lobby route for regression coverage; it does not pretend to provide
native Slippi online play.

The first iPhoneOS link exposed three integration boundaries and they are now
resolved narrowly: Direct-code constants have explicit storage; the app target
matches the prebuilt core's C++23/no-exceptions libc++ contract; and device
linking uses a non-force-loaded archive response so replacement Slippi objects
do not collide with the original Dolphin objects. Simulator and iPhoneOS Debug
builds both pass with code signing disabled. The iPhoneOS artifact is an
unsigned arm64 app containing the Slippi host, but it has not been installed or
executed on hardware in this iteration.

The dedicated Simulator launch was exercised through the home screen, Slippi
setup alert and account document picker, then cancelled cleanly. This verifies
the product route and picker wiring only. It does not import an account,
execute the native host or contact a service.

The required native offline subset remains the strongest fresh runtime proof:
`boot-native-required-017` advances 118 frames with no JIT and zero captured
memory/graphics errors. The private Direct candidate remains linked but
unsigned, uninstalled, unexecuted and unauthenticated. Therefore the project
is **not yet online-working**. The next executable gates are: run the signed
main app on a test device, import a distinct real account through the UI, start
an arranged Direct session against a separate standard desktop account, and
capture a complete match/rematch with packet/state comparison. The Normal Lag
Reduction code group also remains an explicit shipping decision: compile its
native region or keep the currently proven required subset and document the
boundary.

[Fresh native required boot](../ref/slippi-compatibility/boot-native-required-017/results.json)
and [private Direct candidate](../ref/slippi-compatibility/ios-direct-005/results.json)
remain the source/runtime evidence; the unsigned app build and Simulator launch
are local workspace validation outputs.

## Iteration 36: signed main-app hardware launch and online gate audit

The main MeleePad target was built for iPhoneOS Release, manually signed with
the existing Apple Development identity and a matching app-specific
`application-identifier`, then installed as `com.meleepad.MeleePad` on the
paired iPad Pro (12.9-inch, sixth generation). The bundle was not previously
installed on that target, so this was a new-container install; no existing
MeleePad save or game-data container was replaced. `devicectl` confirmed the
installed bundle and the app launched in the foreground.

QuickTime wired mirroring visibly confirmed the actual iPad home screen: the
Original Melee card and Slippi Multiplayer card both rendered, with the
expected game-data and account setup actions. This closes the main-app signed
install and physical home-surface gate. It does not establish game boot,
account acceptance, matchmaking, peer connection, rollback, or crossplay.

An attempt to provision the local v1.02 extracted game data into this new app
container using recursive CoreDevice copy remained silent for approximately
two minutes and was cancelled. No error or app reinstall followed. The
repository's prior evidence identifies the wired House Arrest/AFC path as the
reliable fallback, but an existing stale AFC process for another app currently
owns that device service and was left untouched to preserve concurrent work.

The current blocker is therefore explicit and finite: provision the user's
matching v1.02 game root, ISO and iOS module into this app's private container;
import the user's own Slippi account through the app's Keychain flow; then
exercise the native Slippi menu with a distinct arranged desktop account. The
native source path already contains matchmaking and rollback code, but no
online claim is valid until that end-to-end path produces a real Direct match,
complete match/rematch, and clean disconnect evidence.

## Iteration 37: matching asset audit and device-service contention

The private workspace contains the matching USA v1.02 image and extracted root:
the image and root both identify as `979c42a2…` and match the v1.02 module
identity. The separately indexed OpenEmu image identifies as v1.00, so it is
not a valid input for the v1.02 Slippi path and was not sent to the device.

The device-copy gate was retried with the matching image and with a tiny
non-game transfer. Both CoreDevice and the direct House Arrest client were
blocked while another task held a long-running device session; the session was
released without terminating that app or touching its data, but the transport
then returned `Connection interrupted` and the bounded retry timed out. No
game data or credentials were imported. The signed app therefore remains at
the physical home screen, not at native game boot.

The next loop action is to retry the matching image transfer only after the
device service is free, then use MeleePad's importer to derive its private
`GameData-r2/GALE01` root. The subsequent gates are account import, a real
arranged Direct opponent, and complete match/rematch/disconnect evidence. The
public Unranked path stays disabled as an acceptance claim until Direct is
proven.

## Iteration 38: first-run device controls and the acceptance loop

The first-run path was audited against the actual acceptance task rather than
the presence of native symbols. Three wrapper defects were found and fixed:
fresh Home → Slippi launches now start the shared 60 Hz input consumer, the
in-game overlay remains visible so touch controls and Exit to Home are usable
while Slippi owns the render layer, and host teardown reaps a completed worker
before its `std::thread` is destroyed. The last issue could otherwise terminate
the app after a finished or failed native run. These are source/build fixes,
not evidence of a match.

The active goal loop is now deliberately linear:

1. **Provision:** transfer only the matching USA v1.02 image/root and the
   signed v1.02 module into the current app container; verify identity and
   preserve the existing container.
2. **Boot:** launch the signed app, import/select the data through MeleePad,
   start Original Melee and prove a rendered interactive frame, then return to
   Home.
3. **Native Slippi:** import the user's own `user.json` through the UI,
   start Slippi on-device, prove native startup and touch/controller input,
   then return to Home and relaunch once to exercise teardown.
4. **Direct acceptance:** use two distinct normal accounts and an arranged
   Slippi Direct code; capture peer negotiation, rollback/gameplay frames,
   completed results, rematch, and clean disconnect/reconnect.
5. **Expansion:** only after Direct passes, decide full code-set/Normal Lag
   Reduction parity and test Unranked/service discovery. Until then, claims are
   limited to the verified native subset and the physical product shell.

At each iteration, stop at the first failing gate, record the exact artifact,
device, and error, fix only that gate, rebuild/install in place, and repeat the
same gate. Do not substitute a simulator lobby, a synthetic peer, a boot probe,
or an empty online menu for a real match.

## Handoff checkpoint: 2026-09-11

This stopping pass rebuilt the corrected source successfully for iPhoneOS and
iOS Simulator Release configurations:

- device artifact: `/tmp/meleepad-slippi-device-release-iter38/Build/Products/Release-iphoneos/MeleePad.app`
- simulator artifact: `/tmp/meleepad-slippi-sim-release-iter38/Build/Products/Release-iphonesimulator/MeleePad.app`
- `git diff --check`: passed

The latest corrected app shell was installed in place on the iPad and launched
successfully. The bounded CoreDevice temporary-file probe still acquired the
tunnel but stalled in developer file services and timed out after 45 seconds,
so no game image, extracted root, account, or credential was copied or removed.
The physical app evidence therefore remains limited to the two-card Home
surface; the current foreground mirror was left to another active device task.

Current truth at handoff: native Slippi source is linked and the required
offline subset has separate no-JIT evidence, but the main app has no physical
game boot, account-authenticated Direct session, rollback match, rematch, or
Unranked proof. Resume at Provision gate 1 when the device file service is
available; do not repeat the same stalled transfer or claim the game is online
until gates 2–4 produce their stated evidence.

## Iteration 39: iOS runtime factory reaches the physical device

The first physical QA launch exposed a build-graph defect rather than a data
or Slippi defect: Xcode compiled the app target's replacement
`dolphin_runtime.cpp` without `MODERNGEKKO_HAVE_IOS=1`. Its `Runtime::Create`
therefore had no iOS platform branch, and the device reported
`the requested Dolphin host platform is unavailable`. The per-file Xcode
compiler flags now define the iOS branch explicitly; the existing CMake-built
archive already contains `PlatformIOS.mm`.

Release iPhoneOS build `/tmp/meleepad-xcodebuild-iter40` passed with signing
disabled. Its runtime object references both `Platform::CreateIOSPlatform()`
and `Platform::CreateHeadlessPlatform()`, and the final app contains both
factories. The matching private QA bundle was signed with the existing Apple
Development identity; `codesign --verify --deep --strict` passed.

That bundle was installed in place on the paired iPad Pro 12.9-inch (6th
generation), retaining MeleePad's container database UUID
`979047F1-0409-46A6-9D7E-8A7042696DB0`. The device console then proved the
actual v1.02 path: provisioned root, `GALE01-r2.iso`, and
`gGALE01r2_recomp.dylib` were found; `runtime created` was logged; the module
loaded; and the native Metal runtime reported `fps=59.9`, `vps=59.9`,
`graphics frames=1189`, and an Apple M2 GPU. A single optional memory-map
allocation logged `Failed to allocate memory space: 0x3`, but the runtime
continued rendering; this is recorded as a follow-up diagnostic rather than
silently treated as a clean zero-error run.

This closes physical native boot/rendering for the private v1.02 build. It
does **not** close Slippi online: no user account was imported, no standard
peer negotiated, and no rollback match/rematch/disconnect evidence exists.
The next gate is the user's explicit `user.json` import followed by a real
arranged Direct session against a distinct compatible Slippi peer. The private
QA bundle and game data remain outside Git and are not a public release.

## Iteration 40: repeat physical native boot and close the platform-fix loop

The corrected iPhoneOS Release target was rebuilt again at
`/tmp/meleepad-xcodebuild-iter40`. The final executable contains both
`Platform::CreateIOSPlatform()` and `Platform::CreateHeadlessPlatform()`, and
the private QA bundle passed `codesign --verify --deep --strict`. It was
installed in place on the same iPad with the same MeleePad container database
UUID, `979047F1-0409-46A6-9D7E-8A7042696DB0`.

A fresh CoreDevice console launch on iPad14,5 / iPadOS 26.6.1 reached
`runtime created`, loaded `gGALE01r2_recomp.dylib`, initialized CoreAudio, and
reported `fps=59.9`, `vps=59.9`, `speedRatio=1.000`, zero frames over 20 ms,
zero audio DMA underruns, and the Apple M2 GPU. The optional
`Failed to allocate memory space: 0x3` diagnostic remains, but the process
continued rendering until it was intentionally terminated. An attempted
wrapper-level override for that optional 64-GiB map caused a SIGSEGV before
runtime creation and was fully reverted; it is not part of the accepted fix.

The repository-wide regression suite passed after the revert. This repeats
and closes the physical native v1.02 boot/render gate, but does not change the
online status: no account was imported, no standard peer negotiated, and no
rollback match/rematch/disconnect evidence exists. The next gate remains an
explicit user-owned account import followed by an arranged Direct session with
a distinct compatible Slippi peer.

## Iteration 41: separate the native Slippi module path and remove the session watchdog

The main app no longer resolves the ordinary recompiled game module for both
cards. `MeleePadGameViewController` now selects ordinary modules and native
Slippi modules through separate revision maps and bundle-relative paths. On a
device Slippi v1.02 therefore requires `gGALE01r2_slippi_recomp.dylib` (or an
explicit `DeviceBundledSlippiModuleRelativePath`) plus its matching original
DOL identity sidecar. A missing Slippi module is reported as such instead of
silently falling back to the ordinary module.

The deterministic `-meleepadSlippi` launch argument was added for device
acceptance. It sets the same Slippi request flags as the home-card action but
still enforces game-data, module, account and Keychain gates. The shared native
probe's old unconditional 900-second watchdog was removed for normal app
sessions; the bounded account-boot probe retains its 45-second deadline, so an
active match or rematch is no longer terminated by an arbitrary timer.

Release iPhoneOS build `/tmp/meleepad-xcodebuild-iter44` passed with signing
disabled and still contains both iOS and headless runtime factories. A private
QA bundle was signed with the existing development identity, installed in place
on the iPad, and retained database UUID
`979047F1-0409-46A6-9D7E-8A7042696DB0`. The device console then logged:
`boot module kind=slippi file=gGALE01r2_slippi_recomp.dylib` after finding the
provisioned v1.02 root and disc. This proves the main app reaches the intended
Slippi module-selection/account gate on physical hardware; it is not gameplay
or online proof because no user-owned account was imported and no peer was
negotiated. The accepted separate iPhoneOS module was generated from captured
Slippi patched text/GCT and has not yet completed a full main-app iPad run.

The lobby source contract test and full repository checks remain required after
this source change. The next executable gate is an explicit user-owned
`user.json` import, followed by a real arranged Direct match, rematch and clean
disconnect against a distinct compatible Slippi peer.

## Iteration 42: baked Normal Lag Reduction does not clear the native failure

To isolate whether the two Normal Lag Reduction writes were failing because
they were applied by the runtime Gecko handler, a private macOS native module
was rebuilt from the captured v1.02 Slippi DOL with these exact guest-word
replacements compiled into the native text:

- `0x803761EC`: `4180001C` → `4800001C`
- `0x80376238`: `41820018` → `48000018`

The module linked successfully as arm64 macOS (`gGALE01_recomp.dylib`, 80 MiB)
and was run through the existing no-JIT boot harness using the owner-supplied
v1.02 image. The required subset still passed with 102 frames and zero memory
or graphics errors. Both `required-normal` and `full` still stopped at frame 2
with 84 invalid reads. This rules out those two branch replacements as the
complete fix; no generated private module was copied into the app or staged
for release.

This iteration makes the production boundary intentional rather than
accidental: `slippi-direct-probe.cpp` verifies that all six GameINI groups are
present, then enables only **Required: General Codes**, **Required: Slippi
Recording**, and **Required: Slippi Online**. It does not claim Normal Lag
Reduction or full-code parity. The online gates are unchanged: the physical
main app has selected the separate Slippi module, but still lacks the user's
account import, an arranged standard peer, a real rollback match, rematch, and
clean disconnect evidence.

The source-only diagnostic log was then rebuilt into `/tmp/meleepad-xcodebuild-iter45`,
signed with the existing development identity, and installed in place on the
same iPad. A fresh `-MeleePadGameRevision 2 -meleepadSlippi` launch found the
provisioned v1.02 root, ISO, and `gGALE01r2_slippi_recomp.dylib`, then logged
`native Slippi start blocked reason=account-missing` before creating a runtime.
The process was terminated intentionally after this bounded gate check. The
MeleePad database UUID remained `979047F1-0409-46A6-9D7E-8A7042696DB0`.

## Iteration 43: make the prepared iPhoneOS build boundary explicit

The Xcode target consumes generated and private material under `ref/`, while
those artifacts are intentionally ignored and are not a fresh-checkout source
distribution. A new `scripts/check-ios-slippi-build-inputs.py` preflight now
enumerates the target's literal generated paths, the required native Slippi
overlay sources, the separate packed-float source, and every archive named by
the iPhoneOS linker response. It reports the complete missing set without
reading game or account data. In this prepared workspace it passed with **90
required paths**; `scripts/ios-provision.sh device` runs the same check before
writing the local linker/configuration files.

The local machine also contains the owner's existing official Slippi account
export at the expected desktop Dolphin location. Its contents were not added
to Git, printed in diagnostics, or copied into the app bundle. A bounded
read-only AFC connection to the paired iPad timed out because another
long-lived session owns the device file service; that session was left running
and no account or game data was changed. The main app therefore remains at the
same physical gate: the native Slippi module is selected, but its device-only
Keychain account is still absent.

The preflight and device provisioning check pass, and the existing iPhoneOS
Release build remains valid. This does not change online status: there is still
no authenticated main-app Slippi runtime, arranged distinct peer, Direct
match, rollback match, rematch, or clean reconnect evidence. Resume at account
import when the device service is free; do not kill the unrelated AFC session
or substitute a duplicate/synthetic account.

## Iteration 44: verify the private account-to-native-runtime handoff on iPad

The private device acceptance path now supports a bounded QA-only
`-meleepadSlippiAccountImportTest` argument. It reads an injected account file
from the app sandbox, sends it through the same normalization and device-only
Keychain store as the document picker, and deletes the inbound plaintext file
before starting Slippi. The desktop account export remains outside Git and
outside the app bundle. The latest prepared-input preflight passed with **91
required paths**, including the pinned Slippi `GALE01r2.ini` used when the
native module is staged.

The iPhoneOS Release target rebuilt successfully at
`/tmp/meleepad-xcodebuild-account-telemetry`. A private QA bundle containing
the locally prepared v1.02 game root, retained disc image, and separate
`gGALE01r2_slippi_recomp.dylib` was manually signed with the existing
development identity. It was installed in place on the paired iPad, retaining
database UUID `979047F1-0409-46A6-9D7E-8A7042696DB0`.

The fresh physical launch on iPad14,5 / iPadOS 26.6.1 found the provisioned
game root and ISO, selected the Slippi module, initialized CoreAudio, loaded
the native module, and reached clean worker shutdown (`native Slippi host
finished exit=0`). The bounded report recorded:

- `account_file_loaded=1`, `boot_error=0`, JIT disabled;
- zero captured memory or graphics errors;
- zero Direct searches and denied searches;
- `code_subset=required`, with only General Codes, Slippi Recording, and
  Slippi Online enabled after verifying all six pinned groups are present;
- no game-start, game-end, or frame-bookend events because this acceptance run
  stopped at the native menu and did not navigate into a match;
- `crossplay_accepted=false`.

The report's account flag means the local Keychain-to-runtime handoff happened;
it is not a Slippi service-authentication result. The raw inbound cache file
and the runtime's temporary `User/Slippi/user.json` were both absent after
teardown. Repeated SMC chunk-mismatch diagnostics (23 failed chunks) remain a
known warning from executing the patched guest code; they did not increment
the captured memory/graphics error counters, but full-code and Normal Lag
Reduction compatibility remain unverified.

This closes the physical native Slippi boot and private account handoff gates.
It does **not** close online gameplay: no Service Direct ticket, authenticated
server response, distinct arranged peer, rollback match, rematch, clean
disconnect, crossplay, or Unranked evidence exists. A real arranged peer and
manual device navigation are still required before claiming that Slippi works
online. Do not enter a public queue or duplicate the same account across two
peers merely to manufacture a pass.

## Iteration 45: close the public IPA host-path packaging gate

The first public-package attempt correctly rejected the fresh iPhoneOS app
because the linked Slippi Rust archive contained the local Cargo registry path
from `ring` and precompiled `compiler_builtins` objects. This was build metadata,
not game data or an account credential, but it still violated the public bundle
boundary. Rebuilding the pinned Rust workspace with the installed Rust 1.88
toolchain, remapping project and registry paths, compiling the `ring` C/assembly
objects with prefix maps, and stripping only object debug sections removed the
private strings while retaining all 806 archive members.

The sanitized archive was used only in a throwaway link. The unsigned iPhoneOS
Release app rebuilt successfully, the original ignored private archive was
restored byte-for-byte, and `scripts/package-public-ios-ipa.sh` produced and
ZIP-tested `/tmp/meleepad-public-sanitized.ipa`. The package identity audit
passed with no findings; the packaged app contained no module, ISO, save,
profile, signature, `/Users/` path, or `/tmp/meleepad` path in the packager's
Mach-O string scan. This is public-shell evidence only; the IPA remains
intentionally module-free and not playable.

The runtime gate is unchanged. The physical iPad run proves native Slippi
module load, CoreAudio initialization, account handoff into the device-only
Keychain/runtime path, zero captured memory/graphics errors, and clean native
worker shutdown. It still has zero game starts/bookends and zero Direct
searches. No service ticket, authenticated server response, distinct peer,
rollback match, rematch, clean disconnect, crossplay, or Unranked result has
been observed. A second legitimate Slippi identity and an arranged compatible
peer remain required for the online claim; do not manufacture one or enter a
public queue merely to make the counters nonzero.

## Iteration 46: expose the supported Unranked search path

The native EXI adapter was still rejecting every matchmaking mode except
Direct, even though the linked Slippi client contains the standard Unranked
path. The guarded acceptance policy now permits Unranked with its required
empty connect code and Direct only with a bounded, printable arranged-opponent
code. Ranked, Teams, and Party remain rejected until their separate service and
gameplay lifecycles are accepted. Telemetry now distinguishes Direct and
Unranked search attempts.

The gate test passed with 15 checks. The main iPhoneOS Release target rebuilt
successfully after the change. A newly signed private QA bundle was installed
in place on the same iPad and retained database UUID
`979047F1-0409-46A6-9D7E-8A7042696DB0`. Its bounded native Slippi account boot
recorded `boot_error=0`, zero captured memory/graphics errors,
`account_file_loaded=1`, JIT disabled, and clean worker completion; the
temporary account cache and runtime `User/Slippi/user.json` were absent after
teardown. No input was injected, so search and game counters correctly stayed
zero.

This enables the intended Unranked route in the client but does not claim that
the service accepted a ticket. A real account-backed Unranked or arranged
Direct run still needs manual game-menu navigation, a compatible peer where
applicable, and evidence of the service response, netplay connection,
rollback, match end, and clean disconnect.

## Iteration 47: prevent stale private overlays from regressing the search gate

The iPhoneOS Slippi preflight previously verified only that the generated
overlay paths existed. It now also checks three non-sensitive source markers
in `Core/HW/EXI/EXI_DeviceSlippi.cpp`: the guarded search predicate, the
Unranked/Direct rejection message, and the separate Unranked telemetry
counter. An old Direct-only overlay therefore fails before Xcode compiles it,
instead of producing a misleading app that appears to contain the new route.

The updated preflight passed with 91 required paths and no invalid contracts.
`bash scripts/check-repository.sh` passed, `git diff --check` passed, and a
fresh unsigned iPhoneOS Release build completed successfully at
`/tmp/meleepad-xcodebuild-preflight`. The change is tracked in commit
`2869a78` (`Guard prepared Slippi overlay contract`).

This improves build reproducibility only; it does not advance the online
acceptance gate. The latest physical report still has zero searches and zero
game bookends because no menu input was injected. A distinct legitimate peer,
manual navigation, service response, rollback match, rematch, and clean
disconnect remain necessary for a real online claim.

## Iteration 48: align the native entry surface with the accepted modes

The main app's Slippi card and native boot status previously described the
account-ready path as Direct-only. They now identify the actual guarded
capability as **Unranked + Direct** and use neutral opponent-waiting status
text. This keeps the two-pane home surface and the native runtime's visible
state consistent without implying that a service ticket or match has already
been accepted.

The iOS Online Play source-contract test passed and the unsigned iPhoneOS
Release target rebuilt successfully at `/tmp/meleepad-xcodebuild-final`.
The UI-only change is tracked in commit `86a60fc` (`Align Slippi status with
supported modes`).

## Iteration 49: reproduce the private native candidate from pinned evidence

The private candidate builder was rerun with the accepted iPhoneOS link
evidence (`ios-link-002`), its referenced boot evidence (`game-delay-003`),
the accepted iPad probe base (`ios-app-012`), and the current iPhoneOS static
runtime. It compiled the native Slippi sources, iOS host, and packed-float
adapter into a new ignored candidate at
`ref/slippi-compatibility/ios-direct-007`.

The candidate record reports `permitted_search_mode=Unranked/Direct`,
`code_subset=required`, bundle identity audit pass, unchanged shared archives,
and `signed=false`, `installed=false`, `executed=false`, and
`service_authentication_tested=false`. This closes the private candidate
rebuild/relink check, but it is not an online result and must not be packaged
or distributed with game data or credentials.

## Iteration 50: reproduce the Normal Lag Reduction failure on the locked chain

The next native diagnostic reran `required-normal` from a fresh ignored output
directory using the same accepted component probe, v1.02 ISO, native module,
Rust archive and no-JIT runner as `boot-native-required-017`. The result is
unchanged: exit 8 after two frames, 84 invalid memory accesses, zero graphics
errors, no late frame progress, one Slippi EXI device, and
`jit_enabled=false`. The module hash is
`024ecbd65d39751b66831b0556d887c4af562bf5e18c7fc248f008dbec7ee1a6`.

The first invalid writes are at guest PC `0x80343680`, followed by invalid
reads through the same null-object path (`0x803436d0`, `0x803881a4`,
`0x8034370c`, and related PCs). This is a fresh reproduction of the earlier
Normal Lag Reduction failure, not a new fix. No guessed branch replacement or
verification bypass was added. The shipping native subset therefore remains
General Codes + Slippi Recording + Slippi Online; Normal Lag Reduction and the
full six-group configuration remain open.

## Iteration 51: verify the current main-app candidate on the physical iPad

The current iPhoneOS Release target rebuilt successfully at
`/tmp/meleepad-xcodebuild-resume`, with the Slippi input preflight reporting 91
required paths. A throwaway APFS clone of the existing private QA app was
staged with the pinned Slippi GameINI and the newly linked iPhoneOS module from
`ios-direct-007`, then signed with the existing development identity. It was
installed in place on iPad14,5 / iPadOS 26.6.1 while retaining database UUID
`979047F1-0409-46A6-9D7E-8A7042696DB0`.

The main app launch resolved the module from its actual device-configured
`PrivateQA/gGALE01r2_slippi_recomp.dylib` path, found the retained v1.02 ISO
and game root, initialized CoreAudio at 48 kHz, and logged
`native Slippi host started revision=2` with the imported account present.
The newer candidate module was the one staged at that resolved path. The
bounded QA process was then terminated intentionally because the CoreDevice
console wrapper does not end a resident UIKit app. Its temporary plaintext
`User/Slippi/user.json` was removed and verified absent afterward.

This is current-main-app native boot/account evidence, not online acceptance:
the run supplied no menu input, so it produced no search, game, rollback,
rematch, disconnect, or crossplay result. The first staging attempt also
caught and corrected a normal (non-Slippi) GameINI being copied into the
throwaway bundle; the corrected rerun passed the native six-group guard.

## Iteration 52: verify ordinary input reaches the native Slippi menu

A small opt-in diagnostic fixture, `scripts/fixtures/slippi-login-menu-input.txt`,
sends one ordinary A press to the native Online Play menu at second eight. A
fresh required-group Metal run completed 102 frames with zero memory or
graphics errors and one observed menu command. The screenshot remains on the
native `1-P Mode > Online Play > Log-in` screen, confirming that the menu path
is rendered and stable under input; the account-free probe intentionally does
not attempt service authentication.

The remaining executable gate is therefore a real account-backed menu session:
manual controller navigation into Unranked or an arranged Direct search,
followed by a legitimate distinct peer for match, rollback, rematch and clean
disconnect evidence. No second identity is available locally, so no online
gameplay claim is made and no synthetic account is substituted.

## Iteration 53: close the native lifecycle and physical-run evidence loop

The private native candidate was rebuilt as `ios-direct-008` and the main
iPhoneOS target was rebuilt from this working tree at
`/private/tmp/meleepad-xcodebuild-final2`; the unsigned Release build completed
with `** BUILD SUCCEEDED **`. Focused probe, Python compilation, 91-path input
audit, iOS Online Play source contract, repository checks and `git diff --check`
also passed.

The physical iPad run used the retained private app and the explicitly signed
`PrivateQA/gGALE01r2_slippi_recomp.dylib`. The explicit module signature is
required because the nonstandard `PrivateQA` bundle path is not covered by
`codesign --deep`; the app then passed its native module preflight and loaded
the Slippi runtime. The latest exact-source run was
`9A29C4A3-FBAC-4AFE-87C9-B703077C50FC` at 22:51:24 on iPad14,5 /
iPadOS 26.6.1:
`worker_finished=true`, `exit_code=0`, `boot_error=0`, `memory_errors=0`,
`graphics_errors=0`, `account_file_loaded=1`, and `game_files_written=true`.
Its search and matchmaking counters were all zero, with zero games and zero
trace packets. The installed app database UUID remained
`979047F1-0409-46A6-9D7E-8A7042696DB0`.

The direct probe now resets its process-global counters between launches and
reports runtime readiness only after the native runtime has been created; the
main app no longer labels a pre-runtime launch as “waiting for an opponent”.
These changes make repeated-run evidence and visible status trustworthy, but
they do not create a service ticket or peer. The current result is therefore
native Slippi boot plus account handoff on physical iPad, not online gameplay.

The next and still-blocking acceptance step is an account-backed Unranked or
arranged Direct search that records a legitimate service response, distinct
peer connection, rollback match, result/rematch and clean disconnect. Until a
second legitimate identity/opponent and that service boundary are available,
the native runtime remains a private QA capability and the active goal stays
open. The original Melee path remains separate and working; the current main
app is a chooser with one active native runtime, not simultaneous left/right
gameplay panes.

## Iteration 54: reconcile the live iPad retry without overstating acceptance

The focused native candidate was installed in place on the paired physical
iPad and launched with the account-backed menu probe. The app loaded the
bundled v1.02 disc, Slippi bootloader and private GALE01 resource pack,
including `MxScn.dat`; the native worker finished cleanly with
`boot_error=0`, `memory_errors=0`, `graphics_errors=0`,
`account_file_loaded=1`, and `exit_code=0`. The retry's final screenshot was
still the Slippi character-selection screen, so its search counters remained
zero. This is a bounded menu-input retry result, not a completed online-match
result and not a regression of the earlier search proof.

The strongest current physical acceptance evidence remains the prior direct
run: the iPad visibly reached `Searching for opponent`, and its structured
report recorded `unranked_searches=1`, `matchmaking_initializing=1`, and
`matchmaking_ticket_ready=1`, with `matchmaking_connected=0`, zero games and
zero rollback packets. The live retry was terminated after report collection;
an unrelated SlippiProbe process on the device was left untouched.

The active goal therefore remains open at the same precise boundary: native
Slippi boot, resource loading, account handoff, menu rendering and ticket
creation are demonstrated on the physical iPad; a legitimate distinct peer,
opponent connection, rollback gameplay, rematch and clean disconnect are not.
The simulator can continue validating the original/fixed-delay surface, but
it cannot validate this device-only native Slippi path.

## Iteration 55: verify the simulator boundary explicitly

The current Release target also built successfully for arm64 iOS Simulator
and launched on the dedicated MeleePad Netplay iPad simulator. The captured
home screen shows the two experience cards: Original Melee is installed, while
Slippi Multiplayer is correctly setup-gated with `Import your own Slippi
user.json`. This confirms the intended boundary in the runnable artifact:
the simulator can validate the chooser and legacy/fixed-delay surface, but it
does not claim to execute the native iPhoneOS Slippi runtime or prove online
play.

## Iteration 57: verify the normal physical entry point

The installed private candidate was launched on the paired physical iPad with
no QA arguments. `devicectl` returned `outcome=success` and a process ID for
the installed `com.meleepad.MeleePad` bundle, confirming that the ordinary
product entry point launches independently of the scripted native probe. The
newly launched process was terminated after verification; pre-existing
processes from other device work were not touched.
