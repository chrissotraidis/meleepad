# Private Room community testing

MeleePad Preview 3 build 7 is ready for controlled attempts with trusted
testers. It adds peer chat to the room screen. It is not a finished multiplayer
beta. These tests determine whether the fixed-delay peer-to-peer gameplay is
reliable and enjoyable enough to justify a public game browser.

Preview 2 build 5 can still test connection and gameplay, but it does not have
the Private Room chat composer. Use the same build on both devices.

## What this test proves

Room creation proves that one device can register with Dolphin's public
traversal service and receive a code. It does not prove that another network
can reach the host.

A joined lobby proves that traversal introduced two devices. It does not prove
that they can finish a synchronized match.

The useful acceptance result is a complete match, results screen, return to
character select, and rematch across independent networks.

## Before testing

Both players need:

- the same locally built, playable MeleePad version and build on both devices;
- Preview 3 build 7 when testing Room Chat;
- their own exact supported `GALE01` USA revision-0 game image and locally
  generated module;
- matching gameplay settings;
- ordinary home Internet where possible; and
- a private channel for sharing the temporary room code.

For the baseline, turn off VPNs and avoid cellular, hotel, school, and workplace
networks. Keep MeleePad open in the foreground. The players should use separate
Internet connections; they do not need the same Wi-Fi or public IP address.

## Run the test

1. The host opens **More (•••) → Online Play → Private Room → Host**.
2. Record the approximate time from tapping Host until the room code appears.
3. Share the eight-character code privately. Do not post it publicly.
4. The other player opens **Private Room → Join** and enters the code.
5. Record whether the player joins and the approximate displayed ping.
6. Send one short Room Chat message in each direction and record whether each
   message appears once with the correct player name.
7. Both players mark Ready and the host starts the match.
8. Complete a match, reach results, return to character select, and start a
   rematch without recreating the room.
9. If that succeeds, continue for at least 30 minutes and note delay, stutters,
   audio problems, heat, disconnects, or desync messages.

Start with two players. Four-player testing comes later because one unstable
connection can affect the whole fixed-delay session.

## If room creation appears stuck

`Creating lobby` means the host is starting the local netplay session and
registering with Dolphin's traversal service. A slow success is not the same as
a failure, so record approximately how long it took.

If it does not complete:

1. tap **Cancel**;
2. turn off any VPN;
3. verify ordinary Internet access;
4. retry once; and
5. if it still fails, export diagnostics before relaunching the app.

If joining fails, retry with the other player as host. Preview 2 has no relay,
so some NAT and firewall combinations will not connect even when room creation
works.

## Report the result

Use **More (•••) → Share Diagnostic Logs** and attach the reviewed export to a
[GitHub issue](https://github.com/chrissotraidis/meleepad/issues/new). Copy this
template into the issue:

```text
MeleePad version/build:
Host device and OS:
Guest device and OS:
Host and guest general regions:
Same network or separate networks:
Connection type on each side (home Wi-Fi, cellular, other):
VPN active on either side: yes/no
Host direction:
Approximate time to create room:
Connection attempts / successful connections:
Approximate displayed ping:
Room Chat host to guest: pass/fail/not tested
Room Chat guest to host: pass/fail/not tested
Full match completed: yes/no
Results screen reached: yes/no
Returned to character select: yes/no
Rematch completed: yes/no
Total connected time:
Input delay and stability:
Disconnect, desync, audio, heat, or lifecycle problems:
Diagnostic report attached: yes/no
```

Do not include player names, active room codes, full IP addresses, game data,
generated modules, saves, signing material, or precise home locations. Review
the diagnostic file before uploading it.

Private Room messages use the same unencrypted peer connection as gameplay.
They are temporary and excluded from MeleePad's diagnostic export. Share only
the behavior and pass/fail result in a public issue, not the message text.

## Go/no-go decision

Public discovery remains deferred until independent reports show that Private
Room connects reliably, completes matches and rematches without desync or
crash, and feels acceptable at the measured latency. A polished public lobby
cannot repair an unreliable gameplay connection.
