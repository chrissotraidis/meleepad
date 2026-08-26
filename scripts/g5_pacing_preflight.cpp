// Host-only preflight for the macOS frame-pacing tail investigated at G5.
// This does not run emulated code or alter guest timing.

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <numeric>
#include <string_view>
#include <thread>
#include <vector>

namespace
{
using Clock = std::chrono::steady_clock;
using Ns = std::chrono::nanoseconds;

constexpr auto FRAME_PERIOD = Ns{16'683'333};
Ns g_spin_time{1'020'000};
Ns g_synthetic_work{5'500'000};
Ns g_sleep_chunk{1'000'000};

enum class Mode
{
  SchedulerYield,
  ChunkedSchedulerYield,
  ChunkedBusySpin,
  BusySpin,
};

struct Sample
{
  double frame_ms;
  double overshoot_ms;
  double sleep_ms;
  double wake_lateness_ms;
  double final_spin_ms;
};

void BusyUntil(Clock::time_point target)
{
  while (Clock::now() < target)
    std::atomic_signal_fence(std::memory_order_seq_cst);
}

Sample RunFrame(Mode mode)
{
  const auto start = Clock::now();
  const auto target = start + FRAME_PERIOD;
  BusyUntil(start + g_synthetic_work);

  const auto requested_wake = target - g_spin_time;
  const auto sleep_start = Clock::now();
  if (mode == Mode::ChunkedSchedulerYield || mode == Mode::ChunkedBusySpin)
  {
    while (true)
    {
      const auto now = Clock::now();
      if (now >= requested_wake)
        break;
      std::this_thread::sleep_until(std::min(requested_wake, now + g_sleep_chunk));
    }
  }
  else
  {
    std::this_thread::sleep_until(requested_wake);
  }
  const auto woke = Clock::now();

  while (Clock::now() < target)
  {
    if (mode != Mode::BusySpin && mode != Mode::ChunkedBusySpin)
      std::this_thread::yield();
    else
      std::atomic_signal_fence(std::memory_order_seq_cst);
  }

  const auto end = Clock::now();
  const auto ms = [](auto duration) {
    return std::chrono::duration<double, std::milli>(duration).count();
  };
  return {
      .frame_ms = ms(end - start),
      .overshoot_ms = std::max(0.0, ms(end - target)),
      .sleep_ms = ms(woke - sleep_start),
      .wake_lateness_ms = std::max(0.0, ms(woke - requested_wake)),
      .final_spin_ms = ms(end - woke),
  };
}

double Percentile(std::vector<double> values, double fraction)
{
  std::sort(values.begin(), values.end());
  const double position = fraction * static_cast<double>(values.size() - 1);
  const auto lower = static_cast<std::size_t>(std::floor(position));
  const auto upper = static_cast<std::size_t>(std::ceil(position));
  const double weight = position - static_cast<double>(lower);
  return values[lower] * (1.0 - weight) + values[upper] * weight;
}

void Report(std::string_view name, const std::vector<Sample>& samples)
{
  std::vector<double> frame;
  std::vector<double> overshoot;
  std::vector<double> lateness;
  frame.reserve(samples.size());
  overshoot.reserve(samples.size());
  lateness.reserve(samples.size());
  std::size_t at_or_below_16_7 = 0;
  double sleep_sum = 0.0;
  double spin_sum = 0.0;

  for (const Sample& sample : samples)
  {
    frame.push_back(sample.frame_ms);
    overshoot.push_back(sample.overshoot_ms);
    lateness.push_back(sample.wake_lateness_ms);
    sleep_sum += sample.sleep_ms;
    spin_sum += sample.final_spin_ms;
    at_or_below_16_7 += sample.frame_ms <= 16.7;
  }

  const double mean = std::accumulate(frame.begin(), frame.end(), 0.0) / frame.size();
  std::printf(
      "%.*s frames=%zu mean=%.6f median=%.6f p95=%.6f p99=%.6f worst=%.6f "
      "le16.7=%.3f%% overshoot_p95=%.6f overshoot_p99=%.6f "
      "wake_late_p95=%.6f wake_late_p99=%.6f sleep_mean=%.6f final_spin_mean=%.6f\n",
      static_cast<int>(name.size()), name.data(), samples.size(), mean, Percentile(frame, 0.50),
      Percentile(frame, 0.95), Percentile(frame, 0.99), *std::max_element(frame.begin(), frame.end()),
      100.0 * static_cast<double>(at_or_below_16_7) / samples.size(),
      Percentile(overshoot, 0.95), Percentile(overshoot, 0.99), Percentile(lateness, 0.95),
      Percentile(lateness, 0.99), sleep_sum / samples.size(), spin_sum / samples.size());
}
}  // namespace

