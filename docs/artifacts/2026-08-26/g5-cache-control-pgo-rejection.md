# G5 exact-source cache-control PGO rejection

Date: 2026-08-26

## Question

Does fresh Fountain-trained PGO on the retained generated cache-control path
meet the absolute 16.7 ms Fountain gate? Final Destination was permitted only
if Fountain passed.

## Exact inputs

- Corrected generated-source identity:
  `0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448-06852d9fd6223c6a`
- Instrumented module SHA-256:
  `facf9f97625faa31deac9ccd37e8e84287f17352af588cf97f3e6eccdd69b80a`
- Eligible raw profile: exactly one visually verified Fountain run, SHA-256
  `8cbc48897bf07ddef4d1b77e5748ac3a3269575ba98923362577dbbd66c55617`
- Merged profile SHA-256:
  `6a73581f21b3a93a955e9805e50abf6b8f63d3aaeb4a8057cddd368fb843202e`
- PGO-use module SHA-256:
  `1993ed0c9619875b19e5b7fc711143ee241bf7c3084c0397b0ee281f931b26b5`
- PGO-use module is signed arm64/macOS 14 and exports
  `_staticrecomp_get_module`; it exports no profile reset/dump hooks.

The eligible training run used P1 Bowser versus level-1 CPU Zelda on visually
verified Fountain for 30 repeats of the combat cycle. Shutdown reported
`fallback=0` and `smc_failed=0`. Four earlier route-debug profiles were moved
outside the eligible profile directory and were not merged.

## Acceptance run

The accepted timing bracket used:

- native macOS runner, Metal, 640x528, Cubeb;
- P1 Bowser versus level-1 CPU Bowser;
- an explicitly verified Fountain highlight and live Fountain match;
- 20 repeats of the existing combat cycle with no UI capture inside the
  bracket;
- phase-log line count 45,997 before and 52,665 after;
- 120 rows trimmed from each edge, leaving 6,428 frames.

The first PGO route accidentally entered a four-player Final Destination demo
and was discarded before timing. Two later profile-free route attempts also
entered attract matches and were discarded. They are not controls and are not
used for any comparison. The previously collected Bowser versus CPU Ice
Climbers profile-free bracket is useful diagnostic context but is roster-
unmatched and is not presented as an A/B control.

## Strict result

| Metric | PGO Fountain |
| --- | ---: |
| trimmed frames | 6,428 |
| mean | 16.894 ms |
| median | 16.676 ms |
| p95 | 17.860 ms |
| p99 | 18.080 ms |
| worst | 1,367.699 ms |
| frames <=16.7 ms | 55.009% |
| FPS from mean | 59.194 |
| mean audio mix | 0.789 ms |
| fallback steps | 0 |
| cache fallbacks | 0 |

The candidate fails without relying on the single large stall: 2,892 frames
exceed 16.7 ms, p95 is 17.860 ms, and the mean after excluding the only frame
over 100 ms is still 16.683 ms. Eight frames exceed 20 ms and two exceed
30 ms.

Frame 48,910 is the 1,367.699 ms outlier. It is guest-work dominated rather
than present/video overhead: 1,358.656 ms CPU wall, 906.791 ms CPU-thread time,
478.074 ms throttle sleep, 69.168 ms audio mix, 51,975 static bursts,
664,798,267 charged cycles, and 41,469,067 native dispatches. Ordinary frames
carry roughly 630-647 bursts and about 100k-450k native dispatches. The stall
therefore remains a real runtime event in the retained bracket, not a screen-
capture cost.

## Visual and route findings

The live acceptance screen reproduced severe lower-viewport warping and
Bowser duplication/morphing. This reopens `VISUAL-001B` under its explicit
recurrence rule. The same class of corruption was also seen with the current
profile-free cache-control module, so the evidence does not attribute it to
PGO.

Cold-boot routing also has a reproducibility defect. The memory-watched route's
first title-lockout predicate timed out during the opening movie, while an
immediate or sustained START can enter an attract match instead of the menu.
Visual inspection successfully prevented every such route from contaminating
the accepted bracket.

## Decision

**PGO CANDIDATE REJECTED; G5 OPEN; VISUAL-001B REOPENED.** Do not retain or
package the PGO-use dylib. Do not run Final Destination and do not start G6.

The next single experiment is a deterministic adjacent-frame reproduction of
`VISUAL-001B` on the retained profile-free cache-control module. Capture the
first coherent frame and first corrupted frame with the same match state, then
attribute the earliest divergent generated draw/vertex data before resuming
performance experiments. In parallel with that evidence, replace the stale
cold-boot title predicate with a state transition that distinguishes opening
movie, title, menu, and attract match; no future timing bracket is accepted
without explicit roster, stage-label, and live-stage proof.

## Retained artifacts

- `g5-cache-control-pgo-fountain-trimmed.csv` — SHA-256
  `a703812da46e112c2baf9bad10367a40495d1b5ad589595fad4fcaab3e603986`
- `g5-cache-control-pgo-fountain-visual.png` — SHA-256
  `98f3fd1d05e27ccd6cf4c0b7bf14457a963469f004623aed6f3f93d3c8fa723a`

No ROM, extracted game data, save data, raw profile, profdata, or dylib is
retained in git.
