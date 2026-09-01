# G8 iOS Simulator savestate trigger boundary

Date: 2026-09-01

Status: **CAPTURE PREREQUISITE PASSED; ROW 7 STILL FAILS**

## Why this boundary was necessary

The retained Big Blue failure is randomized attract content. An eight-minute
no-recorder diagnostic run did not encounter its exact projection hash,
`002a81fb84e3f68f`. Waiting longer would not make the experiment reproducible.
The next useful optimization requires the exact slow scene to be captured once,
then replayed repeatedly with matched phase and dispatch evidence.

The existing default-off ModernGekko signal harness did not satisfy this on
iOS Simulator: both its handler implementation and installation were guarded
by `!MODERNGEKKO_HAVE_IOS`, so `SIGUSR1`/`SIGUSR2` were compiled out on
Simulator along with physical iOS.

## Narrow correction

Patch `patches/moderngekko/0012-ios-simulator-savestate-signals.patch`
defines the signal boundary for non-Windows desktop hosts and Apple Simulator.
It remains excluded from physical iOS and remains inert unless
`MODERNGEKKO_ENABLE_SAVESTATE_SIGNALS=1` is explicitly set. The product menu
and default runtime are unchanged.

`scripts/capture-projection-trigger.py` tails a runtime log from its current
end, requires an exact 16-hex-digit `projectionHash` match, sends `SIGUSR1`,
captures a Simulator screenshot, waits for the savestate timestamp to change,
and writes the exact triggering runtime row to JSON. It times out without an
action when the hash does not appear.

## Live proof

A Release iOS Simulator build launched on the sole booted iPad Pro 13-inch
(M5) Simulator with only the save-signal opt-in enabled.

- `SIGUSR1` created a 9.3 MB `GALE01.s01`; the app remained alive.
- `SIGUSR2` returned while the app remained alive and continued advancing.
- The generic trigger correctly timed out on an absent hash without signalling.
- A second run matched recurring title hash `4be288c01ed3ebd5` at 59.9 FPS,
  captured a screenshot, updated the savestate to 22 MB, wrote the exact row,
  and left the app alive.
- The trigger metadata reported `savestateUpdated=true`.

Private proof retained outside Git:

- trigger JSON SHA-256:
  `7416a5e65aabeb51e187c15c7946403b7fd9f3dd7637f788669d0c17b5402f54`;
- trigger screenshot SHA-256:
  `939c59d46807d49b8bbd7d62d29250b91964815f5583515fa97c1c24247a0054`;
- updated savestate SHA-256:
  `876dea92ebe379f871e8e56840f59f011cc1a3fbaf3a792d58d109ce8c81d1`;
  and
- complete runtime log SHA-256:
  `44843bedc57f89886813eff40b96fd790b6634a05ce066be1b832e0cdd20a403`.

No ROM, generated game source, module, save, screenshot, or private path is
tracked. The diagnostic app was stopped and the signal environment cleared.

## Reoriented decision

This work does not improve FPS and cannot pass row 7. It makes the next
performance decision falsifiable:

1. arm phase and sparse burst logs plus the exact Big Blue trigger;
2. retain the first no-recorder Big Blue state and its aligned evidence;
3. replay that state on the unchanged control;
4. if it holds near 60 FPS after replay/warmup, pursue cold resource/state
   creation rather than generated-code architecture; or
5. if it repeats roughly 21-35 FPS with CPU saturation and the complete
   8.11-million-cycle frame workload, use its actual paths as the corpus for
   broad register-resident generated C.

Sixty FPS is known to be possible on this Simulator for many moving scenes,
including a warmed four-player Hyrule match. It is not yet proven possible for
the retained Big Blue and Fountain worst cases. The exact capture/replay is the
shortest experiment that distinguishes an optimizable cold-state pathology
from a roughly two-times static-CPU throughput deficit.
