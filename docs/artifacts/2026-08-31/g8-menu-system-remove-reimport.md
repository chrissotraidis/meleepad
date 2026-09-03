# G8 menu-system remove and reimport closure

Date: 2026-08-31

Status: **row 10 pass**

## Target and boundary

Target: iPad Pro 13-inch (M5) Simulator, iOS 26.5, Release arm64,
GALE01 revision 0, source revision
`1562458c26b383a231ee97946edf5998418235ad`.

This run closes the only destructive menu boundary left after the G7 shell
acceptance and the earlier full import/reimport row. Before invoking removal,
the active image was APFS-cloned to a private temporary path and verified as:

- 1,459,978,240 bytes;
- SHA-256 `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`.

The private backup, game image, extracted files, and save remain outside Git.

## Live removal result

Through the visible three-dot menu:

1. Open `Game Data & Saves`.
2. Select `Remove Stored Game Data`.
3. Observe the confirmation explaining that the retained image and extracted
   files will be removed while saves and control settings are preserved.
4. Select the destructive `Remove` action.

The app logged `runtime stop requested` followed by `stored game data removed`.
The complete `GameData` directory was absent afterward. MeleePad remained open
and showed its legal first-run state: no bundled game files and a visible
`Choose ISO or GCM` action. The memory-card file remained under the separate
`GC/USA/Card A` directory.

## Live folder reimport result

The verified backup was cloned into the Files-visible MeleePad Documents folder.
Through the visible menu, `Import from MeleePad Folder` found the sole image and
entered the real validation/copy/extraction flow. The progress alert advanced
through live file names and then dismissed into visible game boot.

Post-activation checks:

- retained image size: 1,459,978,240 bytes;
- retained image SHA-256:
  `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`;
- extracted regular files under `GALE01/files`: exactly 1,209;
- stale `GameData.import-*` directories: zero;
- runtime log: `game data import activated filename=GALE01.iso`;
- visible boot resumed;
- memory-card GCI remained present outside `GameData`;
- temporary Files-folder source removed after activation;
- private temporary backup retained for recovery.

## Remaining menu entries

Combined retained evidence now observes every row-10 entry:

- Native through 4x render menu and live 2x EFB application;
- Original, 16:9, and Fill aspect menu and live 16:9 application;
- FPS counter on/off;
- Experimental Performance Mode on/off with the correct `Restart Required`
  explanation; final value restored to off;
- controller mapping sheet;
- touch settings, layout edit, and reset;
- document-picker import/reimport, MeleePad-folder import, and stored-data
  removal/recovery;
- privacy-bounded Report a Problem share sheet.

Rows 13 (import) and 12 (diagnostics) remain independently evidenced; this row
only consolidates that each menu entry actually functions. Row 10 passes.

## Retained screenshots

- `screenshots/2026-08-31/g8-game-data-removed-setup.jpeg` — SHA-256
  `0992360787aba0aa18efa65edbad67bef5ad0c2188cdd57e6130038b79c60f42`;
- `screenshots/2026-08-31/g8-game-data-reimported-boot.jpeg` — SHA-256
  `38f83d7e1754d99ea1e60a8bc6620745303fe80a1f4dacff46e76fea3c43e0c5`.

## Decision and next gate

G8 row 10 passes. Row 11 is the sole non-waived partial row: the Simulator
session proves controller assignment, overlay hiding, setting-driven restore,
foreground retention, and focused disconnect/reclaim semantics, but an actual
live controller disconnect/reconnect still has not been observed. Do not begin
G9 until that final G8 interaction boundary closes.
