# G5 Final Destination off-core reversal

Date: 2026-08-28

Status: **COMMON OFF-CORE TAIL CONFIRMED; TRANSIENT BACKUP/BROWSER LOAD REJECTED**

## Question

Does the current Final Destination producer tail come from static-recompiled
game work, video/Metal, audio, throttle wake-up, or host descheduling? Did the
high transient `fseventsd`, Brave, and Time Machine-adjacent load observed
after PERF-136 create the result?

## Harness corrections

A first PERF-136 launch was excluded because a one-second PID lookup missed
the runner and a retry created a second instance. Both were stopped and no
trace was used. A second single-process launch delivered `SIGUSR2` before the
platform handler was installed and exited by the default signal action; it is
also excluded. The accepted launch waited for the phase CSV to reach 4 KiB,
proving runtime initialization, then delivered the existing deferred state
request. Exactly one process survived and visibly loaded the retained
fullscreen Final Destination state.

The current runner/module/state hashes remain those recorded by PERF-135. The
default-dormant phase logger was the only diagnostic change. No product code,
settings, ROM, save, or app artifact is committed.

## PERF-136 attribution

PERF-136 selected exact emulated frames `32600..34600`, 2,001 rows wholly
inside live Final Destination combat:

| Metric | Mean | p95 | p99 | Worst |
| --- | ---: | ---: | ---: | ---: |
| Total | 16.669230 | 17.149958 | 17.508334 | 27.640792 ms |
| CPU wall | 16.553086 | 17.337166 | 17.990223 | 24.253918 ms |
| CPU thread | 5.665406 | 6.729403 | 7.531269 | 9.792909 ms |
| Wall minus CPU thread | 10.887681 | 11.650846 | 12.364465 | 19.608531 ms |
| Video build | 13.185279 | 14.052709 | 14.266625 | 18.850417 ms |
| Audio mix | 0.892400 | 1.311417 | 1.337917 | 1.461124 ms |

1,177/2,001 rows (58.821%) meet 16.7 ms; four exceed 20 ms, three exceed
24 ms, and none exceed 33 ms. CPU-thread work easily meets budget in every
row. The worst frame, emulated frame 34455, spends only 4.148374 ms on the CPU
thread, loses 19.608531 ms off-core, and has only 0.117750 ms video build. The
next two 24 ms rows lose 18.512840 and 17.178708 ms off-core. Audio and
throttle lateness are ordinary.

Private phase SHA-256:
`92c18abe13076de867fed7e52fdc7e80d4e95c89b1367f7ff9aa43572450d8ac`.

## Host-load reversal

Immediately after PERF-136, a process snapshot showed `fseventsd` near 95%, a
Brave renderer previously near 63%, WindowServer around 31-44%, and the Logi
Options+ updater around 16-37%. Time Machine reported `Running = 0`, and five
five-second snapshots showed `fseventsd` and Brave fall out of the top load
set while WindowServer and the Logitech updater remained. No user application
or service was closed or reprioritized.

PERF-137 repeated the exact app, phase logger, state, fullscreen configuration,
and 39-second input sequence after the transient filesystem/browser spike had
cleared. No Computer Use or file copy occurred inside the interval. Exact
frames `31100..33100` produce:

| Metric | Mean | p95 | p99 | Worst |
| --- | ---: | ---: | ---: | ---: |
| Total | 16.666241 | 17.148000 | 17.557416 | 30.737000 ms |
| CPU wall | 16.549903 | 17.328289 | 18.279506 | 27.234867 ms |
| CPU thread | 5.663237 | 6.748984 | 7.644537 | 12.767411 ms |
| Wall minus CPU thread | 10.886666 | 11.808270 | 12.209261 | 24.645359 ms |
| Video build | 13.635837 | 14.060167 | 14.235750 | 14.522834 ms |
| Audio mix | 0.910395 | 1.312751 | 1.357625 | 1.475124 ms |

1,163/2,001 rows (58.121%) meet 16.7 ms; three exceed 20 ms, one exceeds
24 ms, and none exceed 33 ms. The 30.737 ms worst frame does only 2.589508 ms
of CPU-thread work, loses 24.645359 ms off-core, and spends 0.140500 ms in
video build. Clearing the transient filesystem/browser load therefore does
not improve p95 and does not remove the off-core class.

Private phase SHA-256:
`082ba14abc4f5ed348626d0814cee6f85e4142b7aeed8290b814e1b08905cf89`.

## Decision

Final Destination and Fountain share the same remaining natural failure:
occasional runnable/off-core host loss plus ordinary drawable pacing, not an
M1 compute ceiling, generated-code cost, GPU rendering, audio, or timer
lateness. Transient Time Machine-adjacent filesystem work and Brave activity
are rejected as the cause because their removal leaves the distribution and
mechanism intact.

Do not retry static compiler flags, runner PGO, QoS, time-constraint policy,
precision timers, dual-core mode, drawable lifecycle, scheduled presentation,
Rush presentation, or phase-logger overhead. The persistent WindowServer and
Logitech updater load was not isolated and must not be blamed without a
controlled reversible comparison. G5 remains open; G6 remains blocked. The
next action must introduce a genuinely new host-scheduling mechanism or obtain
explicit authority for a controlled background-load isolation; otherwise
return to actual-display evidence rather than optimizing already-fast on-core
execution.
