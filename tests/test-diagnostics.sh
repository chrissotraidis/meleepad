#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
mkdir -p "$TEMP_DIR/home"

clang++ -x objective-c++ -std=gnu++2b -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/apple/shared/MeleePadDiagnostics.mm" \
  "$ROOT/tests/MeleePadDiagnosticsTests.mm" \
  -o "$TEMP_DIR/MeleePadDiagnosticsTests"
CFFIXED_USER_HOME="$TEMP_DIR/home" "$TEMP_DIR/MeleePadDiagnosticsTests"

OVERLAY="$ROOT/apple/ios/MeleePadGameOverlay.mm"
FORM="$ROOT/.github/ISSUE_TEMPLATE/bug_report.yml"
for field in report-id revision platform performance-profile summary context frequency; do
  grep -Fq "queryItemWithName:@\"$field\"" "$OVERLAY"
  grep -Fq "id: $field" "$FORM"
done
grep -Fq 'actionWithTitle:@"Report a Problem…"' "$OVERLAY"
grep -Fq 'actionWithTitle:@"Create Diagnostic & Continue…"' "$OVERLAY"
grep -Fq 'attach Latest-MeleePad-Diagnostic.log manually' "$OVERLAY"
grep -Fq 'MeleePad does not upload the log for you' "$OVERLAY"
grep -Fq 'offerGitHubForReportID:reportID answers:answers' "$OVERLAY"
if grep -Fq 'actionWithTitle:@"Export Diagnostic Log…"' "$OVERLAY" ||
   grep -Fq 'actionWithTitle:@"Report Issue on GitHub…"' "$OVERLAY"; then
  echo "Legacy split diagnostic actions remain in the iOS menu" >&2
  exit 1
fi
grep -Fq 'id: diagnostic-report' "$FORM"
grep -Fq 'id: visual-evidence' "$FORM"
grep -Fq 'accept: ".log,.txt"' "$FORM"
grep -Fq 'Create Diagnostic & Continue…' "$FORM"
grep -Fq 'then choose **Open GitHub**' "$FORM"
grep -Fq 'offlineUnlockAll=%d' "$ROOT/apple/ios/MeleePadGameViewController.mm"
echo "Diagnostic UI and issue-form contract passed"
