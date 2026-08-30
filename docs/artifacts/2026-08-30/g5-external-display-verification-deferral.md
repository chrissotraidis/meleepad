# G5 external-display verification deferral

Date: 2026-08-30

## Decision

The user explicitly directed the loop to proceed without the unavailable
external 59.94 Hz / variable-refresh display and to repeat that display test
after the iPadOS/iOS version exists.

For sequencing only, the external-display portion of G5 is therefore deferred
and G6 is authorized to begin. This is not measured evidence, does not turn G5
into a pass, and does not weaken PRD D2. Final project completion still requires
revisiting G5 on suitable hardware or otherwise satisfying its existing
acceptance criteria with retained evidence.

## Operational boundary

- Do not spend more time searching for an external display on this machine.
- Proceed with G6 in its specified order: iPad Simulator, then iPhone
  Simulator, with exactly one Simulator booted at a time.
- Keep G5 visibly deferred rather than reporting 60 FPS as proven.
- Re-run the external-display verification after the iPadOS/iOS version is
  available, as directed by the user.

