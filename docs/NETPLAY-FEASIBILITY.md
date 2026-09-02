# ssbmpad netplay feasibility and delivery plan

Status: product and architecture plan complete; implementation and gameplay acceptance not started

Written: 2026-08-28; substantially re-audited 2026-09-01

Scope: native fixed-delay online friend play for the existing GALE01
static-recomp runtime, including macOS, physical iPhone/iPad, and Simulator
endpoints, an eight-character room-code traversal service, direct-IP fallback,
the three-dot-menu UX, touch controls, lifecycle, diagnostics, and acceptance

## Decision

Netplay is feasible on the current stack and can be a final ssbmpad feature,
but the Host/Join controls in the current macOS package are not a working
Melee implementation.

The reusable parts already exist: Dolphin's ENet transport, lobby protocol,
fixed-delay input queues, settings/save synchronization, compatibility checks,
desync reporting, and ModernGekko boot-session handoff. The blocking defect is
specific and falsifiable: ModernGekko generates GameCube controller profiles
for ssbmpad, while its customized netplay server assigns every requested slot
to Dolphin's Wii Remote map. Melee therefore starts without the networked
GameCube pad mapping it needs.

The right route is to finish Dolphin-style fixed-delay netplay, not introduce
Slippi rollback. Rollback would require a substantially different state
capture, restore, prediction, replay, audio, rendering, and matchmaking effort.
It remains outside this plan.

This research is an isolated design lane. It does not change the active G8
row-7 acceptance gate or modify the canonical runtime/package. Implementation
starts with a failing protocol regression and an isolated build, not with the
installed product.

## Requirements interpretation

The requirements are now reconciled: G9 fixed-delay online friend play is in
scope, while Slippi rollback, accounts, ranked matchmaking, public lobbies,
spectating, and replay services remain non-goals for the first release. G9's
minimum evidence still requires an iPadOS endpoint. The stronger public claim
"supports online play on iPhone and iPad" additionally requires physical-device
and real-internet evidence; a Simulator-only match is not enough for that claim.

## What exists today

### Product-visible macOS path

The packaged frontend already exposes `Host Netplay` and `Join Netplay`.
Nickname, host/IP, UDP port, and automatic or manual buffer settings are saved
in `config.ini`. The frontend launches `SsbmPadRunner` with one of:

```text
--netplay-host
--netplay-join <host>
--netplay-port <1..65535>
--nickname <name>
--buffer <auto|1..20>
--controller <device>
```

The default is direct UDP port 2626. There is no matchmaking service, session
index, NAT traversal, relay, account, password, or room code.

### Session behavior

Both endpoints run the full game simulation. The host creates a Dolphin
`NetPlayServer` and then connects a local `NetPlayClient`; a joiner connects a
client to the supplied address. The lobby tracks players, ping, controller
slots, game compatibility, readiness, and the input buffer. The host can start
only after at least two slots are occupied and every machine is compatible and
ready.

At start, Dolphin creates `BootSessionData` containing the synchronized
netplay settings. ModernGekko transfers that data into `Runtime::Run()`, so the
normal static-recomp runtime boots under Dolphin's netplay layer rather than a
separate emulator path.

The configured network mode is `fixeddelay`:

1. Each machine polls its local controller.
2. Input is sent through ENet's input channel.
3. Every machine consumes the same ordered input stream after the configured
   buffer.
4. If a required remote input is absent, emulation waits instead of predicting
   it.
5. Automatic buffering uses observed ping/variance and can increase the
   buffer after meaningful input waits; manual mode fixes it at 1-20 frames.

This preserves deterministic lockstep but adds input latency. It does not
rewind or replay frames.

### Compatibility and diagnostics

The connection fingerprint covers:

- ModernGekko netplay protocol and source revision;
- disc ID and hashes of the DOL, REL field, and extracted assets;
- module and CPU ABI versions plus CPU-state size;
- static-recomp descriptor ranges and chunk hashes; and
- discovered mods and mod ABI.

The descriptor fingerprint deliberately ignores host function addresses, so a
macOS dynamic module and an iOS attached/static module can agree when their
guest-code descriptors are identical. That is the correct cross-platform
foundation for Mac-to-iPad play.

Dolphin already reports connection loss, incompatibility, ping, buffer changes,
input-wait telemetry, and timebase desyncs. The current desktop UI stops the
runtime on a reported desync. The recent deterministic savestate harness is
not rollback infrastructure, but it is useful for seeding repeatable netplay
tests without committing live game state.

### iOS substrate

SsbmPad now has a functioning native iOS/iPadOS shell:

- the Release app embeds the ModernGekko runtime behind `SsbmPadCoreHost`;
- the iOS core already compiles Dolphin `core` and `uicommon`;
- provisioning already force-loads ENet plus SFML network/system archives;
- UIKit touch and GameController input are merged at 60 Hz and published to a
  dedicated virtual GameCube pipe device; and
