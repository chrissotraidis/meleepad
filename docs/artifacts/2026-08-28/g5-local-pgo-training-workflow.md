# G5 local PGO training workflow

Date: 2026-08-28

Status: **DATA-FREE LOCAL TRAINING/CONSUMPTION WORKFLOW RETAINED; G5 OPEN**

## Question

PERF-071 could consume a private LLVM profile but could not reproduce that
profile from repository-native scripts. Can a clean local workflow build an
instrumented app from the user-owned revision-0 disc, isolate counters to one
combat match, merge the private result, build a signed PGO-use app, and restore
the canonical module pointer without committing game data or private paths?

## Retained workflow

`moderngekko-port build` now accepts `--pgo-generate`, mutually exclusive with
`--pgo-profile` and restricted to the C backend plus Clang. Generation and use
have distinct cache identities and manifests. `prepare-game.sh` exposes the
same optional mode without changing its ordinary one-argument path.

Three new scripts compose the private workflow:

1. `package-local-pgo-training-app.sh` builds, manifest-checks, packages, and
   signs an instrumented app while restoring `active-module.txt` on every exit;
2. `run-local-pgo-training.sh` runs that app with an explicit revision-0 combat
   predicate, isolated user directory, and private raw-profile directory; and
3. `merge-local-pgo-profile.sh` merges one or more raw files and requires the
   combat-only dump hook before accepting the result.

The scripts never contain or copy the disc, extracted game, profile, generated
module, app, savestate, or private path into Git.

## Failing-before and build proof

Before the patch, `moderngekko-port ... --pgo-generate` returned status 2 as
an unknown option. The retained implementation rejects generation plus use,
non-C/non-Clang generation, and generation on `inspect`.

The first instrumented build completed all 247 generated-module steps. Its
cache manifest contains `pgo_generate=1`, not a profile hash, and the module
exports both reset and dump hooks. The signed training module SHA-256 is
`71d5e12ee72611d04b8efe616cd849e07301e04f61379860160dd57874e5c9d2`.

An initial package attempt ran out of disk after the valid module build and
left a truncated disposable app. That app was removed, only reproducible
intermediate directories under completed cache keys were pruned, and a cached
retry passed package layout plus strict signing. The ROM, final cached modules,
manifests, canonical apps, source inputs, profiles, and saves were untouched.

## Combat-only profile proof

The runner waited until the emulated clock reached frame 2,241 before loading
the retained local Fountain state, avoiding the known startup-load hazard. The
revision-0 predicate armed at `80477D68,ffffffff,02020102`; runtime output then
recorded profile reset, natural match completion, a successful dump, and a
normal Command-Q shutdown.

- raw profile SHA-256:
  `6282e89b7064acd84ba07f5109bb64def1edfb8a95d21879d1e09f8d4c0e9439`;
- merged profile SHA-256:
  `9fe17c1b29dceb0a1b8c80dd61bc518fce1328fbb5816f15a0f6a715319cf91d`;
- coverage: 6,556 functions, 2,727,666 blocks, and
  135,462,879,791 aggregate counts.

The earlier oracle has the identical function/block shape and
135,462,880,664 counts. The 873-count difference is real and must not be
described as byte identity. It is concentrated around one boundary execution:
the new profile records one fewer `loop_80349494` entry and 86 fewer associated
32-bit reads.

## PGO-use product comparison

The locally merged profile drove a fresh 247-step profile-use build without
profile mismatch warnings. The canonical pointer was restored afterward and
the app passed layout, arm64, macOS-14-minimum, and strict-signature checks.

- unsigned locally trained module SHA-256:
  `c3318146093391b78a3e9e3c9fd21fa5e78b22ef687770106f24981e7716ec54`;
- signed locally trained module SHA-256:
  `a458b53d331ea532099b0d217aba6e9a340bef7938b6067a64e89ac00e90f847`;
- locally trained `__text` size/hash:
  `81,959,380` bytes / `2913507b...8289c`;
- earlier-oracle `__text` size/hash:
  `81,959,380` bytes / `5df90990...6bae`.

