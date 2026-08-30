# G5 hot/cold splitting rejection (PERF-204)

Date: 2026-08-30

Status: **IR SPLITTING ALREADY ACTIVE; LATE SPLITTER UNSUPPORTED ON MACH-O; NO BUILD; G5 OPEN**

## Question

Can LLVM intra-function splitting reduce instruction-delivery pressure inside
the very large generated functions containing PERF-196's warm-overrun PCs,
without repeating the rejected whole-symbol order file or changing guest
semantics?

## Late machine splitter

The installed AppleClang documents `-fsplit-machine-functions` only for x86
and AArch64 ELF. A direct target preflight confirms the product boundary:

```text
clang: error: unsupported option '-fsplit-machine-functions' for target
'arm64-apple-macosx14.0.0'
```

This late splitter cannot emit the arm64 Mach-O module used by macOS or the
eventual iPadOS product.

## Profile-guided IR hot/cold split

The earlier LLVM hot/cold splitter is format-independent. Two matching private
generated chunks were compiled at the product's `-O2`, strict floating-point,
arm64/macOS 14 settings with the retained Fountain frontend profile, first
normally and then with explicit `-mllvm -hot-cold-split`:

| Chunk / containing warm PCs | Control `__text` | Existing cold functions | Control/explicit SHA-256 |
|---|---:|---:|---:|
| `func_8035D940` / `0x80360638` | 294,988 bytes | 311 | `5c214e4d...ff83f9` |
| `func_80361940` / `0x80361AF8`, `0x803622DC` | 286,464 bytes | 315 | `0b0105cc...26f60` |

Both normal PGO objects already contain hundreds of `.cold.N` outlined
functions. Explicit enablement produces byte-for-byte identical objects:
identical text sizes, symbol layouts, and whole-object hashes, with no profile
or compiler warnings. The retained profile already activates this mechanism.

Private complete hashes:

- `func_8035D940` control and explicit:
  `5c214e4d4dc02cbce58d2fa7dd23d63ab0d7d3ebf6c8d28fba9dbd714eff83f9`;
- `func_80361940` control and explicit:
  `0b0105cceb9e87cf5d79fecb68e2e5f6608fd81a1c57747547b58a7b00f26f60`.

## Decision

**Reject another game build for hot/cold splitting.** Late machine splitting
is unavailable for the required Mach-O target, while profile-guided IR
splitting is already active and explicit enablement is an exact no-op on both
selected warm-overrun chunks. This is distinct from, and consistent with, the
prior rejection of whole-symbol ordering: the current PGO compiler already
performs internal cold outlining.

No product source, patch, ABI, module, app, ROM data, game process, or
Simulator changed. G5 remains open on the measured warm compute and host-wall
tails; G6 remains blocked.
