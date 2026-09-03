# G5 confirmed-Game-Mode Fountain window

Date: 2026-08-29

Status: **60 FPS MEAN RESTORED; STRICT WORST-FRAME GATE STILL FAILS; G5 OPEN**

## Question

Does the refreshed current-PGO package meet the strict Fountain combat gate
when the input harness is quiet and the same product process is explicitly
confirmed in macOS Game Mode before state load?

## Controlled run

PERF-173 copied the ignored local `MeleePad-PGO.app` into a disposable signed
LaunchServices bundle. The wrapper stayed parent of:

- runner SHA-256
  `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`;
- current-PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- the previously verified private Fountain savestate and isolated user tree;
- Metal, Cubeb, fullscreen, EFB prewarm, and buffered render-time logging.

There was exactly one game process and no booted Simulator. Before the state
load, unified Game Policy logging recorded `Found game`, an active fullscreen
gaming session, `Game mode enabled`, and `Game mode status is now on`. The
balanced `g5-combat-cycle.json` sequence ran for 18 repeats with its progress
redirected to `/dev/null`. The runtime shut down normally with 696,674,344
native dispatches, zero fallbacks, and zero failed SMC verifications. Cubeb
was the active audio backend. macOS recorded no thermal or performance warning
before or after the run.

The private raw render log contains 4,310 rows and has SHA-256
`be587b376590d4470d4df4c28e80e94b75ea31de247b1db120eb07fd3f3faa11`.
Private stderr has SHA-256
`275c7f60900289d830d2ff50f63c1c93683325edf3f2af87c62fd7c675af3066`.
The final focused Game Policy log has SHA-256
`1be6f1e7a5b44872d9a57c6cf27029db6d68b813caef88bb02fc7a9bc63c0951`.
No game data or private runtime artifact is committed.

## Exact final 2,001 rows

Rows 2,310 through 4,310 measure:

```text
mean             16.666485736 ms
FPS from mean    60.000651
median           16.666500000 ms
p95              16.807334000 ms
p99              16.916375000 ms
worst            17.477083000 ms
<= 16.7 ms       1,384 / 2,001 (69.165417%)
> 17 ms          15
> 20 ms          0
> 33 ms          0
```

The large boot/state-load row is outside this final window. Each of the twelve
largest rows with an available successor is followed by a shorter interval;
the worst 17.477083 ms row is followed by 15.861250 ms. This repeats the
delayed/catch-up shape while eliminating the earlier 20-33 ms severe stalls.

## Visual boundary and decision

No fresh screenshot was requested through UI automation during this run, so
PERF-173 does not make a new visual-coherence or fighter-warp claim. The same
current-PGO binary, private state, and input path retain the separate PERF-167
framebuffer evidence, but that evidence is not relabeled as a fresh endpoint.

**Fountain does not pass G5.** Confirmed Game Mode plus the quiet harness
restores an exact 60 FPS mean and removes severe stalls in this window, but
`17.477083 > 16.7` ms. Do not run Final Destination or begin G6. The remaining
measured defect is a small residual producer-cadence tail, not sustained
static-recompiler, GPU, audio, or thermal under-speed. No product source or
setting changed.
