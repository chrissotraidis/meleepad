#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#include "MeleePadControllerMapping.h"
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

    MeleePadInputState touchCStick = {};
    touchCStick.connected = 1;
    touchCStick.cStickY = -127;
    [mixer setInputState:touchCStick fromTouch:YES];
    MeleePadInputState mergedTouch = [mixer consumeMergedState];
    MeleePadInputState touchSmash = MeleePadApplyRightStickSmashMode(
        mergedTouch, YES, YES, NO);
    assert(touchSmash.stickY == -127);
    assert(touchSmash.cStickY == 0);
    assert((touchSmash.buttons & MeleePadButtonA) != 0);
    [mixer clearInputFromTouch:YES];

    MeleePadInputState controllerCStick = {};
    controllerCStick.connected = 1;
    controllerCStick.cStickX = 127;
    [mixer setInputState:controllerCStick fromTouch:NO];
    MeleePadInputState mergedController = [mixer consumeMergedState];
    MeleePadInputState controllerSmash = MeleePadApplyRightStickSmashMode(
        mergedController, YES, YES, NO);
    assert(controllerSmash.stickX == 127);
    assert(controllerSmash.cStickX == 0);
    assert((controllerSmash.buttons & MeleePadButtonA) != 0);
    std::cout << "MeleePad controller disconnect tests passed\n";
  }
  return 0;
}
