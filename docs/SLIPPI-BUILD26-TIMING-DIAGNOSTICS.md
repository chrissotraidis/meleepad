# Build 26: isolate repeated online stalls

Repeated poor connections across opponents leave MeleePad's implementation and device path as the primary investigation target. A peer quitting after lag is not evidence that MeleePad is healthy. Build 25 successfully captured the symptom, but could not locate the delay.

## Changes

The candidate adds numeric-only fields to the one-second network CSV:

- Input-packet submission count, maximum interval gap, and current age.
- Incoming PAD and ACK handling counts, maximum interval gaps, and current ages.
- Input-ACK latency peak, outgoing queue residence peak and ENet service duration peak for each sampling interval, rather than only session maxima.
- Unsequenced input/ACK packets freed with ENet's SENT flag versus freed without it. The latter includes throttle drops, rejected sends and cleanup; use active-game state and existing failure counters before attributing it to throttling. SENT indicates the local outgoing path, not successful remote delivery.
- Numeric local player port, to resolve quit initiator without exporting player names/account credentials.

The packet-free callback uses ENet's existing API; no ENet source or protocol changes were needed. The send-failure path now destroys caller-owned rejected packets, avoiding a leak; the earlier match recorded zero send failures, so this is not presented as its cause. No new patch files or source-patch replay steps were introduced. Hooks are direct edits to the existing private Slippi source input; that input's before/after copies are retained with this candidate. The project's broader existing overlay/source-maintenance debt is not solved by this change.

The native game module, game/code resources, socket priority, timeout values and rollback behavior remain identical to build 25. The new counters do not log payloads, network addresses, credentials or names. At most a few atomic operations are added per input/ACK; CSV writing remains on the existing watchdog.

## Interpretation

Compare active-game intervals only, excluding matchmaking, startup, menus and cleanup. Counters are cumulative, while interval maxima drain at each CSV sample. Ages reveal an unfinished gap even before the next packet arrives. First observations have no prior gap; rematch/idle boundaries can create large gaps and must be excluded. Incoming PAD observations are handler-entry timestamps, not kernel arrival times; malformed inputs must be checked using the existing invalid-packet counter. Multiplayer traffic is aggregated, so initial interpretation should use 1v1.

- Large input-submission gaps localize a pause before or at our input production. They can also be a consequence of rollback waiting on incoming data; compare receive timing and stall counters rather than assigning causality from a single field.
- Regular submissions with small queue residence but missing incoming PAD/ACK handling narrow the fault toward receive scheduling, the local radio/network path or remote behavior.
- Rising unsent packet destruction during active play, without send errors or cleanup, tests whether local ENet throttling is worsening the bursts.
- Service-duration peaks separate time inside `enet_host_service` from the existing post-service work measurement. Its 250 ms idle timeout is intentional, not automatically a bug.

The [official Slippi peer implementation](https://github.com/project-slippi/Ishiiruka/blob/slippi/Source/Core/Core/Slippi/SlippiNetplay.cpp) uses input redundancy, frame ACK timers and asynchronous sends. Our source audit confirms a wakeup after queueing and an outgoing flush after receive dispatch; build-25 queue residence stayed below 0.537 ms. That does not measure earlier simulation stalls, OS transmission or packet discard, which these additions address.

## Verification

- Actual vendored ENet, connected over loopback: 32/32 unsequenced packets take the sent path at throttle 32; at throttle 0, 31/32 take the discarded path; queued-packet cleanup also registers discarded. The test deliberately distinguishes that ambiguity. This verifies instrumentation, not internet gameplay.
- Diagnostic regression checks verify transient peaks, window drain, cumulative count retention, unfinished-gap age, reset and CSV alignment.
- Incident persistence/privacy/concurrency checks and existing ENet disconnect tests pass.
- Release iOS build passes. Signed candidate passes strict deep signature and credential-metadata audit; the game module and Slippi resource hashes match build 25.

No root-cause fix or successful real-opponent match is claimed. Hardware deployment/readback is recorded below after completion.

## Physical deployment

Build 26 was installed in place on the paired iPad. Installed-app metadata confirms 26; runtime records native Slippi ready, revision 2. A readback of the live network CSV contains 29 rows with all 56 columns, including the new fields; the checkpoint is running without a recorded runtime error. The ten configuration files are byte-identical before/after, the GC directory remains empty, and preference changes only relocate the two bundle-relative game paths. No QuickTime capture was opened. No online match was automated or claimed during validation.

Candidate, source hashes, private source snapshots, backup/readback and runtime evidence are in ignored `ref/slippi-compatibility/build26-diagnostics/`. The full repository suite was not rerun; its previously documented sampler symbol-resolution failure remains unresolved. Focused instrumentation/ENet/input tests, device build, signature and on-device logging checks passed. The next owner Unranked match is the intended real-network test.

## Owner acceptance follow-up: completed production games

A subsequent live readback shows two Unranked game reports with end method 2 (normal GAME), winner 0 and LRAS initiator -1, with report frame counts 6,765 and 6,433. The owner independently reports completing a match without disconnection. Later peer teardown occurs after each normal game report; it does not invalidate these completions. This establishes completed Unranked play on the owner's hardware, not general reliability or a causal fix from instrumentation. Logging remains active; no app restart or QuickTime capture was performed for collection.

The same checkpoint records five Unranked searches, zero Ranked/Direct/Teams/Party searches and zero host-denied searches. This session cannot explain a Ranked menu or service failure because no Ranked request reached the host. The host AllowsSearch policy accepts Ranked/Unranked/Party and accepts valid-code Direct/Teams. Obtain the exact menu state or error before changing the gate or attributing rejection to account eligibility.

Private evidence is in `ref/slippi-compatibility/build26-completed-match/`.
