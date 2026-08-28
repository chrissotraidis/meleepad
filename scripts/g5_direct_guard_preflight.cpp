// Host-only cost preflight for G5 guarded cross-chunk direct calls.
// This contains no game code or data. It models the arm64 sequence retained in
// the PERF-076 disassembly: target guard, direct callee, PC check, continuation
// guard. Build with: clang++ -O3 -std=c++20 g5_direct_guard_preflight.cpp -o ...

#include <algorithm>
#include <array>
#include <charconv>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <mach/mach_time.h>
#include <string_view>
#include <utility>
#include <vector>

namespace
{
constexpr std::size_t kSites = 16;
constexpr std::size_t kChunks = 237;
constexpr std::size_t kLookupEntries = 4096;
constexpr std::array<std::uint8_t, kSites> kSiteChunks = {
    3, 17, 29, 41, 58, 73, 89, 101, 119, 127, 143, 157, 173, 191, 211, 229};
constexpr std::uint32_t kBase = 0x80000000u;
constexpr std::uint8_t kVerified = 1;
constexpr double kCanonicalCpuMs = 15.699995;
constexpr double kDispatchesRemovedPerFrame = 35472511.0 / 440.0;

struct Range
{
  std::uint32_t start;
  std::uint32_t end;
};

struct RuntimeState
{
  const Range* forced_begin;
  const Range* forced_end;
  const std::int32_t* address_to_chunk;
  const std::int32_t* address_to_chunk_end;
  const std::uint8_t* chunk_state;
  std::uint32_t lookup_ram_size;
  std::uint32_t rel_module_count;
  bool module_active;
  bool cpu_running;
  bool lockstep;
  bool (*host_call_contains)(std::uint32_t, void*);
  void* host_call_user;
  std::uint32_t ram_size;
};

struct CpuState;
using Guard = bool (*)(CpuState*, std::uint32_t);
using HostCall = bool (*)(CpuState*, std::uint32_t);

struct CpuState
{
  RuntimeState* runtime;
  Guard guard;
  HostCall host_call;
  const volatile std::uint8_t* direct_chunk_eligibility;
  std::uint32_t pc;
  std::uint64_t sink;
  bool direct_links_enabled;
};

[[gnu::noinline]] bool ResolveNativeAddress(RuntimeState*, std::uint32_t address,
                                             std::uint32_t* linked_address)
{
  asm volatile("" ::: "memory");
  *linked_address = address;
  return true;
}

[[gnu::noinline]] bool IsHostCallAddress(const RuntimeState* runtime, std::uint32_t address)
{
  if (!runtime->host_call_contains)
    return false;
  if (runtime->host_call_contains(address, runtime->host_call_user))
    return true;
  return address < runtime->ram_size &&
         runtime->host_call_contains(address | kBase, runtime->host_call_user);
}

[[gnu::noinline]] bool FastDispatchable(RuntimeState* runtime, std::uint32_t address)
{
  for (const Range* range = runtime->forced_begin; range != runtime->forced_end; ++range)
  {
    if (address >= range->start && address < range->end)
      return false;
  }
  if (!runtime->module_active || runtime->address_to_chunk == runtime->address_to_chunk_end)
    return false;
  std::uint32_t linked_address = address;
  // The GALE01 DOL never takes this branch, but the product's generic helper
  // retains it and therefore cannot be compiled as a leaf function.
  if (runtime->rel_module_count != 0 &&
      !ResolveNativeAddress(runtime, address, &linked_address))
    return false;
  if (linked_address < kBase || linked_address >= kBase + runtime->lookup_ram_size)
    return false;
  const std::uint32_t lookup = (linked_address - kBase) >> 2;
  const auto lookup_size = runtime->address_to_chunk_end - runtime->address_to_chunk;
  if (lookup >= static_cast<std::uint32_t>(lookup_size))
    return false;
  const std::int32_t chunk = runtime->address_to_chunk[lookup];
  return chunk >= 0 && runtime->chunk_state[static_cast<std::size_t>(chunk)] == kVerified;
}

[[gnu::noinline]] bool CallbackGuard(CpuState* cpu, std::uint32_t address)
{
  RuntimeState* runtime = cpu->runtime;
  if (!runtime || !runtime->module_active || !runtime->cpu_running || runtime->lockstep)
    return false;
  if (cpu->host_call && IsHostCallAddress(runtime, address))
    return false;
  return FastDispatchable(runtime, address);
}

bool DummyHostCall(CpuState*, std::uint32_t)
{
  return false;
}

[[gnu::noinline]] void DirectCallee(CpuState* cpu, std::uint32_t continuation,
                                    std::uint32_t salt)
{
  asm volatile("" ::: "memory");
  cpu->sink = (cpu->sink * 0x9e3779b97f4a7c15ull) ^ salt;
  cpu->pc = continuation;
  asm volatile("" ::: "memory");
}

inline bool InlineEligible(const CpuState* cpu, std::size_t chunk)
{
  return cpu->direct_links_enabled && cpu->direct_chunk_eligibility[chunk] == kVerified;
}

#define FOR_EACH_SITE(OP)                                                                         \
  OP(0, 3)                                                                                        \
  OP(1, 17)                                                                                       \
  OP(2, 29)                                                                                       \
  OP(3, 41)                                                                                       \
  OP(4, 58)                                                                                       \
  OP(5, 73)                                                                                       \
  OP(6, 89)                                                                                       \
  OP(7, 101)                                                                                      \
  OP(8, 119)                                                                                      \
  OP(9, 127)                                                                                      \
  OP(10, 143)                                                                                     \
  OP(11, 157)                                                                                     \
  OP(12, 173)                                                                                     \
  OP(13, 191)                                                                                     \
  OP(14, 211)                                                                                     \
  OP(15, 229)

[[gnu::noinline]] void RunCallback(CpuState* cpu, std::uint64_t batches)
{
  for (std::uint64_t batch = 0; batch < batches; ++batch)
  {
#define CALLBACK_SITE(site, chunk)                                                                \
    do                                                                                            \
    {                                                                                             \
      constexpr std::uint32_t target = kBase + ((site * 8u + 0u) * 4u);                          \
      constexpr std::uint32_t continuation = kBase + ((site * 8u + 4u) * 4u);                    \
      Guard guard = cpu->guard;                                                                   \
      if (guard && guard(cpu, target))                                                            \
      {                                                                                           \
        DirectCallee(cpu, continuation, site + 1u);                                               \
        guard = cpu->guard;                                                                       \
        if (!(cpu->pc == continuation && guard && guard(cpu, continuation)))                      \
          cpu->sink ^= 0xd1e5u + site;                                                            \
      }                                                                                           \
    } while (false);
    FOR_EACH_SITE(CALLBACK_SITE)
#undef CALLBACK_SITE
  }
}

[[gnu::noinline]] void RunInline(CpuState* cpu, std::uint64_t batches)
{
  for (std::uint64_t batch = 0; batch < batches; ++batch)
  {
#define INLINE_SITE(site, chunk)                                                                  \
    do                                                                                            \
    {                                                                                             \
      constexpr std::uint32_t continuation = kBase + ((site * 8u + 4u) * 4u);                    \
      if (InlineEligible(cpu, chunk))                                                             \
      {                                                                                           \
        DirectCallee(cpu, continuation, site + 1u);                                               \
        if (!(cpu->pc == continuation && InlineEligible(cpu, chunk)))                             \
          cpu->sink ^= 0xd1e5u + site;                                                            \
      }                                                                                           \
    } while (false);
    FOR_EACH_SITE(INLINE_SITE)
#undef INLINE_SITE
  }
}

[[gnu::noinline]] void RunUnguarded(CpuState* cpu, std::uint64_t batches)
{
  for (std::uint64_t batch = 0; batch < batches; ++batch)
  {
#define UNGUARDED_SITE(site, chunk)                                                               \
    do                                                                                            \
    {                                                                                             \
      constexpr std::uint32_t continuation = kBase + ((site * 8u + 4u) * 4u);                    \
      DirectCallee(cpu, continuation, site + 1u);                                                 \
      if (cpu->pc != continuation)                                                               \
        cpu->sink ^= 0xd1e5u + site;                                                              \
    } while (false);
    FOR_EACH_SITE(UNGUARDED_SITE)
#undef UNGUARDED_SITE
  }
}

#undef FOR_EACH_SITE

using Runner = void (*)(CpuState*, std::uint64_t);

double NowNanoseconds()
{
  static mach_timebase_info_data_t timebase = [] {
    mach_timebase_info_data_t result{};
    mach_timebase_info(&result);
    return result;
  }();
  return static_cast<double>(mach_continuous_time()) * timebase.numer / timebase.denom;
}

double Measure(Runner runner, CpuState* cpu, std::uint64_t batches)
{
  const double start = NowNanoseconds();
  runner(cpu, batches);
  const double elapsed = NowNanoseconds() - start;
  return elapsed / (static_cast<double>(batches) * kSites);
}

double Median(std::vector<double> values)
{
  std::sort(values.begin(), values.end());
  return values[values.size() / 2];
}

std::uint64_t ParsePositive(std::string_view text, const char* name)
{
  std::uint64_t result = 0;
  const auto conversion = std::from_chars(text.data(), text.data() + text.size(), result);
  if (conversion.ec != std::errc{} || conversion.ptr != text.data() + text.size() || result == 0)
  {
    std::fprintf(stderr, "%s must be a positive integer\n", name);
    std::exit(2);
  }
  return result;
}

void ValidateModel(CpuState* cpu, RuntimeState* runtime, std::array<Range, 1>* ranges,
                   std::array<std::uint8_t, kChunks>* chunk_state)
{
  constexpr std::uint32_t target = kBase;
  if (!CallbackGuard(cpu, target) || !InlineEligible(cpu, kSiteChunks[0]))
  {
    std::fprintf(stderr, "verified target was not eligible\n");
    std::exit(1);
  }

  (*chunk_state)[kSiteChunks[0]] = 0;
  if (CallbackGuard(cpu, target) || InlineEligible(cpu, kSiteChunks[0]))
  {
    std::fprintf(stderr, "invalidated target remained eligible\n");
    std::exit(1);
  }
  (*chunk_state)[kSiteChunks[0]] = kVerified;

  cpu->direct_links_enabled = false;
  if (InlineEligible(cpu, kSiteChunks[0]))
  {
    std::fprintf(stderr, "disabled direct links remained eligible\n");
    std::exit(1);
  }
  cpu->direct_links_enabled = true;

  (*ranges)[0] = {target, target + 4};
  runtime->forced_end = ranges->data() + 1;
  // The runtime-owned table must clear a whole dependent chunk when a forced
  // fallback or invalidation affects it.
  (*chunk_state)[kSiteChunks[0]] = 0;
  if (CallbackGuard(cpu, target) || InlineEligible(cpu, kSiteChunks[0]))
  {
    std::fprintf(stderr, "forced-fallback target remained eligible\n");
    std::exit(1);
  }
  runtime->forced_end = ranges->data();
  (*chunk_state)[kSiteChunks[0]] = kVerified;
}
}

