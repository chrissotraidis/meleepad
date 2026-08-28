# G5 true-native correction and full-match stall attribution

Date: 2026-08-28

Status: **NATIVE BASELINE CORRECTED; PRE-METAL STALL PROVEN; G5 OPEN**

## Configuration correction

PERF-091 edited only `Config/GFX.ini` from `InternalResolution = 3` to `1`.
That was not the authoritative input for this runner. `moderngekko-run` loads
the top-level frontend `config.ini`, maps `resolution=1920x1080` to scale 3,
assigns `config.graphics.internal_resolution_scale`, and rewrites `GFX.ini` on
shutdown. PERF-091 through PERF-093 therefore remained at 3x despite the
nominal GFX file edit. Their timer/presenter/Metal attribution is still valid
for that measured configuration, but their native-resolution label and the
old 1x/3x comparison are invalid.

PERF-097 used a fresh private user clone and changed both authoritative forms:

- top-level `config.ini`: `resolution=640x528`;
- `Config/GFX.ini`: `InternalResolution = 1`.

Both values remained native after clean shutdown. The slot-1 savestate stayed
byte-identical at SHA-256
`e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
No product config, ROM, save, or generated module changed.

## Corrected 3x / native / 3x reversal

All three windows select emulated frames `48123..48562`, 440 rows, the same
PGO module, Metal, Cubeb, and effectively identical guest work: charged cycles
differ by only 33 out of 3.567 billion, native dispatches by one out of 59.375
million, and no interpreter fallback occurs.

| Metric | 3x A | True native | 3x A2 |
|---|---:|---:|---:|
| total mean | 16.683 ms | 16.571 ms | 16.677 ms |
| total p95 | 17.071 ms | 17.055 ms | 17.170 ms |
| total p99 | 17.986 ms | 17.287 ms | 17.801 ms |
| total worst | 19.495 ms | 19.568 ms | 20.838 ms |
| rows <=16.7 ms | 243/440 | 250/440 | 241/440 |
| CPU-thread mean | 13.890 ms | 14.181 ms | 14.191 ms |
| CPU-thread p95 | 15.227 ms | 15.337 ms | 15.422 ms |
| video-build mean | 0.0467 ms | 0.0476 ms | 0.0470 ms |
| `nextDrawable` mean | 0.0176 ms | 0.0185 ms | 0.0177 ms |

True native improves total mean by 0.106-0.112 ms and its strict pass count by
7-9 rows, but p95 remains above 16.7 ms and renderer construction is unchanged.
Native is the required gate baseline and should be retained; it is not the G5
tail solution.

Evidence identities:

- true-native phase CSV SHA-256:
  `db9a8958bbce797abd40863b6022d50340b626eb93b3dd43aef1fec352242d32`;
- true-native runner-log SHA-256:
  `fe8385a14799e1e45fdc49c8fd520e00586397090fc3c42fc0a39b71d8644cdb`;
- 3x reversal phase CSV SHA-256:
  `0392c6a3bbdec6eae9afdbcb67998c8f171fb9e15e48d25659582f81032e827a`;
- 3x reversal runner-log SHA-256:
  `d4dcf82b0d33389114fa9aea7fe31cd18fb5bdd59d38920ae07efa264913949b`.

## PERF-096 phase-only full Fountain replay

The restored logger-free PGO runner loaded the same Fountain state after 1,227
advancing startup frames and ran naturally to the post-match memory-card
prompt. The title reported 59.9 FPS there. The combat phase contains 6,723
rows over emulated frames `48123..54845`; the next phase row jumps to 54872
and performs 218.9 million charged cycles, 14.38 million dispatches, 297.4 ms
CPU-thread work, and 23.65 ms audio while transitioning to the prompt. That
451.066 ms transition row and all later menu rows are excluded from combat.

| Combat metric | Mean | p95 | p99 | Worst |
|---|---:|---:|---:|---:|
| total | 16.683 ms | 17.001 ms | 17.336 ms | 54.523 ms |
| CPU wall | 16.309 ms | 16.628 ms | 16.968 ms | 54.096 ms |
| CPU thread | 14.051 ms | 15.494 ms | 16.217 ms | 22.570 ms |
| video build | 0.0418 ms | 0.0580 ms | 0.0814 ms | 0.250 ms |
| `nextDrawable` | 0.0163 ms | 0.0245 ms | 0.0321 ms | 0.120 ms |
| audio mix | 0.711 ms | 1.248 ms | 1.321 ms | 1.489 ms |

Only one combat row exceeds 33 ms and nine exceed 20 ms. CPU-thread work fits
16.7 ms on 6,699/6,723 rows (99.643%), but total time fits on only
3,822/6,723 rows (56.850%); the phase logger is diagnostic and does not replace
stripped actual-presentation acceptance evidence.

The 54.523 ms worst row at emulated frame 51080 is causally narrow:

- CPU wall: 54.096 ms;
- CPU thread: 17.223 ms;
- wall minus thread: 36.874 ms;
- `nextDrawable`: 0.031 ms;
- video build: 0.173 ms;
- audio mix: 1.458 ms;
- charged cycles: 8,107,280;
- native dispatches: 144,124;
- EFB pipeline misses: zero.

The neighboring totals are 20.933, 54.523, and 24.063 ms, followed by
14.576/14.092 ms recovery. Guest work is ordinary and Metal acquisition is
negligible. This is a real pre-Metal off-core scheduling stall, consistent
with the rare full-match misses retained in PERF-069/070. Two EFB misses occur
elsewhere and do not explain it.

Full-run evidence identities:

- phase CSV SHA-256:
  `c6990db4a843a691f7fa5ea04e758a85ba71daf3c98688b0fdb784fcda119e21`;
- runner-log SHA-256:
  `cd8ffe4c2d7e611519d02187b4bc127bc5481fc6feb28f1e3ccd26869b13ed13`;
- post-match screenshot SHA-256:
  `accb25e34d8cc2aa976d43ab924c768189d3891dc4160e34bcfb9c541ff02d2c`.

## Decision

Retain true native 640x528 for subsequent gates and correct all references
that called PERF-091 through PERF-093 native. Do not treat resolution or
drawable acquisition as the rare-stall fix. The remaining severe combat stall
is pre-Metal and mostly off-core. The next experiment must attribute that
off-core interval to a concrete kernel wait or scheduling edge without
repeating rejected QoS, time-constraint, dual-core, timer, VSync, or
presentation variants. G5 remains open; Final Destination and G6 remain
blocked.