- the current three-dot menu and diagnostics provide the correct entry and
  support surfaces for Online Play.

Once Dolphin's GameCube netplay map owns pad slot 1, its normal `PollLocalPad`
path can poll that pipe device and transmit the resulting `GCPadStatus`. The
touch overlay does not need a second network-specific input encoder.

## Confirmed blockers

### B1. The server allocates Wii Remote slots

The customized server counts and fills `m_wiimote_map` when clients connect or
change controller count. `m_pad_map` remains empty. The lobby likewise reads
the Wii mapping and labels slots as Wii Remotes. On boot, Dolphin's
`UpdateDevices()` sees no mapped GameCube pads and disables those serial
interface ports.

This is the first implementation gate. A lobby connection is not meaningful
until a focused test fails before and passes after a GameCube pad packet moves
from one client to another through an assigned `m_pad_map` slot.

### B2. The only protocol regression exercises Wii input

`moderngekko_netplay_protocol_test` covers connection failure, compatibility,
room capacity, readiness-related state, adaptive buffer propagation, and a raw
`WiimoteData` packet. It does not exercise `PadData`, `GCPadStatus`, a booted
runtime, Melee, or a completed match.

The test has passed in the recent G5 checkpoint suite, which proves that the
existing protocol still builds and its current Wii-oriented contract works. It
does not prove ssbmpad netplay.

### B3. Session ownership is coupled to the desktop lobby

`RunNetplayLobby()` combines four concerns in one desktop-only file:

- Dolphin service lifetime;
- server/client state and boot handoff;
- SDL/ImGui windows and controller enumeration; and
- runtime creation and restart.

The current iOS shell cannot reuse that function because it owns UIKit,
CAMetalLayer, lifecycle, touch input, and presentation. The session state
machine must be separated from the desktop view without creating a second
protocol implementation.

### B4. iOS permission and lifecycle behavior is unspecified

Direct unicast connections to local hosts require an
`NSLocalNetworkUsageDescription` in the iOS app's `Info.plist`. No Bonjour key
or multicast entitlement is needed for this direct-IP plan because it does not
browse, advertise, multicast, or broadcast.

A lockstep game cannot silently continue while one endpoint is suspended.
Backgrounding, permission denial, Wi-Fi loss, or peer loss must stop the match,
close the session, retain diagnostics, and return the user to a clear lobby
error state. Reconnecting a running match is outside the first delivery.

### B5. Internet UX and transport trust are limited

The inspected path has compatibility validation but no application-level
identity, password, or encryption layer. Direct internet hosting can also
require UDP port forwarding and firewall changes. The first supported product
claim should therefore be **private room-code play between trusted friends**,
with direct IP as the engineering/fallback path. Relay, public rooms,
authentication, moderation, and encrypted transport are separate future work.

### B6. Determinism has not been proven across product endpoints

Static recompilation, strict settings, and identical guest inputs are a strong
base, but cross-platform determinism must be observed. Recent exact-FMA and
runtime semantic corrections make an old netplay result insufficient. A
successful connection or first synchronized frame is not acceptance.

## Target architecture

Keep one Dolphin protocol implementation and give each platform a small view
adapter:

```text
macOS ImGui lobby                 iPadOS UIKit lobby
        |                                |
        +------ platform-neutral -------+
                 NetplaySession
                 - host/join/stop
                 - players/readiness
                 - buffer/ping/errors
                 - start/boot handoff
                 - runtime attachment
                          |
              Dolphin NetPlayServer/Client
                          |
                 ENet fixed-delay input
                          |
       GameCube pad map -> normal ModernGekko Runtime
```

`NetplaySession` should be a small C++ owner with a snapshot/action surface,
not a new framework. The minimum surface is:

- create host or joiner from role/address/port/nickname/buffer/controller count;
- obtain an immutable lobby snapshot;
- change local controller count and ready state;
- ask whether the host can start and request start;
- take the synchronized boot data exactly once;
- attach/detach the active runtime so stop/desync reaches it; and
- stop and expose a stable exit reason plus bounded diagnostics.

The desktop ImGui view can keep its current appearance while consuming that
surface. The iOS Objective-C++ host can wrap the same owner and publish state
to UIKit on the main queue. No networking types need to enter Objective-C UI
code.

## Delivery sequence

### N0. Preserve and specify the current baseline

Work in isolated build/user directories and do not replace the canonical app
or active module. Record the pinned ModernGekko/Dolphin revisions, current
protocol version, present Wii-oriented passing test, and the known GameCube
mapping failure.

Exit gate: one focused regression demonstrates that a connected client has no
GameCube slot under the current implementation.

### N1. Make controller-family assignment explicit

