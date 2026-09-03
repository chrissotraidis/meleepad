#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
OVERLAY_HEADER="$ROOT/apple/ios/MeleePadGameOverlay.h"
CONTROLLER="$ROOT/apple/ios/MeleePadGameViewController.mm"
LOBBY="$ROOT/apple/ios/MeleePadOnlinePlayViewController.mm"
LOBBY_HEADER="$ROOT/apple/ios/MeleePadOnlinePlayViewController.h"
PROJECT="$ROOT/MeleePad.xcodeproj/project.pbxproj"
CORE="$ROOT/apple/ios/MeleePadCoreHost.mm"
CORE_HEADER="$ROOT/apple/ios/MeleePadCoreHost.h"
BUILD_CORE="$ROOT/scripts/ios-build-core.sh"
PROVISION="$ROOT/scripts/ios-provision.sh"
INFO="$ROOT/apple/ios/Info.plist"

for file in "$LOBBY" "$LOBBY_HEADER"; do
  [[ -f "$file" ]] || {
    echo "native Online Play lobby is missing: $file" >&2
    exit 1
  }
done

for contract in \
  'gameOverlayRequestsOnlinePlay:' \
  'actionWithTitle:@"Experimental Multiplayer…"' \
  'systemImageNamed:@"person.2.wave.2"'; do
  grep -Fq "$contract" "$OVERLAY" "$OVERLAY_HEADER"
done

for contract in \
  'MeleePadOnlinePlayViewController' \
  'presentViewController:navigation' \
  'clearInputFromTouch:YES' \
  'clearInputFromTouch:NO' \
  '_coreHost = nil;' \
  'startGameIfProvisioned'; do
  grep -Fq "$contract" "$CONTROLLER"
done

for contract in \
  '@"Experimental Multiplayer"' \
  '@"Direct Peer Connection"' \
  'Each device runs the same Melee match locally and exchanges controller input' \
  'There are no room codes or matchmaking servers yet' \
  'complete matches are not yet reliable.' \
  '@"Host"' \
  '@"Join"' \
  '@"Nickname"' \
  '@"Host IP or hostname"' \
  '@"UDP port (default 2626)"' \
  "2626 is Dolphin's standard direct-NetPlay UDP port, not a server address." \
  '@"Automatic input buffer"' \
  '@"Players"' \
  'Compatibility: %@' \
  '@"Ready"' \
  '@"Start Match"' \
  '@"Cancel"'; do
  grep -Fq "$contract" "$LOBBY"
done

if grep -Fq 'Room codes arrive in a later goal' "$LOBBY"; then
  echo "Online Play still exposes deferred-goal placeholder copy" >&2
  exit 1
fi

grep -Fq 'MeleePadOnlinePlayViewController.mm in Sources' "$PROJECT"
grep -Fq 'MeleePadOnlinePlayViewController.h' "$PROJECT"

for contract in \
  'beginNetplayHostingWithNickname:' \
  'beginNetplayJoiningAddress:' \
  'pollNetplayWithCompletion:' \
  'setNetplayReady:' \
  'requestNetplayStart' \
  'endNetplayWithCompletion:' \
  'NetplaySession::Create' \
  'SetBootSessionData' \
  'AttachRuntime' \
  'FinishRuntime' \
  'onNetplayMatchEnded' \
  'Netplay selects and fingerprints sys/main.dol' \
  'discImagePath:@""' \
  'Options/Always Connected = True'; do
  grep -Fq "$contract" "$CORE" "$CORE_HEADER"
done

grep -Fq 'libmoderngekko_netplay_session.a' "$BUILD_CORE" "$PROVISION"
grep -Fq 'MODERNGEKKO_GAMECUBE_CONTROLLERS=ON' "$BUILD_CORE"
grep -Fq '<key>NSLocalNetworkUsageDescription</key>' "$INFO"
if grep -Fq 'native session bridge is not connected' "$CONTROLLER"; then
  echo "Online Play still exposes the disconnected bridge placeholder" >&2
  exit 1
fi

echo "iOS native Online Play lobby source contract passed"
