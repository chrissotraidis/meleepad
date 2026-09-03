# G8 iPad game-data import

Date: 2026-08-30

Matrix row: **13 PASS**

## Result

The iPad Pro 13-inch (M5) Simulator on iOS 26.5 imported the user's exact
GALE01 revision-0 disc, validated its identity, extracted and activated the
Melee data atomically, and booted visible game frames from the retained
sandbox image. A subsequent ordinary launch without the test hook booted from
the sandbox again. A same-filename reimport from the Files-visible MeleePad
Documents folder repeated validation, extraction, activation, runtime creation,
and visible boot successfully.

## Defects found and fixed

The first live import correctly rejected the image, revealing that the port
still embedded Sunshine's SHA-256. The selected file independently matched all
of the already-pinned MeleePad invariants:

- size: 1,459,978,240 bytes;
- SHA-256: `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`;
- game ID: `GALE01`;
- disc: 0; and
- revision: 0.

Source inspection then found two more Sunshine-only activation checks: 174
files and `AudioRes/mSound.asn` / `data/common.szs`. The MeleePad app now uses
the pinned GALE01 hash, requires 1,209 regular game files, and checks Melee
anchors including `GmRegEnd.dat`, character/stage-select data, Fox data, and a
stage archive. The repository regression rejects reintroduction of all three
Sunshine invariants.

## Live verification

The first corrected import retained a private sandbox ISO with the exact size
and SHA-256 above. Its extracted tree contained 1,209 files and all required
system/game anchors. Logs recorded:

- `game data import activated filename=GALE01.iso`;
- `rootSource=sandbox currentRootExists=1`;
- `discImage=1 moduleExists=1`;
- `runtime frame mode=native 60 FPS source=GALE01`;
- `runtime created`; and
- `input pipe connected attempt=1`.

The normal relaunch repeated sandbox boot and runtime creation without the
`-meleepadImportTest` hook. The Files-visible same-filename reimport then
activated the image again at 05:14:14 and created the replacement runtime at
05:14:28. The active image remained byte-identical and the extracted file
count remained 1,209.

Retained visual evidence:

- `docs/evidence/g8/ipad-import-boot.png`
- `docs/evidence/g8/ipad-import-relaunch.png`
- `docs/evidence/g8/ipad-files-reimport-boot.png`

## Cleanup and boundary

The extra ISO staged in the Files-visible Documents folder was removed after
reimport, recovering its space. The original user ISO and the active private
Simulator import remain available for subsequent save/control tests. No ISO,
extracted file, generated module, save, or container path is tracked. The app
was terminated and the sole Simulator shut down.

This passes row 13 only. Failed-import rollback and removal/save preservation
remain useful hardening work under rows 8 and 10; they are not silently
promoted by this result.
