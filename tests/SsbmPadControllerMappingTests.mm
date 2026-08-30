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
        assert(SsbmPadControllerRightTriggerPressure(0, NO) == 0);
        assert(SsbmPadControllerRightTriggerPressure(0, YES) == 128);
        assert(SsbmPadControllerRightTriggerPressure(64, YES) == 128);
        assert(SsbmPadControllerRightTriggerPressure(192, YES) == 192);
        assert(SsbmPadControllerRightTriggerPressure(255, NO) == 255);

        mapping = SsbmPadControllerButtonMappingByAssigning(
            mapping, SsbmPadPhysicalControllerButtonB, SsbmPadButtonA);
        assert(mapping.gameA == SsbmPadPhysicalControllerButtonB);
        assert(mapping.gameB == SsbmPadPhysicalControllerButtonA);

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
