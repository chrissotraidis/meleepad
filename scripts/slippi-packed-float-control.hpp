#pragma once
// Diagnostic compatibility with pinned Ishiiruka scalar float accesses.
// Only injected Slippi code addressing physical MEM1 through its cached alias.
#include "Core/Slippi/SlippiCompat.h"
#include <atomic>
namespace SlippiPackedFloatControl {
inline std::atomic<unsigned long long> accesses{0};
inline bool Allows(u32 pc, u32 address) {
  if (!SlippiCompat::boot_enabled || SlippiCompat::loaded_gct_size == 0 ||
      pc < SlippiCompat::loaded_gct_address ||
      u64(pc) >= u64(SlippiCompat::loaded_gct_address) + SlippiCompat::loaded_gct_size ||
      address < 0x80000000u || address > 0x817ffffcu)
    return false;
  ++accesses;
  return true;
}
}
