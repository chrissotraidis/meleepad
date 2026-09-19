// Test-only frame-boundary timing and bounded private GCT captures.
#pragma once
#include "Core/HW/Memmap.h"
#include "Core/System.h"
#include "Core/Slippi/SlippiCompat.h"
#include <chrono>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

struct SlippiFrameProfiler {
  struct Row { int frame, phase; long long wall_ns, cpu_ns; };
  struct Capture { int frame, phase; u32 address; std::vector<u8> data; };
  std::vector<Row> rows;
  std::vector<Capture> captures;
  std::filesystem::path directory;
  std::chrono::steady_clock::time_point start = std::chrono::steady_clock::now();
  explicit SlippiFrameProfiler(std::filesystem::path path) : directory(std::move(path)) {
    rows.reserve(5000); captures.reserve(3);
  }
  void Observe(u8 command, const u8* packet, u32 size, int phase) {
    if (command != 0x3c || size < 5) return;
    if (rows.size() >= 10000) return;
    const int frame = static_cast<s32>((u32(packet[1]) << 24) | (u32(packet[2]) << 16) |
                                      (u32(packet[3]) << 8) | u32(packet[4]));
    const auto wall = std::chrono::duration_cast<std::chrono::nanoseconds>(
        std::chrono::steady_clock::now() - start).count();
    timespec cpu{};
    const long long cpu_ns = clock_gettime(CLOCK_THREAD_CPUTIME_ID, &cpu) == 0 ?
        static_cast<long long>(cpu.tv_sec) * 1000000000LL + cpu.tv_nsec : -1;
    rows.push_back({frame, phase, wall, cpu_ns});
    if (!((phase == 0 && (frame == 60 || frame == 180)) || (phase == 3 && frame == 300) ||
          (phase == 4 && (frame == 60 || frame == 180 || frame == 300)))) return;
    for (const auto& capture : captures)
      if (capture.frame == frame && capture.phase == phase) return;
    auto& memory = Core::System::GetInstance().GetMemory();
    const u32 address = SlippiCompat::loaded_gct_address;
    const u32 size_bytes = SlippiCompat::loaded_gct_size;
    const u32 offset = address - 0x80000000u;
    if (address < 0x80000000u || size_bytes == 0 || size_bytes > 128 * 1024 ||
        static_cast<u64>(offset) + size_bytes > memory.GetRamSizeReal()) return;
    const u8* data = memory.GetRAM() + offset;
    captures.push_back({frame, phase, address, std::vector<u8>(data, data + size_bytes)});
  }
  void Write() const {
    std::ofstream timing(directory / "slippi-frame-timing.csv");
    timing << "frame,phase,wall_ns,thread_cpu_ns\n";
    for (const auto& row : rows)
      timing << row.frame << ',' << row.phase << ',' << row.wall_ns << ',' << row.cpu_ns << '\n';
    std::ofstream manifest(directory / "slippi-gct-captures.csv");
    manifest << "frame,phase,address,bytes,file\n";
    for (const auto& capture : captures) {
      const auto name = "slippi-gct-frame-" + std::to_string(capture.frame) + "-phase-" +
                        std::to_string(capture.phase) + ".bin";
      std::ofstream data(directory / name, std::ios::binary);
      data.write(reinterpret_cast<const char*>(capture.data.data()), capture.data.size());
      manifest << capture.frame << ',' << capture.phase << ',' << capture.address << ','
               << capture.data.size() << ',' << name << '\n';
    }
  }
};
