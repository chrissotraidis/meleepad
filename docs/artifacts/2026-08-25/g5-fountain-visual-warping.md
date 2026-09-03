# G5 Fountain visual-warping observation

Date: 2026-08-25

Status: **REFLECTION CLOSED AS REFERENCE PARITY; REAL-MESH REPORT REOPENED**

During the visually verified Fountain of Dreams combat-profile run, the user
reported repeated bizarre warping/morphing of the fighters. The retained frame
shows Bowser and CPU Donkey Kong intersecting in a suspicious pose and a
heavily distorted/blurred lower-stage region:

- `g5-fountain-warping-user-observation.png`
- SHA-256: `a524450eb97c9bb99722a4d48a5d1f55998dc300aac0a7984a2f2af576e19b6c`
- Dimensions: 1230 x 848

The user reconfirmed on 2026-08-25 that the promotion gate must explicitly
track the bizarre character morphing and body warping, not only the stage
surface effect. The reattached screenshot was byte-for-byte identical to the
retained observation above (same SHA-256), so no duplicate evidence file was
created. This reconfirmation keeps `VISUAL-001B` open even though the distinct
Fountain reflection issue is closed as reference parity.

This frame was captured from the fully instrumented profile-generation module,
which was running Fountain at roughly 12-14 host FPS. A single overlapping
combat frame was not enough to assign the cause. The repeated user observation
meant it could not be dismissed as an ordinary animation.

## Reproduction matrix

The lower-stage corruption was subsequently reproduced in every tested native
module class:

| Module / setting | Visible result | Performance observation | Evidence |
|---|---|---|---|
| Profile-use PGO, normal EFB defaults | Lower reflection/surface is smeared and stretched while the real fighters above it remain coherent | 59.9 FPS counter; capture-free interval still fails G5 | `g5-fountain-pgo-normal-speed-warping.jpeg` |
| Profile-free release, normal EFB defaults | Same lower reflection/surface corruption; a Pikachu image below the platform is stretched while the real Pikachu and DK meshes remain coherent | 29.1 FPS counter in retained observation | `g5-fountain-profile-free-warping-control.jpeg` |
| Profile-free, EFB copies to RAM (`EFBToTextureEnable=False`) | Same corrupted lower surface | 22.8 FPS in retained Fountain frame and 1.8 FPS in another copy-heavy scene | `g5-fountain-efb-to-ram-control.jpeg` |
| Profile-free, texture copies non-deferred (`DeferEFBCopies=False`) | Same lower reflection | 25.6 FPS in retained Fountain frame | `g5-fountain-efb-nondeferred-control.jpeg` |
| No-module `--allow-interpreter` reference | Same lower reflection with no generated module loaded | 53.5 FPS in retained frame | `g5-fountain-no-module-reference.jpeg` |
| Official Dolphin 2606a, JIT64 SC + Metal + HLE, native scale | Same blurred/blocky lower reflection | Reference run; not a product performance measurement | `g5-fountain-official-dolphin-2606a-reference.jpeg` |

SHA-256:

- `g5-fountain-pgo-normal-speed-warping.jpeg`:
  `c9fe6f085b8458cb54022b739f06784a786e6f5958a2dad5a6b0570b5da0fd4a`
- `g5-fountain-profile-free-warping-control.jpeg`:
  `ff88a8c144fb786e01dda608c8be46f18613aa9bc8bf2abc44020c16c784e1b8`
- `g5-fountain-efb-to-ram-control.jpeg`:
  `4bcb8f68b7a4cd773caecacd54b51dbc73c95d6ec27a348be2a4eefe76e4f2e8`
- `g5-fountain-efb-nondeferred-control.jpeg`:
  `0dea7aaa0e9ec28b90712ec233741a8bcace5e1d1f270e612f6b5055b65daf60`
- `g5-fountain-no-module-reference.jpeg`:
  `25d6e9dea005744604ccde79467fa58f3feabdb8c02f24bb4b596fa0d3ee50e1`
- `g5-fountain-official-dolphin-2606a-reference.jpeg`:
  `908272b7c3953031cc73a4e1c4ea46693159b7b00cfd1fcd2e1fe9d454a53aa9`

## Current attribution

The normal-speed PGO reproduction rules out slow instrumentation as the sole
cause. The profile-free reproduction rules out the new combat PGO profile. The
no-module control rules out generated static-recomp code and state as the
source of the lower reflection. Most decisively, the current signed official
Dolphin 2606a macOS release reproduces the same blurred/blocky lower reflection
on Fountain at native scale. That portion of the observation is normal
reference behavior and is closed as `VISUAL-001A`.

