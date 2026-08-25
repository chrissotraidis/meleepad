# Corrected visual closure and Fountain baseline

Date: 2026-08-25

Status: **`VISUAL-001B` CLOSED; G5 STILL FAILS**

## Exact corrected build

The run used the corrected exact-source PGO module:

- SHA-256:
  `524dd2df5a65ce36b16692350faac5f44ee42858e2771a92327711b5f3c06639`
- arm64, macOS 14 minimum, Metal, Cubeb
- generated-source identity suffix: `e02b042a2f09321f`
- scalar-single arithmetic and all 1,237 `frsp` sites use exact GXRuntime
  helpers and update both destination lanes

No Simulator was booted.

## Extended visual recurrence test

The native app window was sampled for 402.7 seconds on the same no-input
attract route used to expose the original defect. The corpus contains 2,110
ordered PNGs: the first 750 are approximately 20 samples per second and the
remaining 1,360 are approximately four samples per second.

The run visibly covered several four-player demos and character cinematics,
including:

- Brinstar;
- Battlefield with Peach, Mario, Samus, and Pikachu;
- Peach's Castle with Peach in a four-player match;
- Icicle Mountain;
- multiple additional Peach appearances.

All observed fighter geometry stayed coherent. The dense retained Battlefield
Peach sequence covers frames 950-1003 through standing, hair and dress motion,
hits, parasol, attacks, airborne motion, explosions, overlap, and separation.
It does not show the impossible blade-like hair/arm extension present in the
old buggy frames 176-184.

This is not the identical old Brinstar lineup of Peach, Link, Ness, and Captain
Falcon, but it satisfies the loop's documented extended-matched-equivalent
boundary: more than six minutes, multiple comparable four-player scenes,
Brinstar, and dense Peach-specific combat on the exact corrected module.
`VISUAL-001B` is therefore closed. A future recurrence reopens it immediately.

Retained contact sheets:

| File | SHA-256 |
|---|---|
| `g5-corrected-visual-closure/overview-brinstar.jpg` | `e8f055ec8e4fdf019f4957af23c2da4b8b1e3d34dbf8cebd7758d15395707aab` |
| `g5-corrected-visual-closure/peach-battlefield-01.jpg` | `b088664aaa8fba44232831d9eaaf8a2efe624cd3606c81f268a4eea7ff7e3385` |
| `g5-corrected-visual-closure/peach-battlefield-02.jpg` | `3f5f3047aaa984cafa4a53fb8e33ef546d73f99b51b51a414c1a2eb8e8a13465` |
| `g5-corrected-visual-closure/peach-battlefield-03.jpg` | `ea8398fc9c91fdc85005877d40e7a71ffedfde9dc242fdb30b56fe5f35bf7de6` |
| `g5-corrected-visual-closure/extended-four-player.jpg` | `c7882b29327bb9ada22857b6ca8bcc9950c08926b0495e0ef596c772a373d7f3` |

The full 106 MB first corpus and its extension remain local under
`/private/tmp/ssbmpad-frsp-recurrence.x4E08E`; no ROM or generated module is
stored in Git.

## Clean corrected Fountain baseline

An isolated cold run visibly established:

1. player-one Pikachu and level-1 CPU Zelda on Character Select;
2. an explicit `Fountain of Dreams` highlight on Stage Select;
3. live Fountain combat with Cubeb audio and a 60.0 FPS window title.

The controller then ran 20 combat cycles for 66 seconds. No screenshot, UI
inspection, sampling, or other foreground work occurred inside the bracket.
The final 3,900 buffered samples cover approximately 65 seconds wholly inside
that bracket. The runner used for this acceptance screen predates the retained
phase-CSV build, so only render/vblank measurements are claimed.

| Metric | Render | Vblank |
|---|---:|---:|
| Samples | 3,900 | 3,900 |
| Mean | 16.683 ms | 16.683 ms |
| Median | 16.684 ms | 16.683 ms |
| p95 | 17.000 ms | 16.855 ms |
| p99 | 17.301 ms | 16.883 ms |
| Worst | 79.167 ms | 79.085 ms |
| Frames <=16.7 ms | 54.846% | 65.231% |
| Frames >40 ms | 1 | 1 |

Local full-log hashes:

- render: `37e327d81d3d332f1cbcba5b10e34d670924fb447fd845c90cc9243472ca9908`
- vblank: `b88414e785202c632b91b86b5a6be3fb8108ec3258cf63a1137b43982be09401`

This is a strict G5 failure. The 60.0 FPS title is an average and cannot replace
the retained tail distribution.

## Route and attribution boundary

Two setup attempts were discarded before gameplay because the isolated input
directory lacked, respectively, the SI-device selection and the named FIFO.
The valid run required `SIDevice0 = 6` plus a pre-created `Pipes/ssbmpad` FIFO.
The old all-in-one route then reached CSS but failed because its P2 cursor
assumptions were stale. The live correction was visually checked step by step;
only the subsequently verified Fountain bracket is retained.

The newer diagnostic runner was separately smoke-tested and emitted the full
phase CSV schema after shutdown. Its output is not mixed with the acceptance
run. The next falsifiable G5 step is a corrected-module Fountain replay using
that runner, followed by phase attribution of the >16.7 ms render tail before
changing another timer, renderer, audio, or generated-code path.
