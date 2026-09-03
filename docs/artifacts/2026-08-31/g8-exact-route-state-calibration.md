# G8 exact-route state calibration

Date: 2026-08-31
Decision: route harness incomplete; row 7 remains failed

## Controlling workload

The user's visible product failure defines the acceptance workload precisely:

- P1 Samus
- level-1 CPU Kirby
- four-stock match with a 5:00 time limit
- Fountain of Dreams
- normal installed-app launch and product input path

`Four-stock` describes the stock count, not four fighters. Prior crowded
four-character traces remain useful diagnostics, but they are not the user's
acceptance route and cannot replace its visible 21.9 FPS result.

## What calibration proved

A guarded warm-process calibration reached P1 Samus versus level-1 CPU Kirby,
visibly highlighted Fountain of Dreams, and entered coherent Fountain combat.
The rules were still the default two-minute time match, so this was route
calibration only and is not acceptance evidence. Manual setup subsequently
proved the game can be configured for Stock, 04 stocks, and a 05:00 stock
time limit. Rebooting Simulator reset those rules to the two-minute default.

The retained calibration runtime log is private and contains no ROM data:

- path: `/private/tmp/meleepad-perf248-calibration.log`
- SHA-256:
  `1b5247e5e7b26f9709b9cb3bbbcc91bdd4670c5c18e38946ec56f7d0900bf13a`

Two cold fixed-duration cursor attempts were rejected. One remained on a blank
character-select state with default rules; the other selected Link instead of
Samus and was stopped by the state barrier before stage selection. Cold-load
cursor motion is therefore not deterministic enough for performance control.

## Guest-state probe

The repaired Simulator MemoryWatcher successfully gated title lockout and menu
state on revision-1.00 guest memory. Historical revision-1.02 libmelee cursor
and player addresses were then probed read-only. Candidate cursor words at
`0x81118DEC` and `0x81118DF0` changed to `0x00890221` and `0x01490222` before
returning to zero, rather than yielding validated cursor coordinates; the
candidate player/status words likewise did not yet correlate with the visible
blank character-select screen. Do not use these addresses for steering until
revision-1.00 semantics are derived and proven with controlled movement.

## Refined next loop

1. Derive the revision-1.00 character-select cursor, player-character,
   controller-status, and rules-state fields from the pinned generated source
   or a bounded correlated probe.
2. Add the smallest state-driven steering primitive to `gcpipe.py`, with a
   focused regression that fails before the change. It must pulse and release
   input based on observed coordinates and verify the selected character and
   controller state; elapsed-duration cursor scripts are rejected.
3. Prove two cold control traversals reach the exact Samus/Kirby, four-stock,
   5:00, Fountain workload. Retain visible roster, rules, stage, and combat
   evidence. This proves the harness only; it cannot pass row 7.
4. On that exact visible failing phase, collect matched, process-filtered
   instruction-address-translation and discarded-sampling evidence. Name a
   source mechanism only if those counters align with the 20 FPS interval.
5. Admit one candidate only through mechanism, integrity, and exact-workload
   control/candidate/control gates. Then run the existing two cold full routes
   and unchanged-build five-minute manual veto.

No new module optimization is authorized before step 3. The active control
module remains SHA-256 `af1364e6fabe9ee29d2a64ee6268bd80ba3ef2aaa47de9c7741655fae9f3211b`.

