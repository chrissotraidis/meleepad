# G5 64-bit gather-pipe write rejection

## Question

Retained paired PSQ stores reach the GX gather pipe as one 64-bit external
write. `StaticRecompCore::HookExternalWrite` handled that width by expanding it
to eight `GPFifo::Write8` calls even though Dolphin already provides
`GPFifo::Write64`. Would matching the semantic width reduce the required
Fountain tail without changing bytes or guest-visible behavior?

## Host preflight

A temporary Release benchmark linked Dolphin's real `core` and compared eight
ordered `Write8` calls with one `Write64`. Both paths produced exactly
`01 23 45 67 89 AB CD EF`. Five fresh processes reported stable net speedups:

| Process | `Write8` x8 net ns | `Write64` net ns | Speedup |
|---:|---:|---:|---:|
| 1 | 18.662 | 2.334 | 7.994x |
| 2 | 18.734 | 2.310 | 8.111x |
| 3 | 18.715 | 2.342 | 7.992x |
| 4 | 18.647 | 2.327 | 8.014x |
| 5 | 18.986 | 2.380 | 7.976x |

The temporary target and source are removed. This proved local chassis
headroom only; it did not predict whole-game gain.

## Candidate and semantic gate

The only candidate source change added `case 8` beside the existing 1/2/4-byte
gather-pipe arms and called `GPFifo::Write64`. A regression-first guard failed
before that arm and passed after it. A bounded lockstep run was matched against
the current promoted control:

- 1,398 checks;
- 91 reports;
- seven fallback skips and three zero skips;
- zero undercharges and zero maximum cycle deficit;
- the first 20 report categories and order matched.

The signed isolated artifacts used the same module:

- control runner:
  `48a0943191be8905fdce9f05e87b38d5c4dc2e335a853563a9d6e3937b635ff5`;
- candidate runner:
  `57d1d0f6a4201cceca648b4a22f6ada23d59276091b24bbad78722a190c7896c`;
- common module:
  `2fe01870bfa0fbedc51aa20105ba0738c3b367e98c9566629001a8236e2fa1b3`.

## Live brackets

The first visually verified candidate was P1 Pikachu versus level-1 CPU Peach
on literal Fountain. Stage-load and results transitions delimited exactly
7,430 rows in both binaries. The same wall-time combat sequence was sent:

| Metric | Exact rebuilt control | Candidate |
|---|---:|---:|
| Mean / effective FPS | 18.678609 ms / 53.537 | 19.578675 ms / 51.076 |
| p50 | 18.540563 ms | 19.200500 ms |
| p95 | 20.974708 ms | 22.605417 ms |
| <=16.667 ms | 4.66% | 2.50% |
| CPU-thread mean | 18.267077 ms | 19.040345 ms |
| Native dispatches/frame | 137,968.160 | 140,527.972 |
| Guest cycles/frame | 8,107,175.250 | 8,107,170.860 |
| Static fallback steps | 0 | 0 |

That candidate was slower, but wall-time input delivery means a slower binary
receives actions on different emulated frames. The result is valid product
evidence but not clean causal attribution.

A second pair removed all P1 match input. Candidate roster and literal
Fountain were visually verified as Pikachu/CPU-Zelda. Both logs again had an
exact 7,431-row load-to-results interval:

| Metric | No-input control | No-input candidate |
|---|---:|---:|
| Mean / effective FPS | 18.895951 ms / 52.921 | 18.640614 ms / 53.646 |
| p50 | 18.774500 ms | 18.106333 ms |
| p95 | 21.424541 ms | 23.150917 ms |
| <=16.667 ms | 4.49% | 8.76% |
| CPU-thread mean | 18.493367 ms | 18.228283 ms |
| Native dispatches/frame | 148,239.920 | 183,024.690 |
| Guest cycles/frame | 8,108,268.991 | 8,107,178.541 |
| Static fallback steps | 0 | 0 |

Mean moved by 0.255 ms in the candidate's favor, while p95 worsened by
1.726 ms. More importantly, CPU AI diverged by about 34,785 native dispatches
per frame, so this pair cannot isolate the chassis change.

## Shared-state attempt

Dolphin's standalone no-GUI main installs `SIGUSR1`/`SIGUSR2` save/load
handlers, but this branded runner uses a different entrypoint: `SIGUSR1`
terminated the verified Pikachu/CPU-Ness Fountain seed. The macOS State menu's
Command-Shift-F1 and Shift-F1 variants were then sent through Computer Use;
neither produced a state file under the isolated user directory or standard
application-support paths. No shared-state result is claimed, and no runner
code was added for this attempt.

## Decision

**CANDIDATE REJECTED AND REMOVED; G5 OPEN; G6 BLOCKED.** The candidate did not
approach 60 FPS, worsened p95 in both recorded brackets, and has no
reproducible workload-matched live gain. The compelling microbenchmark is not
allowed to override that evidence. Temporary benchmark/guard code and the
`Write64` arm are removed; the promoted signed product was never replaced.

The next prerequisite for another small performance candidate is a
frame-deterministic comparison harness: either expose a verified save/load
state path in the branded runner or gate controller replay to an emulated
frame source. Do not retry gather-width, GQR0-helper, global MMU, or guest-PC
special cases without that harness.

## Cleanup and verification

- canonical source runner rebuilt successfully;
- 16/16 `gcpipe` tests pass with `PYTHONPATH=scripts`;
- frontend config, GameCube config, netplay protocol, and memory-watcher CTest
  rows pass 4/4;
- promoted app passes strict deep codesign verification;
- promoted runner/module hashes remain
  `48a0943191be8905fdce9f05e87b38d5c4dc2e335a853563a9d6e3937b635ff5`
  and
  `2fe01870bfa0fbedc51aa20105ba0738c3b367e98c9566629001a8236e2fa1b3`;
- no game process or booted Simulator remains.

## Evidence

All files are under `docs/evidence/g5-gpfifo64-rejection/`:

- `candidate-pikachu-peach-fountain.phase.csv` —
  `3cf9d50edd780adbba3b0f1766666f6f31a33952243d25471bed32b072e57fd7`;
- `control-pikachu-peach-fountain.phase.csv` —
  `decdf720400a5b85764d06068d0aae8a5b3242654f28d02475589da9b7f056d1`;
- `candidate-idle-pikachu-zelda-fountain.phase.csv` —
  `575aa031a3258851a36cdf65c020c0b6d9972dece79d0b00923e9a4a4c6d3bd7`;
- `control-idle-pikachu-zelda-fountain.phase.csv` —
  `66d7c1a32e5f0f670fdc5294940f3615e525bec1451750308525bb6da23ab333`;
- `candidate-pikachu-peach-results.png` —
  `b2a00aed7af3ad3e5937b763fd14b9cd6fbdbe61dbfeec253b1d11f8be5aa6f6`;
- `candidate-idle-pikachu-zelda-combat.png` —
  `0639ebe37da0c6279bb3e2cbe286bb103c39392e494f8ef5d1338b14eb2a55bf`;
- `candidate-idle-pikachu-zelda-results.png` —
  `a7521a487375b0147d5d9d505cde63361b01a49fe984aac71a54eadde334f7a5`;
- `shared-state-attempt-pikachu-link-combat.png` —
  `77be6c037ac1f972c8b0d31e1676e2f610306f2222ab9ec474cbee5912985df2`.
