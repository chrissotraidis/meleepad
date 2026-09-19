# Slippi disconnect and visibility audit — September 19, 2026

## Conclusion

The owner's physical iPad match proves real Unranked matchmaking and approximately 140 seconds of gameplay. The capture proves an incoming disconnect command but cannot explain why the remote endpoint sent it. Source comparison found concrete gaps in our diagnostics, not a proven transport cure. Desync recovery, ordinary cleanup, and duplicate-connection cleanup were inadequately represented. A zero forced-removal counter was previously described too broadly as no local disconnect request.

## Sources and comparison scope

Downloaded selected source files by immutable commit into ignored `ref/slippi-compatibility/research-20260919/`, without another checkout. Saved upstream trees and local unified diffs.

| Implementation | Inspected revision | Role |
| --- | --- | --- |
| Official Ishiiruka | `e7711b104b339a99385f2bb12b472d46140a7bc7`, v3.6.4 | Stable reference |
| Official modern Dolphin | `41a7a3a110ed52999486ae1901c8fbb9a63d4f13` | MeleePad's Slippi donor; current slippi branch resolved to this commit |
| MeleePad | Existing private `ios-direct-005/overlay` and host scripts | Current integration; installed build 24 identified in captured runtime log |
| melee-unlocked | `424e59413a3b34963e45d855c7839116447b3cfc` | Independent native runtime code comparison |
| Dashdance | `3e5b3548f32f83153887907530fd275cfc931840` | Apple/native integration comparison |

This is a targeted comparison of matchmaking, peer transport, game-interface disconnect paths and logging. It is not whole-runtime equivalence or a new official-client interoperability test.

## What upstream establishes

