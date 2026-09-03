#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

clang++ -std=c++23 "$ROOT/tests/SsbmPadControllerSlotsTests.cpp" \
  -o "$TEMP_DIR/SsbmPadControllerSlotsTests"
"$TEMP_DIR/SsbmPadControllerSlotsTests"

clang++ -x objective-c++ -std=gnu++2b -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/apple/shared/SsbmPadInputMixer.mm" \
  "$ROOT/tests/SsbmPadControllerDisconnectTests.mm" \
  -o "$TEMP_DIR/SsbmPadControllerDisconnectTests"
"$TEMP_DIR/SsbmPadControllerDisconnectTests"

CONTROLLER="$ROOT/apple/ios/SsbmPadGameViewController.mm"
for contract in \
  'GCController.controllers' \
  'startWirelessControllerDiscoveryWithCompletionHandler' \
  'controller discovery started reason=launch' \
  'reconcileControllersForReason:@"discovery-complete"' \
  'indexOfObjectIdenticalTo:controller' \
  'reconcileControllersForReason:@"foreground"' \
  'reconcileControllersForReason:@"periodic"' \
  'controller.playerIndex = SsbmPadPlayerIndexForSlot(slot);' \
  'clearInputFromTouch:NO' \
  '[_overlay refreshControllerVisibility]'; do
  grep -Fq "$contract" "$CONTROLLER"
done

OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"
visibility_block="$(sed -n '/^- (void)applyControllerVisibility {/,/^- (void)refreshControllerVisibility {/p' "$OVERLAY")"
if grep -Fq '#if !TARGET_OS_SIMULATOR' <<<"$visibility_block"; then
  echo "Simulator controllers must participate in touch-overlay visibility" >&2
  exit 1
fi
for contract in \
  'for (GCController *controller in GCController.controllers)' \
  '[SsbmPadSettings sharedSettings].hideTouchControlsWhenControllerConnected' \
  '[self clearTouchInput]'; do
  grep -Fq "$contract" <<<"$visibility_block"
done
echo "Controller reconciliation source checks passed"
