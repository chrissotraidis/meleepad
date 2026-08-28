# G5 absolute scheduled-presentation rejection

Date: 2026-08-28

Status: **PERF-133 REJECTED BEFORE DOLPHIN BUILD; G5 OPEN**

## Question

The retained host-only Metal harness proves that a three-drawable queue can
deliver stable 60 Hz, while joined Fountain evidence includes genuine gaps
where Dolphin assigns no present command buffer. Dolphin prepares its drawable
before the presentation deadline but calls `PresentBackbuffer` only after its
host sleep. Can Metal's absolute `presentDrawable:atTime:` API commit work
early and absorb a short producer deschedule without changing guest timing or
submitting a duplicate frame?

This differs from the rejected live candidate in
`g5-pgo-pacing-controls-rejection.md`: that candidate combined layer display
sync with `presentDrawable:afterMinimumDuration:`. It also differs from Rush
Frame Presentation, which removes the timing target and worsened the live
tail.

## Host preflight

A disposable extension to `scripts/g5_metal_present_preflight.mm` added an
absolute-time mode and an optional one-shot producer stall. The command buffer
used the same clear-only 64x64 render pass, three-drawable layer, presented
callback, and 600 measured intervals as the retained harness. AppleClang built
it at `-O2 -Wall -Wextra -Werror` with ASan and UBSan.

The unchanged minimum-duration control passed:

```text
samples=600 minimum_duration_us=16667 producer_interval_us=0 mode=duration
mean=16.666619 median=16.666625 p95=16.666667 p99=16.666708
worst=16.666875 le16.7=100.000% gt16.7=0 dropped=0
```

Absolute scheduling failed before it could measure cadence:

```text
displaySyncEnabled=true, no injected stall:  dropped=601 measured=601
displaySyncEnabled=true, 25 ms stall:         dropped=601 measured=601
displaySyncEnabled=false, no injected stall: dropped=601 measured=601
displaySyncEnabled=false, 25 ms stall:        dropped=601 measured=601
```

The 601 values include the endpoint needed to form 600 intervals. Each
presented handler ran, but every drawable reported `presentedTime == 0.0`.
Apple documents that value as not presented or dropped, so these are not
treated as missing telemetry.

## Clock check

Apple defines the requested time as Mach absolute time in seconds. A direct
check measured:

```text
CACurrentMediaTime=604798.8553132918
mach_absolute_seconds=604798.8552959583
delta=0.0000262501 seconds
```

The 26 microsecond agreement rules out a host-clock-domain mistake. The first
requested presentation was also 100 ms in the future. Changing layer display
sync did not change the all-drop result.

## Decision

**Reject absolute scheduled presentation on this M1/macOS Metal layer path.**
Do not build a Dolphin candidate, infer cadence from callbacks that report
zero, retry the API with a different lead, or combine it with another pacing
change. The disposable harness extension was removed; the retained harness and
product remain unchanged.

This closes the remaining simple early-commit API variant. The callful
guest-state path and compiler-target flag path are also not new candidates:
PERF-088 already executed the complete parent/callee trace and rejected it,
and AppleClang already targets `apple-m1` while PERF-086 rejected the explicit
M1/native flag variants. G5 remains open for the separate natural no-queue
producer/descheduling tail.

## Primary API references

- <https://developer.apple.com/documentation/metal/mtlcommandbuffer/present(_:attime:)>
- <https://developer.apple.com/documentation/metal/mtldrawable/presentedtime>
- <https://developer.apple.com/documentation/quartzcore/cametallayer/displaysyncenabled>

No game, ROM data, generated module, app, Simulator, or product source changed.
