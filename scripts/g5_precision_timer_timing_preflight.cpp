#include <chrono>
#include <cstdlib>
#include <iostream>

#include "Common/FramePhaseTiming.h"

int main()
{
  using namespace std::chrono_literals;
  if (setenv("SSBMPAD_FRAME_PHASE_LOG", "/private/tmp/ssbmpad-phase-preflight.csv", 1) != 0)
    return 1;

  const auto before = Common::FramePhaseTiming::GetTotals();
  Common::FramePhaseTiming::AddCpuPrecisionTimer(false, 2ms, 3ms);
  Common::FramePhaseTiming::AddCpuPrecisionTimer(true, 5ms, 7ms);
  Common::FramePhaseTiming::AddMetalBindBackbuffer(11ms, 13ms, 17ms, 19ms);
  const auto after = Common::FramePhaseTiming::GetTotals();

  const bool pass =
      after.cpu_precision_throttle_calls - before.cpu_precision_throttle_calls == 1 &&
      after.cpu_precision_throttle_coarse_ns - before.cpu_precision_throttle_coarse_ns ==
          2'000'000 &&
      after.cpu_precision_throttle_spin_ns - before.cpu_precision_throttle_spin_ns == 3'000'000 &&
      after.cpu_precision_present_calls - before.cpu_precision_present_calls == 1 &&
      after.cpu_precision_present_coarse_ns - before.cpu_precision_present_coarse_ns == 5'000'000 &&
      after.cpu_precision_present_spin_ns - before.cpu_precision_present_spin_ns == 7'000'000 &&
      after.metal_bind_surface_ns - before.metal_bind_surface_ns == 11'000'000 &&
      after.metal_next_drawable_ns - before.metal_next_drawable_ns == 13'000'000 &&
      after.metal_update_backbuffer_ns - before.metal_update_backbuffer_ns == 17'000'000 &&
      after.metal_set_framebuffer_ns - before.metal_set_framebuffer_ns == 19'000'000;
  std::cout << "PRECISION_TIMER_TIMING,origin-deltas," << (pass ? "PASS" : "FAIL") << '\n';
  return pass ? 0 : 1;
}
