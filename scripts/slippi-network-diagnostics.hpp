#pragma once
// Numeric-only diagnostics. Never retain packet contents, addresses or identities.
#include <atomic>
#include <cstdint>
#include <ostream>
#include <string_view>

struct SlippiNetworkDiagnostics {
  std::atomic<uint64_t> ping_samples{0}, ping_total_us{0}, ping_latest_us{0};
  std::atomic<uint64_t> input_stalls{0}, time_sync_advances{0}, stall_disconnects{0};
  std::atomic<uint64_t> invalid_packets{0}, peer_disconnects{0}, peer_reason{0};
  std::atomic<int> apple_service_result{-2};
  std::atomic<uint64_t> queued_packets{0}, queue_total_us{0}, queue_max_us{0};
  std::atomic<uint64_t> loop_max_us{0}, send_failures{0};
  std::atomic<uint64_t> enet_rtt_ms{0}, enet_rtt_variance_ms{0}, enet_packet_loss{0};
  std::atomic<uint64_t> enet_throttle_samples{0}, enet_throttle_min{32};
  // The session minimum cannot show recovery after a bad interval. Windows
  // aggregate every sampled peer; zero samples means the latest value is stale.
  std::atomic<uint64_t> enet_throttle_latest{0}, enet_throttle_window_samples{0};
  std::atomic<uint64_t> enet_throttle_window_min{32}, enet_throttle_window_max{0};
  std::atomic<uint64_t> native_dispatches{0}, fallback_steps{0}, failed_chunks{0};
  std::atomic<uint64_t> verifications{0}, reverify_events{0};

  std::atomic<uint64_t> ping_max_us{0}, ping_over250ms{0}, ping_over500ms{0};
  std::atomic<uint64_t> service_errors{0}, receive_events{0}, flush_calls{0};
  std::atomic<uint64_t> work_max_us{0}, flush_max_us{0};
  std::atomic<uint64_t> sent_datagrams{0}, received_datagrams{0};

  std::atomic<const void*> connected_peer{nullptr};
  std::atomic<uint64_t> remote_disconnect_commands{0}, reliable_timeouts{0}, local_disconnect_requests{0};
  std::atomic<uint64_t> disconnect_ack_age_ms{0}, disconnect_rtt_ms{0};

  // Window maxima are drained by the single CSV writer; counters remain cumulative.
  struct Cadence {
    std::atomic<uint64_t> last_us{0}, count{0}, window_gap_us{0};
    void Observe(uint64_t now) {
      const auto previous = last_us.exchange(now, std::memory_order_relaxed);
      ++count;
      if (previous && now >= previous)
        SlippiNetworkDiagnostics::RecordMaximum(window_gap_us, now - previous);
    }
    void Reset() { last_us=0; count=0; window_gap_us=0; }
    void Write(std::ostream& out, uint64_t now) {
      const auto last = last_us.load(std::memory_order_relaxed);
      out << ',' << count.load() << ',' << window_gap_us.exchange(0)
          << ',' << (last && now >= last ? now-last : 0);
    }
  };
  Cadence input_submitted, pad_received, ack_received;
  std::atomic<uint64_t> window_ping_us{0}, window_queue_us{0}, window_service_us{0};
  std::atomic<uint64_t> unreliable_sent{0}, unreliable_discarded{0};
  std::atomic<int> local_player_port{-1};

