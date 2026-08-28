# G5 matrix-copy family preflight

Date: 2026-08-28

Status: **EXACT COPY FAST PATH PASSES; TWO-ADDRESS CHUNK FAMILY REJECTED; G5 OPEN**

## Question

PERF-084 selected the actual call boundary at `0x803408A0`. Source inspection
shows this is a 48-byte paired-single matrix copy immediately before the
already-proven `0x803408D4` matrix concatenation kernel. Can one chunk-scoped
wrapper implement both operations without the global replacement probe and
project above the 5% retention gate?

## Exact copy semantics

`scripts/g5_psmtxcopy_preflight.c` loads the current canonical module and
compares guest `0x803408A0..0x803408D0` against an ordinary-RAM/GQR0 fast path.
The fast path preserves all six loaded FPR/PS1 pairs, float-subnormal store
behavior, six ordered wide writes, reservation invalidation, exact 13-cycle
charge, LR/PC, and every other CPU-state byte. It falls back to canonical
dispatch for FP-disabled, LSQE-disabled, nonzero-GQR, journaling, external, or
out-of-range memory.

All 20,000 differential cases pass. They include identical source/destination,
forward overlap, backward overlap, disjoint copy, matching and nonmatching
reservations, arbitrary float bit patterns, all initial downcount values from
0 through -255, and each fallback gate including an out-of-range destination.
The comparison covers every CPU-state byte except the intentionally distinct
RAM pointer and all 24 MiB of RAM.

Nine alternating one-million-call timing repeats produce these medians:

| Mode | Median |
| --- | ---: |
| canonical generated copy | 77.795167 ns/call |
| chunk-local fast path | 23.738208 ns/call |
| saving | 54.056958 ns/call |
| local improvement | 69.486268% |

Retained private artifact hashes:

- executable:
  `4e34216d15772a5e1ed03ab6b91baacc1800955266e3e9882d9c6a9f03b5780f`
- result:
  `9352dbffdcf91c4e5f76bb49605e1db4599421f62ef9500a294706d56f85e546`

## Exact coverage

The extended guest-PC mapper measures the copy and concatenation ranges
separately in both retained line-symbol Fountain profiles:

| Profile | Direct generated samples | Copy `A0..D0` | Concat `D4..9C` | Union |
| --- | ---: | ---: | ---: | ---: |
| promoted profile-free | 8,452 | 5 / 0.059158% | 307 / 3.632276% | 312 / 3.691434% |
| current PGO | 1,311 | 0 / 0.000000% | 67 / 5.110603% | 67 / 5.110603% |

The parent range at `0x80377B6C..0x80377CE4` owns 2.662092% and 2.974828%,
but those samples are parent arithmetic; optimizing a rare callee cannot claim
them. The two copy call sites are mutually exclusive and the copy itself is
absent or nearly absent in the sampled windows.

Even granting zero wrapper cost and combining the copy's 69.49% local gain
with the prior concatenation kernel's approximately 69% local gain projects
only about 2.55% for the larger profile and 3.53% for current PGO. Both are
below 5% before compare branches, code footprint, sample error, and product
integration.

## Decision

Retain the exact copy harness, but reject the two-address chunk-local matrix
family before modifying generated dispatch or building a module. The local
speedup is real and the coverage is insufficient. Do not add PSMTXCopy to the
product by itself and do not add its parent samples to the projection.

The broader state-retention objective remains open. Its next representation
must aggregate several high-cost callful families and synchronize live guest
state across selected calls; another isolated SDK leaf or address wrapper
cannot meet G5.
