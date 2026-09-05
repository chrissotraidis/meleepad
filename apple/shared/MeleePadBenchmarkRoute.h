#pragma once

#include "MeleePadInputState.h"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

struct MeleePadBenchmarkStep {
    double startSeconds;
    double durationSeconds;
    uint16_t buttons;
    int8_t stickX;
    int8_t stickY;
};

struct MeleePadBenchmarkGuestState {
    bool cursorValid = false;
    bool cssValid = false;
    uint32_t gameState = 0;
    uint32_t cursorPointer = 0;
    float cursorX = 0.0f;
    float cursorY = 0.0f;
    uint8_t cursorState = 0;
    std::array<uint8_t, 4> characterKinds = {{0xFF, 0xFF, 0xFF, 0xFF}};
    std::array<uint8_t, 4> slotTypes = {{0xFF, 0xFF, 0xFF, 0xFF}};
};

inline bool MeleePadBenchmarkIsTrainingFountainRoute(const char *route) {
    return route != nullptr && std::strcmp(route, "training-fod-v1") == 0;
}

inline bool MeleePadBenchmarkIsFourPlayerBigBlueRoute(const char *route) {
    return route != nullptr &&
           std::strcmp(route, "versus-four-big-blue-v1") == 0;
}

inline bool MeleePadApplyBenchmarkRoute(const char *route, double elapsedSeconds,
                                        MeleePadInputState *input,
                                        std::size_t *activeStep) {
    const bool cursorHold = route != nullptr &&
                            std::strcmp(route, "classic-cursor-hold-v1") == 0;
    const bool selectOnly = route != nullptr &&
                            std::strcmp(route, "classic-select-v1") == 0;
    const bool trainingFountain = MeleePadBenchmarkIsTrainingFountainRoute(route);
    const bool fourPlayerBigBlue =
        MeleePadBenchmarkIsFourPlayerBigBlueRoute(route);
    if (!cursorHold && !selectOnly && !trainingFountain && !fourPlayerBigBlue &&
        (route == nullptr || std::strcmp(route, "classic-v1") != 0))
        return false;

    // A data-free, diagnostic-only route: skip the intro, enter Classic,
    // move the cursor to Peach, select her, and start with default options.
    // Generous gaps make every button press an edge on a slower device.
    static constexpr std::array<MeleePadBenchmarkStep, 5> classicSteps = {{
        {6.0, 0.150, MeleePadButtonStart, 0, 0},
        {10.0, 0.150, MeleePadButtonStart, 0, 0},
        {14.0, 0.150, MeleePadButtonA, 0, 0},
        {18.0, 0.150, MeleePadButtonA, 0, 0},
        {22.0, 0.150, MeleePadButtonA, 0, 0},
    }};
    // Training needs only one selected fighter, making it a deterministic way
    // to reach the stage selector. The hidden third 1-P entry is skipped by
    // the game, so three distinct down edges land on Training mode.
    static constexpr std::array<MeleePadBenchmarkStep, 7> trainingSteps = {{
        {6.0, 0.150, MeleePadButtonStart, 0, 0},
        {10.0, 0.150, MeleePadButtonStart, 0, 0},
        {14.0, 0.150, MeleePadButtonA, 0, 0},
        {18.0, 0.150, MeleePadButtonDpadDown, 0, 0},
        {19.0, 0.150, MeleePadButtonDpadDown, 0, 0},
        {20.0, 0.150, MeleePadButtonDpadDown, 0, 0},
        {22.0, 0.150, MeleePadButtonA, 0, 0},
    }};
    // Enter VS mode through normal menu input. Character selection below is
    // driven by validated guest state rather than elapsed-time cursor motion.
    static constexpr std::array<MeleePadBenchmarkStep, 5> versusSteps = {{
        {6.0, 0.150, MeleePadButtonStart, 0, 0},
        {10.0, 0.150, MeleePadButtonStart, 0, 0},
        {14.0, 0.150, MeleePadButtonDpadDown, 0, 0},
        {18.0, 0.150, MeleePadButtonA, 0, 0},
        {22.0, 0.150, MeleePadButtonA, 0, 0},
    }};
    *input = {};
    input->connected = 1;
    *activeStep = SIZE_MAX;
    const auto applySteps = [&](const auto &steps) {
        for (std::size_t index = 0; index < steps.size(); ++index) {
            const double duration = steps[index].durationSeconds;
            if (elapsedSeconds >= steps[index].startSeconds &&
                elapsedSeconds < steps[index].startSeconds + duration) {
                input->buttons = steps[index].buttons;
                input->stickX = steps[index].stickX;
                input->stickY = steps[index].stickY;
                *activeStep = index;
                break;
            }
        }
    };
    if (trainingFountain)
        applySteps(trainingSteps);
    else if (fourPlayerBigBlue)
        applySteps(versusSteps);
    else
        applySteps(classicSteps);
    return true;
}

