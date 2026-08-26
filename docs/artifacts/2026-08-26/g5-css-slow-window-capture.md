# G5 CSS-armed intermittent slow-window capture

Date: 2026-08-26

## Question

Can the user-reported major menu slowdown be captured without mistaking cold
boot, the opening movie, or diagnostic observer cost for a menu regression?

## Trigger

A default-off extension to the existing phase logger retains a 60-frame
rolling total. When that interval falls below 55 FPS it flushes the buffered
CSV once and writes a small marker. `g5-capture-slow-window.sh` waits for the
marker, copies the flushed marker and phase file, and only then takes a
10-second native sample.

The acceptance run used the earlier wrapper order, which started sampling
before copying. Its retained CSV therefore contains later observer-loaded rows;
all acceptance calculations above are explicitly truncated at the marker,
frame 26106. The retained wrapper now copies first, and passed `bash -n`.

The trigger can ignore a fixed startup prefix and, more importantly, remain
unarmed until an external file exists. In the acceptance run MemoryWatcher
completed the genuine title-lockout route and proved four-slot VS CSS before
the arm file was created. The product path is unchanged unless all diagnostic
environment variables are set.

Two pre-acceptance catches were excluded:

- a transient 14.3 FPS title reading was startup averaging dominated by 3.23 s
  and 1.65 s cold frames;
- a 50.3 FPS window at frame 1350 occurred about 22 seconds into the
  134-second opening/title sequence, before any menu gate.

## Verified CSS result

After more than four minutes of armed CSS, frame 26106 triggered at a rolling
54.9185 FPS. The exact 60-frame window was:

| Metric | Result |
|---|---:|
| Mean / median | 18.208815 / 16.677500 ms |
| p95 / p99 / worst | 22.885869 / 50.731085 / 70.343792 ms |
| CPU-thread mean / worst | 9.639864 / 13.122329 ms |
| Throttle wake lateness mean / p95 | 0.871364 / 1.247012 ms |
| Video build mean / worst | 0.063315 / 0.170875 ms |
| Present mean / worst | 0.026960 / 0.452083 ms |
| Audio mean / worst | 0.657868 / 1.758834 ms |
| Guest cycles mean | 8,107,477 |
| Native dispatches mean | 66,976 |
| Fallback steps | 0 |

Only three frames in the trigger window exceeded 25 ms:

| Frame | Total | CPU wall | CPU thread | Video | Present |
|---|---:|---:|---:|---:|---:|
| 26103 | 70.344 ms | 76.020 ms | 11.281 ms | 0.156 ms | 0.047 ms |
| 26104 | 37.102 ms | 37.308 ms | 11.749 ms | 0.102 ms | 0.452 ms |
| 26106 | 33.618 ms | 33.381 ms | 12.975 ms | 0.094 ms | 0.014 ms |

Guest cycles, dispatches, bursts, fallbacks, video, presentation, and audio did
not surge. The decisive frames lost time while the CPU thread was not on-core;
this is a host scheduling/preemption hitch cluster, not a renderer or generated
compute collapse.

Across post-arm frames 9000-26106, the worst rolling rates were:

| Window | Worst FPS |
|---|---:|
| 1 second | 54.918 |
| 2 seconds | 57.316 |
| 5 seconds | 58.866 |
| 10 seconds | 59.399 |

This reproduces a visibly meaningful one-second hitch cluster, but not a
sustained 12-15 FPS menu state. The native sample begins after the trigger and
therefore is supporting post-trigger state evidence, not attribution for the
three already-finished hitch frames. It finds normal static-recompiler work
with the known scheduler idle loop at the top; it does not justify changing
that loop again.

## Decision

**INTERMITTENT CSS HITCH CLUSTER REPRODUCED; SUSTAINED MAJOR COLLAPSE NOT
REPRODUCED; DEFAULT-OFF TRIGGER RETAINED; G5 OPEN; FINAL DESTINATION NOT RUN;
G6 BLOCKED.** Do not retry focus/activity flags, timers, or idle-loop shortcuts.
The next performance step must address the strict required-stage tail or
capture a genuinely sustained menu interval; this event does not support a
renderer, audio, or guest-compute rewrite.

## Retained files

- `g5-css-slow-window-phase.csv` — SHA-256
  `08d6732c9a5a0b2645b3ed322cc76ce583ceb74a575b95f13e16af7343ce4af3`
- `g5-css-slow-window.sample.txt` — SHA-256
  `acc8d543bbae2947d6fab267bf7f8f6fd292d965c210931dc12138921a72b7c8`
- `g5-css-slow-window-marker.txt` — SHA-256
  `39069be5fbb9b4cc25aeb83d9ebafed0a35f9583997f7c56482d41c29bc54ac5`