Add a controller-family setting to the customized server/session path. For
ssbmpad it selects `m_pad_map`; Wii products retain `m_wiimote_map`. Apply the
same selection to connection capacity, slot assignment, count changes,
readiness, lobby display, disconnect cleanup, and start eligibility.

Record dependency changes as canonical outer-repository patches and bootstrap
steps; do not rely on ignored edits under `ref/`.

Extend the protocol regression to send a real `PadData`/`GCPadStatus`, confirm
the remote client receives the exact buttons, sticks, and analog triggers, and
confirm Wii mode still passes.

Exit gate: the GameCube test fails before the patch, passes after it, and all
existing frontend/netplay tests remain green.

### N2. Separate session state from the desktop view

Extract platform-neutral ownership from `netplay_session.cpp`. Keep the
existing CLI and Host/Join frontend behavior as the macOS adapter. Do not alter
the normal solo runtime path.

Add focused tests for:

- host and join lifecycle;
- compatibility and room-full errors;
- two occupied GameCube slots plus all-ready start gating;
- manual and automatic buffer propagation;
- one-time boot-data transfer;
- runtime stop on desync/connection loss; and
- clean destruction followed by a second session in the same process.

Exit gate: the macOS runner builds, the existing lobby behaves as before with
GameCube labels/mapping, and a headless two-client test can start and stop a
session without SDL.

### N3. Prove a real two-Mac Melee session

Use exactly two processes with distinct user, config, save, pipe, and log
directories. Use the same signed app/module identity on both sides. Start on
loopback first, then repeat over LAN/direct IP.

The acceptance run must show:

- both endpoints identify the game/module as compatible;
- each endpoint controls a different Melee port;
- both displays enter the same match;
- movement and attacks from both sides affect the shared game state;
- a full timed or stock match reaches results on both endpoints;
- no desync callback fires;
- frame/timebase checkpoints agree throughout; and
- stopping or disconnecting returns both processes cleanly.

Retain both logs, identities, lobby evidence, gameplay evidence, completion
evidence, and synchronized diagnostic checkpoints. Do not retain or commit a
savestate, extracted game data, or module.

Exit gate: macOS netplay is proven, but G9 remains open because no iPadOS
endpoint has participated.

### N4. Integrate the current iPhone/iPad shell

Add a native Online Play flow with Host and Join, nickname, room code, advanced
direct address/port, automatic or manual buffer, players, readiness, start,
and explicit errors. Reuse the shell's existing visual language and diagnostic
log; do not embed the desktop ImGui lobby.

The iOS core/provisioning path must include the platform-neutral session
object and its existing ENet/SFML dependencies. Add a clear local-network usage
description. Feed the existing virtual GameCube pipe controller into the
mapped local slot. Ensure all UI updates cross to the UIKit main queue and all
session/runtime teardown is serialized.

Exit gate: an iPad Simulator can host and join a lobby, receives an actionable
permission/network error, sends touch input through GameCube netplay, and
disconnects cleanly on lifecycle interruption.

### N5. Complete cross-platform G9 acceptance

Run both directions if the host path is exposed on iPadOS:

1. Mac host, iPad Simulator join.
2. iPad Simulator host, Mac join.

At minimum, one direction must complete the same full-match evidence contract
as N3. Exercise automatic buffer and at least one manual buffer. Verify
permission denial, wrong release/game, occupied room, host loss, and client
loss produce clear bounded failures rather than hangs.

Exit gate: G9 is met only after a completed synchronized match with an iPadOS
endpoint, retained evidence from both sides, no desync, and green repository,
package, solo-game, controller, lifecycle, and netplay regressions.

## 2026-09-01 product re-audit

### Executive answer and difficulty

SsbmPad can credibly support online friend play without inventing a networking
engine. The pinned Dolphin fork already supplies ENet transport, reliable
ordered channels, fixed-delay GameCube input queues, timebase desync detection,
strict settings/save synchronization, direct-IP connections, an eight-character
UDP traversal code, and a small self-hostable traversal server. The iPhone/iPad
app already links the required ENet and SFML archives and already turns touch or
GameController state into the same local `GCPadStatus` path netplay polls.

The remaining project is still substantial because none of those pieces form a
safe mobile product today. The GameCube slots are assigned to the wrong map,
session ownership is tied to SDL/ImGui, the app always boots solo, UIKit has no
lobby, no SsbmPad traversal service is deployed, lifecycle teardown is not
netplay-aware, the transport is not encrypted, strict NAT has no relay fallback,
and no complete two-endpoint Melee match has been retained.

Difficulty classification: **medium-high integration and acceptance work**, not
new-netcode research.

