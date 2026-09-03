#include "../apple/ios/MeleePadControllerSlots.h"

#include <cassert>
#include <iostream>

int main() {
  constexpr uintptr_t first = 0x1001;
  constexpr uintptr_t returned = 0x1002;
  constexpr uintptr_t second = 0x2001;

  MeleePadControllerSlots single;
  auto result = single.Reconcile({first});
  assert(result.assigned.size() == 1 && result.assigned[0].slot == 0);
  result = single.Reconcile({first});
  assert(result.assigned.empty() && result.removed.empty());
  result = single.Reconcile({});
  assert(result.removed.size() == 1 && result.removed[0].instance == first);
  result = single.Reconcile({returned});
  assert(single.SlotFor(returned) == 0);

  MeleePadControllerSlots multiple;
  multiple.Reconcile({first});
  result = multiple.Reconcile({first, second});
  assert(result.assigned.size() == 1 && result.assigned[0].slot == 1);
  result = multiple.Reconcile({second, first});
  assert(result.assigned.empty() && result.removed.empty());
  result = multiple.Reconcile({second});
  assert(result.removed.size() == 1 && result.removed[0].slot == 0);
  result = multiple.Reconcile({second, returned});
  assert(multiple.SlotFor(returned) == 0);
  assert(multiple.SlotFor(second) == 1);
  std::cout << "MeleePad controller slot tests passed\n";
  return 0;
}
