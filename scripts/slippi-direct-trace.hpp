#pragma once
// Private match-by-match evidence, separate from the accepted short LAN probe.
#include <filesystem>
#include <fstream>
#include <vector>
struct SlippiDirectTrace {
  struct Row { unsigned command; std::vector<unsigned char> payload; };
  struct Game { std::vector<Row> rows; bool ended=false; };
  std::vector<Game> games;
  bool overflow=false, sequence_error=false;
  size_t payload_bytes=0, row_count=0;
  const size_t byte_limit, row_limit;
  explicit SlippiDirectTrace(size_t bytes=64*1024*1024, size_t rows=400000)
      : byte_limit(bytes),row_limit(rows) {}
  void Observe(unsigned command,const unsigned char* packet,unsigned size) {
    if (command==0x36) {
      if (!games.empty() && !games.back().ended) sequence_error=true;
      if (games.size()>=16) { overflow=true; return; }
      games.emplace_back(); return;
    }
    if (command==0x39) {
      if (games.empty() || games.back().ended) sequence_error=true;
      else games.back().ended=true;
      return;
    }
    if (command!=0x38 && command!=0x3a && command!=0x3b && command!=0x3c) return;
    if (games.empty() || games.back().ended) { sequence_error=true; return; }
    if (!packet || size<5 || size>4096) { sequence_error=true; return; }
    if (row_count>=row_limit || size>byte_limit-payload_bytes) { overflow=true; return; }
    games.back().rows.push_back({command,{packet,packet+size}});
    ++row_count; payload_bytes+=size;
  }
  bool Write(const std::filesystem::path& root) const {
    static constexpr char digits[]="0123456789abcdef";
    bool written=true;
    for (size_t i=0;i<games.size();++i) {
      auto folder=root/("game-"+std::to_string(i+1));
      std::error_code error;std::filesystem::create_directories(folder,error);
      if (error) { written=false; continue; }
      std::ofstream data(folder/"online-frame-packets.csv");data<<"command,payload\n";
      for (const auto& row:games[i].rows) {
        data<<row.command<<',';
        for (auto byte:row.payload) data<<digits[byte>>4]<<digits[byte&15];
        data<<'\n';
      }
      data.flush();written=bool(data)&&written;
      std::ofstream state(folder/"online-frame-trace.json");
      state<<"{\"packets\":"<<games[i].rows.size()<<",\"overflow\":"<<(overflow?"true":"false")
        <<",\"sequence_error\":"<<(sequence_error?"true":"false")<<",\"game_ended\":"<<(games[i].ended?"true":"false")<<"}\n";
      state.flush();written=bool(state)&&written;
    }
    std::ofstream status(root/"direct-trace.json");
    status<<"{\"games\":"<<games.size()<<",\"packets\":"<<row_count<<",\"payload_bytes\":"<<payload_bytes
      <<",\"overflow\":"<<(overflow?"true":"false")<<",\"sequence_error\":"<<(sequence_error?"true":"false")
      <<",\"game_files_written\":"<<(written?"true":"false")<<",\"crossplay_accepted\":false}\n";
    status.flush();return bool(status)&&written;
  }
};
