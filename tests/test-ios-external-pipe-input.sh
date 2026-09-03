#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONTROLLER="$ROOT/apple/ios/MeleePadGameViewController.mm"
HOST="$ROOT/apple/ios/MeleePadCoreHost.mm"

grep -Fq 'environment[@"MELEEPAD_EXTERNAL_PIPE_INPUT"] boolValue' "$CONTROLLER"
grep -Fq '@"input publisher disabled source=external-pipe"' "$CONTROLLER"
grep -Fq 'environment[@"MELEEPAD_TRACE_BUTTON_EDGES"]' "$HOST"
grep -Fq '@"input button edge delivered previous=0x%04x current=0x%04x bytes=%lu"' "$HOST"
grep -Fq 'environment[@"MELEEPAD_RUNTIME_USER_DIRECTORY"]' "$HOST"
grep -Fq '#if TARGET_OS_SIMULATOR' "$HOST"
grep -Fq '[resolvedOverride isEqualToString:resolvedUser]' "$HOST"
grep -Fq 'sizeof(((struct sockaddr_un *)0)->sun_path)' "$HOST"
grep -Fq '@"runtime user-directory override enabled source=simulator-diagnostic"' "$HOST"

echo "iOS external-pipe input source regression passed"
