# Potential MeleePad expansions

Research snapshot: September 10, 2026. **All avenues below are proposals.**
They are not release commitments or claims that these mods already work in
MeleePad. Relative effort is an initial assessment, not a delivery estimate.

The strongest direction is portable practice, personal customization, and easy
sharing. These give people reasons to return to MeleePad between online matches.
Slippi interoperability remains a separate investigation; several ideas can be
explored without matchmaking or a new hosted service.

This document combines community discussions on X, upstream project
documentation, and source inspection. Social engagement is a useful interest
signal, not evidence that a feature will produce installs or sustained use.

## Suggested sequence

1. Prototype short clip export and one renderer texture replacement. Improve
   setup guidance alongside them so interested players can reach gameplay.
2. Run a focused lightweight-graphics comparison against a known slow scene.
   Promote it only if physical-device measurements show a worthwhile benefit.
3. Investigate one Training Mode Community Edition event as the major practice
   feature. Inventory its injected and dynamically loaded code first.
4. Introduce one repeatable target or movement challenge with local bests and
   shareable rules. Expand after scoring and resets are dependable.
5. Evaluate practice bookmarks, configurable opponents, Akaneia, and learned
   bots as separate projects after their prerequisites are understood.

Core rendering, sustained performance, controller behavior, and reliable setup
remain prerequisites for a good experience. Feature work should preserve the
existing game data, saves, settings, and supported revision choices.

## Opportunities at a glance

| Avenue | Player benefit | Relative effort / main dependency |
|---|---|---|
| Gameplay clips | Save and share a good moment | Small–medium; capture overhead and audio |
| Texture and cosmetic packs | Personalize the game | Medium for textures; higher for models/code |
| Guided setup | Get from a local game image to a playable app | Medium; build and signing workflow |
| Controller tools | Verify inputs and choose a tested setup | Small–medium; hardware acceptance |
| Lightweight graphics | Potentially steadier play on slower devices | Medium–high; measured scene benefit |
| TM-CE / UnclePunch | Practice specific techniques anywhere | High; injected-code execution |
| Movement challenges | Repeat short drills and compare results | Medium after training support |
| Break the Targets challenges | Race friends asynchronously | Medium–high for randomized courses |
| Practice bookmarks | Retry a situation from a match | High; accurate state restoration |
| Configurable opponents | Practice a particular habit or matchup | Medium–high; game-state/input control |
| Akaneia volleyball | Casual local party play | High / uncertain; m-ex compatibility |
| Learned sparring bot | Stronger offline opponents | High / uncertain; inference and integration |

## 1. Capture and share gameplay clips

Add an opt-in capture action, local preview, and the system share sheet. Start
with manual capture/export; automatic combo detection can follow. Keep the
complete gameplay frame, with optional presentation suitable for a portrait
post. Sharing should always be initiated by the player.

