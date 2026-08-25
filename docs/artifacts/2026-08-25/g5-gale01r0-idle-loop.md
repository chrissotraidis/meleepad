# G5 GALE01r0 static-recomp idle loop

Date: 2026-08-25

Status: **OPTIMIZATION RETAINED; G5 STILL OPEN**

## Attribution

The previously hottest profile symbol, `loop_80349494`, was first treated as
an unknown generated polling helper. The supplied disc is GALE01 revision 0,
and the nearby public Melee maps in this checkout target revision 2, so their
addresses cannot be applied directly.

The actual revision-0 generated source is:

`ref/ModernGekko-Template/extracted/Super-Smash-Bros-Melee-GALE01-r0/recomp-smc/generated/chunks/chunk_0209_text1_80345940.c`

At `0x80349494`, it is the scheduler's idle loop: after interrupts are enabled,
the code repeatedly checks `RunQueueBits == 0` while no runnable thread exists.
The retained Fountain profile entered the function 135,977,937 times and
executed roughly 11.693 billion internal blocks, or about 86 iterations per
256-cycle return to the host dispatcher.

ModernGekko already exposes the intended mechanism:

- `StaticRecompIdlePC` is parsed in
  `Source/Core/Core/Config/StaticRecompSettings.cpp`;
- `StaticRecompCore_Run.cpp` calls `CoreTiming().Idle()` when the guest PC
  reaches the configured idle address.

The retained dependency patch adds only:

```ini
[Core]
StaticRecompIdlePC = 0x80349494
```

to Dolphin's existing `GALE01r0.ini`. No ROM, save, generated module, or
profile data is changed or distributed.

## Native observations

With the retained Fountain-PGO module and the idle PC enabled, an equivalent
native attract run retired 356,219,583 dispatches and 21,656,575,885 guest
cycles. `0x80349494` disappeared from the shutdown top-dispatch histogram;
comparable pre-change runs commonly retired roughly 750-800 million dispatches
and 57-61 billion guest cycles.

On the first 1,000 frames after a 500-frame warm-up, the matched PGO screen was
mixed rather than a G5 pass:

| Metric | PGO + idle PC | Prior PGO control | Result |
|---|---:|---:|---|
| Mean | 16.682979 ms | 16.682977 ms | unchanged |
| Median | 16.704313 ms | 16.684126 ms | slightly worse |
| p95 | 17.823916 ms | 18.076584 ms | better |
| p99 | 18.185666 ms | 18.720125 ms | better |
| Worst | 18.987083 ms | 19.088334 ms | better |
| Frames <= 16.7 ms | 49.80% | 50.80% | slightly worse |
| Frames > 40 ms | 0 | 0 | unchanged |

The profile-free module confirms that the idle setting is not a substitute for
active-combat optimization. Its retained 9,147-frame run visibly progressed
through cinematics and four-player attract gameplay. The first 1,000 frames
after a 500-frame warm-up measured 16.691386 ms mean / 17.007000 ms median /
24.516417 ms p95 / 25.528000 ms p99 / 28.396833 ms worst. Later active scenes
were visibly around 40-55 FPS, with Jungle Japes observed at 16.9 FPS.

Raw profile-free evidence:

- `g5-clean-idle-attract-render-times.txt` — SHA-256
  `48d04ee9d32f625cdd28963d7e86ea76d64ea0d7fe35e7b168355928bae204a7`
- `g5-clean-idle-attract-vblank-times.txt` — SHA-256
  `32cb8d9b9a58178d582d479f19e7bd9c05f8427d11d5239344f353a70b5480bc`

## Controller and required-stage boundary

An isolated one-port profile was validated live: P1 selected Bowser, changed
P2 from N/A to level-1 CPU Mario, reached Ready to Fight, and entered stage
select. An old exploratory stage-cursor sequence landed on Battlefield rather
than Final Destination; the visible three-platform layout rejected that run.
The production PGO module plus idle PC showed 18.8 FPS at the Battlefield
countdown. This is useful failure evidence, not a required-stage result.

The title automation also exposed a distinction between Melee's title card
inside the opening movie, its true input-ready title screen, and subsequent
attract playback. Fixed-delay inputs are not accepted as deterministic stage
automation until they are gated on the actual interactive prompt.

## Decision

Retain the GALE01r0 idle-PC configuration because it removes a proven dominant
idle workload through an existing static-recomp facility. Do not claim G5:
profile-free active combat is still far below 60 FPS, and the PGO screen still
exceeds 16.7 ms at p95, p99, and worst.

The next PGO corpus must be collected from visually verified Fountain and
Final Destination combat with idle skipping already active. That prevents the
scheduler loop from dominating the profile and avoids repeating the rejected
idle-contaminated Fountain/Final Destination merge.
