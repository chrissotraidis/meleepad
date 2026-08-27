# G5 line-symbolized Fountain attribution

Date: 2026-08-26

## Question

The retained paired-store build remains near 60 FPS on Fountain but misses the
strict 16.7 ms p95 gate. Which named guest routine owns the non-idle samples in
the broad generated chunk at `0x8033D940`?

## Diagnostic equivalence

All 237 generated chunks were rebuilt with line tables only and relinked with
an LTO object map. The diagnostic module and the retained source module have
the same 81,633,512-byte `__text` section and the same `__text` SHA-256,
`6a95b66223c2dd8b5c50f91023d351664e2469e7047344eb70270c7b57f002c7`.
The diagnostic UUID and dSYM UUID both equal
`EC49D243-F703-3B9C-A1B4-4167CD08C635`. This run was attribution-only; its
timing is not used as G5 acceptance evidence.

Computer Use verified Bowser versus level-1 CPU Ness on literal Fountain of
Dreams. The native 20-second sample contains 8,892 chassis CPU-thread samples.
The known scheduler/idle loop at guest `0x80349494` accounts for 1,181 and is
excluded from optimization decisions.

## Named hot routine

Six source-line PCs in generated chunk `chunk_0207_text1_8033D940.c` account
for 283 samples, or 3.18% of the chassis total:

| Guest PC | Generated line | Samples |
|---|---:|---:|
| `0x8033FAF4` | 20897 | 59 |
| `0x8033FAF8` | 20907 | 50 |
| `0x8033FAF0` | 20887 | 48 |
| `0x8033FB00` | 20927 | 48 |
| `0x8033FAFC` | 20917 | 44 |
| `0x8033FB04` | 20937 | 34 |

The coarse symbol range labels these addresses as part of
`GXSetIndTexCoordScale`, but the exact instruction sequence and the reference
SDK source identify the routine as `WriteMTXPS4x3` in
`ref/melee/extern/dolphin/src/dolphin/gx/GXTransform.c`: six GQR0 paired loads
from a 48-byte 4x3 matrix followed by six GQR0 paired stores to the GX FIFO.
Nearby samples at `0x8033FB24`, `0x8033FB2C`, and `0x8033FB34` belong to the
adjacent matrix writer.

## Decision

**ATTRIBUTION RETAINED; NO PRODUCT CHANGE; G5 OPEN; G6 BLOCKED.** The broad
chunk is now reduced to a concrete FIFO matrix-upload routine. This does not
prove that a specialized PSQ helper is faster, and the following live test
showed that such a split can regress code layout and dispatch cost. Future work
must preflight a routine-level FIFO batch with exact ordered-write semantics;
do not infer helper cost from sample count alone.

## Retained evidence

- `docs/evidence/g5-linesym-attribution/fountain-highlight.jpeg` —
  `e3e8311de1726bf7780c987981c0b3966d862bfa7a5eb8638b2e66bf3a38ab95`
- `docs/evidence/g5-linesym-attribution/bowser-ness-fountain-combat.jpeg` —
  `d71aab1e1d9af748bc0a240e42f52191d3b1998a5412bfa6138c996658e03c9f`
- `docs/evidence/g5-linesym-attribution/bowser-ness-fountain.sample.txt` —
  `a088ce349c0eb4b66f872c8cab420dd5d587661469a0de43053ca759fe2c360a`
