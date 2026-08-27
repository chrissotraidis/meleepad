# G5 paired-single store transactions retained

Date: 2026-08-26

## Question

The visually verified `How to Play` movie spends most CPU time in Nintendo's
THP decoder and writes almost all decoded output to the 16 KiB locked-cache
window one byte at a time. Can GXRuntime remove redundant per-lane memory
transactions by matching Dolphin's paired-single store semantics, without the
global locked-cache shortcut that previously regressed ordinary combat?

## Reference and source attribution

Dolphin's interpreter does not issue two independent memory operations for a
non-`W` paired store. Its `WritePair` specializations perform one wide write:

- two `u8`/`s8` lanes use one `MMU::Write<u16>`;
- two `u16`/`s16` lanes use one `MMU::Write<u32>`;
- two float lanes use one `MMU::Write<u64>`.

The arm64 JIT describes the same operation with `FLAG_PAIR`. GXRuntime instead
called `psq_store_value` twice. Offline inspection of the two dominant THP
chunks found 384 paired-store sites: 212 in `0x8032D940` and 172 in
`0x80331940`. Of those, 192 use GQR register 6. THP programs GQR6 as
`0x3D043D04`, whose store type is unsigned 8-bit.

## Change and semantic screen

`ppc_psq_store` now retains the existing single-lane path when `W` is set and
uses one big-endian wide memory transaction for paired float, U8, U16, S8,
and S16 stores. This is guest-semantic and type-based; it contains no game ID,
guest PC, or locked-cache address special case.

The regression records external-write address, value, size, and count. It
proves:

- float pair: one 64-bit write with exact lane order;
- U8 and S8 pairs: one 16-bit write;
- U16 and S16 pairs: one 32-bit write;
- `W=true` U8: one unchanged 8-bit write;
- the existing RAM quantization and all GXRuntime tests remain green.

`gxruntime_tests`, all 16 `gcpipe.py` tests, dependency bootstrap, repository
audit, patch reverse-check, clean apply, and repeat reverse-check passed.

## Invalid cache-hit run excluded

The first package silently reused the old `06852d9fd6223c6a` module. The
source-built runner remained byte-identical and the packaged module hash was
the canonical value, proving the candidate code was absent. Every metric from
that run is excluded from candidate evidence. Its temporary CSVs were moved
recoverably to
`~/.Trash/ssbmpad-invalid-paired-store-canonical-run-20260826/` and nothing
from it is committed as candidate evidence.

This exposed a real reproducibility defect: `moderngekko-port` keyed modules
by DOL, toolchain, ABI, generator, and patch settings, but not by the GXRuntime
or module-template sources compiled into the dylib. The tool now hashes the
full pinned `GXRuntime/include`, `GXRuntime/src/core`, and `module-template`
trees into the cache identity and manifest.

Behavioral proof:

- the corrected tool selected new key `1e1debc9fb83a31a` rather than reporting
  the stale hit;
- the new manifest contains `module_sources=7dcfd35e31be989b`;
- the first invocation rebuilt 237 generated chunks and the runtime;
- the identical second invocation reported a cache hit on the new key.

## Genuine candidate artifacts

Before runtime testing, the manually relinked candidate was proven distinct
from the old module:

- old unsigned module: `87153f878bef673f9f34444133b701edf974bd092484b636a3dcee592ebfbb02`;
- genuine candidate unsigned module:
  `7581d513ed5ac600c721da653eed7c7c0f3ef710daa614af09f660b8c2097268`;
- old/new `_ppc_psq_store` text addresses: `0x13f4` / `0x1688`;
- old/new sizes: 82,722,408 / 82,722,712 bytes.

The validated signed candidate module had SHA-256
`c4fe9f235be5fdd7ed3099c2f50b410bf0d3549473e5516328eca5186152440f`.
After the cache-key correction, the reproducible active unsigned module is
`a85cf8c5f72cad0abc9a892684d2468eef09622ff31c46812916bfaf268beaed`.
The promoted signed product runner/module hashes are
`48a0943191be8905fdce9f05e87b38d5c4dc2e335a853563a9d6e3937b635ff5` /
`2fe01870bfa0fbedc51aa20105ba0738c3b367e98c9566629001a8236e2fa1b3`.
The module targets macOS 14 and the bundle passes strict deep codesign
verification.

