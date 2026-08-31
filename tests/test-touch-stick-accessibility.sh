#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"

grep -Fq 'configureAccessibilityWithLabel:@"Move stick"' "$OVERLAY"
grep -Fq 'configureAccessibilityWithLabel:@"C stick"' "$OVERLAY"
grep -Fq 'UIAccessibilityTraitAllowsDirectInteraction' "$OVERLAY"

for direction in Up Down Left Right; do
  grep -Fq "accessibilityMove${direction}:" "$OVERLAY"
done

grep -Fq 'self.valueChanged(x, y);' "$OVERLAY"
grep -Fq '[weakSelf reset];' "$OVERLAY"
grep -Fq -- '- (BOOL)accessibilityActivate' "$OVERLAY"
grep -Fq 'accessibilityPressHandler' "$OVERLAY"
grep -Fq '[strongSelf buttonDown:pressedButton];' "$OVERLAY"
grep -Fq '[weakSelf buttonUp:pressedButton];' "$OVERLAY"
grep -Fq 'initWithName:@"Press"' "$OVERLAY"
grep -Fq 'accessibilityPress:' "$OVERLAY"

echo "Touch-stick accessibility checks passed"
