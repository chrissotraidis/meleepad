# MeleePad FAQ

[Back to MeleePad](../README.md) · [Online Play guide](ONLINE-PLAY.md)


<details>
<summary>Is this possible without a completed Melee decompilation?</summary>

Yes. A traditional decompilation reconstructs human-readable source code.
MeleePad takes a different route: DolRecomp converts the game's existing
PowerPC instructions into generated code that Apple Clang compiles for ARM64.
That makes native execution possible without claiming to have recovered the
game's original source code.

</details>

<details>
<summary>Is MeleePad truly native on iPhone and iPad?</summary>

Yes, in the platform and execution sense. The installed app and generated game
module are ARM64 binaries. Rendering uses Metal, and the app uses native Apple
interfaces for touch, controllers, audio, file import, settings, and lifecycle.
It does not need a browser or just-in-time compiler.

“Native” does not mean the entire GameCube was rewritten by hand. ModernGekko's
Dolphin-derived runtime still provides the hardware behavior that Melee expects.
The most accurate description is a **native static-recompilation compatibility
port**.

</details>

<details>
<summary>Is this an emulator?</summary>

MeleePad shares substantial runtime technology with Dolphin for graphics,
audio, memory, input, and GameCube system behavior. The important difference is
CPU execution: supported Melee code is converted and compiled ahead of time
instead of going through Dolphin's normal runtime JIT or interpreter.

It is best understood as a game-specific static recompilation joined to a
Dolphin-derived compatibility runtime—not a stock Dolphin frontend and not a
from-scratch source port.

</details>

<details>
<summary>Does MeleePad need JIT or special runtime permissions?</summary>

No. The game module is compiled to ARM64 before installation, so normal gameplay
does not generate executable code on the device. A locally installed build still
needs ordinary Apple development signing, just like other apps run from Xcode.

</details>

<details>
<summary>Which game revisions and images does MeleePad support?</summary>

Static recompilation depends on the executable's exact instructions, addresses,
and data. Even legitimate regional or revision releases differ at those
locations. Preview 4 supports verified USA v1.02 (disc revision 2),
recommended for new setups, and USA v1.00 (disc revision 0). Each needs its own
matching native module. Imports and saves remain separate.

See [supported images, hashes, and version tradeoffs](MELEE-VERSIONS.md).
The catalog accepts specific raw images and the verified v1.02 CISO; it does
not accept arbitrary compressed or modified images. Renaming a file does not
make it compatible. v1.01, PAL, and Japanese images remain unsupported.

Preview 4 supports both revisions; older Preview 3/build 7 supported only v1.00.

</details>

<details>
<summary>Does the repository or app include Melee?</summary>

No. The repository contains no game image, extracted game assets, saves, or
generated game module. You select your own supported image on first launch.
MeleePad validates it, keeps a private local copy in the app container, and
extracts the data the runtime needs. That data stays on your device.

</details>

<details>
<summary>Can I download a playable IPA?</summary>

