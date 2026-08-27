# G5 current-source stale-PGO oracle rejection

## Question

After the scalar-FMA and multiword-range corrections, did the retained private
exact-no-input profile still identify material compiler headroom, or had those
source changes made the old PGO direction irrelevant?

## Disposable oracle

The current `b2d4b69da942f7c2` generated source was built at `-O2` with ThinLTO
and the excluded exact-no-input profile. The profile-use link completed, but
Clang reported one mismatched function hash in many chunks and no profile data
for many other chunks. The signed disposable module had SHA-256
`6d748c6ea566dd42b1bf07b3e79f70e81a322c8e66ad37a1d04dd0188d5f8173`.
Its `__text` was 83,583,532 bytes versus 81,235,476 for the profile-free
control, with 852 generated loop symbols versus 592.

The oracle was launched through the then-current packaged runner and loaded
the retained local Fountain state only after the module-ready breadcrumb. Its
nominal `48123..48562` interval executed the pre-fix packaged workload:

- 3,567,157,806 guest cycles;
- 59,374,686 native dispatches;
- 905,164 static bursts; and
- 882 hook fallbacks.

| Metric | Stale-PGO oracle |
| --- | ---: |
| Mean / FPS | 24.378538 ms / 41.020 |
| p95 | 53.859334 ms |
| CPU-thread mean | 18.377052 ms |
| CPU-thread p95 | 28.266574 ms |

The first 275 selected rows remained near 16.3-16.7 ms, then the same guest
cycle rate fell behind and total time rose to 33-42 ms by the final three
55-frame blocks. This is not a repeatable product gain and the stale profile's
partial coverage prevents a source-level causal claim.

## Decision

**Reject PERF-061.** Do not promote, package, or commit the private profile or
its module. Do not retry this stale exact-no-input profile after further source
changes. Fresh PGO remains permissible only for a newly justified, exact-source
question. G5 remains open and G6 blocked.

Evidence: `docs/evidence/g5-stale-pgo-oracle-rejection/current-stale-pgo.phase.csv`
(SHA-256 `5dafbbe0eeb16927061a93067ad9d596800f02bc19d7bc99a16faa9c5b9446aa`).
