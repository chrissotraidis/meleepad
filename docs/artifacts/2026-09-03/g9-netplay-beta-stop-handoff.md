# G9 netplay beta stop handoff

Date: 2026-09-03

## Purpose

Reconcile the physical-iPad work merged from another machine with the isolated
netplay work, publish one truthful stopping point, and leave the project ready
to resume without reopening completed experiments.

## Reconciled state

GitHub merge `fa9c763` contains both parents:

- `279cb5d` — accepted physical-iPad controller, menu-copy, icon, and device-
  build work; and
- `35d6058` — cross-platform canonical-netplay divergence classification,
  including the preceding live two-Mac comparator proof.

The merge fast-forwards cleanly into the local checkout. No ROM, extracted
game data, save, profile, signing material, or private path is added. The local
`scripts/summarize-phase-window.py` helper remains deliberately untracked.

## Product truth at pause

Netplay is an unfinished beta project, not a completed beta build. The current
app correctly presents **Experimental Multiplayer / Direct Connection
Preview**. It can directly host or join a peer and has a complete direct
two-Mac match proof, but the required consumer room-code experience and a
completed cross-platform mobile match do not yet exist.

B0 passes and B1 remains partial. In the latest Release iPad-host/Mac-join run,
the pair connects, becomes ready, starts the same extracted DOL, and then fails
closed at frame 120. Canonical sequence 6780 reports
`differences=timebase,ram`; PC, integer, FPR, paired-single/FPSCR, and combined
CPU hashes match. Exact comparison remains enabled.

This checkpoint does not claim:

- cross-platform completed or rematched gameplay;
- room-code creation or joining;
- physical-device or real-Internet netplay;
- NAT success, relay, security, privacy, or service operations; or
- stable 60 FPS netplay.

Solo physical-iPad cadence and accepted controller/menu work are retained in
`g8-physical-ipad-controller-copy-icon-update.md`; the separate water,
reflection, and shadow corruption remains open.

## Verification

- `git diff c62bcd0..fa9c763 --check`: pass.
- `./scripts/check-repository.sh`: pass after reconciliation.
- Runtime/process audit: no MeleePad, ModernGekko, netplay, Xcode build, or
  Simulator game process active at the stopping point.

No gameplay launch was performed for this stop-only checkpoint; earlier live
claims remain tied to their existing evidence artifacts.

## Exact resumption point

Continue B1 with one bounded diagnostic addition:

1. subdivide the aggregate MEM1 digest hierarchically so the first differing
   guest region can be identified;
2. retain the signed peer timebase delta at the same canonical sequence;
3. rerun the focused injected mismatch regressions and the same-Mac control;
4. rerun iPad-host/Mac-join, then reverse host only after the first difference
   is classified; and
5. keep exact fail-closed comparison—exclude or normalize a region only after
   evidence proves it nondeterministic and gameplay-irrelevant.

Do not begin room-code UI/service work until two consecutive five-minute
Mac/iPad direct matches complete through results and rematch in both host
directions. The authoritative remaining gates are B1 through B10 in
`docs/NETPLAY-BETA-GOAL-LOOP.md`.
