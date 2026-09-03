# G9 B1 canonical-boundary candidate

Date: 2026-09-02

Result: **PARTIAL.** The repository now has a durable, compiling
canonical-boundary diagnostic candidate, but no five-minute Mac/iPad match has
passed and this does not clear B1.

## Mechanism correction

The prior execution fingerprint sampled live static-recomp state when Dolphin
handled a Pixel Engine finish event. Two hosts may reach that callback on
different native dispatch boundaries, so its PC/register differences cannot
alone prove emulated divergence.

Patch `0044-netplay-canonical-boundary.patch` instead captures state at the
configured caller-qualified guest idle boundary. SsbmPad configures the same
PC/LR pair on macOS and iPadOS. If no caller-qualified boundary exists, the
configured main-idle PC is the fallback. Capture is dormant outside netplay.

Every sixtieth boundary record contains:

- an exact boundary sequence and guest PC;
- the guest timebase at that boundary;
- combined, integer/control, scalar-FPR, and paired-single/FPSCR hashes; and
- a low-cost RAM digest over the first cache line of every 4 KiB MEM1 page.

The ordinary callback PC, timebase origin, dispatch, cycle, and burst fields
remain diagnostic context. They no longer decide equivalence. The server
compares only records with the same nonzero boundary sequence, retains at most
eight unmatched sequences, reports dropped unmatched samples, and stops after
two canonical mismatches. With two peers it reports an unknown culprit rather
than falsely blaming one endpoint. The packet-layout change bumps the
ModernGekko netplay suffix from 6 to 7.

## Fail-first and focused proof

`tests/test-netplay-canonical-boundary.sh` initially failed because patch 0044
did not exist. The completed contract verifies capture, netplay-only gating,
selected-RAM hashing, server grouping, protocol versioning, and durable
bootstrap order.

`moderngekko_netplay_protocol_test` directly proves that equal canonical
records compare equal and that independently injected integer, scalar-FPR,
paired-single, timebase, and RAM changes all compare unequal. The protocol and
two-cycle session tests pass. The two new outer patches each pass reverse-apply
checks, and the full bootstrap recognizes the complete ordered stack.

The iOS Simulator core was rebuilt from the patched source, reprovisioned, and
linked into a Release iPad Simulator app successfully. A shell-only app build
before that core rebuild is excluded as stale-core evidence.

## Two-Mac control

Two isolated macOS endpoints used the same freshly rebuilt runner, module,
game root, independent user roots, controller pipes, and direct connection.
They completed compatibility, synchronized boot, the opening movie, title,
main menu, and VS character select. P1 and P2 became independent human slots
and accepted input. There was no desync, crash, or runtime error.

The run is not a B1 pass. Slow same-M1 dual-process opening playback made the
route long, and the scripted character-selection sequence did not finish a
match before the control was ended. The configured game/caller idle boundary
is not reached during the opening movie or title/menu path, so no canonical
pair record was produced. Screenshots used only to classify this setup route
remain outside Git and are not acceptance evidence.

## Decision

Keep B1 active and do not claim cross-platform netplay. The next run must
start from clean isolated roots, drive both human slots through character and
stage selection, and retain the first canonical match or mismatch in combat.
Only after that same-Mac control is interpretable should the identical build
run iPad-host/Mac-join and reverse host. No room-code UI/service work may hide
or bypass this gate.

No ROM, extracted game data, module, save, profile, address, room code, private
path, or raw log is retained in Git.
