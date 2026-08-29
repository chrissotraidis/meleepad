# G5 quiet input-harness reversal

Date: 2026-08-29

Status: **STREAMED-HARNESS SEVERE TAIL EXCLUDED; RESIDUAL PACING FAILS G5**

## Question

After disk headroom was restored, why did a canonical no-observer Fountain
control contain five 33 ms producer gaps when PERF-145/146 had none? The game
ran beside the Codex UI while `gcpipe.py` streamed hundreds of progress lines
through the active tool session. Does rendering that diagnostic output distort
the host scheduling tail?

## Matched reversal

PERF-153 and PERF-154 used the same:

- canonical runner and current-PGO module;
- verified Fountain slot-1 state;
- signed fullscreen/Game Mode-eligible `.app`;
- Metal, Cubeb, native scale, display-sync policy, and buffered stock Dolphin
  `render_times.txt` logger;
- 45-second balanced input sequence; and
- one native process, no Simulator, and Logitech still stopped at 0% CPU.

Both select the conservative final 2,001 presented-frame rows. The only
intended variable is the input tool's stdout: PERF-153 streamed each sequence
step into the live Codex session, while PERF-154 redirected those messages to
`/dev/null`. The input FIFO and timings were unchanged.

## Result

| Metric | PERF-153 streamed | PERF-154 quiet |
| --- | ---: | ---: |
| Mean / implied FPS | 16.708388 ms / 59.8502 | 16.666653 ms / 60.0000 |
| Median | 16.666125 ms | 16.665583 ms |
| p95 | 16.793208 ms | 16.796250 ms |
| p99 | 16.891375 ms | 16.848875 ms |
| Worst | 33.330875 ms | 22.544875 ms |
| At or below 16.7 ms | 1,436 (71.764%) | 1,396 (69.765%) |
| Above 17 / 20 ms | 12 / 8 | 3 / 2 |
| Approximately 30-33 ms | 6 | 0 |

Silencing output does not improve p95 or the percentage under 16.7 ms, so it
is not a product optimization. It does remove the severe observer tail and
restore exactly 60 FPS mean. Streamed terminal/UI progress is therefore
excluded from future acceptance measurements.

The two remaining quiet-run outliers are pacing pairs rather than sustained
under-speed:

- `22.544875 + 11.455625 = 34.000500 ms`; and
- `10.996834 + 22.290125 = 33.286959 ms`.

Only one other row exceeds 17 ms (17.351250 ms). Strict G5 still fails because
the unchanged requirement is a 16.7 ms worst interval, not a 60 FPS average.

The post-run host audit found no thermal or performance warning and 59% free
memory. It did find concurrently active WindowServer, Codex, OpenCodex/Bun,
and Brave processes. Those spot values are not causal attribution and no
unrelated user process was stopped. They reinforce that a next host-contention
test requires explicit authority and a matched reversal, not blame by process
name.

## Visual and private evidence

Both runs show coherent Pikachu/Fox Fountain combat. No fighter-mesh warping
recurs; the lower reflection remains the documented reference behavior.

- PERF-153 streamed render log:
  `c663a0fd954ef8a73838dc0cec4d7d137b13781cca14ffebaf0c13ff7b0b8c90`
- PERF-153 start/end images:
  `a10332a03480c8299b616651f7c2849f40f0d221fbcf70b25134fd0fc566f8b6` /
  `8480a84f37a331641c94f80ec6ee0047b2496296f86d0e7bd0e406e3e595bccb`
- PERF-154 quiet render log:
  `075199c347c8bf96e9a81f74f91b8b826fd97ace4df8d79b50dd2f8533355abe`
- PERF-154 start/end images:
  `689b6e20d828670262fa6eb86bf784de90991139c849e3b65ca1eb0e4b73d68f` /
  `877ae33dbb50ca463bb33916226e9e36b6f904fa0a230482eacb8f3bb5d2a7ce`

## Decision

No product code or configuration changed. Future performance input runs must
silence per-step controller output and avoid live terminal/UI streaming during
the measured window. This is a harness correction, not a G5 pass.

G5 remains open on two isolated 22.3-22.5 ms delayed/catch-up pairs. Do not
retry GPU, guest-code, presentation, timer, QoS, or Game Mode changes from this
result. A test that pauses unrelated user applications requires explicit user
authority; until then, continue only with product-local causal evidence. G6
remains blocked.
