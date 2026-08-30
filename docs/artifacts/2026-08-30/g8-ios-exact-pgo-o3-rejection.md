# iOS exact-profile O3 preflight rejection

Date: 2026-08-30

Status: **rejected before live replay**

## Question and gate

The retained exact-source frontend-PGO iOS Simulator module improves demanding
combat directionally but remains roughly 42-48 FPS. This bounded experiment
asked whether changing only generated-module optimization from `-O2` to `-O3`
materially reduces the residual generated-code cost named by the live sample.

The candidate used the same current generated source, current 6,537-function
combat profile, strict stale-profile error, iOS Simulator 16.0 deployment
target, SDK 26.5, arm64 architecture, strict floating point, and ThinLTO as the
retained O2 candidate. It earned a live replay only if the binary showed a
credible structural path to at least a five-percent improvement in the named
hot code. Size parity or growth was a rejection.

## Binary comparison

| Measurement | Exact PGO O2 | Exact PGO O3 | Result |
|---|---:|---:|---:|
| File size | 84,031,752 | 84,048,264 | +16,512 bytes |
| `__TEXT` | 83,329,024 | 83,345,408 | +16,384 bytes |
| `__text` | 82,861,820 | 82,878,400 | +16,580 bytes (+0.020%) |
| `chassis_dispatch` span | 9,048 | 9,048 | unchanged |
| `func_80015940` span | 363,516 | 363,612 | +96 bytes (+0.026%) |
| `func_8033D940` span | 453,980 | 454,028 | +48 bytes (+0.011%) |
| `func_80341940` span | 381,336 | 382,036 | +700 bytes (+0.184%) |
| `func_8035D940` span | 286,164 | 286,360 | +196 bytes (+0.068%) |

Both binaries are arm64 `IOSSIMULATOR`, minimum iOS 16.0, SDK 26.5. Candidate
SHA-256 is
`42e43e0cd3bbe86c619e918740ba159af40dacd266eaab4a492ad209f849af46`;
the retained O2 comparison SHA-256 is
`207ab99e894f5627d0206bd26a797d850f401456eff88fc9167ee0aa8dcb842d`.

Function spans are measured from each named generated function symbol to the
next generated function symbol. They include any internal loop labels and are
used only as a matched structural comparison.

## Decision

Reject `-O3` without a Simulator replay. It leaves the shared dispatch span
unchanged and grows every sampled hot generated function; no measured
mechanism approaches the five-percent gate. The private candidate is not
copied into the canonical module path and creates no repository dependency.

G8 row 7 remains fail/attributed. Do not repeat O3, native tuning, host-core
ThinLTO, stale profiles, larger audio buffers, or vertex-loader optimization.
The next performance experiment must name a newly measured residual mechanism
and clear a structural/materiality gate before another live run.
