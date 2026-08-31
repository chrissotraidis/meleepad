#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONTROLLER="$ROOT/apple/ios/SsbmPadGameViewController.mm"
HOST="$ROOT/apple/ios/SsbmPadCoreHost.mm"

grep -Fq 'environment[@"SSBMPAD_EXTERNAL_PIPE_INPUT"] boolValue' "$CONTROLLER"
grep -Fq '@"input publisher disabled source=external-pipe"' "$CONTROLLER"
grep -Fq 'environment[@"SSBMPAD_TRACE_BUTTON_EDGES"]' "$HOST"
grep -Fq '@"input button edge delivered previous=0x%04x current=0x%04x bytes=%lu"' "$HOST"

echo "iOS external-pipe input source regression passed"
