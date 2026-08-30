# G5 warm native-PC ring attribution (PERF-206)

Date: 2026-08-30

Status: **EXACT WARM CPU OVERRUNS SYMBOLIZED; COST DISTRIBUTED; NO NEW PRODUCT CANDIDATE; G5 OPEN**

## Question

Can a bounded external ARM64 PC ring replace the failed `xctrace` CLI CPU
Counters route and identify native code executing inside exact same-process
warm Fountain CPU overruns, without adding per-frame product instrumentation?

## Mach access and observer preflight

An ordinary ad-hoc parent/child preflight correctly fails `task_for_pid` with
Mach result 5. Re-signing only the disposable target with the documented
development entitlement `com.apple.security.get-task-allow=true` makes
`task_for_pid`, `task_threads`, and `thread_get_state(ARM_THREAD_STATE64)` all
succeed. The canonical product remains unchanged and carries no debug
entitlement.

The retained external sampler now supports an explicit `native-pc` mode. It:

- maps libproc's `thread_handle` to Mach `THREAD_IDENTIFIER_INFO`;
- can select the highest-CPU thread over a 100 ms preflight as `@hottest`;
- records calibrated Unix ns, CPU time, run state, native PC, and PC-read cost;
- resolves PCs to Mach-O image/base after capture rather than during sampling;
- selects any named phase metric, including `cpu_thread_ms`;
- rejects phase rows older than sampler startup; and
- retains the complete bounded native ring even when the live phase stream is
  buffered and no online trigger is visible.

Eleven signed data-free end-to-end cases cover current/legacy/reordered
schemas, malformed/missing fields, default and named metrics, threshold/no-
trigger paths, full-ring retention, native image resolution, and `@hottest`.
Typical 1 ms preflight calls cost about 7-8 us mean and 36-61 us worst.

## Corrections before the accepted capture

Three failed assumptions were retained rather than hidden:

1. Instruments' display label `CPU thread` is not libproc's name. The exact
   second-match process exposes `CPU-GPU thread`; the data-free `@hottest`
   selection prevents label dependence.
2. A first successful PC trigger selected total 16.735500 ms with only
   11.856561 ms CPU. Its 11 exact samples mixed generated/runner work with
   three `semaphore_timedwait_trap` waits. It is a wall-tail validation, not
   the warm compute class.
3. A 150-second `cpu_thread_ms` trigger retained 98,367 error-free samples but
   saw no live row. The shutdown phase file contained eight qualifying rows;
   `ofstream` buffering, not absence of overruns, hid them. The complete-ring
   fallback removes this race without adding per-row product flushes.

A zsh-only wrapper typo (`PIPESTATUS` instead of `pipestatus`) occurred after
the final sampler had written its complete CSV. It prevented only the final
wrapper screenshot/exit-code echo. The cleanup trap stopped the owned runner,
and the 11 MiB sample CSV plus fully flushed phase CSV are intact.

## Accepted same-process capture

The accepted private run used exactly one native runner and no Simulator:

- exact Fountain slot-1 state SHA-256
  `e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`;
- unchanged frontend-PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- disposable debug-signed diagnostic runner SHA-256
  `840966510d66e9a2db5b30621e9b5d15fb6afa51ca929fdd1e1b7e886d280822`;
- native 640x528, fullscreen Metal, Cubeb audio, `CPUThread = False`, EFB
  prewarm, quiet FIFO input, and exact MemoryWatcher gates;
- title readiness, first exact combat plus natural completion, then second
  exact combat before sampling; and
- a preceding same-configuration fresh image SHA-256
  `8ab5dfb5dbd660aa71558098eaee7c11239437537cc3b459686c6b1073bbab74`
  showing coherent Pikachu/Fox Fountain combat. The known translucent/blurred
  lower reflection remains visible; no fighter-mesh morph is present.

The final 120-second ring retained 78,744 samples with zero read errors.
PC reads cost 7,542 ns mean / 88,583 ns worst over the full ring. Private
hashes:

- phase CSV:
  `3a1b9f987c2709a1af6f200d2294d9fd7b84b27d23530c2a1ee6199586156007`;
- native-PC CSV:
  `8f124b174250f7ef7b6c4b5f38cf43a277c76961c3b33bfb3794e774302b8c6a`;
- sampler binary:
  `999cf567895116cf24cafe63d87f5d71b778a29057a2d1f342225d6664209480`.

`scripts/analyze-triggered-native-pcs.py` reconstructs each phase start as
`host_frame_end - video_build - present`, then uses
`previous_frame_start < sample <= frame_start`. It excludes one structurally
incomplete shutdown row and restricts active combat to
`48063 <= emulated_frame < 54924`, excluding the 1.321-second natural match-
completion transition and post-match rows.

## Exact active-combat result

The joined body contains 6,754 frames: 6,750 ordinary rows and four
`cpu_thread_ms > 16.7` overruns. It assigns 73,871 samples to the body and 48
to overruns:

| Emulated frame | Total ms | CPU thread ms | Exact samples | Running / waiting |
|---:|---:|---:|---:|---:|
| 50,166 | 21.534708 | 17.022829 | 13 | 10 / 3 |
| 52,298 | 17.958750 | 17.366368 | 12 | 12 / 0 |
| 54,242 | 17.572459 | 16.750963 | 11 | 8 / 3 |
| 54,436 | 18.311375 | 16.781226 | 12 | 12 / 0 |

The 48 exact samples are 42 running and six waiting. Their PC reads cost
13,260 ns mean / 57,375 ns worst. Symbol rates versus the 6,750-frame body:

| Symbol | Body samples/frame | Overrun samples/frame | Ratio | Overrun samples |
|---|---:|---:|---:|---:|
| `StaticRecompCore::Run()` | 0.417926 | 1.250000 | 2.991x | 5 |
| `SetPPCStateFromGuestState` | 0.034074 | 0.500000 | 14.674x | 2 |
| `func_8033D940` | 0.554667 | 1.000000 | 1.803x | 4 |
| `ppc_psq_load` | 0.066519 | 0.500000 | 4.542x | 2 |
| `func_80381940` | 0.110074 | 0.500000 | 7.517x | 2 |
| `func_80361940` | 0.135556 | 0.500000 | 3.689x | 2 |
| `func_8035D940` | 0.489037 | 0.750000 | 1.534x | 3 |

No leaf owns more than four exact samples. Generated PCs span the 8033, 8035,
8036, and 8038 chunk families; runner PCs span dispatch/state transfer,
GPFIFO, vertex, DSP, and timing work. This independently agrees with
PERF-196's distributed `0x80360000..0x8036FFFF` enrichment rather than naming
one missing dominant helper.

## Decision

**Retain the sampler/analyzer correctness work, but retain no product
optimization.** `StaticRecompCore::Run`, state transfer, SyncIn/SyncOut,
dispatch validation, merged-state, guarded direct-call, register-cache, and
the named generated chunk families already have focused semantic/materiality
screens and live reversals. Two samples cannot reopen those rejected
mechanisms, and the exact native evidence exposes no new dominant leaf.

This is observer-bearing attribution, not acceptance timing. It changes no
canonical app, module, ROM data, save, ABI, scheduler, graphics, audio, or
netplay behavior. No game or Simulator remains. G5 stays open on rare warm
compute and host execution/wake tails; G6 remains blocked.
