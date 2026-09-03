#pragma once

#import <Foundation/Foundation.h>

#include "MeleePadInputState.h"

NS_ASSUME_NONNULL_BEGIN

/* Merges touch and GameController input into one normalized GameCube state,
 * matching BellPad's canonical mixer: buttons are OR'ed with rising-edge
 * latching, sticks are strongest-wins, triggers are max. The game thread
 * consumes the merged snapshot once per frame. */
@interface MeleePadInputMixer : NSObject

+ (instancetype)sharedMixer;

- (void)setInputState:(MeleePadInputState)state fromTouch:(BOOL)touch;
- (void)clearInputFromTouch:(BOOL)touch;

/* Returns the merged snapshot and clears consumed latched edges. */
- (MeleePadInputState)consumeMergedState;

@end

NS_ASSUME_NONNULL_END
