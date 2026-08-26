# G5 instruction-front-end preflight

Date: 2026-08-26

## Question

Does the common generated-code footprint explain both crowded combat and the
slow How-to/menu path strongly enough to justify a broad chunk-outlining
change?

## Visually gated workloads

- Four-player Pokemon Stadium combat (Bowser, Fox, Captain Falcon, Donkey
  Kong) was visibly live at 50.3 FPS. Retained screenshot:
  `docs/evidence/g5-front-end-preflight/four-player-pokemon-stadium-50.3fps.jpeg`
  (SHA-256 `775afb9ef5f870d9f6f09dba4b4e17993afe78e8b761e2fa77e8c80c06155c61`).
- The real How to Play Mario/Bowser instructional fight was visibly live at
  46.1 FPS. Retained screenshot:
  `docs/evidence/g5-front-end-preflight/how-to-play-46.1fps.jpeg`
  (SHA-256 `bd8b9dc916a90ad7806efe6b212000f94120bf76546c6c28635d8800b089ef78`).
- Both captures used a uniquely identified temporary diagnostic bundle. No
  Simulator was booted and only one game process existed.

## Hardware-counter result

Apple CPU Counters were attached for three seconds to the visually identified
runner. On the emulator CPU thread:

| Workload | Instruction delivery | Discarded | Processing | Useful |
|---|---:|---:|---:|---:|
| Four-player combat | 53.6% | 5.5% | 7.8% | 33.1% |
| How to Play | 20.2% | 3.5% | 1.6% | 74.7% |

The four-player video thread measured 28.9% delivery / 51.3% useful; How-to's
video thread measured 42.3% delivery / 35.3% useful. A simple `yes` control
measured 26.8% process-level instruction-delivery share.

Frames 19,250-19,450 of the visually identified How-to interval independently
measured 21.252 ms mean total, 23.950 ms p95, 20.493 ms mean CPU-thread work,
about 8.099M guest cycles, and only 41,372 native dispatches/frame. This is the
counterexample to a common dispatcher or common instruction-front-end cause.

## Hot-chunk preflight

Four-player dispatch samples in frames 6,900-7,050 included repeated addresses
inside both giant generated chunks `0x80015940-0x80019940` and
`0x80345940-0x80349940`. Standalone native compilation showed that `-Oz`
could reduce their text from 350,202 to 216,276 bytes (-38.2%) and from 322,546
to 205,932 bytes (-36.2%).

Two full-link attempts did not create a candidate artifact:

1. Per-source `-Oz` ThinLTO bitcode was re-optimized under the global link
   policy and produced the exact canonical dylib.
2. Replacing the same two inputs with native `-Oz -fno-lto` Mach-O objects and
   invoking the recorded link command also produced the exact canonical dylib.

All three dylib hashes were
`258da42dd49831432f2c567b30ebb397635312eb95e43b335df4cfc86c291b52`,
with an 81,633,212-byte `__text` section. Because no materially different
binary existed, no semantic or runtime claim was made for either attempt.

## Decision

**BROAD OUTLINING REJECTED; TWO-CHUNK SIZE CANDIDATE DID NOT ENTER THE FINAL
BINARY; G5 OPEN; G6 BLOCKED.** Crowded combat has a real instruction-delivery
problem, but How-to does not share it. Treating them as one bottleneck would be
wrong. The two active module objects were restored to their exact canonical
hashes, the active source-built module is canonical `258da42...`, and the
packaged module/runner remain canonical `2dce1352...` / `9bff54e4...`.

Next: capture a clean native CPU sample over the visually gated How-to interval
and combine it with its frame-PC log. Optimize only a named routine or helper
that accounts for material CPU-thread work; do not retry dispatcher, timer,
chunk-size, or broad-outlining variants without new evidence.
