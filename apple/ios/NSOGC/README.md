# NSOGC

Vendored copy of NSOGCKit from
[pookee/nso-gamecube-ios](https://github.com/pookee/nso-gamecube-ios)
(`Sources/NSOGCKit`, with `include/` flattened) at commit `fe4a2e4`: the Nintendo Switch Online
GameCube controller made for the Switch 2 over Bluetooth LE. iOS has no driver
for it, so the app connects it itself through CoreBluetooth.

`MeleePadNSOGCBridge` makes up to four of them players 1 to 4. Update these
files from that repository rather than editing them here.

NSOGCKit is under the MIT license in [LICENSE](LICENSE); the same text is in
[THIRD-PARTY-NOTICES.md](../../../THIRD-PARTY-NOTICES.md), which the app bundles.
