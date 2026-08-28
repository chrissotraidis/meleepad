# G5 merged-state region preflight rejection

Date: 2026-08-28

## Question

PERF-078 showed that dispatch-only traces cannot materially close G5. Can a
genuinely single-entry generated region keep guest state live in host registers
and eliminate enough of the current switch/label state traffic to justify a
game/module build?

## Actual generated-code mechanism

The current arm64 object for
`chunk_0218_text1_80369940.c` confirms that arbitrary-entry labels force guest
state through `CPUState`. Around revision-0 guest PC `0x8036C91C`, the generated
code stores the PC and cycle count, calls `mem_read32`, stores `gpr[3]`, reloads
it for the following add, stores `gpr[0]`, and later reloads that value for
`mem_write32`. This is legal and simple, but it prevents the compiler from
keeping values live across every possible switch entry.

`scripts/g5_merged_state_preflight.c` retains a data-free model of the exact
`0x8036C91C..0x8036C934` slice. `canonical_region` preserves the current
multi-entry switch/label shape. `merged_region` accepts only the real entry and
keeps the loaded address/value and incremented value in locals while preserving
PC, LR, cycle, CR/XER, memory, and zero/nonzero exits.

## Semantic and arm64 evidence

The harness compares every byte of `CPUState` except the intentionally distinct
RAM pointer and compares all 4 KiB of RAM. It passes 4,096 randomized cases,
including both branch exits:

```text
MERGED,semantic-equivalence-4096-cases,PASS
```

AppleClang `-O2 -DNDEBUG -std=gnu11 -arch arm64` produced a native executable.
The source SHA-256 is
`eeb1179da0c43369753adf5c7fc76ca609ed75a06ee4966054cbf5a424487e33`;
the disposable binary SHA-256 is
`c6521ce9d96ef1f01020c4c7b8a94d263432ae4694856842724da9c7f3e9b717`.
Disassembly contains:

| Region | Instructions | Loads | Stores | Branches |
| --- | ---: | ---: | ---: | ---: |
| Canonical | 159 | 32 | 17 | 36 |
| Merged | 128 | 27 | 18 | 23 |

The extra counted store is a host allocation/path artifact; the merged region
still removes five loads, thirteen branches, and thirty-one total arm64
instructions.

## Timing and absolute materiality

Each timing run rotates canonical/merged order and reports the median of nine
measurements. Two five-million-iteration runs measured:

| Run | Canonical | Merged | Saved | Local improvement |
| --- | ---: | ---: | ---: | ---: |
| 1 | 5.760742 ns | 4.529583 ns | 1.231158 ns | 21.371525% |
| 2 | 5.803075 ns | 4.538683 ns | 1.264392 ns | 21.788304% |

A fresh repeat measured 5.709350 versus 4.493767 ns, saving 1.215583 ns /
21.291099%. The relative result is real; the absolute saving is too small.

The retained PERF-075 edge sample observes 88 entries to this region over the
440-frame window at 1/4,096 sampling, or about 819.2 executions/frame. Even the
best 1.264392 ns result therefore projects only 0.001036 ms/frame for this
exact slice. As a deliberately impossible upper bound, applying the saving to
all 51,380,895 native dispatches in 440 frames reaches only 0.147649 ms/frame,
or less than 1% of the 15.7 ms profile-free CPU mean.

## Decision

**Reject this slice and reject a generic one-small-region-per-dispatch rollout
before a game build.** The experiment proves that generator-level state
retention works, but percentage speedup inside a tiny region is a misleading
selection metric. No runtime, module, ABI, game package, or Simulator changed.

G5 remains open. The next candidate must be selected by inclusive host CPU cost
mapped back to guest PCs, not edge frequency alone. Form one larger
single-entry region around a genuinely expensive guest path, retain exact
exception/cycle/SMC exits, and require its absolute projection to clear the 5%
gate before paying for another full module and live A/B.
