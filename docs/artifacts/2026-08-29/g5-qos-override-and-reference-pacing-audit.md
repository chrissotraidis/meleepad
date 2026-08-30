# G5 QoS override and reference pacing audit (PERF-201)

## Question

After PERF-199 localized the remaining producer tail to host execution/wake
loss, do either Apple's temporary pthread QoS override or the current upstream
Dolphin/Slippi pacing implementation provide a genuinely distinct mechanism?

## Temporary QoS override

The installed macOS 26.5 SDK's `pthread/qos.h` defines
`pthread_override_qos_class_start_np` for a specific pending work item whose
completion depends on work currently executing on a target thread. The
override must end once that dependency is satisfied. While active, the target
runs at the maximum QoS class/relative priority among its own requested class
and all overrides.

That contract rejects a permanent game-loop override for two independent
reasons:

1. SsbmPad has no separate pending user-interactive work item waiting on the
   combined thread for the duration of gameplay. Manufacturing one would
   misrepresent the dependency and leak/elevate resources if not paired.
2. The prior rejected scheduler reversal already requested
   `QOS_CLASS_USER_INTERACTIVE` at relative priority zero on the combined
   thread. An override cannot exceed that same maximum class/priority.

It is therefore neither a new scheduling tier nor a valid use of the API. No
benchmark or product build is justified. Header SHA-256:
`bfcfcf23501c328f5aa7f3bb39c0c8167730ab111393063c5b5fb4bd72d074f2`.

## Current reference-source comparison

Fresh primary-source files were fetched from current `master` for both
[`dolphin-emu/dolphin`](https://github.com/dolphin-emu/dolphin) and
[`project-slippi/dolphin`](https://github.com/project-slippi/dolphin):

- `Source/Core/Core/CoreTiming.cpp`;
- `Source/Core/VideoCommon/Present.cpp`; and
- `Source/Core/VideoBackends/Metal/MTLGfx.mm`.

Upstream Dolphin and Slippi are byte-identical in `CoreTiming.cpp` and
`MTLGfx.mm`. Their `Present.cpp` difference is limited to Slippi omitting two
framebuffer metadata fields and an initializer-order change. Both retain the
same `Throttle`, `PrecisionTimer::SleepUntil`, presentation sleep,
`GetUpdatedPresentationTime`, `nextDrawable`, and `presentDrawable` flow used
by this checkout before SsbmPad's default-dormant observers and retained Metal
display-sync policy.

Primary-source SHA-256 identities:

| source | Dolphin | Slippi |
| --- | --- | --- |
| `CoreTiming.cpp` | `821e9959...fa9` | `821e9959...fa9` |
| `MTLGfx.mm` | `f658f7f0...241` | `f658f7f0...241` |
| `Present.cpp` | `b729e0f2...869` | `24a30dd2...93e` |

There is no unported reference pacing/scheduler implementation to transfer.
This is a source comparison, not proof that the references meet SsbmPad's
strict D2 gate.

## Compiler recheck

The other open required stage, Fountain, already uses the retained frontend-
PGO, O2, ThinLTO module. O3/native tuning, whole-module IR PGO, order files,
LLVM lowering, and all dispatch regions selected by PERF-196 have direct
rejections. No whole-module compiler lever was missed by returning from the
host-wake lane.

## Decision

Retain no product change. Do not add a permanent fake QoS dependency, repeat
the already-rejected user-interactive class, or import identical reference
pacing code. PERF-201 closes these two proposed escape routes without a game
launch. G5 remains open on genuine producer intervals above 16.7 ms; G6
remains blocked.
