# macOS default keyboard controls

Date: 2026-08-30

Status: **retained product correction; physical-key live check pending**

## Failure

The app already shipped a Quartz keyboard profile, but a prior automation run
left both of the real persistent input selectors on the internal
`Pipe/0/ssbmpad` transport:

- `Config/GCPadNew.ini` selected the pipe device;
- `config.ini` selected the same pipe device as controller 1.

The macOS wrapper deliberately preserved all existing profiles, so launching
the app never installed its WASD profile. The result was a normal-looking game
window with no usable keyboard input.

## Correction

The macOS wrapper now recognizes only SsbmPad's exact internal pipe device and
migrates both persistent selectors to the shipped Quartz profile. Arbitrary
custom keyboard and SDL controller profiles remain byte-for-byte unchanged.
The default profile maps:

- WASD: move;
- J/K: attack/confirm and special/back;
- Space or U, plus I: X/Y jump buttons;
- arrow keys: C-stick;
- Q/E: L/R shield;
- O: Z/grab;
- Return: Start/pause.

## Verification

- The focused functional regression creates a synthetic app bundle and proves
  first-install behavior, exact pipe-profile migration in both files, and
  preservation of a custom SDL profile.
- The package-layout gate requires the WASD and Space bindings in the packaged
  resource and the pipe-migration logic in the executable wrapper.
- The full `./scripts/check-repository.sh` suite passes.
- The actual user files and packaged default profile are byte-identical with
  SHA-256
  `9ee3ae05c8d56919c9bcc929cea61f4b2ee276729a0ada318901812ed21c7eb9`.
- The rebuilt launcher visibly reports `Quartz/0/Keyboard & Mouse` in
  `docs/evidence/g8/macos-keyboard-profile-active.jpg`.
- The packaged runner started and shut down normally with zero static fallback
  and zero SMC failure.

Computer Use key taps are not a valid live-input validator for this path. A
separate read-only probe sampled the same
`CGEventSourceKeyState(kCGEventSourceStateCombinedSessionState, ...)` API used
by Dolphin's Quartz backend at 1 kHz; synthetic Return/W/Space taps produced no
held-key state. A physical keyboard press is therefore still required for the
final in-game confirmation. This limitation is recorded rather than turning a
configuration proof into a gameplay claim.

No game image, generated module, save, or controller capture is committed.
