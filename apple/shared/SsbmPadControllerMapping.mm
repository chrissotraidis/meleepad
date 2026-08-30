#import "SsbmPadControllerMapping.h"

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
        .gameB = SsbmPadPhysicalControllerButtonB,
        .gameX = SsbmPadPhysicalControllerButtonX,
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
