# G5 current Game Mode activation probe

Date: 2026-08-29

Status: **CURRENT PGO TOPOLOGY ACTIVATES GAME MODE; PERFORMANCE NOT MEASURED; G5 OPEN**

## Question

After PERF-171 refreshed the fastest local PGO package, does the current macOS
26.5.2 Game Policy path still recognize the product topology and turn Game
Mode on, or does package metadata merely make the runner eligible?

## Bounded probe

A signed disposable bundle copied the refreshed PGO app, retained its games
category and `LSSupportsGameMode=true`, and changed only its bundle identity
and executable to a short wrapper. LaunchServices owned that wrapper while it
kept the exact current runner as its child:

```text
wrapper PID 18597 -> SsbmPadRunner PID 18631
```

The runner used:

- current runner SHA-256
  `e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`;
- known PGO module SHA-256
  `bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`;
- private extracted revision-0 game data and an isolated private user tree;
- Metal, Cubeb, fullscreen default, and the retained EFB prewarm policy; and
- no Simulator and exactly one game process.

The probe booted only long enough to establish the policy state. No savestate,
input replay, screenshot, frame-time measurement, visual inspection, or
playability claim is attached. Current external host activity would make a G5
timing result invalid, so none was collected.

The first log-stream invocation accidentally selected zsh's `log` builtin and
failed before launch; it is excluded. The corrected stream used explicit
`/usr/bin/log`. Because the live stream was verbose, the final retained excerpt
was reconstructed from the same unified-log interval with an exact
`gamepolicyd` predicate.

## Activation evidence

The initial `paused` status occurred before the fullscreen grant. Within about
0.47 seconds, the complete transition was:

```text
Found game GameProcess(Optional("SsbmPadRunner"), ... labelReason=infoPlist)
Acquired ... IdentifiedGameGrant
Acquired ... FrontmostGrant
Acquired ... FullScreenGrant
Full screen gaming session is now active
Game mode is now available
Acquired ... ConsoleModeGrant
Game mode enabled
Enabled DPS for SsbmPadRunner
Game mode status is now on
```

The focused private Game Policy excerpt SHA-256 is
`d28899f85215ad76b0827945611dffde3c482a37656bf4e2b00415992dc3f524`.
The runner reached static-recomp core initialization and shut down with zero
runtime fallback and zero failed SMC verification. Private stderr SHA-256 is
`bcc490a9b19fe4e94a0e59329acf25601596ab35fec0db68da361847b8a09e37`.

## Reversal and decision

The runner and wrapper were terminated, the Game Policy stream was stopped,
and macOS logged the game exit plus Game Mode off/inactive transition. No game
or Simulator remains. The disposable bundle, user tree, and logs remain only
under `/private/tmp`; no game-bearing or private artifact is committed.

**Current Game Mode activation is proven for the refreshed PGO runner topology.**
This is a policy/readiness result only. It does not prove coherent rendering,
input, audio, FPS, worst-frame cadence, Fountain, Final Destination, or G5.
The next acceptance run can require the same `Game mode status is now on` line
before loading the combat state. G5 remains open and G6 remains blocked.
