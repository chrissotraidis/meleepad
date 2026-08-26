# Fountain repeat control and thread-CPU attribution

Date: 2026-08-25

Status: **TAIL IS MAINLY ON-CORE COST; G5 OPEN**

An unchanged second Fountain control retained 3,678 visually verified,
capture-free frames. Its p95 reproduced the first control almost exactly
(16.975204 versus 16.975 ms), p99 was 17.205534 ms, and worst was 21.604041 ms.
The earlier 51.412 ms cluster is rare, but a smaller ordinary-work host-cost
cluster recurred. Evidence: `g5-static-work-repeat-control.csv`, SHA-256
`4c71b786fc7382202be5f9c3dd422cb869f234c659685a76fd6e3d7f043c97b6`.

The default-off phase logger was then extended with CPU-thread execution time
from `CLOCK_THREAD_CPUTIME_ID`. It applies cleanly from the pinned dependency
stack and builds. A route attempt that visibly launched Yoshi's Story was
discarded without a bracket. A fresh route initially returned to CSS with P2
N/A; stepwise visual correction exposed the stale assumption: the script had
picked P1's character token back up. P1 Pikachu was re-locked, P2 CPU Mario
level 1 was enabled, Stage Select explicitly showed `Fountain of Dreams`, and
live Fountain was verified before timing.

The valid 3,628-frame bracket measured total p95/p99/worst of
16.969765/17.183966/19.088000 ms. Thread CPU was 10.860363 ms mean,
11.679757 ms p95, 12.498748 ms p99, and 16.450571 ms worst. The residual after
subtracting idle, throttle sleep, and thread CPU from CPU wall was only
0.018378 ms p95 and 0.148006 ms p99. Tail frames averaged 0.207 ms more thread
CPU than the body but only 0.067 ms more residual off-core time. The 19.037 ms
frame spent 16.451 ms on-core and 2.377 ms residual; the tail is therefore
mainly real on-core execution cost, not scheduler preemption. Evidence:
`g5-thread-cpu-attribution.csv`, SHA-256
`49eac2409df452d537b9de0649c4747e8ce935b7891441068151cfebb9da65bd`.

Static corrected-source inspection finds 325 fallback sites, 222 unique raw
instructions. The largest site classes are XO 467 (`mtspr`) and XO 339
(`mfspr`); cache XO 54/86/470/982 sites are already handled by the runtime fast
path. Since runtime hook fallbacks occur roughly 5,000-7,000 times per frame,
the next diagnostic should classify runtime fallback frequency by instruction
class before optimizing one class.

No Simulator was booted.