| Scope | Focused engineering estimate | Confidence |
|---|---:|---|
| Correct GameCube mapping plus exact payload tests | 2-4 days | High |
| Platform-neutral session owner and headless tests | 4-7 days | Medium-high |
| Two-Mac direct/LAN match proof | 3-5 days | Medium |
| Native iPhone/iPad Online Play UI and host bridge | 5-8 days | Medium |
| Private traversal-code service and app integration | 3-6 days | Medium |
| Cross-platform/device/NAT/lifecycle hardening | 6-10 days | Medium-low |
| Release/docs/privacy/licensing acceptance | 2-4 days | Medium-high |
| **Friend-code online play total** | **25-44 engineer-days (about 4-7 focused weeks)** | Medium |
| Add a production UDP relay fallback | **+10-20 days (about 6-10 weeks total)** | Low-medium |
| Slippi-style rollback plus matchmaking | **separate multi-month program** | Low |

These are planning estimates inferred from the present source boundaries, not
elapsed-time promises. The largest uncertainty is real-world NAT and
cross-platform determinism, not the UIKit screen.

### Recommended product promise

The first public promise should be:

> **Online Play with Friends (Beta):** host or join a private SsbmPad room with
> a short code. Mac, iPhone, and iPad players can use touch controls or a
> connected controller. Online play uses delay-based synchronization, so nearby
> players and stable networks work best.

Do not initially promise rollback, public matchmaking, ranked play, accounts,
spectating, arbitrary Dolphin interoperability, or universal NAT compatibility.
Do not use the unqualified phrase "works online on iPhone" until a physical
iPhone completes the real-internet acceptance matrix.

### Release ladder

1. **Engineering alpha — direct connection:** two isolated Mac processes
   complete a match on loopback and LAN. No product menu claim.
2. **Cross-platform alpha — direct connection:** Mac and iPad Simulator complete
   a match using touch. This meets the technical G9 minimum only after every
   written gate passes.
3. **Friends beta — room code:** SsbmPad clients use an SsbmPad-operated
   traversal server and eight-character invite code. Physical iPhone and iPad
   join from a different network.
4. **Public beta hardening:** connection-success, latency, lifecycle, privacy,
   diagnostics, and failure messaging meet the matrix below.
5. **Relay decision:** build a UDP relay only if traversal/direct connection
   success is below the product threshold on the tested network matrix. Do not
   pre-emptively build accounts, matchmaking, or a general backend.

### Native three-dot-menu flow

Use UIKit controls and the current SsbmPad visual language. The lobby is a
full-screen sheet/navigation flow above the Metal surface, not an ImGui window
and not another game overlay. Entering it stops the solo runtime cleanly before
network services start; there is never a solo and netplay runtime alive
together.

```text
Three-dot menu
  Online Play…
    Online Play with Friends
      Host a Game
      Join a Game
      Advanced Direct Connection

Host a Game
  nickname -> Create Room
  room code + Copy + Share
  player list / GC port / ping / compatibility / ready
  Automatic buffer (recommended)
  Ready / Start / Cancel

Join a Game
  nickname + 8-character room code -> Join
  same lobby, without host-only Start

During gameplay
  existing touch/controller overlay
  three-dot menu: Online status / ping / buffer / Leave Match
```

#### Entry behavior

- Menu title: `Online Play…` with `person.2.wave.2` or the closest available
  system multiplayer symbol.
- If solo gameplay is active, confirm: `Leave the current game and open Online
  Play?` Then stop the runtime, flush ordinary save state, neutralize input, and
  present the Online screen.
- If game data is missing or the installed module is not eligible, disable the
  row with one actionable explanation.
- Persist only nickname and advanced connection preferences. Never persist the
  last room code.

#### Online home

- Primary actions: `Host a Game` and `Join a Game`.
- One sentence explains delay-based friend play and recommends nearby players.
- `Advanced Direct Connection` contains IP/hostname, UDP port, and manual
  buffer. It is not the default path.
- No public server browser and no chat in version 1. This avoids moderation,
  identity, keyboard, and discovery scope while preserving the core use case.

#### Host lobby

- Display the traversal code as four plus four characters for readability,
  while sending the protocol's eight lowercase hexadecimal characters.
- `Copy Code` and the native share sheet share only the invite code and a short
  instruction; never attach logs, IP addresses, game data, or saves.
- Each player row shows nickname, GameCube port, input source (`Touch Controls`
  or a bounded controller name), ping, `Compatible`/specific mismatch, and
  ready state.
- `Start` is enabled only when at least two GameCube slots are occupied, every
  endpoint has an exact compatibility match, save sync succeeded, and everyone
  is ready.
- Mobile version 1 exposes one local player per device. Additional physical
  controllers on one phone/tablet remain a later extension; this avoids
  ambiguous touch ownership and keeps the first protocol/UI matrix bounded.

#### Join lobby

- Accept paste, uppercase/lowercase, and an optional visual hyphen; normalize to
  eight lowercase hex characters before connecting.
