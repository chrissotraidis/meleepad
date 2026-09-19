// Private diagnostic capture at the emulated EXI item-event boundary.
// Output belongs under ignored ref/ and must not be distributed.
#pragma once

#include <algorithm>

#include "Common/CommonTypes.h"
#include "Core/Core.h"
#include "Core/PowerPC/MMU.h"
#include "Core/PowerPC/PowerPC.h"
#include "Core/System.h"

#include <array>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <limits>
#include <optional>
#include <vector>

class SlippiItemGuestCapture final
{
public:
  explicit SlippiItemGuestCapture(const std::filesystem::path& path)
      : m_output(PreparePath(path)), m_last_frame(std::numeric_limits<s32>::min())
  {
    m_output << "frame,ordinal,item_type,pc,npc,lr,r28,r29,r31,packet_18,packet_28,packet_29";
    for (unsigned i = 0; i < 32; ++i)
      m_output << ",gpr" << i;
    for (const u32 offset : ITEM_OFFSETS)
      m_output << ",r28_plus_0x" << std::hex << std::setw(3) << std::setfill('0') << offset
               << std::dec << std::setfill(' ');
    for (const char* base : {"r4", "r30", "saved_r28", "saved_r30"})
      for (const u32 offset : ITEM_OFFSETS)
        m_output << ',' << base << "_plus_0x" << std::hex << std::setw(3) << std::setfill('0')
                 << offset << std::dec << std::setfill(' ');
    for (const u32 offset : SCRATCH_OFFSETS)
      m_output << ",scratch_0x" << std::hex << std::setw(3) << std::setfill('0') << offset
               << std::dec << std::setfill(' ');
    for (const u32 offset : STACK_OFFSETS)
      m_output << ",stack_plus_0x" << std::hex << std::setw(3) << std::setfill('0') << offset
               << std::dec << std::setfill(' ');
    m_output << ",ram_candidate_count";
    for (unsigned i = 0; i < MAX_RAM_CANDIDATES; ++i)
      m_output << ",ram_candidate_" << i;
    m_output << '\n';
  }

  ~SlippiItemGuestCapture() { m_output.flush(); }

  void Observe(u8 command, const u8* packet, u32 size)
  {
    if (command != 0x3b || !packet || size != 45)
      return;

    Core::CPUThreadGuard guard(Core::System::GetInstance());
    const auto& state = guard.GetSystem().GetPPCState();
    const s32 frame = static_cast<s32>((u32(packet[1]) << 24) | (u32(packet[2]) << 16) |
                                        (u32(packet[3]) << 8) | u32(packet[4]));
    if (frame != m_last_frame)
      m_ordinal = 0;
    else
      ++m_ordinal;
    m_last_frame = frame;

    m_output << frame << ',' << m_ordinal << ',';
    WriteHex16(packet[5], packet[6]);
    m_output << ',';
    WriteHex(state.pc);
    m_output << ',';
    WriteHex(state.npc);
    m_output << ',';
    WriteHex(LR(state));
    m_output << ',';
    WriteHex(state.gpr[28]);
    m_output << ',';
    WriteHex(state.gpr[29]);
    m_output << ',';
    WriteHex(state.gpr[31]);
    m_output << ',';
    WriteHex(ReadPacketWord(packet, 0x18));
    m_output << ',';
    WriteHex8(packet[0x28]);
    m_output << ',';
    WriteHex8(packet[0x29]);
    for (unsigned i = 0; i < 32; ++i)
    {
      m_output << ',';
      WriteHex(state.gpr[i]);
    }
    for (const u32 offset : ITEM_OFFSETS)
    {
      m_output << ',';
      WriteOptionalHex(ReadWord(guard, state.gpr[28], offset));
    }
    const auto saved_r28 = ReadWord(guard, state.gpr[1], 0x0d0);
    const auto saved_r30 = ReadWord(guard, state.gpr[1], 0x0d8);
    for (const auto base : {std::optional<u32>(state.gpr[4]), std::optional<u32>(state.gpr[30]),
                            saved_r28, saved_r30})
    {
      for (const u32 offset : ITEM_OFFSETS)
      {
        m_output << ',';
        WriteOptionalHex(base ? ReadWord(guard, *base, offset) : std::nullopt);
      }
    }
    for (const u32 offset : SCRATCH_OFFSETS)
    {
      m_output << ',';
      WriteOptionalHex(ReadWord(guard, SCRATCH_BASE, offset));
    }
    for (const u32 offset : STACK_OFFSETS)
    {
      m_output << ',';
      WriteOptionalHex(ReadWord(guard, state.gpr[1], offset));
    }
    const auto candidates = FindRamCandidates(guard, packet);
    m_output << ',' << candidates.size();
    for (unsigned i = 0; i < MAX_RAM_CANDIDATES; ++i)
    {
      m_output << ',';
      if (i < candidates.size())
        WriteHex(candidates[i]);
      else
        m_output << '-';
    }
    m_output << '\n';
  }

private:
  // This page was zero in the accepted native captures; 0x817ff000 is used
  // by the game's character-file name table and is not safe scratch memory.
  static constexpr u32 SCRATCH_BASE = 0x817f0000;
  static constexpr std::array<u32, 15> ITEM_OFFSETS{
      0x010, 0x024, 0x02c, 0x040, 0x044, 0x04c, 0x050, 0x518,
      0xc9c, 0xd44,  0xda8,  0xdd7,  0xddb,  0xdeb,  0xdef};
  static constexpr std::array<u32, 16> SCRATCH_OFFSETS{
      0x000, 0x004, 0x008, 0x00c, 0x010, 0x014, 0x018, 0x01c,
      0x020, 0x024, 0x028, 0x02c, 0x030, 0x034, 0x038, 0x03c};
  static constexpr std::array<u32, 17> STACK_OFFSETS{
      0x0a8, 0x0ac, 0x0b0, 0x0b4, 0x0b8, 0x0bc, 0x0c0, 0x0c4, 0x0c8,
      0x0cc, 0x0d0, 0x0d4, 0x0d8, 0x0dc, 0x0e0, 0x0e4, 0x0e8};
  static constexpr unsigned MAX_RAM_CANDIDATES = 8;

