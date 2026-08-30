#import "SsbmPadInputPipeEncoder.h"

#include <cstdio>

std::string SsbmPadEncodePipeCommands(const SsbmPadInputState &input,
                                     uint16_t previousButtons,
                                     bool modernCStickHorizontal) {
    std::string commands;
    commands.reserve(320);
    auto appendCommand = [&commands](const char *format, auto... values) {
        char line[64];
        int length = snprintf(line, sizeof(line), format, values...);
        if (length > 0 && static_cast<size_t>(length) < sizeof(line))
            commands.append(line, static_cast<size_t>(length));
    };

    // Sticks are int8 [-127,127]; the pipe expects raw [0,1] with 0.5 neutral
    // and the positive Y axis mapped to stick-down (GCPadNew.ini).
    float mx = 0.5f + (input.stickX / 127.0f) * 0.5f;
    float my = 0.5f - (input.stickY / 127.0f) * 0.5f;
    float cStickX = modernCStickHorizontal ? -input.cStickX : input.cStickX;
    float cx = 0.5f + (cStickX / 127.0f) * 0.5f;
    float cy = 0.5f - (input.cStickY / 127.0f) * 0.5f;
    appendCommand("SET MAIN %.3f %.3f\n", mx, my);
    appendCommand("SET C %.3f %.3f\n", cx, cy);
    appendCommand("SET L %.3f\n", input.triggerL / 255.0f);
    appendCommand("SET R %.3f\n", input.triggerR / 255.0f);

    struct {
        uint16_t bit;
        const char *name;
    } buttons[] = {
        {SsbmPadButtonA, "A"},    {SsbmPadButtonB, "B"},
        {SsbmPadButtonX, "X"},    {SsbmPadButtonY, "Y"},
        {SsbmPadButtonZ, "Z"},    {SsbmPadButtonStart, "START"},
        {SsbmPadButtonL, "L"},    {SsbmPadButtonR, "R"},
        {SsbmPadButtonDpadUp, "D_UP"},
        {SsbmPadButtonDpadDown, "D_DOWN"},
        {SsbmPadButtonDpadLeft, "D_LEFT"},
        {SsbmPadButtonDpadRight, "D_RIGHT"},
    };
    for (const auto &button : buttons) {
        bool pressed = (input.buttons & button.bit) != 0;
        bool wasPressed = (previousButtons & button.bit) != 0;
        if (pressed && !wasPressed)
            appendCommand("PRESS %s\n", button.name);
        else if (!pressed && wasPressed)
            appendCommand("RELEASE %s\n", button.name);
    }
    return commands;
}
