#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 PID MARKER PHASE_CSV OUTPUT_PREFIX" >&2
  exit 2
fi

pid="$1"
marker="$2"
phase_csv="$3"
output_prefix="$4"

while [[ ! -s "$marker" ]]; do
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "process $pid exited before a slow-window marker appeared" >&2
    exit 1
  fi
  sleep 0.25
done

cp "$marker" "${output_prefix}.marker.txt"
cp "$phase_csv" "${output_prefix}.phase.csv"
sample "$pid" 10 -file "${output_prefix}.sample.txt"
echo "captured triggered slow window at ${output_prefix}"
