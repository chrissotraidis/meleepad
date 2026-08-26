# G5 8,192-instruction C chunk semantic rejection

Date: 2026-08-26

## Question

Can larger generated C functions reduce cross-chunk return/redispatch cost
without changing SMC verification, exception and host-call exits, cycle
accounting, bounded event delivery, or guest semantics?

## Rationale

The rejected 1,024-instruction experiment increased native dispatches from the
roughly 128,000/frame control to 161,478/frame and added about 2.6 ms of CPU
thread time. The generator already keeps direct branches and dynamic returns
inside a chunk while returning on its existing cycle budget, exceptions, host
calls, and outside-chunk targets. Testing 8,192 instructions therefore directly
tests the opposite side of the same boundary-cost hypothesis without adding a
new runtime batching loop.

## Isolation and build

The C generator's accepted environment range was temporarily extended from
4,096 to 8,192 only in the ignored dependency checkout. A stale sibling
`dolrecomp` initially emitted its explicit `128..4096` warning; that canonical
compile was stopped immediately and moved to Trash. A temporary tool directory
then paired `moderngekko-port` with the verified rebuilt generator.

The correct candidate produced:

- 119 hashed chunks versus the canonical 237;
- an 83 MB module;
- module SHA-256
  `8bba5fca26361bf0cebe34d05a9d1f54fec262349f244e683e5cf8d701f9e292`.

The candidate existed only under `/tmp`; it was never installed into the
product app or active module cache.

## Matched lockstep result

Both runs used the same canonical runner, headless game root, start value,
5,000,000-dispatch limit, 20-report print cap, 512-step cap, and approximately
20-second wall interval.

| Metric | C8192 candidate | Canonical C4096 control |
|---|---:|---:|
| Checks | 1,245 | 1,398 |
| Reports | 91 | 88 |
| Fallback skips | 7 | 7 |
| Zero skips | 3 | 3 |
| Undercharges | 0 | 0 |

The candidate shared the control's first ten report PCs, then introduced three
additional memory-writing report entries:

- `0x80339460`
- `0x803394C4`
- `0x80339510`

Those entries contained large register and RAM-journal mismatches. The later
candidate report sequence resumed at the control's next known report PC. The
matched totals therefore isolate a three-PC semantic report-set expansion,
not merely a higher print cap.

## Decision

**C8192 REJECTED BEFORE VISUAL OR PERFORMANCE TESTING; PRODUCT UNCHANGED; G5
OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.**

The generator source and rebuilt generator binary were restored to the
canonical `128..4096` limit. The 548 MB candidate tree and temporary tools
were moved to Trash. No game process or Simulator remained.

Do not retry larger monolithic C chunks. Cross-segment optimization must keep
the canonical generated segment boundaries visible to the existing semantic,
SMC, and timing checks, or first strengthen the verifier enough to prove that
a boundary transformation is equivalent.
