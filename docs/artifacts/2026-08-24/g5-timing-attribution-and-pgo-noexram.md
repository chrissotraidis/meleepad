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
