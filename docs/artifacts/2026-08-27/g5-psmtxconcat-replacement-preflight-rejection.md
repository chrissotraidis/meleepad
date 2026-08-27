# G5 PSMTXConcat replacement preflight rejection

Date: 2026-08-27

## Question

The exact late-Fountain line sample attributes 144 CPU-thread samples to guest
`0x803408D4..0x8034099C`. The instruction sequence is byte-for-byte the SDK
`PSMTXConcat` routine even though the coarse GALE01 symbol map labels this
region incorrectly. Can DolRecomp's supported whole-function replacement path
remove its paired-single helper overhead?

## Exactness and local cost

A disposable replacement was enabled only for the exact revision-0 DOL SHA-256
`0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448`.
It fell back for unavailable FP/LSQE, nonzero GQR0, unsafe memory, stack
overlap, or non-normal edge values. It preserved the 51-cycle charge, output
write order, scratch-stack writes, clobbered GPR/FPR/paired-single state, LR
return, and aliased input/output behavior.

Twenty thousand randomized finite trials compared the current canonical dylib
with the disposable candidate. Full CPU state, the 48-byte output, and the
64-byte scratch-stack window matched exactly. Integrated per-call timings were:

| Run | Canonical | Replacement | Speedup |
|---:|---:|---:|---:|
| 1 | 202.043 ns | 61.399 ns | 3.291x |
| 2 | 173.252 ns | 53.108 ns | 3.262x |
| 3 | 169.421 ns | 52.508 ns | 3.227x |

The disposable module SHA-256 was
`9395ce8a43ba1aed41faa361050821fac4a9b4b2d84b5be0b70b8af7376dd267`.

## Global dispatch tax

DolRecomp's public replacement dispatcher is probed at every native dispatch.
Five million non-hit calls through the same canonical/candidate dylibs measured
2.404 ns and 2.041 ns extra per dispatch. At roughly 130,000 Fountain native
dispatches/frame, that costs about 0.27-0.31 ms/frame. Saving roughly 117 ns per
`PSMTXConcat` call requires more than 2,200 hits/frame merely to break even.
The 144/5,852 exact-window sample share bounds the plausible net gain to only a
few hundredths of a millisecond, far below the current G5 deficit.

## Decision

**REJECTED BEFORE LIVE RUN; G5 OPEN; G6 BLOCKED.** The function replacement is
locally correct and fast but the supported global probe consumes essentially
all plausible gain. The candidate CMake/source edits were removed; the active
module pointer and packaged app were never changed. Do not retry this public
replacement shape or add a common-path guest-PC shortcut. A future coherent
kernel must either save materially more work or use a general mechanism that
does not tax every dispatch.

The temporary source, binary, module, and build directory remain under
`/private/tmp` for the current session only and are not repository inputs.
