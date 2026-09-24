#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cat > "$scratch/test.cpp" <<'CPP'
#include "MeleePadSlippiConnectionQuality.hpp"
#include <cassert>

int main() {
  MeleePadSlippiConnectionQuality quality;
  using State = MeleePadSlippiConnectionState;
  MeleePadSlippiConnectionSample sample;
  assert(quality.Update(sample).state == State::Disconnected);
  sample.connected = true;
  assert(quality.Update(sample).state == State::Measuring);
  sample.ping_samples = 1;
  sample.ping_total_us = 150000;
  assert(quality.Update(sample).state == State::Steady);
  sample.ping_samples = 2;
  sample.ping_total_us = 300000;
  assert(quality.Update(sample).state == State::HighLatency);
  sample.ping_samples = 3;
  sample.ping_total_us = 550000;
  auto severe = quality.Update(sample);
  assert(severe.state == State::SevereLatency && severe.average_ms == 250);
  sample.ping_samples = 4;
  sample.ping_total_us = 600000;
  assert(quality.Update(sample).state == State::Steady);
  sample.game_active = true;
  sample.rollback_stalls = 3;
  assert(quality.Update(sample).state == State::Stalling);
  assert(quality.Update(sample).state == State::Steady);
  assert(quality.Update(sample).state == State::NoFreshPing);
  sample.connected = false;
  assert(quality.Update(sample).state == State::Disconnected);
  sample.connected = true;
  sample.game_active = false;
  sample.ping_samples = sample.ping_total_us = sample.rollback_stalls = 0;
  assert(quality.Update(sample).state == State::Measuring);
}
CPP
${CXX:-c++} -std=c++17 -I "$root/apple/shared" "$scratch/test.cpp" -o "$scratch/test"
"$scratch/test"
echo "PASS: peer connection warnings and session reset"
