#include "slippi-direct-trace.hpp"
#include <iostream>
int main(int argc,char** argv) {
  if (argc!=2 || !std::filesystem::create_directory(argv[1])) return 2;
  int checks=0,failures=0;auto check=[&](bool ok){++checks;failures+=!ok;};
  const unsigned char packet[]={0x38,0xff,0xff,0xff,0x85,1};
  SlippiDirectTrace trace;
  for (unsigned game=0;game<2;++game) {
    trace.Observe(0x36,nullptr,0);
    for (unsigned i=0;i<70000;++i) trace.Observe(0x38,packet,sizeof(packet));
    trace.Observe(0x39,nullptr,0);
  }
  check(trace.games.size()==2 && trace.games[0].ended && trace.games[1].ended);
  check(trace.row_count==140000 && !trace.overflow && !trace.sequence_error);
  check(trace.games[0].rows[0].payload==trace.games[1].rows[0].payload);
  check(trace.Write(argv[1]));
  check(std::filesystem::exists(std::filesystem::path(argv[1])/"game-2/online-frame-packets.csv"));
  SlippiDirectTrace bounded(6,1);bounded.Observe(0x36,nullptr,0);
  bounded.Observe(0x38,packet,6);bounded.Observe(0x38,packet,6);
  check(bounded.overflow && bounded.row_count==1 && bounded.payload_bytes==6);
  SlippiDirectTrace invalid;invalid.Observe(0x38,packet,6);
  check(invalid.sequence_error && invalid.games.empty());
  SlippiDirectTrace missing_end;missing_end.Observe(0x36,nullptr,0);missing_end.Observe(0x36,nullptr,0);
  check(missing_end.sequence_error);
  SlippiDirectTrace after_end;after_end.Observe(0x36,nullptr,0);after_end.Observe(0x39,nullptr,0);after_end.Observe(0x38,packet,6);
  check(after_end.sequence_error && after_end.row_count==0);
  std::cout<<"{\"checks\":"<<checks<<",\"failures\":"<<failures<<",\"synthetic_only\":true,\"gameplay_tested\":false}\n";
  return failures?1:0;
}
