#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
LAUNCHER="$ROOT/ref/ModernGekko/tools/moderngekko_launcher.cpp"

for contract in \
  'ExportDiagnosticReport(' \
  'Latest-MeleePad-Diagnostic.log' \
  'MeleePad Diagnostic Report v1' \
  '<absolute-path>' \
  '--export-diagnostics' \
  'ImGui::Button("Export Diagnostics")'; do
  grep -Fq -- "$contract" "$LAUNCHER"
done

echo "macOS diagnostic export source checks passed"
