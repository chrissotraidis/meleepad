# G8 iOS host-core ThinLTO rejection

Date: 2026-08-30

Status: **rejected before live replay by the structural gate**

## Question

Can ThinLTO across the iOS host compatibility core remove enough of the
residual `StaticRecompCore::Run` helper overhead to justify another sustained
combat reversal?

This is distinct from the already-retained ThinLTO game-module work. The
fresh exact-source iOS PGO residual sample still assigns 220 top-of-stack
samples to `FastDispatchableAt`, 118 to `SyncIn`, and additional work to
state/hook helpers. The shipped iOS host core was compiled at O3 without LTO,
and the linked app contained explicit calls from `Run` to those helpers.

## Bounded build

An isolated `/tmp` CMake build used the exact canonical iOS Simulator
toolchain and release configuration plus
`CMAKE_INTERPROCEDURAL_OPTIMIZATION=ON`. The compiler command for
`StaticRecompCore_Run.cpp` contained `-flto=thin`, and its object was LLVM
bitcode. Only the resulting `libcore.a` replaced the control core archive in a
disposable app link; all other archives and tracked sources remained
unchanged. The app link also used `-flto=thin`.

- candidate core archive: 17,948,184 bytes
- candidate core SHA-256:
  `224552b55c32451df4c54e06362c7e27f74fa60aa2b7505de1ecf4ea66913030`
- candidate app binary SHA-256:
  `a6ca5baf94c0c19abc075b258f010a3dbd5fcfc771fef7f20301588441a6203d`
- control app binary: 17,889,992 bytes
- candidate app binary: 17,984,216 bytes

The generated linker response was restored byte-for-byte immediately after
the disposable build.

## Structural result

ThinLTO did not eliminate the three target boundaries. The candidate
`StaticRecompCore::Run` still contains direct calls to
`FastDispatchableAt`, `SyncIn`, and `SyncOut`. It also retains calls to
`DispatchableAt` and `ResolveNativeAddress`.

ThinLTO instead internalized and expanded other logic. The linked `Run`
function grew from 2,768 bytes / 692 instructions to 5,308 bytes / 1,327
instructions. Its direct-call count also rose from 59 to 61. The whole app
binary grew by 94,224 bytes.

## Decision

Reject host-core ThinLTO before Simulator launch. The exact measured
mechanism did not occur, the hot boundaries remain, and the doubled hot-loop
body creates an instruction-cache risk. A live result from this shape would
not justify the time or private-game replay needed for a matched combat
reversal.

Do not add host-core ThinLTO to the product or repeat it as a performance
candidate. Row 7 remains fail/attributed. The next static-core experiment must
change a measured hot path that this link demonstrably left intact and must
clear a structural/materiality gate before live play.

No Simulator was booted, no game process ran, and no ROM, module, profile,
save, or tracked source was changed by this experiment.
