# G5 current Metal drawable API screen (PERF-208)

Date: 2026-08-30

Status: **NO DISTINCT DRAWABLE-LATENCY LEVER; NO PRODUCT BUILD; G5 OPEN**

## Question

PERF-207 proves that the repeated warm timed-semaphore stack is
`CAMetalLayer.nextDrawable`. Does the installed macOS 26.5 SDK or the host's
actual layer defaults expose a drawable/command-queue mechanism that is
distinct from the already-rejected queue-depth, display-sync, timed-present,
display-link, and reserve-frame routes?

## Installed SDK result

The authoritative installed headers define a `CAMetalLayer` swap queue with a
hard `maximumDrawableCount` range of two or three and a default of three.
`nextDrawable` always blocks until one is available. The only timeout property
changes whether that block may return `nil` after one second; disabling the
timeout permits an infinite wait and cannot shorten a 5-22 ms acquisition.

The remaining layer properties do not expose new latency capacity:

- `presentsWithTransaction` moves content into ordinary Core Animation
  transactions rather than the default asynchronous Metal path;
- `displaySyncEnabled` is already directly rejected;
- `framebufferOnly` controls drawable texture usage/allocation, not queue
  count; and
- `CAMetalDisplayLink` supplies a drawable and target timestamps, but PERF-200
  proves it quantizes this 59.94 Hz source onto the fixed 60 Hz panel and
  cannot invent the missing distinct source frame.

The default `MTLDevice::newCommandQueue` permits up to 64 non-completed command
buffers. This is far above the three-drawable layer pool. Raising that limit
cannot create another drawable; lowering it can only add earlier command-
queue backpressure.

Metal 4 does not replace the layer lifecycle. `MTL4CommandQueue` adds explicit
`waitForDrawable` and `signalDrawable` ordering around an existing
`MTLDrawable`, then requires the same `present`, `presentAtTime`, or
`presentAfterMinimumDuration` calls. Acquisition still comes from
`CAMetalLayer.nextDrawable`. A full Metal-4 backend migration therefore does
not supply a new causal mechanism for PERF-207's wait.

## Actual host defaults

A disposable Objective-C host probe instantiated a real `CAMetalLayer` and
reported:

```text
framebufferOnly=1 maxDrawable=3 presentsWithTransaction=0 displaySync=1 allowsTimeout=1
```

The runner is already receiving the intended fast/default combination:
framebuffer-only textures, the maximum supported three drawables,
asynchronous layer updates, display sync, and finite timeout behavior. The
probe binary SHA-256 was
`c475cf3e5a4c3816f1a71a6b4a2584a54c327c6044e915036de7e77b6f845bda`
and was deleted after recording the result.

## Decision

Do not build a command-buffer-count, timeout, transaction-presentation, or
Metal-4 migration candidate. Their documented semantics do not alter the
proved limiting drawable pool or source/display cadence, while direct
neighboring mechanisms already have live reversals. This closes the current
SDK escape route without changing Dolphin, the app, module, configuration,
ROM data, save, audio, graphics, or netplay behavior.

No game or Simulator ran. G5 remains open and G6 remains blocked.
