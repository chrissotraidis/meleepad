# DashDance replay reader

`slp.py` comes from DashDance `tools/mac/slp.py` at commit
`507ccb452137d032458e3e7e6d834e4d4d815f21` (original SHA-256
`dd7fd408c44a22eb28ecda3b0ab5f5b43e976cfdff50b3838356f6a83be7d551`).
Copyright remains with its original authors. DashDance states GPL-2.0-or-later;
the original GPL-2.0 license text is included here. MeleePad's local changes
validate raw lengths and event sizes, reject truncated/non-finite frame records,
and retain repeated rollback records alongside the finalized frame view.

`scripts/compare-slippi-replays.py` is MeleePad's command-line comparison layer.
It compares two explicitly supplied files and never searches for a Slippi account.
It does not re-simulate a replay or prove that the game ran correctly; the
reference replay must come from a separately verified source.
