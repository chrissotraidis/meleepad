# G8 physical-iPad controller, copy, and icon update

Date: 2026-09-03

## Trigger

An exploratory iPad session reported strong approximately 60 FPS performance
and working 2x scaling, but also found that the external controller's right
stick did not perform expected attacks, the default Xbox B/X layout felt
reversed, and water/reflected or shadowed areas rendered incorrectly. The
session also found that the online and diagnostic menu language overstated or
obscured the current product boundary, and that the app icon needed a clearer
identity.

## Bounded change

- External controllers default to **Right Stick Smash — On**. During active
  combat, a cardinal right-stick input produces a chargeable main-stick-plus-A
  smash input. Menus, CSS, results, and cutscenes keep the untouched C-stick;
  turning the setting off restores Melee's original C-stick path everywhere.
- Xbox physical X now maps to GameCube B (special), and Xbox physical B maps to
  GameCube X (jump). The existing button-remapping screen remains available.
- When the app launches with no controller, it now starts Apple's wireless
  controller discovery and reconciles any controller announced during that
  discovery window.
- The online entry is now **Experimental Multiplayer…** and explains that the
  current implementation has no matchmaking service or room codes, expects a
  directly reachable peer on a LAN/private VPN, and cannot yet promise complete
  matches.
- Diagnostic actions are named **Export Diagnostic Log…** and **Report Issue on
  GitHub…**. Automatic log attachment remains future work because opening an
  issue URL cannot attach a local file.
- The app icon is replaced with an original, text-free analog-gate and energy-
  slash mark. Its generation prompt and source hash are recorded in the asset
  catalog provenance file.

Water/reflection/shadow corruption is intentionally not changed in this update.
It is a separate scene-matched rendering investigation in `docs/TECH-DEBT.md`.

## Verification

- `./scripts/check-repository.sh`: pass, including controller mapping,
  diagnostics, performance-menu, and iOS online-lobby source contracts.
- Signed Debug device build: pass; Xcode compiled the opaque 1024px icon into
  the iPad-specific 152px asset without warnings.
- In-place install and launch on an attached iPad14,5: pass. No uninstall or
  destructive container copy was used.
- ISO, memory-card save, and signed recompilation module: post-install readbacks
  matched the pre-update/local SHA-256 values byte-for-byte.
- Runtime boot: game root, disc image, and module readable; input pipe connected;
  native 60 FPS mode active at 2x render scale.
- Runtime cadence after startup: repeated 59.9-60.0 FPS/VPS samples at nominal
  thermal state, including the heavier gameplay workload.
- A second in-place install with launch-time wireless discovery repeated the
  exact ISO, memory-card save, and signed-module readback matches. The live log
  confirms that discovery started, but iPadOS announced no controller during
  the observed window.
- The subsequent hands-on controller run confirmed that the initial translation
  performed the intended attacks in combat but incorrectly navigated menus by
  rewriting the left stick globally. The first attempted scene gate fixed the
  menu behavior but rejected Classic combat because it mixed a public
  revision-1.02 scene address into the supported revision-1.00 image. That
  attempt is rejected.
- The replacement uses the already verified revision-1.00 `GameState` word at
  `0x80477D68` through the static-recomp-safe big-endian memory reader. Focused
  regressions now separate main menu, CSS, stage select, ordinary VS combat,
  Classic intro/fight routes, and Training. A signed device build passes and is
  installed for another hands-on test.
- The final copy/documentation build passed the complete repository check and
  was installed in place at 13:29 local time. A second targeted preservation
  gate retained the current memory card and preferences; post-install SHA-256
  readbacks matched the save, preferences, signed module, and 1,459,978,240-byte
  ISO exactly. The relaunched app found all game data, connected its input pipe,
  retained 2x scaling, and reported 59.9 FPS/VPS with zero audio underruns.
- The revision-1.00 scene-gate replacement was installed in place at 14:17.
  The save had legitimately changed during the rejected Classic retest; its new
  `e74d91f2…` SHA-256 plus preferences and module matched their immediate
  pre-install copies afterward. The relaunch found the disc and module, assigned
  the connected Xbox controller to slot 1 with Right Stick Smash enabled, and
  again reached 59.9 FPS/VPS with zero audio underruns.

## Acceptance result

The user repeated the same physical-iPad route after the revision-1.00 gate was
installed: main-menu right-stick behavior remained correct, One Player →
Regular Match → Classic accepted controller navigation, and Samus's in-combat
right-stick attacks worked. The user explicitly accepted the controls and the
three-dot menu. This closes the controller/menu acceptance scope of this
update.

This artifact proves the bounded controller behavior, build/install/data
preservation, and observed runtime cadence. It does not close rendering
correctness or the complete physical-device matrix. The existing single
`Failed to allocate memory space: 0x3` startup diagnostic remains non-fatal in
this run and is not reclassified by this change.
