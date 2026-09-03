# G5 current-source combat PGO oracle

Date: 2026-08-27

## Question

Would a fresh profile from the exact promoted scalar-FMA, multiword-helper,
idle-enabled source reproduce the old PGO signal, and would it explain whether
the remaining Fountain tail is an M1 hardware ceiling or avoidable generated
module cost?

## Profile provenance and build identity

The profile was generated from source key `b2d4b69da942f7c2`, the same
generated source used by the promoted module. The instrumented arm64/macOS 14
module exported the normal module entry plus the already-tested reset/dump
hooks. A revision-0 match predicate at `0x80477D68` reset counters only after
the retained Fountain state entered combat and dumped them when combat ended.

- raw profile SHA-256:
  `c02cd40e0aedbd6330cadf9968cee46faa3c0d2ae20039dbdde4f5f717945549`;
- merged profile SHA-256:
  `3f9d2aa4dbd5aa34465c8b975e5c6c369518e0db23137b2e424295a0f572ac12`;
- profile coverage: 6,556 functions, 2,727,666 blocks, and
  135,462,880,664 aggregate counts;
- source DOL is the locally validated GALE01 revision-0 image. The profile,
  savestate, image, and generated module remain local and are not committed.

Revision discipline matters for every address in this experiment. The local
image is retail revision 0 (`main.dol` SHA-1
`77bbb63d4abca829e946dada886adbaf5889dc9c`), while the checked-in
`ref/melee/config/GALE01` decomp map targets revision 2 (`main.dol` SHA-1
`08e0bf20134dfcb260699671004527b2d6bb1a45`). Raw revision-2 symbols must not
be applied to revision 0. For example, the revision-0 matrix routine used by
the current attribution is independently verified at `0x803408D4`, not copied
from the revision-2 map.

AppleClang 21 consumed that profile without missing-data or hash-mismatch
warnings. The resulting module is arm64, requires macOS 14, exports only
`_staticrecomp_get_module`, and passes strict ad-hoc signature verification.

- unsigned candidate SHA-256:
  `abb435806d2f123981686b097661f89fa6d41513709be4b61f8252b2785bd3ab`;
- signed candidate SHA-256:
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- promoted control SHA-256:
  `44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`.

## Exact Fountain A/B/A result

Candidate A, the current promoted control, and candidate A2 loaded the same
repository-excluded Pikachu/CPU-Fox Fountain state only after the emulated
frame counter exceeded 1,000. Each accepted row is the last occurrence of
emulated frames `48123..48562`. All three current runs exactly match:

- 1,501,757,755 guest cycles;
- 51,380,895 native dispatches;
- 905,756 static bursts; and
- 882 hook fallbacks.

The totals differ slightly from the older package pair because the current
isolated user/app bracket assigns the boundary presentation consistently. No
cross-bracket claim uses the older work totals.

| Metric | Candidate A | Current control | Candidate A2 |
| --- | ---: | ---: | ---: |
| Mean / FPS | 16.682964 ms / 59.941 | 16.572748 / 60.340 | 16.682442 / 59.943 |
| p95 | 17.608188 ms | 18.123332 | 17.775729 |
| p99 | 18.419277 ms | 19.756375 | 18.590647 |
| Worst | 19.823709 ms | 24.335334 | 21.317292 |
| CPU-thread mean | 11.888651 ms | 15.941134 | 11.606481 |
| CPU-thread p95 | 14.073879 ms | 17.520329 | 13.126768 |
| Frames <=16.7 ms | 52.045% | 63.636% | 55.682% |

The approximately 4.2 ms CPU-thread reduction is large and repeats. It is not
a whole-machine or guest-work artifact. Total mean remains locked near the
59.94 Hz field period because the faster module deliberately sleeps longer.
The candidate improves the control tail, but neither repeat satisfies the
strict 16.7 ms p95/p99/worst gate.

The host is an 8-core, 16 GB M1 MacBook Air. macOS reported no thermal or
performance warning throughout the build and runs. A persistent Logitech
updater used roughly 12-40% of one host core during parts of the bracket; it
was not stopped because it is unrelated user state. Interleaved A/B/A and
exact guest-work equality make the compute result causal despite that
background load. The evidence therefore does not prove that M1 speed is
irrelevant, but it rejects the M1 as the cause of the former sustained 12.5
FPS behavior and identifies avoidable code-generation cost.

## Pacing control

With the PGO module, precision-timer wake lateness was 0.442/0.503 ms mean and
0.936/1.070 ms p95. A disposable user directory set
`PrecisionFrameTiming=False` and repeated the identical guest work. Ordinary
`sleep_until` preserved CPU-thread mean at 11.607500 ms but worsened wake
lateness to 1.422744 ms mean / 2.124091 ms p95 and total p95 to 18.227265 ms.

**Reject ordinary sleep.** The existing precision timer remains correct. This
does not reopen the previously rejected wake-lead, busy-spin, sleep-chunk,
QoS, or scheduler experiments.

## Binary oracle

PGO increased `__text` from 81,235,476 to 81,959,380 bytes, so the gain is not
blanket outlining or a smaller instruction footprint. It increased visible
symbols from 870 to 1,123 while selectively removing hot call sites:

| Direct call target | Control sites | PGO sites | Delta |
| --- | ---: | ---: | ---: |
| `ppc_fp_available` | 98,392 | 87,890 | -10,502 |
| `ppc_psq_load` | 496 | 436 | -60 |
| `ppc_psq_store` | 505 | 468 | -37 |
| `ppc_fmadd_op` | 3,661 | 3,197 | -464 |
| `ppc_fmuls` | 6,372 | 5,791 | -581 |
| `ppc_lmw_op` | 339 | 821 | +482 |
| `ppc_stmw_op` | 430 | 398 | -32 |

