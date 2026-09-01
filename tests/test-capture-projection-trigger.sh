#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup() {
  if [[ -n "${target_pid:-}" ]]; then
    kill "$target_pid" 2>/dev/null || true
    wait "$target_pid" 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

mkdir -p "$TMP/bin" "$TMP/out"
cat > "$TMP/bin/xcrun" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1 $2 $3 $4" == "simctl io TEST-UDID screenshot" ]]
: > "$5"
SH
chmod +x "$TMP/bin/xcrun"

signal_marker="$TMP/signal.received"
SIGNAL_MARKER="$signal_marker" bash -c \
  'trap '\''touch "$SIGNAL_MARKER"'\'' USR1; while :; do sleep 0.1; done' &
target_pid=$!

cat > "$TMP/runtime.log" <<'LOG'
performance fps=20.0 projectionHash=002a81fb84e3f680 draws=999
performance fps=59.9 projectionHash=4be288c01ed3ebd5 draws=2
performance fps=27.5 projectionHash=002a81fb84e3f68f draws=900
LOG

PATH="$TMP/bin:$PATH" python3 "$ROOT/scripts/capture-projection-trigger.py" \
  --runtime-log "$TMP/runtime.log" \
  --projection-hash 002A81FB84E3F68F \
  --pid "$target_pid" \
  --simulator-udid TEST-UDID \
  --output-dir "$TMP/out" \
  --timeout-seconds 2 \
  --from-start >/dev/null

for _ in {1..20}; do
  [[ -f "$signal_marker" ]] && break
  sleep 0.05
done
[[ -f "$signal_marker" ]]
[[ -f "$TMP/out/trigger.png" ]]
python3 - "$TMP/out/trigger.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    capture = json.load(stream)
assert capture["projectionHash"] == "002a81fb84e3f68f"
assert "fps=27.5" in capture["runtimeRow"]
assert "002a81fb84e3f680" not in capture["runtimeRow"]
assert capture["savestateUpdated"] is None
PY

echo "projection-hash trigger checks passed"
