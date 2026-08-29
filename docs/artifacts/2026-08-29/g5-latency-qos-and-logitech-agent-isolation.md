# G5 latency-QoS audit and complete Logitech isolation

Date: 2026-08-29

Status: **LATENCY-QOS IS NOT A NEW SCHEDULER ROUTE; ALL-LOGITECH ISOLATION FAILS G5**

## Questions

1. Can `THREAD_LATENCY_QOS_POLICY` reduce the residual off-core producer tail
   through a genuinely new supported macOS scheduling mechanism?
2. After the user stopped both Logitech Options+ components, does the same
   quiet Fountain window meet the strict 16.7 ms gate?

## Apple mechanism audit

The audit used Apple's public XNU source at commit
[`f6217f891ac0bb64f3d375211650a4c1ff8ca1ea`](https://github.com/apple-oss-distributions/xnu/tree/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea).
It closes this candidate before a host preflight or game build:

- `osfmk/mach/thread_policy_private.h` labels both requested and effective
  latency policy fields **Timer latency QoS**.
- `osfmk/kern/timer_call.c::tcoal_qos_adjust` reads the policy to choose timer
  coalescing scale, maximum leeway, and rate limiting.
- `osfmk/kern/thread_policy.c` maps user-interactive thread QoS to
  `LATENCY_QOS_TIER_0` automatically.

The prior user-interactive QoS reversal therefore already exercised tier 0
while also changing CPU scheduling priority. It removed one severe outlier but
regressed p95 from 16.975 to 17.031 ms and was removed. Setting the latency
policy directly would only reopen the separately rejected timer-coalescing
route; it is not evidence for different runnable CPU placement. No preflight,
product edit, or game build was justified.

## Valid complete-Logitech run

PERF-165 used the same retained current-PGO product identities as the quiet
PERF-154 control:

- runner: `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`;
- module: `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- Fountain slot-1 state:
  `e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`;
- signed LaunchServices `.app`, fullscreen/Game Mode eligibility, Metal,
  Cubeb, native internal scale, and stock buffered `render_times.txt` logging;
- the same 45-second balanced left/right/attack FIFO sequence, with
  `gcpipe.py` output redirected away from the live terminal.

The newly isolated variable was PID 629, the user-owned Options+ agent. It was
stopped at 0% CPU in addition to the already stopped root-owned updater PID
276. No unrelated application was paused. Exactly one native runner existed
before and after input, no Simulator was booted, and the runner explicitly
acknowledged `SIGUSR2` slot-1 loading after its signal handler became ready.

The conservative final 2,001 of 3,151 buffered rows measure:

| Metric | PERF-154 updater stopped | PERF-165 updater + agent stopped |
| --- | ---: | ---: |
| Mean / implied FPS | 16.666653 ms / 60.0000 | 16.675053 ms / 59.9698 |
| Median | 16.665583 ms | 16.666709 ms |
| p95 | 16.796250 ms | 16.794959 ms |
| p99 | 16.848875 ms | 16.838917 ms |
| Worst | 22.544875 ms | 33.249209 ms |
| At or below 16.7 ms | 1,396 (69.765%) | 1,405 (70.215%) |
| Above 17 / 20 ms | 3 / 2 | 7 / 4 |

The body is effectively unchanged, while the residual tail varies in the
wrong direction. Stopping the Options+ agent does not repair G5 and does not
support an exclusive causality claim. The valid private timing log hashes to
`d9a435bcfee664e767578bb9b63f5ba51e3eb1f911ba0121746dd1bc3199326b`.
There was no thermal or performance warning and no throttled memory page after
the run.

## Fresh visual proof and excluded setup attempts

PERF-167 was a separate visual-only replay and is not used for timing. The
runner's own **Take Screenshot** menu action captured the emulator framebuffer
directly before and after twelve seconds of quiet input:

- start: 1:48.24, Pikachu 33%, Fox 0%, SHA-256
  `8cd7358385e6405e87c60a10ac2f93627ebe88cc3b8fdbba24287a594b526466`;
- end: 1:33.83, Pikachu 50%, Fox 0%, SHA-256
  `e87d1225ac848b82176d8ac49ebe8a1d06bc162f80c0813a7c7a49bf472c8b64`.

Both frames show literal Fountain of Dreams and coherent Pikachu/Fox models.
The lower-stage reflection remains the documented reference-parity distortion;
no real fighter morphing or mesh warp recurs.

PERF-155 through PERF-164 are excluded setup evidence, not performance runs.
They exposed and corrected broad process matching, early savestate signaling,
the `SIGUSR1` save versus `SIGUSR2` load distinction, stale fullscreen window
IDs, and a screenshot fallback that accidentally launched a second runner.
The second process was killed immediately and PERF-158 was rejected under the
one-game rule. The verified state hash remained unchanged throughout. Blank
or menu-strip ScreenCaptureKit images are also excluded; only Dolphin's two
framebuffer screenshots establish the visual boundary.

## Decision

No product code or configuration changed. Direct latency-QoS is not a new
host scheduling mechanism, and stopping the remaining Logitech agent does not
meet the strict 16.7 ms worst-frame requirement. G5 remains open and G6/iPadOS
remains blocked.

The supported product-local scheduler, timer, Game Mode, workgroup, renderer,
presentation, and code-generation routes already have causal rejection or
retained mitigation evidence. A next background-load reversal must be
explicitly authorized and reversible; process-name spot CPU is not causality.
No ROM, save, app, module, screenshot, or private timing log is committed.
