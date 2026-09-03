#import "MeleePadControllerMapping.h"

#include <algorithm>
#include <cstdlib>
#include <initializer_list>

static NSString *const MeleePadControllerMappingDefaultsKey =
    @"MeleePadControllerButtonMappingV1";

static uint8_t const MeleePadRunAndSprayPressure = 128;

static NSArray<NSString *> *MeleePadMappingKeys(void) {
    return @[@"A", @"B", @"X", @"Y", @"Z"];
}

static NSArray<NSNumber *> *MeleePadMappingValues(MeleePadControllerButtonMapping mapping) {
    return @[@(mapping.gameA), @(mapping.gameB), @(mapping.gameX),
             @(mapping.gameY), @(mapping.gameZ)];
}

static MeleePadPhysicalControllerButton *MeleePadMappingSlot(
    MeleePadControllerButtonMapping *mapping, uint16_t gameButton) {
    switch (gameButton) {
    case MeleePadButtonA: return &mapping->gameA;
    case MeleePadButtonB: return &mapping->gameB;
    case MeleePadButtonX: return &mapping->gameX;
    case MeleePadButtonY: return &mapping->gameY;
    case MeleePadButtonZ: return &mapping->gameZ;
    default: return nullptr;
    }
}

MeleePadControllerButtonMapping MeleePadDefaultControllerButtonMapping(void) {
    return (MeleePadControllerButtonMapping){
        .gameA = MeleePadPhysicalControllerButtonA,
        // Xbox's left face button is a more natural special-move button, while
        // its right face button sits where GameCube X is expected for jump.
        .gameB = MeleePadPhysicalControllerButtonX,
        .gameX = MeleePadPhysicalControllerButtonB,
        .gameY = MeleePadPhysicalControllerButtonY,
        .gameZ = MeleePadPhysicalControllerButtonLeftShoulder,
    };
}

BOOL MeleePadControllerButtonMappingIsValid(MeleePadControllerButtonMapping mapping) {
    uint8_t seen = 0;
    const uint8_t allowed = MeleePadPhysicalControllerButtonA |
        MeleePadPhysicalControllerButtonB | MeleePadPhysicalControllerButtonX |
        MeleePadPhysicalControllerButtonY |
        MeleePadPhysicalControllerButtonLeftShoulder;
    for (NSNumber *number in MeleePadMappingValues(mapping)) {
        uint8_t value = number.unsignedCharValue;
        if (value == 0 || (value & (value - 1)) != 0 || (value & ~allowed) != 0 ||
            (seen & value) != 0) {
            return NO;
        }
        seen |= value;
    }
    return seen == allowed;
}

uint16_t MeleePadApplyControllerButtonMapping(
    MeleePadControllerButtonMapping mapping,
    MeleePadPhysicalControllerButton pressedButtons) {
    if (!MeleePadControllerButtonMappingIsValid(mapping))
        mapping = MeleePadDefaultControllerButtonMapping();
    uint16_t gameButtons = 0;
    if (pressedButtons & mapping.gameA) gameButtons |= MeleePadButtonA;
    if (pressedButtons & mapping.gameB) gameButtons |= MeleePadButtonB;
    if (pressedButtons & mapping.gameX) gameButtons |= MeleePadButtonX;
    if (pressedButtons & mapping.gameY) gameButtons |= MeleePadButtonY;
    if (pressedButtons & mapping.gameZ) gameButtons |= MeleePadButtonZ;
    return gameButtons;
}

MeleePadControllerButtonMapping MeleePadControllerButtonMappingByAssigning(
    MeleePadControllerButtonMapping mapping,
    MeleePadPhysicalControllerButton physicalButton,
    uint16_t gameButton) {
    if (!MeleePadControllerButtonMappingIsValid(mapping))
        mapping = MeleePadDefaultControllerButtonMapping();
    MeleePadPhysicalControllerButton *destination = MeleePadMappingSlot(&mapping, gameButton);
    if (destination == nullptr)
        return mapping;
    MeleePadPhysicalControllerButton previous = *destination;
    if (previous == physicalButton)
        return mapping;
    for (uint16_t candidate : {MeleePadButtonA, MeleePadButtonB, MeleePadButtonX,
                               MeleePadButtonY, MeleePadButtonZ}) {
        MeleePadPhysicalControllerButton *slot = MeleePadMappingSlot(&mapping, candidate);
        if (slot != nullptr && *slot == physicalButton) {
            *slot = previous;
            break;
        }
    }
    *destination = physicalButton;
    return mapping;
}

NSString *MeleePadPhysicalControllerButtonName(MeleePadPhysicalControllerButton button) {
    switch (button) {
    case MeleePadPhysicalControllerButtonA: return @"A";
    case MeleePadPhysicalControllerButtonB: return @"B";
    case MeleePadPhysicalControllerButtonX: return @"X";
    case MeleePadPhysicalControllerButtonY: return @"Y";
    case MeleePadPhysicalControllerButtonLeftShoulder: return @"Left Shoulder";
    default: return @"Unknown";
    }
}

uint8_t MeleePadControllerRightTriggerPressure(
    uint8_t triggerPressure, BOOL rightShoulderPressed) {
    return rightShoulderPressed
        ? MAX(triggerPressure, MeleePadRunAndSprayPressure)
        : triggerPressure;
}

MeleePadInputState MeleePadApplyRightStickSmashMode(
    MeleePadInputState state, BOOL enabled, BOOL gameplayScene,
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
    state.buttons |= MeleePadButtonA;
    return state;
}

BOOL MeleePadShouldApplyRightStickSmashForRevision0GameState(uint32_t gameState) {
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

@implementation MeleePadControllerMappingStore

+ (MeleePadControllerButtonMapping)mapping {
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults]
        dictionaryForKey:MeleePadControllerMappingDefaultsKey];
    if (saved == nil)
        return MeleePadDefaultControllerButtonMapping();
    NSArray<NSString *> *keys = MeleePadMappingKeys();
    MeleePadControllerButtonMapping mapping = {
        .gameA = (MeleePadPhysicalControllerButton)[saved[keys[0]] unsignedCharValue],
        .gameB = (MeleePadPhysicalControllerButton)[saved[keys[1]] unsignedCharValue],
        .gameX = (MeleePadPhysicalControllerButton)[saved[keys[2]] unsignedCharValue],
        .gameY = (MeleePadPhysicalControllerButton)[saved[keys[3]] unsignedCharValue],
        .gameZ = (MeleePadPhysicalControllerButton)[saved[keys[4]] unsignedCharValue],
    };
    return MeleePadControllerButtonMappingIsValid(mapping)
        ? mapping : MeleePadDefaultControllerButtonMapping();
}

+ (void)setMapping:(MeleePadControllerButtonMapping)mapping {
    if (!MeleePadControllerButtonMappingIsValid(mapping))
        mapping = MeleePadDefaultControllerButtonMapping();
    NSArray<NSString *> *keys = MeleePadMappingKeys();
    NSArray<NSNumber *> *values = MeleePadMappingValues(mapping);
    NSMutableDictionary *saved = [NSMutableDictionary dictionaryWithCapacity:keys.count];
    for (NSUInteger index = 0; index < keys.count; ++index)
        saved[keys[index]] = values[index];
    [[NSUserDefaults standardUserDefaults] setObject:saved
                                              forKey:MeleePadControllerMappingDefaultsKey];
}

+ (void)reset {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MeleePadControllerMappingDefaultsKey];
}

@end
