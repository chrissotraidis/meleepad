# Secure public-lobby deployment

## The plain-English answer

MeleePad's lobby can run on a VPS or Zo Computer, but the reference server must
not be placed directly on the public Internet. It is small and intentionally
simple. It can limit ordinary misuse, but it cannot absorb a volumetric DDoS or
replace an operated web-application firewall.

An unlisted hostname is not a security control. Anyone can recover the endpoint
from the app or observe its traffic. Public Games should remain disabled unless
the endpoint is designed on the assumption that strangers will find and probe
it.

The recommended path is:

```text
MeleePad
   |
   | HTTPS
   v
edge DDoS protection + WAF + route limits
   |
   | outbound authenticated tunnel
   v
localhost:8765 on the host
   |
   v
Pad lobby reference service
```

The edge absorbs large attacks and rejects abusive requests. The outbound
tunnel keeps the host address and port closed. The lobby still validates every
request, expires rooms, hides connection codes, and bounds its own memory,
threads, request size, and request time.

## Zo Computer

Zo supports long-running services. Its public HTTP service mode is public by
default and has no built-in user authentication, according to the
[Zo Services documentation](https://www.zo.computer/docs/services). Do not use
a directly published Zo HTTP hostname as the production security boundary.

For a small staging deployment, use this pattern if Zo permits the required
outbound tunnel process:

1. Run the lobby as a Zo **process** service with no public endpoint. Use the
   repository as its working directory and start:

   ```sh
   python3 -m services.lobby.server --host 127.0.0.1 --port 8765 --trust-cloudflare
   ```

2. Run `cloudflared` as a second supervised process service. Configure one
   public hostname, such as `lobby.example.com`, to reach
   `http://127.0.0.1:8765`.
3. Keep the Zo public HTTP and TCP service modes off for port 8765. The lobby
   should have no directly reachable `zocomputer.io` origin URL.
4. At the edge, enable managed DDoS protection, WAF rules, body-size limits,
   connection limits, and per-route rate limits. Cloudflare recommends WAF and
   rate-limiting rules in addition to its automatic network mitigation in its
   [proactive DDoS guidance](https://developers.cloudflare.com/ddos-protection/best-practices/proactive-defense/).
5. Confirm from another network that port 8765 and any origin hostname are not
   reachable directly.

`--trust-cloudflare` is required in this tunnel shape so application rate limits
use the actual client address instead of treating every tunnel request as one
local client. The service validates the address and keeps only an ephemerally
keyed hash. Never use this flag if callers can reach the origin directly and
forge the header.

Cloudflare Tunnel uses outbound-only connections and does not require a public
origin address or inbound firewall opening. See the
[official Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/).

If Zo cannot run and supervise `cloudflared`, use Zo only for a private staging
test. A conventional VPS where you control the firewall is the simpler public
host in that case.

## Conventional VPS

The recommended first provider is a 1 GB DigitalOcean Basic Droplet. The exact
dashboard, firewall, tunnel, deployment, client-build, and acceptance steps are
in the [DigitalOcean runbook](PUBLIC-LOBBY-DIGITALOCEAN.md).

1. Patch the operating system and enable automatic security updates.
2. Allow SSH by key only. Restrict administrative access and never expose the
   Docker socket.
3. Run `services/lobby/compose.yaml`. It binds the container to
   `127.0.0.1:8765`, runs as an unprivileged user, drops Linux capabilities,
   uses a read-only filesystem, and sets CPU, memory, process, and temporary
   storage limits.
4. Put an outbound edge tunnel in front of loopback, or configure a reverse
   proxy whose origin firewall accepts traffic only from the edge provider.
5. Do not open port 8765 in the VPS firewall.

Docker's security documentation recommends non-root execution, reduced
capabilities, and resource controls. Rootless Docker provides a stronger daemon
boundary when the host supports it. See
[Docker security](https://docs.docker.com/engine/security/) and
[rootless mode](https://docs.docker.com/engine/security/rootless/).

## Edge rules

Exact thresholds need a staging load test because schools, homes, and mobile
networks can place many legitimate players behind one public IP address. Start
with these principles:

- permit only `GET`, `POST`, `PUT`, and `DELETE` on the documented `/v1` paths;
- reject request bodies over 8 KiB before they reach the origin;
- set short header, body, upstream, and idle timeouts;
- apply a strict creation limit to `POST /v1/sessions` and `POST /v1/rooms`;
- rate-limit chat and reports separately from room-list refreshes;
- cap concurrent requests and connections to the origin;
- challenge or block obvious automation and abusive networks;
- never cache authenticated lobby responses;
- do not trust `X-Forwarded-For` unless the origin can only be reached through
  the configured proxy.

Cloudflare Access or another interactive login page should not be placed in
front of the player API because the native app cannot complete that browser
login. The public API uses its own short-lived bearer sessions. Edge controls
protect the endpoint itself.

## What the current server protects

- connection codes are hidden until a compatible join is authorized;
- tokens are stored only as hashes and are never intentionally logged;
- product, game, revision, protocol, app version, and build must match;
- names, messages, payloads, room capacity, room count, sessions, workers, and
  rate-limit key storage are bounded;
- rooms and member reservations expire without heartbeats;
- chat, block, and report operations require room context;
- the container runs without Linux capabilities and with resource ceilings.

## What remains before broad public use

The current report store is in memory and disappears on restart. A public
service needs durable, access-controlled moderation records with a retention
policy. It also needs sanitized metrics, alerting, backups, an operator runbook,
and a published abuse contact. These are required even if the host and edge are
technically secure.

Player names are unverified pseudonyms. Public room listings and chat can still
be used for harassment, spam, or offensive content. Public hosting should begin
as a small canary with the ability to disable room creation or the entire
endpoint quickly.

No design can promise that a public service will never be attacked or taken
offline. The practical goal is to hide the origin, limit damage, preserve no
valuable secrets in the service, detect abuse, and recover quickly.

## Release gate

Do not configure `MeleePadLobbyBaseURL` in a distributed physical-device build
until all of these pass:

- the URL is HTTPS and the certificate validates normally;
- the origin is unreachable except through the approved edge or tunnel;
- oversized, slow, malformed, unauthenticated, and rate-limited requests fail
  closed;
- restart and overload drills do not expose connection codes or tokens;
- reports survive a restart and can be reviewed by the operator;
- logs and metrics contain no player names, chat text, tokens, connection codes,
  IP addresses, or private host paths;
- a kill switch can disable Public Games without breaking Private Room or
  Direct IP;
- the exact iPad build completes the two-device lifecycle test.
