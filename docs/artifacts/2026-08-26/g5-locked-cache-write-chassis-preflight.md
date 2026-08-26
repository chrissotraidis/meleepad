# G5 locked-cache write-chassis host preflight

Date: 2026-08-26

## Question

The rejected direct locked-cache path proved that Nintendo THP's one-byte
output writes pay material generic-MMU cost, but it also regressed matched
ordinary combat. Before considering any narrower mechanism, which parts of
the canonical locked-cache byte-write chassis actually account for the host
cost, and does preserving the omitted stable-MSR propagation leave meaningful
headroom?

## Method

A temporary Release-mode arm64 executable linked Dolphin's real `core`,
`System`, `MMU`, `MemoryManager`, and static-recomp lockstep globals. It
initialized the actual L1 buffer, disabled data translation, verified that the
locked-cache journal callback was null, and wrote a permuted 16 KiB working set.

Each path ran 2,000,000 one-byte writes for 11 rounds; the process reported the
median nanoseconds/write. Five fresh processes were run. Every path used the
same no-inline function boundary and observable post-loop checksum.

The measured paths were:

- `canonical`: `MMU::Write<u8>` including `Memcheck` and
  `WriteToHardware`;
- `hardware`: `WriteToHardware<Write>` only;
- `journal_direct`: the real null journal-callback branch plus direct byte
  store;
- `propagated_direct`: the stable `ppc.msr == guest_msr` propagation check,
  journal branch, and direct byte store;
- `direct`: direct byte store only.

The benchmark did not include `TranslateRelAddress` or the outer
`HookExternalWrite` call. Those are common to the canonical and rejected
direct paths, so this preflight isolates the inner write chassis rather than
claiming end-to-end game cost.

## Results

All values are median ns/write from the process's 11 rounds:

| Process | Canonical | Hardware | Journal + direct | MSR + journal + direct | Direct |
|---:|---:|---:|---:|---:|---:|
| 1 | 6.734 | 5.392 | 1.325 | 2.259 | 1.004 |
| 2 | 6.775 | 5.472 | 1.360 | 2.290 | 1.018 |
| 3 | 6.758 | 5.440 | 1.356 | 2.287 | 1.018 |
| 4 | 6.808 | 5.479 | 1.357 | 2.296 | 1.020 |
| 5 | 6.765 | 5.446 | 1.356 | 2.289 | 1.017 |
| **Median process** | **6.765** | **5.446** | **1.356** | **2.289** | **1.018** |

The median split is:

- `Memcheck`/outer `MMU::Write`: about 1.319 ns;
- generic `WriteToHardware` work beyond the null journal/direct store:
  about 4.090 ns;
- null journal branch beyond the store: about 0.338 ns;
- stable MSR propagation beyond journal/direct: about 0.933 ns.

A direct store that preserves the stable MSR and journal checks is still
about 4.476 ns/write, or 66.2%, cheaper than the canonical inner path. The
earlier THP runtime gain is therefore not explained solely by omitting MSR
propagation, and `Memcheck` alone is not the dominant cost.

## Decision

**PREFLIGHT PASSED AS ATTRIBUTION ONLY; NO PRODUCT CHANGE; G5 OPEN; G6
BLOCKED.** The generic hardware dispatcher has real per-byte cost, but two
independent global locked-cache integrations have already regressed gameplay:
the earlier generated pointer path and the fresh direct host path. This
microbenchmark does not override those runtime rejections.

Do not retry a global direct store, pointer callback, guest-PC condition, or
`Memcheck`-only shortcut. The next single experiment is offline analysis of the
exact generated THP chunks `0x8032D940` and `0x80331940`: identify and quantify
contiguous byte/paired-store runs that could form a guest-visible bulk or
routine-boundary operation. A new game build is justified only after an exact
semantic regression proves the bulk operation preserves byte order, overlap,
exceptions, MSR state, cycle accounting, and lockstep journaling.

The temporary benchmark target, source, and public MMU wrapper were removed.
The active source runner rebuilt to canonical SHA-256
`352ecd3cc69e645a1f58ea6f9306e535e02fe86ec098184ec00cb42b42c0e895`.
The packaged runner/module remain
`9bff54e4fd747aa4088beae1e847149a06fc7046bd4141e9d684aed58c1f355b` /
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.
