#pragma once
// Private acceptance target only. Shared between the UIKit host and CPU thread.
#include <array>
#include <atomic>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include "slippi-network-diagnostics.hpp"
namespace SlippiDirectProbe {
struct Pad { double x=0, y=0, cx=0, cy=0, l=0, r=0; unsigned buttons=0; };
inline std::mutex pad_mutex;
inline Pad pad;
inline std::atomic<bool> stop{false};
inline std::atomic<unsigned> denied_searches{0}, direct_searches{0}, unranked_searches{0};
inline std::atomic<unsigned> ranked_searches{0}, teams_searches{0}, party_searches{0};
inline std::atomic<unsigned> matchmaking_initializing{0}, matchmaking_ticket_ready{0};
inline std::atomic<unsigned> matchmaking_opponent_connecting{0}, matchmaking_connected{0};
inline std::atomic<unsigned> matchmaking_errors{0};
inline std::atomic<int> last_matchmaking_state{-1};
inline bool account_boot_check=false;
inline bool menu_probe=false;
inline std::atomic<bool> account_loaded{false};
inline std::atomic<unsigned long long> game_starts{0}, game_ends{0}, game_frames{0};
inline std::atomic<int32_t> game_latest_frame{-124}, game_finalized_frame{-124};
inline std::atomic<unsigned long long> game_progress_frames{0}, game_rewinds{0};
// Written only by the game-frame observer; reset before the runtime starts.
inline int32_t game_highest_frame = -124;
inline void BeginGameTimeline() {
  game_highest_frame = -124;
  game_latest_frame.store(-124, std::memory_order_relaxed);
  game_finalized_frame.store(-124, std::memory_order_relaxed);
}
inline void ObserveBookend(const uint8_t* packet, unsigned size) {
  if (!packet || size < 9 || packet[0] != 0x3c) return;
  const auto read = [](const uint8_t* p) {
    return static_cast<int32_t>((uint32_t(p[0]) << 24) | (uint32_t(p[1]) << 16) |
                                (uint32_t(p[2]) << 8) | uint32_t(p[3]));
  };
  const int32_t frame = read(packet + 1);
  if (frame <= game_latest_frame.exchange(frame, std::memory_order_relaxed))
    game_rewinds.fetch_add(1, std::memory_order_relaxed);
  if (frame > game_highest_frame) {
    game_progress_frames.fetch_add(static_cast<uint64_t>(int64_t(frame) - game_highest_frame),
                                   std::memory_order_relaxed);
    game_highest_frame = frame;
  }
  game_finalized_frame.store(read(packet + 5), std::memory_order_relaxed);
}
inline std::atomic<unsigned long long> menu_events_emitted{0}, input_override_reads{0}, input_active_reads{0};
inline std::array<std::atomic<unsigned long long>, 6> input_button_reads{};

inline void ResetTelemetry() {
  slippi_network_diagnostics.Reset();
  std::lock_guard lock(pad_mutex);
  pad = {};
  denied_searches.store(0, std::memory_order_relaxed);
  direct_searches.store(0, std::memory_order_relaxed);
  unranked_searches.store(0, std::memory_order_relaxed);
  ranked_searches.store(0, std::memory_order_relaxed);
  teams_searches.store(0, std::memory_order_relaxed);
  party_searches.store(0, std::memory_order_relaxed);
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
  BeginGameTimeline();
  game_progress_frames.store(0, std::memory_order_relaxed);
  game_rewinds.store(0, std::memory_order_relaxed);
  menu_events_emitted.store(0, std::memory_order_relaxed);
  input_override_reads.store(0, std::memory_order_relaxed);
  input_active_reads.store(0, std::memory_order_relaxed);
  for (auto& count : input_button_reads)
    count.store(0, std::memory_order_relaxed);
}
// Called before any code history write or matchmaking request. Never silently
// changes a requested mode or bypasses the service's account/version checks.
inline bool AllowsSearch(int mode, const std::string& code) {
  // Ranked, Unranked and Party ignore the guest's saved code buffer.
  // Direct and Teams use a code; the service validates its meaning and
  // account eligibility. This gate only rejects malformed/unknown requests.
  if (mode == 0 || mode == 1 || mode == 4) return true;
  if ((mode != 2 && mode != 3) || code.empty() || code.size() > 18) return false;
  for (unsigned char c : code) if (c < 32 || c == 127) return false;
  return true;
}

inline const char* SearchDeniedMessage(int mode) {
  if (mode == 2) return "Direct requires your opponent's valid connect code.";
  if (mode == 3) return "Teams requires a valid team code.";
  return "Unknown online mode. Return to the online menu and try again.";
}

inline void ObserveSearch(int mode) {
  switch (mode) {
    case 0: ++ranked_searches; break;
    case 1: ++unranked_searches; break;
    case 2: ++direct_searches; break;
    case 3: ++teams_searches; break;
    case 4: ++party_searches; break;
    default: break;
  }
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
