# G1 DolRecomp SMC report — 2026-08-24

## Exact input and command

- Disc identity: `GALE01`, disc 0, revision 0
- Disc SHA-256: `2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484`
- Extracted `main.dol` SHA-256:
  `0f09e240e37586a996b2bcbc8904fb589cf2d7cfa79c916e33a7cf1c316a2448`
- DolRecomp:
  `93b881c8f73df1d64a88491f2aa50c7c9ed2384d`
- Command:
  `dolrecomp --gamecube --cpu gekko --backend c -j8 main.dol recomp-smc`
- Decode: text0 2,312 instructions; text1 966,288 instructions; zero
  unknown instructions; 237 generated chunks.

## Complete detector output

```text
possible patching instructions:
0x800034A0-0x800034A0
0x80005458-0x80005458
0x800D2AF4-0x800D2AF4
0x800D2B08-0x800D2B08
0x80123D50-0x80123D50
0x801465EC-0x801465EC
0x8015020C-0x8015020C
0x80150230-0x80150230
0x801B3B58-0x801B3B58
0x801B3B68-0x801B3B68
0x8021E1D0-0x8021E1D0
0x80300F48-0x80300F48
0x80300F54-0x80300F54
0x80300F60-0x80300F60
0x8032760C-0x8032760C
0x80337F7C-0x80337F7C
0x80337F84-0x80337F94
0x80337FD8-0x80337FD8
0x80341AEC-0x80341AEC
0x80341C38-0x80341C38
0x80342FC4-0x80342FC4
0x80348184-0x80348184
0x8034AF04-0x8034AF04
0x8034AFA4-0x8034AFA4
0x8034B024-0x8034B024
0x8034B038-0x8034B038
0x8034B048-0x8034B048
0x8034B060-0x8034B060
0x8034B078-0x8034B078
0x8034B088-0x8034B088
0x8034C2F0-0x8034C2F0
0x8034C30C-0x8034C30C
0x8034C330-0x8034C330
0x8034C354-0x8034C354
0x8034C378-0x8034C378
0x8034C3A0-0x8034C3A0
0x8034C3B0-0x8034C3B0
0x8034C3C0-0x8034C3C0
0x8034C3CC-0x8034C3CC
0x8034C3DC-0x8034C3DC
0x8034C3E8-0x8034C3E8
0x8034C3F0-0x8034C3F8
0x8034C410-0x8034C410
0x8034C428-0x8034C428
0x8034C434-0x8034C434
0x8034C440-0x8034C440
0x8034C44C-0x8034C44C
0x8034C458-0x8034C458
0x8034C464-0x8034C464
0x8034C480-0x8034C480
0x8034C4A4-0x8034C4A4
0x8034C4C8-0x8034C4C8
0x8034C4EC-0x8034C4EC
0x8034C514-0x8034C514
0x8034C524-0x8034C524
0x8034C534-0x8034C534
0x8034C540-0x8034C540
0x8034C550-0x8034C550
0x8034C55C-0x8034C55C
0x8034C564-0x8034C56C
0x8034C584-0x8034C584
0x8034C59C-0x8034C59C
0x8034C5A8-0x8034C5A8
0x8034C5B4-0x8034C5B4
0x8034C5C0-0x8034C5C0
0x8034C5CC-0x8034C5CC
0x8034C5DC-0x8034C5DC
0x8034C5EC-0x8034C5EC
0x8034C5F8-0x8034C5F8
0x8034C670-0x8034C670
0x8034C680-0x8034C680
0x8034C68C-0x8034C68C
0x8034C698-0x8034C698
0x8034C6A4-0x8034C6A4
0x8034C6B0-0x8034C6B0
0x8034C6C4-0x8034C6C4
0x8034C6D4-0x8034C6D4
0x8034C6E0-0x8034C6E0
0x8034C6EC-0x8034C6EC
0x8034C6F8-0x8034C6F8
0x8034C704-0x8034C704
0x8034C718-0x8034C718
0x8034C728-0x8034C728
0x8034C734-0x8034C734
0x8034C740-0x8034C740
0x8034C74C-0x8034C74C
0x8034C754-0x8034C754
0x8034C76C-0x8034C76C
0x8034C77C-0x8034C77C
0x8034C788-0x8034C788
0x8034C790-0x8034C798
0x8034C7B0-0x8034C7B0
0x8034C7C0-0x8034C7C8
0x8034C7D4-0x8034C7D4
0x8034C7DC-0x8034C7DC
0x8034C7F0-0x8034C7F0
0x8034C804-0x8034C804
0x8034C810-0x8034C810
0x8034C81C-0x8034C81C
0x8034C878-0x8034C878
0x8034C8D4-0x8034C8D4
0x8034C930-0x8034C930
0x8034C98C-0x8034C98C
0x8034C9A8-0x8034C9A8
0x8034C9C4-0x8034C9C4
0x8034D60C-0x8034D60C
0x8034D648-0x8034D648
0x8034D658-0x8034D658
0x8034D750-0x8034D750
0x803502D4-0x803502E8
0x803502F0-0x803502F0
0x80350300-0x80350300
0x803532A4-0x803532A4
0x803532C4-0x803532C4
0x803532E8-0x803532E8
0x8035330C-0x8035330C
0x80353330-0x80353330
0x80353354-0x80353354
0x80353378-0x80353378
0x8035339C-0x8035339C
0x803533C0-0x803533C0
0x803533F8-0x803533F8
0x80353428-0x80353428
0x8035C6E4-0x8035C6E4
0x80379518-0x80379518
0x80379524-0x80379524
0x80379530-0x80379530
0x80391F84-0x80391F84
```

