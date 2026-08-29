# G5 Activity Monitor isolation A leg

Date: 2026-08-29

Status: **LOADED A CONTROL RETAINED; OPTIONAL ISOLATION PARKED; G5 OPEN**

> PERF-184 correction: this A leg records an observation only. Activity Monitor
> does not need to be paused for the project to continue. B/A2 is parked as an
> optional future diagnostic and is neither a prerequisite nor a blocker.

## Host audit

No authority had been given to pause unrelated user applications, so this step
changed none. A read-only current snapshot identified the exact active load:

- Activity Monitor, PID 69567, varied between 0.6% and 7.3% CPU across nearby
  snapshots;
- its root-owned sampling helper `sysmond`, PID 1279, varied between 0% and
  4.0% CPU;
- the complete Brave family was about 0.1-1.6% CPU and Claude was effectively
  idle;
- OpenCodex's `bun.exe`, PID 626, showed one transient 16.5% sample, then seven
  of eight two-second samples at 0.0-1.7% except one 6.4% sample; and
- the Logitech updater and agent remained stopped at 0% CPU as previously
  directed. LogiRightSight remained idle at 0%.

OpenCodex, Codex, ChatGPT, Logitech, Brave, Claude, and every system daemon are
therefore outside the smallest proposed B scope. Only Activity Monitor itself
is a candidate for reversible pause. `sysmond` must never be signaled; any
reduction in its work should occur naturally when Activity Monitor stops
requesting samples.

## Unchanged A control

The current signed PGO app and module, isolated Fountain state, fullscreen
Metal, Cubeb, confirmed Game Mode, quiet 18-cycle input, one game, and no
Simulator ran while Activity Monitor remained active. Host snapshots before
and after prove the same Activity Monitor PID remained present; neither it nor
any other external process was altered.

Exact final 2,001-row result:

| Metric | Render | Vblank |
|---|---:|---:|
| Mean / implied FPS | 16.725132 ms / 59.790259 FPS | 16.725230 ms / 59.789910 FPS |
| Median | 16.667250 ms | 16.652041 ms |
| p95 | 16.795167 ms | 17.588541 ms |
| p99 | 16.852791 ms | 18.426541 ms |
| Worst | 33.468333 ms | 36.375250 ms |
| Above 20 ms | 7 | 12 |
| At or below 16.7 ms | 70.715% | 55.872% |

All seven render gaps above 20 ms are doubled frames between 33.163 and
33.468 ms. Matching vblank stalls occur at the same relative rows. The loaded
A result is worse than the recent quiet title-on control's 59.969577 FPS and
two >20 ms rows, but that historical comparison is contextual only; it is not
a causal A/B because host time differs.

The A run reached Game Mode on before state load and ended with 616,133,411
native dispatches, zero interpreter fallback, zero failed SMC verification,
Cubeb active, and no thermal or performance warning. Private evidence hashes:

- render log: `eaf43177092ce41f444d6fb7d47b7e295b1527542ed70b762c11609e04faa2e9`
- vblank log: `921dc6349796d5f63f1fab9d0015939f3da1885521a93fe711b3a9d82872fc2e`
- selected render window: `db7ffd787ea1adf3861e54cbfa8bddcf4e2af3a52f71a0d224c7f02bc523ea37`
- selected vblank window: `a54591ba1dac1de525e647fb60348eab8069aabd861ba629574c62d3e7afdcfb`
- host-before snapshot: `bb2b72c23f2523b923b6cf76035608bbeb75df9bcbac1943fd137105d4a0e4b1`
- host-after snapshot: `705104656e9f09b85a6e8c7979f6cc1a9609e390d7fe8da5acafb218b0476126`
- runtime stderr: `0719caa57007c0439c38c3e51c8310c2058a940420ca42d3c0883fc8665fbe9d`
- Game Policy log: `91f421dbfe0b0545ef3cde650d5ff79f8dd383afb8a0610b19f35f9c2596dc45`

## Optional follow-up, not a blocker

This is not a causal verdict and does not authorize external manipulation.
If the user ever explicitly requests completion of this optional experiment,
the exact safe scope would be:

1. verify Activity Monitor's current executable identity;
2. send `SIGSTOP` to only that user-owned Activity Monitor PID;
3. verify Activity Monitor is stopped and `sysmond` naturally settles, without
   signaling `sysmond`;
4. run the identical Fountain B leg;
5. send `SIGCONT` to the exact stopped PID and verify it resumes; and
6. run identical resumed A2.

Brave, Claude, OpenCodex, Codex, ChatGPT, Logitech, and all system services
remain untouched. Do not run B or infer Activity Monitor causality. Failure to
run B/A2 does not block continued goal-loop work. G5 remains open; G6 remains
blocked. No game or Simulator remains.
