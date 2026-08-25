#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

git diff --check
for script in scripts/*.sh; do
  bash -n "$script"
done

prohibited=$(git ls-files | grep -E \
  '(^|/)(ref|DerivedData|Provisioned|build[^/]*)/|\.(iso|gcm|rvz|wia|wbfs|gcz|dylib|ipa|xcarchive|mobileprovision|p12|pem|key|gci|sav|raw|profraw|profdata)$' || true)
if [[ -n "$prohibited" ]]; then
  echo "prohibited tracked material:" >&2
  echo "$prohibited" >&2
  exit 1
fi

if git grep -n -I -E \
  'BEGIN [A-Z ]*PRIVATE KEY|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}' -- .; then
  echo "possible credential material found" >&2
  exit 1
fi

echo "Repository checks passed"