The report contains 128 ranges covering 145 instructions: 4 `icbi`, 76
`stb`, 32 `stw`, 28 `sth`, and 5 `stfs`.

## Interpretation

DolRecomp's detector is intentionally conservative. In this pinned version,
`KnownReg regs[32]` is initialized once per executable section and then
updated during a linear instruction scan. It is not reset at branches,
returns, function entries, or unreachable regions. A later store through an
argument register can therefore inherit a constant value established in
unrelated earlier code and be reported as if it targeted executable memory.

That failure mode is directly visible in this DOL:

- The dense `0x8034C2F0`–`0x8034C9C4` cluster consists of ordinary
  byte/halfword writes through `r4` across many separate functions. The
  first inspected function begins after a `blr` with `li r3,0; sth r3,0(r4)`;
  no local instruction assigns `r4` an executable address.
- The `0x803502D4` range begins at a normal function prologue and writes a
  structure through incoming argument `r3`; no local code constant exists.
- Gameplay-region examples `0x800D2AF4` and `0x800D2B08` are floating-point
  result stores through function arguments, not hard-coded writes to text.
- Equivalent local-flow inspection was performed across every reported
  cluster. None contains a locally constructed executable destination plus a
  store.

The four `icbi` instructions are cache-maintenance operations:

- `0x800034A0`: instruction-cache invalidation inside the low-memory
  interrupt-vector body.
- `0x80005458`: the startup cache-flush loop (the v1.02 reference names this
  unchanged early routine `__flush_cache`).
- `0x8032760C`: a `dcbst; dcbf; sync; icbi` cache-maintenance loop.
- `0x80342FC4`: a 32-byte-stepped instruction-cache invalidation loop.

An `icbi` invalidates cached instructions but does not itself write or
generate code. The two later routines can support code loading in a generic
SDK/runtime, but the detector found no paired hard-coded write into executable
text.

## G1 patch list

**Empty.** No analysis-time replacement is justified by the supplied v1.00
DOL. Patching any of the flagged stores or cache primitives would change valid
game/SDK behavior based only on false-positive static state.

This does not disable runtime protection. ModernGekko's StaticRecomp SMC chunk
hash guard remains enabled. Any real runtime modification will demote the
affected chunk to fallback execution and produce runtime evidence; such
evidence reopens G1 and requires a targeted replacement or matching module
variant.
