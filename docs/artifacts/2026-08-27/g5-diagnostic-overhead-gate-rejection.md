# G5 diagnostic-overhead gate rejected

## Question

The fresh promoted exact-window sample placed 429 CPU-thread top samples in
`clock_gettime` and `__thread_selfusage` while frame-phase logging was enabled.
The normal runtime also executed lockstep, freeze-trace, and dispatch-sampling
checks in the common dispatch loop even when their outputs were not requested.
Was observer overhead the reason the promoted product remained near 52 FPS?

## Crash-report reconciliation

The supplied incident `9AE31C76-671C-42F8-89AF-D64EE5BA5059` is the already
recorded 03:05 crash from temporary `MeleePad-fp-inline.app`, process 24720. It
occurred when slot 1 was requested while Dolphin's emulation thread was still
starting. It is not a crash from the promoted scalar-FMA package. The retained
harness now waits for emulated frame 1,000 before `SIGUSR2`; every run below
loaded cleanly.

## Normal-path control

The signed promoted runner and module were launched with no
`MELEEPAD_FRAME_PHASE_LOG`, using a disposable copy of the same user tree and
the retained Fountain slot. Direct UI inspection observed a real four-player
Brinstar attract scene at 22.9 FPS, then the loaded Pikachu/CPU-Fox Fountain
scene at 55.0 FPS and 53.3 FPS after a ten-second native sample. A reversal
control observed 55.3 and 53.6 FPS. This proves the full phase logger costs
roughly 1-2 FPS in this window, but observer overhead does not explain the
remaining gap to 60.

The no-logger CPU sample contained 8,024 CPU-GPU-thread samples. Its largest
self costs were the known scheduler poll (945), generated chunks
`func_8035D940` (598), `func_8033D940` (394), and `func_80339940` (364), then
309 samples attributed to `StaticRecompCore::Run`. Runtime helper leaves
included exact scalar FMA (193), `ppc_fp_available` (119), `ppc_fmuls` (104),
and `psq_load_value` (102).

## Bounded candidate

A failing-before source contract required all default-off dispatch diagnostics
to sit behind one cached runtime gate. The candidate:

- made dispatch-site sampling opt-in through
  `STATICRECOMP_DISPATCH_SAMPLES=1` (frame logging still implied sampling);
- made the old hard-coded freeze trace opt-in through
  `STATICRECOMP_FREEZE_TRACE=1`;
- skipped `ShouldCheck` unless lockstep was enabled; and
- skipped the profile-trigger call when no trigger was armed.

The regression passed after the change and the incremental Release runner
linked. In a no-logger live run, `ShouldCheck` disappeared from the native
sample and `StaticRecompCore::Run` self samples fell from 309 to 274. The
candidate title read 57.2 FPS immediately after load and 54.4 FPS after the
sample, only 0.8-1.1 FPS above the two controls.

## Equal-emulated-frame decision

The causal comparison used the same exact `48123..48562` interval and the same
promoted module. The candidate changed only the runner.

| Metric | Diagnostic gate | Promoted control |
|---|---:|---:|
| Mean / FPS | 18.997244 ms / 52.639 | 18.926719 ms / 52.835 |
| p95 | 20.771917 ms | 20.781917 ms |
| p99 | 21.867875 ms | 22.132167 ms |
| Worst | 25.188708 ms | 25.837958 ms |
| CPU-thread mean | 18.587566 ms | 18.524784 ms |
| CPU-thread p95 | 20.241562 ms | 20.299840 ms |
| Frames <=16.7 ms | 0.682% | 0.682% |
| Guest cycles | 3,567,157,795 | 3,567,157,781 |
| Native dispatches | 59,374,684 | 59,374,687 |
| Static bursts | 905,079 | 905,019 |

Work differed by only 14 guest cycles and three native dispatches. The
candidate lost mean and CPU-thread mean while p95 was tied. The candidate,
its regression, and all dependency edits were removed; the signed packaged
product was never changed.

## Decision and next experiment

**Reject the diagnostic gate as a performance change. G5 remains open and G6
remains blocked.** Phase logging is measurably perturbing and should not be
used as a product-speed claim, but the no-logger product still misses 60 FPS.
The next diagnostic is line-symbol attribution of the promoted no-logger
`func_8035D940`/`func_8033D940` work to a coherent guest kernel. Do not retry
diagnostic gating, scheduler variants, broad FP shortcuts, or global PSQ load
changes without new evidence.

## Verification

- the candidate source and its failing-first regression were removed;
- the restored Release runner rebuilt successfully;
- focused frontend, GameCube, netplay-protocol, and memory-watcher tests pass
  4/4;
- `gcpipe` passes 16/16;
- repository safety checks pass;
- the promoted signed package and module were never overwritten; and
- no game process or Simulator remains.

## Evidence

The no-logger native samples, equal-window phase CSVs, and runner logs are in
`docs/evidence/g5-diagnostic-gate-rejection/`. ROM-derived source and the
RAM-bearing savestate remain excluded.
