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
| 6 | Classic mode, 3 stages | Pass | A retained macOS run naturally cleared Brinstar, cleared the following team battle, completed the target bonus stage by timeout, and advanced into the Bowser fight. Generated-code-derived pointer chains matched live fighter percentages. The known visual-warping defect remains separate. |
| 7 | Audio continuity | Pass | The earlier dual-core acceptance was retracted after a 139.4-second malformed-FIFO crash in the Video thread. The retained cache-direct exact-PGO app is single-core with three shader workers. It survived 22 minutes 44 seconds across combat, menus, results, and lifecycle; callbacks continued, the final interval was 59.9 FPS/VPS at queue 14/15, underruns had long flat runs, and no FIFO/desync/fatal/crash match occurred. This satisfies no sustained underrun, not locked-60 or physical-device performance. See the 2026-08-31 single-core artifact. |
| 8 | Save/memory card | Pass | Live `CODM` (macOS) and `CODX` (iPad Simulator) names were visibly recovered after clean process relaunches. SsbmPad settings were also read back after relaunch on both targets. See the row artifact. |
| 9 | Touch overlay drives gameplay | Pass | The visible overlay moved the stage cursor and P1, selected Onett, paused/resumed, produced separate X/Y jumps, and exercised A/B/Z/L/R, C-right/C-up, and all four D-pad directions during a retained match. Accessibility actions use the same touch handlers; no FIFO menu script drove the row. Prior G7 evidence proves layout edit/reset. |
| 10 | Menu system parity | Partial | G7 proves live resolution/aspect/FPS/layout/mapping/game-data/report surfaces; every action's full behavior, including import/removal boundaries, remains a G8 row. |
| 11 | Controller connect/disconnect | Partial | A fail-first regression removed the Simulator-only visibility exemption. The exact rebuilt app hides the overlay for its assigned MFi Gamepad and restores it when the setting is disabled; background/foreground retains P1 with no stuck input. Slot removal, reclaim, held-input clearing, and visibility refresh pass focused tests. An actual live disconnect/reconnect still needs observation. |
| 12 | Diagnostics export | Pass | iPad export/privacy scan pass. The rebuilt macOS launcher now exposes Export Diagnostics; its compiled exporter produced a real runner-log report with required breadcrumbs and zero private-path, game-data, disc-image, memory-card, or save matches. |
| 13 | Game data import flow | Pass | Exact GALE01 validation, 1,209-file extraction, atomic activation, visible boot, normal relaunch, and same-filename Files-folder reimport passed. See the row artifact. |
| 14 | Regression suite | Pass | All existing G5 tools plus the ported input, controller, diagnostics, performance, frame-mode, touch-layout, and game-data tests pass. |
| 15 | Clean-clone build | Pass | A fresh checkout exposed and repaired a stale Metal patch-composition hunk, then cloned every pin, extracted the exact private image, regenerated the 237-chunk module, built/signed the macOS app, and passed bootstrap, package, and repository gates. See the row artifact. |

## Next execution order

1. Close the remaining iPad interaction cluster while keeping exactly one
   Simulator booted: actual controller disconnect/reconnect and the destructive
   Game Data remove/reimport boundary. Touch and save persistence pass.
2. Continue presentation polish separately from row 7: test bounded Metal
   binary-archive/pipeline persistence against cold creation and the remaining
   Simulator presentation dips. Cache-direct exact PGO plus single-core and
   bounded shader workers is the safe comparison floor.
3. Repeat the provisionally accepted row 3 on 59.94 Hz/VRR hardware during
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

Row 6 was subsequently closed by
`docs/artifacts/2026-08-30/g8-macos-classic-three-stage-progression.md`.

Row 7 was subsequently closed at its explicit no-sustained-underrun boundary
by the source-integrated cache-direct, dual-core, and shader-worker run. The
separate Simulator presentation hitch remains open and is not a 60 FPS claim.
See
`docs/artifacts/2026-08-30/g8-ios-cache-direct-dual-core-audio.md`.

That dual-core acceptance was subsequently retracted after a 139.4-second
malformed-FIFO crash. Row 7 is safely re-closed by the 22-minute-44-second
single-core reversal, and row 9 is closed by retained every-control live play.
Row 11 remains partial. See
`docs/artifacts/2026-08-31/g8-ios-single-core-stability-and-touch-input.md`.
