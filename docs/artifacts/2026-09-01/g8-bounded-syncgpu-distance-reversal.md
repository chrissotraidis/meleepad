# PERF-268 — bounded SyncGPU distance reversal

Date: 2026-09-01

Status: **retained partial improvement; sustained combat is 59.94 FPS; cold load still fails**

## Question

The synchronized CPU/video product used Dolphin's 200,000-tick SyncGPU lead
limit, about 0.41 ms of guest time. A recorder-free cold control showed the CPU
thread losing about 2.55 ms off-core during a slow pipeline-dense transition.
Would a still-bounded 1,000,000-tick limit (about 2.06 ms) remove that wait
without restoring the previously rejected unconstrained dual-core crash?

## Change

Set iOS `MAIN_SYNC_GPU_MAX_DISTANCE` to 1,000,000 while retaining
`MAIN_CPU_THREAD=true`, `MAIN_SYNC_GPU=true`, the stable product profile, and
all deterministic and correctness checks. This is bounded producer headroom,
not unconstrained dual-core execution and not a user-facing performance mode.

Candidate executable SHA-256:
`d13c8776176f976c88a7fb4c9a02bb64b661e2db9077443d9521753aa1d1e6fa`.

## Matched cold reversal

The recorder-free 200,000-tick control retained these five-second windows:

| Window | Control | 1,000,000-tick candidate |
|---|---:|---:|
| 105–110 s | 57.20 FPS | 59.94 FPS |
| 135–140 s | 57.56 FPS | 59.97 FPS |
| 145–150 s | 58.71 FPS | 59.88 FPS |
| DMA underruns | 11 | 2 |

The candidate ran 182.8 seconds, beyond the old unconstrained candidate's
139.4-second failure point, with no crash, FIFO error, malformed-command
report, panic, or desync. Its phase and runtime hashes are:

- control phase:
  `4bc531bc89b9039886157c568d9c5f62729861724d9c671c6c5cf1b2add8f7f9`;
- control runtime:
  `8bb089c78d5c26770d9018c13909ec2d12c6476df6d87f58889786ac3decb325`;
- candidate phase:
  `05745abef1b34f3d983f5410eadd81638e00b9ff665b82cccc77df08daf996af`;
- candidate runtime:
  `81c08f3de727dc6336ccd91f37db8914fa7a95db9f738f1124630bdd2e82fe33`.

This clears the five-percent falsifiability gate in the reproduced windows and
materially reduces underruns, so the bounded distance is retained.

## Exact Fountain safety route

The same candidate completed state-verified P1 Samus versus level-1 CPU Kirby,
Stock/04/05:00, on Fountain. Consecutive 2,001-frame combat windows from
emulated frames 4,000 through 10,000 average 16.6832–16.6834 ms, or
59.9398–59.9406 FPS. The complete 186.2-second capture has no crash, FIFO,
malformed-command, panic, fatal, unknown-command, or desync report. The result
screen is coherent.

- phase SHA-256:
  `f0f23095703c4c2a51db69df1cdd690e886577810d48057802b0fbd3ccc2b822`;
- runtime SHA-256:
  `fd5db8284a88d510361260f6ad10e9d39e0661cdc74217ce68d6dc3819f0797b`;
- result-screen SHA-256:
  `eaf053c3809a80bbe44fb33c5d86642439ef353ee22c759f29b1d530c32a9dfb`.

## Remaining failure and mechanism split

The exact cold route still visibly reported 57.5 FPS/VPS followed by 53.5 FPS
/ 53.6 VPS before sustained combat, and underruns rose from zero to five. It
therefore does not pass row 7.

Host-time alignment makes the next work precise:

| Ten-second interval | Rows | Total mean | CPU-thread mean | Pipelines / time | Guest cycles/frame | Native dispatches/frame |
|---|---:|---:|---:|---:|---:|---:|
| first slow interval | 597 | 16.747 ms | 9.199 ms | 93 / 80.735 ms | 4.69 M | 321 k |
| second slow interval | 591 | 16.912 ms | 16.224 ms | 16 / 13.107 ms | 8.11 M | 523 k |

Metal present averages only 0.059 ms and 0.122 ms respectively. The first
interval is a one-time pipeline/load burst with substantial off-core wait; the
second is a dense on-core guest-CPU phase. This is not a general rendering
limit or proof that the M1 cannot run the game: the immediately following
combat holds 59.94 FPS. It is also not one monolithic mechanism.

## Decision and next experiment

Retain the 1,000,000-tick bound as a low-risk partial reversal. Keep G8 row 7,
physical-iPad promotion, and G9 closed because a moving cold phase remains
below target.

Next profile only emulated frames 3,124–3,714 of the exact route, preserving
the route and candidate. Rank native/static guest PCs by on-core samples and
dispatch/cycle contribution. Build nothing unless one safe hot path predicts
at least a five-percent reduction in that interval. Treat the preceding
pipeline-heavy interval separately; do not repeat pipeline-cache seeding,
generic PGO, QoS, resolution, audio-buffer, or unconstrained-dual-core work.
