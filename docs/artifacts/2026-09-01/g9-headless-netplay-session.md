# G9 headless netplay session

Date: 2026-09-01

Goal: NL2

## Question

Can the existing Dolphin-derived netplay owner be separated from SDL/ImGui and
drive host, join, compatibility, ready, start-data handoff, and teardown twice
in one process without launching a game window?

## Prediction and control failure

The desktop lobby directly owned `SessionUI`, `NetPlayServer`, and
`NetPlayClient`, so no window-independent target or lifecycle regression
existed. The first extracted test build failed on missing concrete Dolphin
headers. After those compile seams were corrected, its initial run exited 139.
Phase markers localized that exit to the synthetic fixture's early invalid-game
return: it omitted the required `files/` directory and returned without the
test's normal `UICommon::Shutdown`. Adding the required empty directory made
the game valid and removed the exit. This was a fixture/lifecycle defect, not a
network transport crash.

## Change

- Add a pImpl `NetplaySession` with serialized state, immutable player/lobby
  snapshots, controller-count and ready actions, host-only start, one-shot boot
  data, runtime attachment, and idempotent stop.
- Move Dolphin UI callbacks and raw client/server ownership into
  `netplay_session_core.cpp`.
- Build that core as the reusable `moderngekko_netplay_session` static library.
- Reduce the SDL/ImGui file to a desktop adapter over snapshots and actions.
- Add `moderngekko_netplay_session_test` using a synthetic, data-free GameCube
  root and attached test descriptor.
- Store the complete dependency change in ordered outer patch `0014` and add it
  to bootstrap.

## Results

The lifecycle test passes two consecutive cycles in one process. Each cycle:

1. creates an ephemeral-port host and its local client;
2. creates a second joining session;
3. observes two matching players on both endpoints;
4. rejects start from the joining endpoint;
5. readies both endpoints and observes the host start gate;
6. generates and consumes synchronized `BootSessionData` exactly once on both;
7. stops join and host twice safely; and
8. rejects ready/start actions after returning to `Idle`.

The existing exact GameCube/Wii protocol test still passes, and
`SsbmPadRunner` rebuilds against the new adapter. The standalone session library
also compiles successfully with the iPhone Simulator arm64 toolchain, proving
the core does not depend on the desktop window adapter.

Patch `0014` passes reverse-apply validation against the live nested worktree.
No ROM, generated module, game save, installed app, or Simulator runtime was
used or changed.

## Boundary and next step

NL2 passes at headless lifecycle, desktop-build, and iPhone-Simulator compile
evidence. Save synchronization was disabled only in the synthetic start test
because no emulated Core/IOS exists there; product configuration remains
enabled and must pass in the real two-Mac match.

NL3 is now the lowest unmet goal: use two isolated macOS user roots, pipes,
logs, and saves to complete an actual Melee match with two-sided input, no
desync, clean teardown, and unchanged ordinary saves.
