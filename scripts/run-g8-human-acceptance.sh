#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUNDLE_ID="com.ssbmpad.SsbmPad"

usage() {
  cat <<'EOF'
Usage: ./scripts/run-g8-human-acceptance.sh

Records the mandatory human-controlled G8 row-7 route without UI polling.
Exactly one Simulator must be booted unless G8_SIMULATOR_UDID selects it.
Set G8_EVIDENCE_DIR to retain evidence somewhere other than /private/tmp.

The operator must manually run this exact route:
  P1 Samus vs level-1 CPU Kirby, Stock/04, 05:00, Fountain of Dreams

Play for at least five uninterrupted combat minutes, reach results, return to
the menu, then press Return in this terminal. The script records the complete
screen, copies the same-session runtime log, hashes the immutable inputs and
evidence, and reports numeric thresholds. It never drives or inspects the UI.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ $# -ne 0 ]]; then
  usage >&2
  exit 2
fi
if [[ ! -t 0 ]]; then
  echo "human acceptance requires an interactive terminal" >&2
  exit 2
fi
if env | grep -Eq '^SIMCTL_CHILD_(SSBMPAD_|DYLD_)'; then
  echo "refusing forwarded SsbmPad or DYLD diagnostic environment" >&2
  exit 2
fi

if [[ -n "${G8_SIMULATOR_UDID:-}" ]]; then
  UDID="$G8_SIMULATOR_UDID"
  xcrun simctl list devices available | grep -Fq "$UDID) (Booted)" || {
    echo "selected Simulator is not booted: $UDID" >&2
    exit 2
  }
else
  booted="$({ xcrun simctl list devices available || true; } | sed -nE \
    's/.*\(([0-9A-Fa-f-]{36})\) \(Booted\).*/\1/p')"
  count="$(printf '%s\n' "$booted" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$count" -ne 1 ]]; then
    echo "expected exactly one booted Simulator, found $count" >&2
    exit 2
  fi
  UDID="$booted"
fi

APP_BUNDLE="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" app)"
APP_EXECUTABLE="$APP_BUNDLE/SsbmPad"
[[ -x "$APP_EXECUTABLE" ]] || {
  echo "installed Release executable is missing: $APP_EXECUTABLE" >&2
  exit 2
}

if [[ -n "${G8_EVIDENCE_DIR:-}" ]]; then
  EVIDENCE_DIR="$G8_EVIDENCE_DIR"
  mkdir -p "$EVIDENCE_DIR"
else
  EVIDENCE_DIR="$(mktemp -d /private/tmp/ssbmpad-g8-human-acceptance.XXXXXX)"
fi

VIDEO="$EVIDENCE_DIR/route.mov"
RECORDER_LOG="$EVIDENCE_DIR/recorder.log"
RUNTIME_COPY="$EVIDENCE_DIR/runtime.log"
PERFORMANCE_ROWS="$EVIDENCE_DIR/performance-rows.log"
SUMMARY="$EVIDENCE_DIR/summary.txt"
METADATA="$EVIDENCE_DIR/metadata.txt"
recorder_pid=""
app_launched=0

stop_recorder() {
  if [[ -n "$recorder_pid" ]] && kill -0 "$recorder_pid" 2>/dev/null; then
    kill -INT "$recorder_pid" 2>/dev/null || true
    wait "$recorder_pid" 2>/dev/null || true
  fi
  recorder_pid=""
}

cleanup() {
  stop_recorder
  if [[ "$app_launched" -eq 1 ]]; then
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    app_launched=0
  fi
}

abort() {
  trap - INT TERM
  cleanup
  exit 130
}

trap cleanup EXIT
trap abort INT TERM

xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl io "$UDID" recordVideo --codec=hevc --force "$VIDEO" \
  > /dev/null 2> "$RECORDER_LOG" &
recorder_pid=$!

for _ in {1..100}; do
  grep -Fq 'Recording started' "$RECORDER_LOG" && break
  if ! kill -0 "$recorder_pid" 2>/dev/null; then
    echo "Simulator recorder exited before capture began" >&2
    exit 1
  fi
  sleep 0.1
done
grep -Fq 'Recording started' "$RECORDER_LOG" || {
  echo "Simulator recorder did not start within ten seconds" >&2
  exit 1
}

START_EPOCH="$(date +%s)"
START_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
LAUNCH_RESULT="$(xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID")"
app_launched=1

