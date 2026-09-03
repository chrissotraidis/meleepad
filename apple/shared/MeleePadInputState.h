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
} MeleePadInputState;

typedef NS_ENUM(uint16_t, MeleePadButton) {
    MeleePadButtonDpadLeft = 1 << 0,
    MeleePadButtonDpadRight = 1 << 1,
    MeleePadButtonDpadDown = 1 << 2,
    MeleePadButtonDpadUp = 1 << 3,
    MeleePadButtonZ = 1 << 4,
    MeleePadButtonR = 1 << 5,
    MeleePadButtonL = 1 << 6,
    MeleePadButtonA = 1 << 8,
    MeleePadButtonB = 1 << 9,
    MeleePadButtonX = 1 << 10,
    MeleePadButtonY = 1 << 11,
    MeleePadButtonStart = 1 << 12,
};

NS_ASSUME_NONNULL_END
