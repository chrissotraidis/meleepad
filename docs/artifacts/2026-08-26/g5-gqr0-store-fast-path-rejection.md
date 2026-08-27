# G5 GQR0 paired-store fast-path rejection

Date: 2026-08-26

## Question

Would selecting a guarded default-float GQR0 helper in generated code reduce
the six paired-store calls sampled in `WriteMTXPS4x3` without changing guest
semantics?

## Semantic and build screen

Regression-first tests referenced the absent helper and failed at link time.
The candidate then covered paired and `W=true` float writes, quantized GQR0
fallback, HID2/LSQE exception CIA, and no-write behavior. GXRuntime passed 1/1
and DolRecomp passed 14/14 tests.

The helper checked the live GQR0 type/scale fields and fell back to canonical
`ppc_psq_store` when they were non-default. Both C and LLVM emitters selected
it only for encoded GQR index zero; there was no game ID, guest PC, address,
or renderer special case. The cache produced distinct key `714512b16f05c99a`
and unsigned module SHA-256
`8b4973e62855600087f6bb9d2d08275baed9b3b6c820ae0aac05080774eb5478`.
The isolated signed app retained the canonical runner SHA-256
`48a0943191be8905fdce9f05e87b38d5c4dc2e335a853563a9d6e3937b635ff5`;
its signed candidate module SHA-256 is
`6f9fb3387b5dc0313c5ae5f15169aa193de057de7e34c3ac70908c59fad59b74`.

## Live Fountain result

Computer Use explicitly verified P1 Bowser, level-1 CPU Ness, literal Fountain
of Dreams, and coherent live combat. Menus held 59.8-60.1 FPS, but combat read
44.9-54.6 FPS. Frames 41,579-47,064 are the immutable combat bracket:

| Metric | Candidate |
|---|---:|
| Frames | 5,486 |
| Mean / FPS | 20.823964 ms / 48.022 |
| p50 / p95 | 20.706416 / 23.354708 ms |
| p99 / worst | 25.496666 / 142.053500 ms |
| Frames <=16.7 ms | 1.713% |
| CPU-thread mean / p95 | 20.331661 / 22.750468 ms |
| Video-build / present mean | 0.065349 / 0.020794 ms |
| Audio mean | 1.063638 ms |
| Guest cycles/frame | 8,107,170.859 |
| Native dispatches/frame | 149,650.631 |
| Static fallback steps | 0 |

The last 1,800 rows remained at 20.947574 ms / 47.738 FPS with 23.858459 ms
p95, so startup transients do not explain the result. The two retained combat
screens show coherent Bowser and Ness meshes; no adjacent-frame recurrence of
`VISUAL-001B` occurred.

## Decision and cleanup

**CANDIDATE REJECTED; G5 OPEN; G6 BLOCKED.** A sampled helper is not
automatically a profitable call split. The candidate increased ordinary
Fountain dispatch work and decisively missed the frame budget. All helper,
emitter, prototype, and regression changes are removed. The active pointer is
restored to retained paired-store key `1e1debc9fb83a31a`; the promoted product
was never modified, and no game process or Simulator remains.

Next: perform a host-only semantic/cost preflight for a general ordered GX FIFO
matrix batch matching `WriteMTXPS4x3`. Require fewer external callback
transactions and exact ordered bytes before another module build. Do not retry
the GQR0 call split, global MMU shortcuts, or guest-PC specialization.

## Retained evidence

- `docs/evidence/g5-gqr0-store-rejection/bowser-ness-fountain.phase.csv` —
  `d44f29e54c964c07438e348a857c48904d32095ea168647b3ec123c1770267b9`
- `docs/evidence/g5-gqr0-store-rejection/bowser-ness-fountain-combat.png` —
  `a27f43b5dd63a64bc41b1caa90c23ee96ce4de9017df038f6d716e80ef3b3a7b`
- `docs/evidence/g5-gqr0-store-rejection/bowser-ness-fountain-adjacent.png` —
  `bcbb0060b901aee829a34cfacaa1364e7715bccb73b5125b792a35f9f39a6703`
