#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
OVERLAY_HEADER="$ROOT/apple/ios/MeleePadGameOverlay.h"
CONTROLLER="$ROOT/apple/ios/MeleePadGameViewController.mm"
LOBBY="$ROOT/apple/ios/MeleePadOnlinePlayViewController.mm"
LOBBY_HEADER="$ROOT/apple/ios/MeleePadOnlinePlayViewController.h"
PUBLIC_CLIENT="$ROOT/apple/ios/MeleePadPublicLobbyClient.m"
PUBLIC_CLIENT_HEADER="$ROOT/apple/ios/MeleePadPublicLobbyClient.h"
PROJECT="$ROOT/MeleePad.xcodeproj/project.pbxproj"
CORE="$ROOT/apple/ios/MeleePadCoreHost.mm"
CORE_HEADER="$ROOT/apple/ios/MeleePadCoreHost.h"
BUILD_CORE="$ROOT/scripts/ios-build-core.sh"
PROVISION="$ROOT/scripts/ios-provision.sh"
INFO="$ROOT/apple/ios/Info.plist"

for file in "$LOBBY" "$LOBBY_HEADER" "$PUBLIC_CLIENT" "$PUBLIC_CLIENT_HEADER"; do
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
  '@"Online Play"' \
  '@"Play Melee Together"' \
  '@"MELEE ONLINE  ·  2–4 PLAYERS"' \
  '@"How does Online Play work?"' \
  '@"Your player name"' \
  '@"Confirm Name"' \
  '@"Playing as %@"' \
  'Name changed. Confirm it to update your public name.' \
  'online-player-name-confirm' \
  'It stays on this device and out of diagnostics.' \
  '@"Host a public game"' \
  '@"Create Public Game"' \
  '@"Join Game"' \
  'refreshed now' \
  '@"Players: %@"' \
  '@"Public Games"' \
  '@"PUBLIC GAMES OFFLINE"' \
  '@"Public Games needs a secure lobby service"' \
  '@"The lobby will use HTTPS"' \
  '@"Gameplay is still peer to peer"' \
  '@"Why Public Games Is Off"' \
  'public-lobby-unavailable' \
  'public-lobby-availability-help' \
  '@"Room size"' \
  '@"Use Private Room"' \
  '@"Private Room"' \
  'eight-character room code' \
  '@"Direct IP"' \
  'address = address.lowercaseString' \
  'hexadecimal characters' \
  '@"Host"' \
  '@"Join"' \
  '@"Nickname"' \
  '@"Host IP or hostname"' \
  '@"UDP port (default 2626)"' \
  "Dolphin's public traversal service" \
  '@"Automatic input buffer"' \
  '@"Advanced settings"' \
  '@"Players"' \
  '@"Room chat"' \
  '@"Message the room"' \
  'room-chat-send' \
  '@"0 / 160"' \
  'Messages must be between 1 and 160 characters.' \
  'sendChatMessage:' \
  'setHeroCompact:' \
  'attributedPlaceholder' \
  '_heroWatermark' \
  'seatPalette.accessibilityElementsHidden = YES' \
  '@"Hide Player"' \
  '@"Report Chat Message"' \
  '@"Online Play FAQ"' \
  '@"Direct IP Setup"' \
  '@"Direct IP setup & troubleshooting"' \
  'online-connection-faq' \
  '@"Hide This Game"' \
  '@"Offensive Name"' \
  '@"Spam Listing"' \
  '@"Open seat"' \
  '@"YOU · HOST"' \
  '@"Build matches"' \
  'occupancyViewWithPlayers:' \
  '@"Ready"' \
  '@"Start Match"' \
  '@"Leave Session"' \
  '@"Return to Game"' \
  '@"Across Pad games"' \
  'Other games stay separate and cannot be joined from MeleePad.' \
  'ms to host' \
  '@"Cancel"'; do
  grep -Fq "$contract" "$LOBBY"
done

if rg -q 'sendQuickMessage|quickChatMenu|Choose a quick message' \
    "$LOBBY" "$PUBLIC_CLIENT" "$PUBLIC_CLIENT_HEADER"; then
  echo "Online Play still contains the removed quick-message UI" >&2
  exit 1
fi

