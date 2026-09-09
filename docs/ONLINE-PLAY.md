# Experimental Online Play

[Back to MeleePad](../README.md) · [FAQ](FAQ.md)


> [!WARNING]
> **Online play is not ready for general use.** Preview 4 contains experimental
> private rooms and Direct IP. Its Public Games interface has passed local
> development testing, but no production public-game service is deployed.
> Preview 4 includes peer chat in Private Room and Direct IP for controlled tests.

| Available now | Not available yet |
|---|---|
| Private eight-character room codes | Production public-game browser |
| Direct IP for advanced testing | Automatic or ranked matchmaking |
| Temporary peer chat in Preview 4 build 18 | Moderated public chat service |
| Two-player Mac/iPad Simulator evidence | Verified four-player online rooms |
| Physical-iPad room creation | Physical-device completed Internet matches |
| Compatibility checks and desync shutdown | Relay fallback or encrypted gameplay |
| Native Host, Join, Ready, and Start flow | General multiplayer-beta evidence |

### What a player can test now

1. Arrange a game with another MeleePad player outside the app.
2. Confirm that both players use the same build, the exact supported `GALE01`
   game revision, modules, and matching gameplay settings. Both peers must use
   Preview 4/build 18 and the same game revision (v1.02 recommended).
   Older Preview 3 builds are incompatible with this version.
3. The host opens **More (•••) → Online Play → Private Room → Host**.
4. After the app displays an eight-character room code, the host sends it to
   the other player through a trusted channel.
5. The guest opens **Private Room → Join**, enters that code, and connects.
6. Send one Room Chat message in each direction, then verify the compatibility
   state, mark Ready, and let the host start the match.

This flow depends on Dolphin's public traversal service. There is no in-app
list of strangers to play in the shipped configuration.

Players do not need the same public IP address or Wi-Fi network. In fact, the
most useful community test places the two players on independent networks.
Follow the [Private Room community test guide](PRIVATE-ROOM-TESTING.md) and
report the complete result, including slow or failed attempts.

### Safety and privacy today

- Play only with people you trust.
- A room code helps two devices find each other. It is not a password, identity
  check, or encryption key.
- Gameplay and Private Room or Direct IP chat travel directly between peers and
  are currently plaintext.
- Some routers and firewalls will reject a connection because there is no relay
  fallback.
- Exported diagnostics should never include full IP addresses, room codes, game
  data, saves, or signing material.

<details>
<summary>How does Preview 4 connect the players?</summary>

- Both players run the match locally; MeleePad exchanges synchronized
  controller input rather than streaming video.
- Both devices need the same MeleePad build, supported game revision, module,
  and compatible settings.
- The transport uses fixed delay. It is not Slippi rollback netcode.
- Gameplay is peer-to-peer over ENet after traversal introduction. MeleePad
  does not host the match or stream the game.
- There is no relay fallback. Some NAT or firewall combinations may fail even
  when the room code resolves.
- The joining player is assigned another GameCube controller port.
- A synchronization mismatch stops the session instead of allowing the two
  games to continue in different states.

</details>

### What has been verified

| Test | Result |
|---|---|
| Two Macs using direct connection | One full match completed through results and lobby return, with saves unchanged |
| Mac and iPad Simulator direct connection | Clean rebuilt peers sustained synchronized execution in both host directions beyond the old failure point |
| iPhone multiplayer interaction | Compile coverage only; no completed device match |
| Public Internet room code | Dolphin's live traversal service created/resolved fresh codes; Mac/iPad Simulator sustained about 4,700 rendered frames in each host direction |
| Physical iPad room creation | Preview 2 build 5 reached `Internet room is ready` and received a room code; no remote peer joined, so this is not match or P2P acceptance |
| Private/Direct peer chat | Build 7 includes the build-6 two-way host/join runtime coverage; its Private Room composer is visible on the physical iPad, but a two-device physical exchange remains unverified |
| Public room discovery | Local lobby service discovered a live Mac traversal host and authorized an iPad Simulator join; production service is not deployed |

