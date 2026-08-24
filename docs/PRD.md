# ssbmpad PRD: Super Smash Bros. Melee, native on Apple platforms

Status: approved for autonomous execution. Written 24 Aug 2026.
Audience: an autonomous agentic system with full control of a macOS machine.
Companion document: `docs/GOAL-LOOP.md` (the operating loop). Read both before doing anything.

---

## 1. Objective

Build **ssbmpad**: a native ARM64 port of Super Smash Bros. Melee (GameCube, GALE01) for Apple platforms, using static recompilation of the retail `main.dol` (DolRecomp) running against the ModernGekko runtime (Dolphin-derived: GX video via Metal, audio, DVD, PAD, HLE). This is the exact stack that already shipped Super Mario Sunshine as **sunpad**, which is your reference implementation and lives in `ref/sunpad`.

Order of delivery:

1. Melee running natively on **macOS** (Apple Silicon), playable, sustained 60 fps.
2. The same core running in the **iPadOS and iOS Simulators** (no JIT, interpreter fallback for uncovered code, software vertex loader).
3. **SunPad's touch controls and menu system ported over** as the ssbmpad shell: touch overlay, three-dot menu, settings, game data import, diagnostics logging, experimental-mode framework.
4. **End-to-end testing** per Section 10, with dated evidence for every claim.

60 fps is a hard requirement, not a gate with a fallback. If the frame budget is missed, the response is profiling and optimization, iterated until it is met. Do not propose substitute titles or reduced targets.

## 2. What "done" means

All of the following, each backed by evidence per Section 11:

- D1. macOS app boots Melee to the title screen, through the character select screen, into a 1v1 match, with working input, video, and audio.
- D2. macOS worst-case frame interval is inside 16.7 ms, including audio, sustained through a 1v1 on a flat stage (Final Destination) AND on Fountain of Dreams (the known heavy stage). Measured, not asserted.
- D3. iPadOS Simulator build and iOS Simulator build both boot to gameplay with the same core. Simulator performance numbers are recorded but are diagnostic only; the Simulator is not representative hardware, and the 60 fps requirement is judged on the macOS native build.
- D4. Touch controls and the menu system, ported from sunpad, work in the iPadOS Simulator: overlay renders, buttons and sticks drive gameplay, three-dot menu opens with resolution / aspect / layout-edit / game data / diagnostics entries, diagnostic log export produces a file.
- D5. The full test matrix in Section 10 has a Pass with evidence on every row.
- D6. `docs/` contains the journal, evidence, and status documents described in Section 11.

Explicit non-goals for this build: physical-device deployment and IPA packaging (Chris does device testing himself afterward), App Store anything, netcode/Slippi integration, widescreen or texture enhancement, versions other than the ROM provided.

## 3. Why this is feasible (validated 24 Aug 2026)

You are not the first mile on this road. Verified facts you should rely on:

- **The substrate shipped.** sunpad runs Super Mario Sunshine on a physical iPad via DolRecomp + ModernGekko at ~37% upstream decomp. Decomp percentage does not gate this route: DolRecomp reads the retail DOL directly.
- **Melee is structurally the easy case.** It is a single `main.dol` with zero REL overlay modules (verified: `doldecomp/melee` config has no `modules:` key, no `OSModule` entries in splits). Game data lives in DAT/HSD archives, not code overlays.
- **Melee needs no emulation hacks.** Dolphin ships no per-game `[Core]` or `[Video_Hacks]` overrides for GALE01; its INIs contain only cheat sections.
- **60 fps on Apple Silicon is already proven under a worse execution path.** Slippi's macOS wiki: M1 machines run Melee under Rosetta 2 translating an x86-64 JIT emulator, "surprisingly ... fairly well". Static recompilation removes both translation layers.
- **Known risks are enumerated, not open-ended.** They are SMC (Section 6, checked on day one), the 60 fps frame budget (Section 8), and Fountain of Dreams (Section 10). Nothing else in the route is novel relative to sunpad.

