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
| 3 | Final Destination, 8 min | Provisionally accepted by user waiver | Warm game-side CPU/audio evidence is retained; the unavailable 59.94 Hz/VRR display check is assumed to pass by explicit user direction and must be repeated later. This is not an empirical external-display result. |
| 4 | Fountain of Dreams 1v1 | Pass | Multiple visually verified complete macOS matches and CPU/GPU/presentation profiles are retained; timing failures are recorded honestly. |
| 5 | 4-player item match, Battlefield | Pass | A controlled macOS run explicitly selected Battlefield with P1 plus three level-1 CPUs, visibly showed an item in live combat, and reached natural Time Battle results without a crash. The retained bracket records an honest approximately 36.2 effective game FPS despite near-59.94 host presentation. |
| 6 | Classic mode, 3 stages | Open | Mobile Classic combat does not satisfy the required macOS three-stage progression row. |
| 7 | Audio continuity | Fail / attributed | Live iPad diagnostics prove RemoteIO callbacks remain active, but demanding combat at 37-40 FPS starves the DMA queue; underruns rose 99→258 in 30 seconds. A 160 ms reserve failed. Fresh exact-source PGO directionally improved demanding demo scenes to roughly 42-48 FPS but still saturated CPU-GPU and accumulated underruns, so it is promising but insufficient. See the audio/combat artifact. |
| 8 | Save/memory card | Pass | Live `CODM` (macOS) and `CODX` (iPad Simulator) names were visibly recovered after clean process relaunches. SsbmPad settings were also read back after relaunch on both targets. See the row artifact. |
| 9 | Touch overlay drives gameplay | Partial | Stick/A/X/Start and layout edit/reset are live-proven. L/R now have matching compact geometry and digital-plus-trigger semantics, with a focused regression and live visual proof; every remaining control still must be verified in-match. |
| 10 | Menu system parity | Partial | G7 proves live resolution/aspect/FPS/layout/mapping/game-data/report surfaces; every action's full behavior, including import/removal boundaries, remains a G8 row. |
| 11 | Controller connect/disconnect | Partial | Slot retention, P1 reclaim, and held-input clearing pass focused tests; live overlay hide/show and reconnect need evidence. |
| 12 | Diagnostics export | Pass | iPad export/privacy scan pass. The rebuilt macOS launcher now exposes Export Diagnostics; its compiled exporter produced a real runner-log report with required breadcrumbs and zero private-path, game-data, disc-image, memory-card, or save matches. |
| 13 | Game data import flow | Pass | Exact GALE01 validation, 1,209-file extraction, atomic activation, visible boot, normal relaunch, and same-filename Files-folder reimport passed. See the row artifact. |
| 14 | Regression suite | Pass | All existing G5 tools plus the ported input, controller, diagnostics, performance, frame-mode, touch-layout, and game-data tests pass. |
| 15 | Clean-clone build | Pass | A fresh checkout exposed and repaired a stale Metal patch-composition hunk, then cloned every pin, extracted the exact private image, regenerated the 237-chunk module, built/signed the macOS app, and passed bootstrap, package, and repository gates. See the row artifact. |

## Next execution order

1. Repair the measured generated/static-core combat producer deficit; row 7
   cannot pass while the optimized game still falls to roughly 42-48 FPS. Use
   the fresh compatible PGO candidate as the comparison floor and address a
   newly measured residual generated-dispatch/static-core mechanism. Exact-PGO
   O3 is structurally rejected and must not be replayed.
2. Close the remaining iPad interaction cluster while keeping exactly one
   Simulator booted: every touch control, controller lifecycle, and import
   rollback/removal hardening. Save persistence is already passed.
3. Close the remaining macOS non-display row: Classic three-stage progression.
   Battlefield completion, persistence, and diagnostic export now pass.
4. Repeat the provisionally accepted row 3 on 59.94 Hz/VRR hardware during
   later device validation; a failure reopens it.

G9 netplay begins only after G8 is green. G5 is provisionally accepted for
loop progression under the explicit user waiver recorded in
`docs/artifacts/2026-08-30/g5-external-display-user-acceptance.md`.

Row 13 was subsequently closed by
`docs/artifacts/2026-08-30/g8-ipad-game-data-import.md`.

Row 7 was subsequently measured and failed under sustained iPad Simulator
combat. See
`docs/artifacts/2026-08-30/g8-ipad-audio-and-combat-attribution.md`.

Row 8 was subsequently closed by
`docs/artifacts/2026-08-30/g8-save-and-settings-persistence.md`.

Row 15 was subsequently closed by
`docs/artifacts/2026-08-30/g8-clean-clone-build.md`.

The compact equal-size L/R product correction and live visual proof are
retained in
`docs/artifacts/2026-08-30/g8-public-presentation-and-compact-r.md`; row 9
remains partial pending every-control live gameplay proof.

Exact-profile iOS O3 was subsequently rejected before live replay because it
left `chassis_dispatch` unchanged and grew every sampled hot generated-function
span. See
`docs/artifacts/2026-08-30/g8-ios-exact-pgo-o3-rejection.md`.

Row 12 was subsequently closed by
`docs/artifacts/2026-08-30/g8-macos-diagnostics-export.md`.

Row 5 was subsequently closed by
`docs/artifacts/2026-08-30/g8-macos-battlefield-four-player-item-match.md`.
