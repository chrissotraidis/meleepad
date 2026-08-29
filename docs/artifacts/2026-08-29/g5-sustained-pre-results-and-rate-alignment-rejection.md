# G5 sustained pre-results window and rate-alignment rejection

Date: 2026-08-29

Status: **PRE-RESULTS TAIL REPRODUCED; 1001/1000 HOST-RATE ALIGNMENT REJECTED; G5 OPEN**

## Questions

1. Does the clean confirmed-Game-Mode Fountain result remain close to 60 FPS
   over a longer replay, or was PERF-173 only a short lucky window?
2. Can aligning the exact `60000/1001` guest cadence to this fixed 60 Hz panel
   remove the residual presentation holds without changing guest code,
   renderer behavior, or timer implementation?

## Long-run boundary correction

An initial 36-cycle attempt was actively polled through its PTY and is not used
as a product-speed sample. The accepted repeat ran in a silent persistent
session with no session polling during gameplay. It used the same exact PGO
runner/module, private Fountain state, Metal, Cubeb, fullscreen Game Mode,
quiet controller input, one game, and no Simulator as PERF-173.

Both long attempts reached their first very large presented-frame interval at
exact absolute render-log row 6,784: 629.340125 ms in the actively observed
attempt and 621.296875 ms in the clean attempt. Each was followed by additional
roughly 247-285 ms intervals about 6-8 seconds apart. This repeated absolute
boundary is consistent with the already classified match/results transition,
not random host contention. Post-boundary rows are excluded from combat-speed
claims. No fresh screenshot was taken, so this classification is based on the
repeated log boundary plus the retained PERF-130/131 transition evidence and
is not presented as a new visual observation.

The clean final 2,001 pre-transition rows, 4,783 through 6,783, measure:

```text
mean             16.666780026 ms
FPS from mean    59.999592
median           16.664292000 ms
p95              16.785125000 ms
p99              16.835750000 ms
worst            16.946375000 ms
<= 16.7 ms       1,448 / 2,001 (72.363818%)
> 17 ms          0
> 20 ms          0
```

The wider 4,001-row pre-transition window averages 16.683472184 ms / 59.939561
FPS, with 16.792250 ms p95 and 33.291500 ms worst. It contains five rows above
20 ms and four above 33 ms. This confirms both the stable near-budget body and
the rarer pre-results one-refresh hold class. The clean raw render log was
retained privately with SHA-256
`72152e5dfaa912f737c841d44c49727ed6d1c51c5854de9e9440fe78ae1d2d02`.

## Reversible rate-alignment candidate

The private `Dolphin.ini` changed only `EmulationSpeed` from its default 1.0 to
1.001, the exact `1001/1000` wall-rate scale that maps a `60000/1001` source to
60 Hz. The same signed app, state, 18-cycle input, Cubeb, Metal, fullscreen,
and Game Mode gate were reused. No source, guest tick sequence, generated
module, renderer setting, audio backend, or timer implementation changed.

Its exact final 2,001 presented-frame rows measure:

```text
mean             16.675137619 ms
FPS from mean    59.969520
median           16.664958000 ms
p95              16.791291000 ms
p99              16.847959000 ms
worst            33.281208000 ms
<= 16.7 ms       1,391 / 2,001 (69.515242%)
> 17 ms          2
> 20 ms          1
> 33 ms          1
```

The candidate therefore aligns the nominal body but does not prevent the
fixed-panel/compositor hold and does not improve the p95 tail. Runtime shutdown
recorded 603,792,383 native dispatches, zero fallback, and zero failed SMC
verification. Cubeb was active, Game Mode was on before state load, and macOS
reported no thermal or performance warning.

Private candidate hashes:

- render log: `8785604848eb90523b00da50f8375b36554870bf1067fa28fd7afc5b0430b355`;
- vblank log: `a179e7390a6ac3acb25e422c0a9b9e4f4b3c11593784b437ba7832442bc126f4`;
- stderr: `1e7eb8d43ca55cc04aeeec613eb0f832932e1f95e08ecbfe4b1cbd629f5cac7e`;
- Game Policy log: `09074b031a22cfb6d1954ed10c61d8b16f263a6e7a69ae7e0f6991b7df7e4901`.

## Reversal and decision

`EmulationSpeed = 1.001` was removed immediately after the run. The private
configuration returned byte-for-byte to SHA-256
`1f3a69fa0b44bb01dbea8b59c39ca88793c3c08d3d1c8ac3233685dd1e29c2b2`.
No game or Simulator remains.

**Reject host-rate alignment.** It cannot satisfy strict D2 on this display and
would introduce a product-wide wall-rate policy without eliminating the hold.
Do not increase the scale further, drop distinct guest frames, or relabel the
results transition as combat. Continue G5 only from a distinct pre-results
producer/host-presentation mechanism. Final Destination and G6 remain blocked.
