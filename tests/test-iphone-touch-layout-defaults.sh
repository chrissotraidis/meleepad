#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
for contract in \
  'UIUserInterfaceIdiomPhone' \
  '0.1234722222, 0.7803490991' \
  '0.9233055556, 0.8130067568' \
  '0.0812777778, 0.4677364865' \
  '1.158457040786743' \
  'savedScales[identifier] != nil' \
  'MeleePadGameButton *button = [MeleePadGameButton buttonWithType:UIButtonTypeSystem]' \
  'CGRectGetMaxX(safe) - margin - shoulderWidth, shoulderY' \
  'CGRectGetMaxX(safe) - margin - large' \
  '0.1310395315, 0.7905894519' \
  '0.2686676428, 0.7947259566'; do
  grep -Fq "$contract" "$OVERLAY"
done
if grep -Fq 'rightShoulderWidth' "$OVERLAY"; then
  echo "R must use the same compact shoulder width as L" >&2
  exit 1
fi
echo "iPhone touch-layout default checks passed"
