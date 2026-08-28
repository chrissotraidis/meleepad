// Data-free regression for frame-correlated EFB pipeline miss counters.

#include "Common/FramePhaseTiming.h"

#include <chrono>
#include <cstdlib>
#include <iostream>

int main()
{
  if (setenv("SSBMPAD_FRAME_PHASE_LOG", "/private/tmp/ssbmpad-phase-preflight.csv", 1) != 0)
    return 2;

  const auto before = Common::FramePhaseTiming::GetTotals();
  Common::FramePhaseTiming::AddEfbPipelineMiss(
      true, std::chrono::nanoseconds{2'000'000}, std::chrono::nanoseconds{3'000'000});
  Common::FramePhaseTiming::AddEfbPipelineMiss(
      false, std::chrono::nanoseconds{5'000'000}, std::chrono::nanoseconds{7'000'000});
  const auto after = Common::FramePhaseTiming::GetTotals();

  const bool passed =
      after.efb_vram_pipeline_misses - before.efb_vram_pipeline_misses == 1 &&
      after.efb_vram_shader_ns - before.efb_vram_shader_ns == 2'000'000 &&
      after.efb_vram_pipeline_ns - before.efb_vram_pipeline_ns == 3'000'000 &&
      after.efb_ram_pipeline_misses - before.efb_ram_pipeline_misses == 1 &&
      after.efb_ram_shader_ns - before.efb_ram_shader_ns == 5'000'000 &&
      after.efb_ram_pipeline_ns - before.efb_ram_pipeline_ns == 7'000'000;
  std::cout << "EFB_PIPELINE_TIMING,counter-deltas," << (passed ? "PASS" : "FAIL") << '\n';
  return passed ? 0 : 1;
}
