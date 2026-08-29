# G5 current actual-presentation deferral

Date: 2026-08-29

Status: **ACTUAL DISPLAY PACING QUANTIFIED; RARE REFRESH DEFERRAL FAILS G5**

## Question

PERF-145/146 showed repeated delayed/catch-up pairs in Dolphin's low-overhead
app-side frame counter. Does macOS Metal absorb that producer jitter at the
display, or does the current product actually miss refreshes?

## Diagnostic boundary

A disposable current-source runner added the same default-dormant
`CAMetalDrawable.addPresentedHandler` mechanism used by the earlier retained
Metal attribution. It recorded:

- `CACurrentMediaTime()` immediately before and after `nextDrawable`;
- callback registration time; and
- `MTLDrawable.presentedTime` supplied by the display path.

The hook activated only when `SSBMPAD_METAL_PRESENT_LOG` named a private CSV.
It used no phase logger. The signed disposable runner SHA-256 was
`2e558b1f48f261e80a9ef4b64ce64f38c39255cccb1b813ab8d47437c380ad09`;
the unchanged current-PGO module remained
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
The diagnostic source and build product were removed after the runs, and the
canonical runner was rebuilt without its marker.

PERF-147 and PERF-148 used the same verified Fountain state, balanced FIFO
input, native-scale Metal/Cubeb configuration, exactly one game process, no
Simulator, and the Logitech updater still stopped at 0% CPU. The conservative
window in each run uses the final 2,002 valid callback points to form 2,001
actual presentation intervals. No callback inside either selected boundary
reported `presentedTime == 0`; no dropped drawable is silently excluded.

## Repeated actual-display result

| Metric | PERF-147 | PERF-148 |
| --- | ---: | ---: |
| Actual intervals | 2,001 | 2,001 |
| Mean | 16.691666 ms | 16.683388 ms |
| Median | 16.666667 ms | 16.666667 ms |
| p95 | 16.666750 ms | 16.666792 ms |
| p99 | 16.666792 ms | 16.666833 ms |
| Worst | 33.333375 ms | 33.333500 ms |
| At or below 16.7 ms | 1,998 (99.850%) | 1,999 (99.900%) |
| Above 20 / 33 ms | 3 / 3 | 2 / 2 |
| Dropped callbacks | 0 | 0 |

Most of the app-side 16.7-20 ms jitter is therefore absorbed by the
display-synchronized Metal queue. The remaining misses are quantized to
exactly two refresh periods and are visible at the actual display boundary.

## The producer registered on time

For all five missed-refresh endpoints, the previous-to-current registration
gap remained one nominal producer period:

- PERF-147: 16.626167, 16.595709, and 16.792125 ms;
- PERF-148: 16.620375 and 16.663541 ms.

Their `nextDrawable` acquisitions completed in 3.955-5.745 ms. Acquire-begin
gaps were 15.528-17.081 ms. The CPU-GPU thread therefore did not arrive one
whole refresh late, the drawable was available, and the present request was
registered on time. Metal/macOS deferred the drawable by one display refresh
after registration.

This is distinct from the older full-match misses that began before drawable
acquisition. It also explains why optimizing another generated guest function
cannot remove the current strict worst: the five current misses do not contain
a late 33 ms producer interval before registration.

The handler is an observer and cannot be assumed free. Its two repeats also
show two or three 33 ms app-side intervals, while the no-handler PERF-145/146
windows showed none above 20 ms. The result is therefore used to localize the
observed callback runs, not to claim an observer-free miss rate. Historical
actual-presentation full-match evidence independently contains missed
refreshes, so the mechanism is not unique to this new callback build.

## Visual and private evidence

Fresh endpoints show coherent Pikachu/Fox Fountain combat throughout both
runs. PERF-147 spans 1:44.83 to 0:57.14; PERF-148 spans 1:45.39 to 0:57.58.
Poké Ball characters/items in later screenshots are normal gameplay objects,
not fighter-mesh deformation. No real-mesh warping recurred; the lower
Fountain reflection remains documented reference parity.

- PERF-147 presented CSV:
  `37bd997e8ffb7960ba0ea4e02d5b25951edb8a72d3b8c6a171a39fcaeec5b425`
- PERF-147 buffered render log:
  `fd3378a741145729dac6ad476af56082baf3f510aab99458c8390d0c711f662e`
- PERF-147 start/end images:
  `874906fe727d23041ac95dd6916c9f4cfaee4236475f52c4b72af1bb17c81fe9` /
  `dcea24f8ec45139d17eefe0c3d849524dfcf61aaec8ffaeca13115130ff35c47`
- PERF-148 presented CSV:
  `c0fcb335e25268f4c8bdf4b9e945505b0bc737f71ee5440aea198621ffeb788c`
- PERF-148 buffered render log:
  `7dc638de10828d3aad7bd4d7ec8be50234fe8c76fc322c681dd42a7ebca97a6e`
- PERF-148 start/end images:
  `0b21d001ddb914aabfec131a929b04752e9c1aecd82930aa88e7c4254c6b2522` /
  `df6713edbff20b6137ceb9f88a908012f9dabc8a9d4203276968f509dc30b5e0`

## Decision

G5 remains open. Actual-display p95/p99 are excellent and confirm that the M1
is not broadly too slow, but the unchanged requirement is a worst presented
frame at or below 16.7 ms. Repeated 33.333 ms actual intervals fail it.

Do not retry guest codegen, timer, QoS, dual-core, focus, display-sync,
scheduled-presentation, Rush, or drawable-acquisition changes from this
evidence. The next bounded diagnostic must add command-buffer scheduled/GPU
start/GPU end/completed timestamps to distinguish a drawable that was
registered on time but not GPU-ready from one that was GPU-ready and deferred
only by the compositor. It must not alter presentation scheduling. G6/iPadOS
remains blocked.

No ROM, save, app, module, screenshot, CSV, or private runner is committed.
