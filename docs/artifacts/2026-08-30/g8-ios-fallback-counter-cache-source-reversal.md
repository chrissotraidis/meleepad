# G8 iOS fallback counter and cache-source reversal

Date: 2026-08-30

Status: **PERF-234 MECHANISM CONFIRMED; PROFILE-FREE CANDIDATE REJECTED; G8 row 7 remains open**

## Question

The independent audit inferred roughly 100 million per-instruction
`HookInstructionFallback` state-sync round trips from host PGO counts. Does a
live iOS phase interval confirm that volume, which opcodes cause it, and does
the audit's proposed `mtspr` specialization target the material family?

## E1 live counter result

The exact combined host+module PGO candidate ran one cold-to-heavy route on the
sole iPad Pro 13-inch (M5) iOS 26.5 Simulator with the existing default-off
phase logger. The log contains 10,873 data rows and has SHA-256
`8c5e2e1ee820d53fc746eabaabc536ff6d40ad02855384bd8b619cf82a61b369`.

| Counter | Live total |
| --- | ---: |
| native bursts | 12,603,242 |
| native dispatches | 1,425,204,550 |
| hook fallbacks | 132,082,558 |
| cache fallbacks | 130,890,484 |
| `mtspr` fallbacks | 1,192,060 |
| `mfspr` fallbacks | 14 |
| direct cache helpers | 0 |

This confirms the audit's broad A1 claim more strongly than its profile-count
bound: the live product route executes 10.48 hook fallbacks per native burst.
It refutes E3's proposed `mtspr` priority. `mtspr` is only 0.9% of hook
fallbacks overall and about two instructions per frame in the 46-49 FPS combat
window. Cache operations are 99.1% of the observed hook path.

## Source cause

The combined iOS module was built from the canonical 237 generated chunks.
Those chunks contained 325 generic `ppc_fallback_instruction` sites and zero
`ppc_cache_control` calls. The repo's already-retained C-backend cache-control
correction had previously proved 14 direct cache sites and a broad macOS win,
but the canonical generated output had later been restored to its legacy form;
the iOS build reused it without regeneration.

An isolated clone regenerated the exact DOL with the current retained code
generator. Its source identity is
`0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448-b2d4b69da942f7c2`.
It contains exactly 14 direct cache helpers and 311 remaining generic fallback
sites. The canonical private extraction was not modified.

## Profile-free iOS reversal

The regenerated source was cross-built profile-free for the iOS Simulator.
The 82,326,152-byte module is arm64 `IOSSIMULATOR`, ad-hoc signed, exports only
the normal module entry, contains no profile hooks, and has SHA-256
`5be13bb0fc34ac5b2ae9c19e8bfc618feeedd11cc5553e5a6a6b81a5ca90b749`.

The same host-PGO app and route produced 11,780 phase rows, SHA-256
`01c0b3ae5ff142f8c842d9cbafd36ce4b9c2b36bd6c737f044241f3c71d40055`:

| Counter | Cache-direct total |
| --- | ---: |
| native bursts | 12,620,216 |
| native dispatches | 1,339,040,280 |
| hook fallbacks | 1,349,480 |
| cache fallbacks | 0 |
| `mtspr` fallbacks | 1,349,466 |
| direct cache helpers | 144,173,043 |

The intended mechanism reversed exactly: hook fallbacks fell 98.98%, and all
cache work moved to the direct helper. This profile-free candidate is not a
product win. Its first heavy transition measured 33.3, 35.7, and 39.5 FPS;
later demanding intervals measured 47.3 and 50.3 FPS; DMA underruns rose from
2 to 232. The later aligned 7,800-8,999 frame region improved from
20.914/21.365 ms means to 19.536/17.978 ms, but the earlier transition became
materially worse.

## Decision and next experiment

**Retain the regenerated cache-direct source mechanism; reject the unprofiled
iOS module as the product candidate.** The live counter result confirms A1 but
refutes a narrow `mtspr` E3. The comparison also demonstrates that the legacy
module's fresh combat PGO advantage is larger than the standalone source
change during cold transitions. Applying its profile to the changed source
would be stale and invalid.

Next collect a representative profile on the regenerated cache-direct source,
strict-use all observed generated/runtime units while keeping unobserved
interpreter fallback units profile-free, and pair it with the retained
host-runtime PGO app. Judge that combined exact-source reversal by per-interval
FPS and DMA-underrun deltas. If it still misses, continue to the audit's iPad
dual-core experiment; do not specialize `mtspr` first.

Both runs were terminated and the sole Simulator was shut down. No ROM,
generated game source, module, profile, phase CSV, save, or private path is
tracked.
