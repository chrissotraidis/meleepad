# G8 caller-qualified controller-wait yield

Date: 2026-09-01

Status: **MECHANISM AND PRODUCT REVERSAL PASS; ROW 7 ACCEPTANCE STILL OPEN**

## Question

Why can a live opening/attract battle spend 27-37 ms on the CPU thread while
Metal presentation remains negligible, and can that work be removed without
underclocking, changing graphics, or skipping game logic?

## Zoomed-out diagnosis

PERF-280 retained sparse consecutive edges from a live visible four-player
interval whose 480-row window averaged 27.807 ms total and 26.609 ms CPU-thread
time, with 7.689 million guest cycles and 434,437 native dispatches per frame.
The dominant edge stream is a deterministic 23-entry cycle rooted at:

```text
801A4064 -> 80019814 -> ... -> 80019550 -> ... -> 801A4064
```

Generated revision-1.00 code shows that `0x801A4064` calls the raw controller
queue service. That service disables interrupts, checks the controller queue,
services the periodic alarm path, restores interrupts, and returns. When no
sample is ready, the caller services reset/card callbacks at `0x80019550` and
branches back. The loop exits only after the scheduled controller alarm
supplies a sample. It is host-busy waiting for emulated time, not useful fighter
AI, rendering, DVD decompression, or a weak-M1 symptom.

This is distinct from the already retained scheduler-idle address. The safe
boundary is caller-qualified: after the branch, guest PC is `0x80019550` while
LR remains `0x801A4064`. The shared service routine is called elsewhere, so PC
alone is not a sufficient guard.

## Candidate

Patch 0038 adds two ordinary static-recompiler config values and a default-off
environment override for diagnostics. It calls Dolphin's existing
`CoreTiming::Idle()` only when both PC and LR match. The iOS GALE01 host enables
the exact pair `80019550/801A4064`; no player-facing toggle or performance mode
was added. The existing scheduler-idle guard remains unchanged.

`CoreTiming::Idle()` consumes the remaining host slice by moving to the next
scheduled event. It does not invent guest results, lower the emulated clock, or
remove the alarm that exits the loop.

## Same-sequence reversal

An environment-enabled candidate and default-off control used the same Release
binary and ordinary save. The deterministic emulated-frame range 7,500-9,500
contains the stressed live sequence:

| Metric | Control | Candidate | Change |
| --- | ---: | ---: | ---: |
| Total/frame | 17.048 ms | 16.684 ms | -2.1% while cadence-capped |
| CPU-thread/frame | 13.600 ms | 9.529 ms | **-29.9%** |
| Native dispatches/frame | 380,751 | 107,535 | **-71.8%** |
| Charged guest cycles/frame | 6.346M | 3.116M | **-50.9%** |

The candidate retained 26,200 active rows through emulated frame 26,699 at
16.689 ms mean and 19.034 ms p95. It had no consecutive strict-slow cluster;
the guest frame index advanced throughout and a final screenshot visibly shows
advancing Hyrule combat at 59.9 FPS.

The reduction in charged cycles is expected: the busy loop's repeated guest
instructions are no longer executed one iteration at a time while waiting for
the same scheduled event. Emulated time and the event still advance through
CoreTiming.

## Default-product validation

The config-backed implementation was rebuilt into a fresh Release Simulator
app and launched with no caller-idle environment variables. Its runtime log
records:

```text
runtime scheduler idle skip=enabled pc=80348814 caller=80019550/801A4064
```

Across 15,021 complete active rows through emulated frame 15,520, it measures:

- 16.714 ms mean, 19.148 ms p95, and 20.220 ms p99 total time;
- 9.482 ms mean CPU-thread time;
- no strict-slow cluster longer than two frames;
- 59.6-60.2 FPS/VPS in every retained ten-second live runtime report;
- progressing multi-character attract combat, including the stressed range;
- active speaker audio, with DMA underruns rising only during cold/high-work
  transitions from 0 to 10 and then remaining flat; and
- no crash, pause, audio interruption, or visible geometry failure in the run.

In the same 7,500-9,500 range, the product uses 10.464 ms CPU time and 126,364
dispatches per frame, close to the opt-in candidate and materially below the
control. This proves the default product configuration is active.

## Decision and remaining gate

Retain patch 0038 and the iOS GALE01 caller-qualified configuration. The
primary live CPU collapse now has a causal, semantics-bounded fix and the
default Simulator product holds target cadence in the measured sequence. Do
not return to the rejected fixed-phase region rewrite, broad PGO/compiler
tuning, M1 host blame, resolution reductions, or an exposed performance mode.

Row 7 is not yet marked complete. The next work is acceptance, not another
architecture rewrite: two complete fresh-process routes and the required
manual five-minute Fountain combat route must retain controls, results/return,
audio, lifecycle, coherent rendering, and 59.9-60.0 FPS. A physical iPad still
requires its separate signed-device and thermal replay.

## Private evidence

No ROM, save, module, phase log, runtime log, or screenshot is tracked.

- live slow phase/burst: `9b7f221e...` / `0aa07ce...`;
- opt-in candidate phase/final screenshot:
  `2b3f688689a811e105c0b4f6f4892b99fa7c1c8d43701e8d8b25f67e8857658b` /
  `0c239924a14cc8100824bdfab745f0828c3a98f7db0ecfcdfe91f75cc1d63950`;
- same-binary control phase/final screenshot:
  `4bdeb92977eeea9daed2c39d2ace0a5cbe217a0e320106c68349f1cb228d6118` /
  `c7e5e747386fba6697351b23f013520cebc10335ab49204e45d03b778fd812e3`;
- default-product phase/runtime/final screenshot:
  `620c25a31d0a3f0ebcc3eaab61d096127d44e8a82bb6908319df8ba3919247af` /
  `04f93a6a8e59e9ea2e882e2c91a31eddedd82b48484147e1b7e96ba8fa8c4d7e` /
  `619700d34f0e868b18b9e842f6dee59e6843277c16f45b44e5096f5fd45febbc`;
- ordinary Simulator GCI remains
  `0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