The earlier Mac/iPad canonical failure was stale-build contamination and did
not reproduce after clean rebuilds; no timing tolerance or RAM exclusion was
used. The stronger full-match and real-network acceptance work continues in
the [multiplayer goal loop](NETPLAY-BETA-GOAL-LOOP.md).

### Private Room, Public Games, and Direct IP

- **Private Room** is the working Internet-room preview. Players arrange a game
  elsewhere and exchange an ephemeral room code privately. Current `main`
  build 18 includes temporary chat over the same peer connection.
- **Public Games** is the planned discovery layer. Its native UI can show
  compatible room cards and supports bounded room chat, Hide, and Report in
  local development tests. No production endpoint is deployed.
- **Direct IP** bypasses discovery and traversal. It is intended for local
  networks and advanced testing. Preview 4 exposes the same peer-chat composer
  after the direct session connects.

The public browser is designed so room listings never reveal traversal codes.
Only an authorized, compatible Join response discloses the connection code.
Release builds fail closed when no production service is configured.

<details>
<summary>How does Direct IP work, and when should I use it?</summary>

Use Direct IP for controlled testing on a trusted local network or private VPN:

1. The host chooses **Host**, keeps UDP port **2626**, and creates the lobby.
2. The host shares an IP address or hostname reachable by the joining device.
3. The second player chooses **Join**, enters that address and the same port,
   then connects.
4. Both players mark themselves **Ready**; the host starts the synchronized
   session.

UDP port 2626 is Dolphin's standard direct-netplay listening port. It is not a
MeleePad server. Same-network testing normally requires no router change;
testing across the public internet may require UDP port forwarding or a private
VPN. The current gameplay channel is plaintext, so use it only with trusted
people on a private test network. Do not expose it as a public service.

</details>

Local service and Simulator instructions are in
[services/lobby/README.md](../services/lobby/README.md). The remaining discovery,
moderation, and deployment gates are in the
[public lobby goal loop](PUBLIC-LOBBY-GOAL-LOOP.md). The reusable,
multi-game directory boundary and MeleePad-first implementation sequence are in
the [Pad Lobby Protocol goal loop](PAD-LOBBY-PROTOCOL-GOAL-LOOP.md).

### Plan after Preview 4

The next-preview plan is deliberately staged:

1. run bounded Private Room community tests on Preview 4 build 18,
   beginning with trusted two-player pairs on independent networks and a chat
   message in each direction;
2. finish full matches on physical Apple devices across independent networks,
   including NAT, disconnect, backgrounding, save, input, audio, and thermal
   coverage;
3. use the connection-success, latency, desync, and rematch evidence as the
   go/no-go gate for further public-lobby work;
4. only after that gate passes, deploy a supported HTTPS staging discovery
   service with durable moderation, rate limits, monitoring, retention
   deletion, and rollback; and
5. freeze one version/build/protocol tuple for the next preview, keeping Public
   Games disabled if either gameplay or service acceptance is incomplete.

The detailed gates and stop rules are in the
[public lobby goal loop](PUBLIC-LOBBY-GOAL-LOOP.md).

<details>
<summary>What must pass before this can be called a beta?</summary>

Before the UI can be called **Online Play with Friends (Beta)**, one unchanged
build must complete full Mac/iPad, Mac/iPhone, and iPad/iPhone matches; pass
disconnect, backgrounding, save, input, performance, and privacy checks; and
connect across separate networks through a working short room-code flow. The
[multiplayer beta plan](NETPLAY-BETA-GOAL-LOOP.md) defines the complete
acceptance matrix.

Four-player online play has additional gates: four stable controller slots,
four-seat room state, coordinated match start, peer-loss behavior, latency and
buffer policy, full-match determinism, and physical-device thermal testing.

</details>
