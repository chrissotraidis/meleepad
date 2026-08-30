#include "moderngekko/runtime.hpp"

#include <cassert>

int main() {
  moderngekko::RuntimeConfig config;
  assert(!config.emulated_cpu_clock_scale);
  config.emulated_cpu_clock_scale = 0.90f;
  assert(config.emulated_cpu_clock_scale == 0.90f);
  config.emulated_cpu_clock_scale = 0.95f;
  assert(config.emulated_cpu_clock_scale == 0.95f);
  return 0;
}
