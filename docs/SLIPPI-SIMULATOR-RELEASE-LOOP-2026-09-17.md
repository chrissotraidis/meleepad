# Slippi Simulator release test loop — September 17, 2026

**The local Simulator checks passed. This does not yet qualify a public Slippi
release.** Two rebuilt native clients completed six games, including two with
controlled latency, and compared 15,969 complete frames and 48,262 emitted
player/RNG/item packets with zero mismatches. No production matchmaking or
physical-device trial was performed in this pass.

[Aggregate results and source hashes](artifacts/slippi-simulator-release-loop-2026-09-17/summary.json)
record all six comparisons and their limits. The original dirty development
checkout and physical iPad installation were preserved. No production runtime
fix was indicated by these local tests, and no public release was published.

## Actual repeated tests

| Test | Result |
| --- | --- |
| Current Simulator app build | Xcode Release build passed. |
| Two local clients | Separate synthetic accounts, bundle IDs, simulators and user directories; both reached the native online menu. |
| Unavailable matchmaking service | The initial test-server process exited with its launching shell. The app reported an error and recovered after the fixture was restarted. This was a test-setup failure, not a discovered product defect. |
| Cancel and retry | Three Unranked accepted-search → cancel → idle → retry → accepted cycles passed. |
| Local assignment | Both clients accepted an assignment, connected and entered Battlefield. |
| Games and rematches without added delay | Four completed games, 9,240 compared frames, zero mismatches, both Game End events in every game. |
| Delayed games and rematch | Two completed games, 6,729 compared frames, zero mismatches; both passed the changed-prediction rollback gate. |
| Delay delivery | 29,017 relayed datagrams, zero rejected/dropped datagrams, zero queued at shutdown; mean hold 61.92 ms per direction, target 60 ms. |
| Runtime restart | Exit to Home and Play Slippi worked again in the same app processes. The peer returned to idle after the other client exited. |
| Ranked routing | Actual Ranked menu selection submitted mode 0 to the local service; accepted search and two cancel/retry cycles passed. |
| Party routing | Actual Party menu selection submitted mode 4; accepted search and cancellation passed. |
| Teams routing | Actual Teams code-entry screen accepted a synthetic lobby code, submitted mode 3, received acceptance and cancelled to idle. No four-player match was attempted. |
| Status UI | Slippi Multiplayer dialog correctly showed connected state and the five enabled modes. |

The first attempted delay trial re-entered an existing peer session and sent no
relay traffic. It was not counted as a delayed trial. Both runtimes were exited
and restarted before the measured delayed pair. The four no-added-delay games
include that extra ordinary rematch; their full-game traces passed independently.

## State, performance and audio evidence

The six complete-match comparisons require both game ends, complete frame groups,
no excluded finalized frames, no overflow/sequence failure, and matching emitted
packets. They do not compare every byte of guest RAM or establish compatibility
with an official desktop Slippi client.

Median active presentation was 59.94–59.95 FPS; median new-game-frame progress
was 59.91–59.94 frames/s across the client/session groups. These are concurrent
Simulator measurements with diagnostic overhead, not physical-device benchmarks.
The delayed session recorded 48 and 50 rewind events cumulatively. Both games
contained changed predictions and a maximum two-frame rewind.

Both client sessions reported zero runtime boot, memory and graphics errors.
The mixer produced output in both sessions. The first session recorded two DMA
underruns per client in its observed window; the delayed session recorded zero.
The audio probe is a bounded window, not continuous whole-session coverage, and
no human listening acceptance is claimed.

## Build provenance and fixture boundaries

The normal current-source Simulator build was performed first. The fixture then
recompiled the current matchmaking source with loopback endpoint selection and
the current host with synthetic identities and a private test-pad timer. It
linked against the freshly built app objects, including the mode observer and
transport diagnostics. The timer exercises the shared game-pad input state;
it does not prove UIKit touch gestures. Home, restart, exit and status controls
were also exercised through Simulator's UI.

The fixture retained previously accepted Simulator modules and private resources;
it was not a clean regeneration of the game module or every core dependency.
The retained visual build number is 18. Exact executable, source and module
hashes in the aggregate identify the tested fixtures; do not identify them as
the physical build 24 merely because the mode behavior matches.

The linked guard restricts the fixture's runtime/Rust sockets to loopback UDP.
It is not an OS sandbox. No production account was submitted and no production
ranked result was created. These app bundles contain private game inputs and
must not be published as release packages.

Private fixtures, build commands, scripts, logs and copied match evidence are
retained under `ref/slippi-compatibility/release-loop-20260917/`, which Git ignores.
The old temporary directories were absent; the fixture builder was reconstructed
from prior recorded commands, updated to current build inputs, and verified by
fresh execution. All testing is stopped after orderly trace writes; the created
simulator data is retained rather than erased.

## Regressions

- 40 compiled mode-policy/counter/frame-telemetry checks passed.
- 22 packet-analyzer regression cases passed.
- Nine private-input contract tests passed.
- Actual ENet disconnect-handler and loopback disconnect tests passed.
- Actual queued-receive/input/ACK flush reproduction passed.
- RTT-spike retention, reset and network CSV alignment passed.
- Full repository checks and `git diff --check` passed.

## Release decision

This pass supports continued private testing of the native local lifecycle. It
does not close the earlier physical disconnect or explain long waits in the
production queue. The remaining public Slippi release work is concrete:

1. Complete matches against a known official desktop Slippi version, including
   rematch, disconnect/recovery, performance and audible sound on the intended
   physical build.
2. Verify real Ranked eligibility and complete-set reporting; run four-player
   Teams and Party gameplay before advertising those as validated modes.
3. Review the private Slippi host/overlay integration into maintained source and
   prepare a reproducible, module-free recipient package with matching notices
   and source. Main's maintained runtime fork migration alone does not supply
   these private Slippi build inputs.
4. Verify the exact intended release artifact's install/startup and data
   preservation. The private simulator fixture is not that artifact.

The public/private release scope question remains separate from these tests.
No new release tag, uploaded binary or claim of public Slippi readiness was made.
