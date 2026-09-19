# Private iPad preview: online mode enablement

The owner requested access to Ranked, Teams and Party for hardware testing.
The preview's local `AllowsSearch` policy previously rejected those modes before
any service request. The existing adapter contains their matchmaking, team
selection, game reporting and ranked set-status paths; the linked maintained
Rust FFI calls the real reporter rather than no-op replacements.

The policy now accepts Ranked, Unranked and Party without interpreting the
saved Direct-code buffer. Direct and Teams retain nonempty code, length and
control-byte validation; meaning and eligibility are validated by the service.
Unknown modes remain rejected. The requested mode passes through unchanged;
account/version checks, server rejection handling and ranked reporting remain
in place. This enables testing, not proven mode compatibility.

The UIKit status copy now describes all five modes. Search counters distinguish
Ranked, Unranked, Direct, Teams and Party, including reset behavior. The existing
adapter-generation script and private input contract use the same observer, so
newly prepared adapters cannot silently count every non-Direct request as
Unranked. No new patch file or bootstrap patch replay was introduced.

## Current search observation

Read-only hardware telemetry before replacement showed two Unranked searches,
two accepted waiting transitions, zero opponent-connection transitions and zero
matchmaking errors. The latest state was waiting for assignment. No game had
started in that session. This establishes service acceptance of the requests,
not current player population, why no match was assigned, or peer connectivity.

## Validation

- 40 compiled host checks passed: all mode IDs, missing/malformed codes,
  Shift-JIS code bytes, per-mode counters/reset and existing frame telemetry.
- Nine private-input contract tests passed and all 93 required paths were present.
- Repository checks and the unsigned iOS Release build passed.
- Build output confirms the changed EXI adapter, host, controller and diagnostics
  were recompiled. The candidate preserves the prior private module/resources.

No production match was initiated by the agent. Ranked eligibility, server-side
availability, four-player Teams, Party and complete ranked-set reporting require
owner testing. Enabling a menu path does not establish those results or fix the
previous peer-disconnect incident. Private deployment/evidence stays outside Git.

## Deployment

Build 24 was signed with the existing identity and installed in place. Installed
app inspection confirms version 24; runtime logs confirm native Slippi readiness.
The signed package differs from build 23 only in executable, version metadata
and signing envelope. The module and private resources are unchanged. All ten
saved configuration files match, GC remains empty, and the two changed preference
values only relocate the same bundled game root/data to the new installation.
Live performance telemetry contains all 28 expected columns, including the three
new per-mode search counters. Mode gameplay acceptance remains pending.
