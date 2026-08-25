# G5 required-stage PGO and input-route recovery

Date: 2026-08-25

## Controller-path result

Temporary, default-off traces in the vendored Pipe, GCPad, and SI paths proved
one complete input edge. The active device was `Pipe/0/ssbmpad`; the A binding
resolved exactly one control; the same `PipeInput` address received `PRESS A`
and returned `1.0`; `GCPadStatus` produced `0x0100`; and SI observed the same
button value. No controller implementation change was required.

The earlier apparent failure was a startup/focus timing artifact. Once the
native window's input gate opened, the checked-in FIFO driver navigated the
real title and menus. A ROM-safe isolated user directory then provided two
independent FIFO devices and an already persisted unlocked GCI. This produced:

- a visible Peach-versus-Ice-Climbers Fountain of Dreams 1v1 at 60.1 FPS;
- a visible Bowser-versus-Donkey-Kong Final Destination 1v1;
- movement, jumps, normals, specials, match completion, and rematch coverage.

The temporary trace hooks, second port, unlocked save, instrumented module,
and profile data remain outside the repository. The normal save was not
modified. `g4-title-to-menu.json` now waits for the post-title transition, and
`g4-menu-to-css.json` uses one discrete D-pad edge instead of a timing-sensitive
held analog direction.

## Final Destination profile

The portable instrumentation module generated a new 44,671,152-byte raw
profile from the controlled Final Destination workload:

`a2be063d405f653c7f551864c2e8bc410e40535acab2312aadec2c1187db6a12`

It was merged 1x with the original Fountain raw profile weighted 2x. The
resulting profile contains 6,531 functions and 2,733,180 blocks and has SHA-256
`443d7088655583535f95a588b0ab4a49a76237d8f77503deb629890f4f9daf2b`.
Both inputs remain local because they were trained from the retail-image run.

The macOS 14 O2 + strict-FP + ThinLTO candidate built successfully. Its
unsigned module SHA-256 is
`ffdc2cabca5b1f41ded3e27b87165055abefb6626c13ee1947cf2109f851ccf1`.

## Matched attract screen

The candidate and retained Fountain-only PGO module were run with the same
native runner, isolated user directory, Metal backend, resolution, audio
backend, and two connected FIFO ports. No capture or UI action occurred inside
the measured interval. The first 500 frames were excluded; the next 1,000
frames form the matched steady-state screen before the attract sequence
diverged into different scenes.

| Metric | Fountain 2 + FD 1 | Fountain-only PGO | Decision |
|---|---:|---:|---|
| Mean | 16.684285 ms | 16.682977 ms | candidate worse |
| Median | 16.778146 ms | 16.684126 ms | candidate worse |
| p95 | 18.383000 ms | 18.076584 ms | candidate worse |
| p99 | 18.774417 ms | 18.720125 ms | candidate worse |
| Worst | 57.090500 ms | 19.088334 ms | candidate worse |
| Frames <= 16.7 ms | 46.60% | 50.80% | candidate worse |
| Frames > 40 ms | 1 | 0 | candidate worse |

Raw evidence:

- `g5-fountain2-fd1-candidate-attract-render-times.txt` — SHA-256
  `aecc77f75eb2774818eaee88616ab7ebb1964cc5b115b0d77ceb5580e1594fc3`
- `g5-fountain2-fd1-candidate-attract-vblank-times.txt` — SHA-256
  `32ae9402dc6e901bc837d1c2e421ea6765d9b192fc113ef424e1ff7fea7425bb`
- `g5-fountain-pgo-matched-attract-render-times.txt` — SHA-256
  `0b360ed586e3d13dcb8c76d2c3920cc596f9a35806e60783165083cff4a92470`
- `g5-fountain-pgo-matched-attract-vblank-times.txt` — SHA-256
  `b07f781b61b8ec2ee264dd1c47374862ecadf011fbb96a8f6970bd8c83f4f75e`

## Decision

The required-stage-balanced PGO candidate is **not retained**. Direct Final
Destination coverage diluted the Fountain profile enough to regress every
matched steady-state metric and introduce a frame above 40 ms. An expensive
Fountain/Final Destination replay is therefore not justified.

The signed package is restored to production runner SHA-256
`d2642b463a41e0a94a3cc2869b836ed3ab5cb7777eb0ea9d9f0240c7c760cff6`
and retained Fountain-PGO module SHA-256
`a961abecb1f14fe3da2c7fd101713f191f9d9d7b6225ce850bffacf4d718577b`.
No game process or Simulator remains active. G5 stays open.
