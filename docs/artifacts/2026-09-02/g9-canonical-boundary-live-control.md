# G9 B1 canonical-boundary live control

Date: 2026-09-02

Result: **PARTIAL.** The canonical comparator now produces matching records in
live synchronized Melee combat. This closes the two-Mac diagnostic preflight,
not B1: the required consecutive five-minute Mac/iPad matches in both host
directions remain open.

## Packaging regression and correction

The first combat run used an isolated desktop wrapper whose copied
`GALE01r0.ini` still contained only the obsolete `0x80349494` idle PC. The
runner contained the canonical code, but neither caller-qualified setting was
loaded, so no boundary record could be captured.

The macOS package-layout regression now requires the current main idle PC
`0x80348814`, caller PC `0x80019550`, and caller LR `0x801A4064`. It correctly
rejects the stale package. Both isolated profiles were seeded with those same
values for the rerun because the test-only wrapper does not resolve bundled
GameSettings like the product bundle.

Both endpoints then reported:

```text
[staticrecomp] caller idle pc=80019550 lr=801a4064
[staticrecomp] canonical-boundary active pc=80019550
```

## Live result

The paired route reached two-human character select with independent P1/P2
Pipe input, selected Mario and Bowser, and entered Fountain of Dreams. The host
accepted four exact peer comparisons with no canonical mismatch, unpaired
record, legacy desync, or crash:

```text
[netplay] canonical-match sequence=598200 state_hash=0x6a12c37eaea02bc6 ram_hash=0xe8c39e1e794e5f00
[netplay] canonical-match sequence=946800 state_hash=0x3aa4c965b1a56381 ram_hash=0x7c7530579ab6809e
[netplay] canonical-match sequence=958800 state_hash=0x0d2dc514f9ce5ac3 ram_hash=0xa74ac8fe780e204e
[netplay] canonical-match sequence=982200 state_hash=0x97fa2e9ee8bd0949 ram_hash=0xf1d07b1f6f1a76db
```

The route also exposed a repeatability weakness: five wall-clock seconds is
not enough for menu input lockout while two emulators contend on one M1. The
retained B1 title-to-CSS sequence uses twelve-second transition waits and the
analog stick for VS selection; its focused controller tests pass.

## Decision

Accept the canonical design for cross-platform testing: exact synchronized
CPU/FPU/paired state, timebase, and sampled MEM1 can match during real combat.
Do not call netplay beta-ready or B1 complete. The next experiment is the
unchanged comparator in iPad-host/Mac-join, followed by Mac-host/iPad-join,
each on the full five-minute route with results and rematch. Any mismatch must
name the first differing component; no tolerance or timing workaround is
permitted.

No ROM, module, save, private path, or raw private log is retained here.
