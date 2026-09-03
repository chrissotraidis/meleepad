# G5 deterministic savestate harness

## Problem

The rejected 64-bit gather-pipe experiment exposed a measurement flaw:
wall-time controller scripts can land on different emulated frames, and CPU AI
can then diverge even with no P1 input. The second control/candidate pair had
the same 7,431-row duration but differed by about 34,785 native dispatches per
frame. A shared emulator state is required before another small optimization
can receive a causal live verdict.

## Failing-before evidence

Dolphin's standalone no-GUI main installs `SIGUSR1`/`SIGUSR2` handlers that
call `Platform::RequestSaveState` and `RequestLoadState`. The branded
ModernGekko runtime uses a different entrypoint, so `SIGUSR1` terminated a
visually verified Fountain seed instead of saving it.

After the first handler-only build, the process survived and stderr confirmed
`[nogui] SIGUSR1: saving state to slot 1`, but no file appeared. The custom
runtime called `UICommon::SetUserDirectory()` and `UICommon::Init()` without
Dolphin's standard `UICommon::CreateDirectories()` step. `StateSaves/` did not
exist, so the asynchronous writer could not create its temporary file.

## Retained implementation

Patch `patches/moderngekko-dolphin/0013-runtime-savestate-signal-harness.patch`
does two general things in `src/runtime/dolphin_runtime.cpp`:

1. creates the standard Dolphin user-directory tree before UI initialization;
2. when `MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1` is set on a non-Windows,
   non-iOS host, installs scoped `SIGUSR1`/`SIGUSR2` handlers around the
   platform main loop.

The handlers only set Dolphin's existing platform request flags. The main loop
performs `State::Save`/`State::Load` in normal host context. Previous signal
actions are restored when `Runtime::Run()` exits. Normal launches and iOS are
unchanged.

The dependency bootstrap now uses the existing marker-aware composition rule
for the original SunPad runtime patch because patch 0013 intentionally edits
the same source file. Patch 0013 cleanly reverse-applies and reapplies and has
one-file scope.

## End-to-end proof

An isolated signed app used the retained paired-store module and the rebuilt
runner. With the environment toggle enabled:

- the runtime produced normal frames and remained alive after `SIGUSR1`;
- stderr confirmed the save request;
- `/private/tmp/ssb-tail.5OWsxL/StateSaves/GALE01.s01` was written at 9.2 MB;
- the local-only state SHA-256 was
  `8867a111130dcf42a329bcd384cca931004dbd98a5fcef19b42236e325e7401b`;
- emulation visibly advanced to a later attract scene;
- `SIGUSR2` logged a load request, the process remained alive, phase rows
  continued, and the visible attract sequence rewound to the saved branch.

The savestate contains live game RAM and is deliberately not committed. Only
ROM-safe screenshots are retained.

## Verification

- runner build: pass;
- focused CTest: 4/4 (frontend config, GameCube config, netplay protocol,
  memory-watcher utilities);
- `gcpipe`: 16/16;
- patch reverse/forward checks: pass;
- dependency bootstrap: pass;
- repository safety and diff checks: pass;
- isolated app strict deep codesign: pass;
- promoted signed runner SHA-256:
  `5121b6be59b19094f1995ec483626ff9a7206f73850ed2556aa144427c6dc546`;
- unchanged promoted module SHA-256:
  `2fe01870bfa0fbedc51aa20105ba0738c3b367e98c9566629001a8236e2fa1b3`;
- runner and module both declare macOS 14.0 minimum; the canonical packager
  preserved the prior app at
  `build-macos/MeleePad.app.previous.20260827-001935`;
- no booted Simulator.

## Decision and next experiment

**HARNESS RETAINED; G5 OPEN; G6 BLOCKED.** This does not improve FPS and is not
a G5 pass. It closes the comparison-method blocker. Next, create one visually
verified Fountain match state late enough to keep reruns short, load that exact
state into the canonical control and one distinct candidate, require aligned
frame/guest-cycle/native-dispatch counts, and only then evaluate performance.

## Evidence

- `docs/evidence/g5-savestate-harness/before-load.png` —
  `2960d34657f5ba4ad295378d77858de2a7f6c5ee9db2ffcb939e8d77fb9cefd0`;
- `docs/evidence/g5-savestate-harness/after-load.png` —
  `22a041a24e8b75677af0a952657b61bc2165c75a67e91d1c7544039c8e7593be`.