int main(int argc, char** argv)
{
  const int frames_per_mode = argc >= 2 ? std::atoi(argv[1]) : 600;
  const int spin_microseconds = argc >= 3 ? std::atoi(argv[2]) : 1020;
  const int work_microseconds = argc >= 4 ? std::atoi(argv[3]) : 5500;
  const int chunk_microseconds = argc >= 5 ? std::atoi(argv[4]) : 1000;
  if (frames_per_mode < 100)
  {
    std::fprintf(stderr, "frames per mode must be at least 100\n");
    return 2;
  }
  if (spin_microseconds < 100 || spin_microseconds >= 10'000)
  {
    std::fprintf(stderr, "spin lead must be between 100 and 9999 microseconds\n");
    return 2;
  }
  if (work_microseconds < 0 || work_microseconds >= 15'000)
  {
    std::fprintf(stderr, "synthetic work must be between 0 and 14999 microseconds\n");
    return 2;
  }
  if (chunk_microseconds < 100 || chunk_microseconds >= 10'000)
  {
    std::fprintf(stderr, "sleep chunk must be between 100 and 9999 microseconds\n");
    return 2;
  }
  g_spin_time = std::chrono::microseconds{spin_microseconds};
  g_synthetic_work = std::chrono::microseconds{work_microseconds};
  g_sleep_chunk = std::chrono::microseconds{chunk_microseconds};
  std::printf(
      "spin_lead_us=%d frame_period_ns=%lld synthetic_work_us=%d sleep_chunk_us=%d\n",
      spin_microseconds, static_cast<long long>(FRAME_PERIOD.count()), work_microseconds,
      chunk_microseconds);

  // Warm both paths before measuring. Alternation gives the modes the same
  // changing host conditions instead of running one entire cohort first.
  for (int i = 0; i < 30; ++i)
    RunFrame(static_cast<Mode>(i % 4));

  std::vector<Sample> scheduler_yield;
  std::vector<Sample> chunked_scheduler_yield;
  std::vector<Sample> chunked_busy_spin;
  std::vector<Sample> busy_spin;
  scheduler_yield.reserve(frames_per_mode);
  chunked_scheduler_yield.reserve(frames_per_mode);
  chunked_busy_spin.reserve(frames_per_mode);
  busy_spin.reserve(frames_per_mode);
  for (int i = 0; i < frames_per_mode * 4; ++i)
  {
    const Mode mode = static_cast<Mode>(i % 4);
    if (mode == Mode::SchedulerYield)
      scheduler_yield.push_back(RunFrame(mode));
    else if (mode == Mode::ChunkedSchedulerYield)
      chunked_scheduler_yield.push_back(RunFrame(mode));
    else if (mode == Mode::ChunkedBusySpin)
      chunked_busy_spin.push_back(RunFrame(mode));
    else
      busy_spin.push_back(RunFrame(mode));
  }

  Report("scheduler_yield", scheduler_yield);
  Report("chunked_scheduler_yield", chunked_scheduler_yield);
  Report("chunked_busy_spin", chunked_busy_spin);
  Report("busy_spin", busy_spin);
  return 0;
}
