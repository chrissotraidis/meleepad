# G8 iOS persisted shader-cache prewarm rejection

Date: 2026-08-30

Status: **PERF-233 REJECTED; G8 row 7 remains open**

## Question

Does relaunching the combined host+module PGO candidate with its persisted
Metal/Dolphin shader cache remove the cold resource-transition collapse?

## Result

The persisted `GFX.ini` already enabled the shader cache, asynchronous uber
shaders, and wait-before-start behavior. `GALE01.uidcache` was present. A fresh
process using that state reduced runtime creation from about 43 seconds to
about 23 seconds, so the cache was active and useful.

It did not close the performance deficit. The first stage transition measured
42.1 and 54.6 FPS while shader counts were initially flat. A later heavy
sequence measured 49.5, 60.4, 59.9, 47.0, 51.1, and 51.8 FPS while vertex and
pixel shader totals continued growing to 106 and 170. DMA underruns rose from
5 to 128.

## Decision

**Reject existing cache persistence as a sufficient row-7 solution.** It
improves startup and remains enabled, but it does not prevent the live cold
resource/shader collapse. Do not repeat a cache-only relaunch and call it a
performance fix. Continue with the independently measured generated-dispatch
mechanism.

The private runtime log has SHA-256
`af6354d780e5c5a5abc0fa354db2c74e54b34b79338ed9174c2c6e9b00dbe07e`.
No cache, module, profile, game data, or log is committed.
