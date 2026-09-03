# G4 clean controlled match

Status: **PASS**

## Proof route

- Clean packaged `MeleePad.app`, ad-hoc signature verified.
- Native `arm64` frontend, runner, and generated GALE01 module;
  `sysctl.proc_translated` reported `0`.
- Character Select: player 1 Kirby, CPU Samus.
- Stage: Venom, timed 1v1.
- Reference FIFO commands produced visible movement, attacks, and jumps.
- The match completed and reached the Time Battle results screen with Samus
  first and Kirby second.

Retained visual evidence:

- `g4-character-select-clean.png`
- `g4-live-match-clean.png`
- `g4-results-clean.png`

## Audio evidence

The retained live process sample (`g4-audio-live-sample.txt`) shows the running
game calling `Mixer::PushStreamingSamples`, the Cubeb mixer callback, and the
CoreAudio IO work loop during the controlled match. This proves that game audio
samples traversed the active output stack. It is technical continuity evidence,
not a claim about subjective loudness at the listener position.

## Boundary

The match ran far below the required 60 FPS (about 12.5-13.0 FPS during active
combat). That does not invalidate G4 playability, but it is an immediate G5
failure and the next active loop target.
