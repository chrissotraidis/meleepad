#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HOST="$ROOT/apple/ios/MeleePadCoreHost.mm"
OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
SETTINGS="$ROOT/apple/shared/MeleePadSettings.mm"
APP_DELEGATE="$ROOT/apple/ios/MeleePadAppDelegate.mm"
GAME_INI="$ROOT/ref/ModernGekko/vendor/dolphin/Data/Sys/GameSettings/GALE01r0.ini"

for contract in \
  'Offline Cheats' \
  'Unlock All Characters & Stages' \
  'If Melee saves while the cheat is active, those unlocks may remain' \
  'Turning it off is not a rollback' \
  'Online Play always disables cheats'; do
  grep -Fq "$contract" "$OVERLAY"
done

grep -Fq 'boolForKey:@"MeleePadUnlockAllCharactersAndStages"' "$SETTINGS"
grep -Fq '@"UnlockAllCharactersAndStages"' "$APP_DELEGATE"
grep -Fq 'MeleePadUnlockAllCodeName = @"$All Characters and Stages"' "$HOST"
grep -Fq 'stringByAppendingPathComponent:@"GALE01r0.ini"' "$HOST"
grep -Fq '_allowOfflineCheats->store(false' "$HOST"
grep -Fq 'MeleePadConfigureOfflineCheats(runtimeUserDirectory, NO' "$HOST"
grep -Fq 'Config::SetBase(Config::MAIN_ENABLE_CHEATS, false)' "$HOST"
grep -Fq 'Config::SetBase(Config::MAIN_ENABLE_CHEATS' "$HOST"

python3 - "$GAME_INI" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
section = text.split('[ActionReplay]', 1)[1].split('\n[', 1)[0]
required = (
    '$All Characters and Stages',
    '04459F58 FFFFFFFF',
    '04459F60 FFFFFFFF',
)
for line in required:
    if line not in section:
        raise SystemExit(f'missing bundled unlock contract: {line}')
PY

echo "Offline cheat menu, persistence warning, code selection, and netplay gate passed"
