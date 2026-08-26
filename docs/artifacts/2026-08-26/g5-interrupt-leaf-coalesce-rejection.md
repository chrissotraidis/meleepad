# G5 interrupt-leaf coalescing rejection

Date: 2026-08-26

## Question

The CSS-only post-throttle sample ranked the tiny GALE01
`OSDisableInterrupts`/`OSRestoreInterrupts` leaves at `0x80345738` and
`0x80345760` immediately behind the known scheduler poll. Can exact
module-boundary execution of those leaves remove enough native dispatch work
to improve the strict menu tail?

## Focused semantics

A standalone C regression was added before the helper and failed to compile
because the implementation did not exist. The completed regression covered:

- EE initially set and clear for the disable leaf;
- zero, positive, and signed compare behavior for the restore leaf;
- exact GPR3/GPR4/GPR5, MSR, CR0/SO, PC/LR, and 5/7/8-cycle effects;
- no mutation for any address other than the two exact revision-0 leaves.

The candidate then passed both the standalone test and the CMake/CTest target.
It was compiled only for `GAME_ID=GALE01`. After executing a leaf it continued
the caller in the same module entry only when guest downcount remained and no
exception was pending; event/interrupt boundaries returned to the normal
scheduler path.

## Native run

The candidate module linked with the same C backend, `-O3`, ThinLTO, Metal,
Cubeb, normal arm64 runner, and corrected scalar-single generated source as the
control. MemoryWatcher started before exactly one runner and self-verified the
genuine title lockout, main menu, and `GameState=0x02020100` CSS route. Computer
Use observed a coherent CSS window titled `59.9 FPS`; no Simulator ran.

The final 3,600 untouched CSS frames measured:

| Metric | Normal CSS control | Leaf coalescing |
|---|---:|---:|
| Mean | 16.683499 ms | 16.683329 ms |
| p95 | 16.896375 ms | 16.907625 ms |
| p99 | 17.084541 ms | 17.154916 ms |
| Worst | 17.467959 ms | 27.725250 ms |
| FPS from mean | 59.939 | 59.940 |
| Frames <=16.7 ms | 56.976% | 57.861% |
| CPU-thread mean | 8.463245 ms | 8.483023 ms |
| Native dispatches/frame | 67,051.812 | 67,000.656 |

The mechanism removed about 51 native dispatches per frame, consistent with
the two helper calls, but that is only 0.076% of CSS dispatches. CPU work did
not fall and p95 did not improve. The existing shutdown sampler still reports
the leaf entry PCs because it samples `m_guest.pc` before calling the module;
module-boundary interception cannot make those pre-dispatch samples disappear.
That previously proposed mechanic check is therefore corrected, not treated
as a failure of the compiled branch.

## Decision

**CANDIDATE REJECTED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.** The
temporary helper, regression, CMake define, and module wrapper were removed.
The signed package is restored to runner
`c26625db7fd1eb504f418ad8ab52a3accc61bb222fd08b369c7804a5465d5598`
and module
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.
No runner, controller, frontend, or Simulator remains.

Do not retry either leaf or another isolated low-frequency guest helper. The
next bounded preflight is the exact per-dispatch chassis overhead that applies
to all roughly 67,000 CSS dispatches/frame, beginning with the semantically
free empty-forced-fallback-range check. Measure it in a focused host benchmark
before another cold game build. Retain nothing unless the benchmark signal is
large enough to justify a matched CSS run.

## Retained artifact

- `g5-interrupt-leaf-coalesce-css-phase.csv` — SHA-256
  `7c0730af4f2a31c829774761805afab5bac1fa5bdef8e745be1c099608270823`
