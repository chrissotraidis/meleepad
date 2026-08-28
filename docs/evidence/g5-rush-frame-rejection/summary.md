# PERF-129 retained evidence summary

Date: 2026-08-28

Verdict: **Rush Frame Presentation rejected**

- Candidate/control exact work matches across emulated frames 48123..52195.
- Actual 33.333 ms holds increase from four in the comparable logger-free
  control window to ten in the 44.982-second Rush trace.
- CPU-thread p95 rises from 13.472 to 13.544 ms and rows above 16.7 ms double
  from 13 to 26.
- `nextDrawable` rows above 10 ms rise from two to four; worst remains about
  22.9 ms.
- Audio remains normal. No product setting or code is retained.

Details and hashes:
`docs/artifacts/2026-08-28/g5-rush-frame-presentation-rejection.md`.
