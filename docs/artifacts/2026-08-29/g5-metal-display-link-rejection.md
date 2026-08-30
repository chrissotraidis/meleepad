# G5 CAMetalDisplayLink rejection (PERF-200)

## Question

Can Apple's current `CAMetalDisplayLink` API eliminate the separate GPU-ready
actual-presentation hold while preserving every distinct approximately
59.94 Hz Melee frame and leaving deterministic guest, audio, and netplay timing
unchanged?

## API and source audit

The installed macOS 26.5 SDK declares `CAMetalDisplayLink` for macOS 14 and
later. A callback owns a `CAMetalDrawable` and exposes target render and target
presentation timestamps. The link accepts a `CAFrameRateRange` and preferred
frame latency. Current Dolphin does not use it; it acquires a drawable from its
`CAMetalLayer`, sleeps to the guest-derived intended presentation time, and
submits the command buffer directly.

This is distinct from previously rejected absolute/minimum-duration Metal
presentation, Rush Frame Presentation, display-sync, drawable-count, and
fixed-wake candidates. It was therefore eligible for a host-only preflight.

## Data-free preflight

Retained harness `scripts/g5_metal_display_link_preflight.mm` creates a 64x64
Metal layer, renders a changing clear color for every callback, and records
callback, target, target-presentation, and actual `presentedTime` intervals.
It also maps the returned target-presentation timeline to the requested source
rate. A repeated-source callback means a real source at that rate has no new
distinct frame for the display deadline.

AppleClang built the harness for arm64 at `-O2 -Wall -Wextra -Werror` with
AddressSanitizer and UndefinedBehaviorSanitizer. Runs used
`ASAN_OPTIONS=detect_leaks=0:halt_on_error=1` because LeakSanitizer is not
supported on this macOS host. No sanitizer diagnostic occurred.

## Exact 60 Hz control

The 600-interval control requested and modeled exactly 60 Hz:

| metric | result |
| --- | ---: |
| Modeled repeated-source callbacks | 0 |
| Actual presentation mean | 16.666964 ms |
| Actual p95 / p99 | 16.667042 / 16.667042 ms |
| Actual worst | 16.667083 ms |
| Actual intervals at or below 16.7 ms | 599 / 599 |

The harness can therefore drive this fixed panel cleanly when it invents one
new host-rendered frame for every 60 Hz callback.

## Requested 59.94005994 Hz result

The 2,400-interval run requested an exact fixed range of 59.94005994 Hz. Core
Animation still returned a 60 Hz target/presentation cadence:

| metric | result |
| --- | ---: |
| Target interval mean | 16.666980 ms |
| Actual presentation mean | 16.666966 ms |
| Actual p95 / p99 | 16.667042 / 16.667083 ms |
| Actual worst | 16.670750 ms |
| Actual intervals at or below 16.7 ms | 2,399 / 2,399 |
| Modeled repeated-source callbacks | 2 |
| Modeled skipped-source frames | 0 |

The apparently perfect actual cadence is possible only because the preflight
generates a fresh color on every callback. Mapping the same deadlines to a
valid 59.94 Hz source exposes two callbacks with no new source frame in forty
seconds. A real integration must therefore duplicate a stale frame, synthesize
an intermediate frame, or speed up deterministic guest/audio time.

Those are not solutions to G5: stale duplication does not produce a distinct
game frame, interpolation was visually rejected in PERF-190, and changing
guest speed was rejected in PERF-189 and would affect audio/netplay semantics.
The display link cannot create source information that does not exist.

## Identity and decision

- retained source SHA-256:
  `3e956041da32f526cf450f96b9919e25e0ee8948e92e5dad4a4c1a8b3aa834a8`;
- 60 Hz private output SHA-256:
  `53d52075eb7cd497d33e818f90d20144c77995b40ea3369785340e08e9a706db`;
- 59.94 Hz private output SHA-256:
  `48a91a949ae09946b0b4745ab4d684b79ace389791386f499c09075fd4e3ba58`.

Reject product integration. `CAMetalDisplayLink` is a useful display-driven
rendering primitive, but on this fixed 60 Hz panel it quantizes the requested
59.94 Hz source to 60 Hz and merely moves the unavoidable conversion decision
into the callback. No game, ROM, save, module, product source, or Simulator was
used. G5 remains open and G6 remains blocked.
