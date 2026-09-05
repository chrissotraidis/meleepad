#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/meleepad-benchmark-route.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

clang++ -x objective-c++ -std=c++20 -fobjc-arc -framework Foundation \
  -I"$ROOT/apple/shared" \
  "$ROOT/tests/MeleePadBenchmarkRouteTests.cpp" \
  -o "$BUILD_DIR/benchmark-route-tests"
"$BUILD_DIR/benchmark-route-tests"

echo "Benchmark route tests passed"