inline bool MeleePadApplyBenchmarkGuestRoute(
    const char *route, double elapsedSeconds,
    const MeleePadBenchmarkGuestState &guest, MeleePadInputState *input,
    std::size_t *activeStep) {
    const bool selectOnly = route != nullptr &&
                            std::strcmp(route, "classic-select-v1") == 0;
    const bool cursorHold = route != nullptr &&
                            std::strcmp(route, "classic-cursor-hold-v1") == 0;
    const bool trainingFountain = MeleePadBenchmarkIsTrainingFountainRoute(route);
    const bool fourPlayerBigBlue =
        MeleePadBenchmarkIsFourPlayerBigBlueRoute(route);
    if (!selectOnly && !cursorHold && !trainingFountain && !fourPlayerBigBlue &&
        (route == nullptr || std::strcmp(route, "classic-v1") != 0))
        return false;
    // The direct cursor state is the reliable selector-screen signal for this
    // revision. The broader game-state word contains substate bits that vary
    // while Classic is loading, so gating on it can suppress the route after
    // the cursor is already live. Wait for the same settled-selector point as
    // the validated timed route before acting on the cursor.
    if (elapsedSeconds < 29.0)
        return false;

    if (!guest.cursorValid) {
        if (trainingFountain && elapsedSeconds < 29.150) {
            *input = {};
            input->connected = 1;
            *activeStep = 11;
            return true;
        }
        return false;
    }

    *input = {};
    input->connected = 1;
    *activeStep = SIZE_MAX;

    if (fourPlayerBigBlue) {
        const uint8_t gameMode = static_cast<uint8_t>(guest.gameState >> 24);
        const uint8_t scene = static_cast<uint8_t>(guest.gameState);
        if (gameMode != 0x02u || scene != 0u || !guest.cssValid)
            return false;

        constexpr float tolerance = 1.2f;
        const bool pulse = std::fmod(elapsedSeconds, 1.0) < 0.150;
        const auto steerOrPress = [&](float targetX, float targetY,
                                      std::size_t steerStep,
                                      std::size_t pressStep) {
            const float dx = targetX - guest.cursorX;
            const float dy = targetY - guest.cursorY;
            if (std::abs(dx) > tolerance || std::abs(dy) > tolerance) {
                if (std::abs(dx) >= std::abs(dy))
                    input->stickX = dx > 0.0f ? 96 : -96;
                else
                    input->stickY = dy > 0.0f ? 96 : -96;
                *activeStep = steerStep;
            } else if (pulse) {
                input->buttons = MeleePadButtonA;
                *activeStep = pressStep;
            }
        };

        // The retained controller configuration can enter CSS with every door
        // closed. Activate P1 through the normal door control before touching
        // its token so the route is independent of saved port state.
        if (guest.slotTypes[0] != 0u) {
            steerOrPress(-31.0f, -2.2f, 5, 6);
            return true;
        }
        if (guest.characterKinds[0] != 0x10u) {
            if (guest.cursorState == 1u) {
                steerOrPress(4.4f, 11.5f, 9, 10);
            } else {
                // An unselected human slot has no usable character-model
                // position yet. Clicking once in the icon field makes Melee
                // attach that player's token at the hand position.
                steerOrPress(-20.0f, 5.0f, 7, 8);
            }
            return true;
        }

        static constexpr std::array<float, 3> doorX = {{-16.5f, -1.0f, 14.0f}};
        for (std::size_t selection = 0; selection < doorX.size(); ++selection) {
            const std::size_t player = selection + 1;
            const std::size_t stepBase = 11 + selection * 2;
            if (guest.slotTypes[player] != 1u) {
                steerOrPress(doorX[selection], -2.2f,
                             stepBase, stepBase + 1);
                return true;
            }
        }

        static constexpr std::array<uint8_t, 4> roster =
            {{0x10u, 0x04u, 0x05u, 0x06u}};
        if (guest.characterKinds != roster) {
            *activeStep = 17;
            return true;
        }
        if (pulse) {
            input->buttons = MeleePadButtonStart;
            *activeStep = 18;
        }
        return true;
    }

    constexpr float targetX = -1.0f;
    constexpr float targetY = 18.5f;
    constexpr float tolerance = 1.2f;
    const float dx = targetX - guest.cursorX;
    const float dy = targetY - guest.cursorY;
    const bool atTarget = std::abs(dx) <= tolerance && std::abs(dy) <= tolerance;
    const bool pulse = std::fmod(elapsedSeconds, 1.0) < 0.150;
    const std::size_t guestStepBase = trainingFountain ? 7 : 5;

    if (guest.cursorState <= 1) {
        if (elapsedSeconds < 30.0) {
            if (guest.cursorState == 0 && pulse) {
                input->buttons = MeleePadButtonA;
                *activeStep = guestStepBase;
            }
        } else if (cursorHold || !atTarget) {
            if (std::abs(dx) >= std::abs(dy))
                input->stickX = dx > 0.0f ? 96 : -96;
            else
                input->stickY = dy > 0.0f ? 96 : -96;
            *activeStep = guestStepBase + 1;
        } else if (guest.cursorState == 1 && pulse) {
            input->buttons = MeleePadButtonA;
            *activeStep = guestStepBase + 2;
        }
    } else if (!selectOnly && elapsedSeconds >= 32.0 && pulse) {
        input->buttons = MeleePadButtonStart;
        *activeStep = guestStepBase + 3;
    }
    return true;
}

