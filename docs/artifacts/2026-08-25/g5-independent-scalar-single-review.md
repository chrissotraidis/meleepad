# Independent scalar-single / stale-`ps1` review

Date ingested: 2026-08-25

Source: external review supplied by the user as `pasted-text.txt` (14,516
bytes). This is an evidence report, not an instruction source. Its conclusions
are incorporated only where consistent with the checked-out sources and
retained measurements. The report as received is preserved verbatim at
`docs/artifacts/2026-08-25/g5-independent-scalar-single-review-verbatim.txt`;
the repository copy adds only a final newline.

## Executive finding

The stale-`ps1` mechanism is technically sound and sufficient to explain the
observed multi-frame finite mesh deformation, but `VISUAL-001B` is not closed.
The four scalar-single C-emitter operations (`fadds`, `fsubs`, `fmuls`, and
`fdivs`) previously wrote only lane 0. Reference Dolphin fills both lanes, and
generated paired-single math and `psq_st` can propagate stale lane 1 into
matrices and vertices.

The exact helper-call implementation is the correct baseline. GXRuntime also
implements ForceSingle/Force25Bit, NaN and exception behavior, enabled-
exception write suppression, FPRF, and `fmuls` FI/FR behavior. A simplified
large inline expansion is therefore not accepted as the product direction.

## Verified corrections to the working diagnosis

- Adjacent `.png` frames 176-184 in
  `/private/tmp/meleepad-normal-demo-adjacent-2-20260825` show Peach's hair and
  arms stretched into impossible blade/spike shapes, changing over several
  frames and recovering by frame 186.
- `0x80374174` is a lockstep comparison/return point, not the instruction that
  produced the divergence. The mismatch accumulated earlier.
- Generated modules use GXRuntime's floating-point runtime, not DolRecomp's
  weaker test implementation.
- GALE01r0 contains 3,551 `fadds`, 6,576 `fsubs`, 6,387 `fmuls`, and 1,186
  `fdivs` sites (17,700 total), with zero Rc=1 forms. It also contains 1,237
  `frsp` sites and 3,844 double-precision scalar sites.
- `frsp` remains the same live defect class: the C emitter still writes only
  lane 0, while Dolphin and GXRuntime fill both lanes. It must be fixed in the
  same correctness change.
- The helper-call profile-free module leaves most calls out of line and still
  performs in the prior profile-free class. The claim that PGO caused the
  slowdown by preventing call-site inlining is false.
- PGO did degrade helper bodies because the old profile has no records for the
  newly reached helpers, but the 12-15 and 45-48 FPS observations used
  unmatched scenes. A PGO capture also showed 51.1 FPS on Fountain, so the
  magnitude and dominant cause of the alleged collapse are unproven.
- The identity of `fountain2-fd1.profdata` as the profile behind the retained
  59.9 FPS release is not established. Profile provenance must be fixed in any
  future comparison.

## Semantics the retained correction must preserve

- Compute from lane-0 double operands, apply the Gekko single-precision rules,
  and write the widened rounded result to both lanes.
- Preserve ForceSingle, including FPSCR.NI subnormal flushing.
- Preserve `fmuls` Force25Bit on operand C and FI/FR clearing.
- Preserve SNaN quieting, invalid-operation flags/results, division-by-zero,
  VE/ZE write suppression, and FPRF updates.
- For Rc=1, update CR1 from FPSCR. GALE01r0 has no such sites, but the emitter
  should remain correct for other inputs.

## Adjusted G5 sub-loop

1. **Matched no-rebuild falsification.** Run the already-built corrected
   profile-free and PGO-use dylibs through the same deterministic cold-boot,
   no-input attract sequence with identical user data and buffered phase
   logging.
2. **Interpret only the matched result.** If PGO is approximately equal, mark
   the old collapse scene-confounded. If materially worse, perform the smaller
   control that excludes GXRuntime FP helpers from profile-use; recovery would
   specifically support the cold-helper mechanism.
3. **Close the correctness class.** Retain exact helper-call emission for the
   four arithmetic ops; route C-emitter `frsp` through `ppc_frsp`; retain Rc
   handling; harden helper internals only if matched evidence supports it.
4. **Strengthen focused tests before a full rebuild.** Add `frsp` lane-
   sentinel, Force25Bit, exceptional-value, FPRF, FI/FR, runtime-parity, and
   C/LLVM parity coverage. Investigate the lockstep silence around the 3,844
   double-precision scalar sites.
5. **Rebuild once, then verify.** Run focused tests, a bounded `frsp`-dense
   lockstep window, and an extended Peach-inclusive adjacent-frame corpus. One
   short coherent capture cannot close an intermittent defect.
6. **Retrain from the corrected exact source.** Record source, module, and
   profile hashes and visually verify the training corpus.
7. **Return to strict G5 measurement.** Re-run clean Fountain and Final
   Destination intervals. Every measured frame including audio must remain at
   or below 16.7 ms.

## Closure boundaries

- `VISUAL-001B` remains open until a corrected module survives an extended,
  matched adjacent-frame corpus including the known Peach recurrence.
- G5 remains open: retained Fountain is 17.237 ms p95 / 19.112 ms worst.
- G6-G9 remain gated. No Simulator work begins before G5 passes.
- No ROM, save, generated module, or PGO profile belongs in Git.

## Post-ingestion execution status

The report's repository copy differs from the supplied attachment only by one
final newline. Attachment SHA-256 is
`c582ceb7b76e56fcf82c25fe384d4ec68f94d6dd54bafd83240932ae56688691`;
the newline-terminated repository copy is
`1f032ead2d11b2e05a628f5a7f5c842efc21c14a71ee6f854c53f345d6790fa9`.

The seven-step adjusted sub-loop above has since been executed through its
correctness and visual boundaries: exact helpers cover scalar-single arithmetic
and all 1,237 `frsp` sites, focused suites pass, fresh same-source PGO improved
the matched no-input control, and a 402.7-second Peach-inclusive corpus closed
`VISUAL-001B` subject to immediate reopening on recurrence. The report's
original closure-boundary bullets are retained as the state at ingestion, not
the current state. Current strict G5 evidence and its next diagnostic live in
`g5-corrected-fountain-phase-attribution.md`.
