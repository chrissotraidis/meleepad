# G5 Fountain visual-warping observation

Date: 2026-08-25

Status: **OPEN; MACOS PROMOTION BLOCKER**

During the visually verified Fountain of Dreams combat-profile run, the user
reported repeated bizarre warping/morphing of the fighters. The retained frame
shows Bowser and CPU Donkey Kong intersecting in a suspicious pose and a
heavily distorted/blurred lower-stage region:

- `g5-fountain-warping-user-observation.png`
- SHA-256: `a524450eb97c9bb99722a4d48a5d1f55998dc300aac0a7984a2f2af576e19b6c`
- Dimensions: 1230 x 848

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
| Profile-free, texture copies non-deferred (`DeferEFBCopies=False`) | Same corrupted lower surface | 25.6 FPS in retained Fountain frame | `g5-fountain-efb-nondeferred-control.jpeg` |

SHA-256:

- `g5-fountain-pgo-normal-speed-warping.jpeg`:
  `c9fe6f085b8458cb54022b739f06784a786e6f5958a2dad5a6b0570b5da0fd4a`
- `g5-fountain-profile-free-warping-control.jpeg`:
  `ff88a8c144fb786e01dda608c8be46f18613aa9bc8bf2abc44020c16c784e1b8`
- `g5-fountain-efb-to-ram-control.jpeg`:
  `4bcb8f68b7a4cd773caecacd54b51dbc73c95d6ec27a348be2a4eefe76e4f2e8`
- `g5-fountain-efb-nondeferred-control.jpeg`:
  `0dea7aaa0e9ec28b90712ec233741a8bcace5e1d1f270e612f6b5055b65daf60`

## Current attribution

The normal-speed PGO reproduction rules out slow instrumentation as the sole
cause. The profile-free reproduction rules out the new combat PGO profile.
The two one-setting EFB controls rule out both the normal texture-copy shortcut
and deferred-copy completion as sufficient causes. Accurate RAM copies are
also far too slow to retain.

The strongest current distinction is that the real fighter meshes above the
platform remain coherent in the retained control frames while their copied /
reflected images and the lower surface are corrupted. `VISUAL-001` is therefore
currently attributed to a shared Fountain reflection / EFB-copy render path,
not yet to the generated fighter animation or skinning path. This does not
invalidate the user's broader morphing report: a video capture around a fresh
real-mesh occurrence is still required to classify that separately.

Before G5 can pass:

1. compare Fountain against the reference implementation at the same native
   scale and camera;
2. capture a short video around any fresh real-fighter mesh deformation;
3. isolate the shared Metal texture-cache / EFB-copy path below the high-level
   copy-mode switches;
4. rerun both required stages after a falsifiable fix.

For each run, distinguish ordinary collision/grab overlap from persistent mesh
deformation, character teleportation, invalid pose transitions, and copied
stage-surface corruption. A normal-speed release candidate that still shows
the defect does not satisfy macOS stability and must not advance to G6.
