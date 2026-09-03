#pragma once

#import <Foundation/Foundation.h>

#include "SsbmPadInputState.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(uint8_t, SsbmPadPhysicalControllerButton) {
    SsbmPadPhysicalControllerButtonA = 1 << 0,
    SsbmPadPhysicalControllerButtonB = 1 << 1,
    SsbmPadPhysicalControllerButtonX = 1 << 2,
    SsbmPadPhysicalControllerButtonY = 1 << 3,
    SsbmPadPhysicalControllerButtonLeftShoulder = 1 << 4,
};

typedef struct {
    SsbmPadPhysicalControllerButton gameA;
    SsbmPadPhysicalControllerButton gameB;
    SsbmPadPhysicalControllerButton gameX;
    SsbmPadPhysicalControllerButton gameY;
    SsbmPadPhysicalControllerButton gameZ;
} SsbmPadControllerButtonMapping;

FOUNDATION_EXPORT SsbmPadControllerButtonMapping SsbmPadDefaultControllerButtonMapping(void);
FOUNDATION_EXPORT BOOL SsbmPadControllerButtonMappingIsValid(
    SsbmPadControllerButtonMapping mapping);
FOUNDATION_EXPORT uint16_t SsbmPadApplyControllerButtonMapping(
    SsbmPadControllerButtonMapping mapping,
    SsbmPadPhysicalControllerButton pressedButtons);
FOUNDATION_EXPORT SsbmPadControllerButtonMapping SsbmPadControllerButtonMappingByAssigning(
    SsbmPadControllerButtonMapping mapping,
    SsbmPadPhysicalControllerButton physicalButton,
    uint16_t gameButton);
FOUNDATION_EXPORT NSString *SsbmPadPhysicalControllerButtonName(
    SsbmPadPhysicalControllerButton button);
FOUNDATION_EXPORT uint8_t SsbmPadControllerRightTriggerPressure(
    uint8_t triggerPressure, BOOL rightShoulderPressed);
FOUNDATION_EXPORT SsbmPadInputState SsbmPadApplyRightStickSmashMode(
    SsbmPadInputState state, BOOL enabled, BOOL gameplayScene,
    BOOL reverseHorizontal);
FOUNDATION_EXPORT BOOL SsbmPadShouldApplyRightStickSmashForRevision0GameState(
    uint32_t gameState);

/* Versioned, app-local persistence for the deliberately narrow A/B/X/Y/Z
 * remapping layer. Sticks, D-pad, Menu, right shoulder, and analog triggers
 * remain outside this store and keep their established direct mappings. */
@interface SsbmPadControllerMappingStore : NSObject

+ (SsbmPadControllerButtonMapping)mapping;
+ (void)setMapping:(SsbmPadControllerButtonMapping)mapping;
+ (void)reset;

@end

NS_ASSUME_NONNULL_END
