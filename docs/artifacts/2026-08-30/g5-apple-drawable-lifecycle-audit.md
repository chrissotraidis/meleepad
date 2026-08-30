# G5 Apple drawable-lifecycle audit (PERF-209)

Date: 2026-08-30

Status: **APPLE RECOMMENDED LIFECYCLE ALREADY SATISFIED; NO OPACITY/RETAIN CANDIDATE; G5 OPEN**

## Question

Apple's current Metal guidance says blocking `nextDrawable` can be aggravated
when an application acquires a drawable too early, retains it too long, or
prevents direct-to-display presentation. Does SsbmPad violate one of those
conditions in a way that explains PERF-207's drawable waits?

Primary references:

- <https://developer.apple.com/documentation/quartzcore/cametallayer>
- <https://developer.apple.com/documentation/metal/onscreen-presentation>
- <https://developer.apple.com/documentation/metal/managing-your-game-window-for-metal-in-macos>

## Apple's relevant boundaries

Apple documents a limited reusable drawable pool and recommends requesting a
drawable only when needed, performing independent CPU/GPU work first, and
releasing strong references promptly after committing the onscreen render
pass. On Apple silicon, direct-to-display also requires fullscreen operation,
an opaque Metal layer, and RGB content.

`CAMetalDisplayLink.preferredFrameLatency` is not an untested continuum: Apple
accepts only 1.0 or 2.0 frames. PERF-200 already uses 1.0 and proves that a
fixed 60 Hz panel still requests two source-less callbacks in forty seconds
from a 59.94 Hz source. More lead time cannot create those distinct frames.

## Current source audit

The macOS Metal backend replaces the SDL view's backing layer with a fresh
`CAMetalLayer`, sets the Metal device, and uses `BGRA8Unorm` unless HDR is
explicitly active. The retained configuration is native 640x528 fullscreen
and non-HDR.

Before `BindBackbuffer` calls `nextDrawable`, `Presenter::Present` performs
the independent flush/rectangle work. The remaining XFB and onscreen UI work
must target the acquired drawable. Moving those operations earlier requires
an offscreen texture and later blit, which is the separate presentation-
reserve architecture already rejected by PERF-168 rather than a free reorder.

Both `BindBackbuffer` and `PresentBackbuffer` use Objective-C autorelease
pools. The latter moves the sole retained drawable into the scheduled
presentation handler and clears `m_drawable`; the direct `presentDrawable`
alternative already has a live rejection. No forgotten product reference was
found.

## Actual layer preflight

A disposable host probe instantiated the same class and reported:

```text
opaque=1 pixelFormat=80 framebufferOnly=1
```

Metal value 80 is `MTLPixelFormatBGRA8Unorm`. Together with the separately
verified fullscreen setting, the layer is already opaque, RGB, and eligible
for Apple's direct-to-display path. Adding `setOpaque:YES` would be a semantic
no-op. The probe binary SHA-256 was
`0b919ea37edbac6901f10f1cad48e3088c5f175abc70e0eaa4c5ee90c263e01f`
and was deleted after recording the result.

## Decision

Do not build an opacity, framebuffer-only, extra-autorelease, drawable-retain,
or preferred-latency candidate. The current product already satisfies the
relevant Apple guidance, while the only materially later-acquisition design
duplicates an architecture that failed actual-cadence and latency screens.

No Dolphin, product, module, configuration, ROM data, save, audio, graphics,
or netplay state changed. No game or Simulator ran. G5 remains open and G6
remains blocked.
