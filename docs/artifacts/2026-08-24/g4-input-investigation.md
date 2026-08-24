# G4 input investigation

Status: **IN PROGRESS**

## Positive evidence

- Native Quartz previously moved the Character Select cursor and produced the
  retained G3 A-button transition.
- The runtime remains alive through multiple title/attract cycles and renders
  real multi-character battles.
- Cubeb initializes and the module shuts down with `smc_failed=0`.

Attract battles are excluded from playability evidence because they are title
screen demos, not user-controlled matches.

## Rejected automation interpretations

1. Mapping Start and A to one key reached menus but made CSS pickup ambiguous.
2. Mapping Start and X to one key still conflated two GameCube buttons.
3. A unique Quartz Start key plus explicit window focus and temporary external
   background-input sampling did not reliably reproduce a title/menu edge.
4. The reference FIFO backend was configured exactly as SunPad documents.
   `SsbmPadRunner` opened the expected FIFO read-only, the writer was connected
   both after boot and before boot and held open, and documented
   `PRESS START`/`RELEASE START` edges were sent. The emulated pad did not
   change.

All temporary Application Support settings were restored to the shipped
Quartz profile (`Start = Return`, background input false), and all SsbmPad
processes were stopped.

## Next falsifiable experiment

Instrument the already-vendored controller path at two points in one build:

- log each parsed FIFO command and resulting `PipeInput` state in
  `InputCommon/ControllerInterface/Pipes/Pipes.cpp`;
- log port-1 `GCPadStatus` immediately after `Pad::GetStatus(0)`.

Then launch one runner through the frontend, hold the FIFO writer open before
boot, send one Start edge, and retain the paired log plus visible screen. If
the parser changes but `GCPadStatus` does not, fix device-expression/config
binding. If `GCPadStatus` changes but Melee does not, inspect SI delivery. Do
not touch renderer, game logic, performance, or mobile targets until this edge
is visible and reproducible.
