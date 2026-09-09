# Startup polish and efficiency investigation

## Shipped source changes

The macOS launcher now separates Play, Display, Controllers, Online Play, Game
Data and Diagnostics. It uses the system font, larger controls and a clear
primary Play action. The installed revision remains visible. Existing import,
controller, configuration and launch actions retain their original handlers.
The change is recorded in `0028-polished-launcher.patch` and dependency bootstrap.

On iOS/iPadOS, a verified local game now opens to a lightweight home screen with
Play, installed revision, Game Data and Settings. The first-run import state
uses the same design. Settings reuses the existing Display, Game Data & Saves,
and Report a Problem actions. Touch editing and online play remain in-game.
The runtime and 60 Hz input publisher wait until Play; benchmark, external-pipe
and automated netplay launches retain direct boot. No game module was changed.

## Verification

- Native macOS launcher built and inspected. All six pages rendered; keyboard
  navigation, Play dispatch and the selected revision module were checked.
  A clipped UDP port field was widened. The Play action launched the existing
  native runner with the intended isolated user directory and v1.02 module.
- Simulator and Release iphoneos targets built successfully. Device-target
  compilation is not physical-device acceptance or a new distributed IPA.
- iPad-sized and iPhone 14-sized Simulator layouts inspected, one simulator at
  a time. Both installed-game and empty/import states inspected. Play reached
  game rendering; Import opened version selection and Cancel returned home.
- Home Settings -> Display -> Render Resolution changed 1x to 2x, persisted
  `MeleePadRenderScale=2`, and showed the updated selection. Restored to 1x.
- A three-second Simulator home sample contained no CPU-GPU runtime thread or
  generated game dispatch, consistent with deferred startup. This is not an
  iPhone power measurement or a combat FPS improvement.
- Revision tests (3), external-pipe source regression, Online Play source
  contract, Mac keyboard profile and diagnostics checks passed. Launcher patch
  reverse application and `git diff --check` passed.

Private build logs, screenshots and sample are in `ref/launcher-polish/`.
The follow-up themed home uses the existing MeleePad emblem, navy/violet panels,
an amber Play action, and a green installed-version label. The generic welcome
headline was removed. Build 23 was installed in place and launched on the hardware
iPad; device app inventory and runtime logs confirm the build. The v1.02 ISO size
and timestamps and all ten configuration files were unchanged. Preferences were
unchanged except the extracted-root path updating to the relocated app container.
Game modules match the existing private build byte for byte. iPhone hardware was
not changed. The themed iPhone/iPad Simulator layouts were inspected, and Settings
and Play were checked again. Unrelated Slippi/FAQ research remains outside this change.

## Upstream efficiency screen

Inspected the pinned melee4mac implementation from the preceding native Mac
comparison (`a276aeb70f9879204d891d967f1c9442523568e1`).

1. **Critical frame timer:** ran its three focused timing tests (all pass) and
   official isolated timer benchmark. At 60 Hz, original/new timer CPU use was
   0.458%/1.006%; p99 lateness 1122.791/825.084 microseconds and maximum
   1880.750/2419.251 microseconds. At 120 Hz, CPU was 1.912%/2.118% and p99 lateness
   2334.584/304.709 microseconds. Host measurements are mixed; the tested timer
   was not more CPU-efficient here. No iPhone timer or QoS policy is changed.
2. **Texture cache:** its added budget/release behavior concerns replacement
   texture assets. Our current problem is unmodified-game combat without that
   optional texture pack. No demonstrated applicable saving justifies importing
   those changes for this issue.
3. **Fast loading:** skips modeled disc delays and guards netplay. This is a
   loading-time feature, not evidence of better sustained four-player combat.
   No disc timing policy is changed.
4. **120 FPS prediction:** adds draw work. The earlier same-Mac test already
   showed simulation slowing in that mode; this is not an iPhone speed fix.

Sources: [timing](https://github.com/t3dotgg/melee4mac/tree/a276aeb70f9879204d891d967f1c9442523568e1/native/macos/timing),
[patches](https://github.com/t3dotgg/melee4mac/tree/a276aeb70f9879204d891d967f1c9442523568e1/native/macos/patches).
Raw timer output is retained as `upstream-timer-benchmark.log` alongside test
output. These are short host tests, not a physical iPhone A/B.

## Remaining performance work

This pass improves startup and usability. It does **not** establish a combat
speedup or resolve iPhone 14 audio underruns. The next gameplay experiment
remains exact guest-PC attribution of the CPU hotspots, followed by a measured
shared routine replacement, as described in the
[native Mac comparison](NATIVE-MACOS-COMPARISON-GOAL.md). Avoid repeating the
previous matrix candidate without a deterministic scene and matched thermal
conditions. Build 23 is installed on the hardware iPad for user review; no new public release
or gameplay performance improvement is claimed here.
