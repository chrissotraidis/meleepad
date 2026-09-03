# PERF-262 — synchronized dual-core exact Fountain reversal

Date: 2026-09-01

Status: **major combat reversal; route still fails; candidate remains unmerged**

## Question

PERF-261 left the synchronized CPU/video split unclassified because its exact
route harness never received MemoryWatcher state. The ordinary installed-app
anchor is still 21.9 FPS in Samus versus level-1 CPU Kirby, Stock/04/05:00,
Fountain of Dreams. This checkpoint asks whether the unchanged PERF-261 binary
actually reverses that combat deficit and, if so, which phases still prevent a
row-7 pass.

## Harness correction

The app-container MemoryWatcher socket exceeds Darwin's 104-byte Unix-domain
socket limit. The existing guarded Simulator override works when a short path
resolves to the exact normal MeleePad user directory and both the app and
`gcpipe.py` use that same path. The corrected socket path was 49 bytes. No
product source change was needed.

MemoryWatcher then proved the complete route, including rules normalization,
P1 Samus, level-1 CPU Kirby, Stock/04, 05:00, Fountain selection, and match
state `0x80477D68=02020102`.

## Exact combat result

The unchanged Release executable SHA-256 was
`5d0965325ebaed5749d44cba790f5b8089ebab6c5d6dec6bf18c748e6d29bcec`.
It completed the exact match twice without the prior malformed-FIFO crash,
unknown opcode, panic, fatal line, callback loss, or process crash. One full
match continued through the results screen after crossing the old 139.4-second
crash boundary. A retained in-combat frame visibly reported 59.9 FPS; its
private SHA-256 is
`b40e833ea3fa9e0ee6d366a1b90b545d1e4d70bc48d5234004d1b26280663c90`.

The second run retained 5,001 consecutive emulated combat frames with no
missing emulated-frame index:

- mean 16.683633 ms (about 59.94 FPS);
- p95 17.481167 ms;
- p99 18.374041 ms;
- worst 91.782083 ms;
- 78.724255% at or below the 16.95 ms diagnostic budget.

Runtime rows remained around 59.9-60.0 FPS/VPS at speed ratio 0.997-1.003 with
separate CPU and Video threads. The candidate therefore reverses the ordinary
sustained 20-22 FPS combat deficit by roughly 2.7x. It does not meet the
written p95/p99 or every-interval gate.

## Remaining mechanisms

The second run reproduced three distinct classes that must not be averaged
together:

1. Cold boot, animated transitions, and first match loading visibly reached
   3.9, 17.7, 37.8, 25.3, and 8.5 FPS before recovering.
2. The match-to-results boundary produced a 1,017.404 ms no-present interval
   while the guest advanced 61 emulated frames. A first run produced the same
   class at 1,048.418 ms while advancing 63 frames. Guest-PC samples and the
   generated instructions identify Melee's synchronous drive-status,
   interrupt-guard, `lbDvd`, and card-polling loop. This is a scene/resource
   transition XFB drought, not sustained guest slowdown and not a proven disc
   error. The earlier isolated `FastDiscSpeed` control already failed and must
   not be repeated.
3. Active combat contained a 91.782 ms wall frame with only 11.403 ms of guest
   CPU work and one Metal render-pipeline creation measured at 101.033 ms
   across the worker timing. The one-second overlay dipped to 56.1 FPS and
   recovered to 63.5. This is a first-use pipeline hitch, distinct from both
   the former sustained static-CPU deficit and scene loading.

The known malformed lower Fountain reflection/geometry remains visible, so
rendering correctness independently fails promotion.

Private diagnostic hashes:

- first phase CSV:
  `83ab4b33ef206495cbd20847b736d6c33516ab6199d256949c7834c2770a4e1f`;
- second phase CSV:
  `b0b32a8569637e03edda42d020a00c5ec50119c3b37b18d3bb338c6498f2f4`;
- second dispatch CSV:
  `0fc5ba7e72728346ef926a7ad9b969a041a2958ac859ef52bb70a033ffbd60fe`;
- second spike marker:
  `dc4245e70ee96db43afe0e75d51cea0d7233867b225f8a902d29dcc5187e12c8`;
- second post-results frame:
  `e490fcfd59662ad7389f020a22a82f539abbe4cb2649d5009222bc178e1a9604`.

## Decision and next experiment

Keep synchronized dual-core as the only architecture currently demonstrating
enough combat ceiling, but keep its code unmerged and row 7 failed. The next
small falsifiable experiment is pipeline-specific: retain the identity and
cache/persistence status of the first slow Metal pipeline, then replay the
same cold exact route. Accept a prewarm or persistence change only if it
removes the 91.782 ms class without new FIFO, visual, input, lifecycle, audio,
or netplay-determinism risk.

After the pipeline hitch, separately classify moving front-end intervals from
intentional blank/static scene loads and repair the malformed Fountain output.
Only then run candidate/control/candidate, two complete cold routes, and the
ordinary manual five-minute acceptance route. Physical-iPad promotion and G9
netplay remain closed.

Both app processes were stopped. The Simulator stayed booted with no app
running, and every diagnostic environment variable was cleared. ROM, generated
source/module, logs, profiles, phase/dispatch traces, app bundles, saves, and
private paths remain untracked.
