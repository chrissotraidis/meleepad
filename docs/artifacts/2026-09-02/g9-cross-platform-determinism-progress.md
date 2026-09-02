# G9 cross-platform netplay determinism investigation

Date: 2026-09-02

Result: **PARTIAL.** Native iPad-host/macOS-join netplay now boots and runs far
beyond the original frame-60 failure, but an exact emulated-timebase mismatch
still stops the pair at frame 6,240. This is not a cross-platform gameplay pass.

## Instrumented baseline

Dolphin patch `0042` records every mismatching frame's player IDs and reported
emulated timebase. ModernGekko patch `0016` retains those records in the native
session error, so the match-ended UIKit recovery presents the evidence rather
than a stale final drawable.

With the original iPad path, which supplied an imported ISO while the Mac peer
booted the extracted DOL, the repeated paired run reported:

- frame 0: host `34086830090828572`, join `34086830102998645`, gap `12,170,073`;
- frame 60: host `34086830190078551`, join `34086830209541113`, gap `19,462,562`.

The native match-ended callback visibly reopened Online Play and displayed the
exact error. This closes the stale-drawable recovery observation from the NL4
first-slice artifact.

## Rejected single-core control before boot alignment

Changing only `MAIN_CPU_THREAD` from true to false reproduced effectively the
same result:

- frame 0 gap `12,170,977`;
- frame 60 gap `19,462,560`.

The candidate was reverted. The near-identical values reject unlike-platform
dual-core scheduling as the cause of the large immediate divergence.

## Boot-path mechanism and reversal

`Runtime::Run` chooses `RuntimeConfig::disc_image` over the inspected
`metadata.main_dol`. The native iPad session populated `disc_image` whenever an
imported ISO existed, while the reusable session selected, fingerprinted, and
started `game_root/sys/main.dol`; the isolated Mac peer also booted that DOL.

The iPad netplay configuration now deliberately leaves `disc_image` empty so
every peer boots the selected extracted DOL. Solo play still retains its ISO
path. This one-variable change moved the desync from frame 60 to frame 6,240.
The pair visibly advanced through the opening and title/attract sequence, and
the iPad overlay reported 59.9 FPS. The Mac process reported zero network wait,
although two-emulator contention produced unstable local FPS.

The later exact error was:

- frame 120: host `34086859491094893`, join `34086859491081612`, gap `13,281`;
- frame 6,180: host `34086863719181247`, join `34086863719180001`, gap `1,246`;
- frame 6,240: host `34086863759577487`, join `34086863759577497`, gap `-10`.

Only frames with unequal values are retained. Dolphin stops after two
consecutive mismatches; the old frame-120 record is diagnostic history, while
frames 6,180 and 6,240 caused the stop.

## Rejected single-core control after boot alignment

Serializing CPU/GPU emulation on top of the aligned-DOL fix again stopped at
frame 6,240. It reproduced the exact frame-120 gap of `13,281`; the final two
gaps were `2,784` and `2,794`. The candidate was reverted. Exact timebase
comparison remains intact; no tolerance was added.

## Exact-source module control

The Simulator module is a fresh `-O2`, ThinLTO, strict-floating-point build
from the current 237 generated C chunks. The isolated Mac fixture initially
used the older promoted PGO module. A private macOS control module was rebuilt
from the exact same generated source and policy as the Simulator module and
validated as GALE01 ABI 3 with 237 chunk ranges.

That pair crossed the old frame-6,240 boundary and reached visible combat. The
iPad overlay ranged from 59.8–60.0 FPS in the opening and later showed roughly
36 FPS during combat; no 60 FPS claim passes. The pair ultimately stopped on an
exact timebase mismatch at frame 7,440. Matching module provenance therefore
improves the boundary but does not close determinism.

The next gate is instruction-level static-recomp lockstep around the first
reproducible 13,281-tick frame-120 divergence. Do not repeat ISO/DOL,
single-core, broad PGO, network-delay, or checksum-tolerance experiments
without contradictory evidence.

No ROM, module, profile, save, or private path is retained in the repository.
