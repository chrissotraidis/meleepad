#import "SsbmPadControllerMapping.h"

#include <algorithm>
#include <cstdlib>
#include <initializer_list>

static NSString *const SsbmPadControllerMappingDefaultsKey =
    @"SsbmPadControllerButtonMappingV1";

static uint8_t const SsbmPadRunAndSprayPressure = 128;

static NSArray<NSString *> *SsbmPadMappingKeys(void) {
    return @[@"A", @"B", @"X", @"Y", @"Z"];
}

static NSArray<NSNumber *> *SsbmPadMappingValues(SsbmPadControllerButtonMapping mapping) {
    return @[@(mapping.gameA), @(mapping.gameB), @(mapping.gameX),
             @(mapping.gameY), @(mapping.gameZ)];
}

static SsbmPadPhysicalControllerButton *SsbmPadMappingSlot(
    SsbmPadControllerButtonMapping *mapping, uint16_t gameButton) {
    switch (gameButton) {
    case SsbmPadButtonA: return &mapping->gameA;
    case SsbmPadButtonB: return &mapping->gameB;
    case SsbmPadButtonX: return &mapping->gameX;
    case SsbmPadButtonY: return &mapping->gameY;
    case SsbmPadButtonZ: return &mapping->gameZ;
    default: return nullptr;
    }
}

SsbmPadControllerButtonMapping SsbmPadDefaultControllerButtonMapping(void) {
    return (SsbmPadControllerButtonMapping){
        .gameA = SsbmPadPhysicalControllerButtonA,
        // Xbox's left face button is a more natural special-move button, while
        // its right face button sits where GameCube X is expected for jump.
        .gameB = SsbmPadPhysicalControllerButtonX,
        .gameX = SsbmPadPhysicalControllerButtonB,
        .gameY = SsbmPadPhysicalControllerButtonY,
        .gameZ = SsbmPadPhysicalControllerButtonLeftShoulder,
    };
}

BOOL SsbmPadControllerButtonMappingIsValid(SsbmPadControllerButtonMapping mapping) {
    uint8_t seen = 0;
    const uint8_t allowed = SsbmPadPhysicalControllerButtonA |
        SsbmPadPhysicalControllerButtonB | SsbmPadPhysicalControllerButtonX |
        SsbmPadPhysicalControllerButtonY |
        SsbmPadPhysicalControllerButtonLeftShoulder;
    for (NSNumber *number in SsbmPadMappingValues(mapping)) {
        uint8_t value = number.unsignedCharValue;
        if (value == 0 || (value & (value - 1)) != 0 || (value & ~allowed) != 0 ||
            (seen & value) != 0) {
            return NO;
        }
        seen |= value;
    }
    return seen == allowed;
}

uint16_t SsbmPadApplyControllerButtonMapping(
    SsbmPadControllerButtonMapping mapping,
    SsbmPadPhysicalControllerButton pressedButtons) {
    if (!SsbmPadControllerButtonMappingIsValid(mapping))
        mapping = SsbmPadDefaultControllerButtonMapping();
    uint16_t gameButtons = 0;
    if (pressedButtons & mapping.gameA) gameButtons |= SsbmPadButtonA;
    if (pressedButtons & mapping.gameB) gameButtons |= SsbmPadButtonB;
    if (pressedButtons & mapping.gameX) gameButtons |= SsbmPadButtonX;
    if (pressedButtons & mapping.gameY) gameButtons |= SsbmPadButtonY;
    if (pressedButtons & mapping.gameZ) gameButtons |= SsbmPadButtonZ;
    return gameButtons;
}

SsbmPadControllerButtonMapping SsbmPadControllerButtonMappingByAssigning(
    SsbmPadControllerButtonMapping mapping,
    SsbmPadPhysicalControllerButton physicalButton,
    uint16_t gameButton) {
    if (!SsbmPadControllerButtonMappingIsValid(mapping))
        mapping = SsbmPadDefaultControllerButtonMapping();
    SsbmPadPhysicalControllerButton *destination = SsbmPadMappingSlot(&mapping, gameButton);
    if (destination == nullptr)
        return mapping;
    SsbmPadPhysicalControllerButton previous = *destination;
    if (previous == physicalButton)
        return mapping;
    for (uint16_t candidate : {SsbmPadButtonA, SsbmPadButtonB, SsbmPadButtonX,
                               SsbmPadButtonY, SsbmPadButtonZ}) {
        SsbmPadPhysicalControllerButton *slot = SsbmPadMappingSlot(&mapping, candidate);
        if (slot != nullptr && *slot == physicalButton) {
            *slot = previous;
            break;
        }
    }
    *destination = physicalButton;
    return mapping;
}