The [official FAQ](https://github.com/project-slippi/slippi-launcher/blob/main/FAQ.md) requires NTSC 1.02 and recommends two input-delay frames for connections up to 130 ms. It also describes modern Dolphin as compatible with stable Slippi. Our incident's 789 ms peak is far beyond that ordinary latency range; changing the delay setting is not evidence of a cure.

The [official game interface](https://github.com/project-slippi/dolphin/blob/41a7a3a110ed52999486ae1901c8fbb9a63d4f13/Source/Core/Core/HW/EXI/EXI_DeviceSlippi.cpp) contains several distinct failure paths:

- Per-player consecutive input stalls exceeding 420 checks force removal. Our incident records no such forced stall.
- Poor-performance debt can terminate Ranked; the function returns immediately in Unranked. Do not attribute this match to that Ranked policy.
- Failed desync recovery invokes ordinary connection cleanup. Current logs do not establish whether either endpoint entered recovery.

The [official peer implementation](https://github.com/project-slippi/dolphin/blob/41a7a3a110ed52999486ae1901c8fbb9a63d4f13/Source/Core/Core/Slippi/SlippiNetplay.cpp) separately handles duplicate connections, normal teardown and incoming disconnects. Ordinary cleanup defaults to reason zero; that value does not distinguish manual departure from automatic cleanup. Desync recovery reports timer, stock and health disagreements that our existing callback discarded.

Version 3.6.1's [connection-related changes](https://github.com/project-slippi/Ishiiruka/pull/459) count live connections, check the active peer/global player port, and mark redundant peers disconnected immediately. These guards are already present in our overlay. Reapplying that upstream fix is not a new solution.

## Comparison with our integration

The modern-donor matchmaking diff is only three replaced lines: include adaptation and version-provider calls. Ticket construction, server selection and peer assignment remain donor behavior. The peer diff mainly adapts includes/message-ID names, ownership and diagnostics, adds the stable client's Apple socket classification, and explicitly flushes outgoing packets. The inspected input packet fields, unsequenced pad/ACK channel, rollback-stall threshold and recovery decisions were not replaced with a separate protocol.

The iPad capture confirms Apple's socket classification succeeded, maximum observed asynchronous queue dwell was 1.342 ms, and send/service error counters stayed zero. Those observations do not identify the network as healthy: ACK latency includes both endpoints' scheduling and network delay, and current cumulative maxima do not align every scheduling event with a spike.

A key limitation is `connected_peer`: the ENet observer stores only the initial first peer. Upstream can replace a peer when resolving duplicate connections. Negative observer counters therefore have limited coverage, particularly with multiple opponents or replaced peers. The positive incoming-disconnect observation remains useful.

`local_disconnect_requests` increments only in `ForceDisconnectPlayer`. `Disconnect()` and redundant-peer cleanup do not increment it. The incident report now explicitly corrects that interpretation.

## Other implementations

[melee-unlocked's peer source](https://github.com/Hero88go/melee-unlocked/blob/424e59413a3b34963e45d855c7839116447b3cfc/port/runtime/hle/slippi_net.cpp) likewise uses ENet, frame/checksum-bearing input packets, separate input acknowledgements, peer liveness and recovery state. Its synthetic receive-delay facility is a test hook, not evidence that a user's production disconnect is solved. It supplies no established drop-in fix for this incident.

[Dashdance's Apple transport](https://github.com/TheAndersMadsen/dashdance/blob/3e5b3548f32f83153887907530fd275cfc931840/port/runtime/hle/slippi_net.cpp) uses voice socket classification rather than our reference-matched responsive-video classification. That difference requires a measured hardware comparison; its existence does not prove better performance. Its [service checkpoint](https://github.com/TheAndersMadsen/dashdance/blob/3e5b3548f32f83153887907530fd275cfc931840/docs/SLIPPI_SERVICES.md) explicitly limits its described headless target to offline diagnostics and distinguishes loopback proof from production service acceptance. Neither README claims nor local test results establish sustained iPad interoperability for us.

## Physical evidence revisited

Seven separate groups of ACK samples above 250 ms occur around watchdog seconds 210, 225, 228, 239, 257, 272 and 324. Several last about two seconds at the available sampling resolution. They are not strictly periodic. The final burst recovers before the disconnect at 335.940 seconds. Possible network jitter, endpoint scheduling and game-state divergence remain distinguishable hypotheses, not findings.

Substantial native-to-interpreter fallback was recorded. Near-60 presentation FPS does not prove identical state versus official Slippi, nor continuous simulation progress during stalls. Same-build self-play cannot rule out a shared deterministic error.

## Changes made in this audit

- Added a bounded `incidents.csv` writer with monotonic and wall-clock timestamps, fixed event names and numeric values. It persists recognized desync-recovery failures, performance termination, forced stalls, matchmaking ticket rejection, connection failures, duplicate cleanup and teardown sends without storing arbitrary upstream messages.
- Records matchmaking/game-start and disconnect-counter changes approximately once per second; callback events flush immediately. A telemetry-start marker connects the event clock to existing CSV clocks.
- Refreshes the checkpoint every five seconds; the old startup-only checkpoint misleadingly retained zero search counts throughout an active session.
- Added checks for privacy, persistence before destruction, concurrent writes and the 4,096-event bound with an explicit overflow marker. Wired the test into repository checks.

These changes are source-only. No new patch file or dependency source-replay step was added. The pre-existing private overlay build remains a separate release-source maintenance issue.

## Validation and remaining work

Focused incident logging and network CSV checks passed. iOS input-contract tests passed. The iOS compile reached linking, where the current Xcode 27 headers and retained core archive disagree on the libc++ ABI-tagged `State::LoadFileStateData` signature. The new app did not link; no new build was installed or real match run. Fix archive/toolchain consistency before deploying the diagnostic candidate.

Next acceptance must be a real Slippi match. Use a known official-client opponent so both endpoint logs can identify a manual exit, automatic recovery failure or stall; public queue observation alone cannot recover the opponent's internal decision. Keep the same game/module identity, record the candidate build, and compare a wired iPad connection against Wi-Fi if both are available. Add direct recovery-start/checksum and per-window scheduler measurements if the event log still cannot separate the hypotheses. Do not increase timeouts, change socket priority or disable correctness guards based on this evidence alone.

## Deeper follow-up: game-side termination and reported incidents

The next pass traced callers rather than treating every disconnect-capable function as equally applicable. `handleReportGame` only starts the synchronized-state recovery exchange for Ranked and end method 7. Failed recovery is therefore not a leading explanation for this Unranked incident. The earlier discussion of recovery errors was too general for this specific mode.

The [game-side engine loop](https://github.com/project-slippi/slippi-ssbm-asm/blob/fcf47f10dc244152c2ebaa3a9dec142ea42243b7/Online/Core/StartEngineLoop.asm) checks matching finalized-frame checksums. Its hard check uses a signed low-16-bit value representing summed positions/damage, with tolerance of one; the high half supplies a softer mismatch warning. Consequently, arbitrary full-checksum inequality is not equivalent to Slippi's hard-desync decision. The hard path displays its warning and calls the game-ending helper. This code exists below the host's network logger.

More usefully, [InitOnlinePlay's report construction](https://github.com/project-slippi/slippi-ssbm-asm/blob/fcf47f10dc244152c2ebaa3a9dec142ea42243b7/Online/Core/InitOnlinePlay.asm) encodes the displayed failure state in the report's winner field: -3 for disconnect and -2 for desync. Disconnect takes precedence when both flags are set. Our actual EXI implementation logs this numeric report, but our old callback threw it away. The new logger now retains only validated numeric mode, frame count, winner classification, end method and LRAS initiator, plus cleanup-start/completion events. This is an additional local evidence source; an opponent log remains helpful but is not the only route forward. These report markers describe the local detector's result, not ultimate fault attribution, and may be absent if the app stops before reporting.

The assembly reference is pinned at `fcf47f10dc244152c2ebaa3a9dec142ea42243b7`. This pass did not independently prove byte-for-byte identity between every deployed native module instruction and that source. The existing host report layout was checked directly in the active overlay.

### What people report, and what it does not establish

- A [one-minute Unranked freeze report](https://www.reddit.com/r/Slippi/comments/1t1xph1/slippi_freezes_and_disconnects_about_a_minute/) remained unresolved after reinstalling, network resets and trying a vanilla ISO. It does not support prescribing those steps as a fix here.
- An [older two-to-three-minute disconnect report](https://www.reddit.com/r/smashbros/comments/i26xn1/eventual_disconnect_with_mate_on_slippi/) describes a ping spike and freeze. Similar duration alone does not establish the same defect or network cause.
- [Official issue 156](https://github.com/project-slippi/Ishiiruka/issues/156) concerns disconnect before Ready/game start. Our successful multi-minute match is a different failure milestone.
- [AWDLControl](https://github.com/james-howard/AWDLControl) targets macOS wireless latency associated with Apple peer-to-peer radio activity. It is a mechanism worth distinguishing from endpoint stalls, not evidence that AWDL caused this iPad capture. Do not apply macOS interface-disabling commands to the iPad or change the user's networking without a controlled comparison.

These are first-person reports or project documentation, not controlled acceptance results. No inspected report supplied a verified MeleePad-specific cure.

### Narrowed next decision

1. If the new report records desync (-2), compare the native simulation against official Slippi at matching finalized frames. Investigate deterministic arithmetic, exact game/code resources and rollback restore/invalidation; another native-vs-native test cannot clear those differences.
2. If it records disconnect (-3), use cleanup ordering, pre-reset remote-command/timeout events and per-window timing to distinguish initiated teardown from loss of communication. A remote reason-zero message still cannot reveal an unreported remote internal cause.
3. If neither report appears, retain the last checkpoint and incident events and investigate incomplete game reporting/runtime lifecycle. The periodic checkpoint now avoids the earlier all-zero startup snapshot.

The new report parser's test verifies that a desync-classified numeric report is retained while unknown/malformed messages and arbitrary appended text are excluded. Logging remains bounded. These checks exercise diagnostic behavior, not online compatibility or a fixed disconnect.

### Confirmed evidence-loss bug and build repair

A fresh recursive `.slp` listing of the physical app container returned zero files. The host explicitly set `SLIPPI_SAVE_REPLAYS` to false. This explains why a normal replay could not be recovered for the owner's match; it is an evidence-loss setting, not a demonstrated cause of disconnection. The candidate enables upstream asynchronous replay saving with an explicit path inside the private run directory. Replay metadata remains private. Replay creation/finalization must still be verified on the iPad; successful compilation does not prove it.

The build blocker above is now resolved. Xcode builds `StateFile.cpp` alongside the already compiled `State.cpp`, using the same current headers/toolchain, rather than importing the companion's ABI-sensitive `UniqueBuffer` signature from the retained archive. Added its existing LZO/lz4 include directories; no vendored file was edited and no archive was overwritten. The unsigned Release iOS build completed successfully. This is build validation, not a signed, resource-audited install or an online acceptance result. Build 24 remains installed.

The follow-up ENet tests also passed: the actual vendored handlers distinguish incoming reason-zero disconnect from reliable timeout before peer reset, and the separately linked observer classifies a real loopback UDP disconnect. This validates the classifier only; it does not reproduce the user's production failure. The new event/report logger passes its privacy, live-write, concurrency and bound checks.

Full repository checks were attempted. They stopped in `test_triggered_thread_sampler.py` at `cpu-thread-metric-trigger: native PCs did not resolve to a Mach-O image`. That sampler test is outside the files changed in this audit; its failure was not diagnosed here. Do not describe the complete suite as passing. Focused incident/ENet tests, the nine iOS input contracts, diff checks and the unsigned iOS build passed.

### Build 25 final review

The incident writer now creates its parent session directory before opening the file. The regression test starts with a nonexistent session directory and verifies live persistence, preventing a silent first-session logging failure.

The embedder forwards warning/error logs only. Numeric game reports, cleanup start/completion, matchmaking failures and performance/recovery errors use those levels and are observable. Upstream INFO messages for duplicate connections, teardown sends, final disconnect and peer connection failure do **not** currently reach this callback; their parser branches must not be interpreted as complete coverage. The independently instrumented remote-disconnect/timeout counters and periodic state transitions remain the transport evidence. This candidate does not broaden raw log collection.

Replay recording is enabled, but the [official replay specification](https://github.com/project-slippi/slippi-wiki/blob/master/SPEC.md) permits incomplete files and an absent Game End event. An interrupted recording cannot on its own establish why a match ended.

### Physical build 25 deployment

Private build 25 was signed with the installed app's development identity and installed in place on September 19. Profile/device authorization, all three device-module platforms/identities, retail v1.02 data, staged Slippi resources, bundle credential audit and strict deep signature verification passed. The native Slippi module was staged from the retained accepted native-GCT device source; signing changes its file hash. The installed runtime-reported signed hash matches the candidate manifest. No public artifact was published.

The iPad reports build 25 and `native Slippi runtime ready revision=2`. A new session's incident file contains timestamped startup, telemetry and connection-cleanup events, confirming end-to-end live persistence rather than only a unit test. Its running checkpoint reports no runtime error. Startup presentation samples are about 59.94 FPS; this is menu/startup evidence, not online performance acceptance.

Readback confirms all ten existing configuration files are byte-identical. The saved GC directory was empty. Preference differences are limited to relocation of the two bundled game-data paths, whose relative paths were checked. The account was accepted by the existing startup path; credentials were not exported into the candidate.

The private signed app, backup/readback, module/resource hashes and acceptance manifest are retained in ignored `ref/slippi-compatibility/ipad-build25-20260919/`. Focused incident, network CSV, actual ENet classification and nine input-contract tests passed, as did the final iOS build and diff whitespace check. The full-suite sampler failure described above remains unresolved.

No real opponent match was played by the agent during deployment. Replay creation/finalization, sustained production play and resolution of the disconnect remain unverified. The next owner match can now provide the missing game-report classification and local replay evidence if those paths complete. This is a diagnostic test build, not a claimed disconnect cure.
