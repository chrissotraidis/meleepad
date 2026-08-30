# G5 external-display user acceptance

Date: 2026-08-30

Status: **provisionally accepted for loop progression by explicit user direction**

The current machine has no external 59.94 Hz or suitable variable-refresh
display. The retained G5 investigation attributes the remaining strict display
tail to the built-in fixed 60.00 Hz panel presenting Melee's distinct
59.94005994 Hz source cadence; warm game-side CPU and audio work were already
bounded separately.

The user directed the loop to assume the unavailable external-display check
passes and to proceed, with the check repeated later when the iPadOS/iOS
version is ready for broader hardware validation. This closes the test as a
**user-accepted assumption**, not as an empirical external-display result.

Consequences:

- G5 and G8 row 3 no longer block the active loop.
- Existing timing artifacts remain authoritative; they are not relabeled as a
  measurement from hardware that was not present.
- Final device validation must repeat the 8-minute Final Destination test on a
  59.94 Hz or suitable VRR display and retain audio-inclusive frame timing.
- A failed later hardware run reopens G5 and G8 row 3.