- Show distinct errors for invalid/expired code, traversal unavailable, strict
  NAT, host unavailable, room full, game already running, version mismatch,
  game/module mismatch, save-sync failure, and local-network denial.
- Never collapse those cases into `Connection failed`.

#### During gameplay

- The existing input mixer remains the only touch/controller authority. The
  network layer polls the resulting GameCube pipe device; UIKit never encodes a
  second network-specific controller packet.
- Keep the gameplay overlay unchanged. The menu's Online section shows peer,
  ping, automatic/manual buffer, aggregate input-wait diagnostics, and a
  destructive `Leave Match` action.
- The room code is hidden after gameplay begins and excluded from diagnostics.
- Results and rematches remain inside Melee. Leaving the running game tears down
  the session and returns to Online home, where solo play can be restarted.

#### Accessibility and phone ergonomics

- Build the lobby from native labels, buttons, text fields, lists, and system
  sheets so Dynamic Type, VoiceOver, Switch Control, keyboard navigation, paste,
  and password-manager-style code entry semantics work without custom hit
  testing.
- Label the code as a single value and also expose `Copy room code` as a direct
  accessibility action.
- Keep critical state textual; color is supplementary.
- On iPhone landscape, use a scrollable single-column lobby. Do not shrink the
  player table into unreadable columns.
- The lobby must never consume or leave held gameplay input. Enter, dismiss,
  disconnect, error, and background transitions all publish neutral state.

### Session state model

One serialized state machine owns both networking and runtime handoff:

```text
Idle
  -> CreatingHost | Connecting
  -> Lobby
  -> Synchronizing
  -> Starting
  -> Running
  -> Stopping
  -> Idle | Failed(reason)
```

Only `Lobby` accepts ready/controller changes. Only the host can move
`Lobby -> Synchronizing`. `BootSessionData` is consumed exactly once during
`Starting`. Every failure and lifecycle event is idempotent and converges on
`Stopping`; no UI callback owns a raw Dolphin client/server pointer.

The platform-neutral owner should expose immutable snapshots plus serialized
commands:

```cpp
struct NetplayLobbySnapshot {
  NetplayState state;
  NetplayRole role;
  std::string room_code;
  std::vector<NetplayPlayerSnapshot> players;
  unsigned buffer_frames;
  bool adaptive_buffer;
  bool can_start;
  std::optional<NetplayFailure> failure;
};

class NetplaySession {
 public:
  StartResult Host(NetplayHostOptions);
  StartResult Join(NetplayJoinOptions);
  NetplayLobbySnapshot Snapshot() const;
  void SetLocalControllerCount(std::uint8_t);
  void SetReady(bool);
  void RequestStart();
  std::unique_ptr<BootSessionData> TakeBootData();
  void AttachRuntime(Runtime*);
  void Stop(NetplayStopReason);
};
```

The actual API may use a pImpl/opaque boot handoff to avoid exposing Dolphin
types publicly. The important constraints are one owner, snapshot reads, one
boot-data transfer, and serialized teardown.

### Code architecture and exact seams

```text
SsbmPad Online UIKit                  macOS lobby adapter
          |                                  |
          +---- Objective-C++ wrapper -------+
                          |
                 NetplaySession (C++)
                 state / errors / snapshots
                          |
          Dolphin NetPlayServer + NetPlayClient
                    /                 \
      SsbmPad traversal           direct IP
        room-code service          UDP 2626
                          |
       existing fixed-delay PadData/GCPadStatus
                          |
       existing SsbmPad virtual GameCube pipe
                          |
            touch mixer or GameController
```

Required durable source changes:

- ModernGekko: split `tools/netplay_session.cpp` into a platform-neutral
  session target and a desktop SDL/ImGui adapter.
- Dolphin patch: make requested controller family explicit and use
  `m_pad_map` for SsbmPad capacity, assignment, count changes, readiness,
  display, cleanup, and start eligibility.
- Dolphin client: add a locked `GetPadMappingSnapshot()` counterpart to the
  existing Wii snapshot and retain exact `PadData` validation.
- ModernGekko public/runtime seam: make synchronized boot-data handoff a stable
  API instead of requiring UIKit to call `detail::SetBootSessionData`.
- iOS core build: compile/link the platform-neutral session owner. The app
  already links `core`, `uicommon`, ENet, SFML network/system, curl, and mbedTLS;
  do not add a second networking library for version 1.
- SsbmPadCoreHost: own start/stop for solo or netplay, never both; publish
  session snapshots to the main queue; attach the runtime for stop/desync.
- SsbmPadGameViewController: present Online home/lobby, route lifecycle events,
  and restart solo play after a session ends.
- SsbmPadGameOverlay: add one `Online Play…` action and the small in-match
  status/leave submenu. Do not put nickname, code, or lobby tables directly in
  the `UIMenu`.
- Info.plist: add a plain-language `NSLocalNetworkUsageDescription` before the
  first LAN/direct-IP attempt.

