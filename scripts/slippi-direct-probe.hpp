#pragma once
// Private acceptance target only. Shared between the UIKit host and CPU thread.
#include <array>
#include <atomic>
#include <functional>
#include <mutex>
#include <string>
namespace SlippiDirectProbe {
struct Pad { double x=0, y=0, cx=0, cy=0, l=0, r=0; unsigned buttons=0; };
inline std::mutex pad_mutex;
inline Pad pad;
inline std::atomic<bool> stop{false};
inline std::atomic<unsigned> denied_searches{0}, direct_searches{0}, unranked_searches{0};
inline std::atomic<unsigned> matchmaking_initializing{0}, matchmaking_ticket_ready{0};
inline std::atomic<unsigned> matchmaking_opponent_connecting{0}, matchmaking_connected{0};
inline std::atomic<unsigned> matchmaking_errors{0};
inline std::atomic<int> last_matchmaking_state{-1};
inline bool account_boot_check=false;
inline bool menu_probe=false;
inline std::atomic<bool> account_loaded{false};
inline std::atomic<unsigned long long> game_starts{0}, game_ends{0}, game_frames{0};
inline std::atomic<unsigned long long> menu_events_emitted{0}, input_override_reads{0}, input_active_reads{0};
inline std::array<std::atomic<unsigned long long>, 6> input_button_reads{};

inline void ResetTelemetry() {
  std::lock_guard lock(pad_mutex);
  pad = {};
  denied_searches.store(0, std::memory_order_relaxed);
  direct_searches.store(0, std::memory_order_relaxed);
  unranked_searches.store(0, std::memory_order_relaxed);
  matchmaking_initializing.store(0, std::memory_order_relaxed);
  matchmaking_ticket_ready.store(0, std::memory_order_relaxed);
  matchmaking_opponent_connecting.store(0, std::memory_order_relaxed);
  matchmaking_connected.store(0, std::memory_order_relaxed);
  matchmaking_errors.store(0, std::memory_order_relaxed);
  last_matchmaking_state.store(-1, std::memory_order_relaxed);
  account_loaded.store(false, std::memory_order_relaxed);
  game_starts.store(0, std::memory_order_relaxed);
  game_ends.store(0, std::memory_order_relaxed);
  game_frames.store(0, std::memory_order_relaxed);
  menu_events_emitted.store(0, std::memory_order_relaxed);
  input_override_reads.store(0, std::memory_order_relaxed);
  input_active_reads.store(0, std::memory_order_relaxed);
  for (auto& count : input_button_reads)
    count.store(0, std::memory_order_relaxed);
}
// Called before any code history write or matchmaking request. Never silently
// changes a requested mode or bypasses the service's account/version checks.
inline bool AllowsSearch(int mode, const std::string& code) {
  // Unranked has no connect code. Direct is allowed only with an explicitly
  // entered arranged-opponent code. Ranked, Teams, and Party remain gated
  // until their service and gameplay lifecycles are accepted.
  if (mode == 1) return code.empty();
  if (mode != 2 || code.empty() || code.size() > 18) return false;
  for (unsigned char c : code) if (c < 32 || c == 127) return false;
  return true;
}

// Called by the game-thread EXI status read. Keeping this at the producing
// boundary avoids racing the upstream matchmaking object's non-atomic state
// from the watchdog. Counts are transition counts, not service claims.
inline void ObserveMatchmakingState(int state) {
  if (last_matchmaking_state.exchange(state, std::memory_order_acq_rel) == state)
    return;
  switch (state) {
    case 1: ++matchmaking_initializing; break;
    case 2: ++matchmaking_ticket_ready; break;
    case 3: ++matchmaking_opponent_connecting; break;
    case 4: ++matchmaking_connected; break;
    case 5: ++matchmaking_errors; break;
    default: break;
  }
}
}
int SlippiDirectMain(const char* game, const char* iso, const char* module,
                    const char* user, const std::string& account, void* surface,
                    const std::function<void()>& on_runtime_ready = {});
