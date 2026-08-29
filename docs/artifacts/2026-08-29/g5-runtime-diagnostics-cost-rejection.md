# G5 runtime-diagnostics cost rejection

Date: 2026-08-29

Status: **ALWAYS-ON DIAGNOSTICS BELOW MATERIALITY GATE; KEEP API; G5 OPEN**

## Question

ModernGekko registers an `after_frame_event` hook for
`Runtime::GetDiagnosticsSnapshot` on every boot. No current launcher caller was
found. Could lazy-gating this otherwise useful diagnostics path materially
reduce G5 frame time?

## Exact work

The hook performs:

- an FNV-1a hash across `Statistics::proj` and `Statistics::gproj`, totaling
  22 floats or 88 bytes;
- one relaxed atomic frame-count increment;
- one relaxed 64-bit hash store; and
- eleven relaxed 32-bit statistic stores, including scissor-vector size.

It does no allocation, file I/O, lock, syscall, GPU operation, or wait. The
snapshot remains part of ModernGekko's public runtime API and will be useful to
the later diagnostics acceptance gate, so removing it requires a material
cost—not merely the absence of a current launcher caller.

## Host-only bound

A disposable C++ preflight reproduced the exact 88-byte hash and relaxed-atomic
store shape. AppleClang built it at `-O3 -mcpu=apple-m1 -Wall -Wextra -Werror`.
Five independent ten-million-call loops measured:

| Repeat | ns/call | us/call | Share of 16.7 ms |
| ---: | ---: | ---: | ---: |
| 1 | 62.788 | 0.062788 | 0.000376% |
| 2 | 59.960 | 0.059960 | 0.000359% |
| 3 | 59.689 | 0.059689 | 0.000357% |
| 4 | 59.410 | 0.059410 | 0.000356% |
| 5 | 59.487 | 0.059487 | 0.000356% |

The slowest optimized measurement is 0.000062788 ms per frame. Even deleting
all of it is about 1,593 times smaller than a deliberately permissive 0.1 ms
screen and far below the established 5% candidate gate.

An ASan/UBSan build then ran 100,000 calls with leak detection disabled (not
supported on this platform), emitted no diagnostic, and measured 92.040
ns/call. The corrected disposable source SHA-256 was
`92713eedbc21bb1405bffcbcd633d9fd3626c3050e762b8c3edf8ce8d899a9d0`.

## Decision and reversal

**Reject diagnostics lazy-gating as a G5 optimization.** Preserve the public
snapshot behavior and future diagnostics value. Its entire synthetic upper
shape is many orders of magnitude smaller than current wall-time misses and
cannot fix off-core host execution loss.

The disposable preflight source was removed. No ModernGekko, Dolphin, runner,
module, app, ROM, save, configuration, or Simulator state changed. No game or
Simulator is running. G5 remains open and G6 remains blocked.