echo
echo "Recording ordinary Release: $LAUNCH_RESULT"
echo "Evidence directory: $EVIDENCE_DIR"
echo
echo "Manually navigate through opening/menu/CSS and visibly confirm:"
echo "  P1 Samus vs level-1 CPU Kirby, Stock/04, 05:00, Fountain of Dreams"
echo "Play at least five uninterrupted combat minutes with music and SFX."
echo "Reach results and return to the menu before finishing."
echo
read -r -p "After the complete route, press Return here to finalize evidence: " _

END_EPOCH="$(date +%s)"
END_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
stop_recorder
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
app_launched=0

APP_DATA="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"
RUNTIME_SOURCE="$APP_DATA/Library/Application Support/SsbmPad/Logs/runtime.log"
[[ -s "$RUNTIME_SOURCE" ]] || {
  echo "same-session runtime log is missing: $RUNTIME_SOURCE" >&2
  exit 1
}
cp "$RUNTIME_SOURCE" "$RUNTIME_COPY"
grep ' performance fps=' "$RUNTIME_COPY" > "$PERFORMANCE_ROWS" || true

awk '
  / performance fps=/ {
    fps = vps = speed = underruns = callbacks = ""
    for (i = 1; i <= NF; ++i) {
      split($i, pair, "=")
      if (pair[1] == "fps") fps = pair[2] + 0
      else if (pair[1] == "vps") vps = pair[2] + 0
      else if (pair[1] == "speedRatio") speed = pair[2] + 0
      else if (pair[1] == "dmaUnderruns") underruns = pair[2] + 0
      else if (pair[1] == "callbacks") callbacks = pair[2] + 0
    }
    if (rows == 0 || fps < min_fps) min_fps = fps
    if (rows == 0 || vps < min_vps) min_vps = vps
    if (rows == 0 || speed < min_speed) min_speed = speed
    if (rows == 0) {
      first_underruns = underruns
      first_callbacks = callbacks
    }
    last_underruns = underruns
    last_callbacks = callbacks
    if (fps < 59.0) low_fps++
    if (vps < 59.0) low_vps++
    if (speed < 0.98) low_speed++
    rows++
  }
  END {
    printf "runtime_reports=%d\n", rows
    if (rows == 0) exit
    printf "min_fps=%.1f\n", min_fps
    printf "min_vps=%.1f\n", min_vps
    printf "min_speed_ratio=%.3f\n", min_speed
    printf "reports_below_59_fps=%d\n", low_fps + 0
    printf "reports_below_59_vps=%d\n", low_vps + 0
    printf "reports_below_0.98_speed=%d\n", low_speed + 0
    printf "dma_underruns=%d->%d\n", first_underruns, last_underruns
    printf "audio_callbacks=%d->%d\n", first_callbacks, last_callbacks
  }
' "$RUNTIME_COPY" > "$SUMMARY"

WALL_SECONDS="$((END_EPOCH - START_EPOCH))"
if [[ "$WALL_SECONDS" -ge 300 ]]; then
  echo "minimum_capture_duration_met=1" >> "$SUMMARY"
else
  echo "minimum_capture_duration_met=0" >> "$SUMMARY"
fi

{
  echo "git_commit=$(git -C "$ROOT" rev-parse HEAD)"
  echo "simulator_udid=$UDID"
  echo "bundle_id=$BUNDLE_ID"
  echo "installed_executable_sha256=$(shasum -a 256 "$APP_EXECUTABLE" | awk '{print $1}')"
  echo "start_utc=$START_UTC"
  echo "end_utc=$END_UTC"
  echo "wall_seconds=$WALL_SECONDS"
  echo "video_sha256=$(shasum -a 256 "$VIDEO" | awk '{print $1}')"
  echo "runtime_log_sha256=$(shasum -a 256 "$RUNTIME_COPY" | awk '{print $1}')"
} > "$METADATA"

trap - EXIT INT TERM
echo
echo "Capture complete. Numeric summary:"
cat "$SUMMARY"
echo
echo "Evidence retained at: $EVIDENCE_DIR"
if [[ "$WALL_SECONDS" -lt 300 ]]; then
  echo "INELIGIBLE: capture is shorter than five minutes."
fi
echo "Review the full video and phase-align every runtime row before a pass claim."
echo "This harness never declares row 7 passed automatically."
