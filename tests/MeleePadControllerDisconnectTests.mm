#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#include "MeleePadInputMixer.h"

int main() {
  @autoreleasepool {
    MeleePadInputMixer *mixer = [[MeleePadInputMixer alloc] init];
    MeleePadInputState held = {};
    held.connected = 1;
    held.buttons = MeleePadButtonA | MeleePadButtonR;
    held.stickX = 127;
    held.triggerL = 96;
    [mixer setInputState:held fromTouch:NO];
    MeleePadInputState active = [mixer consumeMergedState];
    assert(active.connected == 1 && active.buttons == held.buttons);
    assert(active.stickX == held.stickX && active.triggerL == held.triggerL);
    [mixer clearInputFromTouch:NO];
    MeleePadInputState released = [mixer consumeMergedState];
    assert(released.connected == 0 && released.buttons == 0);
    assert(released.stickX == 0 && released.triggerL == 0);
    std::cout << "MeleePad controller disconnect tests passed\n";
  }
  return 0;
}
