# G8 controlled Big Blue factorial

Date: 2026-09-01

Status: **STAGE ALONE REFUTED; FOUR-PLAYER ATTRACT INTERACTION REMAINS**

## Question

Does Big Blue itself cause the retained 21-35 FPS collapse, or does the
failure require its four-player attract roster/cold state?

## Deterministic route

Two bounded passive no-recorder searches failed to encounter the retained Big
Blue projection hash `002a81fb84e3f68f`. The next run stopped relying on
attract selection.

The on-screen touch publisher initially neutralized external analog commands.
The existing diagnostic-only `SSBMPAD_EXTERNAL_PIPE_INPUT=1` boundary gave the
FIFO route sole control. The route visibly reached VS character select and
Stage Select. The ordinary Simulator GCI had Big Blue locked, so the current
GCI was backed up byte-for-byte and the already-retained isolated ROM-safe
unlock GCI was installed temporarily. The full stage grid appeared.

The game itself visibly labeled the selected tile:

```text
F-Zero Grand Prix
Big Blue
```

The match used P1 Pikachu and CPU Peach. This is a controlled one-on-one stage
factorial, not a recreation of the failing Ness/Peach/Ice Climbers/Bowser
attract roster.

## Result

The live no-recorder match held 59.9 FPS. Runtime confirmed the exact retained
Big Blue hash at two consecutive rows:

```text
fps=59.9 vps=59.9 projectionHash=002a81fb84e3f68f
CPU thread=68.8 Video thread=35.9

fps=59.9 vps=59.9 projectionHash=002a81fb84e3f68f
CPU thread=60.2 Video thread=37.4
```

`SIGUSR1` retained the live Big Blue state. A fresh diagnostic launch loaded it
with `SIGUSR2`; after the one load row at 57.4/56.4, the replay held 59.9-60.0
FPS/VPS. The exact Big Blue row remained 59.9/59.9 with CPU/video at
66.5%/41.9%. DMA underruns rose only 0 to 1 at load and then stayed flat.

Private proof outside Git:

- live screenshot SHA-256:
  `24453ad7095dfa82d702f8514e930a651661e95dd2bf67006ee898e6e8c9144e`;
- Big Blue state SHA-256:
  `b77413f85ad58d20efe647829eb412704e121ff64a9068a79a3fc120c0b77c05`;
- replay phase CSV SHA-256:
  `fb4fd853de2200d686d0c7e54df6a76c740958420953607027439f55a5132d94`;
- replay burst CSV SHA-256:
  `38d0b8be249b5c6d28e48cd1d993d3d00ccbd563fb41b42f18ae6619bba4a1e1`;
  and
- replay runtime SHA-256:
  `4251fea051aea9fabe8a035284217368fb614a9da579ad8f509531ac55e98601`.

The app was stopped, all diagnostic environment was cleared, and the original
Simulator GCI was restored at SHA-256
`0a361d3471289f6c4ea1f4c0254b1f197b44fb8466e408b71240418f01ad0e70`.
No GCI, state, ROM, module, log, or screenshot is tracked.

## Decision

Big Blue stage geometry alone does not explain the collapse. Four players
alone also remains refuted by the 59.7-60.0 FPS Hyrule control. The remaining
causal unit is the interaction among Big Blue, the four-player roster/AI, and
attract first-use state.

Do not build broad register-resident regions from the passing one-on-one trace
and do not call the worst case solved. The next controlled factorial is the
same unlocked Big Blue route with three CPU slots active. If that holds 60,
the failing attract roster/cold state is controlling. If it collapses, retain
that four-player state and use its matched control/replay paths for the
architecture gate.
