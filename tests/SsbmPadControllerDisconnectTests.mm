#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#include "SsbmPadInputMixer.h"

int main() {
  @autoreleasepool {
    SsbmPadInputMixer *mixer = [[SsbmPadInputMixer alloc] init];
    SsbmPadInputState held = {};
    held.connected = 1;
    held.buttons = SsbmPadButtonA | SsbmPadButtonR;
    held.stickX = 127;
    held.triggerL = 96;
    [mixer setInputState:held fromTouch:NO];
    SsbmPadInputState active = [mixer consumeMergedState];
    assert(active.connected == 1 && active.buttons == held.buttons);
    assert(active.stickX == held.stickX && active.triggerL == held.triggerL);
    [mixer clearInputFromTouch:NO];
    SsbmPadInputState released = [mixer consumeMergedState];
    assert(released.connected == 0 && released.buttons == 0);
    assert(released.stickX == 0 && released.triggerL == 0);
    std::cout << "SsbmPad controller disconnect tests passed\n";
  }
  return 0;
}
