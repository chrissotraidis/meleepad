# G5 static-recomp MemoryWatcher and revision-0 cold route

Date: 2026-08-25

Status: **WATCHED MEMORY FIXED; COLD ROUTE SELF-VERIFIES VS CSS**

## Static-recomp watched memory

Dolphin's ordinary `MemoryWatcher` reads through the synchronized PPC/MMU
state. Static recomp keeps the authoritative guest bytes in Dolphin's MEM1 and
MEM2 backing stores while its register state is resident in `CPUState`, so the
ordinary MMU read produced unresolved-address panics.

The retained dependency patch adds a bounded, big-endian direct reader for
cached and uncached MEM1/MEM2 aliases only while an active static-recomp module
is running. Ordinary Dolphin cores retain the existing MMU path. Watch values
are now optional so the first observed value is published even when it is
zero.

Focused regressions cover cached/uncached MEM1 and MEM2 reads, big-endian
conversion, truncated and invalid ranges, and initial-zero publication. The
test failed before implementation and passes afterward. The modified Dolphin
core and full arm64 runner link successfully.

Reproducible patches:

- `patches/moderngekko-dolphin/0004-static-recomp-memory-watcher.patch`
- `patches/moderngekko/0004-static-recomp-memory-watcher-test.patch`

## Revision-0 address correction

The first route revision incorrectly mixed GALE01 revision-1.02 decomp
addresses into the private revision-0 game image. The revision-0 generated DOL
provides the direct instruction-level mapping:

- `GameState` base: `0x80477D68`. The revision-0 getter materializes
  `0x80477D68` before loading `curr_scene_idx` at byte offset 3.
- title input lockout: `0x804D4594`. Revision-0 title entry writes 20 through
  `stw r3,-20364(r13)`, and revision-0 startup sets `r13=0x804D9520`.

The previous `0x80479D30` and `0x804D6714` addresses are revision-1.02
symbols and read unrelated revision-0 memory.

`GameState.curr_scene_idx` is a per-major-mode route index, not the global
`GameSceneKind` class. The main menu predicate is therefore `(GM_MENU=1,
route scene=0)` or masked value `0x01000000`; VS CSS is `(GM_VS=2, route
scene=0)` or `0x02000000`.

## Live cold replay

One-runner preflight selected MacBook Air Speakers to avoid the prior Jump
Desktop CoreAudio hang. MemoryWatcher was bound before launch. The retained
trace showed:

```text
80477D68=00000000
804D4594=00000000
80477D68=28002D00
80477D68=18182800
80477D68=18182801
80477D68=18182802
804D4594=00000014 ... 00000000
START at 135.25 seconds
80477D68=01011800
```

The nonzero-to-zero lockout transition prevents the boot-time zero from
triggering START early. Five-second bounded readiness windows are retained
after the menu-mode transition and after entering VS Mode because one-second
and two-second windows sent input during menu animations. The corrected route
visibly reached the four-slot Melee VS character-select screen from a cold
launch without manual gameplay input.

The original final timeout was caused by socket starvation in `gcpipe.py`, not
an incorrect game-state model. Dolphin emits an empty MemoryWatcher datagram
each frame, while the controller originally stopped reading during roughly
eleven seconds of menu delays. The client now pumps the watcher throughout
delays and watched tap holds. It also no longer requires a timing-dependent
initial GameState zero packet; the nonzero-to-zero title lockout is sufficient.

A clean retry observed `80477D68=02020100` and exited zero at 143.83 seconds.
That word proves current mode `GM_VS=2`, previous mode `GM_MENU=1`, and CSS
route index zero. The route is now fully self-verifying. Clean CSS, temporal
mesh, and Fountain timing evidence is retained in
`g5-watcher-pump-fountain-replay.md`.

Local-only diagnostic screenshots (not publication-quality because the
foreground macOS microphone permission sheet contaminated them):

- `/private/tmp/ssbmpad-g5-r0-route-after-start.png` — visible Main Menu.
- `/private/tmp/ssbmpad-g5-r0-five-second-route.png` — visible VS CSS.

The permission request was not accepted. The runner and controller process
were stopped by exact session, no Simulator was booted, and Jump Desktop Audio
was restored as the default output.
