#!/usr/bin/env python3
"""Exercise the exact accumulator distributed in the dependency patch."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
patch = (root / 'patches/moderngekko-dolphin/0057-frame-interval-summary.patch').read_text()
section = patch.split('+++ b/Source/Core/VideoCommon/FrameIntervalSummary.h\n', 1)[1].split('\ndiff --git ', 1)[0]
header = '\n'.join(line[1:] for line in section.splitlines() if line.startswith('+')) + '\n'
with tempfile.TemporaryDirectory(prefix='meleepad-frame-summary-') as directory:
    path = Path(directory)
    (path / 'FrameIntervalSummary.h').write_text(header)
    (path / 'test.cpp').write_text(r'''
#include "FrameIntervalSummary.h"
#include <cassert>
#include <limits>
#include <thread>
int main() {
  FrameIntervalSummary summary;
  summary.Record(0); summary.Record(-1);
  summary.Record(std::numeric_limits<double>::infinity());
  assert(summary.Take().frames == 0);
  for (int i=0; i<95; ++i) summary.Record(16.67);
  for (int i=0; i<4; ++i) summary.Record(34);
  summary.Record(300);
  auto s=summary.Take();
  assert(s.frames==100 && s.p95_upper_ms==17 && s.maximum_ms==300);
  assert(s.over_20_ms==5 && s.over_33_ms==5 && s.over_50_ms==1);
  assert(std::abs(s.average_ms-20.1965)<0.00001);
  assert(summary.Take().frames==0);
  summary.Record(400); assert(summary.Take().p95_upper_ms==400);
  std::atomic<bool> done=false;
  std::thread producer([&] { for(int i=0;i<100000;++i) summary.Record(17); done=true; });
  std::uint64_t total=0;
  while(!done.load()) total+=summary.Take().frames;
  producer.join(); total+=summary.Take().frames;
  assert(total==100000);
}
'''.replace('#include <thread>', '#include <thread>\n#include <atomic>'))
    subprocess.run(['clang++','-std=c++17','-O2','-pthread','-Wall','-Wextra','-Werror',str(path/'test.cpp'),'-o',str(path/'test')],check=True)
    subprocess.run([str(path/'test')],check=True)
print('Frame interval summary tests passed')
