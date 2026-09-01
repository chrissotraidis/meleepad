# PERF-261 — synchronized dual-core screen and menu reconciliation

Date: 2026-09-01

Status: **architectural candidate partial; not merged; G8 row 7 remains failed**

## Question

The ordinary visible iPad Simulator control remains 21.9 FPS in the exact
Samus-versus-level-1-Kirby, Stock/04/05:00 Fountain route. Cache/SPR fallback
elimination already removed 98.98% of hook fallbacks without making that route
playable; PGO and broad code-size changes also failed. The only previous
candidate with enough demonstrated headroom was Dolphin's CPU/video split, but
unconstrained dual-core execution crashed after 139.4 seconds on a malformed
XF FIFO command.

This bounded screen asks whether enabling Dolphin's existing guest-cycle GPU
synchronization together with the CPU/video split can retain the architectural
speedup without allowing the CPU to outrun the video FIFO.

## Product-menu decision

The user-facing three-dot menu remains independent of this experiment.
`Experimental Performance Mode` is absent; its old persisted preference is
removed on settings initialization; the stable menu contains render
resolution, aspect ratio, FPS counter, controller mapping, touch settings,
game-data/save actions, direct diagnostic sharing, and problem reporting.
The loop now requires risky scheduling/codegen experiments to use explicit
developer-only build identities, not product toggles.

## Candidate and integrity screen

The unmerged candidate enables `MAIN_CPU_THREAD` and `MAIN_SYNC_GPU` on iOS and
logs `cpuVideoSplit=1 syncGPU=1`. It changes neither the emulated CPU clock nor
the menu. Current upstream Dolphin has the same gather-pipe and opcode-decoder
implementation as the vendored tree, so there was no smaller upstream FIFO fix
to import.

- focused configuration/menu regression: pass;
- canonical dependency bootstrap: pass;
- iOS Simulator core and GALE01 module build: pass;
- Release app build/sign/install: pass;
- candidate executable SHA-256:
  `5d0965325ebaed5749d44cba790f5b8089ebab6c5d6dec6bf18c748e6d29bcec`.

## Runtime result

One diagnostic attract/title process remained alive for 505.552 seconds,
well beyond the previous 139.4-second crash boundary. It logged separate CPU
and video threads and no `cmd2`, unknown-opcode, malformed-FIFO, panic, fatal,
or crash line. Most retained ten-second runtime rows reported 59.9-60.0
FPS/VPS with continuing CoreAudio callbacks. The phase log retained 29,628
rows, 17.062714 ms mean, 2,753.789166 ms cold-start worst, and 9,789 rows above
16.95 ms. Its private SHA-256 is
`6bb584f98377bbb2d945eae29930cda6875b24237de3ab3a28ba9967191d6de8`.

This is not a row-7 pass. A visible title transition showed **47.4 FPS**, and
the automated exact Fountain route did not complete. The first route used the
wrong support root; two corrected attempts then waited indefinitely for the
first MemoryWatcher state predicate while the game remained on the title
screen. Per the loop timebox, the harness branch stopped rather than generating
another non-controlling attract-mode claim.

## Decision and next step

Synchronized dual-core is the first recent candidate with credible ceiling and
substantially better bounded stability than unconstrained dual-core, but it is
still unproven in the controlling combat workload and visibly fails an animated
front-end phase. Keep its code unmerged and row 7 hard-failed.

Next, repair or replace only the cold-route state/input bracket, then run the
unchanged candidate through the exact Fountain control. Reject it on any FIFO
error, visual corruption, interval below 55 FPS, or less than 5% matched
improvement. If it clears that screen, require a longer crash soak plus two
cold exact routes and the ordinary manual route before considering retention.
Netplay determinism remains a later explicit gate; synchronized dual-core does
not by itself prove deterministic netplay.

The app was stopped and all diagnostic Simulator environment variables were
cleared. No ROM, generated module/source, profile, save, phase log, app bundle,
or private path is tracked.
