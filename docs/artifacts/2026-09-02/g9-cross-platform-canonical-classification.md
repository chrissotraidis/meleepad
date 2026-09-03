# G9 B1 cross-platform canonical classification

Date: 2026-09-02

Result: **PARTIAL / FAIL at frame 120.** The current Release iPad Simulator
host and isolated macOS joiner connect at 0–1 ms, agree on compatibility and
GC 1/GC 2 ownership, become ready, and start the synchronized DOL. They then
stop cleanly after two canonical mismatches at frame 120.

## Reproduction correction

The initially installed Release executable was stale and still exposed the
pre-B0 Online Play copy. It was rejected, rebuilt from current source, and
reinstalled. The tested candidate uses executable SHA-256
`5e1347ae88ba132c3f6037e65eeb2bacf1bae752c3b6527538bd7697ee67f112`
before the diagnostic-only status-summary rebuild.

The first current-source run surfaced only `Desync at frame 120 reported for
??` because `SessionUI` retained only the old `netplay-timebase` chat prefix.
ModernGekko patch 0019 now retains `netplay-canonical` history in the native
error. Dolphin patch 0045 prepends a compact component difference list before
the long peer records so accessibility and ordinary UI can classify the
failure without relying on private stderr.

## Classified result

The diagnostic rerun reproduced the same stop and surfaced:

```text
Desync at frame 120 reported for ??:
netplay-canonical sequence=6780 differences=timebase,ram
```

Both endpoints reported caller boundary `80019550/801A4064` and canonical PC
`0x80019550`. The visible first record retained matching integer, FPR,
paired-single/FPSCR, and combined CPU-state hashes; the comparator's summary
therefore isolates the failing components to emulated timebase and sampled
MEM1. This refutes a generic CPU-register or floating-point divergence at the
first failure.

The iPad host recovered to the native error screen and the macOS process exited
without a crash. This is correct fail-closed behavior, not a playable match.

## Decision and next experiment

Keep exact comparison and B1 PARTIAL. Extend the once-per-second diagnostic
with bounded hierarchical MEM1 hashes so the next identical frame-120 run
names the first differing guest-memory region. Include the signed canonical
timebase delta before the verbose records. If the differing region is
presentation/audio/nondeterministic scratch memory, remove only that proven
non-gameplay range from the canonical digest; if it is gameplay state, trace
the first writer. Do not add tolerance, change CPU timing, or proceed to room
codes before this gate passes.

No ROM, module, save, private path, or raw private log is retained here.
