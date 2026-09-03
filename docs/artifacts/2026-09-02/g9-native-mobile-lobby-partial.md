# G9 NL4 native mobile lobby first slice

Date: 2026-09-02

Result: **PARTIAL.** The exact iPadOS Simulator build now exposes a native
Online Play screen backed by the real platform-neutral netplay session. Hosting,
a Mac joining the native host, live lobby state, Ready, synchronized Start,
Cancel, clean teardown, and solo-runtime restart reach their intended
boundaries. The paired runtime then desynchronizes at the first checksum on
frame 60, and the reverse host direction, failure families, background teardown,
and iPhone layout remain open. NL4 does not pass.

## Prediction and pre-fix regression

Prediction: the extracted `NetplaySession` can be embedded without reusing the
desktop SDL/ImGui lobby if one serialized iOS owner controls UICommon lifetime,
session actions, synchronized boot handoff, and runtime attachment.

The new source contract initially failed because
`MeleePadOnlinePlayViewController.mm` did not exist. It now checks the three-dot
entry, native host/join controls, player/compatibility/ready/start state, input
neutralization, real session methods, synchronized boot handoff, mobile library
linkage, and the absence of the disconnected-bridge placeholder.

## Implementation

- The three-dot menu has an icon-labelled `Online Play…` entry.
- A native UIKit form-sheet supports Host/Join, nickname, direct host address,
  UDP port, automatic or 1–20-frame manual input buffer, player rows, ping,
  GameCube slot, compatibility, Ready, Start Match, status, exact errors, and
  Cancel. It uses ordinary UIKit controls and accessibility labels on iPad and
  iPhone rather than the desktop renderer.
- The iOS core build now enables GameCube controllers, builds
  `libmoderngekko_netplay_session.a`, provisions it into the linker response,
  and supplies the same architecture definitions as CMake.
- `MeleePadCoreHost` owns the session on one serial queue. Connecting stops solo
  emulation first; host/join/ready/start delegate to `NetplaySession`; snapshots
  feed UIKit; synchronized boot data is installed before the runtime starts;
  the runtime is attached/finished at its real lifetime boundaries.
- Session saves remain load-only. The iOS Pipe profile is explicitly always
  connected. Opening and closing Online Play clears both touch and physical
  controller mixer state.
- Cancel stops any active runtime and session, shuts down externally owned
  UICommon services, releases the stopped host, dismisses the sheet, and boots
  a fresh solo runtime.
- Bootstrap composed-patch markers now point at the files to which NL2 moved
  the GameCube and headless-session markers, restoring reproducible iOS builds.
- A match-ended callback reopens the native lobby after the runtime stops so a
  desync/host-loss error is not hidden behind a stale last drawable. This
  callback builds but was added after the retained frame-60 failure and still
  requires a visible reversal.

## Visible iPad evidence

The exact Debug Simulator app was installed on the sole booted iPad Pro
13-inch simulator. The three-dot menu visibly showed Online Play above Display.
The native form visibly showed Host/Join, Player, UDP port 2626, automatic
buffer, and Host Lobby.

Tapping Host Lobby stopped the active solo runtime and created a real direct-IP
lobby. The screen then showed:

- Player, 0–1 ms, GC 1;
- Compatibility: Match;
- Not ready, then Ready after tapping the native Ready button;
- Start Match disabled with only one controller slot, as required.

The first host initialization took roughly 14.5 seconds after solo shutdown.
That latency is retained as debt; the UI correctly remained in Creating Lobby
rather than freezing or claiming connection.

Tapping Cancel dismissed the sheet, tore down netplay, and performed a fresh
solo boot. The app visibly returned to the Nintendo/HAL opening and the
accessibility FPS label reported 59.9 FPS. The app was then terminated cleanly.

Both Debug and Release `iphonesimulator` SDK builds succeeded with the session
library linked. This is iPad visual/host evidence plus compile coverage for the
shared iPhone target, not an iPhone interaction pass.

## Paired iPad-host/Mac-join result

An isolated exact-candidate Mac endpoint joined the native iPad host over the
local direct-IP path. The native screen visibly converged to:

- Player at GC 1 and Mac at GC 2;
- 1 ms ping for both endpoints;
- matching compatibility and Ready for both; and
- an enabled Start Match button only after both controller slots were ready.

Tapping the native Start Match button installed synchronized boot data and
started both runtimes. Both visibly reached the same Nintendo/HAL opening;
the Mac title reported automatic buffer 2 and 0.0 ms/s network wait. At the
first periodic checksum, the Mac reported `Desync at frame 60 reported for
Player` and returned to its lobby. The iPad runtime stopped without a reported
runtime error but the tested build left its last Nintendo frame visible.

This proves that the native transport, slot assignment, ready gate, and shared
boot handoff are real. It rejects any claim that cross-platform deterministic
gameplay works. Because both endpoints were arm64 processes on the same M1 host
and network wait was zero, the next mechanism is a boot/config/save-state
divergence rather than network or CPU throughput.

## Rejected completion language

Do not say mobile Online Play works yet. The paired iPad-host/Mac-join path
desynchronizes at frame 60 and the reverse direction, connection-loss behavior,
and iPhone layout remain unproven. This slice also does not improve or clear G8
performance.

## Next experiment

Repeat the same iPad-host/Mac-join boot with one default-off diagnostic that
records the exact synchronized NetSettings/config digest, synchronized save
manifest, initial SRAM/RTC state, and frame-60 checksum on each endpoint.
Accept the first divergence only when both logs name the differing field or
memory range; reject broad timing/performance changes. Then visibly confirm the
new match-ended callback reopens the native lobby with the exact desync error.
After determinism is restored, exercise Mac-host/mobile-join, cancel/host-loss,
background, and iPhone layout. The 14.5-second setup interval remains secondary
until correctness passes.
