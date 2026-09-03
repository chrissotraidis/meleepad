#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"
OVERLAY_HEADER="$ROOT/apple/ios/SsbmPadGameOverlay.h"
CONTROLLER="$ROOT/apple/ios/SsbmPadGameViewController.mm"
LOBBY="$ROOT/apple/ios/SsbmPadOnlinePlayViewController.mm"
LOBBY_HEADER="$ROOT/apple/ios/SsbmPadOnlinePlayViewController.h"
PROJECT="$ROOT/SsbmPad.xcodeproj/project.pbxproj"
CORE="$ROOT/apple/ios/SsbmPadCoreHost.mm"
CORE_HEADER="$ROOT/apple/ios/SsbmPadCoreHost.h"
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
  'actionWithTitle:@"Online Play…"' \
  'systemImageNamed:@"person.2.wave.2"'; do
  grep -Fq "$contract" "$OVERLAY" "$OVERLAY_HEADER"
done

for contract in \
  'SsbmPadOnlinePlayViewController' \
  'presentViewController:navigation' \
  'clearInputFromTouch:YES' \
  'clearInputFromTouch:NO' \
  '_coreHost = nil;' \
  'startGameIfProvisioned'; do
  grep -Fq "$contract" "$CONTROLLER"
done

for contract in \
  '@"Direct Connection Preview"' \
  '@"Advanced Direct Connection"' \
  'Room-code Online Play is not available in this build yet.' \
  '@"Host"' \
  '@"Join"' \
  '@"Nickname"' \
  '@"Host address"' \
  '@"UDP port"' \
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

grep -Fq 'SsbmPadOnlinePlayViewController.mm in Sources' "$PROJECT"
grep -Fq 'SsbmPadOnlinePlayViewController.h' "$PROJECT"

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
