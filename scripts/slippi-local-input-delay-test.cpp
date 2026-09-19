#include <algorithm>
#include <vector>
#include <SFML/Network/Packet.hpp>
#include "slippi-local-input-delay.hpp"
#include <cstdio>
int main() {
  using namespace SlippiLocalInputDelay;
  int checks=0,failures=0;
  auto check=[&](bool ok){++checks;if(!ok)++failures;};
  std::vector<std::vector<u8>> sent;
  auto send=[&](sf::Packet& p){auto* b=static_cast<const u8*>(p.getData());sent.emplace_back(b,b+p.getDataSize());};
  auto packet=[](u8 c,s32 frame){sf::Packet p;p<<c<<frame;return p;};
  Queue q(120);
  auto early=packet(0x80,119);q.Submit(early,1000,send);check(sent.size()==1);
  auto pad=packet(0x80,120);q.Submit(pad,1000,send);check(sent.size()==1 && enqueued==1);
  check(q.PollTimeout(1000)==120);q.Flush(120999,send);check(sent.size()==1);
  auto ack=packet(0x81,120);q.Submit(ack,2000,send);check(sent.size()==2);
  pad.clear();q.Flush(121000,send);check(sent.size()==3 && sent.back()==std::vector<u8>({0x80,0,0,0,120}));
  check(released==1 && max_hold_us==120000 && q.entries.empty());
  check(q.PollTimeout(122000)==250);
  Queue immediate(0);auto later=packet(0x80,300);immediate.Submit(later,0,send);check(sent.size()==4 && immediate.entries.empty());
  for(unsigned i=0;i<1025;++i)q.Submit(later,200000,send);
  check(q.entries.size()==1024 && overflow==1);
  q.Flush(320000,send);check(q.entries.empty() && sent.size()==1028);
  std::printf("{\"checks\":%d,\"failures\":%d,\"packet_copy_and_due_time_tested\":true}\n",checks,failures);
  return failures?1:0;
}
