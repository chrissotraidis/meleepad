#import "SsbmPadInputMixer.h"

#include <algorithm>
#include <cmath>
#include <mutex>

@implementation SsbmPadInputMixer {
    std::mutex _mutex;
    SsbmPadInputState _states[2];   // 0 = touch, 1 = controller
    uint16_t _latchedButtons[2];
}

+ (instancetype)sharedMixer {
    static SsbmPadInputMixer *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[SsbmPadInputMixer alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if ((self = [super init])) {
        _states[0] = (SsbmPadInputState){0};
        _states[1] = (SsbmPadInputState){0};
        _latchedButtons[0] = _latchedButtons[1] = 0;
    }
    return self;
}

- (void)setInputState:(SsbmPadInputState)state fromTouch:(BOOL)touch {
    std::scoped_lock lock(_mutex);
    NSUInteger index = touch ? 0 : 1;
    // Latch rising edges so a fast tap survives until the game thread polls.
    _latchedButtons[index] |= state.buttons & ~_states[index].buttons;
    _states[index] = state;
}

- (void)clearInputFromTouch:(BOOL)touch {
    std::scoped_lock lock(_mutex);
    NSUInteger index = touch ? 0 : 1;
    _states[index] = (SsbmPadInputState){0};
    _latchedButtons[index] = 0;
}

- (SsbmPadInputState)consumeMergedState {
    std::scoped_lock lock(_mutex);
    const SsbmPadInputState &touch = _states[0];
    const SsbmPadInputState &controller = _states[1];

    SsbmPadInputState merged;
    merged.buttons = touch.buttons | controller.buttons |
                     _latchedButtons[0] | _latchedButtons[1];
    merged.stickX = std::abs((int)controller.stickX) > std::abs((int)touch.stickX)
                        ? controller.stickX : touch.stickX;
    merged.stickY = std::abs((int)controller.stickY) > std::abs((int)touch.stickY)
                        ? controller.stickY : touch.stickY;
    merged.cStickX = std::abs((int)controller.cStickX) > std::abs((int)touch.cStickX)
                         ? controller.cStickX : touch.cStickX;
    merged.cStickY = std::abs((int)controller.cStickY) > std::abs((int)touch.cStickY)
                         ? controller.cStickY : touch.cStickY;
    merged.triggerL = std::max(touch.triggerL, controller.triggerL);
    merged.triggerR = std::max(touch.triggerR, controller.triggerR);
    merged.connected = controller.connected || touch.connected;

    _latchedButtons[0] = _latchedButtons[1] = 0;
    return merged;
}

@end
