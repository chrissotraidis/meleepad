# G5 FP-availability cache rejection

Date: 2026-08-27

## Question

Could generated C retain exact lazy-FP exception semantics while avoiding
repeated successful `ppc_fp_available` calls inside one native generated-chunk
invocation?

## Candidate and semantic boundary

The test-first candidate added a local `fp_available_checked` flag only to
generated functions and counted-loop helpers that contain FP instructions.
Every FP instruction retained its own CIA-specific check behind that flag, so
direct entry at any instruction still checked the correct guest address. The
only continuing generated MSR mutation, `mtmsr`, cleared the flag. Exception,
`rfi`, fallback, and external-control paths return from generated code and
cannot reuse it.

The focused code-generation test failed before implementation with
`generated functions do not cache a successful FP availability check`. After
implementation, direct entry at the second FP instruction with MSR.FP clear
raised FP-unavailable at the second instruction's CIA without modifying its
destination. A first FP operation followed by `mtmsr` clearing MSR.FP then
raised at the second FP instruction. The focused opcode, cross-check,
PC-reference, CFG, generated-compile, and generated-execution groups passed
6/6 without warnings.

A disposable signed module then passed the established bounded lockstep
screen exactly: 1,401 checked PCs, the canonical 91-report set, seven fallback
skips, three zero skips, zero undercharges, and zero maximum deficit. This
proves the bounded semantic screen, not performance.

## Actual-profile preflight

The retained exact-source Fountain profile recorded 4,234,689,456 calls to
`ppc_fp_available`. All 230 generated chunks containing FP code recorded
803,473,272 entries. Even the conservative assumption that every such entry
would require one candidate check bounds the reduction at 3,431,216,184 calls,
or at least 81.026%. This justified one full build despite source-size risk.

The risk materialized in linked code. Generated chunk source grew from
251,208,005 to 261,603,429 bytes (+4.138%), while linked `__text` grew from
81,235,476 to 94,598,884 bytes (+13,363,408 bytes, +16.450%). The signed
candidate module SHA-256 was
`d4428a3754292ac5ed8c326f8a67eed4d2a09071ead3bfc15420829c9fada9fe`;
the signed control was
`44366f2e5392c331fa72871ef829af86813da383dce4957aa8c445d8d4505b90`.
Both were native arm64/macOS 14 modules with the same two exports.

## Exact Fountain reversal

Candidate A, canonical control, and Candidate A2 used separate copies of the
same seed, Cubeb, the same canonical runner, readiness-gated state loading,
and one process at a time. The common last occurrence of emulated frames
`48123..48507` contains 385 frames. All three windows match exactly:

- 1,330,434,029 guest cycles;
- 45,572,090 native dispatches;
- 801,319 bursts;
- zero static fallback steps; and
- 772 hook fallbacks.

| Metric | Candidate A | Control | Candidate A2 |
| --- | ---: | ---: | ---: |
| Mean / FPS | 24.233160 ms / 41.266 | 16.556167 / 60.400 | 24.091905 / 41.508 |
| p95 | 26.924542 ms | 18.112850 ms | 26.621650 ms |
| p99 | 31.386338 ms | 19.587948 ms | 28.206307 ms |
| Worst | 45.149958 ms | 23.309292 ms | 35.855292 ms |
| CPU-thread mean | 23.750177 ms | 16.113886 ms | 23.650414 ms |
| CPU-thread p95 | 26.062001 ms | 17.552447 ms | 25.932741 ms |
| Frames <=16.7 ms | 0.000% | 63.636% | 0.000% |

The candidate repeats a roughly 7.6 ms CPU-thread regression with identical
guest work. The saved helper calls cannot compensate for the much larger and
more complex generated control-flow graph.

## Decision

**PERF-067 REJECTED; G5 OPEN; FINAL DESTINATION AND G6 BLOCKED.** Remove all
candidate source and candidate-specific regressions. Do not retry a per-chunk
FP-availability flag or another branch at every FP instruction. The canonical
module and app remain unchanged. A next FP experiment must reduce call-site
spill/call cost without multiplying the generated control-flow graph.

## Retained evidence

- `docs/evidence/g5-fp-cache-rejection/candidate-a.phase.csv` — SHA-256
  `66b3c535ce73a26280086a638f396ee0977b5e9fe46d9d44cffedf1e2a9e250d`;
- `docs/evidence/g5-fp-cache-rejection/control.phase.csv` — SHA-256
  `089c7a74704972c04bb6eb92ce528a84f4ae54fbbd6c35c86a019257c8b718ec`;
- `docs/evidence/g5-fp-cache-rejection/candidate-a2.phase.csv` — SHA-256
  `32dca979177569f7ed87abef1f4e02c0811ccb98275f198094d2f24b76657a9e`;
  and
- `docs/evidence/g5-fp-cache-rejection/lockstep-candidate.txt` — SHA-256
  `d7990d05d50073646b05b9156d5dfb921e6a2e979c90443b2eaddb8808211286`.

The ROM-derived generated source, DOL, candidate module, app, savestate, and
isolated user directories remain local and excluded from Git. No game process
or Simulator remains.
