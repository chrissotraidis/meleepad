# G5 frame-interpolation rejection

Date: 2026-08-29

Status: **FAST HOST SUPPORT PROVEN; LATENCY/ARTIFACT ROUTE REJECTED; PRODUCT UNCHANGED**

## Question

PERF-187/188 separate rare fixed-display conversion holds from independent
producer stalls. Can a host-generated, genuinely distinct intermediate frame
fill the fixed 60 Hz panel timeline without changing Melee's exact
`60000/1001` guest, audio, or future netplay timing and without duplicating a
stale image?

## Apple API boundary

The installed macOS 26.5 SDK exposes two candidate APIs on this Apple M1:

- MetalFX `MTLFXFrameInterpolator`, which accepts color with optional depth and
  motion vectors; and
- VideoToolbox `VTLowLatencyFrameInterpolationConfiguration`, which performs
  temporal interpolation from previous/current IOSurface-backed frames.

The MetalFX class reports device and Metal 4 support and creates a color-only
640x528 instance. A 100-iteration synthetic encode costs 2.192113 ms mean,
2.152500 ms p95, 4.721917 ms p99, and 6.051292 ms worst. Without Dolphin depth
or motion vectors, however, a moving square becomes a 50/50 two-position ghost
with no midpoint object. Reject color-only MetalFX before product integration.

The VideoToolbox class reports supported and successfully starts a 640x528
session. Its only supported source/destination format is IOSurface-backed
`420v` NV12. The optional protocol min/max/reference-count selectors advertised
by the SDK are absent at runtime and therefore must be guarded. Model/session
startup varied from 69.827 ms with warm system caches to 910.776-1208.543 ms
on the first launches, confirming Apple's warning that startup does not belong
on the rendering/UI thread.

## VideoToolbox functional result

A host-only Objective-C++ harness used two synthetic NV12 frames, a caller-
allocated midpoint frame at phase 0.5, and synchronous processing. After the
one-time session start:

| Metric | Result |
| --- | ---: |
| First process | 2.353 ms |
| Steady iterations | 40 |
| Mean | 2.380 ms |
| p95 | 2.498 ms |
| p99 | 2.499 ms |
| Worst | 2.849 ms |

For a textured 64x64 square translated across a static checker background,
output MSE was much closer to the true geometric midpoint than to a 50/50
blend for 4-64 pixel displacements:

| Displacement | MSE vs ideal midpoint | MSE vs blend |
| ---: | ---: | ---: |
| 4 px | 3.417 | 11.351 |
| 8 px | 3.625 | 21.221 |
| 16 px | 8.834 | 44.497 |
| 32 px | 5.859 | 71.156 |
| 64 px | 16.188 | 123.128 |
| 128 px | 283.271 | 125.126 |

The 128-pixel case fails by retaining dim objects at both endpoints rather
than forming the midpoint. The 64-pixel visual also develops edge smearing.
This proves useful small-motion interpolation, not artifact-free game output.

## Retained Melee stress screen

A private 120-image capture from 2026-08-25 supplied three adjacent-file
pairs. File timestamps show the set was captured only about three times per
second, so these are deliberately conservative combat/change stress cases,
not claims about consecutive 60 Hz source frames. The standalone tool cropped
the macOS title bar, scaled the viewport to 640x528, converted BGRA to required
NV12, interpolated phase 0.5, converted back, and retained private PNGs.

| Pair | Source luma MAD | Processing | Visual result |
| --- | ---: | ---: | --- |
| 000/001 | 18.311 | 2.251 ms | Bowser, Peach, Ice Climbers, and effects smear across positions |
| 060/061 | 5.733 | 2.177 ms | Ness's hands, legs, and silhouette blend despite the lowest change |
| 100/101 | 11.815 | 2.175 ms | fighters and stage-edge effects become translucent/smeared |

The HUD percentages remain numerically stable in these three midpoint images,
but fighter silhouettes and moving effects fail the visual bar. This is the
same class of morphing/ghosting that `VISUAL-001B` and the user's explicit
warping report require the port to avoid.

## Product and timing decision

**Reject frame generation as the G5 fix.** A causal 59.94-to-fixed-60 converter
must show an interpolated point between previous and current in chronological
order. Because the current frame is required before that point can be created,
the game timeline must be delayed by approximately one source frame
(16.683333 ms). That adds fighting-game input/display latency and future
netplay presentation latency. The processor itself also adds roughly 2.4 ms,
real integration still needs RGB/NV12 conversion or an NV12 render path, and
the low-latency API is available only on macOS/iOS 26 rather than the current
macOS 14 deployment floor.

More importantly, it does not fix the independent producer tail and cannot
guarantee that macOS selects a ready drawable; it manufactures replacement
visual content with demonstrated fighter artifacts. Do not add MetalFX,
VideoToolbox frame generation, 120 Hz synthetic submission, or a one-frame
delayed presentation queue to Dolphin from this evidence.

No product source, module, runner, configuration, ROM, save, app, or Simulator
state changed. No game or Simulator remains. G5 stays open on the genuine
producer timing requirement and the exact acceptance boundary; G6 remains
blocked.

Private evidence hashes:

- MetalFX support/encode sources:
  `0ff00855fa170c88c8faefc6622b61c4d324b7428783f2575888e3fd6898feb9` /
  `82df8dee013385a9ea87183d82c8cd675e71c1af6d1cef4890eab154f2dc4cc7`;
- VideoToolbox support/functional/Melee sources:
  `e948ba9616c06058c4de056ddaf0024e099a94e27f991b1ce0667334b8d8abd0` /
  `ae3c71f0e8d56bad3dd6ab73311f591dee8e1c67d656a819ae0543db67c901bb` /
  `1674d338667f29f8bd118612bae6b23dc487836f623a4883c3ab121d51bbf784`;
- Melee midpoint PNGs 000/001, 060/061, and 100/101:
  `cc56e492e1fa0082c7d8a1ca6600564803a217bcef7ff113bb7a11ac3f317895` /
  `74550bfb7b16e6c1233144a19888d7f76294297742b72573b888b2152d04bb42` /
  `0347006ed37740614ccce062748adf139680d088e9bc45bf8ecc42d1f475520b`.
