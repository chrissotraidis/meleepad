# G5 locked-cache external-write fast path rejection

Date: 2026-08-26

## Question

The visually verified Mario/Bowser How-to sequence is Nintendo THP video,
not ordinary rendered combat. Native sampling placed most CPU time in
`THPVideoDecode` and its MCU-row decompressors, with byte-sized external
writes prominent in the stacks. Are those writes concentrated in a stable
guest range, and can bypassing the generic MMU write path materially improve
THP without regressing normal gameplay?

## Default-off write histogram

A temporary one-in-64 sampler was added only to `HookExternalWrite`. Its
observer cost was too high for a visual or performance claim: the trace grew
very quickly and the run did not reach the movie. It is retained only as an
address/mechanism diagnostic.

- 8,389,081 sampled external writes;
- 8,354,567 writes, or 99.588560%, targeted locked cache
  `0xE0000000-0xE0003FFF`;
- 8,365,843 writes were one byte;
- page shares were 26.6375% at `0xE0002000`, 26.6011% at `0xE0000000`,
  26.4545% at `0xE0001000`, and 19.8955% at `0xE0003000`;
- the gather page `0xCC008000` accounted for only 0.3761%;
- the leading guest PCs all mapped to the already attributed THP range.

The raw diagnostic trace had SHA-256
`c067466de2494321acedc453275adb135139bca2a75cd760f4d2f7cac970ba0c`.
It was removed to Trash after extracting this distribution.

## Candidate and semantic screen

The temporary candidate recognized only an in-bounds store to Dolphin's exact
locked-cache window after relative-address translation. It preserved the
existing lockstep locked-cache journal, wrote the guest big-endian bytes to
`Memory::GetL1Cache() + offset`, and returned. Gather-pipe and all other
addresses retained the canonical path.

The bounded lockstep screen passed exactly:

- 1,401 checks;
- 88 canonical reports;
- seven fallback skips;
- three zero skips;
- zero undercharges and zero maximum cycle deficit.

The lockstep log SHA-256 was
`05bee4a0e754b9f50eac2db4799cbee8c50b575635b5c42d0303dacb6670ced8`.

## THP result

Computer Use visibly confirmed the same Mario/Bowser How-to movie. Compared
with the canonical 301-frame interval, the candidate removed several
milliseconds of CPU work:

| Metric | Canonical | Candidate |
|---|---:|---:|
| Mean / FPS | 21.251930 ms / 47.055 | 16.564629 ms / 60.370 |
| p95 | 23.949708 ms | 17.965250 ms |
| CPU-thread mean | 20.492810 ms | 13.597789 ms |
| Native dispatches/frame | 41,371.507 | 39,039.960 |

This is strong mechanistic evidence that THP's per-byte locked-cache writes
pay material generic-MMU overhead. It still does not pass strict G5 because
the candidate's 17.965 ms p95 exceeds 16.7 ms.

## Matched ordinary-combat replay

The earlier mixed candidate log could not reproduce its recorded range, so it
was excluded. A fresh candidate run used a new phase file and the deterministic
MemoryWatcher cold route. Computer Use then verified, in order:

1. blank VS character select;
2. P1 Pikachu and level-1 CPU Pikachu;
3. literal Fountain of Dreams on Stage Select;
4. coherent live Pikachu mirror combat.

The canonical and candidate brackets each contain the final 1,877 rows of the
same twelve-cycle combat input sequence. Both averaged about 8.107 million
guest cycles/frame and recorded zero static fallback steps.

| Metric | Canonical control | Locked-cache candidate |
|---|---:|---:|
| Frame range | 33,072-34,948 | 24,489-26,365 |
| Mean / FPS | 16.801288 ms / 59.519246 | 17.932665 ms / 55.764160 |
| p50 | 16.660042 ms | 17.812959 ms |
| p95 | 18.391276 ms | 20.200351 ms |
| p99 / worst | 24.523933 / 35.220958 ms | 22.839520 / 131.809458 ms |
| Frames <=16.7 ms | 54.981% | 19.446% |
| CPU-thread mean / p95 | 16.177287 / 18.058214 ms | 17.609451 / 19.834046 ms |
| Native dispatches/frame | 128,190.872 | 125,888.196 |
| Guest cycles/frame | 8,107,150.897 | 8,107,177.416 |

The candidate regressed mean by 1.131377 ms, p95 by 1.809075 ms, and average
rate by 3.755086 FPS despite slightly fewer native dispatches. The live
candidate capture read 55.1 FPS, consistent with the phase bracket rather
than with a transient earlier title reading.

## Decision

**CANDIDATE REJECTED AND REMOVED; THP ATTRIBUTION RETAINED; G5 OPEN; G6
BLOCKED.** A product optimization cannot trade a large prerecorded-video gain
for a repeatable ordinary-combat regression. The broad locked-cache shortcut
is removed and must not be retried or narrowed by an ad-hoc guest-PC check.

Canonical source `HookExternalWrite` is restored. The active source-built
runner SHA-256 is
`352ecd3cc69e645a1f58ea6f9306e535e02fe86ec098184ec00cb42b42c0e895`.
The untouched packaged runner/module hashes remain
`9bff54e4fd747aa4088beae1e847149a06fc7046bd4141e9d684aed58c1f355b` /
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.

The next experiment must be THP-scoped and semantic, starting with a focused
host preflight that separates the cost of one-byte locked-cache address
translation/journaling from the actual store. Only a guest-visible bulk or
routine-boundary mechanism with an exact regression may proceed to another
game build. Do not add another global memory fast path, guest-PC special case,
or per-write observer.

## Retained evidence

- `docs/evidence/g5-locked-cache-fast-path/how-to-60.6fps.jpeg` — SHA-256
  `27df882f51f7f83006873a1d182062023f28772bff52c483f816efec8667542b`
- `docs/evidence/g5-locked-cache-fast-path/control-pikachu-mirror-fountain.jpeg`
  — SHA-256
  `e012d6767eef595ff0d188729a296f602af36559d880a3eb0b9ea0e32d76d6c9`
- `docs/evidence/g5-locked-cache-fast-path/candidate-pikachu-mirror-fountain.jpeg`
  — SHA-256
  `c785274ca739c7681fb56b06615216493a5072b126a3e7de6a9593ef5986c341`
- `docs/evidence/g5-locked-cache-fast-path/control-pikachu-mirror-fountain.phase.csv`
  — SHA-256
  `88c838e379075054154831237376570fc84d977452860052634cce91d21acbfd`
- `docs/evidence/g5-locked-cache-fast-path/candidate-pikachu-mirror-fountain.phase.csv`
  — SHA-256
  `a389b447364fd943c2080095f2ad72eb96c195d960617916cfc0a513d20ff1e3`
