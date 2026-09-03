#pragma once

#import <Foundation/Foundation.h>

#include "MeleePadInputState.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(uint8_t, MeleePadPhysicalControllerButton) {
    MeleePadPhysicalControllerButtonA = 1 << 0,
    MeleePadPhysicalControllerButtonB = 1 << 1,
    MeleePadPhysicalControllerButtonX = 1 << 2,
    MeleePadPhysicalControllerButtonY = 1 << 3,
    MeleePadPhysicalControllerButtonLeftShoulder = 1 << 4,
};

typedef struct {
    MeleePadPhysicalControllerButton gameA;
    MeleePadPhysicalControllerButton gameB;
    MeleePadPhysicalControllerButton gameX;
    MeleePadPhysicalControllerButton gameY;
    MeleePadPhysicalControllerButton gameZ;
} MeleePadControllerButtonMapping;

FOUNDATION_EXPORT MeleePadControllerButtonMapping MeleePadDefaultControllerButtonMapping(void);
FOUNDATION_EXPORT BOOL MeleePadControllerButtonMappingIsValid(
    MeleePadControllerButtonMapping mapping);
FOUNDATION_EXPORT uint16_t MeleePadApplyControllerButtonMapping(
    MeleePadControllerButtonMapping mapping,
    MeleePadPhysicalControllerButton pressedButtons);
FOUNDATION_EXPORT MeleePadControllerButtonMapping MeleePadControllerButtonMappingByAssigning(
    MeleePadControllerButtonMapping mapping,
    MeleePadPhysicalControllerButton physicalButton,
    uint16_t gameButton);
FOUNDATION_EXPORT NSString *MeleePadPhysicalControllerButtonName(
    MeleePadPhysicalControllerButton button);
FOUNDATION_EXPORT uint8_t MeleePadControllerRightTriggerPressure(
    uint8_t triggerPressure, BOOL rightShoulderPressed);
FOUNDATION_EXPORT MeleePadInputState MeleePadApplyRightStickSmashMode(
    MeleePadInputState state, BOOL enabled, BOOL gameplayScene,
    BOOL reverseHorizontal);
FOUNDATION_EXPORT BOOL MeleePadShouldApplyRightStickSmashForRevision0GameState(
    uint32_t gameState);

/* Versioned, app-local persistence for the deliberately narrow A/B/X/Y/Z
 * remapping layer. Sticks, D-pad, Menu, right shoulder, and analog triggers
 * remain outside this store and keep their established direct mappings. */
@interface MeleePadControllerMappingStore : NSObject

+ (MeleePadControllerButtonMapping)mapping;
+ (void)setMapping:(MeleePadControllerButtonMapping)mapping;
+ (void)reset;

@end

NS_ASSUME_NONNULL_END
