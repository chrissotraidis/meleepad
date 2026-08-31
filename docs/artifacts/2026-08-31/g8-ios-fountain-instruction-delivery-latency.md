# G8 iOS Fountain instruction-delivery latency

Date: 2026-08-31

Status: **PERF-245 diagnostic partial; G8 row 7 remains failed**

## Question

Does a literal Fountain of Dreams control reproduce the instruction-front-end
pressure seen in PERF-243, and is the loss primarily sustained delivery
bandwidth or latency waiting for the next instructions?

## Route and harness correction

The exact restored control module had SHA-256 `af1364e6...`. The product was
cold-launched in the iPad Pro 13-inch (M5) Simulator with default stable
single-core settings. No live log stream ran during the accepted route.

The first private-pipe attempt exposed a harness error rather than a product
result. `startInputConsumer` publishes a neutral product snapshot at 60 Hz
unless `SSBMPAD_EXTERNAL_PIPE_INPUT=1` is set before launch, so unguarded pipe
commands are immediately overwritten. The route was restarted with that
documented private diagnostic guard, and only the guarded run is retained.

The visible product path reached:

- P1 Yoshi versus level-1 CPU Zelda;
- an explicit `Fountain of Dreams` stage highlight; and
- coherent live Fountain combat with the on-screen counter at 47.7 FPS.

This is a two-character diagnostic route. It is not the four-character
acceptance workload and cannot pass row 7.

## Process-filtered counter result

Instruments used the Apple M1 host, all-process recording, the guided
`Instruction Delivery Bottlenecks` mode, and a rolling capture-last-five-second
window. Run 2 retained 4 seconds while live Fountain combat remained active.
The recorded track was then filtered and selected as `SsbmPad` PID 88916;
the process-specific summary was:

| Metric | SsbmPad Run 2 |
|---|---:|
| Cycles | 5,881,669,124 |
| Instruction Delivery Latency | 41.74% |
| Instruction Delivery Bandwidth | 7.35% |

The unselected host-wide summary was 38.76% latency and 7.42% bandwidth. It is
retained only as a filter cross-check and is not the app attribution.

Private evidence hashes:

- live Fountain image:
  `24960642a6f5e3be617aab2000e5f4e8a00934583ee83c47c1b860976c911db4`;
- selected SsbmPad process summary:
  `494d656761d946684eccbabac59f46eabb57703767e5e2d94b714dd3a7cfa1ed`.

## Interpretation

Literal Fountain reproduces instruction-delivery pressure, and the measured
loss is dominated by latency rather than sustainable delivery bandwidth.
This agrees with PERF-243's broader crowded-combat direction while providing
a stage-matched process selection.

It does not yet distinguish an instruction-cache or address-translation wait
from redirected/discarded execution. It also does not prove that generic code
size reduction helps: PERF-244 already refuted broad non-LTO compaction.

A separate cold control launch took about 101 seconds from runtime-thread
start to `runtime created`, and the accepted route showed visible non-Fountain
menu/transition dips before settling. Those are product failures but were
observed under substantial current-host load, so they are retained without a
new causal attribution.

## Decision and next measurement

- Keep G8 row 7 failed and physical-iPad promotion closed.
- Do not build another module from this aggregate latency result.
- Repeat matched literal-Fountain process-filtered windows using
  `Instruction Address Translation Metrics` and `Discarded Sampling`.
- A source candidate must name the dominant latency sub-event, preserve
  ThinLTO, and predict a measurable change before it earns a build.
- The final acceptance lane still requires the unchanged product path, two
  complete cold routes, the five-minute manual route, and the four-character
  failure reversal.

The app was stopped and `SSBMPAD_EXTERNAL_PIPE_INPUT` was unset. No ROM,
generated module, trace, profile, save, extracted data, or private path is
committed.
