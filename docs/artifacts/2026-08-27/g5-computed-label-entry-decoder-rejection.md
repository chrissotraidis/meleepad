# G5 computed-label entry decoder rejection

Date: 2026-08-27

## Question

Exact native samples inside late-Fountain generated chunks landed in their
initial `ctx->pc` entry decoders. Could preserving the existing 4,096-guest-
instruction chunks while emitting a direct computed-label table reduce entry
dispatch cost without the cross-chunk tax of smaller chunks?

## Regression-first candidate

Before the change, a generated-code probe failed because no
`goto *entry_labels[...]` decoder existed. The disposable Clang/GCC path then
emitted a bounds/alignment guard and a label-pointer lookup, retaining the
portable switch for other compilers. Generated-code compile/execution and
jumptable tests passed 3/3. The exact revision-0 DOL regenerated cleanly into
the same 237 chunks.

A standalone harness used the real hot `func_8033D940` chunk. A fixed entry
was 0.3-0.7 ns slower with the candidate after warmup. Random selection among
32 valid entries was mixed: the first pair slightly favored canonical, while
later pairs favored the candidate by roughly 0.0-0.6 ns. Misaligned and
out-of-range entries remained no-ops. The mixed result justified one isolated
full ThinLTO build, but not a live run.

## Linked result

The full candidate linked successfully with the same exports and a distinct
SHA-256, `a453771e7862e71d3c45bb13e1fbcdb90cd287eacd251c3f2dcced2811479884`.
ThinLTO retained the computed goto, but also exposed why it is not an
optimization over canonical Clang:

- canonical already lowers the dense switch to a constant-time 32-bit
  relative jump table (`ldrsw`, add, indirect branch);
- the candidate uses an 8-byte absolute label pointer per guest instruction
  (`ldr`, indirect branch);
- `__TEXT` fell 5,095,424 bytes, but `__DATA_CONST` grew 7,749,632 bytes;
- total Mach-O VM size grew 2,703,360 bytes and file size grew 2,689,552 bytes;
- hot `func_8033D940` shrank 19,868 bytes, but its stack frame doubled from
  `0x70` to `0xe0` and its label table alone occupies 32 KiB.

This changes where the canonical compiler-generated table lives and doubles
its element width; it does not remove a logarithmic decoder or establish a
repeatable hit-cost improvement.

## Decision

**REJECTED BEFORE LOCKSTEP OR LIVE RUN; G5 OPEN; G6 BLOCKED.** The generator
change was removed with the canonical dependency patch stack preserved.
Regenerated output no longer contains the computed-label pattern, and focused
tests pass 3/3. The active module pointer and packaged app were never changed;
no game process or Simulator was started. Do not retry pointer-width computed
labels for dense chunk entry. Continue from measured dynamic work rather than
static text shrinkage.

All candidate sources, generated chunks, binaries, and the linked module are
disposable `/private/tmp` artifacts and are not repository inputs.
