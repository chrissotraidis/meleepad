# G5 inline-validity preflight

Date: 2026-08-28

Status: **BROAD INLINE TABLE REJECTED BEFORE GAME BUILD; SUPERBLOCK PREFLIGHT NEXT; G5 OPEN**

## Question

Can a generator-known chunk index plus a runtime-owned eligibility byte remove
enough of PERF-076's callback cost to project more than a 5% CPU-thread gain,
without spending another full build on a 90+ MB candidate module?

## Exact old path and bounded model

The preserved PERF-076 no-profile app remains outside the repository. Its
arm64 disassembly shows every guarded direct edge loading a callback from
`CPUState`, issuing an indirect `blr`, and entering
`StaticRecompCore::HookDirectCallGuard`. The accepted DOL path checks module,
CPU-running, lockstep, and host-call state, then calls
`FastDispatchableAt`. That helper retains forced-range scanning, the cold REL
resolver branch and stack frame, address-to-chunk lookup, and verified-state
load even though GALE01 has no REL modules.

The retained data-free host preflight
`scripts/g5_direct_guard_preflight.cpp` models a complete edge rather than an
isolated branch:

1. check the target;
2. directly call a no-inline callee;
3. compare the exact continuation PC; and
4. check the continuation.

It compares the old indirect callback shape, two inline chunk-eligibility byte
loads, and an unguarded floor across 16 statically distinct sites. Its model
self-check refuses an invalidated chunk, a globally disabled direct-link path,
and a forced-fallback target after the runtime-owned byte is cleared. This is
representation proof only; no product ABI or runtime state was changed.

The benchmark was compiled with AppleClang `-O3 -std=c++20 -Wall -Wextra
-Werror`. Disassembly confirms that its callback has the same stack-save,
host-call query, and tail-call shape as the preserved candidate, while its
`FastDispatchable` retains the same cold REL call and hot DOL lookup structure.
The source SHA-256 is
`ce23dc597e984c17c1fb8d906151a0ea931a81855c088e58ad8447ed1f6764e9`.

## Repeated result

Two rotated-order runs each measured 2,000,000 batches, 16 edges per batch,
and 15 repetitions per representation:

| Metric | Run 1 | Run 2 |
| --- | ---: | ---: |
| Unguarded median | 3.181561 ns/edge | 3.183969 ns/edge |
| Inline median | 3.187736 ns/edge | 3.197195 ns/edge |
| Callback median | 9.062361 ns/edge | 9.164049 ns/edge |
| Callback-to-inline saving | 5.874625 ns/edge | 5.966854 ns/edge |

PERF-076 removed 35,472,511 dispatches over 440 frames. A nested call removes
one dispatch when it exits early and two when it reaches its continuation, so
the measured workload bounds direct edges at 40,309.672 to 80,619.343 per
frame. Applying the benchmark saving projects only:

- 0.236804–0.240522 ms/frame at the conservative edge bound; or
- 0.473608–0.481044 ms/frame at the deliberately optimistic bound.

The clean no-profile control's 15.699995 ms CPU-thread mean requires a
0.785000 ms improvement to clear 5%. PERF-076's callback candidate already
saved 0.260529 ms. Even adding the largest optimistic inline projection yields
only 0.741573 ms / 4.72%, with a predicted 14.958422 ms CPU mean. It remains
short of the 14.914995 ms threshold. The likely edge count is nearer the
conservative bound because a completed nested call removes both target and
continuation dispatches.

## Decision

**Reject the broad per-edge inline table before a game build.** It is safe to
represent invalidation this way, but the necessary cost preflight fails. Do
not add another public/GXRuntime ABI field, regenerate all 237 chunks, retrain
PGO, or retry the callback/table designs.

This rejection strengthens the case for a bounded profile-derived superblock:
one entry guard can amortize safety across several observed dispatch edges,
avoid broad text growth, and give Clang a region in which guest state can stay
live. The retained PERF-075 sample identifies the first candidate chain:
`8036C8D8 -> 8033FB64 -> 8036C8E4 -> 80377B6C -> 8036C904 -> 8033FBA0 ->
8036C91C`, with dominant successors after the initial branch. Next statically
exclude cache-control, host-call, exception, and indirect-control boundaries,
then create a focused generated regression before any game module.

No game or Simulator was launched for this preflight. Final Destination and
G6 remain blocked by G5.
