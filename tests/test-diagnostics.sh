#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
mkdir -p "$TEMP_DIR/home"

clang++ -x objective-c++ -std=gnu++2b -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/apple/shared/SsbmPadDiagnostics.mm" \
  "$ROOT/tests/SsbmPadDiagnosticsTests.mm" \
  -o "$TEMP_DIR/SsbmPadDiagnosticsTests"
CFFIXED_USER_HOME="$TEMP_DIR/home" "$TEMP_DIR/SsbmPadDiagnosticsTests"

OVERLAY="$ROOT/apple/ios/SsbmPadGameOverlay.mm"
FORM="$ROOT/.github/ISSUE_TEMPLATE/bug_report.yml"
for field in report-id revision platform performance-profile summary context frequency; do
  grep -Fq "queryItemWithName:@\"$field\"" "$OVERLAY"
  grep -Fq "id: $field" "$FORM"
done
grep -Fq 'actionWithTitle:@"Report a Problem…"' "$OVERLAY"
grep -Fq 'id: diagnostic-report' "$FORM"
grep -Fq 'id: visual-evidence' "$FORM"
grep -Fq 'accept: ".log,.txt"' "$FORM"
echo "Diagnostic UI and issue-form contract passed"
