// Bounded private complete packet trace for the two-client online-loop probe.
#pragma once
#include <filesystem>
#include <fstream>
#include <vector>
struct SlippiOnlineFrameTrace {
  struct Row { unsigned command; std::vector<unsigned char> payload; };
  std::vector<Row> rows;
  bool overflow = false;
  SlippiOnlineFrameTrace() { rows.reserve(12000); }
  void Observe(unsigned command, const unsigned char* packet, unsigned size) {
    if (command != 0x38 && command != 0x3a && command != 0x3b && command != 0x3c) return;
    if (size < 5 || size > 4096 || rows.size() >= 60000) { overflow = true; return; }
    rows.push_back({command, {packet, packet + size}});
  }
  void Write(const std::filesystem::path& directory) {
    static constexpr char digits[] = "0123456789abcdef";
    std::ofstream out(directory / "online-frame-packets.csv");
    out << "command,payload\n";
    for (const auto& row : rows) {
      out << row.command << ',';
      for (auto byte : row.payload) out << digits[byte >> 4] << digits[byte & 15];
      out << '\n';
    }
    std::ofstream status(directory / "online-frame-trace.json");
    status << "{\"packets\":" << rows.size() << ",\"overflow\":" << (overflow ? "true" : "false") << "}\n";
  }
};
