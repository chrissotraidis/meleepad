# PERF-266 — duplicate-XFB presentation reversal

Date: 2026-09-01

Status: **major visible-speed reversal; row 7 still fails**

## Question

The synchronized CPU/video candidate executes Melee near real time, yet a
recorded moving transition froze for 1.732 seconds. Default-off boundary
counters showed 101 XFB output requests, 101 queued and executed swaps, 100
duplicate classifications, and only one present. This reversal asks whether
the iOS-only `GFX_HACK_SKIP_DUPLICATE_XFBS=false` policy restores advancing
pixels, rather than merely changing the FPS label.

## Front-end reversal

The Release candidate executable SHA-256 was
`61852513ae5ba5ba870669ac925bb2dc879d79b59af1677aaa37fc21e92dad8f`.
With duplicate suppression disabled:

- every duplicate-classified XFB in the inspected transition was presented;
- the former 1,731.666 ms gap disappeared;
- the largest corresponding post-frame-5000 host gap was 59.038 ms, with the
  next largest 30.367 ms;
- eight samples spanning the transition had eight distinct PNG hashes; and
- visual inspection confirmed the Melee title animation advancing while the
  overlay remained at 59.9 FPS.

This accepts the mechanism: Melee can update the contents behind a stable XFB
identity, so Dolphin's default duplicate-cache-identity policy is not a safe
proxy for unchanged iOS pixels. The fix is a product configuration correction,
not a performance toggle.

Private evidence hashes:

- candidate front-end phase CSV:
  `8d883a2a8aa9f66f82495738d7b8144ca3e876c833ffb4703bc9929976d3e9c3`;
- synchronized front-end video:
  `606c9560b4140de9d199d22cdf1c2ac9cf2bce4ba39cd2ee6b689b4278557839`.

## Exact Fountain screen

The unchanged candidate then completed the state-verified P1 Samus versus
level-1 CPU Kirby, Stock/04/05:00 Fountain route. The final ten combat seconds
contained 600 consecutive presentation rows:

- mean 16.684733 ms, approximately 59.94 FPS;
- p95 17.150292 ms;
- p99 18.065917 ms;
- worst 20.715625 ms;
- 86.0% at or below the 16.95 ms diagnostic budget; and
- no duplicate XFB classifications in active combat.

The retained combat frame visibly reports 59.9 FPS and shows advancing attacks,
but the lower Fountain reflection remains malformed. This short run therefore
confirms that the XFB change does not erase the synchronized candidate's combat
speed, while still failing strict tails, full-match duration, audio/lifecycle,
and rendering-correctness acceptance.

A second unchanged-process route extended active combat for a full minute.
Its final 3,597 rows measured:

- mean 16.683199 ms, or 59.9405 FPS;
- p95 17.437458 ms;
- p99 18.696834 ms;
- worst 71.069625 ms; and
- 11 runtime pipeline creations without a sustained FPS loss.

The 71.070 ms outlier was 70.712 ms CPU wall time but only 11.870 ms CPU-thread
execution, with zero pipeline time. The recorded screen still read 59.9 FPS at
that point and 60.0 FPS later. This is an off-core host/Simulator scheduling
event followed by catch-up, not proof of insufficient static-recompiler
throughput. It still fails the written worst-frame gate and must be repeated
without the screen recorder and on hardware before release judgment.

Private evidence hashes:

- exact-route phase CSV:
  `66a86b083e41663ac2c908a741e4bab670521bf51635c3dbc2082febae65342e`;
- exact-route video:
  `d162a0998ba7247cd6f2807a3081bdbd0d6124424226bc81a6560ae45531e7f4`;
- inspected active-combat PNG:
  `094a3c61319aae5c25032a24672e4a966891e20e896749484a6fa9a833525d02`.
- one-minute exact phase CSV:
  `27712d43f7e1001ac21ebec3a848aff5a83a97079675ed4284885de065f860bb`;
- one-minute synchronized video:
  `d8ef56cab14a9e8470b3a2df2a30c1150157d525843b5bfa9809b7ec8cda6bdf`.

## Decision

Retain synchronized CPU/video execution plus iOS duplicate-XFB presentation as
the only current candidate with both enough throughput and a proven fix for the
visible front-end freeze. The minute-long exact capture confirms the core speed
problem is feasible and no further speculative generated-code optimization is
justified before product validation. Do not call row 7 passed or promote to a
physical iPad yet. The next gates are the ordinary cold manual route, audio and
lifecycle retention, and the pre-existing Fountain rendering defect. Fast
corrupted output remains a failure. G9 netplay stays queued.

The app was stopped and all diagnostic Simulator variables were cleared. ROM,
generated source/module, saves, logs, videos, phase traces, and private paths
remain untracked.
