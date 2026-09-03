#import <Foundation/Foundation.h>

#include <cassert>
#include <iostream>

#import "MeleePadControllerMapping.h"

static bool Equal(MeleePadControllerButtonMapping lhs,
                  MeleePadControllerButtonMapping rhs) {
    return lhs.gameA == rhs.gameA && lhs.gameB == rhs.gameB &&
           lhs.gameX == rhs.gameX && lhs.gameY == rhs.gameY &&
           lhs.gameZ == rhs.gameZ;
}

int main(void) {
    @autoreleasepool {
        const auto defaults = MeleePadDefaultControllerButtonMapping();
        auto mapping = defaults;
        assert(MeleePadControllerButtonMappingIsValid(mapping));
        assert(MeleePadApplyControllerButtonMapping(
            mapping, MeleePadPhysicalControllerButtonA |
                         MeleePadPhysicalControllerButtonLeftShoulder) ==
            (MeleePadButtonA | MeleePadButtonZ));
        assert(defaults.gameB == MeleePadPhysicalControllerButtonX);
        assert(defaults.gameX == MeleePadPhysicalControllerButtonB);
        assert(MeleePadControllerRightTriggerPressure(0, NO) == 0);
        assert(MeleePadControllerRightTriggerPressure(0, YES) == 128);
        assert(MeleePadControllerRightTriggerPressure(64, YES) == 128);
        assert(MeleePadControllerRightTriggerPressure(192, YES) == 192);
        assert(MeleePadControllerRightTriggerPressure(255, NO) == 255);

        MeleePadInputState rightStick = {};
        rightStick.stickX = -20;
        rightStick.stickY = 30;
        rightStick.cStickX = 127;
        rightStick.cStickY = 50;
        MeleePadInputState smash = MeleePadApplyRightStickSmashMode(
            rightStick, YES, YES, NO);
        assert(smash.stickX == 127 && smash.stickY == 0);
        assert(smash.cStickX == 0 && smash.cStickY == 0);
        assert((smash.buttons & MeleePadButtonA) != 0);

        MeleePadInputState reversed = MeleePadApplyRightStickSmashMode(
            rightStick, YES, YES, YES);
        assert(reversed.stickX == -127 && reversed.stickY == 0);

        MeleePadInputState belowThreshold = rightStick;
        belowThreshold.cStickX = 81;
        belowThreshold.cStickY = -40;
        MeleePadInputState unchanged = MeleePadApplyRightStickSmashMode(
            belowThreshold, YES, YES, NO);
        assert(unchanged.stickX == belowThreshold.stickX);
        assert(unchanged.cStickX == belowThreshold.cStickX);
        assert((unchanged.buttons & MeleePadButtonA) == 0);

        MeleePadInputState originalCStick = MeleePadApplyRightStickSmashMode(
            rightStick, NO, YES, NO);
        assert(originalCStick.stickX == rightStick.stickX);
        assert(originalCStick.cStickX == rightStick.cStickX);

        MeleePadInputState menuCStick = MeleePadApplyRightStickSmashMode(
            rightStick, YES, NO, NO);
        assert(menuCStick.stickX == rightStick.stickX);
        assert(menuCStick.stickY == rightStick.stickY);
        assert(menuCStick.cStickX == rightStick.cStickX);
        assert(menuCStick.cStickY == rightStick.cStickY);
        assert((menuCStick.buttons & MeleePadButtonA) == 0);

        assert(!MeleePadShouldApplyRightStickSmashForRevision0GameState(0x01011800));
        assert(!MeleePadShouldApplyRightStickSmashForRevision0GameState(0x02020100));
        assert(!MeleePadShouldApplyRightStickSmashForRevision0GameState(0x02020101));
        assert(MeleePadShouldApplyRightStickSmashForRevision0GameState(0x02020102));
        assert(MeleePadShouldApplyRightStickSmashForRevision0GameState(0x02020103));
        assert(!MeleePadShouldApplyRightStickSmashForRevision0GameState(0x03000000));
        assert(MeleePadShouldApplyRightStickSmashForRevision0GameState(0x03000001));
        assert(!MeleePadShouldApplyRightStickSmashForRevision0GameState(0x03000008));
        assert(MeleePadShouldApplyRightStickSmashForRevision0GameState(0x03000009));
        assert(MeleePadShouldApplyRightStickSmashForRevision0GameState(0x1C000002));

        mapping = MeleePadControllerButtonMappingByAssigning(
            mapping, MeleePadPhysicalControllerButtonB, MeleePadButtonA);
        assert(mapping.gameA == MeleePadPhysicalControllerButtonB);
        assert(mapping.gameX == MeleePadPhysicalControllerButtonA);

        auto corrupt = mapping;
        corrupt.gameZ = MeleePadPhysicalControllerButtonB;
        assert(!MeleePadControllerButtonMappingIsValid(corrupt));

        [MeleePadControllerMappingStore reset];
        assert(Equal([MeleePadControllerMappingStore mapping], defaults));
        [MeleePadControllerMappingStore setMapping:mapping];
        assert(Equal([MeleePadControllerMappingStore mapping], mapping));
        [MeleePadControllerMappingStore setMapping:corrupt];
        assert(Equal([MeleePadControllerMappingStore mapping], defaults));
        [MeleePadControllerMappingStore reset];
        std::cout << "MeleePad controller mapping tests passed\n";
    }
    return 0;
}
