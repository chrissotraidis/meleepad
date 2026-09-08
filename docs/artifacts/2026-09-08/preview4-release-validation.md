# Preview 4 / build 18 validation

The release adds lightweight frame-interval summaries to the merged build-17
changes. The public artifact remains the unsigned, module-free app shell.
Playable physical builds retain the established private bundle identity so
installation upgrades the existing app instead of creating an empty new app.

- All repository checks pass, including interval percentiles, slow-frame
  thresholds, invalid input, accumulator reset, and concurrent snapshot tests.
- Core and iOS Release builds pass. Dependency bootstrap is idempotent; the
  frame-summary patch passes apply/check/recount and reproduces the built files.
- The signed local build passes strict deep codesign verification. Both original
  game-module hashes match build 17.
- Physical iPhone and iPad received build 18 in place. Before first launch,
  24 iPhone and 23 iPad preserved save/configuration/extracted-executable files
  match their backups byte-for-byte. ISO size and timestamps are unchanged on
  each device. No ISO, save, or setting was replaced or reset.
- Fresh runtime logs on both devices identify build 18 and verified v1.02, reach
  running frames, and include frameIntervals, frameAvgMs, frameP95UpperMs,
  frameMaxMs, slow-frame counts and audioUnderrunsDelta. Per-dispatch capture
  and benchmark routing are off. The existing iPhone 1x and iPad 2x settings
  remain selected. This is launch/logging evidence, not new heavy-match or
  physical Internet-netplay acceptance.
- Two independent public packages are byte-identical and pass the existing
  module/game-data/signing/private-path exclusions. Public IPA SHA-256:
  `a69a0466e0bb3e50a40b31dcb5754e0a5d6e130d00f78e2c81e0fcdcaefeebb0`.

Private installation, preservation, build and runtime receipts remain under
`ref/revision-102/preview4/`. Full-match slowdowns remain documented separately
in the build-17 owner-run report; no sustained-60-FPS claim follows from this
release.
