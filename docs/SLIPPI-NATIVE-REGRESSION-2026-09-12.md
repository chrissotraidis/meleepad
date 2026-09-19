# Native Slippi regression investigation — 2026-09-12

Status: in progress. The hardware boot/menu regression is corrected; sustained offline gameplay, physical audio, Simulator gameplay, and interoperability are not yet accepted.

## Confirmed cause

The latest private hardware bundle carried a vanilla GALE01 v1.02 module under `gGALE01r2_slippi_recomp.dylib`. All 238 verification chunks matched the vanilla module. It lacked the injected Slippi native range `0x8065cc80–0x8066aa10`; 67 original-text chunk hashes differed from the earlier Slippi module. Slippi patches therefore demoted broad code regions to the interpreter. Disabling fallback JIT does not disable interpreter fallback.

The earlier private module matches the loaded Mach-O sections of the retained `ref/slippi-compatibility/native-gct-ios-001/build/gGALE01_recomp.dylib`. It has 242 verification chunks and native coverage of the injected range. That exact retained device module was restored, without regenerating device code.

A previous install also had an unsigned root module while another copy was signed. The current private bundle signs every dylib, synchronizes the root/private Slippi copies, verifies bundle signatures, and logs the SHA-256 of the actual resolved module on device. The observed installed SHA-256 is `1c86303a2291585438f9fbd5f6b71241c690162f81f215a8aa4e41b5addeb490`.

## Changes

- Module staging now reads the generated Mach-O descriptor and rejects modules without the required native Slippi injected-code coverage. Existing revision and platform checks remain mandatory.
- Staging updates an existing private module copy along with the root copy.
- The existing centered-label fix is retained and visually confirmed on physical character select.
- Five-second FPS/VPS/speed/frame-interval samples reuse runtime counters and write private `performance.csv`; no media is captured by this instrumentation.
- Module identity, initial/final thermal state, and inherited host-thread QoS are logged.

Always stage Slippi modules **and resources after Xcode builds**: Xcode copies Dolphin's stock GameINI. One instrumented baseline rebuild was caught at the `code_set` check (exit 6) and is excluded from performance evidence. The corrected bundle explicitly restages the pinned Slippi GameINI, bootloader, and override pack. The checks were not relaxed.

## Fresh hardware evidence

Both runs used the existing physical iPad container, revision 2 disc and account. The original run had no scripted menu input. The corrected bounded run likewise contained no input or match.

| Measurement | Original installed module | Restored Slippi module |
|---|---:|---:|
| Native dispatches | 35,535,982 | 177,659,552 |
| Interpreter fallback steps | 1,367,211,031 | 3,664,961 |
| Failed verification chunks at shutdown | 25 | 0 |
| FPS, sampled over 40 seconds | Not collected | 59.927–59.951 |
| VPS | Not collected | 59.939–59.941 |
| Speed ratio | Not collected | 0.99935–1.00058 |
| Frame-time p95 upper bound | Not collected | 18 ms |
| Maximum frame interval | Not collected | 32.768 ms |
| EFB | Not collected | 640 × 528 |
| Thermal state before/after | Not collected | Nominal / nominal |
| Actual matches | 0 | 0 |

Counters describe bounded boot/menu runs, not equal guest-work benchmarks. The user's original approximately 3 FPS observation has not independently been measured as FPS; the fresh original-module run independently reproduced extensive fallback.

Corrected startup-to-ready was approximately 54.5 seconds. The ready callback precedes `Runtime::Run()` and is not itself boot or performance acceptance. The samples above were collected during the actual runtime afterwards. Initial/final thermal state was nominal. CPU/GPU utilization and physical-speaker audio are not yet measured.

A bounded QuickTime still check confirmed physical Slippi character select without the centered label. The mirror was closed immediately afterwards; no movie recording was started. Capture-affected time is excluded from the earlier bounded performance run.

## Remaining verification

- The existing Simulator configuration also selected a vanilla module. Its previous screenshot/menu report is not accepted as proof of native Slippi gameplay. A module is being compiled for Simulator from the same retained Slippi-generated source.
- Input-driven physical navigation reached Slippi character select; an unsupported online-mode error was visible. Offline match acceptance remains pending.
- Some injected-code chunks can fail again after account/menu state changes. A runtime heap pointer at `0x80668590` lies inside one hashed code/data chunk and is overwritten by guest code at `0x806689e0`. This is a specific hypothesis requiring exact changed-byte confirmation. No verification guard has been bypassed.
- Zero-byte override lookups for `SdToy.dat`, `GmEvent.dat`, and `LbAd.dat` are expected: the guest resumes the original disc loader when no override exists.
- Local account staging was confirmed, but service authentication, actual Slippi desktop compatibility, matches, rollback, rematches, and disconnect recovery remain unproven. Current search guards allow only Unranked and valid-code Direct; other modes remain gated.

