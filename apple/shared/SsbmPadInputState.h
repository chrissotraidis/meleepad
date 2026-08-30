#pragma once

#import <stdint.h>

NS_ASSUME_NONNULL_BEGIN

/* Normalized GameCube controller state, matching BellPad's canonical
 * touch/controller mixer boundary. Sticks are int8 [-127, 127], triggers are
 * uint8 [0, 255] (FLUDD pressure), buttons are a bitmask. */
typedef struct {
    int8_t stickX, stickY;
    int8_t cStickX, cStickY;
    uint8_t triggerL, triggerR;
    uint16_t buttons;
    int connected;
} SsbmPadInputState;

typedef NS_ENUM(uint16_t, SsbmPadButton) {
    SsbmPadButtonDpadLeft = 1 << 0,
    SsbmPadButtonDpadRight = 1 << 1,
    SsbmPadButtonDpadDown = 1 << 2,
    SsbmPadButtonDpadUp = 1 << 3,
    SsbmPadButtonZ = 1 << 4,
    SsbmPadButtonR = 1 << 5,
    SsbmPadButtonL = 1 << 6,
    SsbmPadButtonA = 1 << 8,
    SsbmPadButtonB = 1 << 9,
    SsbmPadButtonX = 1 << 10,
    SsbmPadButtonY = 1 << 11,
    SsbmPadButtonStart = 1 << 12,
};

NS_ASSUME_NONNULL_END
