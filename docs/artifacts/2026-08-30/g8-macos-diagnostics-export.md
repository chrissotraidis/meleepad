# G8 macOS diagnostics export

Date: 2026-08-30

Status: **G8 row 12 pass**

## Gap and implementation

The shared iPad diagnostic report already passed its live export and privacy
scan, but the macOS launcher only redirected runner output into
`Logs/MeleePad.log`; it exposed no export action. The retained ModernGekko patch
adds one bounded product path:

- a visible **Export Diagnostics** launcher action;
- a matching `--export-diagnostics` automation route through the exact same
  exporter;
- a `Diagnostics/Latest-MeleePad-Diagnostic.log` report containing the current
  runner log, capped at the newest 1 MiB;
- known game-root, user-directory, home, and temporary-path replacement plus a
  conservative macOS absolute-path fallback;
- an issue-tracker breadcrumb and explicit report/schema header.

No game image, extracted file, generated module, memory card, or save is read
into the report.

## Evidence

- The focused source regression failed before the implementation and passes
  after it: `tests/test-macos-diagnostics-export.sh`.
- Canonical patch reverse-check: pass.
- Patched dependency bootstrap reaches only the preserved user-owned one-line
  whitespace change in Dolphin `GCPadEmu.cpp`; the new patch itself composes.
- Fresh `moderngekko-launcher` Release rebuild: pass.
- Live rebuilt launcher visibly exposes the action:
  `docs/evidence/g8/macos-diagnostics-export-ui.jpg` (820x732), SHA-256
  `2250c767612b0b3ff4d19d74ab0337e0b5cef8e69a0095c5a6c110fa18e2263a`.
- The compiled exporter consumed the real current macOS runner log and wrote a
  4.7 KiB report, SHA-256
  `ec0c44ce6d4c2c279169afb5f6934a3f08ee52dc17e8da789f155c133055a82e`.
- The report contains the schema header, GitHub issues URL, Cocoa lifecycle
  warnings, static-recompiler initialization/shutdown and dispatch summaries,
  Cubeb audio selection, and controller-profile selection.
- Privacy scan: zero matches for `/Users/`, `/private/`, `/var/`, `/tmp/`,
  `/Volumes/`, extracted `GALE01/sys`, `main.dol`, memory-card/GCI paths, or
  ISO/WBFS/RVZ names.

The private generated report remains outside Git. The launcher was closed and
no MeleePad process or booted Simulator remained after verification. Together
with the retained iPad export, this closes both platforms required by row 12.
