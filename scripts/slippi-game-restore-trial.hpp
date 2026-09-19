// Isolated actual-game Slippi RAM prediction/correction experiment. No network.
#pragma once
#include "Core/Slippi/SlippiSavestate.h"
#include <functional>
#include <map>
#include <memory>
#include <vector>

struct SlippiGameRestoreTrial {
  static constexpr int capture_frame = 120;
  static constexpr int distance = 60;
  struct Trial {
    int delay;
    unsigned compared = 0, mismatches = 0, prediction_differences = 0;
    unsigned aux_compared = 0, aux_mismatches = 0;
    int first_replay_frame = -9999;
    bool completed = false;
  };
  std::vector<Trial> trials{{1}, {3}, {7}};
  std::unique_ptr<SlippiSavestate> snapshot;
  std::map<int, std::map<unsigned, std::vector<u8>>> baseline;
  using Packets = std::vector<std::vector<u8>>;
  std::map<int, Packets> baseline_aux, replay_aux;
  std::function<void(double, bool, bool)> set_input;
  bool captured = false, restored = false, completed = false;
  unsigned compared = 0, mismatches = 0, phase_steps = 0, timeline_errors = 0;
  int first_replay_frame = -9999;
  size_t trial_index = 0;
  enum class Phase { Baseline, Prediction, Correction, Done } phase = Phase::Baseline;

  static int Frame(const u8* p) {
    return static_cast<s32>((u32(p[1]) << 24) | (u32(p[2]) << 16) | (u32(p[3]) << 8) | u32(p[4]));
  }
  void InputAfter(int frame) {
    const int step = frame - capture_frame;
    set_input(step < 4 ? 0.75 : -0.5, step >= 10 && step < 13, step >= 12 && step < 15);
  }
  bool Equal(int frame, unsigned player, const u8* p, u32 size) const {
    const auto row = baseline.find(frame);
    if (row == baseline.end()) return false;
    const auto expected = row->second.find(player);
    return expected != row->second.end() && expected->second == std::vector<u8>(p, p + size);
  }
  void Predict() {
    snapshot->Load({});
    restored = true;
    phase = Phase::Prediction;
    phase_steps = 0;
    replay_aux.clear();
    set_input(0, false, false); // Authoritative input has not arrived in this model.
  }
  void Observe(u8 command, const u8* packet, u32 size) {
    if (completed || size < 5) return;
    const int frame = Frame(packet);
    if (command == 0x3a || command == 0x3b) {
      if (phase == Phase::Baseline && frame > capture_frame && frame <= capture_frame + distance)
        baseline_aux[frame].emplace_back(packet, packet + size);
      else if (phase == Phase::Correction)
        replay_aux[frame].emplace_back(packet, packet + size);
      return;
    }
    if (command == 0x38 && size >= 8) {
      const unsigned player = packet[5] * 2 + packet[6];
      if (phase == Phase::Baseline && frame > capture_frame && frame <= capture_frame + distance)
        baseline[frame][player] = std::vector<u8>(packet, packet + size);
      else if (phase == Phase::Prediction && !Equal(frame, player, packet, size))
        ++trials[trial_index].prediction_differences;
      else if (phase == Phase::Correction) {
        ++compared; ++trials[trial_index].compared;
        if (!Equal(frame, player, packet, size)) { ++mismatches; ++trials[trial_index].mismatches; }
      }
      return;
    }
    if (command != 0x3c) return;
    if (!captured && frame == capture_frame) {
      snapshot = std::make_unique<SlippiSavestate>();
      snapshot->Capture();
      captured = true;
      InputAfter(frame);
      std::fprintf(stderr, "[slippi-restore] captured at frame=%d\n", frame);
    } else if (captured && phase == Phase::Baseline && frame < capture_frame + distance) {
      InputAfter(frame);
    } else if (captured && phase == Phase::Baseline && frame == capture_frame + distance) {
      Predict();
    } else if (phase == Phase::Prediction) {
      ++phase_steps;
      if (frame != capture_frame + static_cast<int>(phase_steps)) ++timeline_errors;
      if (phase_steps == static_cast<unsigned>(trials[trial_index].delay)) {
        snapshot->Load({});
        phase = Phase::Correction;
        phase_steps = 0;
        InputAfter(capture_frame);
      }
    } else if (phase == Phase::Correction) {
      auto& trial = trials[trial_index];
      const auto& expected_aux = baseline_aux[frame];
      const auto& actual_aux = replay_aux[frame];
      const size_t aux_count = std::max(expected_aux.size(), actual_aux.size());
      trial.aux_compared += aux_count;
      for (size_t i = 0; i < aux_count; ++i)
        if (i >= expected_aux.size() || i >= actual_aux.size() || expected_aux[i] != actual_aux[i]) ++trial.aux_mismatches;
      if (phase_steps == 0) {
        trial.first_replay_frame = frame;
        if (trial_index == 0) first_replay_frame = frame;
      }
      ++phase_steps;
      if (frame != capture_frame + static_cast<int>(phase_steps)) ++timeline_errors;
      InputAfter(frame);
      if (phase_steps == distance) {
        trial.completed = true;
        std::fprintf(stderr, "[slippi-restore] delay=%d predicted_differences=%u compared=%u mismatches=%u aux_compared=%u aux_mismatches=%u\n",
                     trial.delay, trial.prediction_differences, trial.compared, trial.mismatches,
                     trial.aux_compared, trial.aux_mismatches);
        if (++trial_index == trials.size()) { completed = true; phase = Phase::Done; set_input(0, false, false); }
        else Predict();
      }
    }
  }
  size_t ExpectedPackets() const {
    size_t count = 0;
    for (const auto& [frame, players] : baseline) count += players.size();
    return count;
  }
  size_t AuxPackets(u8 command = 0) const {
    size_t count = 0;
    for (const auto& [frame, packets] : baseline_aux)
      for (const auto& packet : packets) if (!command || packet[0] == command) ++count;
    return count;
  }
  bool HasMotion() const {
    const std::vector<u8>* previous = nullptr;
    for (const auto& [frame, players] : baseline) {
      const auto p = players.find(0);
      if (p == players.end() || p->second.size() < 18) continue;
      if (previous && !std::equal(previous->begin() + 10, previous->begin() + 18, p->second.begin() + 10)) return true;
      previous = &p->second;
    }
    return false;
  }
  bool Passed() const {
    if (!captured || !restored || !completed || baseline.size() != distance || timeline_errors || !HasMotion() || !AuxPackets(0x3b)) return false;
    for (const auto& trial : trials)
      if (!trial.completed || trial.prediction_differences == 0 || trial.mismatches ||
          trial.compared != ExpectedPackets() || trial.first_replay_frame != capture_frame + 1 ||
          trial.aux_mismatches || trial.aux_compared != AuxPackets()) return false;
    return true;
  }
};
