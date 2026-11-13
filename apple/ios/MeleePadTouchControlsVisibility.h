#pragma once

#include "MeleePadControllerSlots.h"

/* Touch input always drives player 1 (GameCube port 1). Its controller is the
 * GameController pad in player 1's slot or, when one is connected, the NSO
 * GameCube controller that takes player 1. Controllers assigned to players 2-4
 * never hide the touch player. The slot table only holds extended gamepads,
 * which already excludes menu-only remotes. */
inline bool MeleePadTouchPlayerHasController(const MeleePadControllerSlots& slots,
                                             bool nsoPlayerOneConnected) {
  return nsoPlayerOneConnected || slots.InstanceAt(0) != 0;
}

/* Layout editing always shows the controls so it stays escapable. Otherwise
 * auto-hide hides them while player 1 has a controller. "Show Touch Controls"
 * turns auto-hide off, so this returns false with the controller connected. */
inline bool MeleePadTouchControlsHidden(bool editingLayout, bool autoHideWithController,
                                        bool touchPlayerHasController) {
  return !editingLayout && autoHideWithController && touchPlayerHasController;
}
