# G8 revision-1.00 exact-route reproduction

Date: 2026-08-31

## Decision

The exact user-reported workload is now reproducible from a fresh process, but
G8 row 7 remains failed. Two successful cold traversals reached P1 Samus versus
level-1 CPU Kirby, Stock/04/05:00, on literal Fountain of Dreams. Visible active
combat reported 45.2 FPS and 36.4 FPS. Both fail the 59 FPS floor, and neither
supersedes the user's lower ordinary-route observation of 21.9 FPS.

## Revision-1.00 state proof

- P1 cursor position: `8049EA88 C/10`; P1 cursor state: `8049EA88 4`.
- P1 character data: `804D4B30 70`; Samus character kind is `0x10`.
- P2 character data: `804D4B30 94`; `0x0401` proves Kirby and CPU slot type.
- Active rules pointer: `804D1D60`; offsets `1848`, `184C`, and `1850` prove
  Stock, four stocks, and a five-minute limit respectively.
- Stage-select state: `804D4B2C`; hovered slot `0x08` maps through the pinned
  stage table to `St_Kind_Izumi` (`0x02`), Fountain of Dreams.
- Scene state `80477D68` changed from CSS to stage select `0x02020101`, then
  active match `0x02020102` only after all predicates passed.

The harness feedback-drives character cursors, rule values, and the stage
cursor from watched guest state. The revision-1.00 `HSD_GObj_Entities` global
is `0x804D56A4`; following the p-link-5 list head through 22 successors reaches
the live stage cursor object. Its X/Y values at `0x28/0x38` and `0x28/0x3C`
now steer directly toward `(7.4, 14.1)`, while the independent slot-8 predicate
still vetoes A if the cursor is not on Fountain. This replaces the calibrated
elapsed-time stick path that could fail after a fresh heap recreation.

## Runs

1. Cold process 24923: exact CSS/rules/roster passed; the extended route then
   proved stage slot 8 and active combat. Computer Use showed coherent Samus,
   CPU Kirby, four stock icons, a 05:00 countdown, Fountain, and 45.2 FPS.
2. A deliberately simplified two-step stage experiment failed to move from
   slot 14 to slot 8. It was rejected as a harness calibration failure and the
   oversimplification was removed; it is not game stability evidence.
3. Cold process 26251: the restored state-checked route passed end to end.
   Computer Use again showed the exact match and only 36.4 FPS.
4. After replacing the remaining stage timing path with live cursor feedback,
   two further fresh processes reached the same exact match. One visibly
   reported 45.4 FPS. These are route-calibration passes only; they are not
   performance passes and do not replace the 21.9 FPS control floor.

Focused harness tests pass 27/27. The route changes product input only through
the existing GameCube pipe and observes guest state through the diagnostic
MemoryWatcher path; it does not alter emulation performance.

## Loop refinement and next experiment

The exact route is now the mandatory matched phase for performance work. The
controlling floor remains 21.9 FPS because acceptance uses the lower visible
result. The next experiment is a process-filtered, exact-combat comparison of
instruction-address-translation stalls and discarded-instruction sampling,
with runtime FPS/VPS and DMA-underrun rows retained for the same interval.
Do not build another module until those counters identify a narrower mechanism.
