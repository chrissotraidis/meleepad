# G5 Fountain frame-address attribution

## Question

Does the required-stage p95 tail come from one native-dispatch hot address,
and is the visibly slow menu the same problem?

## Diagnostic

A default-off `STATICRECOMP_DISPATCH_FRAME_LOG` diagnostic associated the
existing one-in-4096 native-dispatch PC sample with the current present-frame
index. It adds no new work to the unsampled dispatch path. The analyzer compares
samples per ordinary frame (`<= p50`) with samples per tail frame (`>= p95`).

The temporary runner was installed only in a temporary ad-hoc-signed app. The
packaged runner and corrected module were not replaced. No Simulator was used.

## Visually gated route

Computer Use verified P1 Pikachu, a level-1 CPU Donkey Kong, the literal
Fountain of Dreams stage label, live combat, and Cubeb audio. The title read
59.9-61.0 FPS, but screenshots still showed Fountain's known reference-parity
blurred/mirrored lower-floor reflection. That is why the title counter is not
accepted as visual or pacing proof.

The fixed combat cycle covered frames 20,687 through 24,496 (3,810 frames):

- p50: 16.663833 ms
- p95: 17.881404 ms
- ordinary-frame samples: 31.275/frame
- p95-tail samples: 33.230/frame
- estimated aggregate excess: about 8,008 native dispatches/tail frame

The excess was distributed across many addresses. The largest individual
delta was `0x803248dc`, about 525 estimated dispatches/tail frame; no single
site explained the tail. This rejects another isolated-leaf optimization as
the next experiment.

## Menu and transition classification

The full cold route contained four CPU-bound present gaps:

| Frame | Total time | CPU wall | Native dispatches |
|---:|---:|---:|---:|
| 6,141 | 3,001.920 ms | 2,982.510 ms | 70,660,191 |
| 7,355 | 3,072.756 ms | 3,052.505 ms | 66,825,156 |
| 7,888 | 3,171.447 ms | 3,150.971 ms | 98,869,322 |
| 19,442 | 1,871.141 ms | 1,859.448 ms | 55,103,281 |

Samples in these frames were dominated by the revision-0 equivalents of
`OSDisableInterrupts`, `OSRestoreInterrupts`, `DVDCancel`, and Melee `lbDvd`
functions (`0x800187xx`-`0x800195xx`). These are synchronous disc-transition
waits, not Metal presentation: `present_ms` was about 0.02-0.05 ms in the
multi-second rows.

This makes the major menu/scene-transition delay distinct from the frequent
combat p95 tail. A coherent next experiment is Dolphin's existing fast-disc
mode in an isolated control, because it changes the emulated DVD latency that
the hot wait loop is waiting for. It must be rejected if it changes behavior,
breaks deterministic/netplay settings, or does not improve both the visible
transition and the measured gap. Do not retry isolated interrupt leaves.

## Decision

**FRAME-ADDRESS DIAGNOSTIC RETAINED; NO PRODUCT PERFORMANCE CHANGE; G5 OPEN;
FINAL DESTINATION NOT RUN; G6 BLOCKED.**
