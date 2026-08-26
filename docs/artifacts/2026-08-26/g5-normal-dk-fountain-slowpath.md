# G5 normal-runner DK/Fountain slow path

## Question

Was the new 50-55 FPS behavior caused only by dispatch-return diagnostics, or
does the normal signed runner contain a real roster/scene-sensitive slowdown?

## Diagnostic boundary

Three dispatch-return classifiers were screened and none was retained:

- Exact per-dispatch classification visibly reduced Stage Select to about
  44.5 FPS. The run was stopped before combat and excluded.
- One-in-256 classification reached live Pikachu-versus-CPU-DK Fountain, but
  its 1,799-frame interval averaged 17.945 ms / 55.727 FPS. The additional hot
  path made it ineligible for acceptance timing.
- Classification piggybacked on the existing one-in-4096 dispatch sample. A
  600-frame no-input preflight averaged 16.685 ms / 59.935 FPS, but sustained
  interaction later fell to 50-55 FPS. This still could not distinguish
  observer cost from scene cost.

The attribution source and its proposed canonical patch were removed. The
normal phase logger was rebuilt, copied into the application, and signed. Its
SHA-256 returned to `c26625db7fd1eb504f418ad8ab52a3accc61bb222fd08b369c7804a5465d5598`;
the corrected generated module remained
`2dce13525a8d76f3f8795f343f5967f26fe57c0d30379fbaa37d1f80ec6db829`.

## Matched normal-runner result

The watcher-first cold route visibly established P1 Pikachu, level-1 CPU
Donkey Kong, an explicit Fountain of Dreams selection, coherent live combat,
and Cubeb audio. No dispatch-return classifier was present. The latest 600
capture-free, pre-results rows are retained in
`g5-normal-pikachu-dk-fountain-slowpath.csv` (SHA-256
`ae30e7768c61dc265015fd85a16327716b6eb13d9020fd932c0c942511e95d90`).

| Metric | Result |
|---|---:|
| Frames | 600 (`22970..23569`) |
| Mean / median | 19.761 / 19.909 ms |
| p95 / p99 / worst | 21.551 / 23.098 / 26.278 ms |
| Average FPS | 50.605 |
| Frames <=16.7 ms | 2.000% |
| CPU-thread mean / p95 / p99 | 19.575 / 21.273 / 22.462 ms |
| Video build / present / audio mean | 0.069 / 0.022 / 0.978 ms |
| Native dispatches / guest cycles mean | 124,143 / 8,107,183 |
| Interpreter and cache fallbacks | 0 |

The animated menus also visibly slowed during the investigation. That visual
observation is a valid regression signal but is not promoted to a strict
numeric menu bracket: the only explicit 44.5 FPS menu reading came from the
rejected exact classifier. No screenshot from the normal-runner match was
retained because the temporary UI capture expired before it could be copied;
the CSV is the retained performance evidence.

## Decision

The slowdown is real and workload-sensitive, not solely classifier overhead.
The prior normal-runner Pikachu-versus-CPU-Kirby Fountain control averaged
16.686 ms / 59.932 FPS with a 16.045 ms CPU-thread mean and roughly 130,000
native dispatches/frame. The DK run spends about 3.53 ms more CPU time per
frame despite fewer dispatches and essentially the same guest-cycle budget.
That rejects timer tuning and total guest-work count as the next target.

G5 remains open. The next experiment is a non-invasive, phase-gated native CPU
sample of the slow DK scene, compared with the fast Kirby control, to identify
the generated chunks or host helpers whose cost per dispatch changes. Menu
slowdown remains in the regression scope. Final Destination and G6 remain
blocked until the strict Fountain distribution passes.

## Subsequent correction

A fresh cold normal-runner replay of the same Pikachu/level-1-CPU-DK/Fountain
roster visibly held 59.8-59.9 FPS through active combat and results. This
falsifies the claim above that DK is a deterministic content trigger. The
50.605 FPS CSV remains a valid slowdown observation, but the current evidence
supports an intermittent host/path-state cause, not roster attribution. Its
external sample found the known scheduler idle loop at the top of 156/886 CPU-
thread samples. See `g5-idle-precharge-rejection.md`.
