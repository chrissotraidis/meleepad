# G5 Fountain stopped-updater baseline and symbolized sample

Date: 2026-08-29

Status: **G5 FAILS; `func_80339940` LOCAL REWRITE REJECTED**

## Questions

1. With the Logitech updater stopped, does the current-PGO native arm64 build
   satisfy the strict 16.7 ms Fountain gate?
2. If not, does a fresh native sample expose a coherent, material local
   optimization inside generated `func_80339940`?

The user directed that the exact root-owned Logitech Options+ updater remain
stopped. PID 276 was therefore left in state `Ts` at 0% CPU throughout these
runs. No Logitech configuration, launchd plist, application, or file was
changed, and no further authorization prompt was triggered.

## PERF-142: required-stage timing

The retained private slot-1 state is SHA-256
`e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
It loads Pikachu versus level-1 Fox on literal Fountain of Dreams. The signed
disposable app used the retained current-PGO runner and module:

- runner: `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`
- module: `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`

Two setup attempts are excluded and preserved privately. The first lacked the
required `Pipes` parent; the second had the directory but no named FIFO. Source
inspection confirmed that the FIFO backend opens an existing entry. The
accepted run pre-created private FIFO `Pipes/ssbmpad`, used the balanced
43.2-second controller sequence, and installed unconditional process cleanup.

Fresh endpoints visually bind coherent Fountain combat from 1:44.88 to 0:59.04.
Pikachu and Fox remain recognizable at both ends, with no fighter deformation.
The blurred lower-stage reflection is the already documented reference-renderer
parity behavior, not a recurrence of real-mesh warping.

The exact final 2,001 rows are continuous emulated frames `49598..51598`:

| Metric | Result |
| --- | ---: |
| Total mean / p95 / p99 / worst | 16.677958 / 17.542125 / 18.216125 / 34.499292 ms |
| CPU-wall mean / p95 / p99 / worst | 16.282130 / 17.144133 / 17.839053 / 34.027748 ms |
| CPU-thread mean / p95 / p99 / worst | 12.221511 / 13.160889 / 13.934672 / 16.996984 ms |
| Wall minus CPU-thread mean / p95 / p99 / worst | 4.060619 / 4.761159 / 5.835495 / 20.482501 ms |
| Audio mean / p95 / p99 / worst | 0.841585 / 1.249001 / 1.269750 / 1.840250 ms |
| Video-build mean / p95 / p99 / worst | 3.857948 / 4.820625 / 5.890666 / 20.595458 ms |
| Frames at or below 16.7 ms | 1,049/2,001 (52.424%) |
| Frames above 20 / 24 / 33 ms | 3 / 1 / 1 |
| FPS implied by mean | 59.959 |

Worst frame 49673 spends 13.545 ms on the CPU thread and 20.483 ms off-core;
other slow rows also reach 14.7-17.0 ms of CPU-thread work. Fountain therefore
retains both a compute-heavy normal tail and an intermittent off-core stall.
Stopping Logitech removes it as the fundamental explanation but does not pass
G5.

Private evidence identities:

- phase CSV: `aa987edb26e07e8684f9c80b0c95139a88ab76559969c93ac67dc6f512e7e942`
- start image: `40ba939889b8abb4cd014d14c8b6a62dbf741f41feffcd1ae2ae14dcc34cd437`
- end image: `258292a250f9690b6970c6d911c6d47c85e021d42e7ca1f51c6ec2bc2fc7fd4b`

## PERF-143/144: fresh native source attribution

PERF-143 sampled the current-PGO app for 12 seconds during visually verified
Fountain combat. Its CPU-GPU thread spent 4,176 of 6,735 samples in generated
`chassis_dispatch`. Top-of-stack generated costs were led by
`func_8035D940` (424), `func_8033D940` (408), `func_80375940` (378), and
`func_80339940` (255). The first three routes already have focused rejection
evidence; `func_80339940` was the first material unclosed function family.

PERF-144 replaced only the disposable app's module with the retained line-table
equivalent. The product module and line module have identical function
addresses, identical `__TEXT`/`__text` sizes, and byte-identical `__text`
SHA-256 `7d030de39abe4331a87c847f27639c481dad6d3d5c01def912258f63a79d2109`.
Debug metadata and ad-hoc signatures differ; no symbolized module is promoted.
The corrected run again captured coherent Fountain combat, from 1:44.98 to
1:05.76, and exited cleanly.

In the symbolized sample, `StaticRecompCore::Run` is active in 2,031 samples
and `func_80339940` is top-of-stack in 106, an impossible-best-case bound of
5.219% if all of that function's direct cost vanished. The cost is not a
coherent local operation: the sample resolves across many guest blocks and
source lines. The largest mixed/unknown-line bucket is 14 samples at multiple
different offsets; the hottest individual resolved line has only three
samples, or 0.148% of active recompiler samples.

This rejects a focused line-local rewrite inside `func_80339940` before a
product build. It does not claim that every whole-function or generator-wide
redesign is impossible. Any such proposal still needs a concrete shared
operation with at least 5% projected coverage and preserved PowerPC semantics.

Private sample identities:

- PERF-143 sample: `fc241c7b78016dc871cb3816b0ef0782fee388434e887dbaa4b4b8150e7ce394`
- PERF-144 sample: `ae7717544be6f462f530806ebb6fa2f5df866f5b7263152b2402adc5f6de4178`
- PERF-144 phase CSV: `eac116d7f10b91645e589ced7891d83d99d854acbb8d51834393898f0726feb2`
- PERF-144 start/end images: `a45c399add63379d645b3e8103d73168e6db46cd999299903b6eebea3f4165a3` /
  `60489c7b60210319059645146c25d4ed80d4e8389df34518d1da04eff98f2e8e`

## Decision

G5 remains open. The native M1 build averages essentially 60 FPS on Fountain,
but strict frame pacing still fails: only 52.424% of the measured rows meet
16.7 ms and the worst is 34.499 ms. Logitech is stopped and is not the root
cause. Reject a local `func_80339940` rewrite; choose the next experiment only
from a shared generated/runtime operation whose fresh coverage can plausibly
recover at least 5% of active producer time. G6/iPadOS remains blocked.

No ROM, save, app, module, screenshot, sample, or private timing log is
committed.
