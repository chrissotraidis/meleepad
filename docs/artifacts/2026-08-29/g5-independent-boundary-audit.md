# G5 independent boundary audit

Date: 2026-08-29

Status: **NO EVIDENCE-QUALIFIED PRODUCT-LOCAL BUILD REMAINS; G5 OPEN**

## Scope

An independent read-only reviewer audited the approved D2 wording, the current
G5 loop, all newest 2026-08-29 causal artifacts, and the relevant current
ModernGekko/Dolphin source. It made no edit, build, launch, process change, or
GUI action. The local audit independently checked the same remaining scheduler,
throttle, Foundation-activity, Metal, and audio controls.

## Closed product-local mechanisms

The review confirms the current causal boundary rather than proposing another
near-duplicate toggle:

- **Guest/static-recompiler compute:** the lightweight producer diagnostic has
  no thread-CPU interval above 16.7 ms; captured wall failures lose time while
  off-core. Fresh symbolized work contains no unclosed local operation above
  the 5% implementation gate.
- **GPU/render saturation:** all nine sustained actual-presentation misses had
  completed GPU work 10.408-30.918 ms before the skipped deadline; GPU work is
  only 1.565649 ms mean and 2.522875 ms worst.
- **Metal/presentation:** direct and command-buffer presentation, VSync,
  display sync, scheduled/absolute presentation, Rush, drawable acquisition,
  an extra application queue, and a two-drawable layer all have causal
  rejections. The current source exposes no distinct hidden queue path.
- **Scheduling/timing:** user-interactive QoS, priority, soft time constraint,
  Game Mode, timer variants, process activities, workgroups, dual-core, and
  latency QoS are closed. Apple's affinity tags express cache-locality groups,
  not supported core pinning.
- **Audio:** no-output worsened timing; the effective 1,024-frame Cubeb request
  also worsened timing; DSP-thread toggling is inert under Melee's DSP HLE.
- **Ancillary workers:** new shader compilation, extracted-disc streaming,
  FPS-title/CoreSpotlight traffic, and both Logitech components are rejected as
  the residual shared cause.

Local follow-up also screened `NSActivityAnimationTrackingEnabled`. Apple's
documentation defines it as a performance-investigation signpost interval,
not a scheduling, timer, or App Nap policy. It is an observer flag and does not
justify a build:
<https://developer.apple.com/documentation/foundation/processinfo/activityoptions>.

## Acceptance ambiguity, not a pass

PRD D2 requires the macOS worst-case frame interval inside 16.7 ms including
audio. Section 8 calls this a frame budget and asks for worst-case intervals.
Some later artifacts describe the unchanged requirement as the worst
**presented** interval. Those are not equivalent on this machine:

- GALE01's distinct-frame cadence is exactly `60000/1001`, or 16.683333 ms;
- the built-in panel exposes only fixed 60.000000 Hz modes and no VRR; and
- a host-only Metal control independently reproduces periodic 33.333 ms
  distinct-surface holds when fed at the guest cadence.

A GPU-ready fixed-rate conversion hold therefore cannot prove a guest-work
budget miss. Existing docs already preserve that distinction. This audit does
not edit the PRD or weaken D2, and it cannot pass G5: separate observer-light
producer intervals still exceed 16.7 ms before presentation.

## Decision and next causal boundary

**Do not launch another product build from the current evidence.** Untested
Core Animation hints, transaction presentation, drawable timeout, manual
unified-memory uploads, generic `AudioLatency`, DSP threading under HLE, and
animation-tracking activities cannot repair the established boundary by their
documented semantics.

The remaining genuine class is whole-task host-execution loss shared by
Fountain and Final Destination. Every supported product-local policy found so
far has a causal rejection. The smallest unresolved test is an explicitly
authorized, reversible clean-host isolation of unrelated runnable load,
followed by the same confirmed-Game-Mode Fountain and Final Destination
controls. Until that scope is authorized, leave unrelated processes alone and
do not disguise a repeated timing run as progress.

G5 remains open. Final Destination acceptance and G6 remain blocked. No game or
Simulator is running.
