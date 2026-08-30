# G8 save and settings persistence

Date: 2026-08-30

Status: **G8 row 8 pass**

## Requirement

PRD row 8 requires name entry and settings to persist across a full relaunch
on macOS and the iPad Simulator. A visible post-relaunch product state is the
acceptance signal; merely finding a save file is not sufficient.

## iPad Simulator

- Target: iPad Pro 13-inch (M5), iOS 26.5, UDID
  `68016FEA-1887-4E05-A7F4-B26EC8572B8A`.
- The live SsbmPad menu enabled `Show FPS`. After normal termination and
  relaunch, the FPS label returned and the sandbox preference remained true.
  The temporary test setting was restored to false afterward.
- Melee's live Name Entry screen created `CODX`. The card file changed from
  SHA-256
  `a38824716e60201d84e21795b6bd274c7478054e47c1859952751af11f1dfc7c`
  to a new saved state. After normal termination and relaunch, navigation back
  to Name Entry visibly showed `CODX`.
- The retained post-relaunch screenshot is
  `screenshots/2026-08-30/g8-ipad-name-entry-after-relaunch.jpg`, SHA-256
  `519269af97f621beb3e851bf391b89aaf937c77f2c856741a0f037695c8abddc`.
- Reinstalling the rebuilt app changed the data-container UUID, but Simulator
  migration retained the imported game, preferences, and memory-card data.

## macOS

- Melee's live Name Entry screen created `CODM`. The GCI changed from SHA-256
  `5fd9152de18e51987f237b871189adeaacfeafed90f2c45b1e4d2aa43d36fd74`
  to `812c246dcdcd24e3f04316b09ab8a1b1b80a741dd04726454ee023b953e7af39`.
- The runner was closed through its window, exited cleanly, and a new process
  was started against the same user directory. Navigation back to the Rumble
  settings visibly showed the retained `CODM` name.
- The retained name screenshot is
  `screenshots/2026-08-30/g8-macos-name-entry-after-relaunch.jpg`, SHA-256
  `40f99e387ba593ac16cd8eb8f2a1306fc42a5fcaf3f7447fe68d2bf910287d9e`.
- The SsbmPad launcher was then closed and started as a new frontend process.
  Its persisted `Show FPS in window title` setting returned checked, matching
  `show_fps_in_title=true` in the launcher configuration.
- The retained settings screenshot is
  `screenshots/2026-08-30/g8-macos-fps-setting-after-relaunch.png`, SHA-256
  `6e048aa966af0fd500c57eb6012834f443ddb4bdb45bce86339771adaf2e225c`.
- An additional live game-setting exercise changed Sound from Stereo to Mono
  and produced a normal save notification. It is supporting interaction
  evidence only; row acceptance relies on the visually read-back launcher
  setting above rather than inferring a setting from private save bytes.

## Cleanup and boundary

- No ROM, extracted game data, generated module, preference file, or GCI is
  committed.
- The app and runner were closed normally and the sole Simulator was shut
  down.
- This closes only row 8. It does not promote combat performance, audio
  continuity, lifecycle, clean-clone, or netplay rows.