grep -Fq 'UIModalPresentationFullScreen' "$CONTROLLER"
grep -Fq 'adjustsFontForContentSizeCategory = YES' "$LOBBY"
grep -Fq 'players.count >= _roomCapacity' "$LOBBY"
grep -Fq 'timerWithTimeInterval:10.0' "$LOBBY"
grep -Fq 'MeleePadOnlineNickname' "$LOBBY"
grep -Fq '[self refreshPublicGames:timer]' "$LOBBY"
grep -Fq '[self confirmedNickname]' "$LOBBY"
grep -Fq '[self isNicknameConfirmed]' "$LOBBY"
grep -Fq '_publicAvailableStack.hidden = !publicAvailable;' "$LOBBY"
grep -Fq '_publicUnavailableStack.hidden = publicAvailable;' "$LOBBY"
grep -Fq '_confirmNameButton.hidden = confirmed;' "$LOBBY"
grep -Fq 'if (!contentChanged)' "$LOBBY"
grep -Fq 'netplay automation room-code received length=%lu' "$CONTROLLER"
grep -Fq 'initWithPublicLobbyClient:_publicLobbyClient' "$CONTROLLER"
grep -Fq 'startPublicGameplayHeartbeat' "$CONTROLLER"
grep -Fq 'stopPublicGameplayHeartbeatReturningToLobby:YES' "$CONTROLLER"
grep -Fq '15 * NSEC_PER_SEC' "$CONTROLLER"
if grep -Fq 'netplay automation room code=%@' "$CONTROLLER"; then
  echo "Netplay automation logs a private room code" >&2
  exit 1
fi

if grep -Fq 'Room codes arrive in a later goal' "$LOBBY"; then
  echo "Online Play still exposes deferred-goal placeholder copy" >&2
  exit 1
fi

if grep -Fq 'Public games are not configured in this build. Private rooms and Direct IP are available now.' "$LOBBY"; then
  echo "Online Play still contains the unexplained Public Games dead end" >&2
  exit 1
fi

grep -Fq 'MeleePadOnlinePlayViewController.mm in Sources' "$PROJECT"
grep -Fq 'MeleePadOnlinePlayViewController.h' "$PROJECT"
grep -Fq 'MeleePadPublicLobbyClient.m in Sources' "$PROJECT"
grep -Fq 'MeleePadPublicLobbyClient.h' "$PROJECT"

for contract in \
  'moderngekko-netplay-8' \
  'MELEEPAD_LOBBY_BASE_URL' \
  'ephemeralSessionConfiguration' \
  'HTTPCookieAcceptPolicyNever' \
  'https' \
  '127.0.0.1' \
  '/v1/rooms' \
  '/v1/activity' \
  'MeleePadPublicLobbyProductID' \
  '@"product_id"' \
  'traversal_code'; do
  grep -Fq "$contract" "$PUBLIC_CLIENT"
done

grep -Fq 'HTTPResponse.statusCode == 401' "$PUBLIC_CLIENT"
grep -Fq 'MeleePadMaximumLobbyResponseBytes' "$PUBLIC_CLIENT"
for contract in \
  'MeleePadLobbyRoute' \
  'result=missing-session' \
  'duration_ms=%lu' \
  'request_bytes=%lu' \
  'response_bytes=%lu' \
  'isEqualToString:@"rooms_collection"' \
  'routinePoll'; do
  grep -Fq "$contract" "$PUBLIC_CLIENT"
done

if grep -Eq 'MeleePadLog\([^;]*(roomID|roomCode|traversalCode|nickname|_token|message\[@"text"\])' \
    "$LOBBY" "$PUBLIC_CLIENT"; then
  echo "Online Play diagnostics include a private value" >&2
  exit 1
fi

for contract in \
  'beginNetplayHostingWithNickname:' \
  'beginNetplayJoiningAddress:' \
  'usingTraversal:' \
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
grep -Fq '<key>MeleePadLobbyBaseURL</key>' "$INFO"
grep -Fq '$(MELEEPAD_LOBBY_BASE_URL)' "$INFO"
if grep -Fq 'native session bridge is not connected' "$CONTROLLER"; then
  echo "Online Play still exposes the disconnected bridge placeholder" >&2
  exit 1
fi
if grep -Fq 'There are no room codes or matchmaking servers yet' "$LOBBY"; then
  echo "Online Play still claims Internet rooms do not exist" >&2
  exit 1
fi

echo "iOS native Online Play lobby source contract passed"
