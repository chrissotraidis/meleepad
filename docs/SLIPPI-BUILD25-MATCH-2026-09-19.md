# Build 25 real Unranked match investigation

## Result

Recovered the latest physical-iPad session without restarting the app, changing its container or opening QuickTime. Runtime identifies build 25. New incident logging and replay recording both worked. The private replay is 943,455 bytes and includes a complete Game End event. Raw files, hashes, replay summary and spike windows are retained only in ignored `ref/slippi-compatibility/ipad-build25-match-20260919/`.

This session differs materially from the earlier build-24 capture: the game ended before the recorded peer disconnect. The lag remains real and unexplained.

## Event order

Times are relative to incident logger startup; network/performance CSVs start 24.764 seconds later.

- 67.398 seconds: matchmaking connected.
- 70.525 seconds: game-start counter observed.
- 97.442 seconds: numeric game report: Unranked, winner -1, end method 7, LRAS initiator 0.
- 102.037 seconds: connection cleanup started and completed.
- 102.821 seconds: sampling observed the incoming peer disconnect counter become 1.

The replay independently records end method 7 and LRAS initiator 0. The [official replay specification](https://github.com/project-slippi/slippi-wiki/blob/master/SPEC.md#game-end) defines these as No Contest and the initiating player index. This does not identify whether the owner or opponent was that slot; no identity/account export was retrieved. It also does not establish the person's intent or rule out an input problem. The user was asked whether they invoked quit.

No local game-report desync marker (-2), disconnect marker (-3), reliable timeout or forced-stall disconnect was recorded. The positive replay/game-report evidence is stronger than inferring the reason from a later reason-zero ENet message. Do not apply this conclusion retroactively to build 24, where the game report was missing.

## Connection quality

- 1,471 input ACK latency observations; peak 754.301 ms.
- 119 observations at least 250 ms; 37 at least 500 ms.
- 170 rollback-limit halt events and 391 rewind events; these are not 170 separate outages.
- Active one-second sampled ACK latency median approximately 57.7 ms, with large intermittent bursts.
- Outgoing asynchronous queue maximum 537 microseconds.
- Measured network event-processing maximum 2,084 microseconds; flush maximum 2,074 microseconds.
- No recorded send/service errors or malformed packets.
- The replay contains frames -123 through 1336 and 2,396 frame bookends including re-simulation. Approximately 24.3 seconds of unique simulation progressed over roughly 27 seconds between sampled game-start and report; sampling and startup introduce uncertainty.

The event-processing timer starts **after** `enet_host_service` returns. Its low value does not rule out receive-side scheduling or radio/network delays. The approximately 256 ms cumulative loop maximum includes the intentional 250 ms idle service wait; it cannot be treated as proof of a 256 ms gameplay freeze.

Presentation samples stay near 60 FPS but include frame intervals up to roughly 110 ms. Rendering cadence is not proof of smooth game advancement; rollback halts can still present frames.

## Source audit and narrowed hypotheses

`SendAsync` enqueues and explicitly wakes the ENet thread. The loop drains the queue and flushes inputs/ACKs after each event. The low measured queue residence is inconsistent with a hundreds-of-milliseconds backlog in that instrumented queue during this match. It does not measure all time before queuing or after socket submission.

The vendored ENet protocol drops some outgoing unreliable commands when its packet throttle falls. Slippi inputs and ACKs use unsequenced/unreliable traffic, so this can amplify poor connectivity. In this capture the observed throttle minimum first falls from 32 to 26 around network second 67.65, **after** substantial earlier latency bursts at seconds 45–46 and 52–53. Throttling therefore cannot explain the initial bursts by itself. No timeout/throttle bypass was applied.

Build 24 had similar bursts while replay recording was disabled. Enabling the replay writer in build 25 is consequently not necessary to produce this symptom, although its incremental overhead has not been measured in a matched test.

Remaining candidates include the iPad's wireless path, remote/network delay or loss, receive-side scheduling, and native simulation/input-production stalls. Existing cumulative metrics cannot distinguish these at individual packet boundaries. There is no evidence-supported source fix yet.

## Next diagnostic decision

Correlate per-interval input-production gaps, incoming datagram gaps and local throttle-drop counts with ACK spikes. These are numeric measurements; packet payloads, addresses and credentials are unnecessary. A controlled same-opponent comparison over an alternate iPad network path would distinguish radio/path effects better than another random-opponent match. The replay now also supports later official-client/native simulation comparison if a desync is actually observed.

The current installed build was left intact. No public files contain the private replay or opponent identity. This investigation establishes working evidence capture and a different termination sequence, not a fixed connection.