  static std::filesystem::path PreparePath(const std::filesystem::path& path)
  {
    if (!path.parent_path().empty())
      std::filesystem::create_directories(path.parent_path());
    return path;
  }

  static u32 ReadPacketWord(const u8* packet, unsigned offset)
  {
    return (u32(packet[offset]) << 24) | (u32(packet[offset + 1]) << 16) |
           (u32(packet[offset + 2]) << 8) | u32(packet[offset + 3]);
  }

  static std::optional<u32> ReadWord(const Core::CPUThreadGuard& guard, u32 base, u32 offset)
  {
    if (base > std::numeric_limits<u32>::max() - offset)
      return std::nullopt;
    const u32 address = base + offset;
    if (!PowerPC::MMU::HostIsRAMAddress(guard, address))
      return std::nullopt;
    const auto result = PowerPC::MMU::HostTryRead<u32>(guard, address);
    return result ? std::optional<u32>(result->value) : std::nullopt;
  }

  static u32 ReadRamWord(const u8* ram, u32 offset)
  {
    return (u32(ram[offset]) << 24) | (u32(ram[offset + 1]) << 16) |
           (u32(ram[offset + 2]) << 8) | u32(ram[offset + 3]);
  }

  static std::optional<u8> ReadByte(const Core::CPUThreadGuard& guard, u32 address)
  {
    if (!PowerPC::MMU::HostIsRAMAddress(guard, address))
      return std::nullopt;
    const auto result = PowerPC::MMU::HostTryRead<u8>(guard, address);
    return result ? std::optional<u8>(result->value) : std::nullopt;
  }

