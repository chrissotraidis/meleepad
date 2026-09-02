# G8 human acceptance capture harness

Goal: G8 row 7  
Verdict: **capture path verified; human route still required**

## Gap

The remaining row-7 gate must be driven by a person and must retain one
continuous visible recording plus the matching complete runtime log. Existing
diagnostic and automation tools either drove input, observed UI state, or
captured only a focused interval. None bound the ordinary installed Release,
full-screen evidence, runtime rows, and immutable identities into one
operator-controlled run.

## Implementation

`scripts/run-g8-human-acceptance.sh` now:

- requires one booted Simulator, or an explicitly selected booted UDID;
- rejects forwarded SsbmPad and DYLD diagnostic environment;
- identifies and hashes the already-installed executable;
- terminates the prior app, begins HEVC recording before launch, and launches
  the ordinary `com.ssbmpad.SsbmPad` product;
- performs no screenshot, accessibility query, UI polling, private input,
  savestate, MemoryWatcher, or profiler action;
- waits at an interactive terminal while the person supplies every input;
- stops and finalizes recording after the operator confirms results and menu
  return, then terminates the app;
- copies the same-session runtime log and every performance row outside Git;
- reports FPS/VPS/speed threshold counts, audio callbacks, DMA underruns,
  wall duration, and SHA-256 identities; and
- explicitly marks captures shorter than five minutes ineligible and never
  declares row 7 passed automatically.

The cleanup trap stops the recorder and terminates an app launched by the
harness if the terminal closes or the operator interrupts the run.

## Verification

The focused source contract passes and is part of
`scripts/check-repository.sh`. A live 15-second pseudo-terminal smoke on the
sole booted iPad Pro 13-inch (M5) Simulator verified the real capture path:

| Artifact | Result |
|---|---:|
| HEVC | finalized, 1,942,391 bytes |
| Runtime log | copied, 1,804 bytes |
| Metadata | commit, UDID, bundle, executable/video/log hashes, UTC bounds |
| Orphaned app/recorder processes | 0 |
| Exit | 0 |

The smoke is deliberately **not acceptance evidence**: it has zero ten-second
performance reports and a 15-second wall duration. Its private video/log stay
under `/private/tmp` and outside Git.

A second live interrupt smoke sent Ctrl-C at the operator prompt. The corrected
handler stopped both processes and exited immediately with status 130. A final
short completion smoke emitted `minimum_capture_duration_met=0` and the visible
`INELIGIBLE` warning while still finalizing its evidence. These two branches
cover both abandonment and premature completion without weakening the manual
gate.

## Operator route

Run:

```sh
./scripts/run-g8-human-acceptance.sh
```

The person must navigate the normal opening and menus, visibly configure P1
Samus versus level-1 CPU Kirby with Stock/04 and 05:00, select Fountain of
Dreams, play for at least five uninterrupted combat minutes with music and SFX,
reach results, return to the menu, and only then press Return in the terminal.

Review must phase-align the complete video and runtime rows and apply the
written pessimistic thresholds. Any visible slowdown, input lag, audio breakup,
corruption, crash, or numeric miss returns the loop to exact-interval
attribution. Only a clean route can close row 7 and open physical-device work.
