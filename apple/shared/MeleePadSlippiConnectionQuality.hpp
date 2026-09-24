#pragma once

#include <cstdint>

// A one-second view of the native peer counters. No network addresses or
// player identity leave the Slippi runtime.
struct MeleePadSlippiConnectionSample {
  bool connected = false;
  bool game_active = false;
  uint64_t ping_samples = 0;
  uint64_t ping_total_us = 0;
  uint64_t rollback_stalls = 0;
};

enum class MeleePadSlippiConnectionState {
  Disconnected,
  Measuring,
  Steady,
  HighLatency,
  SevereLatency,
  Stalling,
  NoFreshPing,
};

struct MeleePadSlippiConnectionResult {
  MeleePadSlippiConnectionState state = MeleePadSlippiConnectionState::Disconnected;
  unsigned average_ms = 0;
};

class MeleePadSlippiConnectionQuality {
 public:
  MeleePadSlippiConnectionResult Update(const MeleePadSlippiConnectionSample& sample) {
    if (!sample.connected) {
      Reset();
      return {};
    }
    if (!connected_ || sample.ping_samples < previous_samples_ ||
        sample.ping_total_us < previous_total_us_ ||
        sample.rollback_stalls < previous_stalls_) {
      Reset();
      connected_ = true;
      previous_samples_ = sample.ping_samples;
      previous_total_us_ = sample.ping_total_us;
      previous_stalls_ = sample.rollback_stalls;
      return {MeleePadSlippiConnectionState::Measuring, 0};
    }

    const uint64_t count = sample.ping_samples - previous_samples_;
    const uint64_t total = sample.ping_total_us - previous_total_us_;
    const uint64_t stalls = sample.rollback_stalls - previous_stalls_;
    previous_samples_ = sample.ping_samples;
    previous_total_us_ = sample.ping_total_us;
    previous_stalls_ = sample.rollback_stalls;

    if (count > 0) {
      average_ms_ = static_cast<unsigned>(total / count / 1000);
      missing_windows_ = 0;
      high_windows_ = average_ms_ >= 120 ? high_windows_ + 1 : 0;
    } else if (sample.game_active) {
      ++missing_windows_;
      high_windows_ = 0;
    } else {
      missing_windows_ = 0;
    }

    if (sample.game_active && stalls >= 3)
      return {MeleePadSlippiConnectionState::Stalling, average_ms_};
    if (sample.game_active && missing_windows_ >= 3)
      return {MeleePadSlippiConnectionState::NoFreshPing, average_ms_};
    if (count > 0 && average_ms_ >= 200)
      return {MeleePadSlippiConnectionState::SevereLatency, average_ms_};
    if (high_windows_ >= 2)
      return {MeleePadSlippiConnectionState::HighLatency, average_ms_};
    return average_ms_ > 0
        ? MeleePadSlippiConnectionResult{MeleePadSlippiConnectionState::Steady, average_ms_}
        : MeleePadSlippiConnectionResult{MeleePadSlippiConnectionState::Measuring, 0};
  }

  void Reset() {
    connected_ = false;
    previous_samples_ = previous_total_us_ = previous_stalls_ = 0;
    high_windows_ = missing_windows_ = average_ms_ = 0;
  }

 private:
  bool connected_ = false;
  uint64_t previous_samples_ = 0, previous_total_us_ = 0, previous_stalls_ = 0;
  unsigned high_windows_ = 0, missing_windows_ = 0, average_ms_ = 0;
};
