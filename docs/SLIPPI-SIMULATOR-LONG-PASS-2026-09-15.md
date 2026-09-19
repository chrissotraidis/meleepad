# Slippi Simulator investigation, September 15–16, 2026

Two isolated iPad simulators completed actual local Slippi matches, including a match with 120 ms of injected round-trip latency. Touch controls were operated through Simulator: character selection, search, movement, jumping, attacks, stock losses, rematch, cancellation, and leaving a session. This was not a menu-only or build-only check.

The pass found and fixed two issues: the app did not expose the difference between an accepted search and an assigned opponent, and the private trace analyzer incorrectly rejected the final frames of an otherwise completed delayed game.

## Results

| Check | Evidence and result |
| --- | --- |
| Local Unranked assignment | Two synthetic clients received an assignment, connected, and entered Battlefield. |
| Complete local game | 6,431 frames; 19,395 player/RNG/item packets; zero mismatching frames; Game End observed on both clients. Stocks were deliberately exhausted through movement. |
| Rematch | Both clients locked in again and entered a second game without another matchmaking assignment. |
| Peer leaves during a game | Exit to Home on one client returned the other to character select, able to search again. The interrupted game is not counted as a completed match. |
| Server unavailable | With the local server stopped, the game displayed “Failed to connect to mm server.” Clearing the error allowed another search. |
| Cancel accepted ticket | Z returned to character select; the server observed the disconnect and removed the ticket. |
| Retry after cancellation | A fresh ticket was accepted and paired with the other client; both entered a new game. |
| Restart runtime in same app | Exit to Home followed by Play Slippi successfully booted another native session and connected again. |
| Complete game with delay | 60 ms each direction; 11,811 frames and 35,535 player/RNG/item packets; zero mismatching frames, including the ending. |
| Actual rollback corrections | Receiving client recorded 142 rewinds, 284 repeated frame events, 148 changed prediction frame events; maximum rewind two frames. Both Game End events observed. |
| Performance | Median presentation and new-game-frame progress approximately 59.94 FPS for both clients, including the delayed game. No memory or graphics errors reported by the runtime. |
| Delay delivery | Relay held packets for an average 60.65 ms per direction; zero invalid-source, queue-cap, send, or shutdown drops. |

The local fixture does not reproduce the production service's account validation, geographic matching, queue population, or NAT behavior. Two identical native clients agreeing does not establish official desktop-client compatibility or full RAM equivalence. Human audio/play-feel acceptance and physical iPad acceptance remain separate. Other tasks' KartPad simulators stayed running; the measurements are not an isolated-machine performance benchmark.

## Changes made

### Useful search status in the existing Slippi dialog

`Menu → Slippi Multiplayer…` now reports a snapshot of the game's observed matchmaking state: preparing/connecting, server-accepted search awaiting assignment, assigned opponent connecting, peer connected, error, or no active search. It explicitly labels the text “Status when opened” and does not invent a queue count or a reason for a long wait.

The host reads the existing atomic state published at the guest EXI boundary. It does not read the matchmaking worker's non-atomic state or infer current status from cumulative counters. The simulator rebuild and UI checks verified the unknown-before-first-status, accepted-ticket, and cancelled/no-active-search messages; Return to Game and cancellation continued to work.

Files: `apple/ios/MeleePadSlippiHost.h`, `apple/ios/MeleePadSlippiHost.mm`, `apple/ios/MeleePadGameViewController.mm`.

### Correct Game End handling in the analyzer

The first delayed-game analysis rejected two trailing frames because their last frame-bookend still described them as unfinalized. The official [Slippi parser's Game End handler](https://github.com/project-slippi/slippi-js/blob/ff815345e641836a331191320c0f6eae21542a5f/src/common/utils/slpParser.ts) finalizes remaining frames when the game ends.

Our analyzer now follows that rule only for a trace with an observed Game End and complete frame groups. It retains the bookend finalization boundary and the number of frames finalized at Game End as separate evidence. It still rejects overflow, sequence errors, missing/truncated packets, excessive tails, and a rollback that has not caught up. Tail packets are compared rather than excluded. A changed last-frame packet must fail.

The unchanged delayed-game trace now passes the complete-match and changed-rollback gates: both final two frames match. The original failing result is retained alongside the corrected result, so the validator change is auditable.

Files: `scripts/analyze-slippi-local-game.py`, `scripts/test-slippi-local-game-analysis.py`.

## Build and test scope

- `python3 scripts/test-slippi-local-game-analysis.py`: 22 tests passed, including five new Game End/tail controls.
- `bash scripts/check-repository.sh`: passed.
- `git diff --check`: passed.
- Two rebuilt Simulator apps linked, passed code-signature verification, installed, and ran. This pass did not build or install a new hardware IPA.
- Existing dirty work was preserved; these changes remain local. No release or public Slippi support claim was published.

The private fixture apps used the current host and matchmaking source, retained core objects, the freshly pinned Rust library from the prior preview build, and the validated Simulator native module. The status rebuild additionally recompiled the changed game controller. This is not a claim of a completely clean reconstruction of every private core dependency. Their retained display build number is 18; executable and module hashes identify the tested artifacts more precisely.

The fixture substitutes synthetic local identities and loopback matchmaking only. Its linked network guard permits loopback UDP; it is not an OS sandbox. No production account was submitted by the fixture. The private disc/resources remain private.

Native module SHA-256: `5023d315f6f97ae73cb05d1bbad49eead497df48069e5b1fb7c2617a786231e0`.

## Remaining production question

The production hostname selection and advertised base version were reviewed: the private client selects `mm.slippi.gg`, and its base version is 3.6.4, matching the official release reviewed during this pass. That does not prove that build metadata or other server-side eligibility rules are irrelevant.

The previously captured iPad search reached the server-accepted waiting state without an opponent assignment. This pass demonstrates that the current native client can process an assignment, play, rematch, cancel, recover, and roll back under controlled conditions. It does not prove why the production queue has not assigned that iPad an opponent, or establish that the queue is empty.

The next decisive external check is an arranged Direct match against a known-working official Slippi client, followed by a paired production Unranked control if available. Compare assignment and connection state before changing transport settings. A local synthetic server cannot close that gate. The physical iPad and its installed build/data were not changed during this pass.

## Private evidence

Audit root: `/private/tmp/meleepad-longpass-20260915`.

- `build-manifest.json`, `build-local.py`, build commands/logs: baseline local fixtures and hashes.
- `status-build/`: rebuilt status feature apps, commands, and hashes.
- `status-only.diff`: this pass's UIKit/host edits relative to the already-dirty starting files.
- `evidence-player0/`, `evidence-player1/`: saved run diagnostics and private emitted-packet traces.
- `completed-game-compare.json`: complete zero-delay match comparison.
- `completed-delay-game.before-parser-fix.json`: original conservative rejection of ending frames.
- `completed-delay-game.json`: complete delayed match comparison with corrected end semantics.
- `performance-summary.json`, `delay-60-run/relay-summary.json`: runtime and transport measurements.
- `fixture-first.log`, `fixture-retry.log`, `status-fixture.log`: assignment, cancellation, retry, and status checks.
- `repository-check.log`: full repository check output.

Do not publish the private packet traces, app bundles, disc, or derived game resources with this report.