  static bool MatchesObject(const Core::CPUThreadGuard& guard, u32 base, const u8* packet)
  {
    const auto word = [&guard, base](u32 offset) { return ReadWord(guard, base, offset); };
    const auto half = [&guard, base](u32 offset) {
      return ReadWord(guard, base, offset).transform([](u32 value) { return u16(value >> 16); });
    };
    return word(0x040) == std::optional<u32>(ReadPacketWord(packet, 0x08)) &&
           word(0x044) == std::optional<u32>(ReadPacketWord(packet, 0x0c)) &&
           word(0x04c) == std::optional<u32>(ReadPacketWord(packet, 0x10)) &&
           word(0x050) == std::optional<u32>(ReadPacketWord(packet, 0x14)) &&
           word(0xc9c) == std::optional<u32>(ReadPacketWord(packet, 0x18)) &&
           half(0xd44) == std::optional<u16>(u16(packet[0x1c]) << 8 | u16(packet[0x1d])) &&
           word(0x01c) == std::optional<u32>(ReadPacketWord(packet, 0x1e)) &&
           ReadByte(guard, base + 0xdd7) == std::optional<u8>(packet[0x22]) &&
           ReadByte(guard, base + 0xddb) == std::optional<u8>(packet[0x26]) &&
           ReadByte(guard, base + 0xdeb) == std::optional<u8>(packet[0x27]) &&
           ReadByte(guard, base + 0xdef) == std::optional<u8>(packet[0x28]) &&
           ReadByte(guard, base + 0x518) == std::optional<u8>(packet[0x29]) &&
           half(0xda8) == std::optional<u16>(u16(packet[0x2b]) << 8 | u16(packet[0x2c]));
  }

  static std::vector<u32> FindRamCandidates(const Core::CPUThreadGuard& guard,
                                             const u8* packet)
  {
    auto& memory = guard.GetSystem().GetMemory();
    const u8* ram = memory.GetRAM();
    const u32 ram_size = memory.GetRamSizeReal();
    constexpr u32 base_offset = 0x040;
    constexpr u32 last_offset = 0xda8 + 2;
    std::vector<u32> candidates;
    if (!ram || ram_size < base_offset + last_offset)
      return candidates;

    const auto add_candidate = [&candidates, &guard, packet](u32 base) {
      if (std::find(candidates.begin(), candidates.end(), base) == candidates.end() &&
          MatchesObject(guard, base, packet))
        candidates.push_back(base);
    };

    // Search aligned MEM1 objects once per emitted packet. The complete field
    // tuple is intentionally strict; a partial byte match is not evidence of
    // the guest object used by SendGameInfo. The direct RAM scan covers clean
    // lines; the cache scan below covers modified lines not yet written back.
    for (u32 anchor = base_offset; anchor + last_offset <= ram_size; anchor += 4)
    {
      const u32 base = anchor - base_offset;
      if (ReadRamWord(ram, anchor) == ReadPacketWord(packet, 0x08))
        add_candidate(0x80000000u + base);
      if (candidates.size() == MAX_RAM_CANDIDATES)
        return candidates;
    }

    const auto& state = guard.GetSystem().GetPPCState();
    for (u32 set = 0; set < PowerPC::CACHE_SETS && candidates.size() < MAX_RAM_CANDIDATES;
         ++set)
    {
      for (u32 way = 0; way < PowerPC::CACHE_WAYS && candidates.size() < MAX_RAM_CANDIDATES;
           ++way)
      {
        if (!(state.dCache.valid[set] & (1u << way)))
          continue;
        const u32 line = state.dCache.addrs[set][way] & ~31u;
        if (line & (PowerPC::CACHE_EXRAM_BIT | PowerPC::CACHE_VMEM_BIT))
          continue;
        for (u32 in_line = 0; in_line <= 0x1c && candidates.size() < MAX_RAM_CANDIDATES;
             in_line += 4)
        {
          const auto* bytes = reinterpret_cast<const u8*>(state.dCache.data[set][way].data());
          if (ReadRamWord(bytes, in_line) == ReadPacketWord(packet, 0x08))
            add_candidate(0x80000000u + line + in_line - base_offset);
        }
      }
    }
    return candidates;
  }

  void WriteHex(u32 value)
  {
    m_output << std::hex << std::setw(8) << std::setfill('0') << value << std::dec
              << std::setfill(' ');
  }

  void WriteHex16(u8 high, u8 low)
  {
    m_output << std::hex << std::setw(4) << std::setfill('0')
              << ((unsigned(high) << 8) | unsigned(low)) << std::dec << std::setfill(' ');
  }

  void WriteHex8(u8 value)
  {
    m_output << std::hex << std::setw(2) << std::setfill('0') << unsigned(value) << std::dec
              << std::setfill(' ');
  }

  void WriteOptionalHex(const std::optional<u32>& value)
  {
    if (value)
      WriteHex(*value);
    else
      m_output << "-";
  }

  std::ofstream m_output;
  s32 m_last_frame;
  unsigned m_ordinal = 0;
};
