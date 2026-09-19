# Build 22 hardware disconnect and build 23 diagnostic iteration

## Observed incident

The owner reported playing briefly before an automatic-looking disconnect. The
physical app's runtime log identifies build 22. Its preserved one-second network
CSV and five-second performance CSV show one connected game in this session.
Raw evidence remains private under `/private/tmp/meleepad-build22-incident/`.

| Runtime elapsed seconds | Evidence |
| --- | --- |
| 676.5 | Connected network activity begins. |
| 680.7–683.8 | Input RTT around 0.86–1.09 seconds; observed peak 1.179 seconds. |
| 684.8 | Latest input RTT recovers to 33 ms; cumulative stalls reach 233. |
| 685.9–704.6 | Latest RTT approximately 20–36 ms. Stalls remain 233. New game frames advance at about 60/s. |
| 705.7 | One final-peer disconnect event, reason zero; transport counters stop advancing. |
| 708.8 | Matchmaking state idle/character select. |

Across the collected session: application send-queue maximum 386 microseconds,
network work maximum 524 microseconds, explicit flush maximum 509 microseconds,
zero service/send errors, zero invalid packets, and zero recorded local
stall-disconnect triggers. The game reached frame 1167 with 21 rewinds. Network
loop maximum was approximately 256 ms, which includes the normal 250-ms idle
service wait and must not be called a 256-ms processing stall.

The full-match observed RTT peak is real, not merely the largest sampled latest
ping. It occurred at startup, not just before disconnect. This differs from the
previous build-20 incident. These observations do not establish a causal benefit
from the flush fix: the opponent and network conditions were not controlled.

## Why another diagnostic change is needed

ENet's received-disconnect handler and its reliable-command timeout path can both
surface an application disconnect event with data zero. ENet resets peer state
before the application consumes that event. Ongoing unreliable input traffic
also does not, by itself, prove that every reliable command was acknowledged.
Thus this incident cannot honestly be classified as opponent quit or timeout
from the existing event counter alone.

Build 23 instruments the precise ENet decisions before reset. Numeric counters
separately record a received remote disconnect command and a locally detected
reliable timeout. A separate adapter counter records `ForceDisconnectPlayer`
requests. The hook filters on the actual connected game-peer pointer, excluding
matchmaking and unsuccessful hole-punch peers. It stores no pointer values,
addresses, identities or packet payloads.

Additional CSV columns:

- `remote_disconnect_commands`: received disconnect commands for the selected peer.
- `reliable_timeouts`: ENet's reliable timeout decision for the selected peer.
- `local_disconnect_requests`: calls to the adapter's forced player-disconnect path.
- `disconnect_ack_age_ms`: time since ENet's last reliable ACK timestamp at the
  recorded transport decision; this is not time since any UDP packet arrived.
- `disconnect_rtt_ms`: ENet's smoothed RTT immediately before that decision.

Counters are cumulative across matches in the application runtime. Compare row
deltas. A received disconnect command does not reveal whether the opponent quit
manually, their client enforced a rule, or another remote-side condition occurred.
The local-request counter does not cover all ordinary user cancellation/teardown.

No timeout, congestion-control, rollback, or matchmaking policy changed in this
iteration. The prior explicit-flush change remains. Source generation retains the
adapter hooks, and bootstrap applies the ENet patch after its startup RTT patch.
Ordinary ENet consumers get a weak no-op observer unless they supply an observer.

## Validation

- Existing ENet startup-throttle and outgoing-dispatch tests passed.
- Disconnect test invokes the actual protocol handlers: remote reason-zero
  disconnect and reliable timeout are classified differently before peer reset.
  An already-disconnected peer does not produce a new observation.
- A separately compiled real loopback UDP test verifies that the application's
  observer overrides the weak default and sees an actual peer disconnect.
- Numeric telemetry test retains a short RTT peak and checks CSV header alignment.
- The device ENet archive was rebuilt from the patched source; the iOS app was
  relinked and its observer symbol verified. Full iOS Release build succeeded.

The next hardware trial is intended to identify the disconnect mechanism. Build
23 is not a verified fix for the user's online disconnect and is not release
acceptance. An arranged opponent with desktop-side logs remains the strongest
next test if a received remote disconnect is confirmed.

## Deployment result

Build 23 was signed with the existing development identity and installed in
place. Installed-app inspection confirms version 23, runtime logs confirm native
Slippi readiness, and a readback of the new hardware session confirms 41-column
telemetry including the disconnect-cause counters. Configuration (10 files), GC
(empty), and preferences were unchanged in the immediate before/after readback.
The accepted native module and private Slippi resources were preserved. No new
online match was initiated by the agent; owner gameplay testing remains pending.