All ignored dependency changes must be reproduced by canonical outer patches
and bootstrap checks. Never commit a module, save, game image, room code, IP,
or private device identifier.

### Why touch controls need no netplay fork

The normal iPhone/iPad publisher already runs at 60 Hz:

```text
UIKit touch + GCController
  -> SsbmPadInputMixer::consumeMergedState
  -> SsbmPadCoreHost::publishInput
  -> Dolphin pipe device / Pad::GetStatus
  -> NetPlayClient::PollLocalPad
  -> PadData containing GCPadStatus
```

Once `m_pad_map` owns the local GameCube slot, the same payload includes digital
buttons, analog A/B, main stick, C-stick, analog L/R triggers, and connection
state. The first regression must compare every field byte-for-byte. The live
mobile test must additionally prove simultaneous stick plus shield/attack,
held-input neutralization on disconnect, touch after a controller disconnect,
and no duplicate local polling.

### Room-code traversal service

Dolphin's current source already contains a small CC0 `traversal_server`
executable and an eight-character host-ID protocol. The service coordinates UDP
hole punching; gameplay remains peer-to-peer and does not flow through it.
That is the correct first online-connectivity layer.

Deploy a SsbmPad-controlled instance rather than depending on Dolphin's public
infrastructure without an explicit service agreement:

- one small Linux service with UDP 6262 and alternate UDP 6226;
- configurable hostname compiled/persisted as the SsbmPad default;
- health check, process supervision, restart policy, metrics, and alerts;
- rate limits/firewall limits against packet floods and host-ID enumeration;
- no permanent room list, accounts, chat, or matchmaking database;
- no long-lived room-code logging; truncate/anonymize network diagnostics;
- a development endpoint distinct from production;
- pinned protocol version and a client-visible maintenance/unavailable error.

The code is IPv4-oriented and explicitly lacks traversal IPv6 support. Record
that as a version-1 limitation and test IPv6-only networks for an actionable
failure. A 32-bit room code is an ephemeral locator, not authentication. Do not
market it as a secure secret.

Strict or symmetric NAT can defeat hole punching. Version 1 therefore keeps
Advanced Direct Connection and documents port forwarding. Before a broad
release, measure connection success across the physical-device matrix. If fewer
than 90% of intended friend-pair attempts connect without router configuration,
the product needs a SsbmPad UDP relay fallback before dropping the Beta label.
A relay is a separate operational/security project; it is not part of the CC0
traversal server.

### Security and privacy boundary

Current ENet packets are reliable but not encrypted. Compatibility fingerprints
prevent mismatched builds; they do not authenticate a person or make transport
confidential. The first release is therefore private friend play between
trusted peers, with no public room browser.

- Do not collect accounts, email, contacts, location, or address books.
- Do not log full IP addresses or room codes in exported diagnostics.
- Treat nickname as public to room participants and cap it at the existing
  30-code-point protocol limit.
- Explain that the host's Melee save/unlocks are copied into Dolphin's temporary
  NetPlay save directory. Verify that the ordinary local GCI remains untouched
  on both endpoints before and after every acceptance run.
- Disable code/mod synchronization for the first release and require exact
  fingerprint equality. Never add a compatibility bypass.
- Add protocol fuzz/length tests for nickname, controller count, pad index,
  save chunks, room code, and unknown message IDs.
- Before a non-Beta public release, perform a focused security review of the
  handshake, save transfer, traversal service, denial-of-service surface, and
  plaintext boundary. Authenticated encryption is desirable future hardening;
  it must not be implied before implementation.

### iOS lifecycle contract

Apple can suspend a normal foreground game shortly after it enters the
background. Netplay cannot pretend that endpoint is still participating.

- In a lobby, temporary inactive state may keep the lobby object but must stop
  accepting commands. `didEnterBackground` closes the session within a bounded
  background task.
- During a match, entering background sends a stop/leave reason, requests
  runtime stop, neutralizes input, closes networking, and returns to Online home
  on foreground. Version 1 does not resume a running match.
- Permission prompts happen while the Online screen is foregrounded. The first
  local-network operation must never be initiated from background.
- Local-network denial, Wi-Fi loss, cellular route change, host loss, and peer
  timeout produce distinct errors and a bounded teardown; no spinner can remain
  indefinitely.
- A system interruption that only resigns active is tested separately from a
  real background transition. If safe synchronized pausing is not implemented,
  the conservative behavior is to end the match rather than advance one peer.

### Revised execution order

The earlier N0-N5 sequence remains directionally correct. Use these smaller,
falsifiable work packages:

