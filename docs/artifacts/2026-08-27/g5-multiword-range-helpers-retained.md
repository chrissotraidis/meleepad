# G5 multiword range helpers retained

## Question

The promoted no-logger, line-symbolized Fountain sample placed 251 of 11,849
CPU-thread samples in generated `lmw`/`stmw` register-transfer work. Clang had
already unrolled the constant register loops, but every transferred word still
repeated RAM classification, mirror masking, bounds checks, and store-side
reservation/journal checks. Could long multiword transfers classify one safe
contiguous range without changing observable memory behavior?

## Regression-first semantics

A focused GXRuntime regression failed to compile before the helpers existed.
The retained test now covers:

- `lmw r0` with the effective address captured before r3 is overwritten;
- cached/uncached MEM1 mirror behavior;
- EXRAM loads;
- per-word MEM1 journal callbacks and offsets; and
- reservation invalidation across every cache line touched by a long store.

The helpers classify the complete transfer once. If it does not fit wholly in
one ordinary MEM1/EXRAM range, they fall back to the prior per-word operations,
preserving external/MMIO behavior and partial boundary completion. Long loads
of at least four registers and long stores of at least eight registers use the
helpers. Shorter forms retain the old generated code because preflight showed
their call/range overhead was neutral or slower.

The permanent patch stack is:

- `patches/dolrecomp/0003-multiword-range-helpers.patch`; and
- `patches/moderngekko-dolphin/0016-gxruntime-multiword-range-helpers.patch`.

## Host and structural preflight

Five-million-operation fixed-register runs with a real out-of-line helper
measured common `lmw r20/r24` cases about 2.1-2.6x faster and `stmw r20/r24`
about 1.8-2.0x faster. `stmw r28/r31` regressed and was therefore excluded.

An initial always-inline module was rejected before launch because it added
665,028 bytes of `__text`. The retained shared-helper module instead has
81,235,476 bytes of `__text`, 331,796 fewer than the promoted control's
81,567,272. Total file size fell from 82,656,328 to 82,326,152 bytes. The
export set is unchanged. Generated source contains 1,570 long-load calls and
430 long-store calls; 1,138 short stores remain on the old path.

## Exact emulated-frame verdict

Each accepted row is the final occurrence of emulated frames `48123..48562`
from the same repository-excluded Fountain savestate.

| Metric | Candidate A | Control | Candidate A2 |
|---|---:|---:|---:|
| Mean / FPS | 18.719603 ms / 53.420 | 18.848329 / 53.055 | 18.681924 / 53.528 |
| p95 | 20.385246 ms | 20.315629 ms | 20.598275 ms |
| p99 | 30.484164 ms | 21.470465 ms | 22.226727 ms |
| Worst | 53.516958 ms | 23.557833 ms | 25.470583 ms |
| CPU-thread mean | 18.241015 ms | 18.484106 ms | 18.269532 ms |
| CPU-thread p95 | 19.910806 ms | 19.903093 ms | 20.117132 ms |
| Frames <=16.7 ms | 5.909% | 0.909% | 3.864% |
| Guest cycles | 3,567,157,795 | 3,567,157,795 | 3,567,157,803 |
| Native dispatches | 59,374,684 | 59,374,684 | 59,374,688 |
| Static bursts | 905,080 | 905,178 | 905,029 |

The candidate reproduces a roughly 0.21-0.24 ms CPU-thread reduction. The
first candidate's p99/worst values contain two host stalls and are not claimed
as source behavior. Tail latency is otherwise tied/slightly worse, and the
gain remains far short of the strict 16.7 ms G5 gate.

## Official build, package, and visual proof

The canonical exact-ISO build produced source key `b2d4b69da942f7c2` and
unsigned module SHA-256
`2fa34d164bf1833df32a1215c558396475b2a9cb3ae41f143c3790a40dbb27d7`.
It is byte-identical to the disposable dylib used for A/B/A2. The signed
packaged module is
`44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`;
its 81,235,476-byte `__text` is identical to the unsigned module, SHA-256
`d1bd6f36ded2d8c9031fba3078cbf3cf6e64a75ea97dbb163c532b2fbeb265dd`.
The packaged runner remains
`9d0fdf87df13593aabdc58371b2c2791a7c8910c9451af0504d3a1dd283da3c5`.

Direct UI inspection after a matured no-logger load retained active
Pikachu/Fox Fountain combat at a 54.7 FPS title reading. Models, effects,
stage, and HUD were coherent; the prior character-stretching/morphing failure
was not visible. This is a bounded non-recurrence observation, not broad visual
closure or a 60 FPS pass.

## Verification and decision

- clean forward/reverse patch checks and exact reconstructed-source identity;
- dependency bootstrap recognizes the complete composed stack;
- GXRuntime passes its full standalone suite;
- DolRecomp passes 14/14;
- focused product CTest passes 4/4;
- the gcpipe Python regression suite passes 16/16;
- the repository safety check passes;
- the exact supported ISO generates 237 chunks and the official module;
- strict deep package signing passes;
- no game process or Simulator remains; and
- ROM-derived generated source and the RAM-bearing state remain excluded.

**Retain and promote the shared multiword helpers as a small measured G5
improvement. G5 remains open and G6 remains blocked.** The next experiment
must start from a fresh no-logger native sample of this promoted module and
select a new coherent dynamic cost. Do not retry inline multiword helpers,
short-store helpers, diagnostic gates, or already-rejected global shortcuts.

## Evidence

Raw A/B/A2 phase CSVs and runner logs plus the visual combat frame are under
`docs/evidence/g5-multiword-range-helpers/`. The local benchmark executable,
generated chunks, savestate, and disc image are excluded.
