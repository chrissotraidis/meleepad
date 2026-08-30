#pragma once

#import <Foundation/Foundation.h>

#include <string>

#include "SsbmPadInputState.h"

/* Encodes one complete normalized input snapshot for Dolphin's pipe device.
 * Button transitions are computed relative to previousButtons. The modern
 * C-stick option reverses only the horizontal axis. */
std::string SsbmPadEncodePipeCommands(const SsbmPadInputState &input,
                                     uint16_t previousButtons,
                                     bool modernCStickHorizontal);