## Visually gated Fountain result

Computer Use verified blank CSS, explicit Fountain of Dreams stage selection,
and coherent live Pikachu-versus-level-1-CPU-Mario combat. The final 1,877
rows of the twelve-cycle input sequence are immutable:

| Metric | Paired-store candidate |
|---|---:|
| Frames | 12,864-14,740 |
| Mean / FPS | 16.709787 ms / 59.845168 |
| p50 / p95 | 16.647583 / 18.216709 ms |
| p99 / worst | 21.637188 / 32.580667 ms |
| Frames <=16.7 ms | 57.006% |
| CPU-thread mean / p95 | 16.220105 / 17.831292 ms |
| Guest cycles/frame | 8,107,181.800 |
| Native dispatches/frame | 128,335.436 |
| Static fallback steps | 0 |

The nearest retained canonical control used a different CPU roster, so this is
not promoted as a matched speedup. It does prove the semantic candidate did
not reproduce the prior global-fast-path collapse: coherent combat remained
near 60 FPS with flat guest cycles and zero fallbacks.

## Visually gated How-to result

Computer Use then verified the genuine Mario/Bowser instructional movie in
the distinct candidate. The exact 301-frame bracket is directly comparable to
the retained canonical 301-frame THP control:

| Metric | Canonical | Paired-store candidate |
|---|---:|---:|
| Mean / FPS | 21.251930 ms / 47.055 | 16.677963 ms / 59.959 |
| p50 | not retained | 16.590667 ms |
| p95 | 23.949708 ms | 17.875625 ms |
| p99 / worst | not retained | 17.973791 / 18.709875 ms |
| CPU-thread mean | 20.492810 ms | 11.094652 ms |
| CPU-thread p95 | not retained | 16.270834 ms |
| Native dispatches/frame | 41,371.507 | 37,176.359 |
| Static fallback steps | 0 | 0 |

The semantic pair operation removes 4.574 ms mean frame time and 9.398 ms
mean CPU-thread work from this THP workload. The promoted signed product also
visibly booted the opening THP movie and measured 16.672 ms across its latest
120 frames, confirming the reproducible cache-built module carries the fix.

## Decision

**PAIRED-STORE SEMANTIC FIX RETAINED; CACHE IDENTITY FIX RETAINED; G5 OPEN;
G6 BLOCKED.** The candidate is a large, mechanistically predicted THP gain and
does not use the rejected global memory fast path. It is not a G5 pass:
How-to p95 is 17.876 ms, Fountain p95 is 18.217 ms, and live-rendered
four-player scenes remain materially below 60 FPS. Final Destination is not
rerun while the lower Fountain/How-to tail still fails.

Next: split the retained Fountain p95 rows from its <=16.7 ms body and take a
clean CPU sample over that exact tail. Optimize one newly attributed live-
rendered hotspot only. Do not revisit global locked-cache bypasses, guest-PC
special cases, broad FP inlining, or timer variants.

## Retained evidence

- `docs/evidence/g5-paired-store-transactions/pikachu-mario-fountain.jpeg`
  — `86c3abbd6f8b0b9e9cd180c83923e46fa55a0fb2adfbce01f09dd894c2fdfc00`
- `docs/evidence/g5-paired-store-transactions/pikachu-mario-fountain.phase.csv`
  — `2fffb727522b933fdb2a10689beca4b68d4d6cda578415f0603f12dd1f5c9c1c`
- `docs/evidence/g5-paired-store-transactions/mario-bowser-howto.jpeg`
  — `9def609d858ab60589df475e79e73ed12debbb254be87dc3d92a9c178cc873be`
- `docs/evidence/g5-paired-store-transactions/mario-bowser-howto.phase.csv`
  — `c49c25c42d85c58ed7ef2f209f837c3064cb4bb12cb450e3a2d8bd7f7dd3db1f`
- `docs/evidence/g5-paired-store-transactions/promoted-product-opening-thp.jpeg`
  — `553911ba4c5625ea319b0b2107e3e74d58267f51eef70669c53928c3ea1f3b25`
