#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONTROLLER="$ROOT/apple/ios/SsbmPadGameViewController.mm"
OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"

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
             'initWithString:@"Game data required\\n"'):
    if text not in source:
        raise SystemExit(f"missing first-run contract: {text}")
PY

grep -Fq 'Import or Reimport Game Data' "$OVERLAY"
echo "Game-data setup checks passed"
