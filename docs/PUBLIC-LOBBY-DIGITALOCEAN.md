# MeleePad lobby on DigitalOcean

This is the recommended first hosted proof. It runs only the lobby and an
outbound Cloudflare Tunnel. Gameplay does not pass through this server.

Expected infrastructure cost is about **$6 USD per month** for a 1 GB Basic
Droplet, before optional services or future price changes. DigitalOcean also
lists a $4 512 MiB Droplet, but 1 GB leaves safer operating room for Ubuntu,
Docker, the lobby container, and `cloudflared`. Check the current
[official Droplet pricing](https://www.digitalocean.com/pricing/droplets) before
creating it.

## What this server does

- creates short-lived lobby sessions;
- lists compatible MeleePad rooms;
- hides the traversal code until an authorized compatible join;
- maintains room seats, state, and short room chat;
- accepts bounded block and report requests;
- exposes anonymous totals for other registered Pad games.

It does not contain game data, relay gameplay, improve gameplay latency, or
guarantee that Dolphin traversal and the peer-to-peer match will succeed across
two real networks.

## Accounts and information needed

- a DigitalOcean account with billing configured;
- a Cloudflare account;
- a domain managed by Cloudflare, such as `meleepad.com`;
- an SSH public key from the administrator's computer;
- the desired hostname, such as `lobby.meleepad.com`.

Never send or commit the DigitalOcean login, Cloudflare tunnel token, SSH
private key, or account recovery codes. The tunnel token belongs only in a
root-readable file on the Droplet.

## 1. Create the Droplet

In DigitalOcean:

1. Create a **Basic** Droplet.
2. Select **Ubuntu 24.04 LTS**, one shared vCPU, and **1 GB RAM**.
3. Choose a region near the expected players. This affects lobby and chat
   responsiveness only. Gameplay remains peer to peer.
4. Authenticate with an SSH key, not a password.
5. Give it a clear name such as `meleepad-lobby-1`.
6. Add a DigitalOcean Cloud Firewall. Allow inbound SSH only from the
   administrator's current IP. Do not allow inbound 80, 443, or 8765. Allow
   outbound traffic.

The Cloudflare Tunnel is outbound, so the lobby needs no public web port.

## 2. Prepare Ubuntu

Connect over SSH, install security updates, and install `git`, `ca-certificates`,
and `curl`. Then install Docker Engine and its Compose plugin using Docker's
[official Ubuntu instructions](https://docs.docker.com/engine/install/ubuntu/).
Do not use Docker's convenience installation script for this public host.

Verify the installation:

```sh
sudo docker version
sudo docker compose version
```

Create a dedicated checkout:

```sh
sudo install -d -o "$USER" -g "$USER" /opt/meleepad-lobby
git clone https://github.com/chrissotraidis/meleepad.git /opt/meleepad-lobby
cd /opt/meleepad-lobby
git switch main
```

This public repository does not include an ISO, generated game module, save,
signing identity, or device data. Do not copy any of those items to the VPS.

## 3. Create the tunnel

In Cloudflare:

1. Open **Networking → Tunnels** and create a remotely managed tunnel named
   `meleepad-lobby`.
2. Add the public hostname `lobby.meleepad.com`, substituting the real domain.
3. Set the origin service to `http://pad-lobby:8765`.
4. Copy the generated tunnel token once.

Cloudflare documents this dashboard flow in its
[Tunnel setup guide](https://developers.cloudflare.com/tunnel/setup/). The
tunnel sends traffic outward from the Droplet, so the origin is not published
through DNS or an open web port.

On the Droplet, create `/etc/meleepad-lobby.env` with a text editor. Its only
line should be:

```text
TUNNEL_TOKEN=the-token-from-cloudflare
```

Protect it:

```sh
sudo chown root:root /etc/meleepad-lobby.env
sudo chmod 600 /etc/meleepad-lobby.env
```

Do not place this file inside the repository.

## 4. Start the lobby

From `/opt/meleepad-lobby`:

```sh
sudo docker compose \
  --env-file /etc/meleepad-lobby.env \
  -f services/lobby/compose.yaml \
  -f services/lobby/compose.cloudflare.yaml \
  up -d --build
```

The lobby container is limited to 256 MiB RAM, one CPU, 96 processes, no Linux
capabilities, and a read-only filesystem. The tunnel is separately limited and
receives no host filesystem or Docker socket access.

Check local state without printing the tunnel token:

```sh
sudo docker compose \
  -f services/lobby/compose.yaml \
  -f services/lobby/compose.cloudflare.yaml \
  ps
curl --fail --silent http://127.0.0.1:8765/healthz
curl --fail --silent https://lobby.meleepad.com/healthz
curl --fail --silent https://lobby.meleepad.com/v1/capabilities
```

The expected health response is `{"status":"ok"}`. The capabilities response
should identify `pad-lobby-1`.

## 5. Configure Cloudflare

Keep proxying enabled. Turn on managed DDoS protection and appropriate managed
WAF rules. Add route-level rate limiting for session and room creation, chat,
and reports. Do not cache `/v1/*` responses.

The app refreshes room data normally, so avoid one very low global request
limit. Begin with a small canary, observe sanitized counts, then tune the edge
limits. Cloudflare recommends combining its automatic DDoS protection with WAF
and rate-limiting rules in its
[proactive defense guidance](https://developers.cloudflare.com/ddos-protection/best-practices/proactive-defense/).

Do not enable Cloudflare Access or an interactive login page on this hostname.
MeleePad is a native client and uses the lobby's short-lived bearer sessions.

## 6. Confirm the origin is hidden

From a machine outside DigitalOcean:

- `https://lobby.meleepad.com/healthz` should work;
- the Droplet IP on ports 80, 443, and 8765 should not respond;
- only the administrator's allowed address should reach SSH;
- no separate origin hostname should expose the lobby.

Do not proceed if direct origin access works. The lobby enables
`--trust-cloudflare` in this deployment and therefore trusts Cloudflare's client
address header for rate limiting. That is safe only when Cloudflare is the sole
path to the service.

## 7. Pair a test MeleePad build

The physical app accepts only an HTTPS lobby URL. The iOS build should set:

```text
MELEEPAD_LOBBY_BASE_URL=https://lobby.meleepad.com
```

The project places that value in `MeleePadLobbyBaseURL` inside the built app.
Installing a newer build without this setting updates the UI but deliberately
leaves Public Games offline.

Do not publish that build yet. First install it in place on the test iPad and
complete the acceptance sequence below.

## 8. Prove the whole path

Use two devices on different networks:

1. Device A confirms a player name and creates a two-player public room.
2. Device B sees the room, its host, seats, compatible build, and freshness.
3. Device B joins without learning the hidden traversal code before Join.
4. Both devices exchange room chat and ready up.
5. The host starts Melee. The room stays **In match** for more than 45 seconds.
6. Complete a match, pass through results, and return to character select.
7. Open the connected screen from the three-dot menu. Verify roster, chat,
   `ms to host`, **Return to Game**, and **Leave Session**.
8. Leave and confirm the room or member disappears.
9. Stop the lobby container and confirm Public Games fails closed while Private
   Room and Direct IP remain usable.

This test separates directory success from gameplay success. If the room list
works but the match does not connect or remain synchronized, the VPS is doing
its job and the remaining failure is in traversal, peer networking, or MeleePad
netplay.

## Updating and rollback

Before an update, note the currently deployed commit. Then:

```sh
cd /opt/meleepad-lobby
git fetch origin main
git switch main
git pull --ff-only
sudo docker compose \
  --env-file /etc/meleepad-lobby.env \
  -f services/lobby/compose.yaml \
  -f services/lobby/compose.cloudflare.yaml \
  up -d --build
```

Rooms and chat are currently in memory, so restarting intentionally clears
them. Roll back by checking out the previously recorded commit and running the
same Compose command. Never copy the tunnel token into Git or a support log.

## Current limitation

This is suitable for a small controlled canary, not an unrestricted public
launch. Reports are still stored only in memory. Before broad exposure, add
durable moderation storage, sanitized operational alerts, a published abuse
contact, and a tested kill switch.
