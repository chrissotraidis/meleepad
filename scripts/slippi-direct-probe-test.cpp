#include "slippi-direct-probe.hpp"
#include <iostream>
int main() {
  int checks=0, failures=0;
  auto check=[&](bool value){++checks; failures+=!value;};
  for (int mode=-1;mode<=5;++mode) check(SlippiDirectProbe::AllowsSearch(mode,"TEST#123")== (mode>=0 && mode<=4));
  for (int mode : {0, 1, 4}) {
    check(SlippiDirectProbe::AllowsSearch(mode,""));
    check(SlippiDirectProbe::AllowsSearch(mode,"SAVED#123"));
  }
  for (int mode : {2, 3}) {
    check(!SlippiDirectProbe::AllowsSearch(mode,""));
    check(!SlippiDirectProbe::AllowsSearch(mode,std::string(19,'A')));
    check(!SlippiDirectProbe::AllowsSearch(mode,std::string("A\0B",3)));
    check(!SlippiDirectProbe::AllowsSearch(mode,"TEST\n#123"));
    check(!SlippiDirectProbe::AllowsSearch(mode,std::string(1,127)));
    check(SlippiDirectProbe::AllowsSearch(mode,std::string("\x83\x65\x83\x58#123")));
    check(SlippiDirectProbe::AllowsSearch(mode,std::string(18,'A')));
  }
  SlippiDirectProbe::ResetTelemetry();
  for (int mode=-1;mode<=5;++mode) SlippiDirectProbe::ObserveSearch(mode);
  check(SlippiDirectProbe::ranked_searches==1);
  check(SlippiDirectProbe::unranked_searches==1);
  check(SlippiDirectProbe::direct_searches==1);
  check(SlippiDirectProbe::teams_searches==1);
  check(SlippiDirectProbe::party_searches==1);
  SlippiDirectProbe::ResetTelemetry();
  check(SlippiDirectProbe::ranked_searches==0 && SlippiDirectProbe::teams_searches==0 &&
        SlippiDirectProbe::party_searches==0);
  auto bookend=[](int32_t frame, int32_t finalized) {
    uint8_t packet[9]{0x3c};
    for (unsigned i=0;i<4;++i) {
      packet[i+1]=uint32_t(frame) >> (24-i*8);
      packet[i+5]=uint32_t(finalized) >> (24-i*8);
    }
    SlippiDirectProbe::ObserveBookend(packet, sizeof(packet));
  };
  SlippiDirectProbe::ResetTelemetry();
  bookend(-123,-124); bookend(-122,-124); bookend(-123,-124); bookend(-122,-123);
  check(SlippiDirectProbe::game_progress_frames==2);
  check(SlippiDirectProbe::game_rewinds==1);
  check(SlippiDirectProbe::game_latest_frame==-122 && SlippiDirectProbe::game_finalized_frame==-123);
  bookend(-121,-122);
  check(SlippiDirectProbe::game_progress_frames==3);
  SlippiDirectProbe::BeginGameTimeline(); bookend(-123,-124);
  check(SlippiDirectProbe::game_progress_frames==4 && SlippiDirectProbe::game_rewinds==1);
  const uint8_t truncated[]{0x3c,0,0,0,9};
  SlippiDirectProbe::ObserveBookend(truncated,sizeof(truncated));
  check(SlippiDirectProbe::game_latest_frame==-123 && SlippiDirectProbe::game_progress_frames==4);
  SlippiDirectProbe::ResetTelemetry();
  check(SlippiDirectProbe::game_progress_frames==0 && SlippiDirectProbe::game_rewinds==0);
  std::cout<<"{\"checks\":"<<checks<<",\"failures\":"<<failures<<",\"network_attempted\":false}\n";
  return failures?1:0;
}
