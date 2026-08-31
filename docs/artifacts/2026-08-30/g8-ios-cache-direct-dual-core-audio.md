# G8 iOS cache-direct, dual-core, and audio-continuity result

Date: 2026-08-30

Status: **row 7 passes its no-sustained-underrun criterion; Simulator presentation hitches remain open**

## Question

After the fallback audit identified cache operations as the dominant legacy
hook family, can an exact-profile cache-direct module plus the retained host
PGO sustain the iPad Simulator's full audio path? If not on Dolphin's
single-threaded default, do measured CPU/video separation and bounded shader
workers remove the sustained producer deficit without changing guest timing?

## Exact cache-direct profile and module

The source-corrected training run completed its exported profile dump. The raw
profile is 44,646,960 bytes with SHA-256
`cfbf462585f68cc0bb812acbddd5903f50a32456a7f9d80341af910d79a0684a`.
The merged profile has SHA-256
`0cf65444174077a5b69260feb61626e6055df88166bce278087b3ca7e0e65436`
and contains 6,556 functions, 2,727,666 blocks, 12,058,980,386 total block
counts, and 239,673,165 `chassis_dispatch` calls.

A strict-use arm64 iOS Simulator build compiled all 237 generated chunks with
stale and unprofiled records promoted to errors. Only the three genuinely
unobserved interpreter fallback units stayed profile-free. The signed
81,006,192-byte module has SHA-256
`af1364e6fabe9ee29d2a64ee6268bd80ba3ef2aaa47de9c7741655fae9f3211b`.
It exports only `_staticrecomp_get_module`; profiles, binaries, and private
game data remain outside Git.

## Single-threaded reversal

The module was first paired with the retained host-runtime PGO app without a
scheduler change. Light intervals held 59.9-60.0 FPS, but cold heavy windows
fell to 49.4, 54.6, 37.2, 48.9, and 56.9 FPS while DMA underruns rose from 3
to 117. A warm repeat still fell to 51.3, 45.3, 45.9, and 50.2 FPS and ended
at 241 underruns. Cache-direct exact PGO alone is therefore rejected as the
row-7 fix.

## Dual-core and shader-worker reversals

Setting Dolphin's CPU-thread mode split guest execution from video submission.
A live process sample showed distinct `CPU thread` and `Video thread` workers.
The first demanding cycle, including a 913-draw interval, held 59.9-60.0 FPS
and almost flat underruns. A later cycle retained presentation dips, but
emulated VPS often stayed at approximately 60 and the audio queue recovered.
This materially changed the mechanism from sustained emulation starvation to
occasional presentation and transition stalls.

Adding three shader compiler workers per active shader-cache instance retained
60 VPS through the demanding path. The first heavy cycle held 59.9-60.1 FPS
except for transition recovery; the underrun counter then remained flat for
more than 80 seconds with continuing CoreAudio callbacks and a full DMA queue.
The live sample showed the separate CPU/video workers and the expected async
compiler workers. Presentation-only dips of 39.9 and 47.8 FPS still occurred
while emulation remained approximately 60 VPS, so they are not hidden or
reclassified as a 60 FPS pass.

## Source-integrated proof

The accepted settings are now canonical iOS runtime defaults rather than
private INI state:

- `MAIN_CPU_THREAD = true` on iOS;
- `GFX_SHADER_COMPILER_THREADS = 3` on iOS;
- host diagnostics identify `cpuVideoSplit=1 shaderCompilerThreads=3`.

Before the product rebuild was launched, the two prior private INI overrides
were removed. The source-integrated app then logged the new defaults, created
separate CPU/video workers plus async compiler workers, and reached live
four-character combat. The exact 15,082,096-byte signed runner has SHA-256
`84e80ecb48f9ed8ccc2a8cb5ce8556ff4bfb2ea2ed22ac66b4849219a313d533`.

The cold cycle accumulated transition underruns from 2 to 68 while resources
were created, then remained flat through sustained heavy work and recovery.
The warm combat cycle held 59.9 FPS / 59.9 VPS at 686-705 draws with the DMA
queue at its 15-granule target; only three isolated transition underruns were
added. This is qualitatively different from the prior sustained growth of
hundreds of underruns during every combat interval. Music/output callbacks
continued throughout, and the user independently heard the Simulator audio.

The retained screenshot
`docs/evidence/g8/ipad-cache-direct-dual-core-combat.png` shows coherent warm
four-character combat. It does not resolve the separately tracked historical
camera/mesh-warp defect.

## Decision

PRD row 7 requires music and SFX through the full macOS and Simulator audio
stacks with **no sustained underrun**; it does not require a zero lifetime
counter. Existing macOS evidence plus this source-integrated iPad Simulator
run satisfy that boundary. Mark row 7 pass.

Do not call the iPad presentation path locked 60 FPS. The next performance
work is the remaining presentation hitch: investigate a bounded Metal binary
archive/pipeline persistence experiment against cold creation and warm
presentation dips, with automatic fallback on archive miss. Do not reopen
audio-buffer sizing, stale legacy PGO, the narrow `mtspr` audit theory, or the
single-threaded cache-direct candidate.

