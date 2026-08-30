# G5 dispatcher frame-split rejection (PERF-212)

Date: 2026-08-30

Status: **CALLING-CONVENTION ROUTE REJECTED; COLD-PATH SPLIT SEMANTIC BUT IMMATERIAL; PRODUCT UNCHANGED; G5 OPEN**

## Question

PERF-206's native-PC ring increased the share attributed to
`StaticRecompCore::Run` and generated code. Can a custom ARM64 calling
convention or a narrower split of the module dispatcher's cold paths remove
material register traffic at the chassis/module boundary?

## Actual optimized boundary

The active PGO runner is
`e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`.
Its `StaticRecompCore::Run` prologue saves x19-x28 once, when `Run()` starts.
At the hot `m_module->dispatch(&m_guest, linked_dispatch_address)` call, the
compiler passes the two arguments and executes `blr`; it emits no adjacent
spill or reload. Live loop state already occupies ordinary AAPCS callee-saved
registers.

Applying `preserve_most` to the ABI therefore cannot remove caller traffic.
Applying it only to `chassis_dispatch` would instead require that function to
preserve additional registers across its ordinary generated callee. Applying
it to every generated function would add preservation at every dispatch.
Neither direction has a positive mechanism.

The current module's `chassis_dispatch` does have a smaller opportunity. Rare
host-call and physical-alias paths keep x19 live, so the common generated hit
uses this frame even when `ctx->host_call` is null:

```text
sub sp, sp, #0x30
stp x20, x19, [sp, #0x10]
stp x29, x30, [sp, #0x20]
add x29, sp, #0x20
...
blr x8
...
ldp x29, x30, [sp, #0x20]
ldp x20, x19, [sp, #0x10]
add sp, sp, #0x30
ret
```

The retained branch counter previously measured 373,345,803/373,345,803 Main
Menu dispatches as generated-original hits, with zero host probes, aliases,
replacements, or misses. A frame-layout screen was therefore distinct from
the rejected lookup reorder and direct-call experiments.

## Isolated split candidate

A disposable source change preserved exact public precedence:

1. replacement;
2. installed host call;
3. generated original;
4. physical alias with the same three subprobes; and
5. miss.

Only the post-replacement host path and post-original alias path moved to
`noinline` helpers. The candidate was built in an ignored module directory and
was never copied into an app. ThinLTO emitted the intended common path:

```text
str w1, [x0, #0x280]
ldr x8, [x0, #0xd70]
cbz x8, common_original
b chassis_dispatch_after_replacement
...
stp x29, x30, [sp, #-0x10]!
mov x29, sp
blr x8
mov w0, #1
ldp x29, x30, [sp], #0x10
ret
```

The x19/x20 save pair and separate stack adjustment disappear. Module text
grows only 296 bytes, from 81,959,380 to 81,959,676 bytes. The candidate dylib
was `a1382d1b5b9d69b6e3d57df59041875c56e870f0447576f060f363949f00240b`.

## Data-free semantic and timing screen

A disposable two-module harness loaded the untouched packaged control and the
isolated candidate as distinct images. It compared every CPU-state byte except
the intentionally distinct RAM pointer and all 24 MiB of RAM after each call.
It passed:

- 512 randomized executions of generated GALE01 function `0x803408A0`;
- an installed host-call hit;
- an installed host-call miss followed by an original hit;
- physical-address aliasing to the same generated function; and
- a complete miss.

The harness binary was
`aca45e45e0e99d8c0841f5e16e093dbd1807e585f636ef5fb2ebb07cf44f505f`.
Nine alternating one-million-call repeats measured 49.414833 ns control versus
49.239583 ns split, saving 0.175250 ns/call or 0.354651%. Nine alternating
five-million-call repeats confirmed 49.475708 ns versus 49.285442 ns, saving
0.190267 ns/call or 0.384566%.

At PERF-135's 116,775 dispatches/frame, the confirmed saving projects to only
0.022216 ms/frame. That is approximately 0.18% of PERF-207's 12.273 ms mean
combined-thread CPU time, far below the retained 5% product-build threshold
and incapable of correcting the separate 17-35 ms wall tails.

## Restoration and decision

Reject both the custom calling convention and cold-path frame split. The
temporary comparator source was removed, and the disposable executable was
deleted. The module template returned byte-for-byte to source SHA-256
`c42b3cffd04af43a91348da504cccf54c507615a3575d7dab30dcf14b37f5dc6`.

The old ignored module directory still contains PERF-074's historical order
file in its CMake link flags, so its restored-source relink is not asserted
byte-identical to the active package. The actual packaged frontend-PGO module
remained untouched at
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
No candidate reached the app, no game was launched, and no Simulator or
unrelated process was touched.

G5 remains open. Do not add `preserve_most`, repeat this cold-path split, or
infer a game-FPS improvement from the data-free microbenchmark.
