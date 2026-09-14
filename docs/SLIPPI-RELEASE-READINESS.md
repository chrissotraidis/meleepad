# Slippi release readiness — 2026-09-14

**Do not describe the public Preview 4 as supporting Slippi.** It remains the
older module-free shell and MeleePad peer-room implementation. The native Slippi
work is a separate, private development build, not a published release candidate.

## What is established

- Private native Slippi builds boot and render menus. The September 14 source
  built for Simulator and iPhoneOS; private build 20 was installed on the owner's
  iPad Pro without changing its ten configuration files or save directory.
- Retained September 12 evidence includes an offline Simulator match near 60
  simulation frames/s and a controlled native pair recovering after artificial
  network latency decreased. Those are bounded tests, not broad compatibility.
- A real Internet Simulator Unranked search connected and one game occurred.
  That game advanced approximately 42.83 new frames/s, with substantial stalls
  and a peer disconnect. It demonstrates progress and an unresolved performance
  problem, not acceptable multiplayer quality.
- The native module identity regression was traced to a vanilla module being
  staged as Slippi. The retained private module covers the required injected
  range. Module coverage and exact disc revision remain mandatory.
- ENet startup RTT/throttle behavior has a focused regression test and is now
  recorded in a pinned ENet fork. Network latency beyond local-router controls
  remains a separate unresolved cause; no renderer workaround establishes a fix.

These observations are summarized from retained private investigation logs and
`SLIPPI-NATIVE-REGRESSION-2026-09-12.md` in the development checkout. Raw logs,
accounts, addresses, game files, and private paths are intentionally not published.
This document does not turn a retained report into new device acceptance.

## Release blockers and proposals

| Gap | Required repair or evidence |
| --- | --- |
| Public app and private Slippi host differ | Review and integrate the Slippi host/account/EXI changes through a separate PR with passing source and app builds. |
| Overlay and native libraries are assembled in local diagnostic directories | Inventory source origins and licenses; record upstream commits, patches or fork commits, nested dependencies, and compiler flags; supply a clean build recipe for the redistributable inputs. |
| Generated Slippi module is revision/injection-specific | Record exact private input hashes, generation procedure, output identity, and native coverage checks. Do not substitute a renamed vanilla module. |
| Physical gameplay/audio acceptance is missing for build 20 | Owner test of offline combat, movement, attacks, sound, pause/resume, and sustained performance on the exact installed build. |
| Internet quality and cross-engine correctness remain unsettled | Controlled actual matches against a named official desktop Slippi version, with state/desync evidence, performance/audio, results, rematch, disconnect and recovery checks. |
| Recipient package has not been accepted | Audit the exact signed-by-recipient package, bundled notices and matching source; verify an in-place install preserves data and runs the same tested behavior. |

The runtime fork migration addresses source ownership and reviewability. It does
not resolve the remaining host/overlay, game-module, network or physical test
items. The next Slippi PR must use reproducible dependency inputs rather than
pointing CI at one maintainer's ignored diagnostic directories.

## Public wording

A truthful progress update now is:

> MeleePad's experimental native Slippi integration is running in private test
> builds. Matchmaking and a game have been exercised, but Internet performance,
> broader compatibility, and release packaging are still being validated.
> Built on ModernGekko, DolRecomp, RecompCore/Dolphin, and Project Slippi.

Once a corresponding public artifact passes the gates, announce **experimental
Slippi support**, identify the exact build and supported modes, and link its
known limitations. Do not imply Project Slippi endorsement, ranked support,
universal desktop compatibility, or full-speed play unless separately verified.
No announcement or new Slippi release is published by this maintenance change.