NSString *SsbmPadPhysicalControllerButtonName(SsbmPadPhysicalControllerButton button) {
    switch (button) {
    case SsbmPadPhysicalControllerButtonA: return @"A";
    case SsbmPadPhysicalControllerButtonB: return @"B";
    case SsbmPadPhysicalControllerButtonX: return @"X";
    case SsbmPadPhysicalControllerButtonY: return @"Y";
    case SsbmPadPhysicalControllerButtonLeftShoulder: return @"Left Shoulder";
    default: return @"Unknown";
    }
}

uint8_t SsbmPadControllerRightTriggerPressure(
    uint8_t triggerPressure, BOOL rightShoulderPressed) {
    return rightShoulderPressed
        ? MAX(triggerPressure, SsbmPadRunAndSprayPressure)
        : triggerPressure;
}

SsbmPadInputState SsbmPadApplyRightStickSmashMode(
    SsbmPadInputState state, BOOL enabled, BOOL gameplayScene,
    BOOL reverseHorizontal) {
    if (!enabled || !gameplayScene)
        return state;

    constexpr int kSmashThreshold = 82;
    int cX = reverseHorizontal ? -(int)state.cStickX : (int)state.cStickX;
    int cY = state.cStickY;
    if (std::max(std::abs(cX), std::abs(cY)) < kSmashThreshold)
        return state;

    // Melee normally reserves C-stick attacks for Versus. During an active
    // combat scene, modern controller mode expresses the same intent as a
    // cardinal main-stick direction plus A, which also lets holding the right
    // stick charge the smash. Menus and cutscenes retain the untouched C-stick.
    // The direct C-stick is cleared here to avoid delivering two attack inputs.
    if (std::abs(cX) >= std::abs(cY)) {
        state.stickX = (int8_t)cX;
        state.stickY = 0;
    } else {
        state.stickX = 0;
        state.stickY = (int8_t)cY;
    }
    state.cStickX = 0;
    state.cStickY = 0;
    state.buttons |= SsbmPadButtonA;
    return state;
}

BOOL SsbmPadShouldApplyRightStickSmashForRevision0GameState(uint32_t gameState) {
    // GALE01 revision 0 GameState packs current major mode in the high byte and
    // the current per-mode scene index in the low byte. Keep this deliberately
    // narrow: these are the verified ordinary VS, Classic-fight, and Training
    // combat routes. Front-end scenes such as menu, CSS, and stage select do
    // not match.
    const uint8_t gameMode = (uint8_t)(gameState >> 24);
    const uint8_t sceneIndex = (uint8_t)gameState;
    if (gameMode == 0x02)
        return sceneIndex == 0x02 || sceneIndex == 0x03;
    if (gameMode == 0x03)
        return sceneIndex <= 0x51 && (sceneIndex & 0x07) == 0x01;
    if (gameMode == 0x1C)
        return sceneIndex == 0x02;
    return NO;
}

@implementation SsbmPadControllerMappingStore

+ (SsbmPadControllerButtonMapping)mapping {
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults]
        dictionaryForKey:SsbmPadControllerMappingDefaultsKey];
    if (saved == nil)
        return SsbmPadDefaultControllerButtonMapping();
    NSArray<NSString *> *keys = SsbmPadMappingKeys();
    SsbmPadControllerButtonMapping mapping = {
        .gameA = (SsbmPadPhysicalControllerButton)[saved[keys[0]] unsignedCharValue],
        .gameB = (SsbmPadPhysicalControllerButton)[saved[keys[1]] unsignedCharValue],
        .gameX = (SsbmPadPhysicalControllerButton)[saved[keys[2]] unsignedCharValue],
        .gameY = (SsbmPadPhysicalControllerButton)[saved[keys[3]] unsignedCharValue],
        .gameZ = (SsbmPadPhysicalControllerButton)[saved[keys[4]] unsignedCharValue],
    };
    return SsbmPadControllerButtonMappingIsValid(mapping)
        ? mapping : SsbmPadDefaultControllerButtonMapping();
}

+ (void)setMapping:(SsbmPadControllerButtonMapping)mapping {
    if (!SsbmPadControllerButtonMappingIsValid(mapping))
        mapping = SsbmPadDefaultControllerButtonMapping();
    NSArray<NSString *> *keys = SsbmPadMappingKeys();
    NSArray<NSNumber *> *values = SsbmPadMappingValues(mapping);
    NSMutableDictionary *saved = [NSMutableDictionary dictionaryWithCapacity:keys.count];
    for (NSUInteger index = 0; index < keys.count; ++index)
        saved[keys[index]] = values[index];
    [[NSUserDefaults standardUserDefaults] setObject:saved
                                              forKey:SsbmPadControllerMappingDefaultsKey];
}

+ (void)reset {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SsbmPadControllerMappingDefaultsKey];
}

@end
