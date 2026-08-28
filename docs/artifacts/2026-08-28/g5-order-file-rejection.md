# G5 profile-derived Mach-O order-file screen

Date: 2026-08-28

Status: **ORDER-FILE LAYOUT REJECTED; G5 OPEN**

## Question

Can the retained frontend-PGO profile improve the exact PERF-072 Fountain
workload through a semantics-neutral Mach-O order file that places the common
dispatcher, hot runtime helpers, and four hottest generated regions together?

## Structural preflight

The experiment used the existing locally trained frontend-PGO objects. A
temporary cache-identity tag and `-Wl,-order_file,...` linker flag selected,
in order:

- `chassis_dispatch`;
- the retained `lmw`/`stmw`, FP-availability, PSQ, FPSCR, scalar-FP, FMA,
  conversion, and cache-control helpers; and
- `func_8033D940`, `func_80339940`, `func_8035D940`, and `func_80359940`.

The signed arm64 candidate module SHA-256 is
`adda723a801f28308b7535cb3f86c33988b11fa69c2c1b18666b35925325ef7f`.
`nm` proves the linker placed the requested symbols contiguously from
`chassis_dispatch` at `0xce0` through `func_80359940` at `0x11108c`.
The module's `__text` remains exactly 81,959,380 bytes, matching PERF-072, so
the screen changed placement rather than code size. Package layout, arm64
identity, and strict deep signing pass.

The compiler/cache-identity substitutions were experiment-only. Dependency
bootstrap and patch reverse-apply checks passed after restoration, and the
canonical active module pointer again selects the retained profile-free key.

## Exact-work runtime result

Exactly one foreground game process ran the ordered frontend-PGO app with
Metal, Cubeb, an isolated user directory, frame-phase logging, and no
Simulator. The state-load signal was withheld until emulated frames advanced.
Direct UI inspection showed coherent Pikachu/CPU-Fox Fountain combat at a
60.0-FPS title, with no character morphing in the retained frame. The process
exited normally.

The last occurrence of every emulated frame `48123..48562` produced 440 rows
and exactly matched PERF-072:

- 1,501,757,755 guest cycles;
- 51,380,895 native dispatches;
- 905,756 bursts;
- 882 hook fallbacks; and
- zero fallback steps.

| Metric | PERF-072 frontend PGO | Ordered frontend PGO |
| --- | ---: | ---: |
| Mean / FPS | 16.663618 ms / 60.011 | 16.852325 ms / 59.339 |
| Median | 16.553833 ms | 16.610375 ms |
| p95 | 18.065125 ms | 17.901500 ms |
| p99 | 19.130250 ms | 18.561542 ms |
| Worst | 22.509416 ms | 133.106958 ms |
| CPU-thread mean | 11.620875 ms | 11.537926 ms |
| CPU-thread p95 | 12.770189 ms | 12.547011 ms |
| Frames <=16.7 ms | 55.909% | 55.682% |

The 0.083 ms CPU-thread mean reduction is only 0.714%, below the retained 5%
materiality threshold. Total mean regressed by 0.189 ms, compliance did not
improve, and worst-frame behavior became substantially worse. The better p95
and p99 values do not justify retaining a layout whose mean, compliance, and
worst frame lose the control.

## Decision

**Reject the profile-derived order file.** It proves Apple `ld` can honor a
tight profile-derived layout for this 82 MB Mach-O module, but code placement
alone does not remove the measured compute or off-core tail. Do not promote
the candidate app or add an order-file product input.

The exact interval executes 51,380,895 native dispatches, about 116,775 per
frame. The next bounded experiment must therefore measure and eliminate a
specific frequent dispatcher edge while preserving replacement, host-call,
physical-alias, self-modifying-code, exception, and interpreter-fallback
semantics. It must begin with a focused semantic regression and must not retry
global layout, whole-module IR PGO, isolated low-frequency leaves, timer,
scheduler, Metal, or broad helper-inlining variants.

Final Destination and G6 remain blocked by G5.

## Evidence

- `docs/evidence/g5-order-file-rejection/ordered-pgo-fountain.phase.csv` —
  exact 440-frame interval, SHA-256
  `4596244c55bf86ea1590be07d75eff939c6a3c8cf5b54c2aa3fe4954f2b82205`;
- `docs/evidence/g5-order-file-rejection/fountain-combat.jpeg` — retained
  coherent live frame, SHA-256
  `5f07333d06f9ca5fcfe1e5449a2193f1e0c855ec96a67a2e6a062c60af1496b6`.