The EFB-to-RAM and non-deferred-copy controls were therefore testing an effect
that was not an meleepad defect. Both were reverted; accurate RAM copies are far
too slow to retain. The user's separate report that the actual fighter bodies
morph is tracked as `VISUAL-001B`. The supplied single frame contains a
Bowser/DK intersection that can be a legal grab/hit pose and cannot prove
persistent mesh deformation. A bounded window-only capture then retained 9.8
seconds of native Fountain gameplay during scripted movement, attacks, jumps,
specials, CPU interaction, hit sparks, overlap, and damage transitions. Dense
sampling at 5 FPS produced 49 time-adjacent frames; real Bowser and CPU meshes
remain coherent throughout. That bounded sample did not reproduce the report.
A later four-player Pokémon Stadium montage did: one retained frame shows the
orange fighter stretched into an implausibly thin vertical shape above Captain
Falcon while nearby fighters remain coherent. This fresh recurrence reopens
`VISUAL-001B`. It is not yet attributed because the attempted adjacent-frame
capture was contaminated by a foreground Sound settings window, the subsequent
Fountain capture was coherent, and the unchanged profile-free replay sampled a
different scene. It is again a G5/G6 promotion blocker until uncontaminated
adjacent frames or a matched reference sequence classify it.

- Compressed 640x480 interaction clip:
  `g5-fountain-real-mesh-capture.m4v`
  (`0246b010eec412dbcd5faad84c5d56641094b15c7dc9b86a1fa159c77b3510ee`)
- 49-frame, 5 FPS dense review sheet:
  `g5-fountain-real-mesh-dense-contact-sheet.jpeg`
  (`5b2935b016781f7f6a9c40c1be6b7983d7cc54228557eef7e998176c67557279`)
- The lossless 29.985-second window recording is retained locally outside Git
  at `/private/tmp/meleepad-g5-fountain-real-mesh-capture-original.mov`, SHA-256
  `50dfcadff8d98038030a4ea3901e2f6d62632fb1791939b201369dfaf051ccdd`.
- Fresh four-player recurrence:
  `g5-fp-fast-path-attract-mesh-warp.jpeg`
  (`47831e1fb4862e66221c3772fda55c7425848e70e890f2127b08bf09c81fb099`).
- Fresh app-only temporal control: twelve original JPEG frames under
  `g5-fountain-temporal-mesh-burst/` show Ice Climbers and Yoshi remaining
  coherent through scripted overlap, movement, attacks, and separation. First
  and last frame SHA-256 are
  `16ae52b3538857ae5f27dd72b00a4a04de2ac8fc6898d5c52e53cb669ea9ddf9`
  and `8a815d79765e44d729d89e062c21f33a145c00b11759a91398d2bd5b6d2dac73`.
  This is a bounded non-reproduction and does not close `VISUAL-001B`; see
  `g5-watcher-pump-fountain-replay.md`.

The official reference was fetched through Homebrew's `dolphin` cask without
global installation. It reported Dolphin 2606a and carried Developer ID
Application signature `Stichting Dolphin Emulator (97835T4369)`. It used a
separate temporary user directory and the same private GALE01 revision-0 image;
no game data was copied into this repository.

For future observations:

1. compare the real meshes, not the known reference-matching reflection;
2. retain adjacent frames before attributing a transient pose;
3. keep G5 performance work independent of the closed reflection observation;
4. keep the real-body recurrence open until temporal or matched-reference
   evidence classifies it.

For each run, distinguish ordinary collision/grab overlap from persistent mesh
deformation, character teleportation, invalid pose transitions, and copied
stage-surface effects. The reference-matching Fountain reflection remains
closed. The fresh real-body recurrence now blocks promotion conservatively;
one frame is not enough to assign its subsystem or call it persistent.

## Reduced-idle PGO recurrence

A later, independently trained reduced-idle PGO candidate reproduced clearly
impossible scale/displacement during a freshly verified Fountain match while
the native title read 59.9 FPS. The retained frame and exact candidate timing
rejection are documented in `g5-reduced-idle-pgo-rejection.md`. This separates
the corruption from the earlier idle-contaminated profile and confirms that
frame-rate recovery alone does not close `VISUAL-001B`.