Private raw logs, bundle manifests, module comparisons, backups and install results are under `/private/tmp/meleepad-native-audit-0912`. They must not be published. No app uninstall, container clearing, credential change, main-branch push, or private-data staging was performed.

## Unranked search correction

The guest `HandleInputsOnCSS.asm` sends the saved opponent-code buffer for **every** mode; its comment explicitly says that buffer only matters for Direct. The previous host policy incorrectly required an empty buffer for Unranked. Unranked now ignores that buffer, while Direct still validates it. Ranked/Teams/Party remain gated, with a mode-specific error rather than the ambiguous combined message. Fifteen policy checks passed, including Unranked with a retained Direct code and rejection of malformed Direct codes. This corrects a local rejection; it does not establish service or peer acceptance.

## Simulator checkpoint

The dedicated MeleePad iPad Simulator now uses a newly compiled iOS Simulator module from the same `native-gct-001/codegen/generated` source. Its generated verification tables are byte-identical to the retained device module's tables. Platform binaries are necessarily distinct.

A fresh bounded native run loaded the retained simulator account, reached runtime readiness in about 14.5 seconds, and subsequently measured approximately 59.94 FPS/VPS and 1.00× speed. After startup, frame-time p95 upper bound was 18 ms; the run included a 65.3 ms interval, and initial startup sampling included 125 ms. No match occurred in that window. Direct touch input navigated Online Play → 1-P → Main Menu → VS Mode → Melee. A concurrent GalaxyPad task then launched another app in this same simulator, invalidating continued gameplay acceptance. Device coordination is pending.

## Rebuild/install order

Run from the repository root with the existing private dependency tree prepared. Supply local values for `MEE_BUILD`, `MEE_PRIVATE_QA`, `MEE_SIGNED_REFERENCE`, `MEE_SIGN_IDENTITY`, and `MEE_DEVICE`; these contain private local paths/signing/device information and must not be committed. `MEE_PRIVATE_QA` is the retained directory containing `GALE01-r2.iso` and `GameData-r2/GALE01`. Keep all output private.

```sh
python3 scripts/check-ios-slippi-build-inputs.py
xcodebuild -project MeleePad.xcodeproj -scheme MeleePad \
  -destination 'generic/platform=iOS' -configuration Release \
  -derivedDataPath "$MEE_BUILD" CODE_SIGNING_ALLOWED=NO build
MEE_APP="$MEE_BUILD/Build/Products/Release-iphoneos/MeleePad.app"
cp -cR "$MEE_PRIVATE_QA" "$MEE_APP/PrivateQA"
python3 scripts/stage-ios-modules.py "$MEE_APP" --platform device \
  --slippi-module ref/slippi-compatibility/native-gct-ios-001/build/gGALE01_recomp.dylib
cp "$MEE_SIGNED_REFERENCE/embedded.mobileprovision" "$MEE_APP/embedded.mobileprovision"
codesign -d --entitlements :- "$MEE_SIGNED_REFERENCE" > "$MEE_BUILD/private-entitlements.plist"
find "$MEE_APP" -type f -name '*.dylib' -exec \
  codesign --force --sign "$MEE_SIGN_IDENTITY" {} \;
codesign --force --sign "$MEE_SIGN_IDENTITY" \
  --entitlements "$MEE_BUILD/private-entitlements.plist" "$MEE_APP"
codesign --verify --deep --strict "$MEE_APP"
xcrun devicectl device install app --device "$MEE_DEVICE" "$MEE_APP"
xcrun devicectl device process launch --device "$MEE_DEVICE" \
  --terminate-existing com.meleepad.MeleePad -- -meleepadSlippi
```

The device `dev-config.plist` must select revision 2, the private disc/root above, and root `gGALE01r2_slippi_recomp.dylib`; the existing prepared device provisioning has these entries. Verify them before install. Preserve the existing container; do not uninstall. Check the module hash logged by the installed process against the signed root/private copies. For a bounded boot-only measurement, add `-meleepadSlippiAccountBootCheck`; omit it for user gameplay. Do not add the scripted menu probe to the user test build.

## Preservation check

All ten pre-existing `User-r2/Config` files remain byte-identical after the in-place updates. The existing `User-r2/GC` directory was empty before and after. Preference differences are limited to rebased extracted-game-root and retained-disc paths after bundle replacement. The account continues to load from the existing store. The legacy `com.ssbmpad.SsbmPad` process was terminated without removing its app or data; only the requested MeleePad bundle remained running at the process check.

The user-facing build is installed with the Unranked buffer correction. It is a private test build, not a completed online release. The original objective remains open pending uninterrupted Simulator/offline gameplay, sustained physical match/audio evidence, and network interoperability results.

## Hardware Unranked search follow-up

