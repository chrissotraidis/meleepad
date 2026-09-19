#pragma once

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <string_view>
#include <string>

// Only fixed event names and numeric values reach disk. Upstream messages can
// contain credentials or peer identities, so never persist the message itself.
class SlippiIncidentLog {
public:
  enum class Event {
    SessionStart, DesyncTimer, DesyncStocks, DesyncHealth, PoorPerformance,
    ForcedStall, PeerDisconnect, MatchmakingRejected, MatchmakingConnectFailed,
    MatchmakingResponseInvalid, PeerConnectFailed, MatchmakingState, GameStart,
    RemoteDisconnect, ReliableTimeout, LocalDisconnect, TelemetryStart,
    TeardownSend, DuplicateConnectionCleanup, CleanupStart, CleanupComplete,
    GameReportWinner, GameReportEndMethod, GameReportLras, GameReportFrames,
    GameReportMode, LimitReached
  };

  explicit SlippiIncidentLog(const std::filesystem::path& path)
      : started(std::chrono::steady_clock::now()) {
    std::error_code error;
    std::filesystem::create_directories(path.parent_path(), error);
    output.open(path);
    output << "elapsed_us,unix_ms,event,value\n";
    Record(Event::SessionStart);
  }

  void Record(Event event, int64_t value = 0) {
    std::lock_guard<std::mutex> lock(mutex);
    if (count > limit) return;
    if (count == limit) event = Event::LimitReached;
    ++count;
    const auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now() - started).count();
    const auto utc = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    output << elapsed << ',' << utc << ',' << Name(event) << ',' << value << '\n';
    output.flush(); // Preserve rare failure events even without orderly shutdown.
  }

  void ObserveLog(std::string_view text) {
    const auto starts = [&](std::string_view prefix) {
      return text.substr(0, prefix.size()) == prefix;
    };
    if (starts("Timer values for desync recovery too different:")) Record(Event::DesyncTimer);
    else if (starts("Stocks remaining for desync recovery do not match:")) Record(Event::DesyncStocks);
    else if (starts("Current health for desync recovery too different:")) Record(Event::DesyncHealth);
    else if (starts("Match terminated due to poor performance.")) Record(Event::PoorPerformance);
    else if (starts("Force-disconnecting player ")) Record(Event::ForcedStall);
    else if (starts("[Netplay] Final disconnect received for a client.")) Record(Event::PeerDisconnect);
    else if (starts("[Matchmaking] Received error from server for create ticket")) Record(Event::MatchmakingRejected);
    else if (starts("[Matchmaking] Failed to connect to mm server")) Record(Event::MatchmakingConnectFailed);
    else if (starts("[Matchmaking] Received incorrect response for create ticket")) Record(Event::MatchmakingResponseInvalid);
    else if (starts("Slippi online connection failed")) Record(Event::PeerConnectFailed);
    else if (starts("[Netplay] Disconnecting peer ")) Record(Event::TeardownSend);
    else if (starts("Multiple connections detected for single peer.")) Record(Event::DuplicateConnectionCleanup);
    else if (starts("Connection cleanup started...")) Record(Event::CleanupStart);
    else if (starts("Connection cleanup completed...")) Record(Event::CleanupComplete);
    else if (starts("Mode: ") && text.size() < 512) {
      // This upstream report is numeric-only. Parse selected fields instead of
      // retaining it; nearby upstream report lines contain account credentials.
      unsigned mode, query_mode, frames, game, tiebreak;
      int winner, stage, end, lras;
      const std::string copy(text);
      if (std::sscanf(copy.c_str(),
          "Mode: %u / %u, Frames: %u, GameIdx: %u, TiebreakIdx: %u, WinnerIdx: %d, StageId: %d, GameEndMethod: %d, LRASInitiator: %d",
          &mode, &query_mode, &frames, &game, &tiebreak, &winner, &stage, &end, &lras) == 9 &&
          mode == query_mode && mode <= 4 && winner >= -3 && winner <= 3 &&
          end >= 0 && end <= 255 && lras >= -1 && lras <= 3) {
        Record(Event::GameReportMode, mode);
        Record(Event::GameReportFrames, frames);
        Record(Event::GameReportWinner, winner);
        Record(Event::GameReportEndMethod, end);
        Record(Event::GameReportLras, lras);
      }
    }
  }

private:
  static const char* Name(Event event) {
    switch (event) {
      case Event::SessionStart: return "session_start";
      case Event::DesyncTimer: return "desync_recovery_timer_mismatch";
      case Event::DesyncStocks: return "desync_recovery_stock_mismatch";
      case Event::DesyncHealth: return "desync_recovery_health_mismatch";
      case Event::PoorPerformance: return "poor_performance_disconnect";
      case Event::ForcedStall: return "forced_stall_disconnect";
      case Event::PeerDisconnect: return "peer_disconnect";
      case Event::MatchmakingRejected: return "matchmaking_ticket_rejected";
      case Event::MatchmakingConnectFailed: return "matchmaking_connect_failed";
      case Event::MatchmakingResponseInvalid: return "matchmaking_response_invalid";
      case Event::PeerConnectFailed: return "peer_connect_failed";
      case Event::MatchmakingState: return "matchmaking_state";
      case Event::GameStart: return "game_start";
      case Event::RemoteDisconnect: return "remote_disconnect_count";
      case Event::ReliableTimeout: return "reliable_timeout_count";
      case Event::LocalDisconnect: return "local_disconnect_count";
      case Event::TelemetryStart: return "telemetry_start";
      case Event::TeardownSend: return "teardown_sending_disconnect";
      case Event::DuplicateConnectionCleanup: return "duplicate_connection_cleanup";
      case Event::CleanupStart: return "connection_cleanup_start";
      case Event::CleanupComplete: return "connection_cleanup_complete";
      case Event::GameReportMode: return "game_report_mode";
      case Event::GameReportFrames: return "game_report_frames";
      case Event::GameReportWinner: return "game_report_winner";
      case Event::GameReportEndMethod: return "game_report_end_method";
      case Event::GameReportLras: return "game_report_lras_initiator";
      case Event::LimitReached: return "event_limit_reached";
    }
    return "unknown";
  }
  static constexpr size_t limit = 4096;
  std::mutex mutex;
  std::ofstream output;
  std::chrono::steady_clock::time_point started;
  size_t count = 0;
};
