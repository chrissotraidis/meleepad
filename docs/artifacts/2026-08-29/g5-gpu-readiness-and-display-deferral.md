# G5 GPU readiness and display deferral

Date: 2026-08-29

Status: **GPU LATENESS REJECTED; READY FRAMES STILL MISS REFRESHES; G5 OPEN**

## Question

PERF-147/148 showed rare 33.333 ms actual presentation intervals even when
the drawable was acquired and its present request was registered on time. Was
the associated Metal command buffer still rendering at the skipped refresh,
or had macOS deferred an already GPU-ready frame?

## Bounded diagnostic

A disposable default-dormant runner recorded, in memory, one record per
drawable containing acquisition, registration, command-buffer scheduled,
Metal GPU start/end, command-buffer completion, and `presentedTime` values.
The vector was written to a private CSV only during shutdown, so there was no
per-frame file I/O. Presentation scheduling was unchanged. The signed private
runner SHA-256 was
`52329fb8536a1bd0d34ac3e040a7ca34e925f78391b50bf85d7aa94976d63802`;
the current-PGO module remained
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

Both runs used the same verified private Fountain state, Metal, Cubeb,
native internal scale, one native process, no booted Simulator, and the
Logitech updater still kernel-stopped at 0% CPU.

## PERF-149 short screen

The final 2,001 actual intervals all met 16.7 ms:

| Metric | Result |
| --- | ---: |
| Mean | 16.666589 ms |
| p95 | 16.666667 ms |
| p99 | 16.666708 ms |
| Worst | 16.666749 ms |
| At or below 16.7 ms | 2,001 / 2,001 |

This is a real short-window pass, not G5 completion. Repeated earlier windows
and the required sustained match boundary still contained misses.

## PERF-150 sustained combat result

PERF-150 extended the same diagnostic across the remainder of a timed match.
The retained combat window starts with the fresh 1:34.24 Fountain image and
ends at the last ordinary presentation before the natural match-end
transition. It contains 5,745 presentation points and 5,744 actual intervals
over 95.884 seconds. Every selected command buffer completed successfully and
no selected callback had `presentedTime == 0`.

| Metric | Result |
| --- | ---: |
| Mean | 16.692862 ms |
| Median | 16.666750 ms |
| p95 | 16.666833 ms |
| p99 | 16.666834 ms |
| Worst | 33.333542 ms |
| At or below 16.7 ms | 5,735 / 5,744 (99.843%) |
| Above 20 ms | 9 |

The first later transition gap was 350 ms and is excluded together with the
results screen. Five zero-`presentedTime` callbacks also occur only after the
combat boundary; none is silently removed from the selected combat result.

## All nine missed deadlines were GPU-ready

For each 33.333 ms interval, the skipped refresh deadline is defined as the
previous drawable's `presentedTime + 1/60`. At all nine endpoints:

- the present record was registered **12.397-32.797 ms before** that deadline;
- its command buffer scheduled **12.113-32.586 ms before** the deadline;
- GPU work ended **10.408-30.918 ms before** the deadline; and
- the command buffer completion callback ran **10.307-30.660 ms before** the
  deadline.

Across the whole combat window, Metal GPU duration was 1.565649 ms mean,
1.689158 ms p95, 1.780660 ms p99, and 2.522875 ms worst. Even the endpoint
with a 37.038 ms registration gap remained buffered far enough ahead that its
GPU work completed 10.408 ms before the skipped refresh.

The observed current miss class is therefore not Fountain GPU saturation,
late command-buffer execution, or a slow M1 GPU. macOS's display/compositor
path deferred frames that were already ready. This agrees with PERF-126/128's
independent fixed-rate conversion result: the 60.0 Hz fixed panel cannot show
every distinct approximately 59.94 Hz guest frame at one-refresh intervals.

The callback observer can still perturb queue selection, so this run does not
claim an observer-free miss rate. It does establish the ordering on every
observed miss. The earlier external Display trace independently retained the
same ready-surface conversion holds without this callback.

## Visual and identity evidence

The PERF-149 endpoints show coherent Pikachu/Fox combat. PERF-150 begins with
coherent Pikachu/Fox Fountain combat and ends on the natural results screen.
No real fighter-mesh deformation recurred; Fountain's lower reflection remains
the documented reference-parity artifact.

- PERF-149 private CSV:
  `881dcda0fe8d7bcdffd342b8f4bf633f53a0f5ca77b8b24d8180f3485d0a51e3`
- PERF-149 images:
  `a14778cf864661a1a25010b75dbee11436bd97627202251f7684cd3dd97a3cd7` /
  `1a0de616b8926114333c60eff6cd24922d27bbab523b8bc2a6be57e83be16ff6`
- PERF-150 private CSV:
  `2bf431730ae8b219e56f16e9b3b0a3e4c1a9076fcb85c9e116bc5c6e4ad9e38d`
- PERF-150 buffered render log:
  `daea20101512978e72df6742b3d05f76b85616cbdd40881db84782303c295b2c`
- PERF-150 images:
  `d7f6e052d19f80d06d4b48cfb14f88d158de17abeb19c0130729997ab47a0548` /
  `2ec4eff442552abafd5c5d8398e0d1c86f63b4b78ae12482119f7fc7ac1eddf9`

## Reversal and decision

The entire private recorder was removed. The canonical runner rebuilt
successfully and contains neither `SSBMPAD_METAL_GPU_PRESENT_LOG` nor the
recorder marker. No presentation, renderer, ROM, save, module, app, CSV, or
screenshot is committed.

G5 remains open because its strict worst interval is still 16.7 ms. Do not
return to GPU optimization, drawable acquisition, direct/scheduled present,
display-sync, VSync, timer, QoS, or guest-code changes from this evidence.
Before another product experiment, audit the remaining acceptance boundary
against the already-proven fixed-panel conversion mechanism: a candidate must
produce a new distinct game frame each refresh without changing deterministic
guest/audio/netplay timing or merely duplicating a stale frame. G6 remains
blocked.