| ID | Work | Exit evidence | Estimate |
|---|---|---|---:|
| NP-0 | Freeze protocol/pins and add failing GC-slot regression | Current code proves empty `m_pad_map` and Wii assignment | 1 day |
| NP-1 | Controller-family mapping fix | Exact two-client `GCPadStatus`; Wii regression preserved | 1-3 days |
| NP-2 | Headless `NetplaySession` extraction | Host/join/ready/start/stop twice in one process without SDL | 4-7 days |
| NP-3 | Two-Mac direct proof | Full match to results, two-sided input, no desync | 3-5 days |
| NP-4 | iOS build seam and UIKit Online flow | Simulator host/join lobby, errors, clean teardown | 5-8 days |
| NP-5 | Mac/iPad Simulator gameplay | Full touch-controlled match, matching timebase, no desync | 3-5 days |
| NP-6 | Private traversal service | Stable room code across two outside networks | 3-6 days |
| NP-7 | Physical iPhone/iPad beta matrix | Real-internet matches, touch/controller/lifecycle evidence | 4-7 days |
| NP-8 | Hardening and release claim | Repository/package/security/privacy/docs matrix green | 2-4 days |

NP-0 through NP-2 may proceed in an isolated netplay build while the human G8
row-7 gate remains open. Product integration, installed-app replacement, and a
public claim wait for row 7 and the relevant netplay gates. Every candidate has
an easy rollback: remove the outer patch/UI action and keep the canonical solo
product unchanged.

### Acceptance matrix for the public claim

All endpoints use the same public candidate and exact GALE01/module
fingerprint. Each run retains both endpoint identities, lobby state, visible
gameplay, results, timebase/desync diagnostics, buffer/input-wait metrics, and
ordinary-save hashes.

| Matrix | Required result |
|---|---|
| Mac host -> Mac join, loopback | Headless/protocol and full-match baseline |
| Mac host -> Mac join, LAN | Direct-IP full match |
| Mac host -> iPad Simulator join | G9 cross-platform minimum |
| iPad Simulator host -> Mac join | Host symmetry or documented client-only mobile scope |
| Mac host -> physical iPhone join, different networks | Full touch match to results |
| Mac host -> physical iPad join, different networks | Touch and connected-controller runs |
| Physical iPhone/iPad host -> Mac join | Required if mobile UI advertises Host |
| Wi-Fi -> Wi-Fi, Wi-Fi -> cellular/hotspot | Room-code connection and stable match |
| Local-network Allow / Deny / re-enable | Correct prompt and actionable recovery |
| Wrong app version/module/game/mod | Explicit mismatch; no start |
| Invalid/expired code, room full, game running | Explicit bounded error |
| Client background, host background, route loss | Peer informed; both stop cleanly |
| Automatic buffer plus manual 2/4/8 frames | Stable telemetry and no hidden override |
| Touch, physical controller, controller disconnect | Correct local slot and neutral state |
| Five-minute Fountain plus a second stage | 59+ FPS/VPS on both, no sustained underrun or desync |
| Results/rematch/leave/rejoin | No stale session, stuck input, save mutation, or leaked thread |

For release, target at least 20 room-code connection attempts across the
network matrix, at least 90% no-router-configuration success for intended
friend play, zero desyncs in ten completed five-minute matches, zero crashes or
hung teardown, and no ordinary-save hash changes. These thresholds may be
tightened after the first physical-device data; they may not be relaxed by
averaging failures away.

### Primary research sources

- Dolphin's official Netplay Guide documents direct connection, traversal room
  codes, input buffers, host choice, strict-NAT failure, and port-forwarding
  fallback: <https://dolphin-emu.org/docs/guides/netplay-guide/>.
- Current Dolphin netplay server/client and traversal source:
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/NetPlayServer.cpp>,
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/NetPlayClient.cpp>,
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Common/TraversalClient.cpp>,
  and <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Common/TraversalServer.cpp>.
- Dolphin's current netplay settings source records the public traversal/index
  defaults and eight-character host-code setting:
  <https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/Core/Config/NetplaySettings.cpp>.
- Apple TN3179 and `NSLocalNetworkUsageDescription` cover direct local-network
  access and the required purpose string:
  <https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy>
  and
  <https://developer.apple.com/documentation/bundleresources/information-property-list/nslocalnetworkusagedescription>.
- Apple's lifecycle guidance requires foreground games to quiet work and
  prepare for suspension when backgrounded:
  <https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background>
  and
  <https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time>.
- ENet's primary repository documents reliable UDP packet/channel behavior:
  <https://github.com/lsalzman/enet>.
- Project Slippi's own architecture notes show why rollback is a different
  scope: it combines Melee ASM, EXI communication, emulator savestates, and a
  non-public matchmaking server:
  <https://github.com/project-slippi/slippi-wiki/blob/master/GETTING_STARTED.md>
  and <https://github.com/project-slippi/slippi-ssbm-asm>.

Public UX anecdotes were intentionally not used to make technical claims. The
plan is grounded in the pinned checkout and primary project/platform sources.

