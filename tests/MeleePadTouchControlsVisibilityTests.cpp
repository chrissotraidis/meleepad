#include "../apple/ios/MeleePadTouchControlsVisibility.h"

#include <cassert>
#include <iostream>

static bool Hidden(const MeleePadControllerSlots& slots, bool autoHide, bool nso = false,
                   bool editing = false) {
  return MeleePadTouchControlsHidden(editing, autoHide,
                                     MeleePadTouchPlayerHasController(slots, nso));
}

int main() {
  constexpr uintptr_t first = 0x1001;
  constexpr uintptr_t second = 0x2001;

  // No controller: the controls stay visible whatever the preference.
  MeleePadControllerSlots slots;
  assert(!Hidden(slots, true));

  // A controller already connected at launch is assigned by the launch
  // reconcile, which hides the controls when auto-hide is on.
  slots.Reconcile({first});
  assert(Hidden(slots, true));

  // Turning auto-hide off (the setting, or Show Touch Controls) restores the
  // controls with the controller still connected; on hides them again.
  assert(!Hidden(slots, false));
  assert(Hidden(slots, true));
  assert(!Hidden(slots, true, false, true));  // layout editing

  // Removing player 2 keeps player 1's controller, so the controls stay hidden.
  slots.Reconcile({first, second});
  slots.Reconcile({first});
  assert(Hidden(slots, true));

  // A controller left only in player 2's slot belongs to another port; the
  // touch player keeps its controls.
  slots.Reconcile({first, second});
  slots.Reconcile({second});
  assert(!Hidden(slots, true));

  // An NSO GameCube controller on player 1 stands in for touch on its own.
  MeleePadControllerSlots none;
  assert(Hidden(none, true, true));
  assert(!Hidden(none, false, true));

  // Disconnecting everything shows the controls.
  slots.Reconcile({});
  assert(!Hidden(slots, true));

  std::cout << "MeleePad touch-control visibility tests passed\n";
  return 0;
}
