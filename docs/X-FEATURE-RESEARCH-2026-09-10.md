# MeleePad feature opportunities from X — September 10, 2026

## Recommendation

Build toward **portable practice, personal style, and easy sharing** alongside the separate Slippi program. The strongest flagship is Training Mode Community Edition on iPhone/iPad; the smaller first feature is gameplay clip export. Curated cosmetic packs are the next visual hook. Akaneia volleyball is a compelling larger experiment.

This is research and prioritization, not an implementation or compatibility claim. X was browsed in the owner's Brave session. Public project pages and local source at `a4ef577` were cross-checked. No app, game data, device installation, or external post was changed.

## Evidence and limits

Queries included Melee mods; Melee training/challenges; UnclePunch/TM-CE; replies to the owner; Akaneia; Animelee; and Team Akaneia volleyball. The launch conversation was also read directly. These are selected X results, not a representative survey. Engagement counts are approximate observations on September 10 and cannot predict installs or causally establish which feature drove engagement. Older posts are explicitly dated.

| Signal | Source and observation | Implication |
|---|---|---|
| Existing reach | [MeleePad launch, Sep 3, 2026](https://x.com/chrissotraidis/status/2095518766696468969): 114,119 views, 1,884 likes, 153 reposts, 641 bookmarks at initial observation | There is already an audience; measure conversion to successful play as well as attention. |
| Direct practice request | [Reply, Sep 4, 2026](https://x.com/epicstrumfailgh/status/2095771888207421830) asks whether UnclePunch works | Particularly relevant demand from an actual prospective MeleePad user. |
| Active practice ecosystem | [Aitch, Apr 10, 2026](https://x.com/rwing_aitch/status/2042363970292760623): TM-CE v1.4 announcement, about 1.2K likes / 184 reposts / 54K views | Research the maintained community edition, not only the original mod. |
| Detailed feedback appeals | [Jazzkid, May 12, 2026](https://x.com/Jazzkid__/status/2054032724717895697): custom exact-frame SDI display, 635 likes / 45K views | Small, useful training improvements can earn attention. |
| Replay-to-practice demand | [Fiction, Jun 23, 2025](https://x.com/FictionIRL/status/1936961001515278577): Melee Improover announcement, about 1.8K likes / 161 reposts / 199K views | Saving a situation and practicing it has a clear player benefit. |
| Character novelty | [sc00p, Sep 9, 2026](https://x.com/ssbmSc00p/status/2097661316378816654): character-port tooling showcase, 2,709 likes / 259 reposts / 445,423 views | Visually obvious modifications make strong demonstrations. This does not prove MeleePad compatibility. |
| Availability boundary | [Creator follow-up](https://x.com/ssbmSc00p/status/2097661501448270156) says the new character tools are hoped to become available soon; [another reply](https://x.com/ssbmSc00p/status/2097661708617593061) promotes the 0.8.3 stage editor | Do not plan around the showcased automation as already released. |
| Creator concerns | [PigsSSBM, Sep 10, 2026](https://x.com/PigsSSBM/status/2097727667843764668): about 1.4K likes / 123K views, concern about automated character imports and craft | Credit creators and make their work easier to enjoy; engagement includes controversy. |
| Cosmetic ecosystem | [Animelee DBZ pack, Mar 23, 2023](https://x.com/VC_Primal/status/1638682029641592832): about 1.1K likes / 182 reposts / 69K views | A coherent visual pack can be a feature in its own right. |
| Easier customization | [Melee Skin Manager, May 15, 2025](https://x.com/mrthesaxon/status/1922674059784999286): 427 likes / 25K views; [Sep 5, 2026 reply](https://x.com/buro0z/status/2096089983010361581) requests easy recoloring | Previewing and managing skins solves real friction; the recolor request is only one anecdote. |
| Casual mode appeal | [Akaneia volleyball, Jan 21, 2021](https://x.com/TeamAkaneia/status/1352043538029150209): about 8.5K likes / 2.1K reposts | Strong historical signal for immediately understandable party modes. |
| Setup friction | [Launch reply](https://x.com/cy_gn_us/status/2095807293883666524): supplied a game file but could not start; [another](https://x.com/Awkwardly_Boy2/status/2095536568890966379) assumes JIT activation is necessary | A clearer path from download to playable build is a growth feature. |
| Input concerns | [Adapter request](https://x.com/obesatron67/status/2095715546784309464) and [latency question](https://x.com/cojackSSBM/status/2095652258444648748) | Validate the actual controller experience and communicate measured results. |

## Prioritized features

### 1. Pocket practice: TM-CE support

**Why:** best combination of direct audience demand, repeat use, and mobile usefulness. Hook: practice ledgedashes or movement during a short break.

**Start:** pin one TM-CE release and target v1.02; privately build one training event; prove reset, timing feedback, controller input, and save isolation on a physical device. Only then expose a Practice entry in the existing menu.

The [current v1.4 release page](https://github.com/AlexanderHarrison/TrainingMode-CommunityEdition/releases/tag/CE-v1.4) includes the v1.4.1 update. It documents Slalom movement practice, techchase and float-cancel events, frame decrement, hitbox trails, SDI display, and ledgedash success feedback. These are upstream features, not features currently in MeleePad.

**Effort:** high; recompiler/runtime integration plus native UI and device QA. Modified DOLs and injected/dynamically loaded code need analysis; simply admitting a different ISO hash is insufficient. Stop the first experiment if code execution cannot be covered correctly without violating the intended runtime model.

**Success:** a player starts, repeats, and completes a useful drill in a short session, with correct feedback and preserved saves.

### 2. Clip and share a moment

**Why:** lets players produce the next wave of demonstrations themselves. This is a product inference from the video-led showcases, not a directly measured demand for a MeleePad clip button.

**Start:** an opt-in recording/clip action in the existing menu, local preview, and the system share sheet. Keep the full gameplay frame; optionally place it in a portrait canvas with a small MeleePad label and creator credit when relevant. Begin with manual capture; automatic combo detection can wait.

[Apple's rolling-clips reference](https://developer.apple.com/videos/play/wwdc2021/10101/) documents a 15-second buffer. Choose APIs against the actual deployment target and SDK; newer documentation marks some ReplayKit methods deprecated in favor of ScreenCaptureKit. Do not assume a universal 30-second buffer or zero overhead.

**Effort:** small-to-medium relative to game-code modifications. Test audio sync, lifecycle, export failure, storage, and frame times/thermal behavior with capture enabled. Never auto-post.

**Success:** a user can save and share a good moment without editing a long recording, and capture does not materially worsen supported gameplay.

### 3. Curated cosmetic packs with creator credits

**Why:** immediate visual differentiation and repeatable creator showcases. Start with a few compatible outfits/stages; no need for a marketplace or an editor inside the app.

[SSBM Nucleus](https://ssbmnucleus.net/download), inspected in Brave, advertises mod organization, previews, shareable bundles, custom characters/stages, and xdelta support. The page offers macOS v0.8.3. It also advertises mobile replay viewing, so mobile replay viewing alone would not be a unique claim.

**Start:** test one genuinely data-only replacement against the exact existing native module; add separate mod storage and a reversible selection; show creator, source link, and tested compatibility. Collaborate on an import format rather than assume Nucleus has an integration API. No outreach has been sent.

**Effort:** medium for a narrow data-only path; high for executable modifications. Classify each pack by what it changes. Even cosmetic-looking assets may affect gameplay or online fingerprints. Keep initial experiments offline and preserve the original data.

**Success:** change a look, play, revert, and share a clip without a broken install. Ship only content with the appropriate distribution permission; user-local import is a distinct route from bundling assets.

### 4. Weekly movement challenges and shareable scores

**Why:** creates a repeatable reason to return and invite friends. Examples: a Slalom time, an Eggs-ercise score, or consecutive successful ledgedashes. These build on upstream practice concepts; the weekly challenge layer is our proposal.

**Start:** one fixed, versioned challenge; personal best stored locally; a share card containing character, rules, score, input category, and challenge version. Begin without accounts or a global leaderboard. Touch and physical-controller attempts should remain distinguishable.

**Effort:** medium after training support; high without it. Requires trustworthy event scoring and reset behavior.

**Success:** repeat attempts and voluntarily shared results. Later competition would need consistent rules and score verification.

### 5. Save this situation, then practice it

**Why:** addresses the concrete question “what should I have done there?” and supports coach/student drill exchange.

[Melee Improover](https://github.com/Fiction52s/Melee-Improover) exports selected situations from `.slp` files for TM-CE. Its README explicitly notes incomplete savestate fidelity. This is useful prior art, not a drop-in native iOS component.

**Start:** after basic training works, prove one version-bound local scenario restore; add a practice bookmark; investigate importing a supported drill format. Keep video clips, `.slp` analysis, deterministic replay playback, and executable practice states as separate capabilities.

**Effort:** high. Existing diagnostic savestate infrastructure does not establish reliable player-facing rewind, replay takeover, or cross-version portability.

**Success:** restore and retry a known situation accurately, including controller/timing behavior, without corrupting normal saves.

### 6. Akaneia volleyball / party-mode support

**Why:** easy to understand in seconds, entertaining for casual groups, and a different story from ranked online play.

[Akaneia's repository](https://github.com/akaneia/akaneia-build) documents new fighters, stages, music, and modes using [m-ex](https://github.com/akaneia/m-ex). Its modified image and executable behavior make this a separate compatibility target.

**Start:** one pinned build and one mode, locally, with two physical controllers. Prove a complete round and restart before expanding to characters or online play.

**Effort:** very high / uncertain until m-ex's code-loading and dispatch requirements are mapped. Do not commit to a full expanded roster first.

**Success:** a complete, stable volleyball round on a physical iPad, ready for a short authentic demonstration.

### 7. Controller confidence and measured responsiveness

**Start:** extend existing mapping with an input test/calibration view, explicit connected-controller status, and exportable profiles. Validate one named controller end to end. Investigate exact GameCube adapters separately for each Apple platform; a USB connector alone does not establish iOS support.

**Effort:** small-to-medium for diagnostics; adapter support is uncertain. Measure physical input-to-display latency independently of FPS. UCF is a separate gameplay modification with revision and online compatibility implications, not a blanket latency fix.

**Success:** players can verify their buttons/sticks and choose a tested setup. This supports retention more directly than a flashy trailer.

### 8. Guided local build and import

**Start:** a Mac setup assistant around existing scripts: verify prerequisites and game identity, build the matching module, guide signing/install, and show useful progress/errors. In the app, explicitly distinguish missing game data, missing native module, and mismatched revision.

**Effort:** medium; signing/build tooling and real clean-machine testing. Importing an ISO alone cannot make the public shell playable. The assistant must preserve the local build and signing boundary.

**Success:** more interested users reach their first playable session; fewer “I imported my game and it will not start” reports. No new hosting service is required.

## Current-app cross-check

- `README.md` already documents touch/physical controllers, higher resolutions, persistent saves, experimental rooms, and serious performance/rendering limitations. These should not be repackaged as newly discovered ideas.
- `apple/ios/MeleePadGameOverlay.mm` already offers experimental 16:9 and offline unlock-all. The audience's widescreen question is best addressed through correctness and visibility, not a duplicate setting.
- `apple/ios/MeleePadCoreHost.mm` preserves offline Action Replay/Gecko selections and disables cheats for netplay. This is not evidence of arbitrary mod compatibility.
- `docs/MELEE-VERSIONS.md` restricts admitted images, verifies the executable, and requires matching module/data identities. Mod profiles need deliberate extensions to those rules.
- No ReplayKit/RPScreen integration was found in the inspected iOS host/view-controller/settings files; confirm the complete implementation surface before coding.
- The current README records heavy iPhone scene slowdowns and rendering defects. New capture, HD packs, and visual effects need performance budgets.

## Suggested order

1. Prototype clip export and clearer setup diagnostics; verify overhead on the currently supported device workload.
2. Run a bounded TM-CE feasibility experiment with one event. This is the first major feature research target beyond Slippi.
3. Prove one data-only cosmetic pack and make a creator-credited demonstration.
4. Add one weekly challenge once training is dependable.
5. Pursue practice bookmarks and Akaneia separately after their execution requirements are established.

Retain Slippi as its own program. Avoid expanding this pass into Android, Brawl/Project M, an in-app mod marketplace, a full skin editor, or unverified 120 Hz claims. Those do not solve the immediate “something useful and shareable on an iPhone/iPad” opportunity.

Suggested evaluation: successful setup-to-first-play, repeat practice sessions, clip exports/shares, challenge retries, and bug/performance regression rate. Collect tester feedback or explicitly opted-in aggregate metrics; X likes alone are not the success criterion.

## Second pass: more opportunities and a narrower implementation path

Continued in Brave on September 10. Additional searches covered recent SSBM/Slippi tools, Aitch's current posts, Diet Melee, Break the Targets Randomizer, and Phillip. Public upstream documentation and the local runtime were inspected; nothing was built or installed. The current working tree includes other active work, including a separate Slippi feasibility report; this pass changes only this research document.

### 9. Daily seeded Break the Targets

This is a more concrete version of the earlier challenge proposal and can be investigated independently of TM-CE. Everyone gets the same character, course and rules; players share a time and a link/code for friends to attempt it.

The [creator's September 2020 announcement](https://x.com/sirquine/status/1306325619509137409) shows roughly 1.7K likes and 369 reposts. [A March 2022 follow-up](https://x.com/sirquine/status/1503393023639658502) describes the fourth community competition and the next one starting. That supports historical repeat participation, not just a one-off trailer.

The live [Break the Targets Randomizer](https://bttrandomizer.com/) exposes seeds, share links, fixed randomized target locations, stage-specific placement rules and adjustable completion conditions. It generates Gecko codes. Therefore the challenge is not merely a native menu feature: those writes/injections must execute correctly under our runtime.

**First experiment:** one vetted course on one stage with one character. Inventory the generated code, distinguish data writes from executable injections, and compare repeated resets and completion timing. Store generator version, complete rule definition and target positions with a challenge; a seed alone is insufficient to ensure future reproducibility. A daily schedule can be computed locally without accounts or a hosted leaderboard.

**Product scope:** a normal vanilla target course with personal bests is the fallback first version if custom code support is too expensive. Randomized target layouts are a separate gate. Separate touch and controller result categories; record timings using game frames, not wall-clock elapsed time.

**Effort:** medium-to-high and dependent on code inspection. **Useful outcome:** short solo sessions, a repeatable challenge, and a simple invitation to a friend. This now ranks above a broad Akaneia integration for an initial challenge experiment.

### 10. Configurable practice opponents; warm up while waiting

Aitch's [Preflight announcement, August 15, 2026](https://x.com/rwing_aitch/status/2088310443056201990) has about 1.5K likes, 277 reposts and 105K views. The author describes configurable CPU behavior and practice during matchmaking. The [September 3 update](https://x.com/rwing_aitch/status/2095200089119838500) adds practice while a Direct opponent is not yet locked in, improved recovery, and save/load state. The [June preview](https://x.com/rwing_aitch/status/2067349937441104085) attracted about 192K views.

**MeleePad adaptation:** start with explicit offline habits, such as a retreating Fox or an opponent repeating a chosen approach, instead of a generic difficulty slider. A drill should let a player explain what they want to practice. Later, allow compatible warm-up play while a room is waiting and transition cleanly when everyone is ready.

**Boundary:** Preflight is a distinct project from TM-CE. The author's [distribution reply](https://x.com/rwing_aitch/status/2088322252530233356) describes Patreon access. This pass did not obtain its source or establish integration/redistribution terms. No purchase or contact was made. Its concepts are product evidence, not available source-code components. A MeleePad waiting-room feature also needs deliberate lifecycle/state coordination; Slippi queue behavior is not present merely because the UI has a room.

**Effort:** medium-to-high for a narrow offline training behavior; high for integrating an existing mod or matchmaking flow. **Useful outcome:** practice a matchup problem even when no friend is available.

### 11. Optional lightweight graphics profile inspired by Diet Melee

The [Diet Melee v1.0 announcement, February 2021](https://x.com/DietMelee/status/1361096821087625218) has about 1.3K likes and 273 reposts. Its [official site](https://diet.melee.tv/) describes lower-poly stages and fighters for slower hardware.

This is unusually relevant to MeleePad's existing heavy-scene performance debt. However, reduced geometry cannot be assumed to fix every CPU or timing bottleneck, and there is no measured MeleePad gain from this research.

**First experiment:** inspect one candidate lightweight asset change, then compare the same scene, characters, inputs and resolution against the original over a sustained physical-device run. Measure frame-time tails, audio underruns and thermal state. If performance improves without changed gameplay/collision behavior, offer an explicit reversible lightweight profile with its visual tradeoffs visible.

Do not replace the default with the entire Diet build: its [FAQ](https://diet.melee.tv/faq/) describes removal of substantial single-player and other content. Its [changelog](https://diet.melee.tv/changelog/) includes fixes for a Stadium desync and a move-timing issue, illustrating why simpler-looking content still needs gameplay validation. A standalone texture replacement is not a low-poly model replacement.

**Effort:** medium-to-high depending on asset and executable changes. **Useful outcome:** more stable supported devices and potentially longer comfortable sessions. Battery/thermal benefits remain hypotheses until measured.

### 12. A stronger offline sparring bot

There is an established audience for playing a capable Melee bot: [Aklo's June 2024 post](https://x.com/NotAklo/status/1797742885904994791) describes playing Phillip, and [Nicki's November 2025 post](https://x.com/upgamer_Nicki/status/1987608383307092353) shows roughly 1.4K likes and 66K views.

The [Slippi-AI/Phillip II repository](https://github.com/vladfi1/slippi-ai) publishes code and links trained models. Its documented local path uses Python, a trained policy, and a Slippi Dolphin integration. This establishes a real research starting point; it does not establish a mobile inference library or iPhone performance.

**First experiment:** identify one released model and its input/output contract, reproduce inference on recorded game observations, then measure a prospective Apple runtime for numerical parity, latency and memory. Only after that should it be connected to game state and input. Start with one character and an explicit reaction delay.

**Effort:** high and uncertain. **Useful outcome:** worthwhile offline matches without a player population or network connection. Do not promise famous-player personalities, a recreation of a specific pro, or that a generic language model can play at frame rate. An unverified “Melee Classic” claim found in search was not treated as a released product.

### Technical finding: start cosmetics with renderer texture replacement

The pinned local Dolphin tree (`e13ab348f1`, with MeleePad's local patches) already includes `VideoCommon/HiresTextures.cpp` in its build. `HiresTexture::Update` scans game-specific texture directories for PNG/DDS files, and `TextureCacheBase.cpp` looks up and validates replacement textures when `GFX_HIRES_TEXTURES` is enabled. The flag defaults off; no matching product integration was found in the searched Apple sources and iOS scripts.

This supports a bounded first cosmetic prototype without modifying the game's disc or executable:

1. Make an original, unmistakable replacement image for one known texture identifier. Import it into an isolated pack location and enable the existing renderer path.
2. Confirm the change actually appears on a physical device, persists after restart, and cleanly reverts when the pack is disabled.
3. Measure memory and loading stalls before adding a pack picker, dimension limits and previews to the existing UI.

This is source-level feasibility only. Texture identifiers, file access, cache invalidation, Metal rendering, and device memory behavior still need validation. Nucleus/DAT model replacements are different formats and cannot simply be dropped into this path. Texture replacement can change surface appearance; it cannot add a fighter, alter model geometry, or provide Akaneia support.

### Technical finding: TM-CE and Slippi share an execution prerequisite

[TM-CE's development guide](https://github.com/AlexanderHarrison/TrainingMode-CommunityEdition/blob/master/DEVELOPMENT.md) documents Gecko branches installed over existing instructions and C events compiled into m-ex modules. It also explains that DAT containers can hold code as well as visual data. File extensions therefore cannot classify a mod as data-only.

The local `StaticRecompCore_SMC.cpp` marks chunks whose memory hashes change as failed and reports interpreter execution until invalidation. Prepatching only the retail DOL does not by itself cover later-loaded executable content. Inventory load addresses, relocations and callbacks, and preserve code validation. The [separate Slippi feasibility report](SLIPPI-FEASIBILITY-2026-09-10.md) identifies a related prerequisite; its execution inventory may inform training support, but neither feature automatically validates the other.

For an eventual upstream contribution, TM-CE's guide explicitly rejects AI-generated code contributions. That is an upstream submission constraint, not a prohibition on inspecting the project or conducting an independent compatibility experiment. No upstream contribution or partnership is implied by this research.

### Updated decision

| Track | Smallest useful next result | Gate before expansion |
|---|---|---|
| Shareability | Export one short gameplay clip | Correct video/audio and acceptable capture overhead |
| Cosmetics | One original renderer texture replacement | Physical display, clean reversal, memory budget |
| Mobile performance | One lightweight asset comparison | Repeatable benefit without changed gameplay |
| Replayable solo content | One fixed target-course challenge | Correct timing, reset, reproducible course identity |
| Serious practice | One TM-CE event execution inventory/prototype | Injected and loaded code coverage plus accurate feedback |
| Offline opponents | One explicit practice behavior | Stable game-state and input control |
| Learned bot | One model inference benchmark | Apple-runtime parity and latency before gameplay integration |

The most distinctive plausible release package is **practice, personalize, and share**, with target challenges broadening the casual audience. Clips and texture replacement remain the smaller candidates; TM-CE remains the strongest requested flagship. A lightweight graphics experiment should precede any claim that a mod makes MeleePad faster.