The first text difference occurs inside `func_80345940`; 127,816 bytes differ
across 16,115 small regions within that one enormous generated function. This
is a valid profile-directed code-layout difference, not evidence that either
module is semantically wrong. The locally trained binary therefore remains a
diagnostic product and does not replace `build-macos/SsbmPad-PGO.app`.

Validation found that the reusable oracle app still carried its older
pre-display-sync runner. Repackaging it through PERF-071 selected the cached
known profile module, restored the canonical pointer, and updated only the
local app bundle. It now passes the product layout and strict-signature checks
with runner SHA-256 `93ebc462...6563cd5` and unchanged known PGO module
SHA-256 `bd089303...af26f5a`.

## Clean native runtime result

After the build load had ended and the machine had cooled, one foreground-only
run used Metal, Cubeb, the isolated controller/user tree, and exactly one
native arm64 game process. It waited beyond emulated frame 1,000, loaded the
same Fountain state, rendered coherent Pikachu versus CPU Fox combat, and
closed normally with zero runtime fallbacks. No Simulator was booted.

The last occurrence of every emulated frame `48123..48562` produced 440 rows
with exactly the established PGO-oracle work:

- 1,501,757,755 guest cycles;
- 51,380,895 native dispatches;
- 905,756 bursts; and
- 882 hook fallbacks.

| Metric | Locally trained PGO |
| --- | ---: |
| Mean / FPS | 16.663618 ms / 60.011 |
| Median | 16.553833 ms |
| p95 | 18.065125 ms |
| p99 | 19.130250 ms |
| Worst | 22.509416 ms |
| CPU-thread mean | 11.620875 ms |
| CPU-thread p95 | 12.770189 ms |
| Frames <=16.7 ms | 55.909% |

The 59.8 FPS title and coherent frame are useful runtime evidence, while the
recorded tail is the acceptance result. This reproduces the PGO compute class
but fails the absolute G5 p95/p99/worst requirement.

The supplied incident `7B988C01-591F-412F-89BB-A16A913E5680` belongs to the
older disposable `SsbmPad-FPCFG-Instrument.app` and traps in `ImGui::GetIO`
while `Emuthread - Starting`. It is not a crash of this locally trained app.
The report alone does not establish which external action triggered it; the
retained harness rule is still to withhold state-load signals until an
advancing emulated frame exceeds 1,000. Both current loads followed that rule
and survived.

## Decision

**PERF-072 retains the ROM-safe local generation/training/merge/package
workflow. G5 remains open; Final Destination and G6 remain blocked.** The next
compiler experiment is IR-level PGO (`-fprofile-generate`/`-fprofile-use`) on
the same deterministic Fountain workload. Context-sensitive PGO is not the
first candidate: an Apple-Clang host preflight generated CS profiles without
LTO but silently emitted no profile sections under both ThinLTO and full LTO,
matching upstream LLVM issue 112103. BOLT is also excluded because it accepts
AArch64 ELF, not Mach-O.

## Validation and cleanup

- dependency bootstrap and patch reverse-check: pass;
- ModernGekko desktop-tools rebuild: pass (the known non-fatal SCM probe still
  prints `fatal: bad revision '^master'`);
- generation/use mutual exclusion and command-scope rejection: pass;
- package/run missing-argument and empty-profile-directory rejection: pass;
- shell syntax, executable bits, diff whitespace, and repository safety: pass;
- 40/40 applicable CTest entries: pass;
- 16/16 `gcpipe` tests: pass;
- instrumented/release profile-hook separation: pass;
- canonical, known-PGO, and locally trained package layout/arm64/signature
  checks: pass after refreshing the reusable known-PGO app; and
- canonical active-module pointer restoration: pass.

After retaining the screenshot/phase evidence, the proof app, two isolated
smoke user trees, three small CS-PGO preflight trees, and the reproducible
`module-build`/`dolrecomp-output` directories under the completed local-profile
cache key were removed. The final cached module/manifest and private merged
profile remain available; no game process or Simulator remains.

## Evidence

- `docs/evidence/g5-local-pgo-training-workflow/fountain-combat.png` —
  SHA-256 `0b5681f4...f5f`;
- `docs/evidence/g5-local-pgo-training-workflow/local-pgo-clean-smoke.phase.csv`
  — SHA-256 `47185271...fa77`.
