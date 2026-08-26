# G5 direct verified-chunk table rejection

Date: 2026-08-26

## Question

Can the chassis remove the module's duplicate address-to-generated-function
lookup while preserving the canonical generated segment boundaries and all
existing semantic/timing guards?

## Candidate

The canonical chassis already resolves a guest address to a verified chunk
index for SMC enforcement, then the module performs another address lookup to
find `func_XXXXXXXX`. A temporary ABI 4 added a `StaticRecompChunkFn` table
parallel to the unchanged 237 chunk ranges. After the ordinary forced-fallback,
SMC, and host-call guards, the chassis called the already-resolved function
pointer directly.

This did not batch blocks or change generated code. Segment returns, cycle
flushes, timebase updates, exceptions, host calls, downcount checks, and event
delivery remained at their canonical boundaries.

The candidate runner/module existed only in a temporary signed app. The
unsigned module SHA-256 was
`60a2079337028bd961481792f239ed532aa7118b029f012b88c6f62b51162816`.
The packaged runner/module remained
`9bff54e4fd747aa4088beae1e847149a06fc7046bd4141e9d684aed58c1f355b` /
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.

## Matched semantic gate

Both headless runs used the same 5,000,000-dispatch lockstep window, 20-report
print cap, 512-step cap, game root, and approximately 20-second interval.

| Metric | Direct-chunk candidate | Canonical control |
|---|---:|---:|
| Checks | 1,401 | 1,398 |
| Reports | 88 | 88 |
| Fallback skips | 7 | 7 |
| Zero skips | 3 | 3 |
| Undercharges | 0 | 0 |

The printed report sequence also matched. The candidate passed this bounded
semantic screen and was allowed to proceed to visible Fountain.

## Visual gate and route correction

MemoryWatcher preceded the cold boot and proved the genuine title lockout,
Main Menu, and CSS. Computer Use visibly verified:

- coherent VS CSS at 60.0 FPS;
- P1 Pikachu and level-1 CPU Yoshi;
- the literal `Fountain of Dreams` stage label;
- coherent live fighter geometry and input;
- the normal Yoshi winner screen.

This run proved the retained character sequence selects Yoshi, not Ness. The
script and all earlier C1024 references are corrected accordingly. A first
Fountain screen read 49.6 FPS, but the decision uses the CSV bracket rather
than that title sample.

## Stable Fountain result

Frames 17,000-21,742 exclude match-load and end/result transitions:

| Metric | Result |
|---|---:|
| Frames | 4,743 |
| Mean / FPS | 16.933658 ms / 59.053986 FPS |
| p50 / p95 / p99 | 16.766791 / 18.752725 / 20.255358 ms |
| Worst | 33.403667 ms |
| Frames <=16.7 ms | 44.529% |
| Frames >25 / >50 ms | 1 / 0 |
| CPU-thread mean / p95 | 16.646930 / 18.567576 ms |
| Native dispatches mean / p95 | 137,923.653 / 151,010.400 |
| Guest cycles mean / p95 | 8,107,174.581 / 8,137,988.800 |

The candidate is semantically screened and visibly coherent, but it fails the
absolute G5 tail and mean-FPS requirements. Like the earlier direct-original
candidate, changing module lookup/layout helps some menu work but regresses
required-stage combat.

## Decision

**DIRECT VERIFIED-CHUNK TABLE REJECTED AND REMOVED; ABI 3 AND GENERIC MODULE
DISPATCH RESTORED; G5 OPEN; FINAL DESTINATION NOT RUN; G6 BLOCKED.**

The temporary app/build/evidence were moved to Trash. No game process or
Simulator remained. Retained temporary hashes:

- phase CSV:
  `333743459af66907b0d5147456c4b1c2e426f265d1871c51b777461c48ad6e98`
- watched cold-route log:
  `de6ce15e977f8b47d9159c6c39c44964495b5a1e8270b5cef1a5d5e4cd2cd396`

Do not retry another module-lookup or code-layout shortcut until the repeated
Fountain-only regression is attributed with a mechanism that predicts both
menu and combat behavior.
