# MeleePad public lobby goal loop

Status: development vertical slice complete; production service not deployed
Started: 2026-09-03

Current Preview 2 candidate: `0.1.0` build 5 is installed and running on the
physical iPad, with its game data and save preserved. This proves deployment
readiness for device testing only; the physical Internet-match gate remains
open. The public IPA is an unsigned module-free shell and does not expand that
claim.

## Goal

Let a player open Online Play, see compatible public MeleePad rooms, safely
coordinate with another player, and enter the existing traversal-backed match
without exchanging an IP address or room code out of band.

## Definition of done

The public lobby is release-ready only when one unchanged build proves:

1. room cards show host, region, occupancy, state, app version/build, game
   revision, and a clear compatibility result;
2. public list responses never disclose IP addresses or traversal codes, and
   Join returns a code only to an authenticated, compatible player;
3. Host, Refresh, Join, Hide, Report, preset quick chat, Ready, Start, leave,
   expiry, full-room, incompatible-room, and service-outage paths converge on
   understandable native UI states;
4. arbitrary anonymous messages are impossible; names are filtered and
   reports/blocks have durable moderation handling and a published contact;
5. production traffic uses HTTPS with edge limits, persistent storage,
   monitoring, restart supervision, backups, and secret-safe logs;
6. two physical Apple devices on independent networks find one another and
   finish a five-minute match, results, rematch, and clean exit;
7. NAT success, latency, disconnect recovery, backgrounding, and Wi-Fi loss
   meet the wider netplay beta acceptance matrix; and
8. release diagnostics contain no bearer token, traversal code, IP address,
   message content, save, or game data.

## Completed development slice

- Dependency-free JSON service with ephemeral bearer sessions, hashed tokens,
  exact compatibility gates, bounded storage, rate limits, room heartbeats,
  join reservations, quick chat, hide, report, and a health check.
- Native UIKit public-room browser integrated beside Private Room and Direct
  IP, using the existing MeleePad visual language and netplay owner.
- Simulator-only loopback configuration; physical builds reject plaintext
  service URLs.
- Ten service tests plus source/build checks pass.
- A local service room containing a live Dolphin traversal code was discovered
  by the iPad Simulator. Join disclosed the code only after authorization and
  connected it to a Mac host; both appeared compatible in the native lobby.
  Guest presence renewed beyond the initial reservation and quick chat still
  delivered afterward.

## Iteration loop

For each remaining gate:

1. choose the smallest missing production or device claim;
2. write a fail-first service, source, or live acceptance check;
3. make the narrowest change that preserves private rooms and Direct IP;
4. test failure and abuse paths before the happy path;
5. run the unchanged candidate on independent endpoints;
6. retain redacted evidence and update status; and
7. stop widening the feature if the stronger claim did not pass.

Next gate: choose and authorize a production service owner/domain, then replace
the in-memory report/room store with a durable operational deployment. Until
that passes, the UI remains a development feature and must not imply a live
public player population.

## Roadmap to the next preview

### P1 — supported staging service

- Select the service owner, region, domain, privacy contact, and abuse contact.
- Put the API behind HTTPS and edge connection/rate limits.
- Replace in-memory rooms, blocks, and reports with bounded durable storage;
  keep traversal codes and bearer tokens out of logs and backups.
- Add migrations, health/ready checks, restart supervision, metrics, alerting,
  retention deletion, and a tested rollback.
- Configure staging only in an internal build and prove outage/error copy.

### P2 — physical Internet acceptance

- Run iPad-host/Mac-join, Mac-host/iPad-join, iPad/iPhone, and reverse-device
  directions on genuinely independent networks.
- Complete five-minute matches through results, rematch, and clean leave while
  checking saves, touch/controller input, audio, thermals, and diagnostics.
- Exercise full, stale, incompatible, blocked, reported, backgrounded, Wi-Fi-
  lost, host-lost, and service-unavailable paths on the unchanged candidate.
- Record NAT success by network type; if it is below 90%, decide on a relay or
  explicitly narrow the preview instead of hiding failures.

### P3 — moderated production canary

- Complete privacy/security review and App Review Guideline 1.2 support copy.
- Deploy a small canary, monitor join success and abuse reports, and verify
  operators can remove rooms/identities without retaining gameplay data.
- Promote the same endpoint/configuration only after rollback, alerting,
  deletion, and moderation drills pass.

### P4 — next release preview

- Freeze one version/build/protocol tuple and reject every mismatch visibly.
- Re-run repository, signing, package, installation, lifecycle, and physical
  gameplay gates from the frozen candidate.
- Publish only claims earned by retained evidence. Keep Public Games disabled
  if the supported service or moderation gate is not ready; Private Room and
  Direct IP remain the safe fallback.