The user subsequently confirmed the specific Ranked rejection and reported an indefinite Unranked search using an Xbox controller. The hardware app log confirms the controller connection and restored module hash. The Dolphin log is empty, and the unfinished run has no final runtime report. A bounded debugger read of the then-current process returned zero search/state-transition counters and an unobserved state (-1); this snapshot cannot establish what happened in the reported search. The debugger was detached. No server rejection, accepted ticket, opponent assignment, or peer-connection failure has yet been demonstrated for that report.

The five-second performance CSV now also records atomic search counts, latest observed matchmaking state, and cumulative initializing/ticket-ready/opponent-connecting/connected/error transitions. This preserves evidence while a search is still running and contains no credentials, names, addresses, or server payloads. A fresh user-driven search is required to identify the failing stage. Ranked remains intentionally disabled.

The subsequent installed build captured a real user Unranked search: one initializing transition, one accepted ticket (state 2), no opponent assignment or connection, and no errors through 172 seconds of runtime. Presentation remained approximately 59.94 FPS/VPS. A bounded debugger snapshot located the matchmaking worker inside `handleMatchmaking → receiveMessage → enet_host_service → enet_socket_wait → __select`; the debugger was detached. This establishes server ticket acceptance and a receive wait, not gameplay interoperability. The production host selection and ticket field structure match the inspected official 3.6.4 client. The custom `3.6.4+meleepad.probe` version suffix remains a compatibility difference to investigate; it was not changed speculatively.

The user then identified an enabled iPad VPN, turned it off, and reported that it reconnects automatically. At 382 seconds the counters show two Unranked searches, two accepted tickets, one error transition, and still no opponent assignment. The error's cause is not recorded, so it cannot be attributed conclusively to the VPN. A search with a stable VPN-off connection is pending identification of the VPN's automatic reconnect setting.

## First physical Internet opponent and performance follow-up

The user disabled NordVPN Connect On Demand and initiated a third Unranked search. This received an accepted ticket, an opponent assignment and a successful peer connection, followed by a game start. The user confirmed playing a real opponent, severe slowdown, a poor-performance warning and a disconnect. This supersedes the earlier "no opponent assignment" status. The custom version suffix did not prevent this connection and was left unchanged.

The disconnected session was stopped through the existing atomic runtime stop flag, after checking the process identity and idle matchmaking state, so normal shutdown could flush its trace. No game-memory state was changed; the debugger detached immediately. The final report records one game start/end, zero boot/memory/graphics errors, and 729 game-frame bookends. Frame timing spans -123 through 421: 545 distinct frames, 27 backwards frame transitions, 23.126 seconds wall time and 9.533 seconds CPU-thread time. Several intervals exceed 0.8 seconds; the worst is 1.523 seconds. Presentation samples around 58 FPS therefore do not establish full-speed game simulation.

The local automatic poor-performance debt termination is gated to Ranked. Unranked has a slowdown warning and a seven-second missing-input disconnect path; the available completed trace does not establish which side ended the match or whether the root cause is packet delay, local rollback cost, or both.

