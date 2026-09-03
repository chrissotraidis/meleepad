# G5 reference, shader-worker, and streaming rejection

Date: 2026-08-29

Status: **NO NEW PRODUCT-LOCAL HOST-EXECUTION MECHANISM FOUND; G5 OPEN**

## Question

After PERF-176 tied every current pre-results render stall to the combined
CPU-GPU/vblank path, do SunPad, current Slippi/Dolphin, asynchronous shader
workers, or extracted-disc streaming expose a distinct supported mechanism
that has not already been tested?

## Reference and Slippi audit

SunPad's Apple performance research explicitly identifies shader-worker
competition as a possible cold-scene cause, but its scheduling remedies are
the same QoS and CPU/video split already rejected in MeleePad. Its retained
dual-core route produced FIFO desynchronization and is not transferable as a
safe default.

Current Project Slippi Dolphin source was inspected read-only on 2026-08-29:

- Apple `SetThreadAffinity` still calls `THREAD_AFFINITY_POLICY`; it adds no
  QoS, P-core pinning, Game Mode API, or separate scheduling class;
- `AsyncShaderCompiler` still creates ordinary `std::thread` workers and
  blocks them on the same condition-variable queue when idle; and
- its graphics configuration exposes the same shader-worker controls rather
  than a distinct macOS execution mechanism.

Primary source:

- <https://raw.githubusercontent.com/project-slippi/dolphin/master/Source/Core/Common/Thread.cpp>
- <https://raw.githubusercontent.com/project-slippi/dolphin/master/Source/Core/VideoCommon/AsyncShaderCompiler.cpp>
- <https://raw.githubusercontent.com/project-slippi/dolphin/master/Source/Core/VideoCommon/VideoConfig.cpp>

## Current shader screen

The private Fountain configuration uses `ShaderCompilationMode=2`, Dolphin's
`AsynchronousUberShaders`, plus `WaitForShadersBeforeStarting=True`. Known
pipeline UIDs are therefore compiled before gameplay and one runtime worker is
available only for a newly discovered specialized pipeline.

Dolphin appends a new pipeline UID immediately in
`ShaderCache::GetPipelineForUidAsync`. The current private `GALE01.uidcache`
has mtime `2026-08-29 11:03:16`; the clean PERF-174 run began at
`2026-08-29 11:09:42`, and the later rate-alignment run began at 11:18:47.
Neither run changed the file. Their repeated stalls therefore occurred after
all encountered UIDs were already known, with no new runtime pipeline queued.

A retained 12,067-sample Fountain process profile independently shows three
shader workers asleep for every sample. A fourth shader worker slept for
12,052/12,067 samples and compiled for only 15 samples total: ten pixel-shader,
four vertex-shader, and one pipeline sample, about 0.1243% of the interval.
Other asset/resource workers were asleep for all 12,067 samples. This older
profile is supporting evidence only; the current cache mtime is the decisive
screen for PERF-174.

Changing to exclusive ubershaders or reducing the compiler thread count would
therefore alter rendering policy without removing work present in the clean
stall window. No A/B was launched.

## Extracted-disc streaming screen

MeleePad boots `sys/main.dol` through Dolphin's `DirectoryBlobReader` over the
already extracted private game tree. `MAIN_LOAD_GAME_INTO_MEMORY` only wraps a
file-backed disc `BlobReader` in `CreateDiscForCore`; it is not applied to this
directory-blob boot path. A retained 12,067-sample profile gives the DVD worker
only two file-open samples. The separate FastDisc experiment already left
Fountain combat p95 essentially unchanged and was removed.

Do not add an inert load-whole-disc setting or relabel intentional results
XFB droughts as file stalls.

## Decision

**Reject shader-policy, DVD, affinity, and Slippi-transfer guesses from the
current evidence.** The remaining current pre-results class is runnable
combined-thread host descheduling. QoS, priority, time constraint, Game Mode,
dual-core, timers, workgroups, presentation queues, and process activity hints
already have causal tests. No product source/configuration changed, no game or
Simulator ran, and no unrelated host process was altered.

A next causal test requires a genuinely new supported macOS execution
mechanism or explicit reversible authorization to isolate external host load.
G5 remains open; Final Destination and G6 remain blocked.
