# PERF-269 — warm exact dispatch non-reproduction

Date: 2026-09-01

Status: **diagnostic complete; cold failure did not reproduce; no product change**

## Question

Does the exact route's previously measured 16.224 ms CPU-thread interval have
one guest-PC or host-boundary hotspot large and safe enough to justify the next
optimization?

## Method

Run the unchanged published 1,000,000-tick SyncGPU candidate through the same
state-verified Samus/level-1-CPU-Kirby Stock/04/05:00 Fountain route. Enable
only the existing default-off phase log and one-in-4,096 dispatch-frame sample.
The product configuration, module, input sequence, and app data are unchanged.

Private evidence hashes:

- dispatch CSV:
  `9cff2fa7b7e60d2b1a488efc761437d15bdaa8ce3603d06df10b687357e920a3`;
- phase CSV:
  `6583c56ed43d397bd0b1944724bec853702ad57bafc39781eeceb1f36e211552`;
- state-driven route log:
  `92b19c289b4af81c5087a3b550e00c02d5f1a601b0a6b225b44aef6346cf3765`;
- runtime log:
  `11daa44f7551e71bff89c2c4bd9a8c46deed4976c55938425513e8c5c8e0c6e1`.

## Result

The runtime held 59.9-60.0 FPS/VPS through the timestamps that previously
reported 57.5 then 53.5 FPS/VPS. Underruns reached three, not five, and no
crash, FIFO, malformed-command, panic, fatal, unknown-command, or desync report
appeared. The bad cold interval therefore did not reproduce on this repeat.

The same emulated-frame range, 3,124-3,714, differs materially:

| Metric | Failed cold run | Warm sampled repeat |
|---|---:|---:|
| total mean | 16.912 ms | 16.712 ms |
| CPU-thread mean | 16.224 ms | 12.197 ms |
| static guest cycles / row | 8.11 M | 4.43 M |
| native dispatches / row | 523 k | 206 k |
| Mach syscalls / row | 3,925 | 1,502 |
| throttle sleep / row | 0.577 ms | 3.876 ms |
| pipelines | 16 | 8 |

The repeat is not the same expensive workload merely running faster. It
executes and schedules materially less static work per presented row, then
uses the recovered margin to throttle.

## Dispatch distribution

The sampled repeat retained 29,652 dispatch PCs in the selected range. No
individual PC exceeds 5.75%. CPU-heavy rows concentrate in a related load and
state family: `lbDvd_80018F68`, `lb_8001CBBC`, `lb_800192A8`,
`lb_80019628`, `cbForStateGettingError`, `gm_801A4014`, and HSD resource/draw
boundaries. The two largest boundary targets are 5.75% and 5.69%; treating
them as independently safe optimization sites would be misleading. This is
consistent with cold resource initialization, but the warm non-reproduction
cannot establish which cache or worker state controls it.

## Decision

Do not build from this trace. It cannot predict a five-percent cold-route gain,
and the related broad direct-call, FastDisc, pipeline-seed, and generic preload
directions already failed causal reversals.

The next experiment must reproduce the deficit twice from a genuinely fresh
process/cache state without deleting the user's game data or saves, then
compare the failed and recovered runs by host-time route boundary—not merely
by phase row number. Only a state difference that consistently predicts the
8.11 M-cycle/523 k-dispatch interval may authorize a code change. Row 7,
physical-iPad promotion, and G9 remain closed.