## Parallel-work contract

The active app lane owns G8, the canonical package, active module, runtime
performance patches, and the current iOS shell. The netplay lane may
proceed concurrently only where it does not consume those moving interfaces:

| Safe now | Wait for app seam |
|---|---|
| GameCube failing test and server-map fix | UIKit lobby integration |
| Protocol and compatibility regressions | Final Objective-C++ host API |
| Platform-neutral session extraction | Touch/layout wiring |
| Isolated two-Mac smoke and match proof | Mac-to-iPad acceptance |
| Documentation and diagnostic schema | Lifecycle behavior in the real shell |

Every netplay build uses a separate CMake directory and isolated user trees.
It must not repackage, sign over, launch over, or change the active module
pointer used by G8. Before integration, rebase the canonical patch series and
rerun the full current checkpoint suite because performance/runtime work may
have changed the same ModernGekko files.

## Evidence matrix

| Claim | Required evidence |
|---|---|
| Protocol transport works | Focused host/client regression with exact GC pad payload |
| Compatibility guard works | Accept identical dynamic/attached descriptors; reject changed game/module/mod |
| Desktop lobby works | Fresh Host/Join lobby captures and separate logs |
| Melee is synchronized | Matching frame/timebase checkpoints plus visible two-sided input |
| Match completes | Results screen and clean completion on both endpoints |
| Buffer behaves | Reported buffer and input-wait telemetry under auto and manual modes |
| Failure handling works | Permission, mismatch, room-full, disconnect, and host-loss cases |
| iPadOS works | iPad Simulator lobby, touch input, gameplay, lifecycle, and diagnostic evidence |
| G9 passes | Completed Mac/iPadOS match with no desync and both endpoint identities retained |

## Product boundaries

- Prove direct-IP fixed-delay netplay first, then ship room-code traversal; do
  not market either as rollback.
- Make private-friend, delay-based, strict-NAT, and plaintext boundaries visible
  in the UI and release notes.
- Keep game data, generated modules, private profiles, saves, and savestates out
  of the repository and distributable package.
- Preserve strict build/game/mod compatibility; do not add a bypass to make
  mismatched clients connect.
- Do not weaken solo G5 performance acceptance because netplay wait time is a
  separate metric.
- Review and satisfy ModernGekko/Dolphin GPL and bundled dependency notice/source
  obligations before distributing a final binary. App Store submission remains
  outside the current PRD and is not evaluated here.

## Reviewed source map

- `ref/ModernGekko/tools/moderngekko_launcher.cpp` — product Host/Join controls
  and runner arguments.
- `ref/ModernGekko/tools/moderngekko_run.cpp` — CLI parsing, controller config,
  and netplay entrypoint.
- `ref/ModernGekko/tools/netplay_session.cpp` — desktop lobby, session lifetime,
  fixed-delay settings, boot handoff, and error handling.
- `ref/ModernGekko/tools/netplay_compatibility.cpp` — game/module/mod
  compatibility fingerprint.
- `ref/ModernGekko/src/runtime/dolphin_runtime.cpp` — synchronized boot data and
  input-wait telemetry integration.
- `ref/ModernGekko/vendor/dolphin/Source/Core/Core/NetPlay/NetPlayServer.cpp` —
  current Wii-slot allocation, readiness, and start gate.
- `ref/ModernGekko/vendor/dolphin/Source/Core/Core/NetPlay/NetPlayClient.cpp` and
  `NetPlayClientInput.cpp` — device mapping and fixed-delay pad queues.
- `ref/ModernGekko/tests/netplay_protocol_test.cpp` — present protocol coverage
  and its Wii-only input assertion.
- `ref/sunpad/scripts/ios-provision.sh` and
  `ref/sunpad/apple/ios/SunPadCoreHost.mm` — available iOS network libraries and
  virtual GameCube pipe controller integration.
- `apple/ios/SsbmPadCoreHost.mm` and
  `apple/ios/SsbmPadGameViewController.mm` — current Objective-C++ runtime,
  lifecycle, touch/GameController mixer, and 60 Hz GameCube pipe publication.
- `scripts/ios-provision.sh` — current iOS link closure, including ENet and SFML
  network/system archives.
- Apple, [TN3179: Understanding local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
  and [NSLocalNetworkUsageDescription](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSLocalNetworkUsageDescription)
  — direct local-network access behavior and required purpose string.

## Current conclusion

The project does not need new gameplay netcode from scratch. It needs one
correct GameCube mapping path, a reusable session boundary, native Online Play
screens, a SsbmPad traversal service, and proof that the existing deterministic
input model survives complete Melee matches across Mac and physical iPhone/iPad.
That is a bounded, credible G9 project. Until NP-3, NP-5, and NP-7 pass, the
existing Host/Join controls remain dormant infrastructure rather than a shipped
capability.
