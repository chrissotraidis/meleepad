# G0 environment evidence — 2026-08-24

## Host

- Architecture: `arm64`
- Xcode: 26.6, build 17F113
- CMake: 4.4.0
- Ninja: 1.13.2
- pkg-config: 2.5.1
- Git: 2.36.1
- Python: 3.14.6
- ripgrep: 15.1.0
- Booted Simulators at audit: none
- Matching stale runtime/game processes at audit: none

## Retail input

- Local path: `ref/Super Smash Brothers Melee.iso` (ignored; never publish)
- Size: 1,459,978,240 bytes
- Header: `47414c45303100000000000000000000`
- Game ID: `GALE01`
- Disc number: 0
- Revision byte: 0
- SHA-1: `5ab1553a941307bb949020fd582b68aabebecb30`
- SHA-256: `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`

The PRD expected NTSC-U v1.02 SHA-1
`08e0bf20134dfcb260699671004527b2d6bb1a45`. The image on this machine is a
different revision. PRD Section 5.1 explicitly directs recording the actual
input and proceeding; every generated artifact must remain bound to the actual
SHA-256 above.

## Read-only reference

- `ref/sunpad` HEAD: `e43f0ea6b797e5110787171957c9dc3c6213269c`
- Working tree: clean
- Required architecture, build, dependency, testing, performance, platform,
  issue, debt, handoff, audio, legal, scripts, patches, Apple shell, and test
  paths were inventoried before implementation.
