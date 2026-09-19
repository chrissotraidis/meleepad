# Build 26 third Unranked match: local stalls and discards

Read back the live iPad session and latest replay without restart or QuickTime. This is the third game in the same session as the two completed games. Evidence is private under `ref/slippi-compatibility/build26-latest-round/`, with hashes.

## End and timing

The local player port is 0 throughout this game. Both replay and game report identify No Contest (7), LRAS initiator 1. Thus the recorded quit was on the other player's slot; this does not establish why they quit or assign fault for the preceding lag. The report occurs around incident second 2373.87; cleanup follows at 2377.17 and remote-disconnect observation at 2377.49. The game lasts approximately 60 wall-clock seconds. No local timeout, forced-stall disconnect or desync report is observed.

## What changed during play

Exclude the first active cadence sample: its gap spans about 960 seconds between games and is not an in-game stall. During the following active samples (network seconds 2290–2349.75):

- Input submission gaps initially stay near 17.3 ms, later reaching 73.479 ms.
- Outgoing queue residence peaks at 1.312 ms; ENet service duration peaks at 39.154 ms.
- PAD handler gap peaks at 83.943 ms; ACK handler gap at 243.446 ms.
- Input-ACK round-trip latency peaks at 836.608 ms. After the first active sample, 782 observations exceed 250 ms and 469 exceed 500 ms.
- 82 unsequenced packets are destroyed without ENet's SENT flag, versus 3,565 with it. They are outgoing input/ACK packets, not 82 measured losses on the internet. No send/service errors are recorded. The discard increase precedes end-of-game cleanup and coincides with throttle minimum decreasing to 20/32, strongly supporting local throttling as a contributor. The callback also counts rejected/cleanup packets in general, so do not use its lifetime total without these boundaries.
- The discard counter stops growing around network second 2330.47, but severe stalls continue until game end. Local packet discards alone therefore do not fully explain persistence.
- Rollback-limit halt count rises by 811 after the first active sample. These are halted-frame events, not individual connection outages.
- From network second 2323.69 to 2348.92, latest simulated frame advances from 1919 to 2724: about 31.9 unique frames per second. Earlier five-second windows advance near 60. Presentation FPS near 58–60 concealed this loss of game progress. Later presentation p95 intervals reach 50–64 ms, maximum 125.851 ms.

These measurements establish local packet discard and input/presentation stalls during the bad interval. They do not prove those input gaps preceded the network problem: rollback waits can slow production after incoming inputs are delayed. PAD traffic continues with much smaller gaps than the full input-ACK latency, narrowing attention to outgoing input/ACK delivery, retransmission/redundancy behavior and local/remote frame acknowledgement progress.

## Consequence

Do not treat the opponent's quit as evidence that MeleePad is working correctly. The late loss of simulation progress and local discards are actionable evidence against that conclusion. The two earlier completed games remain valid acceptance evidence, but sustained reliability is not established.

The next implementation investigation should compare outgoing frame/ACK progress and ENet throttling across the onset and persistent-stall intervals. A controlled throttle comparison can test amplification, but bypassing it is not yet a demonstrated cure: the first latency rise and the continued stall after discards stop must both be explained. Keep this as an experimental candidate rather than a stable Slippi release. No code, installed build, network settings or game data were changed during this log review.
