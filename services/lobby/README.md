# MeleePad lobby service

This small service discovers compatible MeleePad traversal rooms. It does not
relay or inspect gameplay traffic.

Local development:

```sh
python3 -m services.lobby.server --host 127.0.0.1 --port 8765
```

Run tests from the repository root:

```sh
python3 -m unittest services.lobby.test_server
```

The iOS Simulator can use the service by launching MeleePad with
`MELEEPAD_LOBBY_BASE_URL=http://127.0.0.1:8765`. Plain HTTP is accepted only
for a loopback Simulator endpoint. Any deployed endpoint must use HTTPS.

To keep one synthetic room visible while refining the UI, run this in a
second terminal. Its placeholder traversal code is never returned by a list
request and is not suitable for a gameplay test:

```sh
python3 -m services.lobby.demo_host --guest FoxMain --guest SamusFan
```

Security properties of this vertical slice:

- opaque two-hour bearer sessions, stored server-side only as SHA-256 hashes;
- exact app build, protocol, game, and revision compatibility checks;
- traversal codes omitted from public room listings and returned only by Join;
- 45-second host/member heartbeat expiry and 20-second initial join
  reservations;
- host-selected two-, three-, or four-seat rooms with capacity enforced under
  the room-store lock;
- public room cards include a bounded four-person roster, open-seat count,
  compatibility/joinability, and heartbeat freshness without exposing room
  codes, addresses, or tokens;
- allow-listed request fields, 8 KiB body limit, bounded room/message storage,
  and per-source/per-session rate limits;
- member-only Room Chat with a 160-character limit, control/content filtering,
  bounded history, and a four-message-per-ten-second limit;
- server-side display-name filtering plus report and block actions; report
  targets must match the referenced room, duplicate reports are idempotent, and
  report submission has a separate per-session limit;
- no standard request logs, IPs, tokens, traversal codes, or message contents in
  application diagnostics;
- no browser CORS surface.

Before deployment, place the service behind TLS, connection limits, a trusted
reverse proxy/WAF, persistent moderation/report storage, operational metrics,
restart supervision, backups, and an abuse-response process with published
contact information. The in-memory single-process store is intentionally a
development vertical slice, not production infrastructure.
