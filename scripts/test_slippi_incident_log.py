#!/usr/bin/env python3
"""Verify live persistence, privacy, concurrent writes, and bounded incident output."""
from pathlib import Path
import csv
import os
import shlex
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = r'''
#include "slippi-incident-log.hpp"
#include <thread>
#include <fstream>
int main(int argc, char** argv) {
  SlippiIncidentLog log(argv[1]);
  log.ObserveLog("unrecognized secret playKey=DO_NOT_STORE");
  log.ObserveLog("Timer values for desync recovery too different: DO_NOT_STORE");
  log.ObserveLog("[Matchmaking] Received error from server for create ticket DO_NOT_STORE");
  log.ObserveLog("Mode: 1 / 1, Frames: 7891, GameIdx: 0, TiebreakIdx: 0, WinnerIdx: -2, StageId: 31, GameEndMethod: 7, LRASInitiator: -1 DO_NOT_STORE");
  log.ObserveLog("Mode: invalid DO_NOT_STORE");
  // Read while still alive: buffering until destruction would lose crash evidence.
  std::ifstream input(argv[1]);
  std::string all((std::istreambuf_iterator<char>(input)), {});
  if (all.find("desync_recovery_timer_mismatch") == std::string::npos) return 1;
  std::thread a([&] { for (int i=0;i<2500;++i) log.Record(SlippiIncidentLog::Event::PeerDisconnect); });
  std::thread b([&] { for (int i=0;i<2500;++i) log.Record(SlippiIncidentLog::Event::ReliableTimeout); });
  a.join(); b.join();
}
'''
with tempfile.TemporaryDirectory(prefix="meleepad-incidents-") as temp:
    temp = Path(temp)
    cpp, exe, output = temp / 'test.cpp', temp / 'test', temp / 'new-session' / 'events.csv'
    cpp.write_text(source)
    subprocess.run([*shlex.split(os.environ.get('CXX', 'c++')), '-std=c++17', '-pthread',
                    '-I', str(root / 'scripts'), str(cpp), '-o', str(exe)], check=True)
    subprocess.run([str(exe), str(output)], check=True)
    text = output.read_text()
    assert 'DO_NOT_STORE' not in text and 'playKey' not in text
    rows = list(csv.DictReader(text.splitlines()))
    assert len(rows) == 4097
    assert rows[-1]['event'] == 'event_limit_reached'
    assert sum(r['event'] == 'event_limit_reached' for r in rows) == 1
    reports = {r['event']: int(r['value']) for r in rows if r['event'].startswith('game_report_')}
    assert reports == {'game_report_mode': 1, 'game_report_frames': 7891,
                       'game_report_winner': -2, 'game_report_end_method': 7,
                       'game_report_lras_initiator': -1}
    assert all(None not in r and len(r) == 4 for r in rows)
    times = [int(r['elapsed_us']) for r in rows]
    assert times == sorted(times)
    assert all(int(r['unix_ms']) > 0 for r in rows)
print('PASS: incident privacy, persistence before close, concurrent writes, bounded output')
