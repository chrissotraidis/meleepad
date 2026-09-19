# iPad Slippi disconnect, September 16, 2026

Read-only diagnostics recovered while the app remained running. No reinstall, restart, account change, or network-setting change was performed.

Private evidence: `/private/tmp/meleepad-search-20260916/incident-performance.csv`, `incident-network.csv`, `incident-direct-checkpoint.json`, and `incident-summary.json`.

## Finding

The run reached the production service, received two opponent assignments, and started one game. The first peer connection failed and automatically requeued. The second connected, played, then emitted a peer-disconnect event following severe input delay. An empty queue does not explain the whole incident.

Times below are seconds since runtime start, sampled about every five seconds, not exact event timestamps:

| Time | Observation |
| --- | --- |
| 25.2 | One unsupported-mode request denied. The error counter belongs to this earlier event. |
| 40.5 | Unranked initialization. |
| 45.6 | First opponent assigned; attempting peer connection. |
| 55.8–60.9 | Returned to initialization, then accepted waiting state. Source has an eight-second peer-handshake timeout and automatically searches again on failure. |
| 374.9 | Second assignment; peer connected. |
| 379.9 | Game started. |
| 384.9–390.0 | New game progress approximately 59 frames/second. Sampled input RTT 224–231 ms. |
| 395.1 | Sampled input RTT 1,546.8 ms; new game progress 30.9 frames/second; input-stall counter increased sharply. |
| 400.1 | New game progress 37.0 frames/second; ENet smoothed RTT 562 ms. |
| 405.1 | Returned to idle/character select; one peer-disconnect event, reason 0. |

The connected interval is bracketed at roughly 25–35 seconds by the telemetry. The user's estimate was about 45 seconds. Do not silently substitute the estimate for measured timestamps.

## Interpretation

- Mean recorded input RTT: 286.35 ms across 1,129 samples; maximum **sampled latest RTT** 1,546.8 ms. Five-second CSV sampling may miss a higher peak.
- 349 input stalls and 373 rollback events; rendering remained approximately 58.7–59.7 FPS during the game. Presentation FPS did not mean the game advanced at full speed.
- One final-peer ENet disconnect with reason 0. This does not distinguish an opponent quit, timeout, or other unclassified termination; no specific poor-performance reason was transmitted.
- Zero recorded local stall-disconnect triggers, invalid packets, and send failures. These do not establish an error-free network path.
- The raw ENet packet-loss value is fixed-point telemetry, not a percentage. Do not report its raw value of 28 as 28% loss.
- `apple_service_result=-2` before the game is the diagnostic's unset sentinel. After connection it becomes 0 (successful socket classification); it is not evidence that Apple denied networking.
- The ordinary `dolphin.log` was empty. Live CSVs contain the useful evidence. The initial checkpoint was stale relative to the live counters; no claim is made from its zero counts.

The strongest evidence is that severe input delay preceded the disconnect. These logs alone cannot assign the delay to the local connection, remote player, intervening network, or client scheduling. The previous simulator result is a controlled comparison, not proof that the hardware client is free of bugs.

Ranked, Teams, and Party remain intentionally blocked in the preview. Unranked and Direct are enabled. These mode restrictions did not prevent this Unranked game from connecting.

## Next discriminating test

Use an arranged opponent running official Slippi, and compare the same iPad/build on its current network and an independent connection. Correlate both endpoints' logs. This controls opponent availability and helps separate network conditions from native-client behavior. Do not change rollback limits or suppress disconnects merely to hide the symptom.

Detailed per-frame buffers are written when the runtime exits normally; this read-only collection did not force the user's current runtime to stop. A diagnostic RVI interface was briefly created and removed; no packet capture was started, so no packet-level explanation of this past incident is claimed.

## Transport follow-up and candidate fix

The owner has not tested official Slippi on this connection. There is therefore
no established same-network PC control showing that this is exclusive to iPad.

A fresh, low-rate Mac UDP control alternated 20 STUN requests to each of
Cloudflare and Google. Cloudflare returned 19/20, with measured RTTs of
20.04–823.35 ms; Google returned 18/20, with RTTs of 15.39–280.16 ms.
Concurrent ICMP probes returned 40/40 with RTTs of 15.4–47.12 ms. These are
separate endpoints and protocols, not an official Slippi game. They establish
UDP variability outside MeleePad, not a particular faulty router, ISP, or
opponent. No network settings were changed.

The incident's application outgoing queue maximum was 457 microseconds across
1,585 queued packets. That metric stops at `enet_peer_send`, which enqueues
inside ENet; it does not measure when the operating system receives the packet.
Inspection found that `enet_host_service` can dispatch an already-queued receive
and return before processing outgoing commands. The examined desktop-reference
service loop has the same general behavior; this is not evidence of an
exclusively iOS ENet defect.

