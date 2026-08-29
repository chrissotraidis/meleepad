# G5 low-overhead Fountain pacing reversal

Date: 2026-08-29

Status: **DETAILED OBSERVER CONFOUND CONFIRMED; RESIDUAL G5 PACING FAILS**

## Question

Does Fountain's 34.499 ms PERF-142 worst frame survive when the current-PGO
native product runs without the detailed phase logger and its per-slice
`CLOCK_THREAD_CPUTIME_ID` calls?

PERF-144's fresh native sample placed 143 top-of-stack samples in macOS
`__thread_selfusage`. Earlier PERF-056 evidence already showed that full phase
logging costs roughly 1-2 FPS, but that control predated the current-PGO build
and did not establish whether today's severe Fountain tail was observer-free.

## Low-overhead harness

PERF-145 and its independent PERF-146 repeat used:

- the same current-PGO native arm64 runner/module code as PERF-142;
- the same private Fountain slot-1 state, SHA-256
  `e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`;
- the same 43.2-second balanced FIFO input sequence;
- exactly one game process and no Simulator; and
- the exact Logitech updater still stopped in state `Ts` at 0% CPU.

The private user trees enabled Dolphin's existing buffered
`LogRenderTimeToFile` path. Patch 0002 writes one presented-frame interval per
line without flushing the stream on every frame. Crucially,
`SSBMPAD_FRAME_PHASE_LOG` was absent, so the CPU loop performed no phase-wall,
thread-CPU, static-work, or task-event observations. This is a measurement
change only; no product source or packaged app changed.

Both runs reached identical log boundaries: the screenshot-bounded input
window is rows `683..3413`, and the conservative final 2,001 rows are
`1413..3413`. Unlike a phase CSV, this logger has no emulated-frame identity;
the evidence is therefore presented-frame pacing, not equal-guest-work A/B.

## Repeated result

| Metric | PERF-145 | PERF-146 |
| --- | ---: | ---: |
| Presented rows | 2,001 | 2,001 |
| Mean / implied FPS | 16.666682 ms / 59.999944 | 16.666737 ms / 59.999746 |
| Median | 16.666250 ms | 16.665875 ms |
| p95 | 16.780083 ms | 16.784000 ms |
| p99 | 16.824416 ms | 16.833458 ms |
| Worst | 19.897333 ms | 19.996833 ms |
| Rows at or below 16.7 ms | 1,446 (72.264%) | 1,420 (70.965%) |
| Rows above 17 / 20 ms | 3 / 0 | 3 / 0 |

The residual misses are delayed/catch-up pairs rather than sustained
under-speed:

- PERF-145: 19.897333 + 13.505959 = 33.403292 ms;
- PERF-145: 19.874042 + 13.383417 = 33.257459 ms; and
- PERF-146: 19.996833 + 13.467000 = 33.463833 ms.

Each pair remains close to two nominal 60 Hz periods. That mechanism repeats
at different row indices, which supports host presentation/wake jitter and
rejects a deterministic guest-compute spike at one fixed point.

Fresh endpoints show coherent Pikachu/Fox Fountain combat in both runs:
PERF-145 spans 1:44.93 to 0:59.16 and PERF-146 spans 1:44.51 to 0:58.93.
No fighter-mesh warping recurred. The blurred lower Fountain reflection remains
the documented reference-renderer parity behavior.

Private evidence identities:

- PERF-145 complete render log:
  `4e881ece5b419e89f0861fa78d180565736ea2fb653cb05f5161fb4cc75d284a`
- PERF-145 start/end images:
  `96a155cf0990cbced4095861552015d73057fc62ac1f9662b97b65f2ad6fac4a` /
  `31e4c373c1073dfbb2cd0f53b1f14830af73df92ae40b34130666fa0372898b2`
- PERF-146 complete render log:
  `9f7b5bc52ad91a543cff6ff5bebf6e1e345c368290d9d614ac3a9158bbaa5cd4`
- PERF-146 start/end images:
  `4463dcda06a404c1931324fbfb6d2a7554a6ab5b5eb1e0028dc564f2b8d22f4a` /
  `57a469a4fe2433d8e388966e4b5193f0a418c2e02a236a618323f2cb2d5686ca`

## Fresh implementation-selection bound

The retained guest-cost analyzer mapped PERF-144's direct generated samples
against the matching source tree: 1,390 samples mapped and 260 were line-zero
or otherwise unmapped. The leading regions independently reproduce already
closed work:

- the matrix/FIFO family at `0x8033FAD8..0x8033FB34`;
- the concat/fog family at `0x803408D0..0x80340990`;
- `float2str`, whose complete-function register cache was already rejected by
  PERF-081 at roughly 0.35% projected global benefit; and
- the pad path whose source weights and state-promoted trace were rejected by
  PERF-088.

No new single function or local source operation reaches the 5% implementation
gate. Do not reopen those codegen candidates merely because the fresh sample
orders them differently.

## Decision

The detailed phase observer materially worsens today's near-60-FPS product
distribution: removing it changes Fountain from 17.542 ms p95 / 34.499 ms
worst / 52.424% compliance to repeated 16.780-16.784 ms p95 / 19.897-19.997 ms
worst / 70.965-72.264% compliance. Phase traces remain valid for mechanism
attribution but must not be presented as observer-free product speed.

G5 still fails honestly. The mean is exactly 60 FPS, but the unchanged gate is
worst presented frame at or below 16.7 ms, and both low-overhead runs exceed
it. The residual is repeated delayed/catch-up presentation pacing, not a new
static-recompiler hotspot. Do not retry closed timer, QoS, Game Mode, VSync,
scheduled-presentation, Rush, direct-link, PC-store, MMU, or isolated-function
routes. The next useful diagnostic must observe actual drawable presentation
cadence without changing scheduling; it must not be another pacing candidate
without a new causal signal. G6/iPadOS remains blocked.

No ROM, save, app, module, screenshot, or private timing log is committed.
