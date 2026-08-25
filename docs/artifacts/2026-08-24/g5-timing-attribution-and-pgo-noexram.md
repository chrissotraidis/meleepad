# G5 timing attribution and combined PGO/no-EXRAM experiment

Date: 2026-08-24

## Timing attribution

The remaining portable-PGO tail was instrumented with temporary, default-off
timestamps at `CountFrame` and at the host throttle boundary. The trace records
render delta, host-clock delta, CPU work before throttling, requested sleep,
throttle markers, and guest cycles. Frame timestamps align with the render log
at offset zero with 0.000123 ms mean absolute error; the frame stream contains
only two extra reset/final entries.

The selected final 90-second no-input attract interval contained 5,275 frames:

| Metric | Value |
|---|---:|
| Mean | 17.063532 ms |
| Median | 16.687000 ms |
| p95 | 17.975471 ms |
| p99 | 18.753514 ms |
| Worst | 1569.559792 ms |

Frames above 17 ms averaged 18.940491 ms render time, 19.318792 ms host-clock
time, 16.756990 ms CPU work, and 2.561802 ms requested sleep. The 19 frames
above 20 ms averaged 79.959 ms CPU work and 41.127 ms sleep. The worst frame
combined 933.964 ms work with 636.776 ms catch-up sleep.

This diagnostic attributes the sustained tail primarily to generated-module
compute, not Metal presentation or timer overshoot. Large scene transitions can
combine excess work and subsequent catch-up sleep. Attract mode remains a
diagnostic and does not replace the two required-stage acceptance traces.
Temporary instrumentation was removed before the next build.

Evidence: `g5-attract-timing-attribution-90s-joined.txt`, SHA-256
`8e94a27b2fe126e13dc07fedb435bdb9eed756bd54a5c207171b8ba748f456b7`.

## PGO plus GameCube-only no-EXRAM

The smaller no-EXRAM specialization had improved the clean Fountain p95 by
3.0%, while portable PGO was within 0.9% of the 16.7 ms p95 threshold. A
combined candidate therefore tested whether the gains composed.

`GXRUNTIME_ASSUME_NO_EXRAM` compiled the Wii MEM2 branch out of
`get_ram_ptr`; no memory layout, guest clock, graphics, audio, or pacing value
changed. The complete arm64 macOS 14 module used O2, ThinLTO, and the retained
local PGO profile. The unsigned 66 MiB dylib had SHA-256
`92eb69e7abc0c9d5adae54a9d26b1f4ce64618d3cc8c2971c094694b88aaf940`.

The candidate loaded through the native static-recomp core. A matched
cumulative 60-150 second no-input attract window was compared with the retained
portable-PGO/default-timer window:

| Render metric | Portable PGO | PGO + no-EXRAM | Change |
|---|---:|---:|---:|
| Frames | 5,135 | 5,139 | +4 |
| Mean | 17.528468 ms | 17.513954 ms | 0.08% lower |
| Median | 16.682666 ms | 16.682792 ms | unchanged |
| p95 | 17.848100 ms | 19.334579 ms | 8.3% worse |
| p99 | 18.813991 ms | 20.477221 ms | 8.8% worse |
| Worst | 3132.187584 ms | 3055.315375 ms | still multi-second |
| Frames <=16.7 ms | 61.25% | 61.59% | +0.34 points |

Candidate vblank timing was 16.683299 ms mean / 20.538429 ms p95 /
21.864502 ms p99 / 98.516625 ms worst.

**Rejected before required-stage replay.** Median did not improve and the
steady-state p95/p99 tail regressed substantially. The build-time header change
was restored byte-for-byte. The packaged app was restored to native runner
SHA-256 `d2642b463a41e0a94a3cc2869b836ed3ab5cb7777eb0ea9d9f0240c7c760cff6`
and signed portable-PGO module SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.
No runner or Simulator remains active.

Candidate raw evidence:

- `g5-pgo-noexram-attract-90s-render-times.txt` — SHA-256
  `17b2cdd710e83149fe94bcc77a0be0804fd627dc031cc9a210a186fc47f21076`
- `g5-pgo-noexram-attract-90s-vblank-times.txt` — SHA-256
  `597f3599af89eaedd7cbdb788c00e1209058ac58e04095c4143af4716529834d`

## Generated loop-cycle budget

The profile's dominant `loop_80349494` helper entered 135,977,937 times and
executed approximately 86 guest polling iterations per entry, matching the
default 256-cycle return budget at three charged cycles per iteration. A
profile-free experiment raised only `DOLRECOMP_C_LOOP_CYCLE_BUDGET` to 1024,
reducing potential host-dispatch returns by about four while widening the host
timing-check interval to approximately 2.1 microseconds at GameCube CPU speed.

The full arm64 macOS 14 O2 + ThinLTO module was 79 MiB with unsigned SHA-256
`47f8a8deda64254e11207f8103e2180ef30d443ba6fb555a0cfe32fd1c509953`.
It loaded successfully, but the matched no-input attract window regressed:

| Metric | Default 256 + PGO | Clean budget 1024 |
|---|---:|---:|
| Frames | 5,135 | 4,863 |
| Mean | 17.528468 ms | 18.508955 ms |
| Median | 16.682666 ms | 16.757250 ms |
| p95 | 17.848100 ms | 22.926175 ms |
| p99 | 18.813991 ms | 24.989434 ms |
| Worst | 3132.187584 ms | 3597.894417 ms |
| Frames <=16.7 ms | 61.25% | 44.77% |

