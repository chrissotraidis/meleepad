// Data-free regression for opt-in texture-pool attribution counters.

#include "Common/FramePhaseTiming.h"

#include <chrono>
#include <cstdlib>
#include <iostream>

int main()
{
  if (setenv("MELEEPAD_FRAME_PHASE_LOG", "/tmp/meleepad-phase-preflight.csv", 1) != 0)
    return 2;

  const auto before = Common::FramePhaseTiming::GetTotals();
  Common::FramePhaseTiming::AddTexturePoolLookup(true, false);
  Common::FramePhaseTiming::AddTexturePoolLookup(false, false);
  Common::FramePhaseTiming::AddTexturePoolLookup(false, true);
  Common::FramePhaseTiming::AddTexturePoolExpirations(4);
  Common::FramePhaseTiming::AddTexturePoolRecentExpiryMiss();
  Common::FramePhaseTiming::AddTextureCreate(std::chrono::nanoseconds{2'000'000});
  Common::FramePhaseTiming::AddFramebufferCreate(std::chrono::nanoseconds{3'000'000});
  const auto after = Common::FramePhaseTiming::GetTotals();

  const bool passed =
      after.texture_pool_hits - before.texture_pool_hits == 1 &&
      after.texture_pool_empty_misses - before.texture_pool_empty_misses == 1 &&
      after.texture_pool_same_frame_misses - before.texture_pool_same_frame_misses == 1 &&
      after.texture_pool_expirations - before.texture_pool_expirations == 4 &&
      after.texture_pool_recent_expiry_misses - before.texture_pool_recent_expiry_misses == 1 &&
      after.texture_create_calls - before.texture_create_calls == 1 &&
      after.texture_create_ns - before.texture_create_ns == 2'000'000 &&
      after.framebuffer_create_calls - before.framebuffer_create_calls == 1 &&
      after.framebuffer_create_ns - before.framebuffer_create_ns == 3'000'000;
  std::cout << "TEXTURE_POOL_ATTRIBUTION,counter-deltas," << (passed ? "PASS" : "FAIL") << '\n';
  return passed ? 0 : 1;
}
