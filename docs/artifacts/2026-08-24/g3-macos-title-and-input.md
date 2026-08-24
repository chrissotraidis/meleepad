# G3 macOS title and input evidence

Status: **PASS**

- The packaged app launches one frontend and one runner through Play.
- The runner loads the revision-0 GALE01 module at `0x8000522C`.
- `g3-title.png` is the real Melee title screen, not a first frame.
- `g3-input-a-transition.png` retains a native Quartz A-button-caused visible
  transition from the first-boot flow.
- Runtime shutdown reports `smc_failed=0`.
- Cubeb initializes without a fatal error.

The pass is intentionally narrow. It proves title plus an input transition,
not stable gameplay controls, audible audio, or 60 FPS.
