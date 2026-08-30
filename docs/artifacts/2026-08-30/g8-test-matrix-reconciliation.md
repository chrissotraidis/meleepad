# G8 test-matrix reconciliation

Date: 2026-08-30

Status: **G8 in progress**

This reconciliation applies the PRD pass conditions to retained evidence after
G6 and G7. It does not promote source inspection or a partial interaction into
a completed row.

| # | Row | State | Current evidence / exact gap |
|---|---|---|---|
| 1 | Boot to title | Pass | macOS G3 plus iPad/iPhone G6 rendered title/menu/gameplay frames without a crash. |
| 2 | Menu navigation | Pass | CSS reached on macOS, iPad Simulator, and iPhone Simulator. |
| 3 | Final Destination, 8 min | Blocked by deferred G5 | macOS gameplay and extensive timing exist, but the strict audio-inclusive 16.7 ms tail has not passed; external 59.94 Hz/VRR verification is deferred. |
| 4 | Fountain of Dreams 1v1 | Pass | Multiple visually verified complete macOS matches and CPU/GPU/presentation profiles are retained; timing failures are recorded honestly. |
| 5 | 4-player item match, Battlefield | Partial | Coherent live four-player Battlefield frames exist, but a natural full match completion with retained timing evidence is not yet proven. |
| 6 | Classic mode, 3 stages | Open | Mobile Classic combat does not satisfy the required macOS three-stage progression row. |
| 7 | Audio continuity | Partial | macOS G4 proves Cubeb/CoreAudio and iPad G6 proves RemoteIO music/gameplay activity; a retained full iPad continuity/underrun window is still needed. |
| 8 | Save/memory card | Open | Memory-card UI rendered, but macOS+iPad name entry and persistence across relaunch are not proven. |
| 9 | Touch overlay drives gameplay | Partial | Stick/A/X/Start and layout edit/reset are live-proven; every remaining control must be verified in-match. |
| 10 | Menu system parity | Partial | G7 proves live resolution/aspect/FPS/layout/mapping/game-data/report surfaces; every action's full behavior, including import/removal boundaries, remains a G8 row. |
| 11 | Controller connect/disconnect | Partial | Slot retention, P1 reclaim, and held-input clearing pass focused tests; live overlay hide/show and reconnect need evidence. |
| 12 | Diagnostics export | Partial | iPad export and privacy scan pass; a macOS export is still required. |
| 13 | Game data import flow | Pass | Exact GALE01 validation, 1,209-file extraction, atomic activation, visible boot, normal relaunch, and same-filename Files-folder reimport passed. See the row artifact. |
| 14 | Regression suite | Pass | All existing G5 tools plus the ported input, controller, diagnostics, performance, frame-mode, touch-layout, and game-data tests pass. |
| 15 | Clean-clone build | Open | No fresh-directory end-to-end reproduction has been retained for the current G7 tree. |

## Next execution order

1. Close the remaining iPad interaction cluster while keeping exactly one
   Simulator booted: every touch control, audio continuity, save persistence,
   controller lifecycle, and import rollback/removal hardening.
2. Close the missing macOS non-display rows: Battlefield completion, Classic
   progression, macOS persistence, and diagnostic export.
3. Run the clean-clone pipeline.
4. Revisit row 3 when the deferred external-display capability exists.

G9 netplay begins only after G8 is green. G5 remains unpassed under the
user-authorized sequencing exception.

Row 13 was subsequently closed by
`docs/artifacts/2026-08-30/g8-ipad-game-data-import.md`.
