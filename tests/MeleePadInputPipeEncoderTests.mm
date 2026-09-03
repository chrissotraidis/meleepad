#import <Foundation/Foundation.h>

#include <algorithm>
#include <cassert>
#include <iostream>
#include <string>

#include "MeleePadInputPipeEncoder.h"

static constexpr uint16_t AllButtons =
    MeleePadButtonA | MeleePadButtonB | MeleePadButtonX | MeleePadButtonY |
    MeleePadButtonZ | MeleePadButtonStart | MeleePadButtonL | MeleePadButtonR |
    MeleePadButtonDpadUp | MeleePadButtonDpadDown |
    MeleePadButtonDpadLeft | MeleePadButtonDpadRight;

static size_t CountLines(const std::string &commands) {
    return static_cast<size_t>(std::count(commands.begin(), commands.end(), '\n'));
}

int main(void) {
    @autoreleasepool {
        MeleePadInputState neutral = {};
        std::string commands = MeleePadEncodePipeCommands(neutral, 0, false);
        assert(CountLines(commands) == 4);
        assert(commands.find("SET MAIN 0.500 0.500\n") != std::string::npos);

        MeleePadInputState pressed = {};
        pressed.buttons = AllButtons;
        pressed.stickX = 127;
        pressed.stickY = -127;
        pressed.cStickX = -127;
        pressed.cStickY = 127;
        pressed.triggerL = 255;
        pressed.triggerR = 255;
        commands = MeleePadEncodePipeCommands(pressed, 0, false);
        assert(CountLines(commands) == 16);
        assert(commands.find("PRESS START\n") != std::string::npos);
        assert(commands.find("PRESS D_RIGHT\n") != std::string::npos);

        MeleePadInputState released = {};
        commands = MeleePadEncodePipeCommands(released, AllButtons, false);
        assert(CountLines(commands) == 16);
        assert(commands.find("RELEASE START\n") != std::string::npos);
        assert(commands.find("RELEASE D_RIGHT\n") != std::string::npos);

        MeleePadInputState cStickRight = {};
        cStickRight.cStickX = 127;
        cStickRight.cStickY = 64;
        const std::string original = MeleePadEncodePipeCommands(cStickRight, 0, false);
        const std::string modern = MeleePadEncodePipeCommands(cStickRight, 0, true);
        assert(original.find("SET C 1.000 0.248\n") != std::string::npos);
        assert(modern.find("SET C 0.000 0.248\n") != std::string::npos);
        std::cout << "MeleePad input pipe encoder tests passed\n";
    }
    return 0;
}
