# G5 warm-profile refresh rejection (PERF-202)

Date: 2026-08-29

Status: **WARM OVERRUN PCS ARE HEAVILY AND REPEATABLY TRAINED; NO REBUILD; G5 OPEN**

## Question

Does the retained frontend-PGO profile underrepresent the five guest PCs
enriched in PERF-196's rare warm Fountain CPU overruns, such that a new
warm-specific training run could justify another module build?

## Active module and profile provenance

The current signed PGO module is unchanged:

- `build-macos/SsbmPad-PGO.app/Contents/MacOS/gGALE01_recomp.dylib`;
- SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.

Its private frontend profile has SHA-256
`3f9d2aa4dbd5aa34465c8b975e5c6c369518e0db23137b2e424295a0f572ac12`.
Despite its historical `current-idle-fountain.profdata` filename, PERF-068's
retained provenance proves that counters were reset only after the verified
Fountain state entered combat and dumped at natural combat completion. It is
already a full Fountain-combat profile, not an idle or title-only profile.

`llvm-profdata show` reports:

- 6,556 functions;
- 2,727,666 blocks; and
- 135,462,880,664 aggregate counts.

The independently retained local-training repeat has SHA-256
`9fe17c1b29dceb0a1b8c80dd61bc518fce1328fbb5816f15a0f6a715319cf91d`.
It has the same function/block totals and 135,462,879,791 aggregate counts, a
difference of only 873 across the entire profile.

## Exact-PC coverage reconstruction

Four private coverage-only objects were compiled from the matching generated
source chunks with Apple Clang `-fprofile-instr-generate -fcoverage-mapping
-O2`. `llvm-cov export` then reconstructed exact source-region counts from
each retained profile. The objects are newer than the profiles, so LLVM emits
a timestamp warning; the relevant function hashes and counter shapes match
both profiles exactly and coverage is populated at every selected label.

| PERF-196 guest PC | Containing function | Current profile count | Repeat profile count |
|---:|---:|---:|---:|
| `0x803408D4` | `func_8033D940` | 17,523,395 | 17,523,395 |
| `0x8035D548` | `func_80359940` | 2,523,933 | 2,523,933 |
| `0x80360638` | `func_8035D940` | 3,700,981 | 3,700,981 |
| `0x80361AF8` | `func_80361940` | 2,613,771 | 2,613,771 |
| `0x803622DC` | `func_80361940` | 8,006,326 | 8,006,326 |

The containing functions also have identical current/repeat entry counts:

| Function | Profile hash | Counters | Function count |
|---|---:|---:|---:|
| `func_8033D940` | `0xcdbef4a8ad35788d` | 10,579 | 97,838,998 |
| `func_80359940` | `0x531066d8a00752f8` | 11,173 | 61,303,620 |
| `func_8035D940` | `0x5310a66549a705f9` | 10,815 | 121,766,257 |
| `func_80361940` | `0x45a1d15d4f65d6c1` | 12,100 | 47,905,570 |

This is not absent, cold, or unstable training. Every enriched warm-overrun PC
already has millions of observations, and an independent full training repeat
assigns the exact same count to all five regions.

## Decision

**Reject a new warm-specific PGO collection and module build.** The candidate
fails the pre-build materiality gate: the existing profile already covers the
proposed scene boundary and heavily trains the exact PCs, while the independent
repeat produces identical regional weights. A third collection would repeat
the same input rather than expose a new optimization signal.

This does not claim that warm Fountain compute is solved. PERF-195 proves eight
real warm CPU overruns, and PERF-196 places their small excess inside the
already-closed HSD/GX family. PERF-202 only closes profile absence or stale
scene weighting as their explanation. Keep the known PGO module, retain no
product edit, and keep G5 open on the separate warm compute and host wall-time
tails. G6 remains blocked.

The profiles, coverage objects, generated source, ROM data, module inputs, and
coverage text remain private and uncommitted. No game or Simulator ran.
