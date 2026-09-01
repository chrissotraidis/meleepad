# G8 lockstep repeat-set screen

Date: 2026-09-01
Goal: G8 row 7
Verdict: **nine interval-boundary reports cleared; row 7 remains a hard fail**

## Question

PERF-259 proved that generated chunks can revisit a guest endpoint before the
native interval has consumed its charged cycles. Replaying one entry per exact
route then cleared `0x80358AE8 -> 0x80358AE0` and
`0x80358AE0 -> 0x80358C00` as the same class of verifier artifact. The next
step needed to screen a coherent family without spending one full route per PC.

## Diagnostic extension

Patch `0034-lockstep-repeat-pc-set.patch` makes the existing
`STATICRECOMP_LOCKSTEP_REPEAT` diagnostic accept a comma-separated PC set.
Every named entry is checked on each occurrence and its shadow replay continues
until it reaches the native endpoint after covering the native charged
interval. A single address remains compatible. Lockstep and the repeat set are
both absent from product defaults, so this adds no product-path work.

The focused regression failed before the source change and passes afterward.
Canonical reverse-apply, bootstrap reproduction, incremental Simulator core
build, Release link, install, and the exact P1 Samus versus level-1 CPU Kirby,
Stock/04/05:00 Fountain route pass.

## Bounded result

The repeat set contained these nine entries:

- `0x80358ABC`, `0x80358AE8`, `0x80358AE0`, `0x80358C00`;
- `0x8035AA64`, `0x8035AB70`, `0x8035AAB8`;
- `0x8035B9DC`, `0x8035BA28`.

All nine disappear from the bounded report stream. The first surviving report
is now:

`0x803210A4 -> 0x80321178`

It differs in `r0`, `r3`, `r4`, `r8`, `r9`, and `ctr`, with no journaled-memory
or MMIO difference. It remains unclassified: the next screen must trace its
first endpoint visit and native charge before deciding whether it is another
interval boundary or a generated semantic defect.

The bounded run prints 12 reports. That total is not compared with earlier
totals because repeat selection changes which recurring entries are checked.
The diagnostic FPS and underruns are observer effects and cannot qualify the
product. The ordinary visible 21.9 FPS floor, animated-menu failures, visible
geometry corruption, and physical-iPad prohibition remain controlling.

## Evidence identities

- canonical patch: SHA-256
  `bdaf778d17dc0dd397ac58d31b248d0ed37c615c3c0890f1b9cd7701cf7659c1`
- rebuilt Simulator core archive: SHA-256
  `53eb7f73400da24bfaa102013c185c616115d3468d482146f3c93ff173cbf855`
- linked Release Simulator executable: SHA-256
  `d881d1c4d4db653726d0149ebdd2b2e2c69a964a08acf5eb43645dd4a27fc677`
- retained private console: SHA-256
  `0844a142b6391fbb751ee72796ee4c8d298c8a641665e58dae3e4e71771eaac5`
- retained private route log: SHA-256
  `3c694de6f039638432d89ba13a7b69bc5785013ac2311956140ed1d851c783f2`

The private traces, ROM, generated module/source, app, and build products remain
outside Git. The app is stopped and all diagnostic Simulator variables are
unset.

## Next falsifiable step

Trace only `0x803210A4 -> 0x80321178`. If full-interval replay clears it, add
only that proven repeated boundary to the bounded set. If identical entry state
and memory produce a specific native/interpreter operation mismatch at the same
charged endpoint, correct that semantic operation and rerun the bounded route.
Do not return to throughput optimization until the earliest transition screen
is trustworthy.