Candidate vblank timing also regressed to 17.284516 ms mean / 22.410896 ms
p95 / 24.254269 ms p99 / 103.979333 ms worst. **Rejected.** Reducing host
returns this way harms timing/pacing enough to overwhelm any dispatch saving.
The default 256-cycle setting is restored; an intermediate budget is not
justified without a narrower mechanism.

Raw evidence:

- `g5-loopbudget1024-attract-90s-render-times.txt` — SHA-256
  `987cf448d0b6083c1f8877dd67c2ce4013eb37a8ac3bc722ae08da4abdae47a4`
- `g5-loopbudget1024-attract-90s-vblank-times.txt` — SHA-256
  `12a6c590d42d80315ebe0de3eb9032ff43e1be0931ceec6eb4add387309cef83`

## Exact PGO-cold helper outlining

Binary/profile comparison found 247 loop helpers present only as symbols in
the PGO module. Every one had a profile entry count from zero through nine and
196 were never entered. Unlike the rejected blanket experiment, a clean
candidate forced `noinline` on exactly those 247 cold helpers across 55 chunks;
hot and common helpers retained normal compiler policy.

A single-chunk oracle first proved the transformation moved all five selected
helpers out of the hottest chunk's giant dispatcher, reducing that dispatcher's
LLVM IR by about 2,410 lines. The full profile-free arm64 macOS 14 O2 + ThinLTO
candidate contained all 247 intended symbols plus the unchanged hot polling
helper. It exposed 839 loop symbols, between clean's 592 and PGO's 779, with
unsigned dylib SHA-256
`282460556c0f8051f7b07846f1ad03be55a1f4c30b196e061e34029efd4c2be4`.

The matched no-input attract diagnostic regressed:

| Metric | Default 256 + PGO | Clean cold-outline 247 |
|---|---:|---:|
| Frames | 5,135 | 4,714 |
| Mean | 17.528468 ms | 18.309539 ms |
| Median | 16.682666 ms | 16.813833 ms |
| p95 | 17.848100 ms | 21.458772 ms |
| p99 | 18.813991 ms | 22.548414 ms |
| Worst | 3132.187584 ms | 3778.770166 ms |
| Frames <=16.7 ms | 61.25% | 43.68% |

Candidate vblank timing was 17.180410 ms mean / 16.712042 ms median /
22.494150 ms p95 / 23.229264 ms p99 / 86.862708 ms worst. **Rejected.** Exact
cold helper symbol reproduction is not sufficient; PGO's internal branch
weights and hot/cold block layout are material. Generated sources were restored
byte-for-byte and the portable-PGO app restored exactly.

Raw evidence:

- `g5-cold-outline247-attract-90s-render-times.txt` — SHA-256
  `0aa68813c5622c5ff6a8f1193177a9a7a6a105131a1e9a9752c680d0bf3f976b`
- `g5-cold-outline247-attract-90s-vblank-times.txt` — SHA-256
  `2b293a4f6d2bf70367ee8e176891b3194dcc6f0991242b30cedba6d6d838e267`

## Broader local PGO corpus

The original instrumented module and Fountain profile were preserved. A new
three-minute no-input attract run produced a separate valid 43 MiB `.profraw`,
SHA-256
`7ed5a14aad9351719ddcd9105c28fede2e7a2d57abdd5aa332fe70415146610d`.
The original Fountain raw profile was weighted 2:1 over attract and merged to a
22 MiB profile with the same 6,531 functions and 2,733,180 blocks, SHA-256
`e95c0a2c64413713e687a68135bf10b43b27add423e5eeb9189dab93e6858314`.

The resulting clean-source arm64 macOS 14 O2 + ThinLTO module exposed 775 loop
symbols and had unsigned SHA-256
`1102ff900c5e638ba68a9678e090cdc433017e5a306117ec7dd724550e530763`.
It loaded successfully. Against the same retained PGO attract window:

| Metric | Fountain PGO | Fountain 2 + attract 1 PGO |
|---|---:|---:|
| Frames | 5,135 | 4,995 |
| Mean | 17.528468 ms | 17.743956 ms |
| Median | 16.682666 ms | 16.683125 ms |
| p95 | 17.848100 ms | 17.682021 ms |
| p99 | 18.813991 ms | 20.654338 ms |
| Worst | 3132.187584 ms | 3618.040375 ms |
| Frames <=16.7 ms | 61.25% | 62.84% |

Candidate vblank timing improved to 16.685468 ms mean / 18.533521 ms p95 /
19.611345 ms p99 / 105.444291 ms worst. **Rejected before required-stage
replay.** The generic attract corpus slightly improved p95 and vblank tail but
worsened render mean, p99, and worst. A broader useful profile must train on
Fountain and Final Destination directly rather than generic attract coverage.
The instrumented and profile-use artifacts remain local and uncommitted.

Raw evidence:

- `g5-combined-pgo-attract-90s-render-times.txt` — SHA-256
  `e8fb7a9efb504250572e75d4e07ca32694ee31934f8847c1525f0707e85fd6f3`
- `g5-combined-pgo-attract-90s-vblank-times.txt` — SHA-256
  `cd6f91b93660ff6a58d29a297526cea39e3d61a5a3da14f146a2329fdda38da1`
