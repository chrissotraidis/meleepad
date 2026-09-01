# G8 ordinary four-fighter attract collapse

Date: 2026-09-01

Status: **ROW 7 HARD FAIL; CPU ARCHITECTURE GATE REOPENED**

## Question

Does the unchanged published iPad Simulator product sustain target speed in an
ordinary cold launch outside the exact one-on-one Fountain harness, and if not,
which subsystem owns the deficit?

## Controlling ordinary run

The installed app launched with product defaults and no private input pipe,
savestate, profiler, phase logger, dispatch logger, or diagnostic environment.
An HEVC recording ran for 130 seconds while the app advanced hands-off into a
four-fighter attract match. Only one sparse UI observation was made after the
unattended interval.

The visible attract match reported 31.6 FPS in the accessibility label and
about 24.9 FPS in the game counter. The geometry remained coherent. The
matching runtime used the intended product configuration:

```text
cpuVideoSplit=1 syncGPU=1 syncGPUMaxDistance=1000000
```

It began at 59.9-60.0 FPS/VPS, then reported 58.1, 35.1, 50.7, 31.8, 32.2,
32.3, 21.1, 28.5, and 51.6 FPS as the attract state entered, ran, and returned.
The CPU thread reached 96-99.7%, the video thread reached 49-73%, total app CPU
reached about 178%, and DMA underruns rose from 0 to 447. This is sustained
emulation slowdown with audio starvation, not a presentation-counter artifact.

Private evidence retained outside Git:

- video SHA-256:
  `70c17b26f0d1b271dc7becff89290552d81c0aedcf7013b8001f9c1edca35f52`;
- runtime-log SHA-256:
  `18f220977a570cec923b193967479a8d43600d94e0ba649761b7aa7052f97de3`.

## Narrow mechanism repeat

PERF-271 repeated the same hands-off attract path with only phase logging and
one-in-4,096 native-dispatch sampling. The sampling overhead materially slows
even idle/title states, so its FPS is not product evidence. Its work
distribution and cycle accounting remain useful.

During attract frames roughly 6,302-7,619:

- the CPU thread and CPU wall average about 29-41 ms per presented row;
- each row carries about 8.11 million guest cycles, the normal 486 MHz / 60 Hz
  GameCube frame budget;
- each row performs about 416,000 native dispatches;
- Metal present averages about 0.05 ms; and
- no post-warmup pipeline or shader wait owns the deficit.

The largest sampled guest PCs are broad rather than singular. `0x80345760` and
`0x80345738` contribute 7.67% and 7.62%; generated code identifies them as
OSRestoreInterrupts and OSDisableInterrupts rather than the coarse symbol
file's OSPanic offsets. The rest spreads across Melee DVD/status callbacks,
HSD/GX/resource work, and many 2-3% sites. Private evidence retained outside
Git:

- dispatch CSV SHA-256:
  `a7668f10edee87a05dcca6f9f9852256386202a679f5926204d247015439fef7`;
- phase CSV SHA-256:
  `97fd684b57d1fa147ad127e2f77c45155d1d4068d4b324de614c397240912d3f`;
- runtime-log SHA-256:
  `17f3739bcaa529558308bfc24ff8ac0b4af6fb0cd32ec33e0b5c344e160b6f8c`.

## Feasibility assessment

The one-on-one route's roughly 4.16 million guest cycles can fit under the
16.7 ms target on this host. The four-fighter attract route doubles useful
guest work to the complete 8.11-million-cycle budget and takes roughly twice
the available CPU time. Sixty FPS is therefore possible in principle, but not
through another isolated five-percent optimization. The failing state needs a
roughly 50% or greater CPU-thread reduction, with margin for audio and tails.

The following measured paths cannot supply that alone:

- current LLVM SSA output: 6.12 times the C text/instruction footprint and
  4.84-4.93 times slower on an equivalent hot slice;
- interrupt-leaf coalescing: direct-dispatch saving projects only about 2% in
  this workload;
- guarded direct calls: 69% fewer dispatches produced only 1.66% CPU gain;
- broad PGO and attract-trained PGO: live regressions;
- ThinLTO/O3/layout, FastDisc, shader seeding, QoS, and timer variants:
  already measured and rejected; and
- small merged-state or single-function register caches: real 9.7-21.8% local
  gains but less than 1% projected globally in the measured regions.

## Reoriented decision

**PERF-271 reopens generated-code architecture as the only in-scope mechanism
with plausible 60 FPS ceiling.** Do not retry the stock LLVM backend or build
another isolated hotspot. Build a data-free representative region-state
preflight that covers a material fraction of the full attract frame: preserve
the canonical arbitrary-entry path, enter optimized regions only at proven
entries, retain guest GPR/FPR/paired state in locals across internal control
flow, and spill at helpers, exceptions, cycle exits, SMC boundaries, and
uncommon entries.

The new feasibility gate is stricter than the old five-percent build screen.
Before a product module, the representative corpus must:

1. pass full CPU/RAM/cycle/exception equivalence;
2. avoid LLVM's duplicated cold-exit text explosion;
3. demonstrate at least 35% local improvement over the same canonical work;
4. cover enough measured attract work to project at least 25% whole-frame CPU
   improvement in a first tranche; and
5. have a credible extension path to the roughly 50% total reduction required
   for 60 FPS.

A first tranche below 25% may be retained as research but does not earn a full
game build. If representative register-resident regions cannot meet this gate,
the honest conclusion is that the no-JIT static-C architecture cannot guarantee
60 FPS for worst-case Melee on this M1 Simulator host. Physical-iPad promotion,
row 7, and G9 netplay remain closed.

`scripts/analyze-region-coverage.py` makes the coverage gate reproducible. On
the retained attract window and 16 KiB guest regions, the top seven regions
cover 70.39%, just below the 71.43% required for a 25% whole-frame projection
at 35% local gain. The top eight cover 75.99% and project 26.60%. This is an
optimistic sampling bound, not a speed claim: the implementation tranche must
span at least those eight regions or find an equivalently broad set of actual
single-entry paths.
