# G9 cross-platform execution fingerprint

Date: 2026-09-02

Result: **PARTIAL.** The native iPad-host/macOS-join path now distinguishes
small static-recomp dispatch-boundary skew from a real cross-platform
divergence, but the pair still stops in the opening combat sequence. This is
not a complete match, mobile Online Play, or 60 FPS pass.

## Question

The aligned-DOL, exact-generated-source pair previously failed an exact
timebase check at frame 7,440. The next loop needed to determine whether the
first mismatch was network delay, unlike timebase origins, scheduler sampling,
or different guest execution.

## Execution fingerprint

Dolphin patch `0043` extends the existing 60-frame timebase record with:

- guest PC and CoreTiming ticks;
- fake-timebase start ticks/value;
- static-recomp native dispatch, charged-cycle, and burst counts; and
- FNV-1a hashes for integer/control, scalar-FPR, paired-single/FPSCR, and
  combined architectural state.

The data is sampled on Dolphin's CPU-thread callback. No RAM, ROM content,
save data, module bytes, or private path is serialized or retained.

## Controls

The first aligned run proved that the timebase gap exactly followed the
CoreTiming gap divided by Dolphin's 12-cycle timer ratio. It also showed
different native-dispatch and charged-cycle totals at the same reported frame,
ruling out packet transport and the timebase formula itself.

Disabling only the iPad caller-idle path removed the first frame-120 mismatch
but regressed the stop to frame 6,240. That asymmetric control was reverted.

The source audit then found that iPad configured both the main and
caller-qualified idle sites while executable-only macOS boot read only the
main GameINI setting. The retained candidate gives both platforms the same
main PC `0x80348814` and caller-qualified PC/LR pair. At frame 60 this reduced
the measured difference to 107 CoreTiming cycles, or 9 timebase ticks.

A temporary diagnostic-only 20-mismatch threshold was used once to observe the
sequence and immediately restored to Dolphin's product default of two. Through
frame 2,520 the peers repeatedly had the same PC; unequal samples usually
oscillated within 2–20 ticks, with exact samples interspersed. Component hashes
all differed at those asynchronous same-PC samples, confirming that this hook
does not run at a shared instruction boundary and cannot be promoted into a
canonical state checksum.

## Bounded comparison and real failure

The candidate keeps Dolphin's two-consecutive-mismatch rule. A record is
equivalent only when timebases are exact, or when every peer reports the same
guest PC within 2,048 timebase ticks. The bound is about 0.31% of one NTSC
frame. A different PC is never accepted by the bound. Full and component state
hashes remain diagnostic evidence rather than an acceptance bypass.

In the native UIKit host run, the large frame-0 startup skew remained one
reported mismatch. Frame 60 and the following same-PC boundary samples reset
the consecutive count. The pair passed the old immediate failure, remained
connected through the opening, and then correctly rejected a real divergence:

- frame 6,180: macOS PC `0x8033821c`, iPad PC `0x80019550`, approximately
  11.0 million timebase ticks apart;
- frame 6,240: macOS PC `0x8037c360`, iPad PC `0x80019550`, approximately
  11.0 million timebase ticks apart.

Every architectural hash family differed at those frames. Dolphin stopped the
pair after the second consecutive mismatch. Network ping was approximately
1 ms; the iPad overlay fell from 59.6–60.0 FPS in the opening to 39.3–41.0 FPS
around the failure. This run therefore connects the remaining cross-platform
failure to the unresolved full-load CPU/performance boundary, not packet
latency.

## Lockstep classification

The earlier verifier's first unresolved report,
`0x803210A4 -> 0x80321178`, reaches the named endpoint after roughly 40
interpreter steps and then revisits it while consuming the native interval's
257-cycle charge. Replaying the full charged interval removes that address
from the report stream. It is another early-endpoint verifier artifact, not a
proven generated-code semantic defect. The remaining broad reports are in the
known stale paired-single/FPSCR and journal-limitation families and do not
justify a product change.

## Decision and next experiment

Retain symmetric idle configuration, the bounded same-PC comparison, and the
diagnostic fingerprints. NL4/NL5 remain partial/failed. Do not claim stable
60 FPS, a complete cross-platform match, physical-device readiness, or public
Online Play.

The next falsifiable step returns to the row-7 mechanism lane: profile the
frame-6,180 combat slowdown with the product comparison active and determine
why the iPad CPU path falls to roughly 40 FPS while the Mac peer advances to a
different guest phase. A candidate must improve that exact interval without
weakening the different-PC rejection, input synchronization, rendering,
audio, or lifecycle behavior.
