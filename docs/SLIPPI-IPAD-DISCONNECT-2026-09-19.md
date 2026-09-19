# iPad online disconnect — 2026-09-19

## Evidence and outcome

Read directly from the physical iPad on September 19, without restarting, reinstalling, or changing app data. The app runtime log identifies MeleePad 0.1.0 build 24 and a session beginning at 09:01:04 JST. One new Slippi run exists for this date. The owner reports playing against Falco; the numeric logs do not record character identity, so that detail is owner evidence.

Private copies of network.csv, performance.csv, direct-checkpoint.json, runtime.log and SHA-256 hashes are retained in ignored `ref/slippi-compatibility/ipad-disconnect-20260919/`. No account export was copied.

This session confirms production Unranked matchmaking, opponent connection, and sustained gameplay before a disconnect. It does not demonstrate a completed match or resolve the disconnect problem.

## Recorded sequence

Times below are relative to the diagnostics watchdog, not app launch. Performance samples arrive approximately every five seconds; network samples approximately every second.

- A Ranked search is followed by a matchmaking error by 172.128 seconds. The error text is not retained, so eligibility or other causes cannot be distinguished.
- Unranked has an accepted ticket by 187.339 seconds and is connected by 192.437 seconds.
- One game has started by 197.511 seconds. It reaches game frame 7,891, with 8,015 progress frames and 385 rewind events.
- The first disconnect sample is at 335.940 seconds: roughly 2 minutes 20 seconds of gameplay, allowing for sampling uncertainty.
- The session returns to idle and continues recording to 528.624 seconds. The disconnect did not immediately terminate the app/runtime.

## Disconnect classification

At the event, `remote_disconnect_commands` becomes 1 and `peer_disconnects` becomes 1. `reliable_timeouts`, `local_disconnect_requests`, and `stall_disconnects` remain 0. The recorded peer reason is 0. The numeric observer filters for the connected gameplay peer and distinguishes ENet's incoming disconnect handler from its reliable-timeout handler.

This establishes receipt of an explicit remote-peer disconnect command. It does not establish a deliberate human quit: the remote software could also disconnect automatically. It does not exonerate MeleePad or identify what prompted the other client.

Follow-up source audit: `local_disconnect_requests` only instruments `ForceDisconnectPlayer`; it does not cover ordinary `Disconnect()` cleanup or duplicate-connection cleanup. Its zero value rules out that instrumented force-removal path, not every local teardown. See `SLIPPI-UPSTREAM-AUDIT-2026-09-19.md` for the comparison and logging changes.

`disconnect_ack_age_ms` is 6 and `disconnect_rtt_ms` is 68. Despite its name, the former reads ENet's lastReceiveTime; it is not proof of a particular input acknowledgement, and may reflect receipt of the disconnect packet itself.

## Preceding conditions

- Maximum recorded input ACK round-trip latency: 788.595 ms; 320 samples at least 250 ms and 126 at least 500 ms.
- A late burst at 324–326 seconds raises the cumulative input-stall counter from 421 to 489. Input ACK latency reaches 755.297 ms in that burst, then returns to roughly 30–49 ms before disconnect.
- Final input-stall counter: 497. These count rollback-limit halt events, not separate outages.
- Active connected-game sampled presentation FPS: median 59.8988, minimum 56.746, maximum 60.0237. Presentation rate does not establish uninterrupted game advancement.
- Recorded send failures, service errors, and malformed packets: zero.
- Substantial interpreter fallback activity and changing failed-chunk counts are also present. These warrant a separate matched investigation but do not establish the cause of this disconnect.

## Limits and next useful test

The startup checkpoint is stale (phase running, zero search counts); the continuously flushed CSVs contain the actual session history. There is no completed worker result or finalized game trace in this run. The ordinary Dolphin log is empty. No opponent-side disconnect reason or character identity is available.

The next decisive test is real Slippi play with a known official-client opponent and logs from both endpoints, correlating the latency burst and remote disconnect. Ask the opponent whether they exited or saw an automatic error. A local self-play loop cannot answer that question. Instrument any missing disconnect/error events with timestamps and persist them immediately so an unfinished runtime does not lose the explanation. Do not change transport timeout behavior based solely on this capture.

No source-code fix or new installation was made during this evidence collection. Raw logs remain private; this report contains only aggregate diagnostics.
