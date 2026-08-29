# G5 park-and-pivot native regression

Date: 2026-08-29

Status: **26/26 SCOPED NATIVE TESTS PASS; G5 REMAINS OPEN**

## Purpose

PERF-184 parked Activity Monitor isolation as an optional diagnostic. This
follow-up verifies that continued work does not depend on changing unrelated
processes and that the restored native macOS baseline remains internally
coherent before the next falsifiable performance investigation.

## Command

```sh
ctest --test-dir ref/ModernGekko/build-desktop-app-ssbmpad \
  --output-on-failure -R '^moderngekko\.' -j 4
```

## Result

All 26 selected tests passed in 4.84 seconds. Coverage includes frontend and
GameCube configuration, module ABI/loading, native runtime, DOL loading and
boot environment, address space, CPU primitives, interpreter and hardware
core, I/O and audio, GX state/commands/vertex/texture/pipeline/conformance,
Dolphin shader translation, MemoryWatcher utilities, and the netplay protocol.

This is a baseline-integrity result, not a frame-rate measurement or G5 pass.
No game or Simulator was launched and no unrelated process was changed.
