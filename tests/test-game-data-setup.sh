#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONTROLLER="$ROOT/apple/ios/MeleePadGameViewController.mm"
OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
APP_DELEGATE="$ROOT/apple/ios/MeleePadAppDelegate.mm"

python3 - "$CONTROLLER" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text()
start = source.index("- (void)startGameIfProvisioned")
end = source.index("- (void)showGameDataSetupState", start)
startup = source[start:end]
for text in (
    "fileExistsAtPath:gameRoot isDirectory:&gameRootIsDirectory",
    "isReadableFileAtPath:gameRoot",
    "if (!gameRootReadable)",
    "[self showGameDataSetupState]",
):
    if text not in startup:
        raise SystemExit(f"missing game-data setup guard: {text}")
if startup.index("if (!gameRootReadable)") > startup.index("_coreHost ="):
    raise SystemExit("game-data guard must run before runtime creation")
for text in ('importConfiguration.title = @"Choose ISO or GCM"',
             'initWithString:@"Game data required\\n"',
             '@"2393aadd346c23e3e44291e7bb7e16dbc4970bc703028261659a87cde9d90484"',
             '@"files/GmRegEnd.dat"',
             '@"files/MnSlChr.dat"',
             '@"files/MnSlMap.dat"',
             '@"files/PlFx.dat"',
             '@"files/GrNBa.dat"',
             '!= 1209'):
    if text not in source:
        raise SystemExit(f"missing first-run contract: {text}")
for stale in ('@"67cec1634e641227a4cd51e6a0b277730cb9a1adaa867530c9e66de45373e51d"',
              '@"files/AudioRes/mSound.asn"', '@"files/data/common.szs"', '!= 174'):
    if stale in source:
        raise SystemExit(f"Sunshine-only import invariant remains: {stale}")
for text in ('- (NSString *)meleePadSupportRoot',
             'contentsOfDirectoryAtPath:applicationSupportRoot',
             '@"GameData/GALE01.iso"',
             '@"GameData/GALE01/sys/main.dol"',
             'if ([candidate isEqualToString:currentRoot])',
             'moveItemAtPath:source',
             'if (candidates.count == 1)'):
    if text not in source:
        raise SystemExit(f"missing product-rename data migration: {text}")
if "sunPadSupportRoot" in source:
    raise SystemExit("stale support-root selector remains")
PY

grep -Fq 'Import or Reimport Game Data' "$OVERLAY"
grep -Fq 'MeleePadMigrateRenamedPreferences' "$APP_DELEGATE"
grep -Fq '@"ControllerButtonMappingV1"' "$APP_DELEGATE"
grep -Fq '[storedKey hasSuffix:suffix]' "$APP_DELEGATE"
grep -Fq 'if (candidates.count == 1)' "$APP_DELEGATE"
echo "Game-data setup checks passed"
