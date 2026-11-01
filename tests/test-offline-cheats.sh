#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HOST="$ROOT/apple/ios/MeleePadCoreHost.mm"
OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
SETTINGS="$ROOT/apple/shared/MeleePadSettings.mm"
APP_DELEGATE="$ROOT/apple/ios/MeleePadAppDelegate.mm"
GAME_INI="$ROOT/ref/ModernGekko/vendor/dolphin/Data/Sys/GameSettings/GALE01r0.ini"
GAME_INI_R2="$ROOT/ref/ModernGekko/vendor/dolphin/Data/Sys/GameSettings/GALE01r2.ini"

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
grep -Fq 'MeleePadUnlockAllCodeNameR0 = @"$All Characters and Stages"' "$HOST"
grep -Fq 'MeleePadUnlockAllCodeNameR2 = @"$Unlock All Characters and Stages"' "$HOST"
grep -Fq 'revision == 2 ? @"[Gecko_Enabled]" : @"[ActionReplay_Enabled]"' "$HOST"
grep -Fq 'revision == 2 ? @"GALE01r2.ini" : @"GALE01r0.ini"' "$HOST"
grep -Fq '_allowOfflineCheats->store(false' "$HOST"
grep -Fq 'MeleePadConfigureOfflineCheats(runtimeUserDirectory, NO' "$HOST"
grep -Fq 'Config::SetBase(Config::MAIN_ENABLE_CHEATS, false)' "$HOST"
grep -Fq 'Config::SetBase(Config::MAIN_ENABLE_CHEATS' "$HOST"

python3 - "$HOST" "$GAME_INI" "$GAME_INI_R2" <<'PY'
from pathlib import Path
import re
import sys

host = Path(sys.argv[1]).read_text()

# Each revision's selection must name its unlock code as Dolphin names the
# codes in that revision's bundled GameINI: an Action Replay code by its whole
# title, a Gecko code by its title before the author's bracket.
for constant, path, section_name, writes in (
    ('MeleePadUnlockAllCodeNameR0', sys.argv[2], '[ActionReplay]', ('04459F58 FFFFFFFF', '04459F60 FFFFFFFF')),
    ('MeleePadUnlockAllCodeNameR2', sys.argv[3], '[Gecko]', ('0445BF28 FFFFFFFF', '0445BF2C FFFFFFFF')),
):
    selection = re.search(constant + r' = @"([^"]*)"', host).group(1)
    text = Path(path).read_text()
    section = text.split('\n' + section_name + '\n', 1)[1].split('\n[', 1)[0]
    codes = {}
    for line in section.splitlines():
        line = line.strip()
        if line.startswith(('$', '+$')):
            title = line.lstrip('+')[1:]
            name = title.split('[', 1)[0].strip() if section_name == '[Gecko]' else title
            code = codes.setdefault(name, [])
        elif codes and line and not line.startswith(('*', '#')):
            code.append(line)
    selected = selection[1:]
    if selected not in codes:
        raise SystemExit(f'{Path(path).name} has no code Dolphin names {selected!r}')
    for write in writes:
        if write not in codes[selected]:
            raise SystemExit(f'missing bundled unlock write in {Path(path).name}: {write}')
PY

echo "Offline cheat menu, persistence warning, code selection, and netplay gate passed"
