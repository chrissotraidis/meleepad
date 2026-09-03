#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#import "SsbmPadControllerMapping.h"

static bool Equal(SsbmPadControllerButtonMapping lhs,
                  SsbmPadControllerButtonMapping rhs) {
    return lhs.gameA == rhs.gameA && lhs.gameB == rhs.gameB &&
           lhs.gameX == rhs.gameX && lhs.gameY == rhs.gameY &&
           lhs.gameZ == rhs.gameZ;
}

int main(void) {
    @autoreleasepool {
        const auto defaults = SsbmPadDefaultControllerButtonMapping();
        auto mapping = defaults;
        assert(SsbmPadControllerButtonMappingIsValid(mapping));
        assert(SsbmPadApplyControllerButtonMapping(
            mapping, SsbmPadPhysicalControllerButtonA |
                         SsbmPadPhysicalControllerButtonLeftShoulder) ==
            (SsbmPadButtonA | SsbmPadButtonZ));
        assert(defaults.gameB == SsbmPadPhysicalControllerButtonX);
        assert(defaults.gameX == SsbmPadPhysicalControllerButtonB);
        assert(SsbmPadControllerRightTriggerPressure(0, NO) == 0);
        assert(SsbmPadControllerRightTriggerPressure(0, YES) == 128);
        assert(SsbmPadControllerRightTriggerPressure(64, YES) == 128);
        assert(SsbmPadControllerRightTriggerPressure(192, YES) == 192);
        assert(SsbmPadControllerRightTriggerPressure(255, NO) == 255);

        SsbmPadInputState rightStick = {};
        rightStick.stickX = -20;
        rightStick.stickY = 30;
        rightStick.cStickX = 127;
        rightStick.cStickY = 50;
        SsbmPadInputState smash = SsbmPadApplyRightStickSmashMode(
            rightStick, YES, YES, NO);
        assert(smash.stickX == 127 && smash.stickY == 0);
        assert(smash.cStickX == 0 && smash.cStickY == 0);
        assert((smash.buttons & SsbmPadButtonA) != 0);

        SsbmPadInputState reversed = SsbmPadApplyRightStickSmashMode(
            rightStick, YES, YES, YES);
        assert(reversed.stickX == -127 && reversed.stickY == 0);

        SsbmPadInputState belowThreshold = rightStick;
        belowThreshold.cStickX = 81;
        belowThreshold.cStickY = -40;
        SsbmPadInputState unchanged = SsbmPadApplyRightStickSmashMode(
            belowThreshold, YES, YES, NO);
        assert(unchanged.stickX == belowThreshold.stickX);
        assert(unchanged.cStickX == belowThreshold.cStickX);
        assert((unchanged.buttons & SsbmPadButtonA) == 0);

        SsbmPadInputState originalCStick = SsbmPadApplyRightStickSmashMode(
            rightStick, NO, YES, NO);
        assert(originalCStick.stickX == rightStick.stickX);
        assert(originalCStick.cStickX == rightStick.cStickX);

        SsbmPadInputState menuCStick = SsbmPadApplyRightStickSmashMode(
            rightStick, YES, NO, NO);
        assert(menuCStick.stickX == rightStick.stickX);
        assert(menuCStick.stickY == rightStick.stickY);
        assert(menuCStick.cStickX == rightStick.cStickX);
        assert(menuCStick.cStickY == rightStick.cStickY);
        assert((menuCStick.buttons & SsbmPadButtonA) == 0);

        assert(!SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x01011800));
        assert(!SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x02020100));
        assert(!SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x02020101));
        assert(SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x02020102));
        assert(SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x02020103));
        assert(!SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x03000000));
        assert(SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x03000001));
        assert(!SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x03000008));
        assert(SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x03000009));
        assert(SsbmPadShouldApplyRightStickSmashForRevision0GameState(0x1C000002));

        mapping = SsbmPadControllerButtonMappingByAssigning(
            mapping, SsbmPadPhysicalControllerButtonB, SsbmPadButtonA);
        assert(mapping.gameA == SsbmPadPhysicalControllerButtonB);
        assert(mapping.gameX == SsbmPadPhysicalControllerButtonA);

        auto corrupt = mapping;
        corrupt.gameZ = SsbmPadPhysicalControllerButtonB;
        assert(!SsbmPadControllerButtonMappingIsValid(corrupt));

        [SsbmPadControllerMappingStore reset];
        assert(Equal([SsbmPadControllerMappingStore mapping], defaults));
        [SsbmPadControllerMappingStore setMapping:mapping];
        assert(Equal([SsbmPadControllerMappingStore mapping], mapping));
        [SsbmPadControllerMappingStore setMapping:corrupt];
        assert(Equal([SsbmPadControllerMappingStore mapping], defaults));
        [SsbmPadControllerMappingStore reset];
        std::cout << "SsbmPad controller mapping tests passed\n";
    }
    return 0;
}
