# G8 macOS Classic three-stage progression

Date: 2026-08-30

Status: **CLASSIC-230 PASS — G8 row 6 closed**

## Question

Can the current macOS product advance through three consecutive Classic-mode
stages without a progression blocker, while retaining honest visual and frame-
rate evidence?

## Harness correction

The first diagnostic used the stale external player-table address
`0x80453080`, and every watched value remained zero. The generated revision-0
GALE01 source is authoritative for this build: its `0x8003415C` path multiplies
the slot by `0xE90` and adds `0x804510C0`. At slot `+0xB0`, it loads the live
fighter object pointer.

`scripts/gcpipe.py` now preserves complete Dolphin MemoryWatcher pointer chains
instead of truncating them to the first address. Focused tests cover canonical
chain formatting, `Locations.txt`, payload parsing, sequence collection, and
existing direct-address behavior. The live chain
`80451170 2C 1830` read Samus at 60.0 percent and then 74.0 percent; the next
slot read Pikachu at 28.0 percent. Those values matched the visible fight.

## Retained progression

The run used the local PGO macOS app, Metal, Cubeb, native EFB resolution, an
isolated user directory, and the existing FIFO controller transport. No
Simulator was booted.

1. Brinstar: Pikachu defeated Samus and reached the natural `STAGE CLEAR`
   screen with 61.00 seconds remaining. The title reported 60.0 FPS.
2. Team battle: a stationary first attempt failed and reached Continue; it is
   not counted. The retry used bounded alternating movement/jump/smash input,
   reached `STAGE CLEAR` with 268.00 seconds remaining, and reported 60.0 FPS.
3. Target bonus: the generic sweep became trapped by the course geometry, so
   it was stopped and every held button/stick was explicitly neutralized. The
   stage resolved by its normal timer and advanced into the Bowser fight,
   proving there was no progression blocker. The next fight reported 59.9 FPS.

## Evidence

- `docs/evidence/g8/macos-classic-brinstar-stage-clear.jpg`
  (`b767a2c9279edcc93f6ea252ffa25e314292f2fd52d185f3452f080aa33a41a7`)
- `docs/evidence/g8/macos-classic-team-stage-clear.jpg`
  (`b6290fd629eff9d5eebdb16ef2b838c3a41d2226c8012ef69f1008ff5bf6022e`)
- `docs/evidence/g8/macos-classic-bowser-stage-after-targets.jpg`
  (`bf9927bbf17dd35d65e66227c83728abc0a06a92954abf9f755b26c692db8af1`)

## Honest boundary

This passes PRD row 6's requirement of three macOS Classic stages with no
progression blocker. It is not a clean-visual claim: the retained stages still
show the known warped/malformed geometry and occasional character distortion.
It also does not promote iPad performance or audio continuity; G8 row 7 remains
failed/attributed.

The isolated runner was closed normally. No disc image, extracted game,
module, profile, savestate, memory card, or private user directory is committed.
