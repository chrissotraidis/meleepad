# G5 macOS precision-pacing contention rejection

Date: 2026-08-26

## Question

The independent stale-state review was retained verbatim and as an actionable
repo review in the 2026-08-25 artifacts. Applying its exact-source and
mechanism-first discipline to the rejected cache-control PGO bracket showed a
different tail from the earlier corrected-module control: after excluding the
single >100 ms guest-work stall, the PGO p95 tail had 0.301 ms less CPU-thread
work but 1.972 ms more throttle sleep, including 0.526 ms more wake lateness.

Would a macOS-only earlier wake plus a non-scheduling final spin remove that
tail without changing guest speed?

## Host preflight

`scripts/g5_pacing_preflight.cpp` alternates Dolphin's current final
`std::this_thread::yield()` loop with a true compiler-fenced busy spin under an
identical 16.683333 ms synthetic frame period and 10 ms busy workload.

At Dolphin's current 1.02 ms wake lead, 600 samples per mode showed both modes
waking too late: scheduler-yield p95 was 18.523932 ms and busy-spin p95 was
18.523002 ms. Changing only the final spin was rejected before a game build.

A distinct 3.02 ms wake-lead plus busy-spin combination passed the longer host
screen:

| Mode | Frames | Mean | p95 | p99 | Worst | <=16.7 ms |
|---|---:|---:|---:|---:|---:|---:|
| Scheduler yield | 900 | 16.685164 | 16.692508 | 16.708384 | 16.732000 | 97.889% |
| Busy spin | 900 | 16.683437 | 16.683375 | 16.686333 | 16.694459 | 100.000% |

This combination had not been tested by the prior rejected 2.02 ms
scheduler-yield experiment or the prior 1.02 ms ARM `yield`-hint experiment.

## Candidate identity and stale-module exclusion

The temporary candidate was Apple-only: it woke 3.02 ms before the deadline
and used `std::atomic_signal_fence` in the final loop. Windows and other Unix
paths were unchanged.

- candidate packaged runner SHA-256:
  `8c63cbd316ef9594f728676459b31b50e0bbba710658dce9ea6865ccbd0d3d11`
- corrected profile-free module source identity:
  `0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448-06852d9fd6223c6a`
- corrected macOS 14 module SHA-256:
  `2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`

The first package incorrectly followed a stale ignored `active-module.txt`
entry with source suffix `980a899e17d23ea5`. Its 3,369-frame bracket was
excluded: it recorded 20,421,643 cache fallbacks, zero direct cache helpers,
and 18.179 ms mean / 20.348 ms p95. It is not candidate evidence.

The canonical `prepare-game.sh` path was then rerun from the verified local
GALE01 revision-0 image. It selected suffix `06852d9fd6223c6a`, rebuilt all 237
chunks, reproduced the known-good `2dce1352...` module hash, targeted macOS
14, exported only `_staticrecomp_get_module`, and generated all 14 cache sites
through `ppc_cache_control`. Packaging then used that exact module.

The bootstrap audit also learned how to verify intentionally overlapping
canonical patches 0005/0006 through unique retained symbols and now permits
the separately verified patched DolRecomp submodule. This fixes reproducible
bootstrap of the composed dependency tree.

## Route and visual gate

The accepted run started MemoryWatcher before exactly one runner. A live trace
observed opening-movie `GameState` values `0x28002D00`, `0x18182800`,
`0x18182801`, and `0x18182802`; the genuine title lockout then counted
`0x14` to zero at `0x804D4594`. A one-second START hold produced
`GameState=0x01011800`, and the watched menu route reached CSS at
`0x02020100`.

P1 Pikachu versus CPU Peach, the explicit `Fountain of Dreams` stage label,
coherent live Fountain combat, and Cubeb were visually verified. A focused
80 ms right-stick route corrected the stage cursor from Yoshi's Story to
Fountain without overshoot. The retained visual shows coherent real meshes and
only the known reference-parity lower reflection.

## Strict Fountain result

The capture-free 20-cycle bracket used source CSV lines 19,672-22,986 and
trimmed 120 rows from each edge. The retained 3,074 rows measured:

| Metric | 3.02 ms + busy-spin candidate |
|---|---:|
| Mean | 19.667450 ms |
| Median | 19.631833 ms |
| p95 | 22.357238 ms |
| p99 | 24.689581 ms |
| Worst | 141.483500 ms |
| Frames <=16.7 ms | 2.895% |
| FPS from mean | 50.845 |

The interval had zero fallback steps and zero cache fallbacks. It recorded
18,635,844 direct cache helpers (6,062.409/frame) with exact subclass
accounting. CPU-thread time rose to 19.436646 ms mean / 22.134254 ms p95,
while requested throttle time and wake lateness were both zero. Video-build,
present, and audio p99 remained only 0.144/0.065/1.382 ms.

The game evidence therefore falsifies the host preflight: the longer busy
deadline region creates enough contention or sustained CPU pressure that the
following guest work becomes slower and the emulator no longer reaches the
throttle point. The absolute gate fails by a wide margin regardless of the
historical control.

## Decision

**CANDIDATE REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.** The
timer edit and patch-stack entry were removed. The normal runner rebuilt and
the app was repackaged with runner SHA-256
`c26625db7fd1eb504f418ad8ab52a3accc61bb222fd08b369c7804a5465d5598`
and the corrected `2dce1352...` module. No runtime or Simulator remains.

The next single experiment is an exact matched Fountain control using that
restored runner, corrected module, watcher-first route, same roster/stage/audio,
and same 20-cycle bracket. It must first reproduce zero cache fallbacks and
direct-cache accounting. That control decides whether to return to generated
host-cost attribution or investigate post-build host pressure; do not test
another timer variant first.

## Retained artifacts

- `g5-macos-pacing-contention-fountain.csv` — SHA-256
  `41dfd02eea044fedc0619405c155a9a70853d24821a37b5cda46b7f09a71c661`
- `g5-macos-pacing-contention-fountain-visual.jpeg` — SHA-256
  `0377cc8558c828191cd00c2353ac1bffe224309edd2abfbd1bcfafa5d97089aa`

