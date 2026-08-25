# G5 locked-cache pointer fast-path rejection

Date: 2026-08-25

Status: **CANDIDATE REJECTED; G5 AND VISUAL-001B REMAIN OPEN**

## Question

The retained combat sample repeatedly placed generated paired-single stores in
`ppc_psq_store -> StaticRecompCore::HookExternalWrite -> MMU`. Dolphin already
provided `CPUState.external_pointer` and a host implementation that returned a
raw pointer only for the GameCube locked-cache range, but GXRuntime never called
it. The experiment asked whether using that existing narrow pointer path would
remove enough MMU work to improve the strict required-stage distribution.

## Failing regression and implementation

A focused GXRuntime regression configured both the external read/write hooks
and a locked-cache-style pointer callback. Before the implementation it failed
because two PSQ lanes still used two external writes and the pointer callback
had zero hits. After `get_ram_ptr()` consulted the callback, the regression
passed with two pointer hits, zero external writes, and correct big-endian lane
values. The existing null-callback path still exercised the exact external
hooks. The complete `gxruntime_tests` target passed.

Dolphin's callback was additionally guarded while lockstep journaling was
active. That preserved the MMU path and locked-cache preimage journal for
native/shadow verification. The complete arm64 native runner compiled and
linked successfully.

The test and implementation were temporary. They were removed after the
performance rejection; no dependency patch was added.

## Candidate identity and runtime signal

- PGO profile SHA-256:
  `f63d73a5da25f4b2282260a4158525a0e93f112459c9d2e6de971e4dd9110539`
- unsigned arm64 macOS 14 candidate module SHA-256:
  `c7b13512652b4922415d6c2668a1a999410ccdb37f3e398bf95877704ccd8c65`
- candidate runner before staging/signing SHA-256:
  `8c4d83d941dcb09708171f6af7a67b00082723cd0165ea58e9b9b145e461de5e`
- 12-second native sample SHA-256:
  `986d49d182522e0855250a04e21a08fa42bbd9996257426ff0af11059d75e103`

The sample proved the candidate was live: `HookExternalPointer` appeared in 46
CPU samples. During the scripted interval the CPU thread spent 6,844 of 9,774
samples in `PrecisionTimer::SleepUntil` and 2,214 in `StaticRecompCore::Run`.
That is a real compute-headroom change from the retained pre-candidate combat
sample, where 666 of 685 CPU samples were in `StaticRecompCore::Run`.

## Clean screening interval

The watcher-first cold route again reached the revision-0 CSS predicate
`0x02020100`. A known controller route then exercised the same 20-cycle combat
script with Metal and Cubeb. No sampling, screenshot, focus change, or UI
inspection occurred inside the bracketed interval.

The raw SDL child was not visible to the accessibility capture service, so
stage identity could not be visually retained. This is therefore a screening
diagnostic, not G5 acceptance evidence and not visual evidence. The exact
brackets were render records 19,116-24,918 and vblank records 19,802-25,604:

| Metric | Render | Vblank |
|---|---:|---:|
| Samples | 5,803 | 5,803 |
| Mean | 16.683997 ms | 16.683325 ms |
| Median | 16.742917 ms | 16.712125 ms |
| p95 | 18.898750 ms | 18.526875 ms |
| p99 | 20.513333 ms | 18.888167 ms |
| Worst | 35.249542 ms | 28.812166 ms |
| Frames <=16.7 ms | 46.631% | 48.682% |

For comparison, the retained visually verified Fountain interval measured
17.115/17.318/59.024 ms render p95/p99/worst with 54.714% of frames at or below
16.7 ms. The pointer candidate reduced the rare worst frame in this diagnostic,
but materially worsened p95, p99, and the pass share. It fails the loop's
strict retention rule before a costly Final Destination replay.

The stopped full diagnostic logs had SHA-256
`700c6407713e5bd1d7687b510a88e0810bd2bd0283b9a7e7c10ad14e54df553c`
(render) and
`bea38b56f795b7dac83021944cb6a11342026b8c8055f33eeab0f65a0bc45b3a`
(vblank). They remain local with the private runtime user directory and are not
committed.

## Cleanup and next experiment

The temporary runtime/test/hook changes were removed. The ignored app bundle
was restored to runner SHA-256
`39c63c0a735be6558dddcdddb511bcc20f7cabe5b380aacf083db5da1541c551`
and retained module SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.
No runner, controller driver, frontend, or Simulator remains active.

The sample changes the next falsifiable question: after locked-cache compute is
removed, the CPU becomes predominantly pacing-sleep bound. The earlier precise
spin timer was tested while the game was compute-bound and was correctly
rejected. That exact pacing change was therefore re-evaluated on top of the
measured compute-headroom state in the follow-up below.

`VISUAL-001B` is unaffected. No image was captured in this run, and the user's
intermittent fighter-body warping remains promotion-blocking.

## Follow-up: Apple-silicon final-spin composition

Status: **COMPOSITION REJECTED**

The follow-up changed only the final precision-timer spin in the fixed
locked-cache candidate state. On Apple silicon, `std::this_thread::yield()` was
temporarily replaced by the ARM `yield` hint; target time, the preceding
`sleep_until(target - 1.02 ms)`, game module, graphics, audio, controller route,
and combat script were unchanged. The lockstep pointer guard remained active.

- unsigned composed runner SHA-256:
  `e1952ef33928496edcf9af9c51e278cb35d936d0b7fcc33b7c108c87f40a74b8`
- exact render bracket: records 11,606-16,385
- exact vblank bracket: records 12,292-17,071

| Metric | Render | Vblank |
|---|---:|---:|
| Samples | 4,780 | 4,780 |
| Mean | 16.682757 ms | 16.683331 ms |
| Median | 16.678000 ms | 16.697333 ms |
| p95 | 19.658000 ms | 18.439958 ms |
| p99 | 21.008584 ms | 18.876250 ms |
| Worst | 70.455125 ms | 63.977000 ms |
| Frames <=16.7 ms | 51.318% | 50.439% |

The ARM hint recovered the render median and slightly improved the <=16.7 ms
share relative to the standalone pointer diagnostic, but it worsened render
p95, p99, and worst. Avoiding the scheduler yield therefore adds contention or
tail risk in this state rather than solving frame delivery. The composition is
rejected before Final Destination and neither temporary change is retained.

The stopped full composed-run logs had SHA-256
`4ae7ab2086d4d94de7a122ac13d096de9c437707199aa7ef94c6862343fa6625`
(render) and
`7ed3edc080951306016f4cf27071ea09fc09268a0971799cb07784a4032441b7`
(vblank). The timer and hook edits were removed, the retained app runner/module
hashes were restored again, and no runner or Simulator remains active.
