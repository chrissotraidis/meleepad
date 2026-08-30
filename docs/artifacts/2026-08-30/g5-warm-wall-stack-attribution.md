# G5 warm wall-stack attribution (PERF-207)

Date: 2026-08-30

Status: **WARM WALL WAIT CALLER PROVED AS `CAMetalLayer.nextDrawable`; PRODUCT UNCHANGED; G5 OPEN**

## Question

PERF-206's offline wall-tail join found repeated
`semaphore_timedwait_trap` residency on the combined CPU/GPU thread even when
the same phase row reported essentially zero CPU throttle and idle time. Is
that residency normal frame pacing, single-core FIFO synchronization, an
emulated-idle wait, or a different blocking caller?

## Source and accounting preflight

The required configuration has `CPUThread = False`. In that path
`FifoManager::RunGpuOnCpu` decodes FIFO work directly and contains no event
wait; `WaitForGpuThread` is reachable only for dual-core synchronized GPU
operation. The retained severe rows also report only 0.0049-0.0078 ms of
instrumented emulated idle and approximately 0.0004-0.0010 ms of CPU throttle
sleep. Those paths cannot explain 5-20 ms of repeated timed-semaphore
residency.

The phase logger's `total_ms` is current-present-start minus
previous-present-start. Metal subphase counters on row N describe row N's
present call. A blocking drawable acquisition during row N therefore appears
inside row N+1's start-to-start interval. This one-row boundary is essential;
reading both values from the same row falsely makes the wait look
uninstrumented.

## Bounded external unwind

The already-retained external sampler gains explicit `native-stack` mode. It
uses the same development-only `get-task-allow` target as PERF-206, reads one
ARM64 thread state, and follows at most four frame records with
`mach_vm_read_overwrite`. The canonical product gains no entitlement or
instrumentation. `native-pc` behavior is unchanged.

The output retains each return PC plus its resolved image/base/offset.
`scripts/analyze-triggered-native-pcs.py --show-stacks` groups exact overrun
stacks and uses `dladdr` to name dyld shared-cache frames that `atos` cannot
resolve from an empty image path. Unresolved zero-base addresses are no longer
mislabeled as shared-cache offsets.

The signed data-free target regression proves `native-stack` retains a live
link register. The focused sampler/analyzer tests and the complete
`scripts/check-repository.sh` gate pass.

## Accepted same-process capture

The private capture reused PERF-206's exact inputs:

- Fountain slot-1 state SHA-256
  `e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`;
- frontend-PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- disposable debug-signed runner SHA-256
  `840966510d66e9a2db5b30621e9b5d15fb6afa51ca929fdd1e1b7e886d280822`;
- native 640x528 fullscreen Metal, Cubeb audio, `CPUThread = False`, quiet
  FIFO input, exactly one runner, and no Simulator.

The first live state load passed at emulated frame 48,066 and reached the
natural-completion boundary at 54,890. The same process then reloaded the
identical state and passed second-combat entry at 48,072 before sampling.

The online trigger saw no flushed row above 20 ms and returned its documented
no-trigger status 3. Its complete-ring fallback nevertheless retained 52,906
samples with zero errors. The fully flushed phase log contained the qualifying
rows offline. Native state plus bounded-stack reads cost 12,451 ns mean,
12,167 ns median, 20,166 ns p95, 31,292 ns p99, and 3,698,667 ns worst. This
observer-bearing run cannot be an acceptance FPS measurement.

Private hashes:

- phase CSV:
  `a2107ae617006c452e2ef2f5a78509035a10ba22334e166895ac7720f1fccc64`;
- native-stack CSV:
  `5b8a6d0daf61093d29e7f2e3e3d801ffa6aad12cec1f240fd6566f093cabf7da`;
- sampler binary:
  `08fd8297edd48704157e1bf330ecc64a9d48cd45cd2d6e4f38ecccbcc5d18e64`.

## Exact warm result

The sample-covered active-combat body contains 6,731 frames. Six
start-to-start intervals exceed 20 ms, while only one combined-thread CPU row
exceeds 16.7 ms. The diagnostic distribution is 16.684929 ms mean
(59.934328 FPS implied), 17.544959 ms p95, 18.158375 ms p99, and 34.670709 ms
worst. These values describe an instrumented attribution run, not G5 timing.

Thirty-one of the 32 timed-semaphore samples inside the six wall tails have
the identical complete return chain:

```text
semaphore_timedwait_trap + 0x8
<- _dispatch_sema4_timedwait + 0x40
<- _dispatch_semaphore_wait_slow + 0x4c
<- CAMetalLayerPrivateNextDrawableLocked + 0x4a8
<- -[CAMetalLayer nextDrawable] + 0x7c
```

The remaining sample preserves the same kernel/libdispatch prefix but has a
truncated frame chain. The wait is drawable acquisition, not PrecisionTimer,
FIFO synchronization, emulated idle, or an unnamed scheduler location.

Applying the proven one-row boundary gives:

| Tail frame | Total ms | CPU-thread ms | Prior `nextDrawable` ms |
|---:|---:|---:|---:|
| 48,293 | 21.883000 | 14.938578 | 6.535541 |
| 53,724 | 31.514541 | 14.170606 | 16.867125 |
| 53,735 | 34.670709 | 13.784254 | 20.414458 |
| 54,308 | 20.690209 | 15.593364 | 3.775250 |
| 54,697 | 20.822416 | 15.950866 | 4.492167 |
| 54,766 | 34.235000 | 11.959743 | 21.805333 |

The three largest tails are dominated by drawable backpressure. The other
three combine a shorter ordinary acquisition wait with elevated but still
sub-budget guest compute. The separate single CPU overrun is distributed
static-recompiler work and does not name a new leaf candidate.

## Decision

Retain the optional stack sampler and analyzer support, but retain no product
change. This call stack strengthens the existing `nextDrawable` attribution;
it does not reopen two drawables, Rush presentation, direct presentation,
display-sync toggles, absolute scheduling, or a separate reserve queue. Those
mechanisms have direct live or host-harness reversals, and phase logging itself
can perturb drawable behavior.

The canonical runner, module, ROM data, save, graphics, audio, timing, and
netplay behavior are unchanged. All owned processes are stopped and no
Simulator remains. G5 stays open; G6 remains blocked.
