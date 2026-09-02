# G9 NL3 two-Mac Melee match

Date: 2026-09-02

Result: **PASS.** Two isolated macOS endpoints completed a full synchronized
Melee match with independent input, returned through character select and both
netplay lobbies, exited cleanly, and left the canonical and both isolated
ordinary memory cards byte-identical.

This proves the bounded NL3 claim: **direct two-Mac Melee netplay works in the
retained test.** It does not prove mobile Online Play, Internet traversal, a
public service, or acceptable performance.

## Candidate corrections

The paired control in the preceding partial artifact exposed three concrete
defects. The final candidate closes each at its source boundary:

- `prepare-game.sh` now configures the actual desktop-tools build with
  `MODERNGEKKO_GAMECUBE_CONTROLLERS=ON`. The test target had compiled with that
  definition while the runner's cached CMake configuration had it off, causing
  the real runner to manage the Wii profile instead of `GCPadNew.ini`.
- Generated Pipe GameCube profiles set `Options/Always Connected = True` and
  retain exact Pipe names for buttons, both sticks, triggers, and the D-pad.
- Dolphin raw and directory memory-card implementations capture the session
  write policy when the card is constructed. A load-only netplay card now has
  no flush thread and performs no destructor flush. This closes the observed
  path where the directory-card destructor called `FlushToFile()` even after a
  netplay session requested non-writable ordinary saves.

The save correction is retained as Dolphin patch `0041`; the runner/profile,
runtime-finish, one-shot start, and load-only session changes remain in
ModernGekko patch `0015`.

## Full-match evidence

- Host and join used separate app bundles, user roots, configs, FIFOs, logs,
  and ordinary memory-card copies. Both loaded the same reviewed GALE01 module.
- The host controlled P1 Pikachu and the join controlled P2 Peach. Both
  controller ports appeared as human slots and responded independently.
- Both endpoints entered the same random pirate-ship stage for a two-minute
  time match. Retained observations showed matching clocks throughout the
  match, including approximately 1:26, 0:51, and 0:13.
- The match reached synchronized Sudden Death at 300% for both players. Both
  endpoints then showed Pikachu first and Peach second with matching result
  details.
- Both runtimes returned to the same ready character-select screen. Closing
  the join runtime returned both endpoints to their respective host/join
  lobbies exactly once, with host on GC 1, join on GC 2, both marked ready,
  and synchronized-save receipt reported.
- Both lobbies closed through their visible window controls. No matching
  runner process remained.
- Window telemetry reported automatic buffer 2 and 0.0 ms/s network wait.
  Shutdown diagnostics were closely matched: 4,067,477,653 versus
  4,061,166,466 native dispatches, 94,268 versus 94,088 fallback hooks, and
  31,450,453 versus 31,331,072 bursts. No desync was reported.

The full match used the final behavioral candidate. Its retained diagnostic
binary still printed temporary controller-boundary lines; those log-only
prints were removed, the runner rebuilt, and all focused regressions rerun
before publication. `strings` confirms those diagnostic messages are absent
from the rebuilt runner.

## Save and teardown reversal

The canonical and both isolated ordinary GCI files ended with the same SHA-256:

`f06ac610ca791a637f19973da35bf8c696c479de3885fd5fe8eaa32551d4e9a2`

Both isolated file modification times remained `2026-09-02 06:06:46` after
the full match and synchronized teardown. A preceding save-focused paired boot
and teardown on the same write-lifetime fix produced the same hash and mtime
result. The previously observed host ordinary-save mutation is therefore
reversed by the candidate.

## Focused verification

All of the following rebuilt tests exited zero:

- `moderngekko_frontend_config_test`
- `moderngekko_frontend_config_gamecube_test`
- `moderngekko_netplay_protocol_test`
- `moderngekko_netplay_session_test`

The session test includes two complete host/join/ready/start/stop cycles plus a
same-session runtime finish and restart. Patch reverse checks, shell syntax,
repository safety, and outer-tree whitespace checks are part of the publication
gate.

## Performance boundary

This was two emulator processes contending on the same M1 host. Final combat
was commonly about 12-21 FPS; results and character select were about 19-23
FPS. An earlier corrected run ranged roughly 11-40 FPS. Network wait remained
zero, so this is host emulation contention rather than demonstrated network
delay. NL3 is a synchronization/correctness gate and does not clear G8 row 7,
prove 60 FPS netplay, or justify a mobile/public Online Play claim.

## Next goal

NL4 is now active: connect the reusable headless session to a native UIKit
Online Play flow in the three-dot menu. Host/join status, player/controller
ownership, ping, buffer, compatibility, start/cancel, exact errors, and input
neutralization must work on iPhone and iPad before cross-platform gameplay is
attempted.
