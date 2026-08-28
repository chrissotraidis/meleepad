# G5 LLVM 22 Apple ARM64 backend preflight

Date: 2026-08-28

## Question

PERF-036 classified DolRecomp's LLVM backend as an out-of-scope x86-only port.
Does the current backend actually contain target-dependent assumptions beyond
its explicit host/version gates?

## Disposable enablement

A private copy under `/private/tmp` changed only:

- the accepted LLVM range from 19/20 to 19 through 22;
- LLVM 22's typed `Triple` and renamed intrinsic-declaration APIs;
- the production-target gate to admit AArch64 macOS; and
- test object-magic checks to accept Mach-O as well as ELF.

The installed `/opt/homebrew/opt/llvm` is LLVM 22.1.8, targets AArch64, and has
host triple `arm64-apple-darwin25.4.0`.

## Evidence

LLVM successfully emitted Mach-O ARM64 objects. The focused test executable is
also native ARM64, and all three backend gates pass:

```text
llvm_backend  PASS
llvm_execute  PASS
llvm_pipeline PASS
```

`llvm_execute` covers generated integer/float/paired work, RAM, fallbacks,
SPR/segment/FPSCR state, exceptions, cache control, and other runtime
boundaries. This is semantic execution evidence, not just legal A64 encoding.

The existing backend already allocates used guest state, runs `mem2reg`, GVN,
DSE, SCCP, jump threading, LICM and vectorization, and materializes dirty state
at runtime/exception exits. That directly matches the mechanism isolated by
the complete-function preflight.

## Initial status

Apple ARM64 LLVM is now a credible bounded G5 candidate rather than a purely
theoretical port. Full private GALE01 object generation has started; module
link, ABI/SMC checks, lockstep, packaging, and live Fountain A/B remain
unproven. No canonical patch, module pointer, packaged app, game process, or
Simulator changed.

## Exact hot-slice footprint screen

The first full objects exposed a product-risk that semantic unit tests could
not: their early mean projected roughly 678 MB of native text, versus 81.2 MB
in the current C module. To distinguish an unrepresentative early projection
from the backend mechanism, a private mini-DOL retained the exact 4 KiB
`0x80323940..0x8032493F` slice containing the leading unclosed Fountain hot
region. Its SHA-256 is
`f82de9173e8d42fbd3b755124188e318ca1de9b2ebd676dd84555a51d01f4e3a`;
the derived DOL and objects remain outside Git.

Both backends decoded the same 1,024 known guest instructions. AppleClang
compiled the generated C with the product's strict FP flags. The resulting
native objects are:

| Backend | Text bytes | Host instructions | Loads | Stores | Branches |
| --- | ---: | ---: | ---: | ---: | ---: |
| Current C | 64,756 | 16,183 | 3,693 | 1,586 | 3,620 |
| LLVM SSA | 396,548 | 99,136 | 41,455 | 37,786 | 5,227 |

LLVM text and instruction count are both about 6.12 times the C result. The
cause is visible in emitted IR and arm64: each arbitrary-entry chunk marks a
guest state slot dirty if any block writes it, then duplicates broad
materialize/reload sequences at ordinary exits and rare memory/MMIO slow
paths. Register retention removes hot state traffic inside a path but creates
large cold boundary code.

Two small falsification attempts are already closed:

- one common side-exit block passed all three focused LLVM tests but grew the
  slice to 411,760 text bytes / 102,939 instructions because SSA predecessor
  values became a large PHI/move problem; and
- LLVM's stock per-module O2 and size-oriented Oz pipelines also passed but
  both grew the slice to the same 421,876 text bytes / 105,468 instructions.

Both disposable variants were removed. Full exact-DOL generation continues
with the original tested pipeline as a performance feasibility baseline, not
as an accepted product candidate. Even a fast live result will require a
separate reduction of duplicated cold runtime-boundary code before promotion,
especially for the eventual iPad memory/package boundary.

## Exact hot-slice execution rejection

The same C and LLVM objects were linked into one native arm64 harness after
renaming only the LLVM object's exported function symbol. The harness starts
both at guest PC `0x803248DC`, supplies identical CPU state and separate
byte-identical 5 MiB RAM, and executes through the exact `0x80324940` slice
boundary. It compares every CPU-state byte except the intentionally distinct
RAM pointer and all RAM bytes. Both paths end at the same PC and change the
same nine RAM bytes:

```text
SLICE,semantic-equivalence,PASS,pc=80324940,changed_bytes=9
```

Each timed iteration restores CPU state and only those nine changed RAM bytes,
then calls one backend. Nine samples per backend are rotated to remove order
bias. A first concurrent 10,000-iteration screen measured C at 173.554 ns and
LLVM at 844.008 ns. After pausing the full-game workers, two uncontended
100,000-iteration repeats measured:

| Repeat | C | LLVM | LLVM regression |
| --- | ---: | ---: | ---: |
| 1 | 100.103330 ns | 487.870830 ns | 387.367233% |
| 2 | 97.535830 ns | 480.811250 ns | 392.958588% |
| Retained harness | 95.992080 ns | 464.883750 ns | 384.293860% |

LLVM is therefore 4.84-4.93 times slower on the exact hot slice despite
producing identical state. This is consistent with its 6.12-times instruction
footprint and directly contradicts the required broad runtime gain.

The data-free retained harness is `scripts/g5_llvm_slice_preflight.c`, SHA-256
`fa38650355cdcd37c21f1d7dd611d9d0874e62d1fc38e5b4cacfea59a35ca00c`.
The final private C object, renamed LLVM object, arm64 executable, and output
hash to `b81b6689...14e28`, `0e471f3d...8f074`, `26ef0936...59a5`, and
`683ea17c...f3a3`, respectively.

## Decision

**PERF-082 REJECTED before module link; G5 remains open.** The full exact-DOL
run was cleanly interrupted at 130/947 objects after the exact slice falsified
both size and speed. Its private partial output remains available for analysis,
but no product patch, module, pointer, package, game process, or Simulator was
changed. Do not retry stock O2/Oz, one common exit, larger LLVM chunks, or a
full LLVM module without a new design that first removes duplicated boundary
materialization and beats the C object on this retained slice.