Comparison with official Ishiiruka v3.6.4 confirmed matching basic pad/ack packet layout and identified a missing Apple socket setting. The candidate now applies `SO_NET_SERVICE_TYPE = NET_SERVICE_TYPE_RV`, matching [the official Apple path](https://github.com/project-slippi/Ishiiruka/blob/v3.6.4/Source/Core/Core/Slippi/SlippiNetplay.cpp). This is a targeted candidate fix, not a proven explanation of the observed stalls. New numeric-only `network.csv` telemetry records ACK latency samples, input stalls, time-sync advances, malformed packets, forced stall disconnects, peer disconnect events/reasons and the socket-setting return value. Account, addresses and packet payloads are excluded. Build and search-policy checks pass; performance acceptance requires another physical match.

The next physical attempt confirms the socket setting succeeded (return 0), but the short match still failed. Eighty input ACK samples average 433.9 ms: the first 19 average 995.9 ms and the next 61 average 258.8 ms, with the last sample 74.2 ms. These measure input-send-to-ACK latency including local queue/processing delay, not isolated Internet round-trip time. The runtime recorded 163 missing-input stalls, three time-sync advances, zero malformed-packet errors, zero local seven-second stall disconnects, and one connected-peer disconnect event carrying reason 0 (unspecified). One game started and produced 156 bookends before returning to idle. This does not prove a voluntary opponent quit or identify where the delay originated. The Apple socket adjustment alone is not an accepted fix.

The user continued searching; at the subsequent 430-second runtime sample, search two was in accepted-ticket state without another connected match. The app remained running throughout these read-only log checks, with no debugger attachment or installation during the user's attempt.

## Two-match delay investigation and display controls

The second game in the same physical run added 176 ACK samples averaging approximately 685 ms, 310 missing-input stalls and a second unspecified peer disconnect. Across both games there were 256 ACK samples, 473 input stalls, nine time-sync advances, no malformed packets and no local seven-second forced disconnect. The user reported the opponent's preset bad-connection quick chat. These measurements do not isolate wire latency from local queue or processing time.

A loopback test using the bundled ENet implementation delivered all 300 queued unsequenced packets; measured maximum queue dwell was 160 microseconds and delivery 269 microseconds. This host test does not establish hardware network behavior. The upstream 250 ms service wait has a working wakeup mechanism in that test, so it was not replaced with busy polling. New numeric-only diagnostics measure queue dwell, service-loop gaps, send failures, ENet RTT/variance/loss and CPU-thread snapshots of native dispatch/fallback/verification counts. Bounded game-phase captures now include online phase 4. No invalidation or compatibility safeguard was weakened.

The active Slippi menu now presents directions for Unranked, Direct and preset quick chat; its Simulator routing was verified by opening the actual menu. Render scale and aspect settings now reach the Slippi runtime. An initial candidate crashed because a background NSUserDefaults notification applied graphics settings before Config's CurrentRun layer existed. The corrected code handles notifications on the main thread and retains/checks the configuration layer before changing it. Hardware subsequently reached runtime-ready at 02:37:52 UTC and remained running after the bounded console session ended. The legacy bundle process was separately stopped without deleting its data.

Both device and Simulator builds passed, and the 93-path build-input contract check passed. In the isolated Simulator, selecting 2x produced measured 1280x1056 EFB dimensions at approximately 59.94 FPS. These are boot/UI checks, not renewed physical match acceptance. The latest installed candidate requires a user-driven match to attribute the remaining delay. Ranked remains disabled; the full goal is still open.

## Isolated Simulator gameplay baseline

A separate iPad Simulator was used without changing Galaxy's simulator. Ordinary accessibility controller actions navigated native menus into Training, where jumping and attacking advanced the game and damage counters. A subsequent normal offline Samus-versus-CPU Captain Falcon match on Battlefield at 2x rendering recorded 8,061 bookends. The measured frame-120-to-7,937 window advanced 7,817 frames in 130.422 seconds wall time, or 59.936 simulation frames/sec, with 70.238 seconds CPU-thread time, 17.425 ms frame-time p95 and 117.076 ms worst interval. The 26 steady presentation samples averaged 59.901 FPS and 59.905 VPS. Audio output progressed through 12,227 callbacks; two DMA underruns were recorded. This establishes a playable Simulator offline path with observed output, not audible-quality or physical-gameplay acceptance.

The completed run reported zero boot, memory or graphics errors. Its three bounded GCT captures (frames 60/180/300) were identical. All 242 immutable fixture chunk hashes matched the simulator module tables. Within the failed 16 KiB chunk, only the four-byte DATA_LDB_ADDR field at 0x80668590 changed; the other 16,380 bytes matched. The suspected data-pointer explanation is now confirmed for these offline captures. Since offline gameplay remained near full speed, this does not establish the cause of online stalls. Correctness guards remain intact.

Native-counter snapshots previously ran only at online-input commands. They now also run at EXI frame bookends so normal offline versus matches can provide comparable counters. The audio report scope now correctly says observed game window rather than assuming every observed game is online. Simulator rebuild and build-input checks passed.

The retained Simulator account was found to be a placeholder, and no search was submitted with it. The running physical app's existing account was copied privately for a bounded Simulator test without printing credential values or changing the physical account. The Mac's VPN services were disconnected. The Simulator's real-account Unranked search received an accepted server ticket; opponent/gameplay results are pending.

The bounded real-account Simulator search remained in accepted-ticket state for 460 seconds with no opponent assignment, no game start, and no matchmaking error. It was cancelled through the native Z control, then stopped through Exit to Home. The completed report confirms zero boot/memory/graphics errors. Its temporary account transfer file was removed, normal runtime teardown removed the staged runtime account, and the Simulator's previous placeholder account was restored. The physical account was unchanged. This is service ticket acceptance, not a failed peer connection or successful online performance test.

## Symmetric current-build Simulator networking

A private loopback-only fixture build reused the current Simulator objects, libraries and byte-identical native modules, changing only the synthetic account host, matchmaking destination and network guard. The app has a separate bundle identity. A first pairing with a retained older desktop native peer completed a short game window but progressed at 37.70 frames/sec; its ACK average was 0.19 ms and queue maximum 0.512 ms. The older peer logged roughly 34 frame increments/sec and 663 million fallback steps at shutdown. This run is not evidence that the current Simulator alone is slow.

A second private app on a separate Simulator used the same current core/module and synthetic player 0. Galaxy's Simulator was not modified. The symmetric pair completed one eight-minute match with 28,924 finalized frames (-123 through 28,800). All 86,843 emitted player, RNG and item packets matched exactly, with no unfinalized tail or trace overflow. No rollback was observed in this near-zero-latency test, so delayed-input correctness remains a separate check.

Across 94 steady samples per participant, FPS/VPS averaged approximately 59.94 and speed ratio approximately 1.0. The bounded frame-timing windows had p95 17.18/17.08 ms and maximum 23.34/23.50 ms. Mean ACK latency was 0.179/0.135 ms. Both recorded zero send failures and zero forced stall disconnects; each recorded one audio DMA underrun over the observed game window. Both complete reports had zero boot, memory or graphics errors. Initial matchmaking error counters came from the first local fixture expiring during setup, before the successfully assigned match. Native verification failures and interpreter fallback remained present while the pair ran at full speed; guards were not weakened.

These results establish current-build Simulator-to-Simulator loopback gameplay and emitted-state agreement for this match. They do not establish Internet latency, official desktop interoperability, physical iPad performance, or audible-quality acceptance. Controlled delayed-input and rematch tests follow separately.


## Controlled delay follow-up

A zero-delay UDP relay was first validated between the same two synthetic Simulator clients. Its 180-second lifetime included 36.8 seconds of setup, followed by 8,398 common finalized frames. All 25,372 emitted player/RNG/item packets matched exactly. Both traces ended with the same seven unfinalized frames when the relay intentionally stopped. All 33,233 relay datagrams were forwarded, with zero invalid-source, queue-cap, or send drops; average relay residence was 0.037 ms. Both runtime reports recorded zero boot, memory, graphics and matchmaking errors, and zero observed audio DMA underruns. The runtime's eventual missing-input stalls and one send failure per side followed deliberate relay shutdown; they are not evidence of traffic loss while the relay was operating.

The controlled relay supports a bounded 60 ms delay in each direction for the subsequent rollback test. It uses synthetic identities, an OS loopback network sandbox, and no datagram payload logging. The measured delay, finalized-state agreement and rematch result must be reported separately from physical Internet acceptance.

The 60 ms each-way run completed a natural eight-minute match and then started a second game over the same connection, using ordinary touch-control actions to move, jump and attack. All 152,371 relay datagrams were forwarded with zero drops; measured average one-way relay residence was 60.586 ms. ACK averages were 121.714/121.423 ms. Each client's 94 progressing steady game-one intervals averaged approximately 59.94 FPS/VPS, with histogram p95 at most 18 ms and observed interval maxima 37.21/37.75 ms. Both reports had zero boot, memory, graphics and matchmaking errors and zero send failures. The observed first-game audio window recorded zero DMA underruns. The peer's one input stall and disconnect followed the intentional Exit to Home ending the bounded rematch.

The first game had 20/34 rewinds and 26/44 changed-prediction frame events. All 28,922 common finalized frames and 87,230 emitted player/RNG/item packets matched. Both clients observed frame 28,800 and game end, but finalized only through 28,798: the last two frames remain outside finalized-state acceptance. The new strict complete-match gate therefore correctly returns false; do not describe this as all frames finalized. The second game's 7,966-frame common finalized prefix also matched exactly with changed predictions observed; it was deliberately stopped, not a complete second match. Trace metadata reported no overflow or sequence errors.

The analyzer now rejects sequence-error metadata and offers explicit complete-match and changed-rollback requirements. Its 17 tests cover false acceptance of unfinished games, excluded tails, missing beginnings and absent changed predictions. During the delayed match, the actual multiplayer help action opened and returned to gameplay, and changing render resolution from 1x to 2x changed measured EFB dimensions from 640x528 to 1280x1056 without breaking the connection. Physical Internet performance remains unaccepted.

A separate diagnostic compared the two latest observed tail frames (28,799 and 28,800): each had three complete packets per client, and both packet lists matched. They remain unfinalized. The pinned recording code is consistent with a timeout leaving this tail: SendGameEnd waits for ODB_IS_GAME_OVER only for normal completion, while FlushFrameBuffer skips an empty buffer and otherwise uses stable finalization unless the game-over flag is set. The captured game-end payload was not retained, so this source explanation is an inference, not proof of the exact end reason. No acceptance gate was weakened.


## Live simulation-progress telemetry

The performance CSV now separates displayed FPS from game simulation progress. It records the latest observed game frame, latest finalized frame, cumulative new frame progress, and rewind events. Replayed frames do not increment new progress, and beginning a rematch resets the per-game high-water mark while retaining cumulative counters. This addresses the earlier physical report where near-60 presentation samples obscured stalled game simulation. The change only observes existing EXI bookends; it does not change emulation timing or rollback. Twenty-two focused policy/timeline checks and the Simulator build passed. Runtime validation of these added fields is pending the next controlled high-delay/recovery run.


## Severe-latency reproduction and recovery on Simulators

After the user requested Simulator-only continuation, the same isolated pair was tested with 250 ms each-way UDP delay for 60 seconds after assignment, then 60 ms each way for the remainder of a bounded 180-second connection. The pair used Samus and Dr. Mario. The first attempted setup did not pair before a coordinated foreground handoff to KartPad; that attempt recorded no game and is excluded from gameplay evidence.

The completed recovery run reproduced the in-game poor-match-performance warning. In ten fixed interior high-latency intervals, mean ACK latency was 501.20/500.96 ms and actual new game-frame progress averaged 35.08/35.14 frames/sec. Displayed FPS remained 59.22/59.45. Send queue maxima observed in that phase were below 1 ms. After the programmed latency reduction, 23 fixed interior intervals averaged 59.95/59.94 new game frames/sec with 120.98/121.62 ms ACK latency, without reconnecting. Input-stall totals stayed constant through the recovered phase. This validates the new live counters against an actual visible slowdown, and shows recovery from latency-induced stalls in this local pair. It does not identify where the physical Internet path accumulated its delay.

The two finalized prefixes matched across all 9,163 frames and 27,489 complete emitted player/RNG packets. There were 8/10 rewinds and 14/49 changed-prediction frame events; maximum rewind was 2/7 frames. Both had the same seven unfinalized tail frames, excluded from acceptance. Runtime reports recorded zero boot, memory, graphics and matchmaking errors, and the observed audio windows recorded zero DMA underruns. The bounded relay expired before the later UI exits: 16 queued datagrams were intentionally discarded at that deadline, and subsequent missing-input stalls/disconnects are shutdown behavior, not a failed recovery. All pre-deadline forwarded traffic had zero invalid-source, queue-cap or send drops. Full phase, transition and shutdown CSV rows were retained.

Both test apps exited through Home and were then terminated; the relay finished. Simulator foreground ownership was returned to the concurrent KartPad task, without changing that task's clone or Galaxy's Simulator. No physical-device changes were made in this continuation.

## Real Internet Simulator reproduction

The regular Simulator build with live progress counters was installed with its existing private module preserved. Its executable SHA-256 is `0ee725eb1592418ab25854e6b1abe9774765b884d01e4fdf3d2f2f11d766b511`; module SHA-256 is `5023d315f6f97ae73cb05d1bbad49eead497df48069e5b1fb7c2617a786231e0`. The existing real account was imported privately into this Simulator, and remains available there for user testing. The temporary transfer file was removed. No physical account was changed.

A real Unranked search received a ticket and connected after approximately five minutes. One game started and ended. Across the observed 24.726-second game window, frame progress was 1,059 frames, or 42.83 new game frames/sec, with 313 rewind events and 14.874 seconds of CPU-thread time. The run recorded 469 missing-input stalls, 15 time-sync advances, 1,023 input acknowledgements averaging 269.88 ms, and one unspecified peer disconnect. There were no malformed packets, send failures, matchmaking errors, local seven-second forced disconnects, or boot/memory/graphics errors. Maximum local send-queue dwell was 1.517 ms. The final ENet RTT/variance was 386/441 ms. The reported raw loss value is fixed-point and must not be read as a percentage. The observed audio window recorded zero DMA underruns, with three preceding that window.

This reproduces poor Internet gameplay on the native Simulator. It does not identify the slow endpoint or route. The controlled pair's recovery to approximately 60 new game frames/sec at 120 ms round-trip delay remains separate evidence; it does not prove every Internet match or the physical device is healthy.

The Mac's VPN services were disconnected. Read-only controls found zero loss in the sampled router and public ICMP probes, with approximately 3.9 ms and 19.2 ms average RTT respectively. Six Cloudflare STUN UDP requests succeeded at 22.66–42.18 ms. Google STUN requests were much slower despite successful, consistent mappings; this endpoint-specific observation is insufficient to diagnose general Wi-Fi failure, symmetric NAT, or the actual opponent route. No router mappings or system network settings were changed.

An official desktop Slippi 3.6.4 comparison was attempted with separate game/controller settings and the already-present matching desktop account. Its game rendered at the Online menu, but automated keyboard presses did not advance it; its in-game menu actions also failed to expose a usable controller panel. A separate GUI file-open attempt exited the app. No official desktop match was obtained, so no desktop performance comparison is claimed. The reference process was stopped. The regular Simulator exited the tested game through Home, flushing its reports; no matchmaking session or capture was left active.

## ENet startup RTT regression and fix

The port uses ENet 1.3.18; official Slippi's pinned dependency is 1.3.13. Their startup RTT estimators differ. The newer implementation adopts the first acknowledgement's RTT directly, while the older version smooths from its existing 500 ms initial estimate. A fast handshake followed by repeated latency spikes can therefore trigger earlier unsequenced-packet throttling in the port. ENet can discard these packets internally despite a successful send call; the existing reliable-packet loss metric does not count these discards.

A bounded host test exercised both actual libraries through the same lossless UDP relay, with 27 ms initial RTT followed by 405 ms. The pinned version delivered and acknowledged all 496 gameplay packets. The current version delivered 420 of 496, with 368 acknowledged exchanges, zero send errors, and throttle falling to 18/32. Restoring startup smoothing in the current library delivered and acknowledged all 494 packets in its run. Stable 120 ms controls passed in all three variants. These are transport tests with controlled packet timing, not Internet gameplay acceptance.

Patch `0060-enet-startup-rtt-smoothing.patch` removes only the first-ACK direct-initialization branch. It retains current variance updates, throttle thresholds, packet-drop logic and established-connection congestion response. The reusable test invokes the actual ENet ACK handler: startup and stable cases remain at 32/32; a low-latency connection that has converged for 60 seconds still reduces throttle to 12/32 after a latency increase. The unpatched source fails the startup test at the second ACK. Run it with `python3 scripts/test_slippi_enet_startup.py` after dependency bootstrap. The patch is registered in `scripts/bootstrap-dependencies.sh`.

The network CSV now also records ENet throttle observation count and minimum, so zero send errors cannot be mistaken for proof that ENet did not throttle. The pre-fix instrumented Internet attempt obtained two assignments during a bounded approximately ten-minute search but no completed peer connection or game; it cannot establish whether the earlier real match throttled.

Both platform ENet archives were rebuilt with the patch. The Simulator app was rebuilt, signed and installed with executable SHA-256 `90c844722ba4c40d222a4a1e29531848b79184de4002683e40a864dc739fd99c`; its native module remains byte-identical at `5023d315f6f97ae73cb05d1bbad49eead497df48069e5b1fb7c2617a786231e0`. No physical app was installed in this Simulator-only continuation. The precise local rebuild sequence is `cmake --build ref/ModernGekko/build-ios-iphonesimulator-meleepad-static --target enet -j 2`, followed by the existing Release Simulator Xcode build. Re-sign and install the retained private app after copying only the rebuilt executable; do not substitute a module-free build product for the private bundle.

The fix addresses a reproduced startup regression. It does not eliminate genuine high latency after convergence, and the earlier Internet slowdown is not fully attributed until real-match throttle and progress measurements are available.

### Patched gameplay validation

The patched local Simulator pair sustained 59.94003/59.94009 new game frames/sec across the same 9,000-frame interior (150.15 seconds). ACK averages were 121.69/121.30 ms, with throttle remaining 32/32 and no interior missing-input stalls, malformed packets, send failures or runtime errors. Observed audio windows had zero DMA underruns. All 10,346 common finalized frames and 31,038 emitted player/RNG packets matched, including changed rollback predictions. Manual Exit to Home left two unfinalized frames per client and four additional finalized frames on one client; those tails are excluded, and complete-match acceptance correctly remains false. Both workers exited successfully and the relay dropped no packets, including at shutdown.

A subsequent real Internet match still slowed down after the fix, reaching 538 missing-input stalls while the observed ENet throttle stayed 32/32. Individual five-second intervals alternated between approximately 60 and 24–31 game frames/sec, then fell to 13.5 near the end. Local send-queue dwell remained below 1.5 ms; ACK latency reached more than 800 ms. Thus the reproduced ENet startup issue is fixed, but it does not explain this remaining Internet failure. Do not describe Internet gameplay as repaired.

A separate 60-second public STUN UDP test showed large latency spikes and timeouts with default socket settings, EF priority alone, and Slippi's EF plus responsive-video classification. A concurrent follow-up traffic sample found substantial upload traffic from other coding processes, but correlation was not robust when timeouts were included; it does not prove upload congestion. A 40-packet router ICMP sample had zero loss and 2.58/3.71/9.50 ms minimum/mean/maximum RTT. Endpoint processing, the external route and contention remain distinct hypotheses.

A temporary private receive diagnostic enables Apple monotonic receive timestamps and measures kernel enqueue-to-recvmsg delay without retaining packet contents or addresses. Only a copied ENet `unix.c.o` changes; the shipping source/archive is not instrumented. A local validation with five immediate and five intentionally held 120 ms datagrams correctly classified exactly five above 100 ms, with zero socket-option errors. The temporary app writes numeric aggregates on the existing five-second watchdog, not on the network thread. It must be replaced by the normal patched Simulator build before handback.

The bounded receive-diagnostic search did not reach a game. Its final sample covered 971 received datagrams, with 613 microseconds maximum kernel enqueue-to-read delay, no samples above 10 ms and zero option errors. This is matchmaking traffic, not peer gameplay evidence. An independent 40-second alternating Google/Cloudflare UDP test reproduced high delay on both services while concurrent ICMP pings stayed below 37 ms with zero loss. Monotonic receive timestamps were present on all 27 successful STUN replies: kernel enqueue-to-Python-read delay averaged 68.96 microseconds and peaked at 128.21 microseconds, despite request RTTs reaching approximately one second. This reproduces the delayed UDP response outside the MeleePad runtime and rules out long local socket-queue residence for those replies. It does not distinguish remote service processing, router/ISP handling, pre-IP host filtering or upload contention.

The temporary diagnostic was stopped through Home and replaced with the normal patched private Simulator app. Its installed executable hash was verified against `90c844722ba4c40d222a4a1e29531848b79184de4002683e40a864dc739fd99c`, and the temporary receive getter is absent from that binary. The real account and private native module remain available. No fixture relay, packet timing capture or matchmaking search was left active. An alternate-connection comparison was proposed at that point. The user subsequently directed continued investigation on the existing Mac connection; the additional same-network controls below narrow the failure without changing networks.


### Existing Mac connection: payload latency isolated outside Slippi

The follow-up retained the existing connection and left the normal patched Simulator app unchanged. Private probe sources, raw samples and summaries are in `/private/tmp/meleepad-native-audit-0912/same-network-latency/`. These are standalone network controls, not additional gameplay acceptance.

| Control | Result |
| --- | --- |
| Same Cloudflare endpoint/port, UDP STUN | 15/20 replies; mean 742 ms |
| Same Cloudflare endpoint/port, TCP STUN | 20/20 replies; mean 906 ms; TCP connect usually 21–39 ms |
| Independent public UDP DNS | 18/20 replies; mean 755 ms |
| Five socket service classes | All 100 replies; each class averaged 945–947 ms; no useful improvement |
| Local router cached DNS, concurrent with public DNS | 20/20 each; local mean 6.94 ms, public mean 884.13 ms |
| Local router HTTP in the same control | 20/20; mean 19.59 ms |
| Public HTTP / HTTPS empty response | All 12 each returned HTTP 200; mean total 1.02 / 1.94 seconds |
| Public DNS receive timestamp in HTTP/HTTPS control | 12 timestamps; kernel enqueue-to-read mean 61.75 microseconds, max 82.58 microseconds |
| TCP request acknowledgment timing | 12/12; SYN connect mean 26.60 ms, request acknowledgment mean 643.38 ms (482–1,101 ms) |
| Explicit foreground policy on probe child only | Policy removal succeeded; concurrent inherited/foreground DNS mean 514.18/513.35 ms; both had the same spikes and brief recovery |

The local DNS replies had successful response codes and decrementing cached TTLs. Public HTTP timing separated fast TCP connect from slow first byte; HTTPS added a similarly delayed TLS handshake. This supersedes any UDP-only inference: ordinary TCP application data also suffers. The TCP kernel probe observed the 20-byte request pending until acknowledgment, 40–60 retransmitted bytes on every trial, and current kernel RTT agreeing with the measured delay. It cannot distinguish delayed outbound payload from delayed returning ACK/data, but rules out a Python read-timing explanation. Sampled monotonic receive timestamps independently bound local receive-queue residence.

The router's public configuration declares `WEBUI_TITLE: "Speed Wi-Fi HOME 5G L13"` and ZTE branding. The generic JavaScript directory name is not used to identify the physical model. The Mac is associated on 5 GHz Wi-Fi. Actual WAN radio mode, signal and traffic readings remain unverified: the unauthenticated read-only status request returned empty fields. No credentials were read, no login bypass was attempted, and no router settings changed. The router login page was opened for the user; authenticated read-only diagnostics are the next discriminator.

Host checks found NordVPN services disconnected, no running NordVPN process, no enabled NordVPN filter in the inspected network-extension configuration, no configured HTTP proxy, and no visible Network Link Conditioner activity. Empty host queue snapshots and socket service-class controls do not prove the entire host path is faultless. Full packet-filter/dummynet rules required administrator access and were not inspected. No unrelated coding processes were interrupted. Earlier concurrent uploads remain a plausible source of queueing, without a quiet controlled baseline proving causation.

The current evidence localizes the reproducible delay to internet-bound payload traffic beyond the fast local-router controls. It does not yet prove a specific cellular radio, router queue, carrier policy or upload-contention cause. It also does not justify changing Slippi rollback limits, input delay or rendering settings to conceal missing packets. The earlier fixed ENet startup estimator remains a separate, tested implementation fix.

Research references: [Cloudflare STUN/TURN transports](https://developers.cloudflare.com/realtime/turn/), [Cloudflare latency measurement and cellular example](https://blog.cloudflare.com/how-does-cloudflares-speed-test-really-work/), [Apple XNU packet service-class handling](https://raw.githubusercontent.com/apple-oss-distributions/xnu/main/bsd/netinet/in_tclass.c), [official L13 manual](https://www.au.com/content/dam/au-com/support/service/mobile/guide/manual/ztr02/pdf/l13_torisetsu_shousai.pdf), and [official Slippi delay-frame guidance](https://github.com/project-slippi/slippi-launcher/blob/main/FAQ.md). Slippi's recommended two-frame delay covers up to approximately 130 ms ping; it is not a remedy for the measured half-second-to-second stalls.
