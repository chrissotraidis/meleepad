#!/usr/bin/env bash
# Merge one or more private raw training profiles into profile data accepted by
# package-local-pgo-app.sh. No profile contents enter Git.
set -euo pipefail

RAW_DIR=${1:-}
OUTPUT=${2:-}
if [[ -z "$RAW_DIR" || -z "$OUTPUT" || ! -d "$RAW_DIR" ]]; then
  echo "usage: $0 private-raw-profile-dir output.profdata" >&2
  exit 2
fi

raw_profiles=()
while IFS= read -r -d '' profile; do
  raw_profiles+=("$profile")
done < <(find "$RAW_DIR" -type f -name '*.profraw' -print0)
if [[ ${#raw_profiles[@]} -eq 0 ]]; then
  echo "no raw LLVM profiles found under $RAW_DIR" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUTPUT")"
xcrun llvm-profdata merge -o "$OUTPUT" "${raw_profiles[@]}"
if ! xcrun llvm-profdata show --all-functions --counts "$OUTPUT" |
     awk '/staticrecomp_profile_dump:/ { found = 1 } END { exit !found }'; then
  echo "merged profile does not contain the combat-only dump hook" >&2
  exit 1
fi
xcrun llvm-profdata show "$OUTPUT"
echo "Merged profile SHA-256: $(shasum -a 256 "$OUTPUT" | awk '{print $1}')"