int main(int argc, char** argv)
{
  const std::uint64_t batches = argc > 1 ? ParsePositive(argv[1], "batches") : 500000;
  const std::uint64_t repeats = argc > 2 ? ParsePositive(argv[2], "repeats") : 9;
  if (repeats < 5 || repeats % 2 == 0)
  {
    std::fprintf(stderr, "repeats must be odd and at least 5\n");
    return 2;
  }

  std::array<std::uint8_t, kChunks> chunk_state{};
  chunk_state.fill(kVerified);
  std::array<std::int32_t, kLookupEntries> lookup{};
  for (std::size_t i = 0; i < lookup.size(); ++i)
    lookup[i] = static_cast<std::int32_t>(i % kChunks);
  for (std::size_t site = 0; site < kSites; ++site)
  {
    lookup[site * 8] = kSiteChunks[site];
    lookup[site * 8 + 4] = kSiteChunks[site];
  }
  std::array<Range, 1> no_ranges{};

  RuntimeState runtime{no_ranges.data(), no_ranges.data(), lookup.data(), lookup.data() + lookup.size(),
                       chunk_state.data(), static_cast<std::uint32_t>(lookup.size() * 4), 0,
                       true, true, false, nullptr, nullptr, 0x01800000u};
  CpuState cpu{&runtime, CallbackGuard, DummyHostCall, chunk_state.data(), kBase, 1, true};

  ValidateModel(&cpu, &runtime, &no_ranges, &chunk_state);

  RunUnguarded(&cpu, 1000);
  RunInline(&cpu, 1000);
  RunCallback(&cpu, 1000);

  std::vector<double> unguarded;
  std::vector<double> inline_guard;
  std::vector<double> callback;
  unguarded.reserve(repeats);
  inline_guard.reserve(repeats);
  callback.reserve(repeats);

  // Rotate the order so thermal/scheduler drift does not systematically favor
  // one representation.
  for (std::uint64_t repeat = 0; repeat < repeats; ++repeat)
  {
    const std::array<std::pair<const char*, Runner>, 3> modes = repeat % 3 == 0
        ? std::array{std::pair{"callback", RunCallback}, std::pair{"inline", RunInline},
                     std::pair{"unguarded", RunUnguarded}}
        : repeat % 3 == 1
            ? std::array{std::pair{"inline", RunInline}, std::pair{"unguarded", RunUnguarded},
                         std::pair{"callback", RunCallback}}
            : std::array{std::pair{"unguarded", RunUnguarded},
                         std::pair{"callback", RunCallback}, std::pair{"inline", RunInline}};
    for (const auto& [name, runner] : modes)
    {
      const double value = Measure(runner, &cpu, batches);
      if (std::string_view{name} == "callback")
        callback.push_back(value);
      else if (std::string_view{name} == "inline")
        inline_guard.push_back(value);
      else
        unguarded.push_back(value);
    }
  }

  const double unguarded_median = Median(unguarded);
  const double inline_median = Median(inline_guard);
  const double callback_median = Median(callback);
  const double saved_per_edge = callback_median - inline_median;
  const double min_edges = kDispatchesRemovedPerFrame / 2.0;
  const double max_edges = kDispatchesRemovedPerFrame;
  const double conservative_saved_ms = saved_per_edge * min_edges / 1.0e6;
  const double optimistic_saved_ms = saved_per_edge * max_edges / 1.0e6;
  const double required_ms = kCanonicalCpuMs * 0.05;

  std::printf("mode,median_ns_per_direct_edge,net_guard_ns_over_unguarded\n");
  std::printf("unguarded,%.6f,0.000000\n", unguarded_median);
  std::printf("inline,%.6f,%.6f\n", inline_median, inline_median - unguarded_median);
  std::printf("callback,%.6f,%.6f\n", callback_median, callback_median - unguarded_median);
  std::printf("saved_ns_per_edge,%.6f\n", saved_per_edge);
  std::printf("dynamic_edges_per_frame_bound,%.3f,%.3f\n", min_edges, max_edges);
  std::printf("projected_saved_ms_per_frame,%.6f,%.6f\n", conservative_saved_ms,
              optimistic_saved_ms);
  std::printf("five_percent_cpu_threshold_ms,%.6f\n", required_ms);
  std::printf("conservative_projection,%s\n",
              conservative_saved_ms > required_ms ? "PASS" : "REJECT");
  std::printf("sink,%llu\n", static_cast<unsigned long long>(cpu.sink));
  return 0;
}
