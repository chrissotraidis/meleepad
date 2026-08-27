# G5 current-PGO pacing controls rejected

Date: 2026-08-27

## Question

Fresh current-source PGO lowers exact Fountain CPU-thread mean to
11.889/11.606 ms, but total p95 remains 17.608/17.776 ms. Is that remaining
tail an M1 compute ceiling, full-phase observer overhead, the CPU sleep
primitive, or Metal presentation backpressure?

## Existing-window attribution

The two retained exact PGO windows each select emulated frames `48123..48562`
and match 1,501,757,755 guest cycles, 51,380,895 native dispatches, 905,756
bursts, and 882 hook fallbacks. Their 23-row p95 tails do less guest work and
have CPU-thread means of 11.758/11.699 ms, but throttle wake lateness rises to
0.859/0.976 ms. A few isolated worst rows are real compute overruns; the
steady p95 is primarily host pacing after longer sleeps, not M1 saturation.

## Low-overhead buffered control

Dolphin's existing buffered `render_times.txt` logger was enabled in a
disposable PGO user tree without `SSBMPAD_FRAME_PHASE_LOG`. MemoryWatcher was
bound before launch, counted 1,001 advancing fields before `SIGUSR2`, observed
post-load revision-0 `GameState=0x02020102`, then counted 500 more fields. The
final 440 render intervals measured:

| Metric | Buffered PGO control |
| --- | ---: |
| Mean / FPS | 16.784093 ms / 59.580 |
| Median | 16.656416 ms |
| p95 | 17.955917 ms |
| p99 | 22.767083 ms |
| Worst | 113.255417 ms |
| Frames <=16.7 ms | 55.000% |

The phase logger therefore is not creating the strict-tail failure. The raw
local render/vblank logs have SHA-256 `98158ffd...5929aa` and
`9d6f6188...f0efd2`; they contain no game data but remain private diagnostic
inputs rather than product artifacts.

## Metal controls

`VSync=True` changed pacing exactly as expected: CPU throttle requests fell to
zero and Metal video-build time absorbed 4.794 ms mean / 6.219 ms p95. It
failed at 16.850765 ms mean / 17.921875 ms p95 / 18.928500 ms p99 /
130.293708 ms worst. `MTLUsePresentDrawable=1` with VSync still off preserved
ordinary CPU/video costs but failed at 16.810710 / 17.736583 / 21.912375 /
79.016125 ms. Both controls produced 1,501,629,399 cycles, 51,369,928
dispatches, and 905,572 bursts in the nominal interval rather than the exact
control work, so neither is a causal G5 candidate.

The local phase CSV SHA-256 values are `0b09049c...c06c93` (VSync) and
`4fafb2de...aba6b` (PresentDrawable). Both processes stopped normally; no
Simulator was booted and no product config changed.

## Strict dispatch-timer preflight

The retained host preflight now includes a macOS `DISPATCH_TIMER_STRICT`
one-shot source on a dedicated serial queue, followed by Dolphin's unchanged
final scheduler-yield window. The first sanitizer run exposed an `%4` mode
selection bug after the fifth vector remained empty; `% mode_count` plus an
explicit empty-vector guard fixed it. ASan/UBSan then passed.

At 600 interleaved samples with 5.5 ms synthetic work, the strict-dispatch
mode measured 16.687700 ms mean / 16.691085 ms p95 / 16.711846 ms p99 /
18.358375 ms worst, with 98.167% at or below 16.7 ms. It is better than the
generic one-shot sleep and uses no busy spin, but it fails the explicit p99
and worst gates. Reject before a Dolphin build; do not vary queue QoS, timer
leeway, or wake lead without a new mechanism.

## Metal actual-presentation preflight and live rejection

A host-only AppKit/Metal harness records `MTLDrawable.presentedTime` from a
64x64 `CAMetalLayer`; it does not link Dolphin or run emulated code. The first
form waited for each presented callback before submitting the next drawable,
which necessarily missed the following refresh and measured 33.333 ms. The
corrected form pipelines up to the layer's three drawables and writes callbacks
into preallocated slots. ASan/UBSan pass.

With a 16.0 ms minimum duration, two 600-interval scheduled runs and an
immediate-present control all delivered zero drops and 100% of actual onscreen
intervals at or below 16.7 ms:

| Host mode | Mean | p95 | p99 | Worst |
| --- | ---: | ---: | ---: | ---: |
| Scheduled A | 16.666690 | 16.666750 | 16.666792 | 16.666958 |
| Immediate | 16.666677 | 16.666750 | 16.666792 | 16.666792 |
| Scheduled A2 | 16.666664 | 16.666708 | 16.666750 | 16.666792 |

This proves the M1 and its display can present a queued Metal workload at a
stable 60 Hz. It does not prove Dolphin can keep that queue fed.

A default-off local Dolphin candidate then set display sync and used
`presentDrawable:afterMinimumDuration:0.016`, with an explicit stderr mode
identity. It kept the exact PGO module but failed its nominal Fountain bracket
at 16.889775 ms mean / 18.021958 ms p95 / 19.667750 ms p99 /
132.187917 ms worst. CPU throttle requests fell to zero while Metal video-build
time rose to 4.517 ms mean / 6.128 ms p95. Work changed to the same
1,501,629,399 cycles / 51,369,928 dispatches / 905,572 bursts seen in the
other display-backed controls. The candidate is rejected and the Dolphin
source edit is removed.

An existing `fullscreen=true` control, without the candidate, measured
17.493 ms p95 / 17.872 ms p99 / 19.248 ms worst and the same boundary-work
mismatch. It is also rejected. The run does not establish whether macOS Game
Mode activated.

## Decision and next experiment

**VSync, PresentDrawable-only, strict dispatch timer, and observer-overhead
attribution are rejected. G5 remains open; Final Destination and G6 remain
blocked.** The current PGO app is unchanged and no game process or Simulator
remains.

Apple's scheduled-present API passes its isolated host gate, but the live
Dolphin producer cannot use it without blocking in the drawable path and
changing nominal work. Do not retry scheduled presentation, fullscreen, VSync,
or PresentDrawable. Return to a fresh no-phase current-PGO CPU sample and
select one coherent remaining compute outlier; exclude the already rejected
scheduler loop, interrupt leaves, blanket helpers, and guest-PC shortcuts.

Authoritative API references:

- <https://developer.apple.com/documentation/metal/mtlcommandbuffer/present(_:afterminimumduration:)>
- <https://developer.apple.com/documentation/metal/mtldrawable/presentedtime>