inline bool MeleePadBenchmarkShouldForceFountain(
    const char *route, const MeleePadBenchmarkGuestState &guest) {
    // Revision-1.00 stores GameRouting in big-endian byte order. Training is
    // mode 0x1C and its stage-selector scene index is 1.
    return MeleePadBenchmarkIsTrainingFountainRoute(route) &&
           ((guest.gameState >> 24) & 0xFFu) == 0x1Cu &&
           (guest.gameState & 0xFFu) == 1u;
}

inline bool MeleePadBenchmarkShouldForceBigBlue(
    const char *route, const MeleePadBenchmarkGuestState &guest) {
    // VS mode is 0x02 and its stage-selector scene index is 1.
    return MeleePadBenchmarkIsFourPlayerBigBlueRoute(route) &&
           ((guest.gameState >> 24) & 0xFFu) == 0x02u &&
           (guest.gameState & 0xFFu) == 1u;
}

inline bool MeleePadBenchmarkShouldFixFourPlayerRoster(
    const char *route, const MeleePadBenchmarkGuestState &guest) {
    static constexpr std::array<uint8_t, 4> roster =
        {{0x10u, 0x04u, 0x05u, 0x06u}};
    static constexpr std::array<uint8_t, 4> slots = {{0u, 1u, 1u, 1u}};
    return MeleePadBenchmarkIsFourPlayerBigBlueRoute(route) && guest.cssValid &&
           ((guest.gameState >> 24) & 0xFFu) == 0x02u &&
           (guest.gameState & 0xFFu) == 0u && guest.slotTypes == slots &&
           guest.characterKinds != roster;
}

inline bool MeleePadBenchmarkShouldFixRandomSeed(const char *route,
                                                 std::size_t index) {
    if (MeleePadBenchmarkIsTrainingFountainRoute(route))
        return index == 2 || index == 6 || index == 10;
    if (MeleePadBenchmarkIsFourPlayerBigBlueRoute(route))
        return index == 4 || index == 10 || index == 17 || index == 18;
    return index == 2 || index == 3 || index == 4 || index == 8;
}

inline const char *MeleePadBenchmarkStepLabel(const char *route,
                                              std::size_t index) {
    if (MeleePadBenchmarkIsFourPlayerBigBlueRoute(route)) {
        static constexpr std::array<const char *, 19> labels = {{
            "skip-intro", "open-main-menu", "move-to-versus", "choose-versus",
            "choose-melee", "steer-p1-door", "enable-p1-human",
            "steer-p1-token-anchor", "pick-up-p1-token", "steer-p1-to-samus",
            "drop-p1-on-samus", "steer-p2-door", "enable-p2-cpu",
            "steer-p3-door", "enable-p3-cpu", "steer-p4-door",
            "enable-p4-cpu", "fix-four-player-roster", "open-stage-select",
        }};
        return index < labels.size() ? labels[index] : nullptr;
    }
    if (MeleePadBenchmarkIsTrainingFountainRoute(route)) {
        static constexpr std::array<const char *, 12> labels = {{
            "skip-intro", "open-main-menu", "choose-one-player",
            "move-to-event", "move-to-stadium", "move-to-training",
            "choose-training", "pick-up-token", "steer-token-to-peach",
            "drop-token-on-peach", "open-stage-select", "probe-css",
        }};
        return index < labels.size() ? labels[index] : nullptr;
    }
    static constexpr std::array<const char *, 9> labels = {{
        "skip-intro", "open-main-menu", "choose-one-player", "choose-regular-match",
        "choose-classic", "pick-up-token", "steer-token-to-peach",
        "drop-token-on-peach", "start-gameplay",
    }};
    return index < labels.size() ? labels[index] : nullptr;
}

inline const char *MeleePadBenchmarkStepLabel(std::size_t index) {
    return MeleePadBenchmarkStepLabel("classic-v1", index);
}