One caution: claims that a Melee recomp already exists (ModernGekko's Hall of Fame credit) were adversarially checked on 24 Aug 2026 and are unsubstantiated. No repo, release, video, or screenshot exists anywhere. Budget for being first past sunpad's prior art; do not go hunting for someone else's Melee module.

## 4. Environment and workspace

You have free reign on a macOS Apple Silicon machine. Expected tooling (verify each; install what is missing): Xcode 26.x with command-line tools, CMake, Ninja, pkg-config, Git, Python 3, ripgrep. `xcodebuild`, `xcrun simctl`, and the iOS/iPadOS Simulators must work.

Working directory layout:

```
docs/    This PRD, GOAL-LOOP.md, and everything you write: journal, status,
         evidence notes. artifacts/ for screenshots and captures.
ref/     Provided before you start:
           ref/<melee rom file>        the retail Melee disc image
           ref/sunpad/                 full clone of the reference implementation
         Everything you download goes here too: ref/ModernGekko, ref/DolRecomp,
         ref/ModernGekko-Template, ref/melee (doldecomp), ref/m-ex, etc.
```

Rules: never modify or delete the ROM or `ref/sunpad`. Treat `ref/sunpad` as read-only reference; your port lives in its own directories. Never commit or upload the ROM, extracted game data, generated modules containing game code, or save files anywhere. Do not push anything to a remote unless Chris has set one up and said so.

## 5. Inputs and repositories

### 5.1 The ROM

In `ref/`. Before anything else: identify the file, verify it is GameCube Melee (game ID `GALE01`), and record its revision byte and hashes (SHA-1, SHA-256) in the journal. Expected: NTSC-U v1.02, expected SHA-1 `08e0bf20134dfcb260699671004527b2d6bb1a45` (from the 24 Aug feasibility spike; verify against the actual file, and if it differs, record what you actually have and proceed). v1.02 is preferred because the community tooling (m-ex, UnclePunch, Slippi) targets it. Supported input formats follow DolRecomp/ModernGekko-Template: raw ISO/GCM.

### 5.2 The reference implementation: ref/sunpad

This is the proof of process. Before writing any code, read, in order:

1. `README.md` (build commands, project structure, touch controls, menu, logging)
2. `docs/ARCHITECTURE.md` (the three-tier model; the iOS no-JIT design, verbatim: "iOS/iPadOS: runtime PowerPC JIT is forbidden. Static-recomp fallback uses the interpreter, and the generic software vertex loader replaces Dolphin's ARM64 code-generating loader.")
3. `docs/BUILDING.md`, `docs/DEPENDENCIES.md` (pinned upstreams and patch snapshots)
4. `docs/TESTING.md` (evidence rules you will adopt wholesale)
5. `docs/APPLE-PERFORMANCE-RESEARCH.md` (the single-host-thread ceiling; what was tried; what broke)
6. `docs/IOS_IPADOS.md`, `docs/MACOS.md`, `docs/KNOWN_ISSUES.md`, `docs/TECH-DEBT.md`, `docs/HANDOFF.md`, `docs/AUDIO_ISSUE.md`, `docs/LEGAL_AND_PROVENANCE.md`
7. `scripts/` (bootstrap-dependencies.sh, prepare-game.sh, ios-build-core.sh, ios-simulator-toolchain.cmake, package-macos-app.sh, gcpipe.py, stage1-run.sh, sunpad-capture.py)
8. `patches/` (the complete Apple-runtime patch snapshots for ModernGekko and its vendored Dolphin: this IS the iOS port, as patches)
9. `apple/` and `tests/` (the shell you will port in Phase 4 and the test style you will copy in Phase 5)

### 5.3 Repositories to fetch into ref/

Core toolchain (sunpad's `scripts/bootstrap-dependencies.sh` clones and pins these and applies the patch snapshots; prefer reusing that script or replicating its pins, and record any deviation):

| Repo | Role | Pin used by sunpad (docs/DEPENDENCIES.md) |
|---|---|---|
| `github.com/ExpansionPak/ModernGekko` | GameCube recomp runtime, Dolphin-derived | `048c426ba3db0369e40826d22ad3adcce7fe7c58` |
| `github.com/ExpansionPak/RecompCore` (branch `moderngekko-vendor`) | Vendored runtime core | `e13ab348f13cd67879f6db6e9d7185410f8f62c6` |
| `github.com/ExpansionPak/ModernGekko-Template` | Extract / recompile / run Makefile pipeline | `1ee85bb5e09c38f493a09f5fa6e9dc8228b23e42` |
| `github.com/ExpansionPak/DolRecomp` | Static PowerPC recompiler, DOL to C/LLVM | `93b881c8f73df1d64a88491f2aa50c7c9ed2384d` |
| `github.com/ExpansionPak/RecompCore` (top-level) | Upstream continuation reference | `af7a1a4854ee243b92926875e5a6b66663b0fda0` |

Newer upstream commits may exist; the pins above are known-good with sunpad's patches. Starting from the pins is the low-risk path. If you move a pin, you own re-basing sunpad's patches.

Melee-specific reference material (symbols and ground truth, NOT build inputs):

| Repo | What you take from it |
|---|---|
| `github.com/doldecomp/melee` (branch `master`) | Symbol names, function map, splits for GALE01. ~90% matched per the 24 Aug sweep. No LICENSE file at root: use for symbols/understanding only, do not vendor its code into ssbmpad. |
| `github.com/akaneia/m-ex` | Headers with function names, addresses, struct definitions for main.dol. Also indirect SMC evidence (Section 6). |
| `github.com/project-slippi/dolphin` | `Source/Core/Core/Slippi/SlippiSavestate.cpp`, `initBackupLocs()`: a hand-verified map of which GALE01 memory is mutable per frame, plus an exclude list. Also proof Melee's simulation is frame-deterministic at fixed 60 Hz. Reference only. |
| `github.com/Ploaj/HSDLib` | Understanding the DAT/HSD archive format if data-side debugging is needed. |
| `github.com/UnclePunch/Training-Mode` | Proof large code injection into v1.02 works; injection-point knowledge. |
| `github.com/aharonahdoot/StrikersRecomp` | Worked example of DolRecomp + runtime packaging (sunpad lists it as a dependency reference). |

Use function maps: DolRecomp accepts a symbol map for naming, and `doldecomp/melee` + m-ex give you one of the best symbol maps any GameCube title has. Named functions make every later profiling and debugging step cheaper. Wire this in from the start.

## 6. Phase 1 gate: the SMC check (day one)

DolRecomp does not handle self-modifying code: "SMC is currently unhandled. You will need to patch the functions manually." It flags suspicious instructions for manual review.

Before any build work, run DolRecomp's suspicious-instruction pass over Melee's `main.dol` and record the complete output in the journal. Expectation, not certainty: vanilla Melee is clean. The indirect evidence is that akaneia/m-ex advertises adding "execution of code stored within fighter and stage files" as an m-ex feature, implying vanilla does not do it. If the detector flags functions: identify each via the doldecomp/melee + m-ex symbol map, determine whether it is load-bearing, and patch manually per DolRecomp's mechanism (`DOLRECOMP_ENABLE_REPLACEMENTS`, `dolrecomp_dispatch_replacement`). This is expected, bounded work, not a stop condition.

## 7. Phase 2: recompile and macOS bring-up

The pipeline is ModernGekko-Template's, the same one sunpad used:

1. `make tools` (builds DolRecomp and ModernGekko), then `make run ISO=/path/to/melee.iso`. The template extracts to `extracted/<slug>/`, recompiles the DOL to C (default backend; `make llvm-run` for the LLVM backend later, when optimizing), compiles a native module cached by DOL hash and toolchain identity, and launches. After first extraction, use `GAME=<slug>`.
2. Controller config: ModernGekko has no in-app controller configuration UI. Hand-author or copy a working `GCPadNew.ini` into `~/.local/share/moderngekko/Config/` (Dolphin format). `ref/sunpad/apple/macos/default-GCPadNew.ini` and `default-config.ini` are working starting points; keyboard bindings are enough for bring-up.
3. Bring-up ladder, each rung with evidence: process launches and renders anything at all; intro/title screen; menus navigable with input; character select; 1v1 match on Final Destination; audio present and continuous.
4. Then package as a proper macOS app following `ref/sunpad/scripts/package-macos-app.sh` and `apple/macos/`, adapted to ssbmpad naming.

Reaching the title screen already exceeds all public GameCube-recomp prior art except sunpad itself (the most advanced public GameCube recomp, sp00nznet/ww, is stuck on its title screen). Do not treat early instability as evidence the route is wrong.

## 8. Phase 3: the 60 fps requirement (macOS)

Melee runs at 60 fps where Sunshine runs at 30: the frame budget is 16.7 ms. This is the project's one hard technical requirement and the main place prior sunpad findings matter.

Established findings from `ref/sunpad/docs/APPLE-PERFORMANCE-RESEARCH.md` (all measured on Sunshine; the direction transfers, magnitudes do not):

- The bottleneck is a **single host thread** (combined CPU-GPU thread) hitting its ceiling. At Sunshine's worst reproduced interval, real time required "roughly a 24% reduction in critical-path work".
- **Do not split CPU/video threads as a fix.** It recovered headroom, then produced CPU/GPU desync ("GFX FIFO: Unknown Opcode"). Recorded as unsafe.
- Cost centers found: generated game functions (up to ~43% in degraded intervals), paired-single/FP helper calls, software vertex loading (~7% in one degraded scene). Ranked optimization candidates: C-emitter FP fast paths, ahead-of-time vertex-format specialization.
- Audio was not a primary bottleneck on Sunshine, but DSP competes for the same thread; include it in every frame-time measurement.

Required approach:

1. **Measure first.** Melee's per-frame PPC instruction count relative to Sunshine's has never been published anywhere; producing it on this stack is genuinely new data. Profile with Instruments (Time Profiler) on the native build: worst-case frame interval, not averages, in menu, CSS, 1v1 Final Destination, 1v1 Fountain of Dreams, and a 4-player item match.
2. Record whether Fountain of Dreams pressure is CPU-bound or GPU-bound under Metal. It is the one stage with consistent community reports of drops in Dolphin; the reflective water is the likely EFB-heavy case.
3. Optimize in ranked order of measured cost. Levers, cheapest first: LLVM backend for the module (`make llvm-run`) with optimization flags; symbol-map-guided hot-function inspection; FP helper fast paths; vertex loader specialization; targeted manual replacement of hot recompiled functions (Melee's near-complete decomp means you can read the real source of almost any hot function by name).
4. Re-measure after every change; keep the frame-time history in the journal. Improvements here are shared infrastructure for every future 60 fps GameCube title; write them up clearly.

Expectations check: Melee (2001 launch-window title) already holds locked 60 fps on M1 through Rosetta 2 + x86 JIT, a double translation tax you do not pay, and runs near full speed on Snapdragon 865-class ARM under Dolphin's JitArm64. An M-series chip is several times that in single thread. The requirement is demanding but there is no evidence it is out of reach.

Melee-specific correctness bar: this audience measures frame timing. Interpreter stalls, uneven frame pacing, and input latency will be noticed. Frame-time evidence, not adjectives.

## 9. Phase 4: iPadOS/iOS Simulator, then the SunPad shell

### 9.1 Core in the Simulator

The iOS constraints and their solutions are already solved in `ref/sunpad`; port, do not reinvent:

- No runtime JIT on iOS/iPadOS. Recompiled module covers what it covers; everything else falls to the interpreter: "slower, never broken". The generic software (portable C) vertex loader replaces Dolphin's ARM64 code-generating loader.
- The module is built for the Simulator with the iOS toolchain (`ref/sunpad/scripts/ios-simulator-toolchain.cmake`, `ios-build-core.sh` pattern) as a `.dylib` (platform IOSSIMULATOR) loaded via `dlopen`.
- The Apple runtime patches live in `ref/sunpad/patches/ModernGekko/` and `patches/ModernGekko-dolphin/` as complete snapshots: CAMetalLayer surface, AppKit guards, cubeb/libusb/hidapi gating, JIT off. Apply, then adapt where Melee needs it.
- Rendering goes to a CAMetalLayer view (sunpad: `SunPadMetalSurfaceView`); Dolphin's Metal backend renders there.

Build both destinations, one Simulator at a time (see GOAL-LOOP.md): an iPad Simulator (primary) and an iPhone Simulator.

### 9.2 Porting the SunPad touch controls and menu

Port the shell from `ref/sunpad/apple/`, renaming SunPad → SsbmPad/ssbmpad throughout:

- `apple/shared/`: `SunPadSettings`, `SunPadInputState`, `SunPadInputMixer`, `SunPadControllerMapping`, `SunPadInputPipeEncoder`, `SunPadDiagnostics`. These are platform-neutral; port nearly as-is. Input reaches Dolphin via the pipe-input bridge (Dolphin Pipes device).
- `apple/ios/`: `SunPadGameOverlay` (touch overlay: main stick, C-stick, A/B/X/Y/Z/Start/L/R, D-pad), `SunPadGameViewController`, `SunPadCoreHost`, `SunPadDiscExtractor`, app delegate, Info.plist, PrivacyInfo.
- Melee-specific layout work, the only real design task: Melee's control demands differ from Sunshine's (C-stick smashes, L/R analog shielding with digital click, wavedash-era timing). Start from the sunpad landscape layout (left: movement stick, D-pad, L; right: C-stick, A/B/X/Y diamond, Z, R, Start) and adjust for Melee; keep the R pressure slider concept for analog shield, and add the same for L. Keep Move-mode drag customization, opacity/size settings, reset, and auto-hide on physical controller connect.
- Three-dot menu, feature parity with sunpad: render scale 1x-4x (live via `Config::GFX_EFB_SCALE`), aspect (original 4:3 default; 16:9 and Fill as experimental), touch layout edit/reset, Game Data & Saves (import/reimport/remove via Files), Share Diagnostic Log, Report a Problem, experimental toggles.
- Logging: replicate sunpad's diagnostics wholesale. Breadcrumbs (boot, display, controller, lifecycle, memory warnings, input-pipe, runtime warnings/errors, screenshot markers, runtime exit) to the unified log and `Library/Application Support/SsbmPad/Logs/runtime.log`; privacy-bounded export that excludes game images, extracted data, and saves.
- Experimental-mode framework: port the mechanism (default-off toggles, restart where required, logged mode identity like sunpad's `experimental-single-core-90` vs `stable`). Note the semantics flip: sunpad's "Experimental 60 FPS" toggle exists because Sunshine is a 30 fps title. Melee is natively 60; 60 is the default, not an experiment. Reuse the framework for whatever ssbmpad's own experiments are (e.g. underclock mode, perf scheduling), not the specific Sunshine toggles.
- GameController framework support with sunpad's slot semantics (slot retention, player-1 reclaim, held-input clearing on removal, touch auto-hide). Melee is a 4-player game: preserve sunpad's multi-slot handling and verify at least 2 physical/virtual controllers map to P1/P2.

## 10. Phase 5: test matrix

Adopt `ref/sunpad/docs/TESTING.md` rules verbatim, especially: "Compilation success is not gameplay success." "Run only one Simulator at a time on this machine." Capture dated evidence (target, OS, build config, git revision, game version, commands, logs, screenshots, result, remaining defects) for every row. Screenshots to `docs/artifacts/screenshots/<date>/`. Use `xcrun simctl io <device> screenshot`, sunpad's `gcpipe.py` pattern for scripted input injection through the pipe device, and `sunpad-capture.py` / `stage1-run.sh` as harness models. Automated input can drive menus and start matches; rows marked hands-on need real interactive play, and a PID or clean log alone never satisfies a gameplay row.

| # | Row | Target | Pass condition |
|---|---|---|---|
| 1 | Boot to title | macOS, iPad Sim, iPhone Sim | Title screen renders, no crash, evidence screenshot |
| 2 | Menu navigation | all three | CSS reached via input injection or touch |
| 3 | 1v1, Final Destination, 8 min | macOS (hands-on) | Completes; macOS worst-case frame interval ≤ 16.7 ms incl audio |
| 4 | Fountain of Dreams 1v1 | macOS (hands-on) | Playable; frame-time profile recorded; CPU vs GPU bound recorded |
| 5 | 4-player item match, Battlefield | macOS | Completes without crash; frame-time recorded (target 60, record honestly if short) |
| 6 | Classic mode, 3 stages | macOS | No progression blocker |
| 7 | Audio continuity | macOS + iPad Sim | Music + SFX through full Simulator audio stack, no sustained underrun |
| 8 | Save/memory card | macOS + iPad Sim | Name entry + settings persist across relaunch |
| 9 | Touch overlay drives gameplay | iPad Sim (hands-on) | Every control verified in-match; layout edit + reset works |
| 10 | Menu system parity | iPad Sim | Every menu entry functions; resolution + aspect apply live |
| 11 | Controller connect/disconnect | iPad Sim | Overlay hides/shows; P1 reclaim; no stuck inputs (port sunpad's controller tests) |
| 12 | Diagnostics export | iPad Sim + macOS | Log exports; contains breadcrumbs; excludes game data |
| 13 | Game data import flow | iPad Sim | ISO import via Files, validation, extraction, boot |
| 14 | Regression suite | repo | Ported equivalents of sunpad's `tests/` (input pipe encoder, diagnostics, controller mapping/slots, experimental config, touch layout defaults) all green |
| 15 | Clean-clone build | fresh dir | Full pipeline reproduces from scripts + pinned deps on a clean checkout |

Sunpad's iPhone finding transfers as a caution, not a requirement: iPhone 14-class was below par for Sunshine. iPhone Simulator rows need boot + input only; the iPhone tier judgment is Chris's, later, on hardware.

## 11. Evidence, journal, and reporting

Maintain in `docs/`:

- `JOURNAL.md`: append-only, dated. Every session: goal attempted, commands run, result, evidence path, next step. This is the handoff artifact if the run is interrupted.
- `STATUS.md`: current rung on the bring-up ladder, test-matrix state, open defects. Overwrite freely; keep current.
- `PERF.md`: every frame-time measurement with build config and scene; the Melee-vs-Sunshine instruction-count comparison when produced; optimization log with before/after numbers. Never state a performance number without a recorded measurement behind it.
- `artifacts/`: screenshots, captures, profiles, logs, organized by date.

Follow sunpad's HANDOFF.md rule: "Do not convert configured or source-inspected behavior into a physical-acceptance claim." The same discipline applies here between Simulator and hardware, and between compiled and played.

## 12. Legal, provenance, and wording

- The runtime is GPL-3.0-or-later (Dolphin-derived, like sunpad). Distribution is sideload; GPL is acceptable for this program and not a blocker. ssbmpad carries the same license and THIRD_PARTY_NOTICES pattern as sunpad.
- `doldecomp/melee` has no LICENSE file at root: symbols and understanding only; do not vendor its code.
- The repo and all artifacts you produce must contain no Nintendo-owned material: no ROM, no extracted assets, no generated module with game code, no saves. Port sunpad's `audit-ios-package.sh` / repository-check pattern to enforce this mechanically.
- Approved description wording, mandatory whenever the project describes itself (README, About screen): this is a static recompilation of the retail GameCube executable, running against a Dolphin-derived runtime for graphics, audio, and HLE. The user supplies their own legally obtained disc image. Unofficial; no Nintendo affiliation or endorsement. Do not describe it as an emulator, and do not describe it as emulator-free.

## 13. Risk register

| Risk | Standing | Response |
|---|---|---|
| SMC in main.dol | Expected clean (m-ex evidence, indirect); unverified | Detector on day one (Section 6); manual replacement path exists |
| 60 fps budget | The real work. Sunshine data says single-thread ceiling is reachable at 30 fps with ~24% headroom needed at worst case; Melee's cost is unmeasured | Section 8: measure, rank, optimize, iterate. No fallback target |
| Fountain of Dreams | Known heavy stage (community reports on Dolphin) | Dedicated matrix row; CPU/GPU-bound determination drives the fix |
| CPU/video thread split temptation | Known unsafe on this stack (FIFO desync, documented in sunpad) | Do not ship it; single-thread optimizations instead |
| Audio underruns | Sunshine had a physical-device audio verification gap | Simulator audio stack verified in matrix row 7; hardware is Chris's pass |
| Toolchain drift vs pins | Sunpad patches are snapshots against pinned commits | Start from pins; any pin move re-bases patches and is journaled |
| Melee community scrutiny | Frame-perfect audience | Ship frame-time evidence; PERF.md is the receipts |
