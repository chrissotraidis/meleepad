#!/usr/bin/env python3
"""Check RTT and throttle windows, session reset, and CSV alignment."""
from pathlib import Path
import os
import re
import shlex
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = r'''
#include "slippi-network-diagnostics.hpp"
#include <iostream>
int main() {
  SlippiNetworkDiagnostics d;
  d.ObservePing(1550000);
  d.ObservePing(220000); // The last sample must not conceal the earlier spike.
  if (d.ping_max_us != 1550000 || d.ping_latest_us != 220000 ||
      d.ping_samples != 2 || d.ping_over250ms != 1 || d.ping_over500ms != 1)
    return 1;
  d.input_submitted.Observe(1000);
  d.input_submitted.Observe(81000);
  if (d.input_submitted.window_gap_us != 80000 || d.input_submitted.count != 2) return 3;
  d.ObserveThrottle(32);
  d.ObserveThrottle(20);
  d.ObserveThrottle(32);
  d.WriteRow(std::cout, 1.0, 101000);
  if (d.input_submitted.window_gap_us || d.window_ping_us ||
      d.enet_throttle_window_samples || d.enet_throttle_window_max) return 4;
  d.input_submitted.Observe(91000);
  if (d.input_submitted.window_gap_us != 10000) return 5;
  d.ObserveThrottle(32);
  d.WriteRow(std::cout, 1.5, 111000);
  d.Reset();
  if (d.ping_max_us || d.ping_samples || d.ping_over250ms || d.ping_over500ms ||
      d.input_submitted.last_us || d.input_submitted.count || d.enet_throttle_latest ||
      d.enet_throttle_window_samples || d.enet_throttle_window_max)
    return 2;
  d.WriteRow(std::cout, 2.0);
}
'''
with tempfile.TemporaryDirectory(prefix="meleepad-network-diagnostics-") as folder:
    folder = Path(folder)
    cpp, binary = folder / "test.cpp", folder / "test"
    cpp.write_text(source)
    subprocess.run([*shlex.split(os.environ.get("CXX", "c++")), "-std=c++17",
                    "-I", str(root / "scripts"), str(cpp), "-o", str(binary)],
                   check=True, timeout=60)
    rows = subprocess.check_output([str(binary)], text=True, timeout=10).splitlines()
header = re.search(r'network << "([^"\n]+)\\n";',
                   (root / "scripts/slippi-direct-probe.cpp").read_text()).group(1)
assert len(rows) == 3
assert all(len(row.split(',')) == len(header.split(',')) for row in rows)
print("PASS: transient RTT peak retained, session reset, CSV header/rows aligned")

fields = dict(zip(header.split(','), rows[0].split(',')))
assert fields['input_submit_gap_window_us'] == '80000'
assert fields['input_submit_age_us'] == '20000'
assert fields['ping_window_max_us'] == '1550000'
assert [dict(zip(header.split(','), row.split(',')))['enet_throttle_window_min']
        for row in rows] == ['20', '32', '32']
assert [dict(zip(header.split(','), row.split(',')))['enet_throttle_window_max']
        for row in rows] == ['32', '32', '0']
assert [dict(zip(header.split(','), row.split(',')))['enet_throttle_window_samples']
        for row in rows] == ['3', '1', '0']
assert [dict(zip(header.split(','), row.split(',')))['enet_throttle_latest']
        for row in rows] == ['32', '32', '0']
assert [dict(zip(header.split(','), row.split(',')))['enet_throttle_min']
        for row in rows] == ['20', '20', '32']
print('PASS: window peaks survive sampling, drain independently, and reset between sessions')