No. The [Preview 4 prerelease](https://github.com/chrissotraidis/meleepad/releases/tag/v0.1.0-preview.4)
includes source and an unsigned, module-free IPA shell for inspection and
signing-workflow development. It deliberately excludes
`gGALE01_recomp.dylib`, and `gGALE01r2_recomp.dylib`, so importing an ISO into that IPA cannot make it
playable.

A playable iPhone or iPad build must be generated locally from your own
supported disc image on an Apple Silicon Mac, then signed with your Apple
development account. Start with the [requirements](../README.md#requirements), follow the
[physical-device build steps](../README.md#build-for-a-physical-iphone-or-ipad), and finish
with [first-launch game-data import](../README.md#first-launch-on-iphone-or-ipad).

</details>

<details>
<summary>Does multiplayer work?</summary>

Experimentally. Preview 4 can create private eight-character room codes through
Dolphin's public traversal service, and Direct IP remains available. Retained
Mac/iPad Simulator tests connected and ran synchronized gameplay in both host
directions.

This is not yet a public multiplayer beta. Physical-device Internet matches,
independent outside networks, complete cross-platform matches and rematches,
real-world NAT success, lifecycle recovery, and a production public-game browser
remain unverified. See [Experimental multiplayer](../README.md#experimental-multiplayer) for
the exact boundary.

</details>

<details>
<summary>Which Online Play option should I use?</summary>

- **Public Games** is the easiest discovery flow when a supported lobby service
  is configured. You can see the host, seated players, open seats, room state,
  freshness, and exact build compatibility before joining. This remains a
  local development feature; Preview 4 does not ship with a production public
  browser.
- **Private Room** is the best current choice for friends. The host creates an
  eight-character room code and shares it privately. Dolphin's traversal
  service introduces the devices without exposing the host's IP address in the
  MeleePad UI.
- **Direct IP** is an advanced fallback for a trusted local network or private
  VPN. It exposes the host address, has no relay fallback, and may require UDP
  port forwarding when used across the internet.

All three modes use MeleePad's experimental fixed-delay gameplay transport.
They do not connect to Slippi or provide encrypted gameplay.

</details>

<details>
<summary>Do Private Room players need to be on the same Wi-Fi?</summary>

No. Private Room is specifically the option to test with a trusted player on
another Internet connection. The host creates an eight-character code and the
other player enters it. Dolphin's public traversal service introduces the two
devices, then controller input travels directly between them.

This automatic connection can fail on restrictive routers, cellular or hotel
networks, and some VPNs because Preview 4 has no relay fallback. For the
cleanest first test, use ordinary home Wi-Fi on both sides, turn off VPNs, keep
MeleePad in the foreground, and try switching which player hosts if the first
attempt fails.

</details>

<details>
<summary>What should I do if “Creating lobby” takes a long time?</summary>

Give the first attempt a short chance to finish. MeleePad is registering the
host with Dolphin's public traversal service and waiting for a room code. If
the room appears, record roughly how long creation took; a delayed success is
still useful test evidence.

If it does not finish, tap **Cancel**, turn off any VPN, confirm that the device
has working Internet access, and retry once. Then use **More (•••) → Share
Diagnostic Logs** and report whether the attempt eventually succeeded. Never
post the room code or an IP address in a public issue.

</details>

<details>
<summary>Why are Public Games offline in this build?</summary>

Public Games needs an online MeleePad lobby service. The app cannot safely
discover strangers by itself: a service must publish and expire rooms, keep
connection codes hidden until a compatible player joins, limit spam, carry
room chat, and accept reports.

Preview 4 has no production service address, so the app deliberately fails
closed. It does not send names, chat, or room information to an unknown server,
and it does not fall back to an insecure public HTTP endpoint. The development
service currently stores rooms and reports only in memory and is not suitable
for public operation.

When Public Games launches, lobby traffic will require HTTPS. That protects the
directory and chat connection to the lobby service, but it does not encrypt the
match itself. Gameplay remains a direct peer-to-peer connection. Player names
are display names, not verified accounts. Until the hosted service and its
moderation process are ready, use **Private Room** with people you trust.

You can self-host the reference service on a VPS or Zo Computer for staging,
but it must not be exposed directly. The recommended deployment uses an HTTPS
edge with DDoS protection, a WAF, and route-level limits in front of an outbound
tunnel to a loopback-only lobby process. The
[secure deployment guide](PUBLIC-LOBBY-DEPLOYMENT.md) explains the Zo and
conventional VPS options and the remaining public-launch gates.
For the first isolated hosted proof, use the
[DigitalOcean lobby runbook](PUBLIC-LOBBY-DIGITALOCEAN.md).

</details>

<details>
<summary>How do player names and room chat work?</summary>

MeleePad asks you to confirm the display name other players will see before
connecting. The confirmed name is saved on that device. It is not an account,
a verified identity, or included in exported diagnostic logs.

Preview 4 build 18 shows **Room Chat** after a Private Room or Direct IP
session connects. Members can type messages up to 160 characters. These
messages use Dolphin's existing peer gameplay connection, not a MeleePad lobby
server. They are plaintext like the gameplay traffic, kept only in a small
in-memory history, and disappear when the session closes. Use these modes only
with people you trust. Preview 2 build 5 does not have this peer-chat UI.

The development Public Games mode has a separate chat path. Its messages are
relayed by the configured lobby service, rate limited, and visible only to
current room members. Public chat provides Hide and Report controls. Those
controls are intentionally absent from trusted-friend Private Room and Direct
IP sessions.

Neither path writes message text to MeleePad diagnostics. Public Games remains
a development implementation, not production anonymous chat. Deployment still
requires durable moderation records, a published support and abuse contact,
and an operated response process.

</details>

<details>
<summary>What happens after an online match ends?</summary>

If Melee is still running, everyone stays in the same synchronized game and
naturally moves from results back to character select. Players can keep playing
without finding or joining the room again. The public directory keeps that room
marked **In match** so new players cannot enter midway through the session.

If the synchronized runtime ends normally, MeleePad returns the public room to
its waiting state and reopens the connected screen. The same group can chat,
ready up, and start again. During play, **More (•••) → Experimental Multiplayer**
shows the current players and room chat. **Return to Game** keeps the connection,
while **Leave Session** disconnects and removes the player's public presence.

</details>

<details>
<summary>Can one lobby service support MeleePad, KartPad, and future games?</summary>

Yes, for discovery. The open Pad Lobby Protocol gives every app its own product
ID and keeps its rooms separate. MeleePad can only browse and join MeleePad
rooms. A small cross-game activity section may show anonymous totals such as
KartPad's open rooms, games in progress, and player count, but not names, chat,
room IDs, connection codes, or IP addresses.

The gameplay layer is not shared. MeleePad keeps its ModernGekko netplay path,
KartPad keeps its own online transport, and each future game needs a small
directory adapter plus its own compatibility rules. KartPad is planned as the
second proof, not implemented in this MeleePad pass.

</details>

<details>
<summary>Why won't Direct IP connect?</summary>

Check these in order:

1. Both players use the same MeleePad version/build and the supported `GALE01`
   game revision, matching modules, and matching game data.
2. The host keeps MeleePad open, chooses **Host**, and listens on UDP port
   `2626`; the guest chooses **Join** and enters the host's reachable address
   and the same port.
3. On a local network, both devices are on the same trusted network and local
   network access is allowed.
4. Across the internet, the host's router and firewall allow UDP `2626`, or both
   players use a trusted private VPN. Carrier-grade NAT and some firewalls may
   make direct hosting impossible.

Direct IP has no traversal or relay fallback. If the network cannot accept the
incoming peer, changing the input buffer will not fix discovery. Prefer a
Private Room unless you specifically need Direct IP for controlled testing.

</details>

<details>
<summary>Does online play support four players?</summary>

The development Public Games lobby now supports two-, three-, and four-seat
rooms, and clearly shows who is seated and which spots are open. That is the
lobby experience, not proof of a four-player match.

MeleePad's retained gameplay evidence still covers two connected endpoints.
Four-player gameplay needs explicit protocol, controller-slot, host-loss,
disconnect, latency, and physical-device testing before it can be called
working. Treat four-seat rooms as development UI until that gate passes.

</details>

<details>
<summary>Why doesn't Slippi work with MeleePad?</summary>

Slippi is not a service that MeleePad can simply turn on. It combines
extensive injected game code, a customized Dolphin
runtime, rollback networking, accounts, and private matchmaking services.

MeleePad supports v1.02 and v1.00 in Preview 4 and uses its own
fixed-delay protocol. Sharing the v1.02 target does not make it Slippi-compatible.
Slippi supports Melee v1.02 and expects Slippi's game modifications and network
protocol. The two systems are not compatible, so MeleePad users cannot join the
normal Slippi player pool. Supporting that would require a major separate port
and cooperation from Project Slippi; it is not planned for MeleePad.

</details>

<details>
<summary>What works on a physical iPhone or iPad today?</summary>

The game launches and plays on physical iPhone and iPad devices with Metal rendering, touch
controls, supported physical controllers, persistent game data and saves, and
the native settings menu. One observed solo run held close to 60 FPS at 2x
resolution; another later run sustained 46–57 FPS under serious thermal
pressure after an extended in-game pause.

Known water, reflection, and shadow rendering defects remain, and the full
device acceptance matrix is still in progress. Physical-device online play has
not passed its release gates. Latest iPhone 14 logs include 37.9–45.6 FPS
slowdowns and audio starvation. The September 9 follow-up retained diagnostics,
not a proven speed fix; see the [resume handoff](SESSION-HANDOFF-2026-09-09.md).

</details>
