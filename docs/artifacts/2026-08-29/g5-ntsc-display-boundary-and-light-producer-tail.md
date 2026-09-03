# G5 NTSC display boundary and lightweight producer tail

Date: 2026-08-29

Status: **FIXED-RATE HOLDS SEPARATED; CURRENT PRODUCER TAIL IS OFF-CORE; G5 OPEN**

## Questions

1. Does a 33.333 ms `presentedTime` interval necessarily mean the emulated
   game missed its 16.7 ms work budget?
2. In the remaining no-phase producer tail, is the combined CPU-GPU thread
   actually computing past 16.7 ms, or is it losing wall time off-core?

## Exact source and display cadence

Dolphin derives the NTSC VI rate from the emulated registers rather than a
rounded `60` constant. The current source and ordinary GALE01 register values
give:

- GameCube core clock: 486,000,000 ticks/s;
- VI sample clock: 27,000,000 samples/s;
- 36 core ticks/sample and `HLW = 429`, or 15,444 ticks/half-line;
- 1,050 half-lines per two-field frame; and
- `(486,000,000 * 2) / (15,444 * 1,050) = 60,000 / 1,001`.

The exact distinct-frame cadence is therefore 59.940059940 Hz, or
16.683333333 ms. That interval is inside PRD D2's 16.7 ms budget.

Core Graphics currently exposes ten modes for the built-in M1 panel; every
mode reports exactly 60.000000000 Hz. PERF-126 also recorded zero minimum and
maximum variable-refresh capability. The source/display difference is
0.059940060 Hz, so a fixed 60 Hz panel must periodically hold the preceding
surface if guest timing is preserved and no stale duplicate is submitted as a
new game frame.

The observer-free external PERF-127 trace independently bounds how close the
product already is to that rate-conversion expectation. In its stable 20-100 second
window, 4,794 MeleePad surfaces were queued and 4,788 were eventually displayed;
six were not selected. Pure `60000/1001` to 60 Hz conversion predicts 4.795
accumulated frame differences in 80 seconds, or a five-hold integer conversion
expectation. The product is one hold above that expectation in the selected
window. Presentation API, display-sync, VSync,
Rush, time-constraint, QoS, drawable, and timer alternatives were already
rejected by causal controls; there is no evidence for reopening them.

Actual presentation remains required to catch real display stalls, but a
unique-surface callback interval cannot by itself replace D2's guest-frame
work test on a mismatched fixed-rate panel. A 33 ms callback is excluded from
the compute verdict only when retained queue/GPU evidence proves that the
frame was ready and the event is a conversion hold. This does not pass G5:
PERF-145/146 still contain observer-light 19.897-19.997 ms producer intervals.

## Lightweight wall/thread-CPU diagnostic

A disposable default-dormant recorder sampled exactly two values at each
`Presenter::Present` entry:

- the existing monotonic `Clock::now()` value; and
- `CLOCK_THREAD_CPUTIME_ID` for the same combined CPU-GPU thread.

Records stayed in a reserved vector and were written once during shutdown.
There were no phase counters, per-slice CPU-clock calls, task queries,
drawable callbacks, or frame-time writes. Five one-million-call Python wrapper
screens bounded the thread-clock call plus interpreter overhead at
180.469-184.348 ns/call. The actual C call is no slower than that conservative
bound for this purpose.

The first direct-executable run is excluded: it was not the packaged product
path and produced a mismatched runtime workload. The corrected run used the
signed `.app`, current-PGO module, verified Fountain state, Metal, Cubeb,
native scale, one process, no Simulator, and Logitech still stopped.

Disk availability fell to 116 MiB and Dolphin emitted filesystem rename
failures after runtime shutdown. The CSV write ended with a malformed partial
row, so only the 1,091 complete combat intervals from the start image through
the last complete in-memory record are retained. This is diagnostic-only and
is not an observer-free product distribution.

| Metric | Wall interval | Thread CPU | Wall minus thread CPU |
| --- | ---: | ---: | ---: |
| Mean | 16.665628 ms | 11.757568 ms | 4.908060 ms |
| p95 | 17.786063 ms | 12.758312 ms | 5.634978 ms |
| p99 | 18.666129 ms | 13.852158 ms | 6.071153 ms |
| Worst | 24.617583 ms | 14.735375 ms | 12.656916 ms |

No selected thread-CPU interval exceeded 16.7 ms. The three wall intervals
above 20 ms split as:

- 24.617583 wall / 11.960667 CPU / 12.656916 off-core ms;
- 21.821792 wall / 11.689875 CPU / 10.131917 off-core ms; and
- 20.223209 wall / 14.537334 CPU / 5.685875 off-core ms.

The current captured producer tail is therefore not a static-recompiled
compute overrun. Disk pressure may aggravate the off-core distribution, so its
p95/worst are not promoted as product acceptance numbers. The mechanism agrees
with the earlier independent phase/task-event evidence: the combined thread
has compute headroom but sometimes loses its presentation/wake interval while
not executing.

Fresh images show coherent Pikachu/Fox Fountain combat with no fighter-mesh
recurrence. The lower reflection remains the documented reference behavior.

- lightweight partial CSV:
  `0db90c49552c0cd54345a68c81cb19fd3c0d93283bc95579d6169e469f3a8010`
- start/end images:
  `39d177cb2a48515378647ac5e2f966519dde9e0204a6dabec1b87b59cc895679` /
  `c5e039c3c9f979a5f225ad6cb1e63c8fcfd5f3525f88c5dda3a2bcd15559c758`

## Reversal and decision

The lightweight recorder was removed, the private render-log setting was
restored, and the canonical runner rebuilt with its marker absent. No product
change remains.

G5 stays open. Do not try to eliminate the mathematically required conversion
floor by changing VI speed, audio pitch, deterministic/netplay timing, or by
counting stale duplicates as new frames. Do not reopen rejected scheduler or
presentation APIs. The next G5 work is limited to genuine producer intervals
above 16.7 ms on a clean host: first recover disk headroom, then select a new
causal host descheduling mechanism rather than another unchanged timing retry.
G6 remains blocked.
