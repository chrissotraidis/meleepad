# Fountain static-work attribution and QoS rejection

Date: 2026-08-25

Status: **HOST-COST TAIL ATTRIBUTED; USER-INTERACTIVE QOS REJECTED; G5 OPEN**

The default-off phase logger now records per-frame static-recompiler bursts,
charged guest cycles, native dispatches, interpreter fallback steps, and
instruction-hook fallbacks. It snapshots existing counters once per CPU slice;
no hot generated dispatch gains an atomic operation. The patch applies cleanly
from pinned Dolphin, the runner builds, and a live smoke populated every
expected field while interpreter fallback remained zero.

The visually verified Fountain control retained 3,678 capture-free combat
frames (`g5-static-work-control.csv`, SHA-256
`0dd409b369b5dbb8c79ef21d2b7db3450e065ed7274fa1751c189dd213b02e5a`).
Total p95/p99/worst were 16.975/17.232/51.412 ms. Tail frames did not execute
more guest work: versus the <=16.7 ms body, mean bursts were 0.25% lower and
charged cycles were 0.04% lower. Host nanoseconds per native dispatch instead
correlated 0.783 with total time. The worst frame ran an ordinary 6.505 million
guest cycles but cost 52.513 ms compute and 731 ns per dispatch.

A single default-off behavior candidate raised only the emulation CPU thread
to macOS `QOS_CLASS_USER_INTERACTIVE`; the API returned zero. The identical
visually verified Fountain route retained 3,714 frames
(`g5-static-work-qos-candidate.csv`, SHA-256
`2169bf8f3e5c1ae90639892240c93b972801ab28e8dcab221b86f6e351095229`).
It reduced worst from 51.412 to 18.002 ms, improved p99 from 17.232 to
17.216 ms, and raised the <=16.7 ms share from the control to 58.428%.
However, p95 regressed from 16.975 to 17.031 ms. The complete strict
distribution therefore did not improve, so the QoS behavior patch was removed.

The diagnostic counters are retained because they falsify guest-work volume as
the cause of the largest spikes. The next step is a matched repeat/control that
can separate rare host preemption from systematic per-dispatch cost before
another behavior change. No Simulator was booted.

