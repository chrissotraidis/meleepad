# G5 warm Final Destination wall attribution (PERF-199)

## Question

PERF-198 found three warm Final Destination producer intervals above 20 ms
with no CPU interval above 16.7 ms. Do those rows begin in guest compute,
Metal/presentation work, or host wall-time loss?

## Observer-free render/vblank join

The retained PERF-198 lightweight and `render_times.txt` files contain 17,499
rows each. Every one of the 17,498 comparable values matches exactly when
`render index = lightweight index + 1`. Rare warm spikes establish a stable
`vblank index = render index + 347` mapping:

| emulated frame | lightweight wall | thread CPU | wall minus CPU | vblank |
| ---: | ---: | ---: | ---: | ---: |
| 30,296 | 25.267167 ms | 6.114166 ms | 19.153001 ms | 26.349416 ms |
| 30,312 | 26.342000 ms | 6.647916 ms | 19.694084 ms | 26.652583 ms |
| 30,535 | 26.497500 ms | 6.019209 ms | 20.478291 ms | 28.360792 ms |

All three producer delays therefore reach the guest/vblank path. They are not
isolated logger-row or compositor-only events. Each has ordinary thread CPU
and predominantly wall loss.

Private hashes:

- lightweight CSV:
  `eabb14a73f5f8d3585a1c8e076b4b32d8348942366f4de3a67c34f04ec115bd1`;
- render log:
  `8ed64ae6c90a477adec3ef363bb6c83897ccdd9def055b16234bd8931b1e730f`;
- vblank log:
  `efcaea6b0b2836c2c086dd811ebe7d70d9012f691d6b4b2d98c6f79509c8a371`.

## Detailed same-process attribution

A separate diagnostic process loaded the same verified Final Destination state
twice and completed both matches. Fresh start and warm-results images show
coherent Pikachu-versus-Yoshi gameplay on literal Final Destination. Exactly
one runner was present throughout both selected combat legs; no Simulator or
unrelated process was changed.

Harness correction: targeting the bundle path once launched its stale wrapper
as a second runner. The two PIDs were detected immediately, that owned stale
runner was stopped, and its prefix was excluded. The valid first and second
state loads occurred only after the direct diagnostic runner was again the
sole game process.

All 5,890 warm lightweight rows (emulated frames 30,295 through 36,184) join
one-to-one to detailed phase rows by emulated frame plus nearest shared host
timestamp, with zero unmatched rows. The diagnostic body averages 59.956
FPS, has 17.336125 ms wall p95, zero thread-CPU intervals above 16.7 ms, and
one wall interval above 20 ms. This distribution is observer-bearing and is
not an acceptance result.

The single 59.993541 ms producer/vblank stall at emulated frame 30,518 has:

- 59.411633 ms CPU-thread wall versus 10.339240 ms CPU-thread execution;
- 59 task context switches and a 1.803015 ms late throttle wake;
- ordinary 2,186,738 guest cycles and 69,022 native dispatches;
- 0.032333 ms `nextDrawable`, 0.266333 ms presentation, and 0.064667 ms video
  build;
- 2.076958 ms audio mixing;
- zero EFB pipeline misses and zero interpreter fallback.

Guest compute, fallback, EFB, audio, drawable acquisition, GPU upload, and
presentation are therefore not large enough to explain the missing wall time.
The event is host execution/wake loss in the combined CPU/vblank path.

Diagnostic private hashes:

- lightweight CSV:
  `2665b4a6199947161fa0abe964f59f21b934bc4440f63a63302b5a0584e861e1`;
- phase CSV:
  `68f50f286adb1c12387f7817ec4c53d74ea0d01ee13c9c7d7c2d5071ce13f385`.

## Decision

Retain no product change. Rush Frame Presentation, precision-timer variants,
QoS/precedence, fixed priority, time constraint, affinity, Game Mode, dual
core, and drawable-lifecycle changes already have direct reversals for this
mechanism. Repeating one without a distinct causal signal would be guesswork.

PERF-199 strengthens the split already seen in combined presentation traces:
producer/vblank wall stalls and fixed-rate actual-display holds are separate
classes. G5 remains open and G6 blocked. The next useful work must identify a
genuinely distinct supported host-execution mechanism or improve evidence for
the separate actual-presentation hold; it must not return to static-recompiler
or Metal-cost rewrites from these rows.