[Apple's rolling-clips reference](https://developer.apple.com/videos/play/wwdc2021/10101/)
documents a 15-second buffer. Select the implementation against MeleePad's
actual OS targets and SDK; do not assume a longer buffer or negligible cost.

**First proof:** export a short physical-device clip with synchronized game
audio; check interruptions, failures, and storage handling. Compare frame-time
tails and thermal behavior with capture on and off. The intended outcome is
easy sharing without materially worsening play.

## 2. Texture replacements and curated cosmetic packs

Start with a small pack selector and reversible installation. Display creator
credits, a source link, and the precise tested compatibility. A marketplace or
an in-app editor is unnecessary for the first version.

[SSBM Nucleus](https://ssbmnucleus.net/download) is a useful ecosystem to study
for mod organization, previews, and shareable bundles.
[Animelee's DBZ showcase](https://x.com/VC_Primal/status/1638682029641592832)
illustrates the visual appeal of a coherent pack. Neither establishes an
integration API, distribution permission, or MeleePad compatibility.

The inspected Dolphin-derived renderer already includes `HiresTextures.cpp`.
It searches game-specific directories for PNG/DDS replacements, and
`TextureCacheBase.cpp` applies them when `GFX_HIRES_TEXTURES` is enabled. The flag
defaults off. This suggests a narrower first experiment than importing a
modified disc.

**First proof:** display one original replacement texture on a physical device,
restart, disable it, and verify clean restoration. Measure loading stalls and
memory before expanding the pack. Texture replacements cannot add fighters or
change model geometry. Nucleus/DAT assets need their own compatibility path.

Creator concerns are visible in the
[modding discussion](https://x.com/PigsSSBM/status/2097727667843764668).
Collaborations should credit the people doing the work and distinguish
user-local imports from assets permitted for redistribution.

## 3. Guided local build and import

A [launch reply](https://x.com/cy_gn_us/status/2095807293883666524) describes a
player supplying a game file but being unable to start. A Mac assistant around
the existing scripts could verify prerequisites, identify the image, generate
the matching module, and guide signing and installation with useful errors.

In the app, distinguish missing game data, a missing native module, and a
revision mismatch. The public IPA is a module-free shell; importing an image
alone cannot make it playable. Preserve the local generation/signing workflow
described in the [version guide](MELEE-VERSIONS.md).

**First proof:** a fresh tester completes setup and reaches gameplay using their
own supported image, without undocumented repair steps. Track where setup
fails before adding more automation.

## 4. Controller confidence and responsiveness

Build on existing mappings with an input test view, connected-controller
status, calibration where appropriate, and exportable profiles. The audience
asked directly about
[GameCube adapters](https://x.com/obesatron67/status/2095715546784309464) and
[input delay](https://x.com/cojackSSBM/status/2095652258444648748).

**First proof:** verify one named controller through menus, gameplay,
disconnect, and reconnect. Measure input-to-display latency independently of
FPS. Investigate exact GameCube adapter support separately on each Apple
platform; a USB connector is not proof of operating-system support. UCF would
be a separate gameplay modification, not a general latency fix.

## 5. Optional lightweight graphics

[Diet Melee](https://diet.melee.tv/) provides prior art for simplified stages
and fighters. A selective lightweight profile might help MeleePad's heavy
scenes, but there is no measured MeleePad gain from this research. Reduced
geometry will not necessarily resolve CPU scheduling or other bottlenecks.

**First proof:** compare one candidate asset change against the original with
the same characters, scene, inputs, and resolution over sustained physical
play. Measure frame times, audio underruns, and thermal behavior; check
collision and gameplay correctness. Keep the original appearance available.

The full Diet build removes substantial content, according to its
[FAQ](https://diet.melee.tv/faq/). Its
[changelog](https://diet.melee.tv/changelog/) also records timing and desync
fixes. A selective experiment is preferable to replacing the entire default
game. Battery and thermal improvements must be measured before being claimed.

## 6. Pocket practice with TM-CE / UnclePunch

A [MeleePad launch reply](https://x.com/epicstrumfailgh/status/2095771888207421830)
explicitly requests UnclePunch support. The maintained
[Training Mode Community Edition](https://github.com/AlexanderHarrison/TrainingMode-CommunityEdition/releases/tag/CE-v1.4)
is a strong target: its documented features include movement practice,
technique events, frame tools, and feedback. This is the clearest requested
flagship beyond online play.

**First proof:** pin one release and one v1.02 event; inventory executable
injections and loaded modules; establish correct execution; then validate
repeated practice, timing feedback, controllers, and isolated saves on hardware.
Add a Practice menu entry only when the underlying event works.

The [development guide](https://github.com/AlexanderHarrison/TrainingMode-CommunityEdition/blob/master/DEVELOPMENT.md)
describes Gecko injections and C events loaded through m-ex. A new ISO hash
allowlist entry is insufficient. Existing native coverage must account for
modified and later-loaded code. The guide also rejects AI-generated upstream
code contributions; any proposed contribution must respect that policy.

## 7. Movement challenges and shareable scores

Build a small recurring challenge around a movement course, Eggs-ercise, or a
technique streak once the relevant training event is dependable. The proposal
adds a repeat-play and sharing layer to established practice concepts.

**First proof:** one fixed challenge with local personal bests and a share card
containing character, rules, score, input category, and challenge version.
Validate scoring and resets. Start without accounts or global leaderboards;
separate touch and physical-controller results. Success means repeat attempts
and voluntary sharing, rather than merely impressions on an announcement.

## 8. Daily Break the Targets courses

[Break the Targets Randomizer](https://bttrandomizer.com/) supplies fixed seeded
layouts and share links through generated Gecko codes. Its creator documented
[recurring community competitions](https://x.com/sirquine/status/1503393023639658502).
This is a useful independent avenue for short solo sessions and asynchronous
races between friends.

**First proof:** one vetted course, stage, and character with reproducible
resets and timing. Inspect generated code for data writes and executable
injections before admission. Store generator version, rules, and actual target
positions with the challenge; a seed alone may not survive generator changes.
Use game-frame timing. A daily rotation can be computed locally.

A vanilla target course with personal bests is a smaller first version if
randomized layouts require extensive runtime work. Randomization and a public
leaderboard are separate milestones.

## 9. Save a situation, then practice it

[Melee Improover](https://github.com/Fiction52s/Melee-Improover) demonstrates
exporting situations from `.slp` files for TM-CE. Its README acknowledges
remaining savestate-fidelity work. The appeal is concrete: return to a mistake
and try a different response.

**First proof:** accurately restore one version-bound local situation, retry
it, and preserve ordinary saves. Add a practice bookmark and investigate
supported drill exchange only after restoration is dependable. Video clips,
replay parsing, deterministic playback, and interactive practice states are
different capabilities. Diagnostic savestates do not establish all of them.

## 10. Configurable opponents and warm-up play

Aitch's [Preflight announcement](https://x.com/rwing_aitch/status/2088310443056201990)
describes configurable CPU habits and practice while queuing. Its
[September update](https://x.com/rwing_aitch/status/2095200089119838500)
includes practice while waiting for a Direct opponent and save/load state.

**First proof:** one offline opponent behavior that addresses a specific
practice need, such as approaching a retreating opponent. Later, consider
warm-up play while a MeleePad room waits, with a reliable transition to the
match once players are ready.

Preflight is distinct from TM-CE and was distributed through Patreon in the
inspected posts. Its source availability and integration permissions were not
established. This is a product lead, not an available code dependency. Waiting
room practice requires deliberate state/lifecycle coordination, and does not
confer Slippi queue access.

## 11. Akaneia volleyball and other party modes

[Akaneia](https://github.com/akaneia/akaneia-build) adds fighters, stages, and
modes through [m-ex](https://github.com/akaneia/m-ex). Its
[volleyball announcement](https://x.com/TeamAkaneia/status/1352043538029150209)
shows a mode that is easy to understand in a short demonstration and could
appeal to casual local groups.

**First proof:** one pinned build, one mode, and a complete round with two
physical controllers, including restart. Map executable loading, relocation,
and dispatch requirements before promising support. Expanded rosters and
online play should follow separate acceptance. This is a larger compatibility
target than a cosmetic pack.

## 12. A stronger offline sparring bot

[Phillip II / Slippi-AI](https://github.com/vladfi1/slippi-ai) provides code and
links to trained models, with documented desktop play through Python and
Slippi Dolphin. [Players have demonstrated interest](https://x.com/NotAklo/status/1797742885904994791)
in stronger bots. Mobile inference and MeleePad integration remain unverified.

**First proof:** select one released model, reproduce its inputs/outputs on
recorded observations, and measure an Apple inference runtime for parity,
latency, and memory. Only then connect it to gameplay, initially for one
character with an explicit reaction delay. Do not infer that a generic language
model can provide frame-rate control or that a policy recreates a named pro.

## Shared technical prerequisites

- **Classify modifications by behavior.** Renderer textures, game assets,
  executable patches, and dynamically loaded code have different requirements.
  DAT containers can contain code as well as visual data.
- **Preserve code verification.** The inspected static-recompilation core sends
  failed code-verification chunks to interpreter execution. Disabling that
  guard would not make stale native code correct. Training and Slippi may
  benefit from related execution work, but must each be validated.
- **Keep identities explicit.** Revision, module, assets, rules, and mod versions
  belong in compatibility checks. Offline support does not establish online
  determinism. See [Melee versions](MELEE-VERSIONS.md) and
  [Online Play](ONLINE-PLAY.md).
- **Use real acceptance.** A source inspection, build, or boot is not a completed
  gameplay test. Capture, graphics packs, and bots must fit the device's measured
  frame-time, memory, audio, and thermal budgets.
- **Preserve local ownership.** Use player-supplied game data and obtain the
  necessary permissions for distributed mod content. No creator endorsement or
  partnership is implied by inclusion here.

The source inspection used MeleePad `a4ef577` and its locally patched
Dolphin-derived tree at `e13ab348f1`. These identify the research context, not a
reproducible new feature build. Recheck the implementation baseline before
starting work; current status is maintained in the [README](../README.md).

## Evidence and evaluation

X was inspected in Brave on September 10, 2026. Examples below are snapshots;
older posts are historical signals, and selected search results are not a
representative audience survey.

| Source | Date | Observed interest |
|---|---|---|
| [MeleePad launch](https://x.com/chrissotraidis/status/2095518766696468969) | Sep 2026 | About 114K views and 1.9K likes |
| [TM-CE v1.4 announcement](https://x.com/rwing_aitch/status/2042363970292760623) | Apr 2026 | About 54K views and 1.2K likes |
| [Melee Improover](https://x.com/FictionIRL/status/1936961001515278577) | Jun 2025 | About 199K views and 1.8K likes |
| [Nucleus character tooling](https://x.com/ssbmSc00p/status/2097661316378816654) | Sep 2026 | About 445K views at initial observation; showcased tools described as upcoming |
| [Preflight](https://x.com/rwing_aitch/status/2088310443056201990) | Aug 2026 | About 105K views and 1.5K likes |
| [Target randomizer](https://x.com/sirquine/status/1306325619509137409) | Sep 2020 | About 1.7K likes and 369 reposts |
| [Akaneia volleyball](https://x.com/TeamAkaneia/status/1352043538029150209) | Jan 2021 | About 8.5K likes and 2.1K reposts |

Evaluate prototypes through successful setup-to-first-play, repeat practice,
challenge retries, voluntary clip sharing, and regressions. Use tester feedback
or explicitly opted-in aggregate measurement. The objective is a more useful,
dependable app that players want to share; virality cannot be guaranteed.
