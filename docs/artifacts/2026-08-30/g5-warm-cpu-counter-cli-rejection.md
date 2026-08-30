# G5 warm CPU-counter CLI rejection (PERF-203)

Date: 2026-08-30

Status: **EXACT WARM FOUNTAIN REPRODUCED; XCTRACE ATTACH DATA INVALID; NO PERFORMANCE CLAIM; G5 OPEN**

## Question

Can Apple CPU Counters distinguish instruction delivery, discarded work, and
processing pressure inside the exact same-process warm Fountain window, rather
than averaging an unrelated combat interval?

## Preflight and corrected game gate

The installed `CPU Counters` template records and exports when `xctrace`
launches a two-second data-free `yes` control. Its per-thread tables expose
1 ms bottleneck samples, cycles, core identity, P/E-core residency, and
backtraces. This made an exact timestamp join technically plausible.

Two harness defects were corrected before the accepted stage reproduction:

1. A 12-second savestate signal was too early for revision 0's roughly
   132-second title lockout. The signal-load path must wait for advancing game
   state, as the retained goal ledger already requires.
2. Dolphin reads the MemoryWatcher address list at startup. The corrected
   client registers both title-lockout `0x804D4594` and GameState `0x80477D68`
   before launch and binds the next socket before each state signal.

The final private run then proved this sequence with exactly one native runner
and no Simulator:

- title lockout became nonzero and returned to zero;
- the first slot-1 load reached exact GameState `0x02020102` and exited it
  naturally;
- a second slot-1 load in the same process reached exact GameState
  `0x02020102`; and
- CPU Counters attached only after that second combat predicate passed.

The private state is the established Fountain SHA-256
`e481363325c55a200066e6f30d48b6c53d8fcc6ebf6286f88e6e88d72a0ab5de`.
A fresh capture eight seconds into the attached window shows literal Fountain
of Dreams at `1:43.19`, a coherent Fox, Pikachu's KO/score transition, and the
known translucent lower-stage/reflection behavior. Its private SHA-256 is
`5b28de311d8add43385eaa5936646f1bd7ab5a7d8608d249568643c719098c06`.
No fighter-mesh morph is visible in that frame.

## Invalid trace result

The attached 20-second game trace reached its requested time limit but
`xctrace` terminated with `SIGTRAP` while aggregating counters. The resulting
602 MiB trace contains only `RunIssues.storedata`; `xctrace export` reports
`Document Missing Template Error`. Crash incident
`4EB8DFC6-4237-4453-8ED3-4896B1541375` faults inside
`SystemCounterAggregator.receive` on the frame-activity queue. The crash report
SHA-256 is
`6f530adeffa3ef935e6e3eeb6a3c16160895a2794d41242ec33fd6b6cd838304`.

The run also exposed a package-identity mismatch before any false join: the
reusable PGO bundle still contains pre-recorder runner
`e1f3c1d81efdc6110dc05c8c2059b61547b39a790f4b3db8cbdbd4163ad60828`,
whereas the current diagnostic runner is
`472ccfc2527b1690f6518117c98733fd0de8df1015b7b18ba9d28b400cd6f5c2`.
Both use the same PGO module
`bd0893031a28e94ba0b9f7eb84cc41d08daa10639759fdb7c1b71feb7af26f5a`.
Because the older runner has no lightweight recorder, no frame-clock CSV
exists and no counter/frame join is possible even if the trace had survived.

A final data-free five-second attach falsified the idea that only game volume
caused the failure: `xctrace` ignored completion, remained live, produced an
unexportable 4.4 GiB trace, and required stopping its three owned preflight
processes. That exact disposable invalid trace was deleted to recover disk;
it cannot be recovered. No user data or unrelated process was touched.

## Decision

**Reject command-line CPU Counters attachment as the exact warm-frame method on
this Xcode 16/macOS 26.5.2 installation.** The launch-only control does not
validate attach finalization, and both attach forms fail before usable tables
exist. Do not retry a longer trace or describe the invalid trace as hardware-
counter evidence.

This does not invalidate earlier retained, successfully exported CPU-counter
work, and it does not prove a new performance cause. The exact warm Fountain
reproduction is visual/harness evidence only. Retain no product edit; no game,
`xctrace`, `yes`, or Simulator remains. G5 stays open and G6 blocked.
