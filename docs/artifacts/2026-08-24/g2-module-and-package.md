# G2 module and package evidence

Status: **PASS**

## Module

- Bundle path: `Contents/MacOS/gGALE01_recomp.dylib`.
- Architecture: Mach-O 64-bit arm64.
- Size: 82,344,400 bytes after ad-hoc package signing.
- SHA-256:
  `bd5201080c20b1083370c4d7aa0929d4e14c323575729e45f09a393fe0ce12ef`.
- Deployment target: macOS 14.0.
- Runtime dependency: `/usr/lib/libSystem.B.dylib` only.
- Required export: `_staticrecomp_get_module` at `0x0000000000000d80`.
- Runtime load evidence: entry `0x8000522C`.

## App bundle

- `MeleePadFrontend`, `MeleePadRunner`, and the module are arm64.
- Bundle identifier: `com.meleepad.MeleePad.macos`.
- `codesign --verify --deep --strict` passes with ad-hoc signing.
- No `.iso`, `.dol`, `.wbfs`, or `.rvz` exists in the app bundle.
- The extracted retail game remains under Application Support and is ignored
  by the repository.

The optional ThinLTO probe failed in Apple's `ar` response-file path. The
non-LTO module passed the ABI/load checks above, so ThinLTO is not a G2 gate.
