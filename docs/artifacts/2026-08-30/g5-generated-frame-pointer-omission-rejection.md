# G5 generated frame-pointer omission rejection (PERF-213)

Date: 2026-08-30

Status: **OBJECT SCREEN BELOW MATERIALITY BOUND; NO MODULE OR GAME BUILD; G5 OPEN**

## Question

PERF-212 proved that the module dispatcher gains only 0.190 ns/call after
removing most of its ARM64 frame-management sequence. The current hot
generated chunk functions also establish x29 frame pointers. Can
`-fomit-frame-pointer` free a register or remove enough prologue/epilogue work
to justify a full frontend-PGO module build?

## Current product shape

The active packaged frontend-PGO module remains
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
Its four retained hot chunk functions all establish x29 after saving the same
ordinary callee-saved register set. For example, `func_8033D940` begins:

```text
sub sp, sp, #0xa0
stp d9, d8, [sp, #0x30]
stp x28, x27, [sp, #0x40]
stp x26, x25, [sp, #0x50]
stp x24, x23, [sp, #0x60]
stp x22, x21, [sp, #0x70]
stp x20, x19, [sp, #0x80]
stp x29, x30, [sp, #0x90]
add x29, sp, #0x90
```

This is not the already-rejected `-mcpu`/O3 flag matrix: frame-pointer
omission changes the function ABI implementation rather than instruction
scheduling or optimization level.

## Bounded object comparison

Generated chunk `chunk_0207_text1_8033D940.c` was compiled twice with the
same AppleClang 21 compiler, locally trained frontend profile, `-O2`, macOS 14
ARM64 target, hidden visibility, and strict `-ffp-contract=off
-fno-fast-math` semantics. The only difference was explicit
`-fno-omit-frame-pointer` versus `-fomit-frame-pointer`. ThinLTO was omitted
from this object-only screen so final ARM64 instructions could be inspected
without linking the 82 MB module.

Object identities:

- frame-pointer control:
  `d09b744a2b9a85a5d0684455b2b04d90b1d6967fd7579a660717c684b5cff3c1`;
- omit candidate:
  `dc55689b465b337a0b52ca3dea3c4e514da4fb0057b341a8b77e75888f1c692d`.

The control has 365,656 text bytes and 88,056 instructions. The candidate has
363,920 text bytes and 87,622 instructions: 1,736 bytes and 434 instructions
smaller across 446 generated `func_` symbols.

The candidate still saves/restores x29 together with LR; it removes the frame
establishment instruction but does not free the save slot:

```text
stp x29, x30, [sp, #0x70]
// no add x29, sp, #0x70
ldr w8, [x0, #0x280]
```

Whole-object mnemonic differences are:

| Mnemonic | Candidate minus control |
|---|---:|
| `add` | -424 |
| `mov` | -5 |
| `ldur` | -6 |
| `stur` | -10 |
| `stp` | +4 |
| `ldp` | +1 |
| `ldr` | +4 |
| `str` | +2 |

Thus nearly the entire result is one removed frame-establishment instruction
per generated function; secondary register allocation nets only ten further
instructions. One generated chunk function executes per native outer
dispatch, so the dynamic opportunity is approximately one instruction per
dispatch, not all 434 instructions per dispatch.

## Materiality bound and decision

PERF-212's same-machine two-module benchmark removed roughly five common-path
frame-management instructions and saved only 0.190267 ns per dispatch. This
candidate removes approximately one. Even assuming linear scaling, PERF-135's
116,775 dispatches/frame project to about 0.0044 ms/frame, approximately
0.036% of PERF-207's 12.273 ms mean combined-thread CPU time. It cannot
explain or correct the remaining 17-35 ms wall tails and is two orders of
magnitude below the 5% product-build threshold.

Reject `-fomit-frame-pointer` before a full ThinLTO module or game build. The
two disposable objects were deleted. No source, module, app, ROM, save,
runtime, or Simulator changed. Do not repeat this flag without a source-level
mechanism that changes register pressure or call structure by materially more
than one instruction per dispatch. G5 remains open; G6 remains blocked.
