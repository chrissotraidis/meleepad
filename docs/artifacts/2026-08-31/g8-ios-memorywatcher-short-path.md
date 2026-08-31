# PERF-247 — Simulator MemoryWatcher short-path repair

Date: 2026-08-31  
Goal: G8 row 7 diagnostic repeatability  
Decision: **retain as an explicit diagnostic harness; no FPS claim**

## Problem

The normal touch route in PERF-246 confirmed another visible failure, but the
private pipe route remained timing-blind and could drift into unrelated menus.
MemoryWatcher produced no packets even though its locations file and client
socket existed before launch.

## Root cause

The iOS core was not missing MemoryWatcher. Its generated compile commands
contain both `USE_MEMORYWATCHER=1` and `USE_PIPES=1`, including the command for
`Core.cpp`.

The actual Simulator user-directory socket path was 232 bytes. Darwin's
`sockaddr_un.sun_path` holds 104 bytes including the terminator. Dolphin's
`MemoryWatcher::OpenSocket` copied at most 103 bytes without rejecting the
path, truncating the destination to the Simulator device's `data` directory.
`sendto` therefore targeted a directory rather than the client socket. A
client-side symlink alone could not work because the core still constructed
the original long destination.

## Smallest retained change

`SsbmPadCoreHost` now recognizes `SSBMPAD_RUNTIME_USER_DIRECTORY` only in a
Simulator build. The override is accepted only when:

1. resolving symlinks yields the exact normal app user directory; and
2. the resulting MemoryWatcher socket path fits `sockaddr_un.sun_path`.

Otherwise the override is rejected and the normal user directory is retained.
The normal product path does not set this variable. The log records only the
decision and booleans, never the private path.

This allows a diagnostic script to create a short temporary symlink to the
real directory and point both the core and `gcpipe.py` at it. All configuration,
pipe, save, and game-data access still resolves to the same app directory.

## Verification

- Focused source regression: pass.
- Release arm64 iOS Simulator build: pass.
- Built app executable: 15,096,064 bytes, SHA-256
  `66e248a09749849dcae23419c2091c5ceff0a17bf6706262afddfda34100c298`.
- Live launch logged `runtime user-directory override enabled
  source=simulator-diagnostic`.
- A pre-bound `gcpipe.py --trace-memory` client received
  `80477D68=00000000` and satisfied its first memory predicate in 0.57 seconds.
- Private runtime log: 5,086 bytes, SHA-256
  `0338f50169c9092085ed5442543e3ea80398b35d73ba2680c0946a90fbf14adc`.
- The app was stopped, both diagnostic environment variables were removed,
  and the temporary symlink/directory were deleted after proof.

## Boundary and next step

This repairs state-gated automation; it does not improve emulation, rendering,
audio, or FPS and cannot pass row 7. The next run must use the watcher to
calibrate an exact normal launch through the same roster/stage as the user's
21.9 FPS Fountain workload. Only after visible route identity is proven should
the prepared address-translation and discarded-sampling counters be recorded.
