# G8 attract stage/workload factorial

Date: 2026-09-01

Status: **ROW 7 FAIL; BIG BLUE/COLD-STATE INTERACTION IS CONTROLLING**

## Question

Does the ordinary attract collapse follow four-player combat, HEVC recording,
or a narrower stage/roster and first-use workload?

## Visual reconciliation of the failing run

Frames extracted from the retained failing ordinary recording identify two
different four-player demonstrations rather than one generic attract state:

- Brinstar initially reports 61.4 FPS, then 49.3 FPS with Captain Falcon,
  Link, Kirby, and Fox visible; and
- Big Blue later reports 27.5 and 35.3 FPS with Ness, Peach, Ice Climbers, and
  Bowser visible.

The matching runtime's sustained 21-35 FPS, 96-99.7% CPU-thread use, 49-73%
video-thread use, and 447 DMA underruns therefore belong primarily to the Big
Blue phase. The earlier PERF-271 description of a generic four-fighter attract
collapse was too broad. Its private video and runtime hashes remain:

- video:
  `70c17b26f0d1b271dc7becff89290552d81c0aedcf7013b8001f9c1edca35f52`;
- runtime:
  `18f220977a570cec923b193967479a8d43600d94e0ba649761b7aa7052f97de3`.

## Recorder factorial on the unchanged implementation

A source-identical Release build with all diagnostic environment disabled ran
the ordinary attract path again while `simctl` recorded HEVC. This arm retained
the existing app data and host caches; it is a recorder reversal, not a fresh-
install reversal.

The visible four-player Hyrule Temple match contains Mario, Link, Fox, and Ice
Climbers and reports 59.9 FPS. Runtime holds 59.7-60.0 FPS/VPS through the
moving match, CPU-thread use peaks near 80%, video-thread use near 52%, and DMA
underruns rise only 0 to 2. Private evidence:

- video:
  `eddc50305b76963bb2f5f0fe26a220ffd5e27db788a6e5e08d6c75e67bd0631b`;
- runtime:
  `cd21a11c30628fcbeff2302a77342e3886a0899fac8b69f8170ff2fffd3f9870`.

HEVC recording alone is therefore refuted. Four fighters alone are also
refuted. Stage/roster work and first-use state remain entangled: Hyrule on a
warmed install passes, Brinstar degrades, and Big Blue collapses in the earlier
ordinary run.

## Path-capture correction

Patch 0036 adds a default-off dispatch-burst trace. It retains 16 consecutive
entries every 16,384 native dispatches, so real successor paths survive while
sampling only about 0.1% of entries. The first trace captured a passing attract
route and is not Big Blue optimization evidence. Its private CSV has SHA-256
`150451b3bdbf4b31a73e024c433a7465c9b80ba72a6fdd6c8e1318a3b5c68eb4`.

The trace now records both present-frame and emulated-frame identity. The edge
analyzer ignores burst index zero because its predecessor crosses an
unsampled gap. This repairs the alignment ambiguity exposed by the first run.

## Decision

Keep row 7 failed, but narrow the next mechanism run to Big Blue. Do not build
an eight-region register-resident candidate from the passing Hyrule trace or
from an unaligned generic attract window.

The next falsifiable sequence is:

1. retain a present-aligned Big Blue interval with phase plus sparse burst
   logging and no video recorder;
2. compare it with a matched Hyrule interval from the same binary and warmed
   state;
3. separate guest cycles/dispatch paths from video-build work and first-use
   resource creation; and
4. proceed with broad register-resident C regions only if Big Blue still needs
   material on-core CPU reduction and the selected paths project the required
   whole-frame gain.

If no-recorder warmed Big Blue holds 60 FPS, the architecture rewrite is not
earned; isolate cold resource/cache state instead. If it reproduces 21-35 FPS
with roughly 8.11 million guest cycles and CPU saturation, Big Blue becomes
the representative architecture corpus. Physical-iPad promotion and G9 remain
closed either way.
