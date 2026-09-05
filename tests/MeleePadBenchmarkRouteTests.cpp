#import <Foundation/Foundation.h>

#include "MeleePadBenchmarkRoute.h"

#include <cassert>
#include <cstddef>

int main() {
    MeleePadInputState input{};
    std::size_t pulse = 0;
    assert(!MeleePadApplyBenchmarkRoute(nullptr, 6.0, &input, &pulse));
    assert(!MeleePadApplyBenchmarkRoute("unknown", 6.0, &input, &pulse));

    assert(MeleePadApplyBenchmarkRoute("classic-v1", 5.99, &input, &pulse));
    assert(input.connected == 1);
    assert(input.buttons == 0);
    assert(pulse == SIZE_MAX);

    assert(MeleePadApplyBenchmarkRoute("classic-v1", 6.05, &input, &pulse));
    assert(input.buttons == MeleePadButtonStart);
    assert(pulse == 0);
    assert(MeleePadBenchmarkStepLabel(pulse) != nullptr);

    assert(MeleePadApplyBenchmarkRoute("training-fod-v1", 18.05, &input, &pulse));
    assert(input.buttons == MeleePadButtonDpadDown);
    assert(input.stickY == 0);
    assert(pulse == 3);
    assert(std::strcmp(MeleePadBenchmarkStepLabel("training-fod-v1", pulse),
                       "move-to-event") == 0);
    assert(MeleePadApplyBenchmarkRoute("training-fod-v1", 22.05, &input, &pulse));
    assert(input.buttons == MeleePadButtonA);
    assert(pulse == 6);
    MeleePadBenchmarkGuestState unavailableGuest{};
    assert(MeleePadApplyBenchmarkGuestRoute("training-fod-v1", 29.05,
                                            unavailableGuest, &input, &pulse));
    assert(pulse == 11);

    assert(MeleePadApplyBenchmarkRoute("classic-v1", 6.16, &input, &pulse));
    assert(input.buttons == 0);
    assert(pulse == SIZE_MAX);

    MeleePadBenchmarkGuestState guest{};
    guest.cursorValid = true;
    guest.gameState = 0x01010000;
    guest.cursorX = -31.0f;
    guest.cursorY = -21.5f;
    guest.cursorState = 0;
    assert(!MeleePadApplyBenchmarkGuestRoute("classic-v1", 28.99, guest, &input, &pulse));
    assert(MeleePadApplyBenchmarkGuestRoute("classic-v1", 29.05, guest, &input, &pulse));
    assert(input.buttons == MeleePadButtonA);
    assert(pulse == 5);

    assert(MeleePadApplyBenchmarkGuestRoute("classic-v1", 30.2, guest, &input, &pulse));
    assert(input.stickX == 0);
    assert(input.stickY == 96);
    assert(pulse == 6);

    guest.cursorState = 1;
    assert(MeleePadApplyBenchmarkGuestRoute("classic-v1", 30.2, guest, &input, &pulse));
    assert(input.stickX == 0);
    assert(input.stickY == 96);
    assert(pulse == 6);

    guest.cursorX = -1.2f;
    guest.cursorY = 18.2f;
    assert(MeleePadApplyBenchmarkGuestRoute("classic-v1", 32.05, guest, &input, &pulse));
    assert(input.buttons == MeleePadButtonA);
    assert(pulse == 7);

    guest.cursorState = 2;
    assert(MeleePadApplyBenchmarkGuestRoute("classic-v1", 31.05, guest, &input, &pulse));
    assert(input.buttons == 0);
    assert(pulse == SIZE_MAX);
    assert(MeleePadApplyBenchmarkGuestRoute("classic-select-v1", 33.05, guest, &input, &pulse));
    assert(input.buttons == 0);
    assert(pulse == SIZE_MAX);
    assert(MeleePadApplyBenchmarkGuestRoute("classic-v1", 33.05, guest, &input, &pulse));
    assert(input.buttons == MeleePadButtonStart);
    assert(pulse == 8);

    assert(MeleePadApplyBenchmarkGuestRoute("training-fod-v1", 33.05, guest,
                                            &input, &pulse));
    assert(input.buttons == MeleePadButtonStart);
    assert(pulse == 10);
    guest.gameState = 0x1C1C0101;
    assert(MeleePadBenchmarkShouldForceFountain("training-fod-v1", guest));
    assert(!MeleePadBenchmarkShouldForceFountain("classic-v1", guest));
    guest.gameState = 0x1C1C0100;
    assert(!MeleePadBenchmarkShouldForceFountain("training-fod-v1", guest));
    assert(MeleePadBenchmarkShouldFixRandomSeed("training-fod-v1", 10));
    assert(!MeleePadBenchmarkShouldFixRandomSeed("training-fod-v1", 8));

    assert(MeleePadApplyBenchmarkRoute("versus-four-big-blue-v1", 14.05,
                                       &input, &pulse));
    assert(input.buttons == MeleePadButtonDpadDown);
    assert(pulse == 2);

    MeleePadBenchmarkGuestState versus{};
    versus.cursorValid = true;
    versus.cssValid = true;
    versus.gameState = 0x02000000;
    versus.cursorState = 1;
    versus.cursorX = 0.0f;
    versus.cursorY = 0.0f;
    assert(MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 30.2,
                                            versus, &input, &pulse));
    assert(input.stickX == -96);
    assert(pulse == 5);

    versus.slotTypes[0] = 0;
    versus.cursorX = -16.5f;
    versus.cursorY = -2.2f;
    versus.cursorState = 0;
    assert(MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 30.05,
                                            versus, &input, &pulse));
    assert(input.stickY == 96);
    assert(pulse == 7);

    versus.characterKinds[0] = 0x10;
    versus.cursorState = 2;
    assert(MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 30.05,
                                            versus, &input, &pulse));
    assert(input.buttons == MeleePadButtonA);
    assert(pulse == 12);

    versus.slotTypes[1] = 1;
    versus.cursorX = 0.0f;
    versus.cursorY = 0.0f;
    assert(MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 30.2,
                                            versus, &input, &pulse));
    assert(input.stickY == -96);
    assert(pulse == 13);

    versus.slotTypes[2] = 1;
    versus.slotTypes[3] = 1;
    assert(MeleePadBenchmarkShouldFixFourPlayerRoster(
        "versus-four-big-blue-v1", versus));
    assert(MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 31.05,
                                            versus, &input, &pulse));
    assert(input.buttons == 0);
    assert(pulse == 17);

    versus.characterKinds[1] = 0x04;
    versus.characterKinds[2] = 0x05;
    versus.characterKinds[3] = 0x06;
    assert(!MeleePadBenchmarkShouldFixFourPlayerRoster(
        "versus-four-big-blue-v1", versus));
    assert(MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 31.05,
                                            versus, &input, &pulse));
    assert(input.buttons == MeleePadButtonStart);
    assert(pulse == 18);
    assert(std::strcmp(MeleePadBenchmarkStepLabel("versus-four-big-blue-v1", pulse),
                       "open-stage-select") == 0);

    versus.gameState = 0x02020101;
    assert(MeleePadBenchmarkShouldForceBigBlue("versus-four-big-blue-v1", versus));
    assert(!MeleePadBenchmarkShouldForceBigBlue("training-fod-v1", versus));
    versus.gameState = 0x02020100;
    assert(!MeleePadBenchmarkShouldForceBigBlue("versus-four-big-blue-v1", versus));
    assert(MeleePadBenchmarkShouldFixRandomSeed("versus-four-big-blue-v1", 18));
    assert(!MeleePadBenchmarkShouldFixRandomSeed("versus-four-big-blue-v1", 16));

    versus.gameState = 0x02020102;
    assert(!MeleePadApplyBenchmarkGuestRoute("versus-four-big-blue-v1", 45.05,
                                             versus, &input, &pulse));

    return 0;
}
