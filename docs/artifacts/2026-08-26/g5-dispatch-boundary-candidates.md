# G5 dispatch-boundary candidates

## Question

Can the host/module dispatch boundary be made cheaper without changing guest
timing, input, or rendering, and does the change improve both animated menus
and required-stage combat?

The packaged control stayed on signed module SHA-256
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.
No candidate was installed into that bundle.

## Fresh Fountain control

The current corrected control was routed cold through visible P1 Pikachu,
level-1 CPU Mario, an explicit `Fountain of Dreams` stage label, and coherent
live combat. Frames 58,975-61,380 exclude the later scene transition and form
a 2,406-frame stable combat interval.

| Metric | Control |
|---|---:|
| Total mean / p95 / p99 / worst | 16.686490 / 17.622406 / 18.651252 / 51.633708 ms |
| Mean FPS | 59.928720 |
| Frames <=16.7 ms | 54.904% |
| Frames >25 / >50 ms | 4 / 1 |
| CPU-thread mean / p95 / p99 | 15.972800 / 17.430343 / 18.449295 ms |
| Native dispatches mean / p95 | 128,945.155 / 140,820.5 |
| Guest cycles mean / p95 | 8,107,182.675 / 8,138,043.5 |

The p95 tail added about 11,768 dispatches and 2.509 ms of CPU-thread work
over the <=16.7 ms body while guest cycles stayed flat. This supported a
dispatch-boundary experiment but did not justify changing guest scheduling.

Visual evidence:

- `g5-current-fountain-stage-select.jpeg`
- `g5-current-fountain-live-combat.jpeg`

## Two-block batch: rejected semantically

The first candidate executed two generated blocks per chassis dispatch. Its
batch-1 rebuild, after equivalent ad-hoc signing, was byte-identical to the
packaged control. The batch-2 lockstep boot produced 9 divergences in only 88
checks. The byte-identical batch-1 control produced the four known baseline
reports across 163 checks, with the same five fallback skips, one zero skip,
and zero undercharges.

The new report set crossed timing/exception-sensitive boundaries. Batch 2 was
rejected before performance testing and never installed into the packaged app.

## Direct-original dispatch: menu win, combat failure

The second candidate preserved one host timing edge per generated block but
called `dolrecomp_call_original` directly from the chassis export, bypassing
the generic replacement, host-call, and physical-alias probes. Its isolated
lockstep boot matched the control exactly: 163 checks, the same four report
PCs, five fallback skips, one zero skip, and zero undercharges.

### Matched title animation

Frames 1,000-4,999 from the control and candidate have matching mean guest
cycles and native-dispatch counts. The candidate materially reduced host CPU
work and slow frames.

| Metric | Control | Direct-original candidate |
|---|---:|---:|
| Total mean | 17.561007 ms | 17.117450 ms |
| Total p95 / p99 | 26.507742 / 29.536133 ms | 21.658183 / 25.184801 ms |
| Mean FPS | 56.944344 | 58.419915 |
| CPU-thread mean | 16.779213 ms | 14.586568 ms |
| Frames >25 ms | 626 | 41 |
| Native dispatches mean | 37,995.375 | 37,995.499 |
| Guest cycles mean | 8,104,649.902 | 8,104,649.951 |

The later visible Main Menu candidate bracket (frames 12,319-15,168) held
16.683282 ms mean, 16.961447 ms p95, 17.332858 ms p99, 21.536417 ms worst,
and 59.940244 FPS, with no frame over 25 ms. Controller input moved from the
title into the menu normally.

### Required-stage failure

The same candidate was routed visibly through P1 Pikachu, level-1 CPU Yoshi,
an explicit `Fountain of Dreams` label, and coherent live combat. The
2,322-frame capture-free combat bracket failed decisively:

| Metric | Direct-original Fountain |
|---|---:|
| Total mean / p95 / p99 / worst | 20.066726 / 22.767865 / 27.446470 / 40.543916 ms |
| Mean FPS | 49.833741 |
| Frames <=16.7 ms | 2.196% |
| CPU-thread mean / p95 | 19.859305 / 22.487026 ms |
| Native dispatches mean | 132,032.504 |
| Guest cycles mean | 8,107,173.399 |

The first retained live frame showed 41.9 FPS; the longer bracket establishes
that this was not merely transition averaging. The opponent differs from the
fresh CPU-Mario control, so no exact character-to-character delta is claimed.
The required-stage result is nevertheless a hard candidate failure. A menu-only
improvement cannot pass G5.

Visual evidence:

- `g5-direct-dispatch-fountain-stage-select.jpeg`
- `g5-direct-dispatch-fountain-live-combat.jpeg`

Raw retained intervals:

- `g5-direct-dispatch-title-control.csv`
- `g5-direct-dispatch-title-candidate.csv`
- `g5-direct-dispatch-main-menu-candidate.csv`
- `g5-direct-dispatch-fountain-candidate.csv`

## Original-first with generic fallback: no broad fix

A third candidate tried the generated-original lookup first and retained the
entire generic dispatcher on a miss. Its isolated early-boot differential
again matched the control exactly: 163 checks, the same four known report PCs,
five fallback skips, one zero skip, and zero undercharges.

The visible route then entered a Brinstar attract battle at 15.1 FPS. This is
the same class of major slowdown reported by the user, and proves that the
common-path lookup saving is not a broad solution for active scenes. Because
this was not a matched control battle, it is recorded as a failure to solve the
problem rather than a quantified regression. The candidate was stopped and
removed without touching the packaged app.

Evidence: `g5-original-first-15fps-attract-regression.jpeg`.

## Decision and next experiment

All three candidates are rejected and their source changes are removed. The normal
signed app remains on module `2dce1352...`; no runtime or Simulator remains.
G5 stays open.

The direct-original result proves that the common generic probe sequence has a
material menu cost, but the two follow-ups show that rearranging or bypassing
the whole sequence does not solve active-scene cost. The next bounded work is
to count the generic dispatch branches on normal title/menu and Fountain
control, then optimize only the actually hot probe while preserving ordering.
No further ThinLTO candidate is justified until that counter identifies a
material per-frame target.