The private adapter now calls `enet_host_flush(m_client)` once at the end of
its connected network-thread iteration, after draining asynchronous inputs and
processing the received event, including any input ACK it generates. The durable
adapter-generation script applies this change as well. It leaves reliable versus
unsequenced packet flags, channels, throttling, peer timeouts, rollback limits,
and matchmaking unchanged. It removes an avoidable outgoing-service deferral;
it cannot remove network jitter and has not been shown to explain the full
incident spike. More frequent socket sends are a possible overhead tradeoff.

### Validation

- `python3 scripts/test_slippi_enet_dispatch.py`: actual loopback ENet hosts,
  compiled from the current vendored C sources. With incoming events queued,
  the baseline delivers neither the new input nor ACK on the next service call;
  explicit flushing delivers both, in one outgoing datagram, while receives
  remain queued. This is a controlled transport reproduction, not an incident
  replay or a performance benchmark.
- `python3 scripts/test_slippi_enet_startup.py`: all three existing RTT/throttle
  scenarios pass, including preserving throttling after a converged connection
  becomes slower.
- Two rebuilt Simulator clients included freshly compiled `SlippiNetplay.cpp`
  objects. Synthetic accounts and a linked loopback UDP guard isolated the
  fixture from production matchmaking. A relay added 60 ms in each direction;
  observed relay holding time averaged 60.50 ms, with no relay drops.
- Both clients completed one full game and returned to character select.
  Complete-match comparison covered 3,372 finalized frames and 10,116 emitted
  player/RNG packets: zero mismatches, zero excluded frames. One client performed
  50 rewinds, with 58 changed prediction events and a maximum two-frame rewind.
  Both game-end records were present. This validates those emitted packets,
  not full emulated RAM or crossplay with official desktop Slippi.
- A fresh unsigned iOS Release build succeeded. `scripts/check-repository.sh`
  passed. The physical iPad was not reinstalled or restarted during this pass.

Private evidence is retained under `/private/tmp/meleepad-transport-20260916/`,
including `completed-match.json`, `change-manifest.json`, simulator build commands,
`device-build.log`, the network-control results, and the relay summary. Temporary
simulators were shut down after clean runtime exits. Game-derived test artifacts
must remain private.

This candidate is **not release-accepted**. The next acceptance test remains an
arranged physical-iPad match against official Slippi with correlated endpoint
logs, preferably followed by the same pairing on an independent network. A
same-network official desktop match would provide the missing comparison.

## Hardware deployment and finer diagnostics (build 22)

Following the owner's deployment request, the signed app was updated in place
with the existing bundle/team identity. The initial build-21 package exposed a
resource-staging mistake: merging the ordinary build's resources replaced the
private Slippi game-settings INI. Startup correctly rejected the incomplete code
set. Restaging the pinned Slippi INI, bootloader, and game files corrected this;
these files must be staged **after** ordinary build resources, as the repository's
`stage-ios-modules.py` already does. This was a packaging error during deployment,
not the original online disconnect.

Build 22 includes the flush fix and additional numeric diagnostics:

- `network.csv` is flushed approximately once per second, independently of the
  five-second performance sampler, with an additional row at watchdog exit.
- `ping_max_us` retains the maximum of every observed input RTT; counts at or
  above 250 ms and 500 ms retain transient delays even when the latest ping is low.
- `service_errors`, `receive_events`, and `flush_calls` show network-thread activity.
- `work_max_us` measures processing from the return of ENet service through the
  explicit flush. It excludes the intentional idle wait inside service.
  `flush_max_us` measures the explicit flush call, not delivery to the opponent.
- `sent_datagrams` and `received_datagrams` are accumulated deltas of ENet's host
  packet counters during the connected loop, not independent packet captures.
  The send counter can include nonblocking zero-byte sends; receive counts can
  include intercepted wakeup traffic. Neither proves peer delivery or wire time.
  Values are cumulative per application runtime, including multiple matches;
  compare successive rows for interval changes.

No account values, peer addresses, or packet payloads were added to these logs.
Kernel arrival timestamps, per-packet socket-send timestamps, and opponent-side
logs are still absent. Thus these additions improve local scheduling diagnosis
but cannot uniquely separate Wi-Fi, Internet transit, and remote processing.

Validation: the diagnostic regression verifies that a 1.55-second spike remains
visible after a subsequent 220-ms sample, reset clears the counters, and CSV
header/row widths agree. Existing ENet dispatch and throttle tests passed, as did
the full iOS build and repository checks. Installed-app inspection confirms build
22. The physical runtime reports `native Slippi runtime ready revision=2` with
the same accepted native-module hash. Online gameplay acceptance is still pending.

Deployment evidence, signing/build identity, startup logs and live telemetry are
under `/private/tmp/meleepad-transport-20260916/deploy/`. The prior build-20 bundle
was retained for rollback; the live app container was never uninstalled or reset.

Live build-22 readback confirmed 36 network columns at approximately one-second
intervals and about 59.94 FPS/VPS at the online menu. All ten saved configuration
files were byte-identical; GC contained no files before or after. The only two
changed preference values relocated the same bundled game root/disc to the new
installation UUID. No gameplay acceptance is inferred from menu frame rate.
