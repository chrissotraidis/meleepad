# G9 NL3 two-Mac Melee match: gameplay pass, teardown/save candidate pending

Date: 2026-09-02

Result: **PARTIAL.** Two isolated macOS endpoints completed one synchronized
two-player Melee match, but the control exposed lifecycle and host-save defects.
The corrective candidate passes focused tests and still requires a paired
runtime reversal before NL3 can pass.

## Retained control evidence

- Independent host/join user roots, FIFOs, configs, GCI copies, logs, and app
  bundles were used. Both loaded the same reviewed GALE01 module fingerprint.
- The SDL-created macOS application crashed when Dolphin sent a selector that
  existed only on its assumed `NSApplication` subclass. A category plus scoped
  platform pointer fixed the handoff and allowed both runtimes to boot.
- The generated Pipe profile used SDL stick/trigger names. A focused regression
  failed with exit `16`; the candidate emits the Pipe backend's exact button,
  main-stick, C-stick, trigger, and D-pad names and omits unsupported rumble.
- Host input moved only P1; join input moved only P2. Both selected distinct
  fighters (Zelda and Samus), selected Onett, and entered a two-minute match.
- Mid-match captures showed matching clocks and state on both endpoints,
  including 1:34 with Zelda at 43%, 1:14 with Zelda at 103%, and 0:51 with
  Zelda at 148%. Window telemetry reported buffer 2 and 0.0 ms/s network wait.
- The tied match entered Sudden Death at 300%; two-sided input ended it. Both
  endpoints showed the same results: Samus first and Zelda second, then both
  returned to the ready character-select screen.
- No desync was reported. Static-recompiler shutdown counters were closely
  matched between endpoints.

## Performance boundary

This same-M1 two-process run is not a performance pass. Cold/complex intervals
ranged from about 0.8 to 25 FPS, warmed light screens briefly reached 58-60 FPS,
and combat commonly reported 16-29 FPS. Network wait remained zero. NL3 tests
correctness; these values neither clear G8 row 7 nor demonstrate 60 FPS online.

## Control failures and candidate

Closing the host game returned to the lobby without clearing Dolphin's running
flag. The test-only auto-start seam then attempted another boot (`Game is
already running`), and the join endpoint later consumed stale boot work after
host exit. The host's ordinary isolated GCI also changed while the join and
canonical user GCI stayed unchanged; Dolphin's load-and-write setting permits
the host to write its normal card while clients use `GC/NetPlayTemp`.

Patch `0015` adds `NetplaySession::FinishRuntime()`, broadcasts/clears game stop
before returning to lobby, makes test auto-start one-shot, sets synchronized
saves to load-only, and generates Pipe-native controller profiles. Patch `0040`
contains the macOS SDL/NSApplication handoff. The session regression now starts,
finishes, and starts again within one session; frontend GameCube/legacy and
protocol tests pass.

## Next experiment

Recreate clean isolated cards from the unchanged canonical hash, rebuild from
the durable patch stack, and repeat a short paired match. Accept NL3 only if
both endpoints reach results, return to lobby/CSS, host close stops the join
runtime without stale reboot, both processes exit through their UI paths, and
canonical plus both ordinary isolated GCI hashes remain identical. Otherwise
retain the exact failing state and keep NL3 open.
