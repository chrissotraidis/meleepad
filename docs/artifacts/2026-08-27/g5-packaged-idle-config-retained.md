# G5 packaged revision-idle configuration retained

## Question

Why did the same M1 and same promoted module execute 3.567 billion guest
cycles in the signed package but only 1.502 billion in a same-build local
runner over nominal emulated frames `48123..48562`?

## Root cause

Three independently harmless assumptions composed into a product defect:

1. The desktop runtime is normally built with `LINUX_LOCAL_DEV=ON`, so
   Dolphin resolves `Sys` relative to its local executable/bundle root.
2. The package copied `Sys` under `Contents/MacOS`, which matched neither that
   local-dev contract nor a normal signed app's `Contents/Resources` layout.
3. Executable-only `main.dol` boots do not supply Dolphin with a disc volume,
   so its normal revision-specific GameINI layer is replaced by `ID-main`.

The result was that `GALE01r0.ini` existed in the app but
`StaticRecompIdlePC=0x80349494` never reached `StaticRecompCore::Init`. Melee's
scheduler poll remained hot and the package burned about 4.69 million extra
guest cycles per field.

## Regression-first fix

`scripts/test-macos-package-layout.sh` failed against the old bundle because
`Contents/Resources/Sys/GameSettings/GALE01r0.ini` was absent. The retained
fix:

- adds an explicit `MODERNGEKKO_APP_BUNDLE` build mode, disabling
  `LINUX_LOCAL_DEV` only for the signed macOS app while preserving unbundled
  developer tools;
- packages Dolphin data under `Contents/Resources/Sys` and checks the exact
  GALE01r0 idle value before signing;
- retains the disc revision byte from validated `boot.bin`; and
- loads only the revision-specific static-recompiler idle setting into the
  current-run config layer before CPU initialization.

A temporary two-point trace proved `80349494` was both seeded by the runtime
and read by `StaticRecompCore::Init`; both trace statements were then removed.
The focused synthetic game-inspection test now also verifies revision `2` and
passes.

## Deterministic package result

The clean signed package, unchanged promoted module, Cubeb audio, and retained
Pikachu/CPU-Fox Fountain state were run twice. Both selected exactly 440 rows
and identical work:

- 1,501,629,399 guest cycles;
- 51,369,928 native dispatches;
- 905,572 static bursts; and
- 882 hook fallbacks.

| Metric | Package A | Package A2 |
| --- | ---: | ---: |
| Mean / FPS | 16.514379 ms / 60.553 | 16.574602 / 60.333 |
| p95 | 18.281042 ms | 18.259292 ms |
| p99 | 19.963333 ms | 19.745334 ms |
| Worst | 24.346250 ms | 25.314875 ms |
| CPU-thread mean | 15.999375 ms | 16.124960 ms |
| CPU-thread p95 | 17.590552 ms | 17.850883 ms |
| Frames <=16.7 ms | 65.682% | 57.500% |

The previous signed packaged control executed 3,567,157,782 cycles and
59,374,687 dispatches at 18.626525 ms mean. The retained product fix therefore
removes the workload contamination and improves mean by about 2.05-2.11 ms,
reproducing average 60 FPS on the M1. It does not meet the strict tail gate.

## Verification and decision

- `moderngekko.game_inspect`: 1/1 pass;
- both retained patches reverse-check against the live applied source;
- package layout regression: pass;
- `MODERNGEKKO_APP_BUNDLE=ON`, `LINUX_LOCAL_DEV=OFF` in the product cache;
- deep strict codesign: pass;
- packaged module SHA-256 remains
  `44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`;
- clean runner SHA-256 is
  `5e7a9c271c89be3b83e23fedd3254ca25295c84e1f2d0385894574b71b7e5e54`;
- no game process or Simulator remains.

**Retain PERF-062. G5 remains open and G6 remains blocked.** The signed product
now averages above 60 FPS in this deterministic Fountain window, but p95 is
still about 18.26-18.28 ms. The next experiment must attribute that exact
idle-enabled package tail; it must not retry scheduler-loop, package-path,
timer, stale-PGO, or gather-width changes.

Evidence:

- `docs/evidence/g5-packaged-idle-config-retained/package-idle-a.phase.csv`
  (`c9a477989fbcfd30da6d43ffeaad50863a0c9cc6ba2cecccb0e9340f7bba20e1`);
- `docs/evidence/g5-packaged-idle-config-retained/package-idle-a2.phase.csv`
  (`1f9bdd85fb48fbf63f9fa4bf9572ced82dd90b6fd0e26c2f4f571df52cacf1f8`).