  void Reset() {
    input_submitted.Reset(); pad_received.Reset(); ack_received.Reset();
    window_ping_us=0; window_queue_us=0; window_service_us=0;
    unreliable_sent=0; unreliable_discarded=0; local_player_port=-1;
    connected_peer=nullptr; remote_disconnect_commands=0; reliable_timeouts=0; local_disconnect_requests=0;
    disconnect_ack_age_ms=0; disconnect_rtt_ms=0;
    ping_max_us=0; ping_over250ms=0; ping_over500ms=0;
    service_errors=0; receive_events=0; flush_calls=0;
    work_max_us=0; flush_max_us=0; sent_datagrams=0; received_datagrams=0;
    ping_samples=0; ping_total_us=0; ping_latest_us=0;
    input_stalls=0; time_sync_advances=0; stall_disconnects=0;
    invalid_packets=0; peer_disconnects=0; peer_reason=0; apple_service_result=-2;
    queued_packets=0; queue_total_us=0; queue_max_us=0; loop_max_us=0; send_failures=0;
    enet_rtt_ms=0; enet_rtt_variance_ms=0; enet_packet_loss=0;
    enet_throttle_samples=0; enet_throttle_min=32;
    enet_throttle_latest=0; enet_throttle_window_samples=0;
    enet_throttle_window_min=32; enet_throttle_window_max=0;
    native_dispatches=0; fallback_steps=0; failed_chunks=0; verifications=0; reverify_events=0;
  }
  static void RecordMaximum(std::atomic<uint64_t>& target, uint64_t value) {
    auto previous = target.load(std::memory_order_relaxed);
    while (previous < value && !target.compare_exchange_weak(previous, value,
            std::memory_order_relaxed)) {}
  }
  void ObserveQueue(uint64_t us) {
    RecordMaximum(window_queue_us, us);
    ++queued_packets;
    queue_total_us.fetch_add(us, std::memory_order_relaxed);
    RecordMaximum(queue_max_us, us);
  }
  void ObservePing(uint64_t us) {
    RecordMaximum(window_ping_us, us);
    RecordMaximum(ping_max_us, us);
    if (us >= 250000) ++ping_over250ms;
    if (us >= 500000) ++ping_over500ms;
    ping_latest_us.store(us, std::memory_order_relaxed);
    ping_total_us.fetch_add(us, std::memory_order_relaxed);
    // Readers use this counter to acquire the preceding total update.
    ping_samples.fetch_add(1, std::memory_order_release);
  }
  void ObserveThrottle(uint32_t value) {
    ++enet_throttle_samples;
    enet_throttle_latest.store(value, std::memory_order_relaxed);
    ++enet_throttle_window_samples;
    auto previous = enet_throttle_min.load(std::memory_order_relaxed);
    while (previous > value && !enet_throttle_min.compare_exchange_weak(
        previous, value, std::memory_order_relaxed)) {}
    previous = enet_throttle_window_min.load(std::memory_order_relaxed);
    while (previous > value && !enet_throttle_window_min.compare_exchange_weak(
        previous, value, std::memory_order_relaxed)) {}
    RecordMaximum(enet_throttle_window_max, value);
  }
  void ObserveLog(std::string_view text) {
    const auto starts = [&](std::string_view prefix) { return text.substr(0, prefix.size()) == prefix; };
    if (starts("Halting for one frame due to rollback limit")) ++input_stalls;
    else if (starts("Advancing on frame ")) ++time_sync_advances;
    else if (starts("Force-disconnecting player ")) ++stall_disconnects;
    else if (starts("Netplay packet too small") || starts("Netplay ack packet too small") ||
             starts("Ack packet too small") || starts("Got packet with invalid player idx") ||
             starts("Got ack packet with invalid player idx") ||
             starts("Netplay packet contained too many frames")) ++invalid_packets;
  }
  void WriteRow(std::ostream& out, double elapsed, uint64_t now_us = 0) {
    out << elapsed << ',' << ping_samples.load() << ',' << ping_total_us.load()
        << ',' << ping_latest_us.load() << ',' << input_stalls.load()
        << ',' << time_sync_advances.load() << ',' << stall_disconnects.load()
        << ',' << invalid_packets.load() << ',' << peer_disconnects.load()
        << ',' << peer_reason.load() << ',' << apple_service_result.load()
        << ',' << queued_packets.load() << ',' << queue_total_us.load()
        << ',' << queue_max_us.load() << ',' << loop_max_us.load()
        << ',' << send_failures.load() << ',' << enet_rtt_ms.load()
        << ',' << enet_rtt_variance_ms.load() << ',' << enet_packet_loss.load()
        << ',' << native_dispatches.load() << ',' << fallback_steps.load()
        << ',' << failed_chunks.load() << ',' << verifications.load()
        << ',' << reverify_events.load()
        << ',' << enet_throttle_samples.load() << ',' << enet_throttle_min.load()
        << ',' << ping_max_us.load() << ',' << ping_over250ms.load() << ',' << ping_over500ms.load()
        << ',' << service_errors.load() << ',' << receive_events.load() << ',' << flush_calls.load()
        << ',' << work_max_us.load() << ',' << flush_max_us.load()
        << ',' << sent_datagrams.load() << ',' << received_datagrams.load()
        << ',' << remote_disconnect_commands.load() << ',' << reliable_timeouts.load()
        << ',' << local_disconnect_requests.load() << ',' << disconnect_ack_age_ms.load()
        << ',' << disconnect_rtt_ms.load();
    input_submitted.Write(out, now_us);
    pad_received.Write(out, now_us);
    ack_received.Write(out, now_us);
    out << ',' << window_ping_us.exchange(0) << ',' << window_queue_us.exchange(0)
        << ',' << window_service_us.exchange(0) << ',' << unreliable_sent.load()
        << ',' << unreliable_discarded.load() << ',' << local_player_port.load()
        << ',' << enet_throttle_latest.load() << ',' << enet_throttle_window_samples.exchange(0)
        << ',' << enet_throttle_window_min.exchange(32)
        << ',' << enet_throttle_window_max.exchange(0) << '\n';
  }
};
inline SlippiNetworkDiagnostics slippi_network_diagnostics;
