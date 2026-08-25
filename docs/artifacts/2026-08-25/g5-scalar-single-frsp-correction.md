# Scalar-single and `frsp` correction

Date: 2026-08-25

This is the implementation and measurement follow-up to
`g5-independent-scalar-single-review.md`. It records a correctness candidate,
not closure of `VISUAL-001B` or G5.

## Retained source change

- DolRecomp's C emitter now routes `fadds`, `fsubs`, `fmuls`, `fdivs`, and
  `frsp` through GXRuntime's exact helpers and implements Rc by copying FPSCR
  status into CR1.
- Those helpers write the rounded scalar result to both `fpr[d]` and `ps1[d]`.
- The hot helper internals are marked always-inline without weakening their
  ForceSingle/Force25Bit, exception, suppression, FPRF, FI/FR, or NI behavior.
- Focused generated-C tests seed lane 1 with a sentinel for all five operations
  and check CR1/FPSCR. GXRuntime tests cover Force25Bit, SNaN and invalid
  behavior, divide-by-zero, VE/ZE write suppression, FPRF, NI flushing, and
  both destination lanes.

The repository retains these ignored-dependency edits as reproducible patches:

- `patches/dolrecomp/0001-scalar-single-semantics.patch`
- `patches/moderngekko-dolphin/0007-gxruntime-scalar-single-semantics.patch`

Both apply after the pinned dependency series in a clean temporary checkout.
DolRecomp passed 14/14 tests and GXRuntime passed 1/1.

## Generated-source audit

The corrected GALE01 source identity suffix is `e02b042a2f09321f`. Counts are
3,551 `fadds`, 6,576 `fsubs`, 6,387 `fmuls`, 1,186 `fdivs`, and 1,237 `frsp`
helper calls. There are zero remaining old inline scalar-single or `frsp`
forms. This audit caught and excluded one initially stale generation tree.

The portable profile-free macOS 14 arm64 module is retained outside Git at:

`/private/tmp/ssbmpad-scalar-frsp-module-v2/GALE01/0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448-e02b042a2f09321f/gGALE01_recomp-macos14.dylib`

SHA-256: `455de1474ee935e279273c25a56f6d537794765c1c755b93e9c0ff64d922a5e1`.
It is arm64, has macOS 14 minimum deployment, valid ad-hoc signing, and the
required runtime exports.

## Runtime correctness evidence and boundary

A broad bounded lockstep run reached 1,402 checks and retained 84 reports.
The reports include known unrelated noise and a double-precision FPSCR
mismatch at `0x80320F5C` to `0x8033EF78`; none of the first 20 implicated stale
`ps1`. A targeted window for an actual corrected `frsp` call at `0x80006094`
did not execute on the cold Fountain route. Therefore lockstep is useful
negative evidence but is **not** claimed as targeted `frsp` coverage.

Two subsequent controller retries stopped at CSS because the recorded cursor
assumptions were stale and did not create the intended CPU opponent. They are
excluded from match evidence.

The corrected profile-free module produced 200 consecutive app-window PNGs at
about four captures per second in:

`/private/tmp/ssbmpad-frsp-demo.HjbC6b/adjacent-200`

The four contact sheets are under that run's `contact-sheets/` directory. The
corpus includes 42 gameplay frames with Peach and a complete Peach cinematic;
all 200 are coherent. The old failing corpus still shows impossible Peach
hair/arm spikes at frames 176-184 and recovery by 186. Because the corrected
corpus did not recreate the exact same Battlefield composition and recurrence,
this is strong negative evidence only. `VISUAL-001B` remains open.

## Exact-source PGO

The profile was regenerated from the corrected source, explicit Apple clang,
arm64, and macOS 14 deployment flags. The instrumentation and profile-use flags
were passed to both compilation and shared linking.

- Generate module SHA-256:
  `1dda74b1e516d07c938384f66dbfbdb512a981f7b6acfb9afd5b2a804951e500`.
- Raw profile SHA-256:
  `d5775d2c3e6922356d00e376b060df5f32d67ae692652f484001f765895d6994`.
- Merged profile SHA-256:
  `26c3cbeb69793a37f8ce0c9741da2cb1404f25d6f5fcd015dd045135b97f3237`.
- Profile-use module SHA-256:
  `524dd2df5a65ce36b16692350faac5f44ee42858e2771a92327711b5f3c06639`.

Exactly one fresh raw profile was merged. The no-input training run visibly
traversed several coherent matches, including Yoshi's Story and Jungle Japes
with Peach. This is a screening corpus, not the final Fountain/Final
Destination acceptance corpus. The profile-use dylib is arm64, macOS 14,
ad-hoc signed, and exposes no instrumentation hooks.

## Matched performance screen

Both runs used the same corrected source, extracted game, SRAM hash, no-input
route, Metal, Cubeb, and frames 501-1500.

| Module | Metric | Mean | Median | p95 | p99 | Worst | <=16.7 ms | >40 ms |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Profile-free | Render | 16.719 | 16.831 | 20.616 | 21.243 | 37.348 | 49.7% | 0 |
| Exact PGO | Render | 16.684 | 16.671 | 18.232 | 18.823 | 30.571 | 51.9% | 0 |
| Profile-free | VBlank | 16.677 | 17.287 | 22.258 | 22.791 | 25.161 | 50.0% | 0 |
| Exact PGO | VBlank | 16.683 | 16.684 | 19.021 | 19.728 | 31.488 | 50.8% | 0 |

The exact retraining improves the tails and falsifies the feared corrected-
helper PGO collapse. It still fails the strict G5 rule: every frame, including
audio, must be at or below 16.7 ms on both required stages.

## Decision and next experiment

Retain the exact semantic correction and its tests. Do not promote to G6.
First reproduce the known Peach composition (or an extended matched equivalent)
with the corrected module to close `VISUAL-001B`. Then use clean, visually
verified Fountain and Final Destination combat intervals to attribute the
remaining tail and test one cause at a time. Do not interpret the no-input PGO
screen as required-stage acceptance.
