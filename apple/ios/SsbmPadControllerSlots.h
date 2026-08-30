#pragma once

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

struct SsbmPadControllerSlotChange {
  uintptr_t instance = 0;
  std::size_t slot = 0;
};

struct SsbmPadControllerReconcileResult {
  std::vector<SsbmPadControllerSlotChange> removed;
  std::vector<SsbmPadControllerSlotChange> assigned;
};

/* Session-local player-slot bookkeeping for Apple's GameController objects.
 * GCController.controllers remains the connection authority; object addresses
 * are used only as process-local instance IDs for reconciliation and logs. */
class SsbmPadControllerSlots {
 public:
  static constexpr std::size_t kMaxPlayers = 4;

  SsbmPadControllerReconcileResult Reconcile(
      const std::vector<uintptr_t>& current_instances) {
    std::vector<uintptr_t> current;
    current.reserve(current_instances.size());
    for (uintptr_t instance : current_instances) {
      if (instance != 0 &&
          std::find(current.begin(), current.end(), instance) == current.end()) {
        current.push_back(instance);
      }
    }

    SsbmPadControllerReconcileResult result;
    for (std::size_t slot = 0; slot < slots_.size(); ++slot) {
      uintptr_t instance = slots_[slot];
      if (instance != 0 &&
          std::find(current.begin(), current.end(), instance) == current.end()) {
        result.removed.push_back({instance, slot});
        slots_[slot] = 0;
      }
    }

    for (uintptr_t instance : current) {
      if (SlotFor(instance) >= 0)
        continue;
      auto free_slot = std::find(slots_.begin(), slots_.end(), 0);
      if (free_slot == slots_.end())
        continue;
      std::size_t slot = static_cast<std::size_t>(free_slot - slots_.begin());
      slots_[slot] = instance;
      result.assigned.push_back({instance, slot});
    }
    return result;
  }

  int SlotFor(uintptr_t instance) const {
    auto slot = std::find(slots_.begin(), slots_.end(), instance);
    return slot == slots_.end() ? -1 : static_cast<int>(slot - slots_.begin());
  }

  uintptr_t InstanceAt(std::size_t slot) const {
    return slot < slots_.size() ? slots_[slot] : 0;
  }

 private:
  std::array<uintptr_t, kMaxPlayers> slots_{};
};