Disassembly also shows profile-directed internal specialization, including an
inline common GQR type-0/RAM path inside `ppc_psq_load`, while cold exception
and host-call paths remain out of line. Previous blanket FP-gate inlining,
global paired-load coalescing, cold-symbol outlining, and outer FMA mode splits
remain rejected. The next diagnostic is to capture/diff the compiler's
optimization remarks for the exact eliminated hot calls and choose one
previously untested, semantics-complete common case. Do not convert this
oracle into another global inline change.

That diagnostic subsequently completed. A byte-identical ThinLTO relink wrote
244 private YAML shards containing 286,220 inline records: 44,741 successful
and 241,479 missed. Successful dynamic hotness is dominated by:

- 41,671 `ppc_fp_available` sites;
- 746 `ppc_lmw_op` sites;
- 585 `ppc_fmuls` sites;
- 464 `ppc_fmadd_op` sites;
- 61 `ppc_psq_load` sites; and
- 36 `ppc_psq_store` sites.

Hot sites received an inline threshold of 3,000, while cold sites commonly
remained at 325 or 45. This directly explains why prior blanket helper
inlining did not reproduce PGO: the useful input is call-site hotness, not a
global helper attribute.

LLVM coverage mapping tied the hottest short long-load candidate to revision-0
PC `0x8036E8B4`, `lmw r27,132(r1)`. It executed about 3.09 million times in
the training profile; the other six calls in its chunk recorded 269, 726, 572,
416, or zero executions. Retained host preflight binaries show that inlining a
fixed short range saves only about 1 ns/call versus the current out-of-line
range helper. One PC therefore cannot materially reproduce the aggregate
4.2 ms/frame PGO gain. The one-site module build was rejected before source or
generated code changed. Do not replace aggregate selective PGO with a large
revision-specific address list.

## Reproducible private PGO cache

`patches/moderngekko/0008-private-pgo-cache-identity.patch` adds an explicit
build-only `--pgo-profile` option to `moderngekko-port`. It is deliberately
limited to the C backend with Clang. The tool canonicalizes and hashes the
private profile, adds only its SHA-256 to the complete module cache identity,
and records only that hash in the manifest. An unavailable profile, a non-Clang
toolchain, and use with `inspect` are rejected before module compilation.

The current combat profile rebuilt into isolated cache key
`0f09e240...-5d9d1b7aea44e9f0`. Its manifest contains profile SHA-256
`3f9d2aa4...f572ac12` in both `flags` and `pgo_profile_sha256`, with no private
path. A repeat invocation was an immediate cache hit. Copying the identical
profile to a different private path also hit the same key, and a manifest scan
found no `/private/tmp` or user path.

The rebuilt unsigned module SHA-256 is `cce4ea64...f629682f`, rather than the
earlier oracle's whole-file hash, because the Mach-O UUID and 47 other non-code
bytes were regenerated. Both files are 83,126,968 bytes and their 81,959,380
byte `__text` sections have identical SHA-256
`5df909902be0306ad723a7882178854197afc3da38ae8330555544163de96bae`.
Only `_staticrecomp_get_module` is exported and no profiling hook remains.
This establishes code equivalence without treating non-deterministic Mach-O
metadata as a cache identity.

The canonical patch passed reverse/apply verification with an identical source
hash. Dependency bootstrap, repository checks, and package-layout checks for
both local macOS apps pass. This makes the known CPU improvement reproducible;
it does not change the strict runtime verdict below.

## Live product boundary

Computer Use inspected the actual candidate window after a readiness-gated
state load. The title reported 59.9 FPS; Pikachu, CPU Fox, timer, HUD, and
Fountain geometry were coherent. The lower reflection matches the already
closed reference-parity behavior, and no fighter morphing appears in the
retained frame.

**Retain the fresh local PGO module as an optimization oracle, not as the
reproducible product module. G5 remains open; Final Destination is not run;
G6 remains blocked.** No game process or Simulator remains.

A validated local copy is installed at `build-macos/MeleePad-PGO.app` so the
best-known native build remains runnable on this machine. Its module is the
signed `bd089303...` candidate above; package layout, deep strict signing,
arm64 identity, macOS 14 minimum, and a no-game-data extension scan pass. The
canonical reproducible `build-macos/MeleePad.app` remains unchanged.

## Evidence

- `docs/evidence/g5-current-idle-pgo/candidate-a.phase.csv` —
  `2bc97f4f71f3772d6c3c73d45db86deb0b5db43536fbafbc1a9c348a0df6d9a1`;
- `docs/evidence/g5-current-idle-pgo/control.phase.csv` —
  `e96cd6a14e43b4b594ba56915ccbfb74711940f80b06ad95ef038f0cdc8527e3`;
- `docs/evidence/g5-current-idle-pgo/candidate-a2.phase.csv` —
  `2525261a678a3676383bc5a7f75f3e9850547bba7636a913d7927959b084f086`;
- `docs/evidence/g5-current-idle-pgo/candidate-no-precision.phase.csv` —
  `2e0a4ada19a07d40a8a4cd7af9474c9988edd7a5a12a124397a57adea305fb89`;
- `docs/evidence/g5-current-idle-pgo/candidate-live-fountain.jpeg` —
  `40aec28b728acf62108e722505b94e0e7ae3aed47938116ed4b8166dae485425`.
