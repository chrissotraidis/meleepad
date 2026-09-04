# Pad lobby reference service

This small, open reference service discovers compatible rooms for MeleePad and
future Pad game projects. It does not relay or inspect gameplay traffic.

See [PROTOCOL.md](PROTOCOL.md) for the product boundary and shared activity
format. MeleePad is the first client. A future KartPad adapter can use the same
directory while keeping KartPad's own gameplay networking.

Local development:

```sh
python3 -m services.lobby.server --host 127.0.0.1 --port 8765
```

Run tests from the repository root:

```sh
python3 -m unittest services.lobby.test_server
```

Or start the loopback-only container from this directory:

```sh
docker compose up --build
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
- product-scoped room listings plus identity-free aggregate activity across
  registered Pad games;
- traversal codes omitted from public room listings and returned only by Join;
- 45-second host/member heartbeat expiry and 20-second initial join
  reservations;
- host-selected two-, three-, or four-seat rooms with capacity enforced under
  the room-store lock;
- public room cards include a bounded four-person roster, open-seat count,
  compatibility/joinability, and heartbeat freshness without exposing room
  codes, addresses, or tokens;
- allow-listed request fields, 8 KiB body limit, bounded room/message storage,
  bounded sessions and rate-limit keys, a 64-request worker ceiling, ten-second
  socket timeouts, and per-source/per-session rate limits;
- member-only Room Chat with a 160-character limit, control/content filtering,
  bounded history, and a four-message-per-ten-second limit;
- server-side display-name filtering plus report and block actions; report
  targets must match the referenced room, duplicate reports are idempotent, and
  report submission has a separate per-session limit;
- no standard request logs, IPs, tokens, traversal codes, or message contents in
  application diagnostics;
- no browser CORS surface.

Do not expose port 8765 directly. The recommended shape is an edge DDoS/WAF
provider in front of an outbound tunnel to this service on loopback. See the
[deployment guide](../../docs/PUBLIC-LOBBY-DEPLOYMENT.md), including the Zo
Computer path and the gates that still prevent a broad public launch.

The in-memory single-process store remains a staging vertical slice, not
production infrastructure. A broad public deployment still requires durable
moderation/report storage, operational metrics, backups, and an abuse-response
process with published contact information.

When, and only when, the origin is reachable exclusively through Cloudflare,
start the service with `--trust-cloudflare`. This uses Cloudflare's validated
client-address header for per-source rate limits while storing only an
ephemerally keyed hash in memory. Never enable it on a directly reachable
origin because a caller could spoof the header.
