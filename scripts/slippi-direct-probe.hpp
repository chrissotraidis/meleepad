#pragma once
// Private acceptance target only. Shared between the UIKit host and CPU thread.
#include <atomic>
#include <mutex>
#include <string>
namespace SlippiDirectProbe {
struct Pad { double x=0, y=0, cx=0, cy=0, l=0, r=0; unsigned buttons=0; };
inline std::mutex pad_mutex;
inline Pad pad;
inline std::atomic<bool> stop{false};
inline std::atomic<unsigned> denied_searches{0}, direct_searches{0}, unranked_searches{0};
inline bool account_boot_check=false;
inline std::atomic<bool> account_loaded{false};
inline std::atomic<unsigned long long> game_starts{0}, game_ends{0}, game_frames{0};
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
}
int SlippiDirectMain(const char* game, const char* iso, const char* module,
                    const char* user, const std::string& account, void* surface);
