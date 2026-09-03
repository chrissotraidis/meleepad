# G5 FP-gate fast path and static-recomp watcher audit

Date: 2026-08-25

Status: **FP CANDIDATE REJECTED; WATCHED MEMORY FIXED; VISUAL-001B REOPENED**

## FP candidate

The fresh combat profile identified `ppc_fp_available` as the hottest named
runtime helper. A local DolRecomp candidate preserved the existing
FP-unavailable exception path but first tested the common `MSR.FP` enabled
state inline. Generated C contained the inline gate in 230 chunks and no old
unconditional helper gate. The complete macOS 14 arm64 O2 + ThinLTO module was
83,679,448 bytes with SHA-256
`b98556e40e15a5cc5bc99850eebe24855f0640cbf67d191e398bec71fee5b74a`.

Focused DolRecomp verification passed the generated-C compile contract,
generated-C execution, and full PowerPC reference semantics tests.

The proof-quality comparison excluded the first 500 frames and measured the
next 1,000 frames from cold no-input launches with the same native runner,
isolated user directory, Metal configuration, Cubeb backend, and profile-free
module class.

| Render metric | Inline FP gate | Unchanged control | Result |
|---|---:|---:|---|
| Mean | 16.684606 ms | 16.687545 ms | candidate slightly better |
| Median | 16.735354 ms | 16.834688 ms | candidate 0.6% better |
| p95 | 19.978833 ms | 20.622458 ms | candidate 3.1% better |
| p99 | 20.853667 ms | 21.597083 ms | candidate 3.4% better |
| Worst | 34.777000 ms | 27.987041 ms | candidate 24.3% worse |
| Frames <= 16.7 ms | 49.20% | 49.80% | candidate 0.6 points worse |
| Frames > 40 ms | 0 | 0 | tied |

Vblank p95 improved from 22.574917 to 21.908083 ms, but its worst value also
regressed from 32.368792 to 39.045375 ms. The candidate additionally ran
four-player intro/demo scenes at only about 45-48 FPS. It therefore does not
meet G5 and fails the loop's strict worst-frame retention rule. The DolRecomp
source and reproducible patch-stack entry were removed; the candidate dylib
remains only under `/private/tmp` for forensic comparison.

Raw evidence:

- `g5-fp-fast-path-clean-render-times.txt` —
  `acf766f1389a78f2489a600d36c3abe0437b18e8f75456a9de7ae5f8f78c1ab3`
- `g5-fp-fast-path-clean-vblank-times.txt` —
  `eaafab880c3557c41e85a335c7e9702327e3199545461ff901e47a2314bdde86`
- `g5-profile-free-matched-fp-control-render-times.txt` —
  `292275db73f2c96db92d73d2a73621f9ab7dd5679d27a43b30c651b582ff6246`
- `g5-profile-free-matched-fp-control-vblank-times.txt` —
  `6975cb98f2047393f1e40a6eba289d5e41d82dd6ac662bf59607b506801f4d77`

The longer exploratory candidate traces are retained separately because they
contain the four-player 45-48 FPS scenes, but they are not a matched decision
pair:

- `g5-fp-fast-path-attract-render-times.txt` —
  `e4d14c07542d5bfffd2701e8f8fbe6c0a923457bf011c99db6cbac2d4a383819`
- `g5-fp-fast-path-attract-vblank-times.txt` —
  `aeab6c16edf18799bbc683024f1cd08a88b2291d520218c42ab7db3db0bb4a87`

## Fresh mesh-warp recurrence

During the candidate's four-player Pokémon Stadium montage, one retained
frame showed the orange fighter stretched into an implausibly thin vertical
shape above Captain Falcon while nearby fighters remained coherent. This is a
fresh occurrence of the user's real-body report, so `VISUAL-001B` is reopened.

- `g5-fp-fast-path-attract-mesh-warp.jpeg`
- SHA-256
  `47831e1fb4862e66221c3772fda55c7425848e70e890f2127b08bf09c81fb099`

The attempted adjacent-frame capture was contaminated by the foreground Sound
settings window. A subsequent 15-second Fountain capture showed coherent
fighters but did not include the same occurrence. An unchanged profile-free
replay sampled a different four-player sequence and showed coherent bodies at
about 44.9 FPS. The recurrence is therefore real enough to track but not yet
attributed to the FP experiment, static recompilation, the renderer, or a legal
single-frame animation. It blocks promotion until an uncontaminated adjacent-
frame recurrence or a reference-matched sequence classifies it.

## MemoryWatcher route

The lockout-aware title-to-CSS sequence emitted no input because Dolphin's
ordinary `MemoryWatcher` attempted to read the static-recomp guest addresses
through an unsynchronized MMU state and reported:

```
Unable to resolve read address 80479d30 PC 888
Unable to resolve read address 804d6714 PC 888
```

A local direct-MEM1 read experiment compiled and removed those panic lines,
but its freshly linked runner then hung while CoreAudio instantiated the Jump
Desktop output device. Closing that window did not terminate the runner; a
second launch briefly created two runner processes before the stale PID was
noticed. Both exact MeleePad PIDs were terminated, all experimental source was
restored, Jump Desktop Audio was restored, and no runner or Simulator remains.

The next watcher experiment must first expose a unit-testable static-recomp
MEM1 reader, ensure an initial zero value is transmitted, use the built-in
speaker for the fresh runner, and prove the first watched values before any
controller action. Process count must be checked after every close and before
every launch.

Follow-up completed those prerequisites. The direct bounded reader and initial
zero publication are packaged and tested, and the cold replay exposed and
corrected mixed revision-1.02/revision-0 route addresses. A later client fix
drains empty watcher datagrams during menu delays; the route now exits zero on
`GameState=0x02020100` and self-verifies VS CSS. See
`g5-static-recomp-memory-watcher-route.md` and
`g5-watcher-pump-fountain-replay.md`.
